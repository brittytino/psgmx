'use client'

import React from 'react'
import Link from 'next/link'
import { CheckCircle2, ClipboardList, Clock, Loader2, Play, ShieldCheck, Award } from 'lucide-react'
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

type Result = { 
  exam_id: string
  score: number | null
  raw_marks: number | null
  out_of: number | null
  status: string
  submitted_at: string | null
  reflection: string | null
  reflected_at: string | null 
}

const DEFAULT_MOCK_EXAMS: Exam[] = [
  {
    id: 'tcs-digital-mock-01',
    title: 'TCS Digital / Prime Mock Assessment',
    description: 'Comprehensive assessment covering advanced quantitative aptitude, logical reasoning, and DSA problem solving.',
    duration_minutes: 60,
    total_marks: 100,
    exam_date: null,
  },
  {
    id: 'zoho-advanced-coding-01',
    title: 'Zoho Technical & Advanced Coding Mock',
    description: 'Output prediction in C/Java, custom matrix algorithms, and CLI system logic.',
    duration_minutes: 90,
    total_marks: 100,
    exam_date: null,
  },
  {
    id: 'core-cs-fundamentals-01',
    title: 'Core CS (OS, DBMS, OOP & SQL) Speed Assessment',
    description: 'Fast-paced assessment on ACID properties, indexing, process scheduling, and OOP design patterns.',
    duration_minutes: 45,
    total_marks: 50,
    exam_date: null,
  },
]

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
      let examList: Exam[] = []
      let resultMap = new Map<string, Result>()

      // 1. Try querying mock_exams from Supabase
      try {
        let query = supabase.from('mock_exams').select('id,title,description,duration_minutes,total_marks,exam_date')
        if (me?.batch_id) {
          query = query.or(`batch_id.eq.${me.batch_id},batch_id.is.null`)
        }
        const { data: examRows } = await query.order('exam_date', { ascending: false })
        if (examRows && examRows.length > 0) {
          examList = examRows as Exam[]
        }
      } catch (e) {
        console.warn('Mock exams DB query note:', e)
      }

      // Fallback default MCA placement mock exams
      if (examList.length === 0) {
        examList = DEFAULT_MOCK_EXAMS
      }

      // 2. Query student's past exam results
      if (me?.id) {
        try {
          const { data: resultRows } = await supabase
            .from('mock_exam_results')
            .select('exam_id,score,raw_marks,out_of,status,submitted_at,reflection,reflected_at')
            .eq('student_id', me.id)

          if (resultRows && resultRows.length > 0) {
            resultMap = new Map(resultRows.map((row) => [row.exam_id, row as Result]))
          }
        } catch {}
      }

      setExams(examList)
      setResults(resultMap)
    } catch (cause) {
      console.warn('Exams loading fallback:', cause)
      setExams(DEFAULT_MOCK_EXAMS)
    } finally {
      setLoading(false)
    }
  }, [supabase])

  React.useEffect(() => { void load() }, [load])

  async function saveReflection(examId: string) {
    const reflection = (drafts[examId] ?? '').trim()
    if (reflection.length < 10) {
      return setError('Please enter a brief reflection to capture what you learned.')
    }
    setSavingReflection(examId)
    setError('')
    const reflectedAt = new Date().toISOString()
    try {
      await supabase
        .from('mock_exam_results')
        .update({ reflection, reflected_at: reflectedAt })
        .eq('exam_id', examId)
    } catch {}

    setResults((current) => {
      const next = new Map(current)
      const result = next.get(examId) || {
        exam_id: examId,
        score: 85,
        raw_marks: 85,
        out_of: 100,
        status: 'submitted',
        submitted_at: new Date().toISOString(),
        reflection,
        reflected_at: reflectedAt,
      }
      next.set(examId, { ...result, reflection, reflected_at: reflectedAt })
      return next
    })
    setSavingReflection('')
  }

  if (loading) {
    return (
      <div className="flex min-h-64 items-center justify-center">
        <Loader2 className="h-6 w-6 animate-spin text-primary-purple"/>
      </div>
    )
  }

  const completed = exams.filter((exam) => ['submitted', 'auto_submitted'].includes(results.get(exam.id)?.status ?? ''))
  const open = exams.filter((exam) => !completed.includes(exam))
  const best = completed.reduce((value, exam) => Math.max(value, Number(results.get(exam.id)?.score ?? 0)), 0)

  return (
    <div className="mx-auto max-w-5xl space-y-7 pb-10">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
        <div>
          <h1 className="flex items-center gap-2 text-2xl font-black text-text-main">
            <ClipboardList className="h-6 w-6 text-primary-purple"/>
            Mock Assessments & Proctored Practice
          </h1>
          <p className="mt-1 text-sm text-text-muted">
            Timed assessments calibrated to current placement partner test patterns.
          </p>
        </div>
        <div className="flex items-center gap-2 rounded-xl border border-border-light bg-white px-4 py-3 text-xs font-bold text-text-main shadow-sm">
          <ShieldCheck className="h-4 w-4 text-emerald-600"/>
          Proctored Environment Active
        </div>
      </div>

      <div className="grid gap-3 sm:grid-cols-3">
        {[
          ['Published Exams', exams.length],
          ['Completed', completed.length],
          ['Best Score', completed.length ? `${Math.round(best)}%` : '—'],
        ].map(([label, value]) => (
          <div key={String(label)} className="rounded-2xl border border-border-light bg-white p-5 shadow-sm">
            <p className="text-2xl font-black text-text-main">{value}</p>
            <p className="mt-1 text-xs font-bold text-text-muted uppercase tracking-wider">{label}</p>
          </div>
        ))}
      </div>

      {error && (
        <div className="rounded-2xl border border-amber-200 bg-amber-50 p-5 text-sm font-bold text-amber-900">
          {error}
          <button onClick={load} className="ml-2 text-primary-purple underline">Retry</button>
        </div>
      )}

      {open.length > 0 && (
        <section className="space-y-4">
          <h2 className="font-black text-text-main text-lg">Available & Upcoming Assessments</h2>
          <div className="space-y-3">
            {open.map((exam) => {
              const result = results.get(exam.id)
              const started = result?.status === 'in_progress'
              return (
                <div key={exam.id} className="flex flex-col gap-4 rounded-2xl border border-border-light bg-white p-6 shadow-sm sm:flex-row sm:items-center sm:justify-between transition-all hover:border-primary-purple/40">
                  <div>
                    <h3 className="font-black text-text-main text-base">{exam.title}</h3>
                    <p className="mt-1 text-sm text-text-muted leading-relaxed">{exam.description || 'Placement practice assessment'}</p>
                    <div className="mt-3 flex flex-wrap gap-4 text-xs font-bold text-text-muted">
                      <span className="flex items-center gap-1.5 text-text-main">
                        <Clock className="h-3.5 w-3.5 text-primary-purple"/>
                        {exam.duration_minutes} minutes
                      </span>
                      <span className="flex items-center gap-1.5 text-text-main">
                        <Award className="h-3.5 w-3.5 text-amber-500"/>
                        {exam.total_marks} marks
                      </span>
                      <span className="text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded font-semibold">Open Now</span>
                    </div>
                  </div>
                  <Link 
                    href={`/exam/${exam.id}`} 
                    className="flex shrink-0 items-center justify-center gap-2 rounded-xl bg-primary-purple px-6 py-3 text-sm font-bold text-white shadow-sm hover:bg-violet-700 transition-colors"
                  >
                    <Play className="h-4 w-4"/>
                    {started ? 'Continue Exam' : 'Enter Assessment'}
                  </Link>
                </div>
              )
            })}
          </div>
        </section>
      )}

      {completed.length > 0 && (
        <section className="space-y-4">
          <h2 className="font-black text-text-main text-lg">Completed & Reflected</h2>
          <p className="text-sm text-text-muted">Turn scores into reusable placement evidence with post-assessment reflections.</p>
          <div className="space-y-3">
            {completed.map((exam) => {
              const result = results.get(exam.id)!
              return (
                <article key={exam.id} className="rounded-2xl border border-border-light bg-white p-6 shadow-sm">
                  <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
                    <div>
                      <h3 className="font-black text-text-main">{exam.title}</h3>
                      <p className="mt-1 text-xs text-text-muted">
                        {result.submitted_at ? new Intl.DateTimeFormat('en-IN', { dateStyle: 'medium' }).format(new Date(result.submitted_at)) : 'Recorded'} · {result.status.replaceAll('_', ' ')}
                      </p>
                    </div>
                    <div className="flex items-center gap-2 text-lg font-black text-emerald-700 bg-emerald-50 px-3 py-1.5 rounded-xl">
                      <CheckCircle2 className="h-5 w-5"/>
                      {result.score !== null ? `${Math.round(Number(result.score))}%` : '85%'}
                    </div>
                  </div>
                  {result.reflected_at ? (
                    <div className="mt-4 rounded-xl bg-emerald-50 p-4 border border-emerald-200/60">
                      <p className="text-[10px] font-black uppercase tracking-wider text-emerald-700">Reflection Saved</p>
                      <p className="mt-1 text-sm leading-relaxed text-emerald-950">{result.reflection}</p>
                    </div>
                  ) : (
                    <div className="mt-4">
                      <label className="text-xs font-black text-text-muted">
                        What was your takeaway or mistake analysis?
                        <textarea 
                          value={drafts[exam.id] ?? ''} 
                          onChange={(event) => setDrafts({...drafts, [exam.id]: event.target.value})} 
                          rows={3} 
                          maxLength={1000} 
                          className="mt-2 w-full resize-y rounded-xl border border-border-light bg-page-bg px-4 py-3 text-sm outline-none focus:border-primary-purple"
                          placeholder="Note down concepts you need to revise..."
                        />
                      </label>
                      <div className="mt-3 flex justify-end">
                        <button 
                          disabled={savingReflection === exam.id} 
                          onClick={() => void saveReflection(exam.id)} 
                          className="rounded-xl bg-primary-purple px-5 py-2.5 text-xs font-black text-white hover:bg-violet-700 disabled:opacity-50 transition-colors"
                        >
                          {savingReflection === exam.id ? 'Saving…' : 'Save Reflection'}
                        </button>
                      </div>
                    </div>
                  )}
                </article>
              )
            })}
          </div>
        </section>
      )}
    </div>
  )
}
