'use client'

import React from 'react'
import Link from 'next/link'
import { AlertTriangle, ArrowRight, Award, Brain, CheckCircle2, Code2, Flame, Loader2, Maximize2, Zap } from 'lucide-react'

type Question = { id: string; question_text: string; options: string[]; topic: string; difficulty: string }
type Submission = { correct_count: number; total_questions: number; accuracy_rate: number; flagged: boolean }

export default function StudentTrainHubPage() {
  const [questions, setQuestions] = React.useState<Question[]>([])
  const [answers, setAnswers] = React.useState<Record<string, number>>({})
  const [index, setIndex] = React.useState(0)
  const [streak, setStreak] = React.useState(0)
  const [active, setActive] = React.useState(false)
  const [completed, setCompleted] = React.useState(false)
  const [result, setResult] = React.useState<Submission | null>(null)
  const [busy, setBusy] = React.useState(true)
  const [error, setError] = React.useState('')
  const [fullscreenWarning, setFullscreenWarning] = React.useState('')

  const load = React.useCallback(async () => {
    setBusy(true); setError('')
    try {
      const response = await fetch('/api/student/daily-five', { cache: 'no-store' })
      const body = await response.json()
      if (!response.ok) throw new Error(body.error || 'Daily Five could not be loaded.')
      setStreak(Number(body.streak?.current_streak ?? 0))
      setCompleted(Boolean(body.completed))
      setQuestions((body.questions ?? []) as Question[])
      if (body.result) setResult({ correct_count: Number(body.result.correct_count ?? 0), total_questions: 5, accuracy_rate: Number(body.result.accuracy_rate ?? 0), flagged: Boolean(body.result.flagged) })
    } catch (cause) { setError(cause instanceof Error ? cause.message : 'Daily Five could not be loaded.') }
    finally { setBusy(false) }
  }, [])

  React.useEffect(() => { void load() }, [load])
  React.useEffect(() => {
    const listener = () => {
      if (active && !completed && !document.fullscreenElement) setFullscreenWarning('Fullscreen was exited. This integrity signal remains visible in your session.')
      else setFullscreenWarning('')
    }
    document.addEventListener('fullscreenchange', listener)
    return () => document.removeEventListener('fullscreenchange', listener)
  }, [active, completed])

  async function begin() {
    if (!questions.length) return setError('No reviewed questions are available today.')
    setActive(true); setError('')
    await document.documentElement.requestFullscreen().catch(() => setFullscreenWarning('Fullscreen permission was not granted. You can still complete the practice.'))
  }

  async function next() {
    if (answers[questions[index].id] === undefined) return
    if (index < questions.length - 1) return setIndex((value) => value + 1)
    setBusy(true); setError('')
    try {
      const response = await fetch('/api/student/daily-five', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ answers }) })
      const body = await response.json()
      if (!response.ok) throw new Error(body.error || 'Daily Five could not be submitted.')
      setResult(body.result as Submission); setCompleted(true); setActive(false)
      if (document.fullscreenElement) await document.exitFullscreen().catch(() => {})
      await load()
    } catch (cause) { setError(cause instanceof Error ? cause.message : 'Daily Five could not be submitted.') }
    finally { setBusy(false) }
  }

  if (busy && !active && !completed) return <div className="grid min-h-64 place-items-center"><Loader2 className="h-6 w-6 animate-spin text-primary-purple" /></div>
  const question = questions[index]

  return <div className="mx-auto max-w-5xl space-y-8 pb-12">
    <header><h1 className="flex items-center gap-2 text-2xl font-black"><Zap className="h-6 w-6 text-primary-purple" />Train Gymnasium & Daily Five</h1><p className="mt-1 text-sm text-text-muted">Five server-selected questions adapt to your latest readiness evidence and become today’s verified practice.</p></header>
    {error && <div className="flex items-center justify-between gap-3 rounded-2xl border border-red-200 bg-red-50 p-4 text-sm font-bold text-red-700"><span>{error}</span><button onClick={() => void load()} className="underline">Retry</button></div>}

    {!active && !completed && <section className="rounded-3xl border border-border-light bg-white p-6 shadow-sm sm:p-8"><div className="flex flex-col gap-6 md:flex-row md:items-center md:justify-between"><div><span className="inline-flex items-center gap-1 rounded-full bg-violet-50 px-3 py-1 text-xs font-black text-primary-purple"><Flame className="h-4 w-4 text-amber-500" />Daily habit · {questions.length || 5} questions</span><h2 className="mt-3 text-2xl font-black">Today’s preparation loop</h2><p className="mt-2 max-w-xl text-sm leading-6 text-text-muted">The question set is fixed for you for the day, graded on the server, and contributes evidence only after submission.</p></div><div className="flex flex-col gap-3 sm:flex-row sm:items-center"><Metric label="Current streak" value={`${streak} days`} /><button onClick={() => void begin()} disabled={!questions.length} className="flex items-center justify-center gap-2 rounded-2xl bg-primary-purple px-6 py-4 text-sm font-black text-white disabled:opacity-40"><Maximize2 className="h-4 w-4" />Start Daily Five</button></div></div></section>}

    {active && question && <section className="space-y-4">{fullscreenWarning && <div className="flex items-center gap-2 rounded-xl bg-amber-50 p-4 text-xs font-bold text-amber-800"><AlertTriangle className="h-4 w-4" />{fullscreenWarning}</div>}<div className="rounded-3xl border border-border-light bg-white p-6 shadow-sm sm:p-8"><div className="flex flex-wrap items-center justify-between gap-2 border-b border-border-light pb-4"><span className="rounded-full bg-violet-50 px-3 py-1 text-xs font-black text-primary-purple">{question.topic} · {question.difficulty}</span><span className="text-xs font-bold text-text-muted">Question {index + 1} of {questions.length}</span></div><h2 className="mt-6 text-lg font-black leading-7">{question.question_text}</h2><div className="mt-6 grid gap-3">{question.options.map((option, optionIndex) => <button key={optionIndex} onClick={() => setAnswers((current) => ({ ...current, [question.id]: optionIndex }))} className={`flex items-center gap-4 rounded-2xl border p-4 text-left text-sm font-semibold ${answers[question.id] === optionIndex ? 'border-primary-purple bg-violet-50' : 'border-border-light bg-page-bg/40'}`}><span className={`grid h-8 w-8 place-items-center rounded-xl text-xs font-black ${answers[question.id] === optionIndex ? 'bg-primary-purple text-white' : 'bg-white'}`}>{String.fromCharCode(65 + optionIndex)}</span>{option}</button>)}</div><div className="mt-6 flex justify-end"><button onClick={() => void next()} disabled={answers[question.id] === undefined || busy} className="rounded-xl bg-primary-purple px-6 py-3 text-xs font-black text-white disabled:opacity-40">{index === questions.length - 1 ? (busy ? 'Submitting…' : 'Submit Daily Five') : 'Next question'}</button></div></div></section>}

    {completed && <section className="rounded-3xl border border-border-light bg-white p-8 text-center shadow-sm"><CheckCircle2 className="mx-auto h-14 w-14 text-emerald-600" /><p className="mt-4 text-xs font-black uppercase tracking-wider text-primary-purple">Today’s loop complete</p><h2 className="mt-1 text-2xl font-black">Evidence recorded</h2><p className="mt-2 text-sm text-text-muted">Return tomorrow for a new adaptive set. Today’s score is never reconstructed in the browser.</p><div className="mx-auto mt-6 grid max-w-md grid-cols-2 gap-3"><Metric label="Score" value={result ? `${result.correct_count}/${result.total_questions}` : 'Recorded'} /><Metric label="Current streak" value={`${streak} days`} /></div></section>}

    <div className="grid gap-4 sm:grid-cols-3"><Feature icon={<Code2 />} title="CodeBox quests" body="Run original challenges against private server tests." href="/student/codebox" cta="Open CodeBox" /><Feature icon={<Brain />} title="Communication practice" body="Record an answer and receive transcript-grounded coaching." href="/student/train/communication" cta="Start speaking" /><Feature icon={<Award />} title="Mock assessments" body="Take faculty-reviewed, timed preparation assessments." href="/student/exams" cta="View assessments" /></div>
  </div>
}

function Metric({ label, value }: { label: string; value: string }) { return <div className="rounded-2xl border border-border-light bg-page-bg px-5 py-3 text-center"><p className="font-black text-text-main">{value}</p><p className="mt-1 text-[10px] font-black uppercase tracking-wider text-text-muted">{label}</p></div> }
function Feature({ icon, title, body, href, cta }: { icon: React.ReactNode; title: string; body: string; href: string; cta: string }) { return <article className="rounded-3xl border border-border-light bg-white p-6 shadow-sm"><div className="grid h-11 w-11 place-items-center rounded-2xl bg-violet-50 text-primary-purple">{icon}</div><h3 className="mt-4 font-black">{title}</h3><p className="mt-1 min-h-10 text-xs leading-5 text-text-muted">{body}</p><Link href={href} className="mt-4 inline-flex items-center gap-1 text-xs font-black text-primary-purple">{cta}<ArrowRight className="h-3.5 w-3.5" /></Link></article> }
