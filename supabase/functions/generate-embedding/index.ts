// ============================================================
// PSGMX — supabase/functions/generate-embedding/index.ts
// Lightweight Edge Function: generates a gte-small (384-dim)
// embedding for a text string. Called from Next.js API routes
// that need semantic search capability outside Edge runtime.
// ============================================================

Deno.serve(async (req: Request) => {
  if (req.method !== 'POST') {
    return new Response('Method Not Allowed', { status: 405 })
  }

  let text: string
  try {
    const body = await req.json()
    text = body.text
    if (!text || typeof text !== 'string') throw new Error('text is required')
    if (text.length > 2000) text = text.slice(0, 2000)  // cap for performance
  } catch (err) {
    return new Response(JSON.stringify({ error: 'Invalid request', detail: String(err) }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  try {
    // @ts-ignore: Supabase.ai available in Edge Function runtime
    const model = new Supabase.ai.Session('gte-small')
    const output = await model.run(text, { mean_pool: true, normalize: true })
    const embedding = Array.from(output as number[])

    return new Response(
      JSON.stringify({ embedding, dimension: embedding.length }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    )
  } catch (err) {
    console.error('generate-embedding error:', err)
    return new Response(
      JSON.stringify({ error: 'Embedding generation failed', detail: String(err) }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})
