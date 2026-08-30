'use client'

import React from 'react'
import { useSearchParams } from 'next/navigation'
import { BookOpen, Building2, Calendar, Copy, Loader2, PenLine, Search, X } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { SubmitArticleModal } from '@/components/brain/SubmitArticleModal'

type Article = { id: string; title: string; summary: string | null; content: string; tags: string[]; company_name: string | null; batch_year: string | null; view_count: number; created_at: string; author_id: string | null }

export default function KnowledgeBrainPage() {
  const supabase = React.useMemo(() => createClient(), [])
  const initialId = useSearchParams().get('id')
  const [articles, setArticles] = React.useState<Article[]>([])
  const [authors, setAuthors] = React.useState<Map<string, string>>(new Map())
  const [query, setQuery] = React.useState('')
  const [tag, setTag] = React.useState<string | null>(null)
  const [active, setActive] = React.useState<Article | null>(null)
  const [submitOpen, setSubmitOpen] = React.useState(false)
  const [loading, setLoading] = React.useState(true)
  const [error, setError] = React.useState('')

  const load = React.useCallback(async () => {
    setLoading(true); setError('')
    try {
      const { data, error: articleError } = await supabase.from('knowledge_brain_articles').select('id,title,summary,content,tags,company_name,batch_year,view_count,created_at,author_id').eq('approval_status', 'approved').order('created_at', { ascending: false }).limit(200)
      if (articleError) throw articleError
      const list = (data ?? []) as Article[]
      setArticles(list)
      const ids = [...new Set(list.map((row) => row.author_id).filter((id): id is string => Boolean(id)))]
      if (ids.length) {
        const { data: users, error: userError } = await supabase.from('users').select('id,name').in('id', ids)
        if (userError) throw userError
        setAuthors(new Map((users ?? []).map((user) => [user.id, user.name])))
      } else setAuthors(new Map())
      if (initialId) setActive(list.find((row) => row.id === initialId) ?? null)
    } catch (cause) { setError(cause instanceof Error ? cause.message : 'Knowledge Brain could not be loaded.'); setArticles([]) }
    finally { setLoading(false) }
  }, [initialId, supabase])
  React.useEffect(() => { void load() }, [load])

  const tags = React.useMemo(() => [...new Set(articles.flatMap((article) => article.tags ?? []))].sort(), [articles])
  const visible = React.useMemo(() => articles.filter((article) => {
    const text = `${article.title} ${article.summary ?? ''} ${article.company_name ?? ''} ${(article.tags ?? []).join(' ')}`.toLowerCase()
    return text.includes(query.toLowerCase()) && (!tag || article.tags.includes(tag))
  }), [articles, query, tag])
  if (loading) return <div className="grid min-h-64 place-items-center"><Loader2 className="h-6 w-6 animate-spin text-primary-purple" /></div>

  return <div className="mx-auto max-w-5xl space-y-7 pb-12">
    <header className="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between"><div><h1 className="flex items-center gap-2 text-2xl font-black"><BookOpen className="h-6 w-6 text-primary-purple" />Knowledge Brain</h1><p className="mt-1 text-sm text-text-muted">{articles.length} approved guides and alumni preparation records.</p></div><button onClick={() => setSubmitOpen(true)} className="inline-flex items-center justify-center gap-2 rounded-xl bg-primary-purple px-5 py-3 text-xs font-black text-white"><PenLine className="h-4 w-4" />Submit an article</button></header>
    {error && <div className="rounded-xl bg-red-50 p-4 text-sm font-bold text-red-700">{error} <button onClick={() => void load()} className="underline">Retry</button></div>}
    <div className="relative"><Search className="absolute left-4 top-3.5 h-4 w-4 text-text-muted" /><input value={query} onChange={(event) => setQuery(event.target.value)} className="w-full rounded-2xl border border-border-light bg-white py-3 pl-11 pr-4 text-sm outline-none focus:border-primary-purple" placeholder="Search approved knowledge…" /></div>
    <div className="flex flex-wrap gap-2"><button onClick={() => setTag(null)} className={`rounded-xl px-3 py-1.5 text-xs font-bold ${!tag ? 'bg-primary-purple text-white' : 'border border-border-light bg-white'}`}>All</button>{tags.map((value) => <button key={value} onClick={() => setTag(value)} className={`rounded-xl px-3 py-1.5 text-xs font-bold ${tag === value ? 'bg-primary-purple text-white' : 'border border-border-light bg-white'}`}>{value}</button>)}</div>
    <div className="grid gap-4 sm:grid-cols-2">{visible.map((article) => <button key={article.id} onClick={() => setActive(article)} className="rounded-3xl border border-border-light bg-white p-6 text-left shadow-sm transition hover:border-primary-purple/40"><div className="flex flex-wrap gap-2">{article.company_name && <span className="inline-flex items-center gap-1 rounded-full bg-violet-50 px-2 py-1 text-[10px] font-black text-primary-purple"><Building2 className="h-3 w-3" />{article.company_name}</span>}{article.batch_year && <span className="rounded-full bg-page-bg px-2 py-1 text-[10px] font-black">{article.batch_year}</span>}</div><h2 className="mt-3 text-base font-black leading-6">{article.title}</h2><p className="mt-2 line-clamp-3 text-xs leading-5 text-text-muted">{article.summary || article.content}</p><p className="mt-4 text-[11px] font-bold text-text-muted">{article.author_id ? authors.get(article.author_id) || 'Verified contributor' : 'PSGMX archive'} · {new Intl.DateTimeFormat('en-IN', { dateStyle: 'medium' }).format(new Date(article.created_at))}</p></button>)}{!visible.length && <div className="col-span-full rounded-3xl border border-dashed border-border-light bg-white p-10 text-center text-sm text-text-muted">No approved article matches this view.</div>}</div>
    {active && <div className="fixed inset-0 z-50 overflow-y-auto bg-slate-950/50 p-4 sm:p-8"><article className="mx-auto max-w-3xl rounded-3xl bg-white p-6 shadow-2xl sm:p-9"><div className="flex justify-between gap-4"><div><h2 className="text-2xl font-black">{active.title}</h2><p className="mt-2 flex items-center gap-1 text-xs text-text-muted"><Calendar className="h-3.5 w-3.5" />{new Intl.DateTimeFormat('en-IN', { dateStyle: 'medium' }).format(new Date(active.created_at))}</p></div><button onClick={() => setActive(null)} aria-label="Close"><X className="h-5 w-5" /></button></div><div className="mt-6 whitespace-pre-wrap text-sm leading-7 text-text-main">{active.content}</div><button onClick={() => void navigator.clipboard.writeText(`${window.location.origin}/student/knowledge-brain?id=${active.id}`)} className="mt-7 inline-flex items-center gap-2 rounded-xl border border-border-light px-4 py-2 text-xs font-black"><Copy className="h-4 w-4" />Copy link</button></article></div>}
    <SubmitArticleModal isOpen={submitOpen} onClose={() => setSubmitOpen(false)} onSuccess={() => void load()} />
  </div>
}
