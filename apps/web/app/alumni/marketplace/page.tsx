'use client'

import React from 'react'
import { BookOpenCheck, CalendarDays, Code2, HandHeart, Info, Plus, ShieldCheck, UsersRound, X } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { getCurrentProfile } from '@/lib/current-profile'
import type { Database } from '@/../../supabase/types/database.types'

type Post = Database['public']['Tables']['collaboration_posts']['Row']
type PostType = Exclude<Post['post_type'], 'job'>

const typeConfig: Record<PostType, { label: string; icon: React.ComponentType<{ className?: string }> }> = {
  project: { label: 'Project collaboration', icon: Code2 },
  mentorship: { label: 'Mentoring circle', icon: HandHeart },
  learning_event: { label: 'Learning event', icon: CalendarDays },
  career_information: { label: 'Career information', icon: BookOpenCheck },
  unofficial_opportunity: { label: 'Unofficial opportunity', icon: Info },
}

export default function CommunityBoardPage() {
  const supabase = React.useMemo(() => createClient(), [])
  const [posts, setPosts] = React.useState<Post[]>([])
  const [userId, setUserId] = React.useState('')
  const [showForm, setShowForm] = React.useState(false)
  const [type, setType] = React.useState<PostType>('project')
  const [title, setTitle] = React.useState('')
  const [description, setDescription] = React.useState('')
  const [visibility, setVisibility] = React.useState<Post['visibility']>('department')
  const [loading, setLoading] = React.useState(true)
  const [busy, setBusy] = React.useState(false)
  const [error, setError] = React.useState('')

  const load = React.useCallback(async () => {
    setLoading(true)
    setError('')
    try {
      const me = await getCurrentProfile(supabase)
      if (!me) throw new Error('Your alumni profile could not be loaded.')
      setUserId(me.id)
      const { data, error: loadError } = await supabase.from('collaboration_posts').select('*').eq('is_active', true).order('created_at', { ascending: false }).limit(50)
      if (loadError) throw loadError
      setPosts(data ?? [])
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : 'The Community Board could not be loaded.')
    } finally {
      setLoading(false)
    }
  }, [supabase])

  React.useEffect(() => { void load() }, [load])

  async function publish(event: React.FormEvent) {
    event.preventDefault()
    if (!userId) return
    setBusy(true)
    setError('')
    const { error: insertError } = await supabase.from('collaboration_posts').insert({
      posted_by: userId,
      post_type: type,
      title: title.trim(),
      description: description.trim(),
      visibility,
      is_active: true,
    })
    if (insertError) setError(insertError.message)
    else {
      setTitle(''); setDescription(''); setShowForm(false)
      await load()
    }
    setBusy(false)
  }

  async function deactivate(postId: string) {
    const { error: updateError } = await supabase.from('collaboration_posts').update({ is_active: false }).eq('id', postId).eq('posted_by', userId)
    if (updateError) return setError(updateError.message)
    setPosts((current) => current.filter((post) => post.id !== postId))
  }

  return <div className="mx-auto max-w-5xl space-y-6">
    <header className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between"><div><div className="mb-2 flex items-center gap-2 text-xs font-black uppercase tracking-[.16em] text-primary-purple"><UsersRound className="h-4 w-4"/> MX community</div><h1 className="text-3xl font-black tracking-tight">Community Board</h1><p className="mt-2 max-w-2xl text-sm leading-6 text-text-muted">Collaborate on projects, mentoring and learning. Every opportunity here is community information, not an official college placement drive.</p></div><button onClick={() => setShowForm((value) => !value)} className="inline-flex items-center justify-center gap-2 rounded-xl bg-primary-purple px-5 py-3 text-sm font-black text-white">{showForm ? <X className="h-4 w-4"/> : <Plus className="h-4 w-4"/>}{showForm ? 'Close' : 'Create community post'}</button></header>
    <div className="flex gap-3 rounded-2xl border border-amber-200 bg-amber-50 p-4 text-xs font-semibold leading-5 text-amber-900"><ShieldCheck className="mt-0.5 h-5 w-5 shrink-0"/><span>Use NEO PAT for official drives, eligibility, applications and shortlists. Verify unofficial opportunities independently before sharing personal information.</span></div>
    {error && <div role="alert" className="rounded-2xl border border-red-200 bg-red-50 p-4 text-sm font-bold text-red-700">{error}</div>}

    {showForm && <form onSubmit={publish} className="space-y-4 rounded-3xl border border-border-light bg-white p-6 shadow-sm"><div><h2 className="text-lg font-black">New community post</h2><p className="mt-1 text-xs text-text-muted">Be specific about the intended outcome, time commitment and who should respond.</p></div><div className="flex flex-wrap gap-2">{(Object.entries(typeConfig) as [PostType, (typeof typeConfig)[PostType]][]).map(([value, config]) => { const Icon = config.icon; return <button key={value} type="button" onClick={() => setType(value)} className={`inline-flex items-center gap-2 rounded-xl px-3 py-2 text-xs font-black ${type === value ? 'bg-primary-purple text-white' : 'bg-page-bg text-text-muted'}`}><Icon className="h-4 w-4"/>{config.label}</button> })}</div><label className="block text-xs font-bold text-text-muted">Title<input required minLength={5} value={title} onChange={(event) => setTitle(event.target.value)} className="mt-2 w-full rounded-xl border border-border-light px-4 py-3 text-sm outline-none focus:border-primary-purple"/></label><label className="block text-xs font-bold text-text-muted">Description<textarea required minLength={20} value={description} onChange={(event) => setDescription(event.target.value)} placeholder="Outcome, context, time commitment and safe response method" className="mt-2 min-h-28 w-full rounded-xl border border-border-light px-4 py-3 text-sm outline-none focus:border-primary-purple"/></label><label className="block text-xs font-bold text-text-muted">Visibility<select value={visibility} onChange={(event) => setVisibility(event.target.value as Post['visibility'])} className="mt-2 w-full rounded-xl border border-border-light px-4 py-3 text-sm"><option value="department">All MX batches</option><option value="batch">My batch</option><option value="lineage_only">My lineage</option></select></label><button disabled={busy} className="w-full rounded-xl bg-primary-purple px-5 py-3 text-sm font-black text-white disabled:opacity-50">{busy ? 'Publishing…' : 'Publish with community disclaimer'}</button></form>}

    {loading && <div className="grid gap-4 md:grid-cols-2">{[1,2,3,4].map((item) => <div key={item} className="h-48 animate-pulse rounded-3xl bg-white"/>)}</div>}
    {!loading && posts.length === 0 && <div className="rounded-3xl border border-dashed border-border-light bg-white p-14 text-center"><HandHeart className="mx-auto h-10 w-10 text-primary-purple"/><h2 className="mt-4 text-lg font-black">No active community post</h2><p className="mt-2 text-sm text-text-muted">Start a focused project, learning or mentoring collaboration.</p></div>}
    <div className="grid gap-4 md:grid-cols-2">{posts.map((post) => { const config = post.post_type === 'job' ? typeConfig.unofficial_opportunity : typeConfig[post.post_type]; const Icon = config.icon; return <article key={post.id} className="rounded-3xl border border-border-light bg-white p-6 shadow-sm"><div className="flex items-start justify-between gap-4"><div className="grid h-11 w-11 place-items-center rounded-2xl bg-primary-purple/10 text-primary-purple"><Icon className="h-5 w-5"/></div>{post.posted_by === userId && <button onClick={() => void deactivate(post.id)} title="Close post" className="rounded-lg p-2 text-text-muted hover:bg-page-bg hover:text-red-600"><X className="h-4 w-4"/></button>}</div><span className="mt-5 block text-[10px] font-black uppercase tracking-[.14em] text-primary-purple">{config.label} · {post.visibility.replace('_', ' ')}</span><h2 className="mt-2 text-lg font-black">{post.title}</h2><p className="mt-3 whitespace-pre-wrap text-sm leading-6 text-text-muted">{post.description}</p><div className="mt-5 rounded-xl bg-amber-50 p-3 text-[10px] font-semibold leading-4 text-amber-900">{post.disclaimer}</div><p className="mt-4 text-[10px] font-bold text-text-muted">Posted {new Date(post.created_at).toLocaleDateString('en-IN', { dateStyle: 'medium' })}</p></article>})}</div>
  </div>
}
