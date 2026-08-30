'use client'

import React from 'react'
import { CalendarClock, CheckCircle2, ClipboardList, Plus, Send, ShieldCheck, WandSparkles } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { getCurrentProfile } from '@/lib/current-profile'
import type { Database } from '@/../../supabase/types/database.types'

type Exam = Database['public']['Tables']['mock_exams']['Row']
type Batch = Pick<Database['public']['Tables']['batches']['Row'], 'id' | 'batch_code' | 'status'>

const examDefaults = { title: '', description: '', duration: 45, examDate: '', batchId: '' }
const questionDefaults = { text: '', a: '', b: '', c: '', d: '', correct: 'A' as 'A' | 'B' | 'C' | 'D', marks: 1 }
const blueprintDefaults = { batchId: '', title: 'Weekly readiness check', topics: '', count: 20, duration: 30, perWeek: 1, weekday: 6 }

export default function AssessmentStudioPage() {
  const supabase = React.useMemo(() => createClient(), [])
  const [exams, setExams] = React.useState<Exam[]>([])
  const [batches, setBatches] = React.useState<Batch[]>([])
  const [selectedExam, setSelectedExam] = React.useState<string>('')
  const [questionCount, setQuestionCount] = React.useState<Record<string, number>>({})
  const [examForm, setExamForm] = React.useState(examDefaults)
  const [questionForm, setQuestionForm] = React.useState(questionDefaults)
  const [loading, setLoading] = React.useState(true)
  const [busy, setBusy] = React.useState(false)
  const [error, setError] = React.useState('')
  const [message, setMessage] = React.useState('')
  const [blueprintForm, setBlueprintForm] = React.useState(blueprintDefaults)
  const [facultyId, setFacultyId] = React.useState('')

  const load = React.useCallback(async () => {
    setLoading(true)
    setError('')
    try {
      const me = await getCurrentProfile(supabase)
      if (!me) throw new Error('Your faculty profile could not be loaded.')
      setFacultyId(me.id)
      const [examResult, batchResult, questionResult, blueprintResult] = await Promise.all([
        supabase.from('mock_exams').select('*').order('exam_date', { ascending: false }),
        supabase.from('batches').select('id,batch_code,status').neq('status', 'graduated').order('start_year', { ascending: false }),
        supabase.from('mock_exam_questions').select('exam_id'),
        (supabase as any).from('assessment_blueprints').select('*').eq('owner_faculty_id', me.id).eq('active', true).order('updated_at', { ascending: false }).limit(1).maybeSingle(),
      ])
      if (examResult.error) throw examResult.error
      if (batchResult.error) throw batchResult.error
      if (questionResult.error) throw questionResult.error
      setExams(examResult.data ?? [])
      setBatches(batchResult.data ?? [])
      if (blueprintResult.data) setBlueprintForm({
        batchId: blueprintResult.data.batch_id,
        title: blueprintResult.data.title_prefix,
        topics: (blueprintResult.data.topics || []).join(', '),
        count: blueprintResult.data.question_count,
        duration: blueprintResult.data.duration_minutes,
        perWeek: blueprintResult.data.exams_per_week,
        weekday: blueprintResult.data.publish_weekday,
      })
      const counts: Record<string, number> = {}
      for (const row of questionResult.data ?? []) counts[row.exam_id] = (counts[row.exam_id] ?? 0) + 1
      setQuestionCount(counts)
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : 'Assessment Studio could not be loaded.')
    } finally {
      setLoading(false)
    }
  }, [supabase])

  React.useEffect(() => { void load() }, [load])

  async function saveBlueprint(event: React.FormEvent) {
    event.preventDefault()
    if (!facultyId || !blueprintForm.batchId) return
    setBusy(true); setError(''); setMessage('')
    const topics = blueprintForm.topics.split(',').map((value) => value.trim()).filter(Boolean)
    const { error: saveError } = await (supabase as any).from('assessment_blueprints').upsert({
      batch_id: blueprintForm.batchId,
      owner_faculty_id: facultyId,
      title_prefix: blueprintForm.title.trim(),
      topics,
      question_count: blueprintForm.count,
      duration_minutes: blueprintForm.duration,
      exams_per_week: blueprintForm.perWeek,
      publish_weekday: blueprintForm.weekday,
      active: true,
      updated_at: new Date().toISOString(),
    }, { onConflict: 'batch_id,owner_faculty_id' })
    if (saveError) setError(saveError.message)
    else setMessage('Automation blueprint saved. One or two assessments will be assembled weekly from the approved question bank.')
    setBusy(false)
  }

  async function createExam(event: React.FormEvent) {
    event.preventDefault()
    setBusy(true)
    setError('')
    setMessage('')
    try {
      const me = await getCurrentProfile(supabase)
      if (!me) throw new Error('Your faculty profile could not be loaded.')
      const { data, error: createError } = await supabase.from('mock_exams').insert({
        title: examForm.title.trim(),
        description: examForm.description.trim() || null,
        duration_minutes: examForm.duration,
        exam_date: examForm.examDate ? new Date(examForm.examDate).toISOString() : null,
        batch_id: examForm.batchId || null,
        created_by: me.id,
      }).select('id').single()
      if (createError) throw createError
      setSelectedExam(data.id)
      setExamForm(examDefaults)
      setMessage('Assessment created. Add reviewed questions before directing students to it.')
      await load()
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : 'Assessment could not be created.')
    } finally {
      setBusy(false)
    }
  }

  async function addQuestion(event: React.FormEvent) {
    event.preventDefault()
    if (!selectedExam) return
    setBusy(true)
    setError('')
    setMessage('')
    try {
      const orderIndex = questionCount[selectedExam] ?? 0
      const { error: insertError } = await supabase.from('mock_exam_questions').insert({
        exam_id: selectedExam,
        question_text: questionForm.text.trim(),
        option_a: questionForm.a.trim(),
        option_b: questionForm.b.trim(),
        option_c: questionForm.c.trim(),
        option_d: questionForm.d.trim(),
        correct_option: questionForm.correct,
        marks: questionForm.marks,
        order_index: orderIndex,
      })
      if (insertError) throw insertError
      const exam = exams.find((item) => item.id === selectedExam)
      await supabase.from('mock_exams').update({ total_marks: (exam?.total_marks ?? 0) + questionForm.marks }).eq('id', selectedExam)
      setQuestionForm(questionDefaults)
      setMessage('Reviewed question added to the assessment blueprint.')
      await load()
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : 'Question could not be added.')
    } finally {
      setBusy(false)
    }
  }

  return <div className="mx-auto max-w-7xl space-y-6">
    <header>
      <div className="mb-2 flex items-center gap-2 text-xs font-black uppercase tracking-[.16em] text-primary-purple"><ClipboardList className="h-4 w-4"/> Evidence-based preparation</div>
      <h1 className="text-3xl font-black tracking-tight">Mock Assessment Studio</h1>
      <p className="mt-2 max-w-3xl text-sm leading-6 text-text-muted">Create low-stakes, explainable assessments that lead directly to remediation. Official placement tests and drives remain outside PSGMX.</p>
    </header>

    <div className="flex gap-3 rounded-2xl border border-blue-200 bg-blue-50 p-4 text-xs font-semibold leading-5 text-blue-900"><ShieldCheck className="mt-0.5 h-5 w-5 shrink-0"/><span>Students receive question-level explanations only after submission. Every assessment should have a clear learning objective and a follow-up preparation path.</span></div>
    {error && <div role="alert" className="flex items-center justify-between rounded-2xl border border-red-200 bg-red-50 p-4 text-sm font-bold text-red-700"><span>{error}</span><button onClick={() => void load()} className="rounded-lg px-3 py-1.5 hover:bg-red-100">Retry</button></div>}
    {message && <div className="rounded-2xl border border-emerald-200 bg-emerald-50 p-4 text-sm font-bold text-emerald-800">{message}</div>}

    <form onSubmit={saveBlueprint} className="rounded-3xl border border-violet-200 bg-violet-50/60 p-6">
      <div className="flex items-start gap-3"><WandSparkles className="mt-1 h-5 w-5 text-primary-purple"/><div><h2 className="text-lg font-black">Weekly automation blueprint</h2><p className="mt-1 text-xs leading-5 text-text-muted">Set the academic boundaries once. PSGMX automatically assembles one or two idempotent weekly mocks from approved bank questions; faculty ownership remains explicit.</p></div></div>
      <div className="mt-5 grid gap-4 md:grid-cols-2 xl:grid-cols-4">
        <label className="text-xs font-bold text-text-muted">Batch<select required value={blueprintForm.batchId} onChange={(event) => setBlueprintForm({ ...blueprintForm, batchId: event.target.value })} className="mt-2 w-full rounded-xl border border-border-light bg-white px-3 py-2.5 text-sm"><option value="">Choose batch</option>{batches.map((batch) => <option key={batch.id} value={batch.id}>{batch.batch_code}</option>)}</select></label>
        <label className="text-xs font-bold text-text-muted">Assessments per week<select value={blueprintForm.perWeek} onChange={(event) => setBlueprintForm({ ...blueprintForm, perWeek: Number(event.target.value) })} className="mt-2 w-full rounded-xl border border-border-light bg-white px-3 py-2.5 text-sm"><option value={1}>One</option><option value={2}>Two</option></select></label>
        <label className="text-xs font-bold text-text-muted">Questions<input type="number" min={5} max={50} value={blueprintForm.count} onChange={(event) => setBlueprintForm({ ...blueprintForm, count: Number(event.target.value) })} className="mt-2 w-full rounded-xl border border-border-light bg-white px-3 py-2.5 text-sm"/></label>
        <label className="text-xs font-bold text-text-muted">Duration<input type="number" min={10} max={120} value={blueprintForm.duration} onChange={(event) => setBlueprintForm({ ...blueprintForm, duration: Number(event.target.value) })} className="mt-2 w-full rounded-xl border border-border-light bg-white px-3 py-2.5 text-sm"/></label>
        <label className="text-xs font-bold text-text-muted md:col-span-2">Title prefix<input required minLength={3} value={blueprintForm.title} onChange={(event) => setBlueprintForm({ ...blueprintForm, title: event.target.value })} className="mt-2 w-full rounded-xl border border-border-light bg-white px-3 py-2.5 text-sm"/></label>
        <label className="text-xs font-bold text-text-muted md:col-span-2">Question-bank topics (comma separated; blank uses all)<input value={blueprintForm.topics} onChange={(event) => setBlueprintForm({ ...blueprintForm, topics: event.target.value })} placeholder="dbms, oop, operating_systems" className="mt-2 w-full rounded-xl border border-border-light bg-white px-3 py-2.5 text-sm"/></label>
      </div>
      <div className="mt-4 flex justify-end"><button disabled={busy || !facultyId} className="rounded-xl bg-primary-purple px-5 py-2.5 text-sm font-black text-white disabled:opacity-50">Save automation blueprint</button></div>
    </form>

    <div className="grid gap-6 xl:grid-cols-[.85fr_1.4fr]">
      <div className="space-y-6">
        <form onSubmit={createExam} className="space-y-4 rounded-3xl border border-border-light bg-white p-6 shadow-sm">
          <div><h2 className="text-lg font-black">Create assessment</h2><p className="mt-1 text-xs text-text-muted">Define the window and audience, then add reviewed questions.</p></div>
          <label className="block text-xs font-bold text-text-muted">Title<input required minLength={3} value={examForm.title} onChange={(event) => setExamForm({ ...examForm, title: event.target.value })} placeholder="Core CS readiness checkpoint" className="mt-2 w-full rounded-xl border border-border-light px-4 py-3 text-sm text-text-main outline-none focus:border-primary-purple"/></label>
          <label className="block text-xs font-bold text-text-muted">Learning objective<textarea value={examForm.description} onChange={(event) => setExamForm({ ...examForm, description: event.target.value })} placeholder="What should this assessment reveal?" className="mt-2 min-h-24 w-full rounded-xl border border-border-light px-4 py-3 text-sm text-text-main outline-none focus:border-primary-purple"/></label>
          <div className="grid gap-3 sm:grid-cols-2"><label className="text-xs font-bold text-text-muted">Duration (minutes)<input type="number" min={5} max={240} value={examForm.duration} onChange={(event) => setExamForm({ ...examForm, duration: Number(event.target.value) })} className="mt-2 w-full rounded-xl border border-border-light px-4 py-3 text-sm"/></label><label className="text-xs font-bold text-text-muted">Target batch<select required value={examForm.batchId} onChange={(event) => setExamForm({ ...examForm, batchId: event.target.value })} className="mt-2 w-full rounded-xl border border-border-light px-4 py-3 text-sm"><option value="">Choose batch</option>{batches.map((batch) => <option key={batch.id} value={batch.id}>{batch.batch_code} · {batch.status.replace('_', ' ')}</option>)}</select></label></div>
          <label className="block text-xs font-bold text-text-muted">Available from<input required type="datetime-local" value={examForm.examDate} onChange={(event) => setExamForm({ ...examForm, examDate: event.target.value })} className="mt-2 w-full rounded-xl border border-border-light px-4 py-3 text-sm"/></label>
          <button disabled={busy} className="flex w-full items-center justify-center gap-2 rounded-xl bg-primary-purple px-5 py-3 text-sm font-black text-white disabled:opacity-50"><Plus className="h-4 w-4"/>{busy ? 'Saving…' : 'Create assessment'}</button>
        </form>

        <form onSubmit={addQuestion} className="space-y-4 rounded-3xl border border-border-light bg-white p-6 shadow-sm">
          <div><h2 className="text-lg font-black">Add reviewed question</h2><p className="mt-1 text-xs text-text-muted">Correct answers remain server-side during attempts.</p></div>
          <label className="block text-xs font-bold text-text-muted">Assessment<select required value={selectedExam} onChange={(event) => setSelectedExam(event.target.value)} className="mt-2 w-full rounded-xl border border-border-light px-4 py-3 text-sm"><option value="">Choose assessment</option>{exams.map((exam) => <option key={exam.id} value={exam.id}>{exam.title}</option>)}</select></label>
          <label className="block text-xs font-bold text-text-muted">Question<textarea required value={questionForm.text} onChange={(event) => setQuestionForm({ ...questionForm, text: event.target.value })} className="mt-2 min-h-24 w-full rounded-xl border border-border-light px-4 py-3 text-sm text-text-main outline-none focus:border-primary-purple"/></label>
          <div className="grid gap-3 sm:grid-cols-2">{(['a','b','c','d'] as const).map((key) => <label key={key} className="text-xs font-bold uppercase text-text-muted">Option {key.toUpperCase()}<input required value={questionForm[key]} onChange={(event) => setQuestionForm({ ...questionForm, [key]: event.target.value })} className="mt-2 w-full rounded-xl border border-border-light px-4 py-3 text-sm normal-case"/></label>)}</div>
          <div className="grid gap-3 sm:grid-cols-2"><label className="text-xs font-bold text-text-muted">Correct option<select value={questionForm.correct} onChange={(event) => setQuestionForm({ ...questionForm, correct: event.target.value as 'A' | 'B' | 'C' | 'D' })} className="mt-2 w-full rounded-xl border border-border-light px-4 py-3 text-sm">{['A','B','C','D'].map((value) => <option key={value}>{value}</option>)}</select></label><label className="text-xs font-bold text-text-muted">Marks<input type="number" min={1} max={20} value={questionForm.marks} onChange={(event) => setQuestionForm({ ...questionForm, marks: Number(event.target.value) })} className="mt-2 w-full rounded-xl border border-border-light px-4 py-3 text-sm"/></label></div>
          <button disabled={busy || !selectedExam} className="flex w-full items-center justify-center gap-2 rounded-xl bg-rich-black px-5 py-3 text-sm font-black text-white disabled:opacity-50"><Send className="h-4 w-4"/>{busy ? 'Saving…' : 'Add question'}</button>
        </form>
      </div>

      <section className="space-y-4">
        <div><h2 className="text-lg font-black">Assessment lifecycle</h2><p className="mt-1 text-xs text-text-muted">Create → review questions → student attempt → explanation → remediation → reflection.</p></div>
        {loading && <div className="h-44 animate-pulse rounded-3xl bg-white"/>}
        {!loading && exams.length === 0 && <div className="rounded-3xl border border-dashed border-border-light bg-white p-14 text-center"><ClipboardList className="mx-auto h-10 w-10 text-primary-purple"/><h3 className="mt-4 font-black">No assessment has been created</h3><p className="mt-2 text-sm text-text-muted">Start with a small diagnostic that leads to a useful next action.</p></div>}
        {exams.map((exam) => {
          const batch = batches.find((item) => item.id === exam.batch_id)
          const count = questionCount[exam.id] ?? 0
          return <article key={exam.id} className="rounded-3xl border border-border-light bg-white p-6 shadow-sm">
            <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between"><div><span className="text-[10px] font-black uppercase tracking-[.14em] text-primary-purple">{batch?.batch_code ?? 'Department'} assessment</span><h3 className="mt-2 text-xl font-black">{exam.title}</h3><p className="mt-2 max-w-2xl text-sm leading-6 text-text-muted">{exam.description || 'Add a clear learning objective before student communication.'}</p></div><button onClick={() => setSelectedExam(exam.id)} className="shrink-0 rounded-xl border border-border-light px-4 py-2 text-xs font-black text-primary-purple hover:bg-page-bg">Add question</button></div>
            <div className="mt-5 flex flex-wrap gap-4 text-xs font-bold text-text-muted"><span className="flex items-center gap-1.5"><CalendarClock className="h-4 w-4"/>{exam.exam_date ? new Date(exam.exam_date).toLocaleString('en-IN', { dateStyle: 'medium', timeStyle: 'short' }) : 'Window not set'}</span><span className="flex items-center gap-1.5"><CheckCircle2 className="h-4 w-4"/>{count} question{count === 1 ? '' : 's'} · {exam.total_marks} marks</span></div>
            {count === 0 && <div className="mt-4 rounded-xl bg-amber-50 p-3 text-xs font-bold text-amber-800">This assessment is not ready for students until reviewed questions are added.</div>}
          </article>
        })}
      </section>
    </div>
  </div>
}
