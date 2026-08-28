'use client'

import React from 'react'
import { BookOpen, Loader2, PenLine, Search } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { SubmitArticleModal } from '@/components/brain/SubmitArticleModal'

type Article = { id: string; title: string; summary: string | null; content: string; tags: string[]; company_name: string | null; batch_year: string | null; view_count: number; created_at: string; author_id: string }

export default function KnowledgeBrainPage() {
  const supabase = React.useMemo(() => createClient(), [])
  const [articles, setArticles] = React.useState<Article[]>([])
  const [authors, setAuthors] = React.useState<Map<string, string>>(new Map())
  const [query, setQuery] = React.useState('')
  const [expanded, setExpanded] = React.useState<string | null>(null)
  const [submitOpen, setSubmitOpen] = React.useState(false)
  const [loading, setLoading] = React.useState(true)
  const [error, setError] = React.useState('')

  const load = React.useCallback(async () => {
    setLoading(true)
    const { data, error: articleError } = await supabase.from('knowledge_brain_articles').select('id,title,summary,content,tags,company_name,batch_year,view_count,created_at,author_id').eq('approval_status', 'approved').order('created_at', { ascending: false }).limit(100)
    if (articleError) {
      setError(articleError.message)
      setLoading(false)
      return
    }
    const rows = data ?? []
    setArticles(rows)
    const ids = [...new Set(rows.map((row) => row.author_id))]
    if (ids.length) {
      const { data: users } = await supabase.from('users').select('id,name').in('id', ids)
      setAuthors(new Map((users ?? []).map((user) => [user.id, user.name])))
    }
    setLoading(false)
  }, [supabase])
  React.useEffect(() => { void load() }, [load])

  const filtered = articles.filter((article) => `${article.title} ${article.summary ?? ''} ${article.tags.join(' ')} ${article.company_name ?? ''} ${authors.get(article.author_id) ?? ''}`.toLowerCase().includes(query.toLowerCase()))
  if (loading) return <div className="flex min-h-64 items-center justify-center"><Loader2 className="h-6 w-6 animate-spin text-primary-purple"/></div>

  return <div className="mx-auto max-w-5xl space-y-7 pb-10">
    <div className="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between"><div><h1 className="flex items-center gap-2 text-2xl font-black"><BookOpen className="h-6 w-6 text-primary-purple"/>Knowledge Brain</h1><p className="mt-1 text-sm text-text-muted">{articles.length} faculty-approved contribution{articles.length === 1 ? '' : 's'} available.</p></div><button onClick={() => setSubmitOpen(true)} className="flex items-center justify-center gap-2 rounded-xl bg-primary-purple px-5 py-3 text-sm font-bold text-white"><PenLine className="h-4 w-4"/>Submit an article</button></div>
    <label className="relative block"><Search className="absolute left-4 top-3.5 h-4 w-4 text-text-muted"/><input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Search topics, companies, tags or authors" className="w-full rounded-2xl border border-border-light bg-white py-3 pl-11 pr-4 text-sm outline-none focus:border-primary-purple"/></label>
    {error && <div className="rounded-2xl border border-amber-200 bg-amber-50 p-5 text-sm font-bold">{error}<button onClick={load} className="ml-2 text-primary-purple">Retry</button></div>}
    {!error && filtered.length === 0 && <div className="rounded-3xl border border-dashed border-border-light bg-white p-14 text-center"><BookOpen className="mx-auto h-10 w-10 text-text-muted"/><h2 className="mt-4 font-black">{articles.length ? 'No article matches that search' : 'No approved articles yet'}</h2><p className="mt-2 text-sm text-text-muted">Contributions appear only after faculty review.</p></div>}
    <div className="grid gap-4 md:grid-cols-2">{filtered.map((article) => <button key={article.id} onClick={() => setExpanded((value) => value === article.id ? null : article.id)} className="rounded-2xl border border-border-light bg-white p-5 text-left hover:border-primary-purple/40"><div className="flex flex-wrap gap-2">{article.company_name && <span className="rounded-full bg-violet-50 px-2 py-1 text-[10px] font-black text-primary-purple">{article.company_name}</span>}{article.tags.slice(0, 3).map((tag) => <span key={tag} className="rounded-full bg-page-bg px-2 py-1 text-[10px] font-bold text-text-muted">{tag}</span>)}</div><h2 className="mt-3 text-lg font-black">{article.title}</h2><p className="mt-2 text-sm leading-6 text-text-muted">{expanded === article.id ? article.content : article.summary || article.content.slice(0, 180)}{expanded !== article.id && article.content.length > 180 ? '…' : ''}</p><p className="mt-4 text-xs font-bold text-text-muted">{authors.get(article.author_id) ?? 'PSGMX contributor'}{article.batch_year ? ` · ${article.batch_year}` : ''} · {article.view_count} views</p></button>)}</div>
    <SubmitArticleModal isOpen={submitOpen} onClose={() => setSubmitOpen(false)} onSuccess={() => { setSubmitOpen(false); void load() }}/>
  </div>
}
