// ============================================================
// GET/PUT /api/faculty/pending-articles
// Migrated from MongoDB KnowledgeBrainArticle to Supabase.
// Faculty can fetch pending articles and approve/reject them.
// ============================================================
import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'
import { requireRole } from '@/lib/auth'

export async function GET(req: NextRequest) {
  try {
    const faculty = await requireRole(req, ['faculty', 'hod'])
    if (!faculty) {
      return NextResponse.json({ error: 'Unauthorized — faculty only' }, { status: 401 })
    }

    const supabase = await createClient()

    const { data: pendingArticles, error } = await supabase
      .from('knowledge_brain_articles')
      .select(`
        id,
        title,
        content,
        summary,
        author_id,
        source,
        tags,
        company_name,
        batch_year,
        approval_status,
        created_at,
        placement_log_entry_id
      `)
      .eq('approval_status', 'pending')
      .order('created_at', { ascending: true })  // Oldest first — FIFO review

    if (error) throw error

    return NextResponse.json({ success: true, pendingArticles })
  } catch (error) {
    console.error('Failed to fetch pending articles:', error)
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 })
  }
}

export async function PUT(req: NextRequest) {
  try {
    const faculty = await requireRole(req, ['faculty', 'hod'])
    if (!faculty) {
      return NextResponse.json({ error: 'Unauthorized — faculty only' }, { status: 401 })
    }

    const { articleId, action } = await req.json()

    if (!articleId || !['approve', 'reject'].includes(action)) {
      return NextResponse.json({ error: 'articleId and action (approve|reject) are required' }, { status: 400 })
    }

    const supabase = await createClient()

    const newStatus = action === 'approve' ? 'approved' : 'rejected'

    const { error } = await supabase
      .from('knowledge_brain_articles')
      // @ts-ignore
      .update({
        approval_status: newStatus,
        approved_by: faculty.id,
        approved_at: new Date().toISOString(),
      } as any)
      .eq('id', articleId)

    if (error) throw error

    // Send notification to article author if approved
    if (action === 'approve') {
      const { data: article } = await supabase
        .from('knowledge_brain_articles')
        .select('author_id, title')
        .eq('id', articleId)
        .single()

      if ((article as any)?.author_id) {
        await supabase.from('notifications')// @ts-ignore
      .insert({
          user_id: (article as any).author_id,
          type: 'article_approved',
          title: 'Your article was approved!',
          body: `"${(article as any).title}" has been approved and is now visible in the Knowledge Brain.`,
          reference_id: articleId,
          reference_type: 'knowledge_brain_article',
        } as any)
      }
    }

    return NextResponse.json({ success: true, message: `Article ${action}d successfully.` })
  } catch (error) {
    console.error('Failed to process article:', error)
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 })
  }
}
