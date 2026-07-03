// ============================================================
// GET/POST /api/brain
// Knowledge Brain articles — migrated from MongoDB KnowledgeBrainArticle
// to Supabase knowledge_brain_articles table.
// ============================================================
import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'
import { getUserFromRequest } from '@/lib/auth'

export async function GET(req: NextRequest) {
  try {
    const session = await getUserFromRequest(req)
    if (!session) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const { searchParams } = new URL(req.url)
    const query = searchParams.get('q')
    const tag = searchParams.get('tag')
    const company = searchParams.get('company')
    const limit = Math.min(parseInt(searchParams.get('limit') ?? '50'), 100)

    const supabase = await createClient()

    let dbQuery = supabase
      .from('knowledge_brain_articles')
      .select('id, title, summary, author_id, tags, company_name, batch_year, view_count, created_at, approval_status')
      .eq('approval_status', 'approved')
      .order('created_at', { ascending: false })
      .limit(limit)

    if (tag) {
      dbQuery = dbQuery.contains('tags', [tag])
    }

    if (company) {
      dbQuery = dbQuery.ilike('company_name', `%${company}%`)
    }

    if (query) {
      // Text search — falls back to ilike on title/summary until tsvector index is added
      dbQuery = dbQuery.or(`title.ilike.%${query}%,summary.ilike.%${query}%`)
    }

    const { data: articles, error } = await dbQuery

    if (error) throw error

    return NextResponse.json({ success: true, articles })
  } catch (error) {
    console.error('Brain GET error:', error)
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 })
  }
}

export async function POST(req: NextRequest) {
  try {
    const session = await getUserFromRequest(req)
    if (!session || !['student', 'alumni'].includes(session.role)) {
      return NextResponse.json({ error: 'Unauthorized — students and alumni only' }, { status: 401 })
    }

    const body = await req.json()
    const { title, content, tags, company_name, is_anonymous } = body

    if (!title || !content) {
      return NextResponse.json({ error: 'title and content are required' }, { status: 400 })
    }

    const supabase = await createClient()

    const { data: article, error } = await supabase
      .from('knowledge_brain_articles')
      .insert({
        title,
        content,
        author_id: is_anonymous ? null : session.id,
        tags: tags ?? [],
        company_name: company_name ?? null,
        approval_status: 'pending',
        source: 'web',
      })
      .select('id, title, approval_status')
      .single()

    if (error) throw error

    return NextResponse.json({ success: true, article })
  } catch (error) {
    console.error('Brain POST error:', error)
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 })
  }
}
