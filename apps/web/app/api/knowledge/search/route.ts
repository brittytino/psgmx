import { NextRequest, NextResponse } from 'next/server'
import { getUserFromRequest } from '@/lib/auth'
import { createClient } from '@/lib/supabase/server'

type ArticleRow = {
  id: string
  title: string
  summary: string | null
  tags: string[] | null
  source: string | null
  created_at: string
  users: { name: string; avatar_url: string | null; role_label: string } | null
}

export async function GET(request: NextRequest) {
  try {
    const session = await getUserFromRequest(request)
    if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

    const rawQuery = request.nextUrl.searchParams.get('q')?.trim() ?? ''
    if (!rawQuery) return NextResponse.json({ articles: [] })
    const query = rawQuery.slice(0, 80).replace(/[,%()]/g, ' ').replace(/\s+/g, ' ').trim()
    if (query.length < 2) return NextResponse.json({ articles: [] })

    const supabase = await createClient()
    const select = 'id,title,summary,tags,source,created_at,users!author_id(name,avatar_url,role_label)'
    const [titleResult, summaryResult] = await Promise.all([
      supabase.from('knowledge_brain_articles').select(select).eq('approval_status', 'approved').ilike('title', `%${query}%`).order('created_at', { ascending: false }).limit(20),
      supabase.from('knowledge_brain_articles').select(select).eq('approval_status', 'approved').ilike('summary', `%${query}%`).order('created_at', { ascending: false }).limit(20),
    ])
    if (titleResult.error || summaryResult.error) throw titleResult.error || summaryResult.error

    const unique = new Map<string, ArticleRow>()
    for (const row of [...(titleResult.data ?? []), ...(summaryResult.data ?? [])] as unknown as ArticleRow[]) {
      if (!unique.has(row.id)) unique.set(row.id, row)
      if (unique.size === 20) break
    }

    const articles = [...unique.values()].map((item) => ({
      id: item.id,
      title: item.title,
      summary: item.summary,
      tags: item.tags || [],
      source: item.source,
      createdAt: item.created_at,
      author: item.users ? {
        name: item.users.name,
        avatar: item.users.avatar_url,
        role: item.users.role_label,
      } : null,
    }))
    return NextResponse.json({ articles })
  } catch (error) {
    console.error('[GET /api/knowledge/search]', error)
    return NextResponse.json({ error: 'Search is temporarily unavailable.' }, { status: 500 })
  }
}
