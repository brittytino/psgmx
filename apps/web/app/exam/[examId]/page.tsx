'use client'

import React, { use } from 'react'
import Link from 'next/link'
import { AlertCircle, CheckCircle2, ChevronLeft, ChevronRight, Clock, ShieldCheck } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { getCurrentProfile } from '@/lib/current-profile'

type Question = { id: string; question_text: string; option_a: string; option_b: string; option_c: string; option_d: string; marks: number }
type Result = { score: number; raw_marks: number; out_of: number; status: string; elapsed_seconds: number }
type StartSession = { started_at: string; duration_minutes: number }
type StartRpc = (name: string, args: { p_exam_id: string }) => Promise<{ data: StartSession | StartSession[] | null; error: { message: string } | null }>

export default function ExamPage({ params }: { params: Promise<{ examId: string }> }) {
  const { examId } = use(params)
  const supabase = React.useMemo(() => createClient(), [])
  const [profileId, setProfileId] = React.useState('')
  const [exam, setExam] = React.useState<any>(null)
  const [questions, setQuestions] = React.useState<Question[]>([])
  const [answers, setAnswers] = React.useState<Record<string, string>>({})
  const [index, setIndex] = React.useState(0)
  const [loading, setLoading] = React.useState(true)
  const [started, setStarted] = React.useState(false)
  const [submitting, setSubmitting] = React.useState(false)
  const [seconds, setSeconds] = React.useState(0)
  const [startedAt, setStartedAt] = React.useState(0)
  const [flags, setFlags] = React.useState<Array<{ type: string; at: string }>>([])
  const [result, setResult] = React.useState<Result | null>(null)
  const [reflection, setReflection] = React.useState('')
  const [reflectionSaved, setReflectionSaved] = React.useState(false)
  const [error, setError] = React.useState('')

  React.useEffect(() => {
    void (async () => {
      try {
        const profile = await getCurrentProfile(supabase)
        if (!profile) throw new Error('Sign in again to open this assessment.')
        setProfileId(profile.id)
        const [{ data: examRow, error: examError }, { data: questionRows, error: questionError }] = await Promise.all([
          supabase.from('mock_exams').select('id,title,description,duration_minutes,total_marks,exam_date,batch_id').eq('id', examId).maybeSingle(),
          supabase.from('mock_exam_questions').select('id,question_text,option_a,option_b,option_c,option_d,marks').eq('exam_id', examId).order('order_index'),
        ])
        if (examError || !examRow) throw new Error('This assessment is unavailable for your batch.')
        if (questionError || !questionRows?.length) throw new Error('This assessment has no reviewed questions yet.')
        setExam(examRow); setQuestions(questionRows as Question[])
      } catch (cause) {
        setError(cause instanceof Error ? cause.message : 'Assessment could not be loaded.')
      } finally { setLoading(false) }
    })()
  }, [examId, supabase])

  React.useEffect(() => {
    if (!started || result) return
    const onVisibility = () => {
      if (document.hidden) setFlags((current) => [...current, { type: 'tab_hidden', at: new Date().toISOString() }].slice(-50))
    }
    const onFullscreen = () => {
      if (!document.fullscreenElement) setFlags((current) => [...current, { type: 'fullscreen_exit', at: new Date().toISOString() }].slice(-50))
    }
    document.addEventListener('visibilitychange', onVisibility)
    document.addEventListener('fullscreenchange', onFullscreen)
    return () => { document.removeEventListener('visibilitychange', onVisibility); document.removeEventListener('fullscreenchange', onFullscreen) }
  }, [started, result])

  const submit = React.useCallback(async () => {
    if (submitting || result || !profileId) return
    setSubmitting(true); setError('')
    try {
      const response = await fetch('/api/student/exam/submit', {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ exam_id: examId, answers, time_taken_seconds: Math.floor((Date.now() - startedAt) / 1000), proctoring_flags: flags }),
      })
      const data = await response.json()
      if (!response.ok) throw new Error(data.error || 'Submission failed.')
      setResult({ score: Number(data.score), raw_marks: Number(data.raw_marks), out_of: Number(data.out_of), status: data.status, elapsed_seconds: Number(data.elapsed_seconds) })
      if (document.fullscreenElement) await document.exitFullscreen().catch(() => {})
    } catch (cause) { setError(cause instanceof Error ? cause.message : 'Submission failed.') }
    finally { setSubmitting(false) }
  }, [answers, examId, flags, profileId, result, startedAt, submitting])

  React.useEffect(() => {
    if (!started || result || seconds <= 0) return
    const timer = window.setInterval(() => setSeconds((value) => value - 1), 1000)
    return () => window.clearInterval(timer)
  }, [started, result, seconds])
  React.useEffect(() => { if (started && !result && seconds === 0) void submit() }, [seconds, started, result, submit])

  async function begin() {
    setError('')
    const { data, error: startError } = await (supabase.rpc.bind(supabase) as unknown as StartRpc)('start_mock_exam', { p_exam_id: examId })
    if (startError) return setError(startError.message)
    const session = Array.isArray(data) ? data[0] : data
    if (!session) return setError('Assessment session could not be started.')
    const began = new Date(session.started_at).getTime()
    const durationSeconds = Number(session.duration_minutes) * 60
    setStartedAt(began)
    setSeconds(Math.max(0, durationSeconds - Math.floor((Date.now() - began) / 1000)))
    setStarted(true)
    await document.documentElement.requestFullscreen().catch(() => {})
  }

  async function saveReflection() {
    const value = reflection.trim()
    if (value.length < 20) return setError('Write at least 20 characters about what you will improve next.')
    const response = await fetch('/api/student/exam/reflection', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ exam_id: examId, reflection: value }) })
    const data = await response.json()
    if (!response.ok) return setError(data.error || 'Reflection could not be saved.')
    setReflectionSaved(true); setError('')
  }

  if (loading) return <div className="grid min-h-screen place-items-center bg-page-bg"><Clock className="h-8 w-8 animate-spin text-primary-purple"/></div>
  if (!exam) return <StateCard title="Assessment unavailable" message={error} />

  if (!started) return <div className="grid min-h-screen place-items-center bg-page-bg p-5"><div className="max-w-xl rounded-3xl border border-border-light bg-white p-8 shadow-sm"><ShieldCheck className="h-10 w-10 text-primary-purple"/><h1 className="mt-5 text-2xl font-black">{exam.title}</h1><p className="mt-2 text-sm leading-6 text-text-muted">{exam.description}</p><div className="mt-5 rounded-2xl bg-page-bg p-4 text-sm font-bold">{questions.length} questions · {exam.duration_minutes} minutes · {exam.total_marks} marks</div><p className="mt-4 text-xs leading-5 text-text-muted">The timer starts only after you continue. Tab changes and fullscreen exits are recorded as integrity signals; no camera recording is uploaded.</p>{error && <p className="mt-4 text-sm font-bold text-red-600">{error}</p>}<button onClick={() => void begin()} className="mt-6 w-full rounded-xl bg-primary-purple py-3 text-sm font-black text-white">Start assessment</button><Link href="/student/exams" className="mt-4 block text-center text-xs font-bold text-text-muted">Return to assessments</Link></div></div>

  if (result) return <div className="min-h-screen bg-page-bg p-5 py-12"><div className="mx-auto max-w-2xl space-y-5"><div className="rounded-3xl border border-border-light bg-white p-8 text-center shadow-sm"><CheckCircle2 className="mx-auto h-12 w-12 text-emerald-600"/><p className="mt-4 text-xs font-black uppercase tracking-wider text-primary-purple">Recorded from server-side grading</p><h1 className="mt-1 text-2xl font-black">{exam.title}</h1><div className="mt-6 grid grid-cols-3 gap-3"><Metric label="Score" value={`${result.score}%`}/><Metric label="Marks" value={`${result.raw_marks}/${result.out_of}`}/><Metric label="Status" value={result.status.replace('_', ' ')}/></div></div><div className="rounded-3xl border border-border-light bg-white p-6"><h2 className="font-black">Turn the result into a next step</h2><p className="mt-1 text-xs leading-5 text-text-muted">Reflection is part of completion. Record the concept or strategy you will practise next.</p><textarea disabled={reflectionSaved} value={reflection} onChange={(e) => setReflection(e.target.value)} className="mt-4 min-h-28 w-full rounded-xl border border-border-light p-4 text-sm outline-none focus:border-primary-purple" placeholder="I noticed… Next I will…"/>{error && <p className="mt-2 text-xs font-bold text-red-600">{error}</p>}<button disabled={reflectionSaved} onClick={() => void saveReflection()} className="mt-3 w-full rounded-xl bg-primary-purple py-3 text-sm font-black text-white disabled:bg-emerald-600">{reflectionSaved ? 'Reflection saved' : 'Save reflection'}</button></div><Link href="/student/exams" className="block text-center text-sm font-bold text-primary-purple">Back to assessments</Link></div></div>

  const question = questions[index]
  const mins = Math.floor(seconds / 60); const secs = seconds % 60
  return <div className="min-h-screen bg-page-bg"><header className="sticky top-0 z-10 flex flex-wrap items-center justify-between gap-3 border-b border-border-light bg-white px-4 py-3 sm:px-6"><div><p className="text-xs font-black text-primary-purple">Question {index + 1} of {questions.length}</p><h1 className="text-sm font-black">{exam.title}</h1></div><div className={`rounded-xl px-4 py-2 font-mono text-sm font-black ${seconds < 300 ? 'bg-red-50 text-red-700' : 'bg-page-bg'}`}>{mins}:{String(secs).padStart(2, '0')}</div></header><main className="mx-auto max-w-3xl p-4 py-8 sm:p-8"><div className="rounded-3xl border border-border-light bg-white p-6 shadow-sm"><p className="text-base font-bold leading-7">{question.question_text}</p><div className="mt-6 space-y-3">{(['A','B','C','D'] as const).map((letter) => { const text = question[`option_${letter.toLowerCase()}` as keyof Question] as string; const selected = answers[question.id] === letter; return <button key={letter} onClick={() => setAnswers({ ...answers, [question.id]: letter })} className={`flex w-full items-start gap-3 rounded-2xl border p-4 text-left text-sm transition ${selected ? 'border-primary-purple bg-primary-purple/5' : 'border-border-light hover:border-primary-purple/40'}`}><span className={`grid h-7 w-7 shrink-0 place-items-center rounded-full text-xs font-black ${selected ? 'bg-primary-purple text-white' : 'bg-page-bg'}`}>{letter}</span><span className="pt-1">{text}</span></button> })}</div></div>{error && <div className="mt-4 flex gap-2 rounded-xl bg-red-50 p-3 text-sm font-bold text-red-700"><AlertCircle className="h-4 w-4"/>{error}</div>}<div className="mt-6 flex items-center justify-between"><button disabled={index === 0} onClick={() => setIndex((value) => value - 1)} className="flex items-center gap-1 rounded-xl border border-border-light bg-white px-4 py-2.5 text-xs font-black disabled:opacity-40"><ChevronLeft className="h-4 w-4"/>Previous</button>{index < questions.length - 1 ? <button onClick={() => setIndex((value) => value + 1)} className="flex items-center gap-1 rounded-xl bg-primary-purple px-5 py-2.5 text-xs font-black text-white">Next<ChevronRight className="h-4 w-4"/></button> : <button disabled={submitting} onClick={() => void submit()} className="rounded-xl bg-emerald-600 px-6 py-2.5 text-xs font-black text-white disabled:opacity-50">{submitting ? 'Submitting…' : 'Submit assessment'}</button>}</div><div className="mt-6 flex flex-wrap gap-2">{questions.map((item, itemIndex) => <button key={item.id} onClick={() => setIndex(itemIndex)} className={`h-8 w-8 rounded-lg text-xs font-black ${answers[item.id] ? 'bg-primary-purple text-white' : itemIndex === index ? 'border border-primary-purple text-primary-purple' : 'bg-white text-text-muted'}`}>{itemIndex + 1}</button>)}</div></main></div>
}

function Metric({ label, value }: { label: string; value: string }) { return <div className="rounded-2xl bg-page-bg p-4"><p className="text-lg font-black capitalize">{value}</p><p className="mt-1 text-[10px] font-black uppercase tracking-wider text-text-muted">{label}</p></div> }
function StateCard({ title, message }: { title: string; message: string }) { return <div className="grid min-h-screen place-items-center bg-page-bg p-5"><div className="max-w-md rounded-3xl border border-border-light bg-white p-8 text-center"><AlertCircle className="mx-auto h-10 w-10 text-amber-600"/><h1 className="mt-4 text-xl font-black">{title}</h1><p className="mt-2 text-sm text-text-muted">{message}</p><Link href="/student/exams" className="mt-5 inline-block font-black text-primary-purple">Return to assessments</Link></div></div> }
