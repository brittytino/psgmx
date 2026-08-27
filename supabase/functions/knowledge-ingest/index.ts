// ============================================================
// PSGMX — supabase/functions/knowledge-ingest/index.ts (v2)
// Deno Edge Function. Called by DB trigger when
// placement_log_entries.approval_status changes to 'approved'.
//
// Uses Supabase native AI (gte-small, 384-dim) for embeddings.
// ============================================================

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

/**
 * Chunks text at sentence boundaries ('. ', '! ', '? ') with max 500 chars per chunk.
 * Never splits in the middle of a sentence.
 */
function chunkText(text: string, maxChunkSize = 500): string[] {
  const sentences = text.split(/(?<=[.!?])\s+/)
  const chunks: string[] = []
  let currentChunk = ''

  for (const sentence of sentences) {
    const candidate = currentChunk ? `${currentChunk} ${sentence}` : sentence

    if (candidate.length <= maxChunkSize) {
      currentChunk = candidate
    } else {
      if (currentChunk) chunks.push(currentChunk.trim())
      if (sentence.length > maxChunkSize) {
        for (let i = 0; i < sentence.length; i += maxChunkSize) {
          chunks.push(sentence.slice(i, i + maxChunkSize).trim())
        }
        currentChunk = ''
      } else {
        currentChunk = sentence
      }
    }
  }

  if (currentChunk.trim()) chunks.push(currentChunk.trim())
  return chunks.filter(c => c.length > 0)
}

Deno.serve(async (req: Request) => {
  if (req.method !== 'POST') {
    return new Response('Method Not Allowed', { status: 405 })
  }

  if (req.headers.get('authorization') !== `Bearer ${serviceRoleKey}`) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), {
      status: 401,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  let entryId: string
  try {
    const body = await req.json()
    entryId = body.entry_id
    if (!entryId) throw new Error('Missing entry_id')
  } catch (err) {
    return new Response(JSON.stringify({ error: 'Invalid request body', detail: String(err) }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey)

  try {
    // Step 1: Read the approved placement log entry
    const { data: entry, error: entryErr } = await supabase
      .from('placement_log_entries')
      .select(`
        id,
        experience_text,
        round_name,
        user_id,
        moderated_by,
        updated_at,
        company_id
      `)
      .eq('id', entryId)
      .eq('approval_status', 'approved')
      .single()

    if (entryErr || !entry) {
      return new Response(
        JSON.stringify({ error: 'Entry not found or not approved', detail: entryErr?.message }),
        { status: 404, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const sourceKey = `placement_log:${entryId}`
    const { data: existingArticle } = await supabase
      .from('knowledge_brain_articles')
      .select('id')
      .eq('source', sourceKey)
      .maybeSingle()
    if (existingArticle) {
      return new Response(
        JSON.stringify({ success: true, skipped: true, reason: 'Already ingested', article_id: existingArticle.id }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const [{ data: company }, { data: author }] = await Promise.all([
      supabase.from('companies').select('name,batch_id').eq('id', entry.company_id).single(),
      supabase.from('users').select('name').eq('id', entry.user_id).single(),
    ])

    // Step 2: Create knowledge_brain_articles row
    const articleTitle = `${author?.name ?? 'Student'}'s Experience at ${company?.name ?? 'Unknown Company'} — ${entry.round_name}`

    const summaryText = entry.experience_text.slice(0, 300).trim()
    const summary = summaryText.length === entry.experience_text.length
      ? summaryText
      : `${summaryText}...`

    const { data: batch } = await supabase
      .from('batches')
      .select('batch_code')
      .eq('id', company?.batch_id ?? '')
      .maybeSingle()

    const { data: article, error: articleErr } = await supabase
      .from('knowledge_brain_articles')
      .insert({
        title:                 articleTitle,
        content:               entry.experience_text,
        summary,
        author_id:             entry.user_id,
        source:                sourceKey,
        tags:                  ['placement', 'interview-experience', company?.name?.toLowerCase().replace(/\s+/g, '-') ?? 'unknown'].filter(Boolean),
        company_name:          company?.name ?? null,
        batch_year:            batch?.batch_code ?? null,
        approval_status:       'approved',
        reviewed_by:           entry.moderated_by,
        reviewed_at:           entry.updated_at ?? new Date().toISOString(),
      })
      .select('id')
      .single()

    if (articleErr || !article) {
      throw new Error(`Failed to create knowledge article: ${articleErr?.message}`)
    }

    // Step 3: Chunk the experience_text
    const chunks = chunkText(entry.experience_text, 500)

    // Step 4 + 5: Embed each chunk using Supabase native gte-small (384-dim, no API key needed)
    // @ts-ignore: Supabase.ai is available in Edge Function runtime
    const model = new Supabase.ai.Session('gte-small')

    let embeddedCount = 0
    for (let i = 0; i < chunks.length; i++) {
      try {
        const output = await model.run(chunks[i], { mean_pool: true, normalize: true })
        const embedding = Array.from(output as number[])

        const { error: embErr } = await supabase
          .from('knowledge_embeddings')
          .insert({
            article_id:  article.id,
            chunk_index: i,
            chunk_text:  chunks[i],
            embedding,
          })

        if (!embErr) embeddedCount++
        else console.error(`Chunk ${i} embedding insert error:`, embErr)
      } catch (embErr) {
        console.error(`Chunk ${i} embedding generation error:`, embErr)
      }
    }

    return new Response(
      JSON.stringify({
        success:        true,
        entry_id:       entryId,
        article_id:     article.id,
        chunks_total:   chunks.length,
        chunks_embedded: embeddedCount,
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    )

  } catch (err) {
    console.error('knowledge-ingest error:', err)
    return new Response(
      JSON.stringify({ error: 'Ingest failed', detail: String(err) }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})
