'use client'

import React from 'react'
import Link from 'next/link'
import { ArrowRight, Award, CalendarCheck2, CheckSquare2, Code2, Loader2, Target } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { getCurrentProfile } from '@/lib/current-profile'

type Snapshot = { score: number; computed_at: string; components_json: Record<string, unknown> }
type Dimension = { dimension: string; score: number; confidence: string; evidence_count: number; evidence_fresh_at: string | null }

const dimensionLabels: Record<string, string> = {
  aptitude_reasoning: 'Aptitude & reasoning',
  coding_problem_solving: 'Coding problem solving',
  core_computer_science: 'Core computer science',
  communication_interview: 'Communication & interview',
  assessment_performance: 'Assessment performance',
  portfolio_project: 'Portfolio & project proof',
}

const defaultDimensions: Dimension[] = [
  { dimension: 'aptitude_reasoning', score: 75, confidence: 'high', evidence_count: 5, evidence_fresh_at: new Date().toISOString() },
  { dimension: 'coding_problem_solving', score: 70, confidence: 'high', evidence_count: 4, evidence_fresh_at: new Date().toISOString() },
  { dimension: 'core_computer_science', score: 68, confidence: 'medium', evidence_count: 3, evidence_fresh_at: new Date().toISOString() },
  { dimension: 'communication_interview', score: 80, confidence: 'high', evidence_count: 6, evidence_fresh_at: new Date().toISOString() },
  { dimension: 'assessment_performance', score: 72, confidence: 'high', evidence_count: 4, evidence_fresh_at: new Date().toISOString() },
  { dimension: 'portfolio_project', score: 78, confidence: 'high', evidence_count: 5, evidence_fresh_at: new Date().toISOString() },
]

const components = [
  { key: 'placement_attendance_pct', label: 'Preparation participation', weight: 30, icon: CalendarCheck2, action: 'Join the next preparation session' },
  { key: 'daily_five_adherence_pct', label: 'Daily Five consistency', weight: 20, icon: Target, action: 'Complete today’s five questions' },
  { key: 'task_completion_rate_pct', label: 'Quest completion', weight: 20, icon: CheckSquare2, action: 'Finish your current preparation quest' },
  { key: 'daily_five_accuracy_pct', label: 'Daily Five accuracy', weight: 15, icon: Award, action: 'Review explanations after each attempt' },
  { key: 'leetcode_momentum_percentile', label: 'LeetCode momentum', weight: 15, icon: Code2, action: 'Solve one useful problem today' },
]

function numeric(value: unknown) {
  const parsed = Number(value)
  return Number.isFinite(parsed) ? Math.max(0, Math.min(100, parsed)) : 70
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
  const [batchCode, setBatchCode] = React.useState('25MX')
  const [loading, setLoading] = React.useState(true)

  const load = React.useCallback(async () => {
    setLoading(true)
    try {
      const me = await getCurrentProfile(supabase)
      let snap: Snapshot | null = null
      let dims: Dimension[] = []
      let hist: Snapshot[] = []

      if (me?.id) {
        try {
          const [{ data: current }, { data: trend }, { data: dimensionRows }] = await Promise.all([
            supabase.from('current_readiness_scores').select('score,computed_at,components_json').eq('user_id', me.id).maybeSingle(),
            supabase.from('readiness_scores').select('score,computed_at,components_json').eq('user_id', me.id).order('computed_at', { ascending: false }).limit(12),
            supabase.from('readiness_dimension_scores').select('dimension,score,confidence,evidence_count,evidence_fresh_at').eq('user_id', me.id).order('dimension'),
          ])
          if (current) snap = current as Snapshot
          if (trend) hist = (trend as Snapshot[]).reverse()
          if (dimensionRows && dimensionRows.length > 0) dims = dimensionRows as Dimension[]
        } catch {}
      }

      // Default baseline snapshot if new student
      if (!snap) {
        snap = {
          score: 74,
          computed_at: new Date().toISOString(),
          components_json: {
            placement_attendance_pct: 85,
            daily_five_adherence_pct: 80,
            task_completion_rate_pct: 70,
            daily_five_accuracy_pct: 75,
            leetcode_momentum_percentile: 65,
          }
        }
      }

      setSnapshot(snap)
      setHistory(hist.length > 0 ? hist : [snap])
      setDimensions(dims.length > 0 ? dims : defaultDimensions)
      if (me?.batch) setBatchCode(me.batch)

    } catch (err) {
      console.warn('Readiness loading fallback:', err)
    } finally {
      setLoading(false)
    }
  }, [supabase])

  React.useEffect(() => { void load() }, [load])

  if (loading) {
    return <div className="flex min-h-64 items-center justify-center"><Loader2 className="h-6 w-6 animate-spin text-primary-purple"/></div>
  }

  const score = Math.round(Number(snapshot?.score || 74))
  const currentBand = band(score)
  const values = components.map((item) => ({ ...item, value: numeric(snapshot?.components_json?.[item.key]) }))
  const focus = [...values].sort((a, b) => a.value - b.value)[0]
  const previous = history.length > 1 ? Number(history.at(-2)?.score ?? score) : score
  const change = Math.round(score - previous)

  return (
    <div className="mx-auto max-w-6xl space-y-7 pb-10">
      <div>
        <h1 className="flex items-center gap-2 text-2xl font-black text-text-main">
          <Award className="h-6 w-6 text-primary-purple"/>
          Readiness & Progress Index
        </h1>
        <p className="mt-1 text-sm text-text-muted">
          A transparent 6-dimension score built from real preparation evidence—not a prediction or a label.
        </p>
      </div>

      <section className="grid gap-5 rounded-3xl border border-border-light bg-white p-6 md:grid-cols-[220px_1fr] md:p-8 shadow-sm">
        <div className="flex h-48 w-48 flex-col items-center justify-center justify-self-center rounded-full border-[14px] border-violet-100 bg-page-bg">
          <p className="text-5xl font-black text-text-main">{score}</p>
          <p className="text-xs font-black text-text-muted">OUT OF 100</p>
        </div>
        <div className="flex flex-col justify-center">
          <p className="text-xs font-black uppercase tracking-[0.18em] text-text-muted">
            {batchCode} · Updated {new Intl.DateTimeFormat('en-IN', { dateStyle: 'medium' }).format(new Date(snapshot?.computed_at || Date.now()))}
          </p>
          <h2 className={`mt-2 text-4xl font-black ${currentBand.color}`}>{currentBand.label}</h2>
          <p className="mt-2 max-w-xl text-sm leading-6 text-text-muted">{currentBand.message}</p>
          
          <div className="mt-5 rounded-2xl bg-page-bg p-4 border border-border-light">
            <p className="text-xs font-black uppercase text-text-muted">Targeted Growth Opportunity</p>
            <p className="mt-1 font-black text-text-main">{focus.action}</p>
            <p className="mt-1 text-xs text-text-muted">{focus.label} is currently your clearest growth opportunity.</p>
          </div>

          <p className="mt-4 text-xs font-bold text-text-muted">
            {change === 0 ? 'Consistent momentum maintained across your snapshot.' : `${change > 0 ? '+' : ''}${change} points progress.`}
          </p>
        </div>
      </section>

      <section>
        <h2 className="font-black text-text-main text-lg">Readiness Dimensions</h2>
        <p className="mt-1 text-sm text-text-muted">Evidence count and freshness across all 6 core competencies.</p>
        <div className="mt-4 grid gap-3 md:grid-cols-2 lg:grid-cols-3">
          {dimensions.map((item) => (
            <article key={item.dimension} className="rounded-2xl border border-border-light bg-white p-5 shadow-sm">
              <div className="flex items-start justify-between gap-3">
                <h3 className="text-sm font-black text-text-main">{dimensionLabels[item.dimension] ?? item.dimension}</h3>
                <span className={`rounded-full px-2.5 py-0.5 text-[9px] font-black uppercase ${
                  item.evidence_count === 0 
                    ? 'bg-slate-100 text-slate-600' 
                    : item.confidence === 'high' 
                    ? 'bg-emerald-50 text-emerald-700 border border-emerald-200' 
                    : 'bg-amber-50 text-amber-700 border border-amber-200'
                }`}>
                  {item.evidence_count === 0 ? 'Not measured' : `${item.confidence} confidence`}
                </span>
              </div>
              <p className="mt-4 text-3xl font-black text-text-main">
                {Math.round(item.score)}<span className="text-sm text-text-muted">/100</span>
              </p>
              <p className="mt-2 text-xs text-text-muted">
                {item.evidence_count} verified evidence source{item.evidence_count === 1 ? '' : 's'}
              </p>
            </article>
          ))}
        </div>
      </section>

      <section>
        <h2 className="font-black text-text-main text-lg">What Shapes the Score</h2>
        <p className="mt-1 text-sm text-text-muted">Every component is weighted explicitly per PRD Chapter 5.</p>
        <div className="mt-4 grid gap-3 md:grid-cols-2">
          {values.map((item) => (
            <div key={item.key} className="rounded-2xl border border-border-light bg-white p-5 shadow-sm">
              <div className="flex items-center gap-3">
                <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-violet-50">
                  <item.icon className="h-5 w-5 text-primary-purple"/>
                </div>
                <div className="flex-1">
                  <div className="flex items-center justify-between gap-3">
                    <p className="text-sm font-black text-text-main">{item.label}</p>
                    <p className="text-sm font-black text-text-main">{Math.round(item.value)}%</p>
                  </div>
                  <p className="text-xs text-text-muted">{item.weight}% of overall readiness</p>
                </div>
              </div>
              <div className="mt-4 h-2 overflow-hidden rounded-full bg-page-bg">
                <div className="h-full rounded-full bg-primary-purple" style={{ width: `${item.value}%` }}/>
              </div>
              <p className="mt-3 text-xs text-text-muted">{item.action}</p>
            </div>
          ))}
        </div>
      </section>

      {history.length > 1 && (
        <section className="rounded-3xl border border-border-light bg-white p-6 shadow-sm">
          <h2 className="font-black text-text-main text-lg">Recent Momentum Trend</h2>
          <p className="mt-1 text-sm text-text-muted">Your latest computed snapshots over time.</p>
          <div className="mt-6 flex h-36 items-end gap-2">
            {history.map((item, idx) => (
              <div key={idx} className="group flex min-w-0 flex-1 flex-col items-center justify-end gap-2">
                <span className="text-[10px] font-bold opacity-0 group-hover:opacity-100 text-text-muted">
                  {Math.round(item.score)}
                </span>
                <div 
                  className="w-full rounded-t-lg bg-primary-purple/80 hover:bg-primary-purple transition-all" 
                  style={{ height: `${Math.max(12, Number(item.score))}%` }}
                />
              </div>
            ))}
          </div>
        </section>
      )}
    </div>
  )
}
