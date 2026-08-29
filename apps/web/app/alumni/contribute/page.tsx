'use client'

import React from 'react'
import { CheckCircle2, Clock3, FilePenLine, PenLine, Send, ShieldCheck } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { getCurrentProfile } from '@/lib/current-profile'

type Submission = { id: string; title: string; kind: string; status: string; updatedAt: string }
type Mode = 'interview_pattern' | 'technical_guide' | 'career_transition' | 'fyp_lesson' | 'communication_advice'

const modeLabels: Record<Mode, string> = {
  interview_pattern: 'Interview pattern',
  technical_guide: 'Technical guide',
  career_transition: 'Career transition',
  fyp_lesson: 'FYP lesson',
  communication_advice: 'Communication advice',
}

export default function AlumniContributePage() {
  const supabase = React.useMemo(() => createClient(), [])
  const [submissions, setSubmissions] = React.useState<Submission[]>([])
  const [mode, setMode] = React.useState<Mode>('interview_pattern')
  const [title, setTitle] = React.useState('')
  const [context, setContext] = React.useState('')
  const [helped, setHelped] = React.useState('')
  const [mistakes, setMistakes] = React.useState('')
  const [advice, setAdvice] = React.useState('')
  const [themes, setThemes] = React.useState('')
  const [loading, setLoading] = React.useState(true)
  const [busy, setBusy] = React.useState(false)
  const [error, setError] = React.useState('')
  const [message, setMessage] = React.useState('')

  const load = React.useCallback(async () => {
    setLoading(true)
    setError('')
    try {
      const me = await getCurrentProfile(supabase)
      if (!me) throw new Error('Your alumni profile could not be loaded.')
      const [patternResult, articleResult] = await Promise.all([
        supabase.from('interview_patterns').select('id,title,approval_status,updated_at').eq('author_id', me.id).order('updated_at', { ascending: false }),
        supabase.from('knowledge_brain_articles').select('id,title,approval_status,updated_at,source').eq('author_id', me.id).order('updated_at', { ascending: false }),
      ])
      if (patternResult.error) throw patternResult.error
      if (articleResult.error) throw articleResult.error
      setSubmissions([
        ...(patternResult.data ?? []).map((item) => ({ id: item.id, title: item.title, kind: 'Interview pattern', status: item.approval_status, updatedAt: item.updated_at })),
        ...(articleResult.data ?? []).filter((item) => !item.source?.startsWith('interview_pattern:')).map((item) => ({ id: item.id, title: item.title, kind: 'Knowledge contribution', status: item.approval_status, updatedAt: item.updated_at })),
      ].sort((a, b) => new Date(b.updatedAt).getTime() - new Date(a.updatedAt).getTime()))
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : 'Your contributions could not be loaded.')
    } finally {
      setLoading(false)
    }
  }, [supabase])

  React.useEffect(() => { void load() }, [load])

  async function submit(event: React.FormEvent) {
    event.preventDefault()
    setBusy(true)
    setError('')
    setMessage('')
    try {
      const me = await getCurrentProfile(supabase)
      if (!me) throw new Error('Your alumni profile could not be loaded.')
      const batchYear = me.reg_no?.match(/^\d{2}MX/)?.[0] ?? null
      if (mode === 'interview_pattern') {
        const { error: submitError } = await supabase.from('interview_patterns').insert({
          author_id: me.id,
          title: title.trim(),
          pattern_type: 'general',
          historical_context: context.trim() || null,
          preparation_helped: helped.trim(),
          mistakes: mistakes.trim() || null,
          example_themes: themes.split(',').map((item) => item.trim()).filter(Boolean),
          advice: advice.trim(),
          batch_year: batchYear,
          approval_status: 'pending',
        })
        if (submitError) throw submitError
      } else {
        const content = [context, helped && `What helped\n${helped}`, mistakes && `Mistakes and lessons\n${mistakes}`, advice && `Advice\n${advice}`].filter(Boolean).join('\n\n')
        const { error: submitError } = await supabase.from('knowledge_brain_articles').insert({
          author_id: me.id,
          title: title.trim(),
          summary: advice.trim().slice(0, 300) || context.trim().slice(0, 300),
          content,
          tags: [mode, ...themes.split(',').map((item) => item.trim()).filter(Boolean)],
          source: 'alumni_contribution',
          batch_year: batchYear,
          approval_status: 'pending',
        })
        if (submitError) throw submitError
      }
      setTitle(''); setContext(''); setHelped(''); setMistakes(''); setAdvice(''); setThemes('')
      setMessage('Contribution submitted for faculty review. You can follow its status below.')
      await load()
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : 'Your contribution could not be submitted.')
    } finally {
      setBusy(false)
    }
  }

  return <div className="mx-auto max-w-6xl space-y-6">
    <header><div className="mb-2 flex items-center gap-2 text-xs font-black uppercase tracking-[.16em] text-primary-purple"><PenLine className="h-4 w-4"/> Leave MX stronger</div><h1 className="text-3xl font-black tracking-tight">Contribute knowledge</h1><p className="mt-2 max-w-3xl text-sm leading-6 text-text-muted">Turn lived experience into a reviewed, reusable resource for juniors. Draft intentionally; impact is measured by resolved questions, not vanity views.</p></header>
    <div className="flex gap-3 rounded-2xl border border-amber-200 bg-amber-50 p-4 text-xs font-semibold leading-5 text-amber-900"><ShieldCheck className="mt-0.5 h-5 w-5 shrink-0"/><span>Do not include confidential questions, private interviewer information or claims about current official drives. NEO PAT remains the official placement system.</span></div>
    {error && <div role="alert" className="rounded-2xl border border-red-200 bg-red-50 p-4 text-sm font-bold text-red-700">{error}</div>}
    {message && <div className="rounded-2xl border border-emerald-200 bg-emerald-50 p-4 text-sm font-bold text-emerald-800">{message}</div>}

    <div className="grid gap-6 xl:grid-cols-[1.25fr_.75fr]">
      <form onSubmit={submit} className="space-y-5 rounded-3xl border border-border-light bg-white p-6 shadow-sm">
        <div><h2 className="text-lg font-black">Guided contribution</h2><p className="mt-1 text-xs text-text-muted">A clear structure makes your experience useful years later.</p></div>
        <div className="flex flex-wrap gap-2">{(Object.keys(modeLabels) as Mode[]).map((value) => <button key={value} type="button" onClick={() => setMode(value)} className={`rounded-xl px-3 py-2 text-xs font-black transition ${mode === value ? 'bg-primary-purple text-white' : 'bg-page-bg text-text-muted hover:text-text-main'}`}>{modeLabels[value]}</button>)}</div>
        <label className="block text-xs font-bold text-text-muted">Title<input required minLength={5} maxLength={160} value={title} onChange={(event) => setTitle(event.target.value)} placeholder="A title a junior would search for" className="mt-2 w-full rounded-xl border border-border-light px-4 py-3 text-sm outline-none focus:border-primary-purple"/></label>
        <label className="block text-xs font-bold text-text-muted">Historical context<textarea value={context} onChange={(event) => setContext(event.target.value)} placeholder="When and why was this lesson relevant?" className="mt-2 min-h-24 w-full rounded-xl border border-border-light px-4 py-3 text-sm outline-none focus:border-primary-purple"/></label>
        <div className="grid gap-4 md:grid-cols-2"><label className="text-xs font-bold text-text-muted">What preparation helped<textarea required minLength={20} value={helped} onChange={(event) => setHelped(event.target.value)} className="mt-2 min-h-32 w-full rounded-xl border border-border-light px-4 py-3 text-sm outline-none focus:border-primary-purple"/></label><label className="text-xs font-bold text-text-muted">Mistakes and lessons<textarea value={mistakes} onChange={(event) => setMistakes(event.target.value)} className="mt-2 min-h-32 w-full rounded-xl border border-border-light px-4 py-3 text-sm outline-none focus:border-primary-purple"/></label></div>
        <label className="block text-xs font-bold text-text-muted">Advice for a junior<textarea required minLength={20} value={advice} onChange={(event) => setAdvice(event.target.value)} className="mt-2 min-h-28 w-full rounded-xl border border-border-light px-4 py-3 text-sm outline-none focus:border-primary-purple"/></label>
        <label className="block text-xs font-bold text-text-muted">Search themes<input value={themes} onChange={(event) => setThemes(event.target.value)} placeholder="DBMS, FYP explanation, communication" className="mt-2 w-full rounded-xl border border-border-light px-4 py-3 text-sm outline-none focus:border-primary-purple"/></label>
        <button disabled={busy} className="flex w-full items-center justify-center gap-2 rounded-xl bg-primary-purple px-5 py-3 text-sm font-black text-white disabled:opacity-50"><Send className="h-4 w-4"/>{busy ? 'Submitting…' : 'Submit for faculty review'}</button>
      </form>

      <section className="space-y-4"><div><h2 className="text-lg font-black">Your review queue</h2><p className="mt-1 text-xs text-text-muted">Pending, change-requested and approved work stays visible.</p></div>{loading && <div className="h-40 animate-pulse rounded-3xl bg-white"/>}{!loading && submissions.length === 0 && <div className="rounded-3xl border border-dashed border-border-light bg-white p-10 text-center"><FilePenLine className="mx-auto h-9 w-9 text-primary-purple"/><h3 className="mt-4 font-black">No contribution yet</h3><p className="mt-2 text-xs leading-5 text-text-muted">Your first reviewed contribution can answer a question future batches have not asked yet.</p></div>}{submissions.map((item) => <article key={`${item.kind}-${item.id}`} className="rounded-2xl border border-border-light bg-white p-5 shadow-sm"><div className="flex items-start gap-3">{item.status === 'approved' ? <CheckCircle2 className="mt-0.5 h-5 w-5 text-emerald-600"/> : <Clock3 className="mt-0.5 h-5 w-5 text-amber-600"/>}<div><span className="text-[10px] font-black uppercase tracking-wider text-text-muted">{item.kind} · {item.status.replace('_', ' ')}</span><h3 className="mt-1 text-sm font-black">{item.title}</h3><p className="mt-2 text-[10px] text-text-muted">Updated {new Date(item.updatedAt).toLocaleDateString('en-IN', { dateStyle: 'medium' })}</p></div></div></article>)}</section>
    </div>
  </div>
}
