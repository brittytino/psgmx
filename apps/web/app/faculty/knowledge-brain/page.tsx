'use client'

import React from 'react'
import { BookOpenCheck, CheckCircle2, Clock3, Search, ShieldCheck, XCircle } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { getCurrentProfile } from '@/lib/current-profile'

type QueueItem = {
  id: string
  source: 'article' | 'pattern'
  title: string
  summary: string
  content: string
  authorId: string
  status: string
  createdAt: string
  tags: string[]
}

export default function FacultyKnowledgeBrainPage() {
  const supabase = React.useMemo(() => createClient(), [])
  const [items, setItems] = React.useState<QueueItem[]>([])
  const [query, setQuery] = React.useState('')
  const [filter, setFilter] = React.useState('pending')
  const [loading, setLoading] = React.useState(true)
  const [busyId, setBusyId] = React.useState('')
  const [error, setError] = React.useState('')
  const [message, setMessage] = React.useState('')

  const load = React.useCallback(async () => {
    setLoading(true)
    setError('')
    try {
      const [articleResult, patternResult] = await Promise.all([
        supabase.from('knowledge_brain_articles').select('id,title,summary,content,author_id,approval_status,created_at,tags').order('created_at', { ascending: false }),
        supabase.from('interview_patterns').select('id,title,historical_context,preparation_helped,mistakes,advice,author_id,approval_status,created_at,pattern_type').order('created_at', { ascending: false }),
      ])
      if (articleResult.error) throw articleResult.error
      if (patternResult.error) throw patternResult.error
      const articles: QueueItem[] = (articleResult.data ?? []).map((item) => ({
        id: item.id, source: 'article', title: item.title,
        summary: item.summary ?? 'No summary provided.', content: item.content,
        authorId: item.author_id, status: item.approval_status,
        createdAt: item.created_at, tags: item.tags,
      }))
      const patterns: QueueItem[] = (patternResult.data ?? []).map((item) => ({
        id: item.id, source: 'pattern', title: item.title,
        summary: item.historical_context ?? 'Historical context not provided.',
        content: [`Preparation that helped: ${item.preparation_helped}`, item.mistakes ? `Mistakes: ${item.mistakes}` : '', `Advice: ${item.advice}`].filter(Boolean).join('\n\n'),
        authorId: item.author_id, status: item.approval_status,
        createdAt: item.created_at, tags: [item.pattern_type],
      }))
      setItems([...articles, ...patterns].sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()))
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : 'Knowledge review queue could not be loaded.')
    } finally {
      setLoading(false)
    }
  }, [supabase])

  React.useEffect(() => { void load() }, [load])

  async function review(item: QueueItem, decision: 'approved' | 'rejected') {
    setBusyId(item.id)
    setError('')
    setMessage('')
    try {
      const me = await getCurrentProfile(supabase)
      if (!me) throw new Error('Your faculty profile could not be loaded.')
      const reviewedAt = new Date().toISOString()
      const result = item.source === 'article'
        ? await supabase.from('knowledge_brain_articles').update({ approval_status: decision, reviewed_by: me.id, reviewed_at: reviewedAt, updated_at: reviewedAt }).eq('id', item.id)
        : await supabase.from('interview_patterns').update({ approval_status: decision, reviewed_by: me.id, reviewed_at: reviewedAt, updated_at: reviewedAt }).eq('id', item.id)
      if (result.error) throw result.error
      setItems((current) => current.map((value) => value.id === item.id && value.source === item.source ? { ...value, status: decision } : value))
      setMessage(decision === 'approved' ? 'Approved content is now eligible for student search and AI grounding.' : 'The contribution was rejected and remains visible in audit history.')
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : 'The review decision could not be saved.')
    } finally {
      setBusyId('')
    }
  }

  const filtered = items.filter((item) => {
    const matchesQuery = `${item.title} ${item.summary} ${item.content} ${item.tags.join(' ')}`.toLowerCase().includes(query.toLowerCase())
    const matchesFilter = filter === 'all' || item.status === filter
    return matchesQuery && matchesFilter
  })
  const pending = items.filter((item) => item.status === 'pending').length

  return <div className="mx-auto max-w-7xl space-y-6">
    <header className="flex flex-col gap-4 lg:flex-row lg:items-end lg:justify-between"><div><div className="mb-2 flex items-center gap-2 text-xs font-black uppercase tracking-[.16em] text-primary-purple"><BookOpenCheck className="h-4 w-4"/> Department intelligence</div><h1 className="text-3xl font-black tracking-tight">Knowledge Brain Review</h1><p className="mt-2 max-w-3xl text-sm leading-6 text-text-muted">Review articles and interview patterns before they reach students or ground AI Senior answers.</p></div><div className="rounded-2xl border border-border-light bg-white px-5 py-4 text-center shadow-sm"><div className="text-3xl font-black text-primary-purple">{pending}</div><div className="text-[10px] font-black uppercase tracking-wider text-text-muted">Awaiting review</div></div></header>
    <div className="flex gap-3 rounded-2xl border border-blue-200 bg-blue-50 p-4 text-xs font-semibold leading-5 text-blue-900"><ShieldCheck className="mt-0.5 h-5 w-5 shrink-0"/><span>Check privacy, usefulness, accuracy, historical context and whether claims could be mistaken for current official placement information.</span></div>
    {error && <div role="alert" className="rounded-2xl border border-red-200 bg-red-50 p-4 text-sm font-bold text-red-700">{error}</div>}
    {message && <div className="rounded-2xl border border-emerald-200 bg-emerald-50 p-4 text-sm font-bold text-emerald-800">{message}</div>}
    <div className="flex flex-col gap-3 rounded-2xl border border-border-light bg-white p-3 sm:flex-row"><label className="relative flex-1"><Search className="absolute left-3 top-3 h-4 w-4 text-text-muted"/><input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Search title, theme or claim" className="w-full rounded-xl bg-page-bg py-2.5 pl-10 pr-4 text-sm outline-none"/></label><select value={filter} onChange={(event) => setFilter(event.target.value)} className="rounded-xl border border-border-light px-4 py-2.5 text-sm font-bold"><option value="pending">Awaiting review</option><option value="approved">Approved</option><option value="rejected">Rejected</option><option value="all">All content</option></select></div>
    {loading && <div className="grid gap-4 lg:grid-cols-2">{[1,2,3,4].map((item) => <div key={item} className="h-56 animate-pulse rounded-3xl bg-white"/>)}</div>}
    {!loading && filtered.length === 0 && <div className="rounded-3xl border border-dashed border-border-light bg-white p-14 text-center"><CheckCircle2 className="mx-auto h-10 w-10 text-emerald-600"/><h2 className="mt-4 text-lg font-black">The selected queue is clear</h2><p className="mt-2 text-sm text-text-muted">New contributions appear here with their full review context.</p></div>}
    <div className="grid gap-4 lg:grid-cols-2">{filtered.map((item) => <article key={`${item.source}-${item.id}`} className="rounded-3xl border border-border-light bg-white p-6 shadow-sm"><div className="flex items-start justify-between gap-4"><div><span className="text-[10px] font-black uppercase tracking-[.14em] text-primary-purple">{item.source.replace('_', ' ')} · {item.status.replace('_', ' ')}</span><h2 className="mt-2 text-lg font-black">{item.title}</h2></div>{item.status === 'pending' ? <Clock3 className="h-6 w-6 text-amber-600"/> : item.status === 'approved' ? <CheckCircle2 className="h-6 w-6 text-emerald-600"/> : <XCircle className="h-6 w-6 text-red-600"/>}</div><p className="mt-3 text-sm leading-6 text-text-muted">{item.summary}</p><details className="mt-4 rounded-2xl bg-page-bg p-4"><summary className="cursor-pointer text-xs font-black">Review full content</summary><p className="mt-3 whitespace-pre-wrap text-xs leading-6 text-text-muted">{item.content}</p></details><div className="mt-4 flex flex-wrap gap-2">{item.tags.map((tag) => <span key={tag} className="rounded-lg bg-page-bg px-2.5 py-1.5 text-[10px] font-bold text-text-muted">{tag}</span>)}</div>{item.status === 'pending' && <div className="mt-5 flex justify-end gap-2"><button disabled={busyId === item.id} onClick={() => void review(item, 'rejected')} className="inline-flex items-center gap-1.5 rounded-xl border border-red-200 px-3 py-2 text-xs font-black text-red-700 disabled:opacity-50"><XCircle className="h-4 w-4"/>Reject</button><button disabled={busyId === item.id} onClick={() => void review(item, 'approved')} className="inline-flex items-center gap-1.5 rounded-xl bg-emerald-600 px-3 py-2 text-xs font-black text-white disabled:opacity-50"><CheckCircle2 className="h-4 w-4"/>Approve</button></div>}</article>)}</div>
  </div>
}
