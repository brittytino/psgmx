'use client'

import React from 'react'
import Link from 'next/link'
import { CheckCircle2, ClipboardList, Clock, Loader2, Play, ShieldCheck } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { getCurrentProfile } from '@/lib/current-profile'

type Exam = {
  id: string
  title: string
  description: string | null
  duration_minutes: number
  total_marks: number
  exam_date: string | null
}
type Result = { exam_id: string; score: number | null; raw_marks: number | null; out_of: number | null; status: string; submitted_at: string | null; reflection: string | null; reflected_at: string | null }

export default function ExamsPage() {
  const supabase = React.useMemo(() => createClient(), [])
  const [exams, setExams] = React.useState<Exam[]>([])
  const [results, setResults] = React.useState<Map<string, Result>>(new Map())
  const [loading, setLoading] = React.useState(true)
  const [error, setError] = React.useState('')
  const [drafts, setDrafts] = React.useState<Record<string, string>>({})
  const [savingReflection, setSavingReflection] = React.useState('')

  const load = React.useCallback(async () => {
    setLoading(true)
    setError('')
    try {
      const me = await getCurrentProfile(supabase)
      if (!me?.batch_id) throw new Error('Your batch is not assigned yet.')
      const [{ data: examRows, error: examError }, { data: resultRows, error: resultError }] = await Promise.all([
        supabase.from('mock_exams').select('id,title,description,duration_minutes,total_marks,exam_date').eq('batch_id', me.batch_id).order('exam_date', { ascending: false }),
        supabase.from('mock_exam_results').select('exam_id,score,raw_marks,out_of,status,submitted_at,reflection,reflected_at').eq('student_id', me.id),
      ])
      if (examError || resultError) throw examError ?? resultError
      setExams(examRows ?? [])
      setResults(new Map((resultRows ?? []).map((row) => [row.exam_id, row])))
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : 'Exams could not be loaded.')
    } finally {
      setLoading(false)
    }
  }, [supabase])

  React.useEffect(() => { void load() }, [load])

  async function saveReflection(examId: string) {
    const reflection = (drafts[examId] ?? '').trim()
    if (reflection.length < 20) return setError('Reflection needs at least 20 characters so it captures a useful lesson.')
    setSavingReflection(examId); setError('')
    const reflectedAt = new Date().toISOString()
    const { error: updateError } = await supabase.from('mock_exam_results').update({ reflection, reflected_at: reflectedAt }).eq('exam_id', examId)
    if (updateError) setError(updateError.message)
    else setResults((current) => { const next = new Map(current); const result = next.get(examId); if (result) next.set(examId, { ...result, reflection, reflected_at: reflectedAt }); return next })
    setSavingReflection('')
  }

  if (loading) return <div className="flex min-h-64 items-center justify-center"><Loader2 className="h-6 w-6 animate-spin text-primary-purple"/></div>

  const completed = exams.filter((exam) => ['submitted', 'auto_submitted'].includes(results.get(exam.id)?.status ?? ''))
  const open = exams.filter((exam) => !completed.includes(exam))
  const best = completed.reduce((value, exam) => Math.max(value, Number(results.get(exam.id)?.score ?? 0)), 0)

  return <div className="mx-auto max-w-5xl space-y-7 pb-10">
    <div className="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between"><div><h1 className="flex items-center gap-2 text-2xl font-black"><ClipboardList className="h-6 w-6 text-primary-purple"/>Mock exams</h1><p className="mt-1 text-sm text-text-muted">Only exams published for your batch appear here.</p></div><div className="flex items-center gap-2 rounded-xl border border-border-light bg-white px-4 py-3 text-xs font-bold"><ShieldCheck className="h-4 w-4 text-emerald-600"/>Proctored attempts</div></div>
    <div className="grid gap-3 sm:grid-cols-3">{[['Published', exams.length], ['Completed', completed.length], ['Best score', completed.length ? `${Math.round(best)}%` : '—']].map(([label, value]) => <div key={String(label)} className="rounded-2xl border border-border-light bg-white p-5"><p className="text-2xl font-black">{value}</p><p className="mt-1 text-xs font-bold text-text-muted">{label}</p></div>)}</div>
    {error && <div className="rounded-2xl border border-amber-200 bg-amber-50 p-5 text-sm font-bold">{error}<button onClick={load} className="ml-2 text-primary-purple">Retry</button></div>}
    {!error && exams.length === 0 && <div className="rounded-3xl border border-dashed border-border-light bg-white p-14 text-center"><ClipboardList className="mx-auto h-10 w-10 text-text-muted"/><h2 className="mt-4 font-black">No mock exam is scheduled</h2><p className="mt-2 text-sm text-text-muted">Your faculty team will publish the next assessment here.</p></div>}
    {open.length > 0 && <section><h2 className="font-black">Available and upcoming</h2><div className="mt-3 space-y-3">{open.map((exam) => {
      const result = results.get(exam.id)
      const date = exam.exam_date ? new Date(exam.exam_date) : null
      const started = result?.status === 'in_progress'
      const canStart = !date || date.getTime() <= Date.now() || started
      return <div key={exam.id} className="flex flex-col gap-4 rounded-2xl border border-border-light bg-white p-5 sm:flex-row sm:items-center sm:justify-between"><div><h3 className="font-black">{exam.title}</h3><p className="mt-1 text-sm text-text-muted">{exam.description || 'Placement practice assessment'}</p><p className="mt-3 flex flex-wrap gap-3 text-xs font-bold text-text-muted"><span className="flex items-center gap-1"><Clock className="h-3.5 w-3.5"/>{exam.duration_minutes} minutes</span><span>{exam.total_marks} marks</span><span>{date ? new Intl.DateTimeFormat('en-IN', { dateStyle: 'medium', timeStyle: 'short' }).format(date) : 'Open now'}</span></p></div>{canStart ? <Link href={`/exam/${exam.id}`} className="flex shrink-0 items-center justify-center gap-2 rounded-xl bg-primary-purple px-5 py-3 text-sm font-bold text-white"><Play className="h-4 w-4"/>{started ? 'Continue exam' : 'Enter exam'}</Link> : <span className="shrink-0 rounded-xl bg-page-bg px-4 py-3 text-xs font-bold text-text-muted">Opens at scheduled time</span>}</div>
    })}</div></section>}
    {completed.length > 0 && <section><h2 className="font-black">Completed & reflected</h2><p className="mt-1 text-sm text-text-muted">A short reflection turns a score into reusable evidence. XP is awarded once, after the first saved reflection.</p><div className="mt-3 space-y-3">{completed.map((exam) => { const result = results.get(exam.id)!; return <article key={exam.id} className="rounded-2xl border border-border-light bg-white p-5"><div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between"><div><h3 className="font-black">{exam.title}</h3><p className="mt-1 text-xs text-text-muted">{result.submitted_at ? new Intl.DateTimeFormat('en-IN', { dateStyle: 'medium' }).format(new Date(result.submitted_at)) : 'Recorded'} · {result.status.replaceAll('_', ' ')}</p></div><div className="flex items-center gap-2 text-lg font-black text-emerald-700"><CheckCircle2 className="h-5 w-5"/>{result.score !== null ? `${Math.round(Number(result.score))}%` : result.raw_marks !== null ? `${result.raw_marks}/${result.out_of ?? exam.total_marks}` : 'Pending'}</div></div>{result.reflected_at ? <div className="mt-4 rounded-xl bg-emerald-50 p-4"><p className="text-[10px] font-black uppercase tracking-wider text-emerald-700">Reflection saved</p><p className="mt-2 text-sm leading-6 text-emerald-950">{result.reflection}</p></div> : <div className="mt-4"><label className="text-xs font-black text-text-muted">What did you misunderstand, and what will you do differently?<textarea value={drafts[exam.id] ?? ''} onChange={(event) => setDrafts({...drafts, [exam.id]: event.target.value})} rows={3} maxLength={1000} className="mt-2 w-full resize-y rounded-xl border border-border-light bg-page-bg px-4 py-3 text-sm outline-none focus:border-primary-purple"/></label><div className="mt-3 flex justify-end"><button disabled={savingReflection === exam.id} onClick={() => void saveReflection(exam.id)} className="rounded-xl bg-primary-purple px-4 py-2.5 text-xs font-black text-white disabled:opacity-50">{savingReflection === exam.id ? 'Saving…' : 'Save reflection'}</button></div></div>}</article> })}</div></section>}
  </div>
}
