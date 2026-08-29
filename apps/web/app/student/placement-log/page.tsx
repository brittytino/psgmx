'use client'

import React from 'react'
import { BookOpenCheck, ChevronDown, Lightbulb, Plus, Search, ShieldCheck, Sparkles } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { getCurrentProfile } from '@/lib/current-profile'
import type { Database } from '@/../../supabase/types/database.types'

type Pattern = Database['public']['Tables']['interview_patterns']['Row']
type PatternType = Pattern['pattern_type']

const patternLabels: Record<PatternType, string> = {
  aptitude_screening: 'Aptitude screening',
  coding_round: 'Coding round',
  technical_deep_dive: 'Technical deep dive',
  fyp_discussion: 'FYP discussion',
  behavioural: 'Behavioural conversation',
  group_discussion: 'Group discussion',
  general: 'General interview pattern',
}

const emptyForm = {
  title: '',
  patternType: 'technical_deep_dive' as PatternType,
  historicalContext: '',
  preparationHelped: '',
  mistakes: '',
  themes: '',
  advice: '',
}

export default function InterviewPatternLibraryPage() {
  const supabase = React.useMemo(() => createClient(), [])
  const [patterns, setPatterns] = React.useState<Pattern[]>([])
  const [me, setMe] = React.useState<{ id: string; reg_no: string | null } | null>(null)
  const [isSenior, setIsSenior] = React.useState(false)
  const [query, setQuery] = React.useState('')
  const [showContribute, setShowContribute] = React.useState(false)
  const [form, setForm] = React.useState(emptyForm)
  const [loading, setLoading] = React.useState(true)
  const [busy, setBusy] = React.useState(false)
  const [error, setError] = React.useState('')
  const [message, setMessage] = React.useState('')

  const load = React.useCallback(async () => {
    setLoading(true)
    setError('')
    try {
      const profile = await getCurrentProfile(supabase)
      if (!profile) throw new Error('Your profile could not be loaded.')
      setMe({ id: profile.id, reg_no: profile.reg_no })
      const [patternsResult, batchResult] = await Promise.all([
        supabase.from('interview_patterns').select('*').eq('approval_status', 'approved').order('created_at', { ascending: false }),
        profile.batch_id
          ? supabase.from('batches').select('status').eq('id', profile.batch_id).maybeSingle()
          : Promise.resolve({ data: null, error: null }),
      ])
      if (patternsResult.error) throw patternsResult.error
      setPatterns(patternsResult.data ?? [])
      setIsSenior(batchResult.data?.status === 'active_senior')
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : 'Interview patterns could not be loaded.')
    } finally {
      setLoading(false)
    }
  }, [supabase])

  React.useEffect(() => { void load() }, [load])

  async function submitPattern(event: React.FormEvent) {
    event.preventDefault()
    if (!me || !isSenior) return
    setBusy(true)
    setError('')
    setMessage('')
    const themes = form.themes.split(',').map((item) => item.trim()).filter(Boolean)
    const { error: insertError } = await supabase.from('interview_patterns').insert({
      author_id: me.id,
      title: form.title.trim(),
      pattern_type: form.patternType,
      historical_context: form.historicalContext.trim() || null,
      preparation_helped: form.preparationHelped.trim(),
      mistakes: form.mistakes.trim() || null,
      example_themes: themes,
      advice: form.advice.trim(),
      batch_year: me.reg_no?.match(/^\d{2}MX/)?.[0] ?? null,
      approval_status: 'pending',
    })
    if (insertError) setError(insertError.message)
    else {
      setMessage('Your pattern was submitted for faculty review. It will appear here only after approval.')
      setForm(emptyForm)
      setShowContribute(false)
    }
    setBusy(false)
  }

  const normalizedQuery = query.trim().toLowerCase()
  const filtered = patterns.filter((pattern) => {
    if (!normalizedQuery) return true
    return `${pattern.title} ${patternLabels[pattern.pattern_type]} ${pattern.preparation_helped} ${pattern.advice} ${pattern.example_themes.join(' ')}`
      .toLowerCase().includes(normalizedQuery)
  })

  return <div className="mx-auto max-w-6xl space-y-6">
    <header className="flex flex-col gap-4 lg:flex-row lg:items-end lg:justify-between">
      <div>
        <div className="mb-2 flex items-center gap-2 text-xs font-black uppercase tracking-[.16em] text-primary-purple"><BookOpenCheck className="h-4 w-4"/> Learn from earlier MX batches</div>
        <h1 className="text-3xl font-black tracking-tight">Interview Pattern Library</h1>
        <p className="mt-2 max-w-2xl text-sm leading-6 text-text-muted">Reusable, faculty-reviewed preparation insight. Patterns help you practise; they are not official current drive information.</p>
      </div>
      {isSenior && <button onClick={() => setShowContribute((value) => !value)} className="inline-flex items-center justify-center gap-2 rounded-xl bg-primary-purple px-5 py-3 text-sm font-black text-white"><Plus className="h-4 w-4"/>{showContribute ? 'Close contribution' : 'Share a pattern'}</button>}
    </header>

    <div className="flex gap-3 rounded-2xl border border-amber-200 bg-amber-50 p-4 text-xs font-semibold leading-5 text-amber-900"><ShieldCheck className="mt-0.5 h-5 w-5 shrink-0"/><span>For eligibility, applications, shortlists and official placement-drive details, use NEO PAT. PSGMX intentionally does not maintain that information.</span></div>
    {error && <div role="alert" className="flex items-center justify-between rounded-2xl border border-red-200 bg-red-50 p-4 text-sm font-bold text-red-700"><span>{error}</span><button onClick={() => void load()} className="rounded-lg px-3 py-1.5 hover:bg-red-100">Retry</button></div>}
    {message && <div className="rounded-2xl border border-emerald-200 bg-emerald-50 p-4 text-sm font-bold text-emerald-800">{message}</div>}

    {showContribute && isSenior && <form onSubmit={submitPattern} className="grid gap-4 rounded-3xl border border-border-light bg-white p-6 shadow-sm md:grid-cols-2">
      <div className="md:col-span-2"><h2 className="text-lg font-black">Share reusable preparation insight</h2><p className="mt-1 text-xs text-text-muted">Do not include private interviewer details, confidential questions or current official drive claims.</p></div>
      <label className="text-xs font-bold text-text-muted">Pattern title<input required minLength={5} maxLength={160} value={form.title} onChange={(event) => setForm({ ...form, title: event.target.value })} placeholder="Explaining an MCA FYP under technical questioning" className="mt-2 w-full rounded-xl border border-border-light px-4 py-3 text-sm text-text-main outline-none focus:border-primary-purple"/></label>
      <label className="text-xs font-bold text-text-muted">Pattern type<select value={form.patternType} onChange={(event) => setForm({ ...form, patternType: event.target.value as PatternType })} className="mt-2 w-full rounded-xl border border-border-light px-4 py-3 text-sm text-text-main">{Object.entries(patternLabels).map(([value, label]) => <option key={value} value={value}>{label}</option>)}</select></label>
      <label className="text-xs font-bold text-text-muted md:col-span-2">Historical context (optional)<textarea value={form.historicalContext} onChange={(event) => setForm({ ...form, historicalContext: event.target.value })} placeholder="Enough context to understand the pattern, without presenting it as a current drive." className="mt-2 min-h-20 w-full rounded-xl border border-border-light px-4 py-3 text-sm text-text-main outline-none focus:border-primary-purple"/></label>
      <label className="text-xs font-bold text-text-muted">Preparation that helped<textarea required minLength={20} value={form.preparationHelped} onChange={(event) => setForm({ ...form, preparationHelped: event.target.value })} className="mt-2 min-h-28 w-full rounded-xl border border-border-light px-4 py-3 text-sm text-text-main outline-none focus:border-primary-purple"/></label>
      <label className="text-xs font-bold text-text-muted">Mistakes and lessons<textarea value={form.mistakes} onChange={(event) => setForm({ ...form, mistakes: event.target.value })} className="mt-2 min-h-28 w-full rounded-xl border border-border-light px-4 py-3 text-sm text-text-main outline-none focus:border-primary-purple"/></label>
      <label className="text-xs font-bold text-text-muted md:col-span-2">Example themes<input value={form.themes} onChange={(event) => setForm({ ...form, themes: event.target.value })} placeholder="normalization, trade-offs, testing" className="mt-2 w-full rounded-xl border border-border-light px-4 py-3 text-sm text-text-main outline-none focus:border-primary-purple"/></label>
      <label className="text-xs font-bold text-text-muted md:col-span-2">Advice for the next batch<textarea required minLength={20} value={form.advice} onChange={(event) => setForm({ ...form, advice: event.target.value })} className="mt-2 min-h-28 w-full rounded-xl border border-border-light px-4 py-3 text-sm text-text-main outline-none focus:border-primary-purple"/></label>
      <button disabled={busy} className="inline-flex items-center justify-center gap-2 rounded-xl bg-primary-purple px-5 py-3 text-sm font-black text-white disabled:opacity-50 md:col-span-2"><Sparkles className="h-4 w-4"/>{busy ? 'Submitting…' : 'Submit for faculty review'}</button>
    </form>}

    <label className="relative block"><Search className="absolute left-4 top-3.5 h-4 w-4 text-text-muted"/><input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Search a skill, round pattern or lesson" className="w-full rounded-2xl border border-border-light bg-white py-3 pl-11 pr-4 text-sm outline-none focus:border-primary-purple"/></label>

    {loading && <div className="grid gap-4 md:grid-cols-2">{[1,2,3,4].map((item) => <div key={item} className="h-44 animate-pulse rounded-3xl bg-white"/>)}</div>}
    {!loading && filtered.length === 0 && <div className="rounded-3xl border border-dashed border-border-light bg-white p-14 text-center"><Lightbulb className="mx-auto h-10 w-10 text-primary-purple"/><h2 className="mt-4 text-lg font-black">No reviewed pattern matches yet</h2><p className="mt-2 text-sm text-text-muted">Try a broader skill. New contributions appear only after faculty review.</p></div>}
    <div className="grid gap-4 md:grid-cols-2">{filtered.map((pattern) => <details key={pattern.id} className="group rounded-3xl border border-border-light bg-white p-6 shadow-sm open:md:col-span-2">
      <summary className="flex cursor-pointer list-none items-start gap-4"><div className="grid h-11 w-11 shrink-0 place-items-center rounded-2xl bg-primary-purple/10 text-primary-purple"><Lightbulb className="h-5 w-5"/></div><div className="min-w-0 flex-1"><span className="text-[10px] font-black uppercase tracking-[.14em] text-primary-purple">{patternLabels[pattern.pattern_type]}</span><h2 className="mt-1 text-lg font-black leading-6">{pattern.title}</h2><p className="mt-2 text-xs text-text-muted">{pattern.batch_year ?? 'MX community'} · Faculty reviewed</p></div><ChevronDown className="mt-2 h-5 w-5 text-text-muted transition group-open:rotate-180"/></summary>
      <div className="mt-6 grid gap-4 border-t border-border-light pt-5 lg:grid-cols-3"><Insight title="Preparation that helped" value={pattern.preparation_helped}/><Insight title="Mistakes and lessons" value={pattern.mistakes || 'No specific mistake was recorded.'}/><Insight title="Advice" value={pattern.advice}/></div>
      {pattern.example_themes.length > 0 && <div className="mt-5 flex flex-wrap gap-2">{pattern.example_themes.map((theme) => <span key={theme} className="rounded-lg bg-page-bg px-2.5 py-1.5 text-xs font-bold text-text-muted">{theme}</span>)}</div>}
    </details>)}</div>
  </div>
}

function Insight({ title, value }: { title: string; value: string }) {
  return <div className="rounded-2xl bg-page-bg p-4"><h3 className="text-xs font-black text-text-main">{title}</h3><p className="mt-2 whitespace-pre-wrap text-xs leading-5 text-text-muted">{value}</p></div>
}
