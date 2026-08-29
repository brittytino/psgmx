'use client'

import React from 'react'
import Link from 'next/link'
import { ArrowRight, Award, CalendarCheck2, CheckSquare2, Code2, Loader2, Target } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { getCurrentProfile } from '@/lib/current-profile'

type Snapshot = { score: number; computed_at: string; components_json: Record<string, unknown> }
type Dimension = { dimension: string; score: number; confidence: string; evidence_count: number; evidence_fresh_at: string | null }

const dimensionLabels: Record<string, string> = {
  aptitude_reasoning: 'Aptitude & reasoning', coding_problem_solving: 'Coding problem solving',
  core_computer_science: 'Core computer science', communication_interview: 'Communication & interview',
  assessment_performance: 'Assessment performance', portfolio_project: 'Portfolio & project proof',
}

const components = [
  { key: 'placement_attendance_pct', label: 'Preparation participation', weight: 30, icon: CalendarCheck2, action: 'Join the next preparation session' },
  { key: 'daily_five_adherence_pct', label: 'Daily Five consistency', weight: 20, icon: Target, action: 'Complete today’s five questions' },
  { key: 'task_completion_rate_pct', label: 'Quest completion', weight: 20, icon: CheckSquare2, action: 'Finish your current preparation quest' },
  { key: 'daily_five_accuracy_pct', label: 'Daily Five accuracy', weight: 15, icon: Award, action: 'Review explanations after each attempt' },
  { key: 'leetcode_momentum_percentile', label: 'LeetCode momentum', weight: 15, icon: Code2, action: 'Solve one useful problem today' },
]

function numeric(value: unknown) {
  const parsed = Number(value)
  return Number.isFinite(parsed) ? Math.max(0, Math.min(100, parsed)) : 0
}

function band(score: number) {
  if (score >= 80) return { label: 'Strong', color: 'text-emerald-700', message: 'Keep the rhythm. Consistency is now your advantage.' }
  if (score >= 60) return { label: 'Building', color: 'text-amber-700', message: 'You have momentum. Improve the lowest input next.' }
  if (score >= 40) return { label: 'Needs attention', color: 'text-orange-700', message: 'A small daily recovery plan can move this quickly.' }
  return { label: 'At risk', color: 'text-red-700', message: 'Start with one action today and ask your mentor for support.' }
}

export default function ReadinessPage() {
  const supabase = React.useMemo(() => createClient(), [])
  const [snapshot, setSnapshot] = React.useState<Snapshot | null>(null)
  const [history, setHistory] = React.useState<Snapshot[]>([])
  const [dimensions, setDimensions] = React.useState<Dimension[]>([])
  const [batchCode, setBatchCode] = React.useState('MCA')
  const [loading, setLoading] = React.useState(true)
  const [error, setError] = React.useState('')

  const load = React.useCallback(async () => {
    setLoading(true)
    setError('')
    try {
      const me = await getCurrentProfile(supabase)
      if (!me) throw new Error('Your student profile is unavailable.')
      const [{ data: current, error: currentError }, { data: trend, error: trendError }, { data: dimensionRows, error: dimensionError }] = await Promise.all([
        supabase.from('current_readiness_scores').select('score,computed_at,components_json').eq('user_id', me.id).maybeSingle(),
        supabase.from('readiness_scores').select('score,computed_at,components_json').eq('user_id', me.id).order('computed_at', { ascending: false }).limit(12),
        supabase.from('readiness_dimension_scores').select('dimension,score,confidence,evidence_count,evidence_fresh_at').eq('user_id', me.id).eq('algorithm_version', 'v2').order('dimension'),
      ])
      if (currentError || trendError || dimensionError) throw currentError ?? trendError ?? dimensionError
      setSnapshot(current as Snapshot | null)
      setHistory(((trend ?? []) as Snapshot[]).reverse())
      setDimensions((dimensionRows ?? []) as Dimension[])
      if (me.batch_id) {
        const { data: batchRow } = await supabase.from('batches').select('batch_code').eq('id', me.batch_id).single()
        setBatchCode(batchRow?.batch_code ?? 'MCA')
      }
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : 'Readiness could not be loaded.')
    } finally {
      setLoading(false)
    }
  }, [supabase])

  React.useEffect(() => { void load() }, [load])

  if (loading) return <div className="flex min-h-64 items-center justify-center"><Loader2 className="h-6 w-6 animate-spin text-primary-purple"/></div>
  if (error) return <div className="mx-auto max-w-3xl rounded-2xl border border-amber-200 bg-amber-50 p-6"><h1 className="font-black">Readiness is temporarily unavailable</h1><p className="mt-2 text-sm">{error}</p><button onClick={load} className="mt-4 font-black text-primary-purple">Try again</button></div>
  if (!snapshot) return <div className="mx-auto max-w-3xl space-y-5 rounded-3xl border border-dashed border-border-light bg-white p-10 text-center"><Award className="mx-auto h-12 w-12 text-primary-purple"/><h1 className="text-2xl font-black">Your score starts with real activity</h1><p className="mx-auto max-w-xl text-sm leading-6 text-text-muted">Complete Daily Five, finish a quest, connect LeetCode and join a preparation session. The engine will then create your first honest readiness snapshot.</p><Link href="/student" className="inline-flex items-center gap-2 rounded-xl bg-primary-purple px-5 py-3 text-sm font-bold text-white">Start today’s loop<ArrowRight className="h-4 w-4"/></Link></div>

  const score = Math.round(Number(snapshot.score))
  const currentBand = band(score)
  const values = components.map((item) => ({ ...item, value: numeric(snapshot.components_json?.[item.key]) }))
  const focus = [...values].sort((a, b) => a.value - b.value)[0]
  const previous = history.length > 1 ? Number(history.at(-2)?.score ?? score) : score
  const change = Math.round(score - previous)

  return <div className="mx-auto max-w-6xl space-y-7 pb-10">
    <div><h1 className="flex items-center gap-2 text-2xl font-black"><Award className="h-6 w-6 text-primary-purple"/>Readiness story</h1><p className="mt-1 text-sm text-text-muted">A transparent score built from real preparation evidence—not a prediction or a label.</p></div>

    <section className="grid gap-5 rounded-3xl border border-border-light bg-white p-6 md:grid-cols-[220px_1fr] md:p-8"><div className="flex h-48 w-48 flex-col items-center justify-center justify-self-center rounded-full border-[14px] border-violet-100 bg-page-bg"><p className="text-5xl font-black">{score}</p><p className="text-xs font-black text-text-muted">OUT OF 100</p></div><div className="flex flex-col justify-center"><p className="text-xs font-black uppercase tracking-[0.18em] text-text-muted">{batchCode} · Updated {new Intl.DateTimeFormat('en-IN', { dateStyle: 'medium' }).format(new Date(snapshot.computed_at))}</p><h2 className={`mt-2 text-4xl font-black ${currentBand.color}`}>{currentBand.label}</h2><p className="mt-2 max-w-xl text-sm leading-6 text-text-muted">{currentBand.message}</p><div className="mt-5 rounded-2xl bg-page-bg p-4"><p className="text-xs font-black uppercase text-text-muted">Best next move</p><p className="mt-1 font-black">{focus.action}</p><p className="mt-1 text-xs text-text-muted">{focus.label} is currently your clearest growth opportunity.</p></div><p className="mt-4 text-xs font-bold text-text-muted">{change === 0 ? 'No change since your previous snapshot.' : `${change > 0 ? '+' : ''}${change} points since your previous snapshot.`}</p></div></section>

    <section><h2 className="font-black">Readiness dimensions</h2><p className="mt-1 text-sm text-text-muted">Evidence count and freshness are shown openly. A dimension with no evidence is not treated as a weakness.</p><div className="mt-4 grid gap-3 md:grid-cols-2 lg:grid-cols-3">{dimensions.map((item) => <article key={item.dimension} className="rounded-2xl border border-border-light bg-white p-5"><div className="flex items-start justify-between gap-3"><h3 className="text-sm font-black">{dimensionLabels[item.dimension] ?? item.dimension}</h3><span className={`rounded-full px-2 py-1 text-[9px] font-black uppercase ${item.evidence_count === 0 ? 'bg-slate-100 text-slate-600' : item.confidence === 'high' ? 'bg-emerald-50 text-emerald-700' : 'bg-amber-50 text-amber-700'}`}>{item.evidence_count === 0 ? 'Not measured' : `${item.confidence} confidence`}</span></div>{item.evidence_count > 0 ? <><p className="mt-4 text-3xl font-black">{Math.round(item.score)}<span className="text-sm text-text-muted">/100</span></p><p className="mt-2 text-xs text-text-muted">{item.evidence_count} evidence source{item.evidence_count === 1 ? '' : 's'} · {item.evidence_fresh_at ? `fresh ${new Intl.DateTimeFormat('en-IN', { dateStyle: 'medium' }).format(new Date(item.evidence_fresh_at))}` : 'freshness unavailable'}</p></> : <p className="mt-4 text-sm leading-6 text-text-muted">Complete a relevant assessed activity before this dimension receives a score.</p>}</article>)}</div></section>

    <section><h2 className="font-black">What shapes the score</h2><p className="mt-1 text-sm text-text-muted">Every component is shown with its exact weight.</p><div className="mt-4 grid gap-3 md:grid-cols-2">{values.map((item) => <div key={item.key} className="rounded-2xl border border-border-light bg-white p-5"><div className="flex items-center gap-3"><div className="flex h-10 w-10 items-center justify-center rounded-xl bg-violet-50"><item.icon className="h-5 w-5 text-primary-purple"/></div><div className="flex-1"><div className="flex items-center justify-between gap-3"><p className="text-sm font-black">{item.label}</p><p className="text-sm font-black">{Math.round(item.value)}%</p></div><p className="text-xs text-text-muted">{item.weight}% of overall readiness</p></div></div><div className="mt-4 h-2 overflow-hidden rounded-full bg-page-bg"><div className="h-full rounded-full bg-primary-purple" style={{ width: `${item.value}%` }}/></div><p className="mt-3 text-xs text-text-muted">{item.action}</p></div>)}</div></section>

    {history.length > 1 && <section className="rounded-3xl border border-border-light bg-white p-6"><h2 className="font-black">Recent direction</h2><p className="mt-1 text-sm text-text-muted">Your latest {history.length} computed snapshots.</p><div className="mt-6 flex h-36 items-end gap-2">{history.map((item) => <div key={item.computed_at} className="group flex min-w-0 flex-1 flex-col items-center justify-end gap-2"><span className="text-[10px] font-bold opacity-0 group-hover:opacity-100">{Math.round(item.score)}</span><div className="w-full rounded-t-lg bg-primary-purple/80" style={{ height: `${Math.max(8, Number(item.score))}%` }}/></div>)}</div></section>}
  </div>
}
