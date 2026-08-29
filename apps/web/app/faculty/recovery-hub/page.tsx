'use client'

import React from 'react'
import { CalendarCheck, CheckCircle2, HeartHandshake, Plus, Search, ShieldCheck } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { getCurrentProfile } from '@/lib/current-profile'
import type { Database } from '@/../../supabase/types/database.types'

type SupportCase = Database['public']['Tables']['support_cases']['Row']
type Student = Pick<Database['public']['Tables']['users']['Row'], 'id' | 'name' | 'reg_no'>

const initialForm = { studentId: '', title: '', context: '', goal: '', reviewAt: '' }

export default function FacultyRecoveryHubPage() {
  const supabase = React.useMemo(() => createClient(), [])
  const [cases, setCases] = React.useState<SupportCase[]>([])
  const [students, setStudents] = React.useState<Student[]>([])
  const [query, setQuery] = React.useState('')
  const [status, setStatus] = React.useState('open')
  const [form, setForm] = React.useState(initialForm)
  const [showForm, setShowForm] = React.useState(false)
  const [loading, setLoading] = React.useState(true)
  const [busy, setBusy] = React.useState(false)
  const [error, setError] = React.useState('')
  const [message, setMessage] = React.useState('')

  const load = React.useCallback(async () => {
    setLoading(true)
    setError('')
    try {
      const [caseResult, studentResult] = await Promise.all([
        supabase.from('support_cases').select('*').order('updated_at', { ascending: false }),
        supabase.from('users').select('id,name,reg_no').eq('role_label', 'Student').order('name'),
      ])
      if (caseResult.error) throw caseResult.error
      if (studentResult.error) throw studentResult.error
      setCases(caseResult.data ?? [])
      setStudents(studentResult.data ?? [])
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : 'Recovery cases could not be loaded.')
    } finally {
      setLoading(false)
    }
  }, [supabase])

  React.useEffect(() => { void load() }, [load])

  async function createCase(event: React.FormEvent) {
    event.preventDefault()
    setBusy(true)
    setError('')
    setMessage('')
    try {
      const me = await getCurrentProfile(supabase)
      if (!me) throw new Error('Your faculty profile could not be loaded.')
      const { error: createError } = await supabase.from('support_cases').insert({
        student_id: form.studentId,
        case_type: 'evidence_gap',
        title: form.title.trim(),
        context: form.context.trim(),
        status: 'active',
        owner_id: me.id,
        goal: form.goal.trim() || null,
        review_at: form.reviewAt ? new Date(form.reviewAt).toISOString() : null,
        created_by: me.id,
      })
      if (createError) throw createError
      setForm(initialForm)
      setShowForm(false)
      setMessage('Support plan started. The student can now see the goal and review date.')
      await load()
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : 'Support plan could not be created.')
    } finally {
      setBusy(false)
    }
  }

  async function updateCase(item: SupportCase, nextStatus: SupportCase['status']) {
    setError('')
    const { error: updateError } = await supabase.from('support_cases').update({
      status: nextStatus,
      resolution: nextStatus === 'resolved' ? 'Recovery goal reviewed with the student.' : item.resolution,
      updated_at: new Date().toISOString(),
    }).eq('id', item.id)
    if (updateError) return setError(updateError.message)
    setCases((current) => current.map((value) => value.id === item.id ? { ...value, status: nextStatus } : value))
  }

  const studentMap = new Map(students.map((student) => [student.id, student]))
  const filtered = cases.filter((item) => {
    const student = studentMap.get(item.student_id)
    const matchesSearch = `${item.title} ${item.context} ${student?.name ?? ''} ${student?.reg_no ?? ''}`.toLowerCase().includes(query.toLowerCase())
    const matchesStatus = status === 'all' || (status === 'open'
      ? !['resolved', 'closed'].includes(item.status)
      : item.status === status)
    return matchesSearch && matchesStatus
  })

  return <div className="mx-auto max-w-7xl space-y-6">
    <header className="flex flex-col gap-4 lg:flex-row lg:items-end lg:justify-between"><div><div className="mb-2 flex items-center gap-2 text-xs font-black uppercase tracking-[.16em] text-primary-purple"><HeartHandshake className="h-4 w-4"/> Evidence-led support</div><h1 className="text-3xl font-black tracking-tight">Recovery Hub</h1><p className="mt-2 max-w-3xl text-sm leading-6 text-text-muted">Turn sustained evidence gaps or student requests into a private, time-bound support plan. Automation may suggest; faculty decides.</p></div><button onClick={() => setShowForm((value) => !value)} className="inline-flex items-center justify-center gap-2 rounded-xl bg-primary-purple px-5 py-3 text-sm font-black text-white"><Plus className="h-4 w-4"/>{showForm ? 'Close' : 'Start support plan'}</button></header>
    <div className="flex gap-3 rounded-2xl border border-blue-200 bg-blue-50 p-4 text-xs font-semibold leading-5 text-blue-900"><ShieldCheck className="mt-0.5 h-5 w-5 shrink-0"/>Recovery is private support, never a public label. PR and peers cannot see faculty notes or individual readiness evidence.</div>
    {error && <div role="alert" className="rounded-2xl border border-red-200 bg-red-50 p-4 text-sm font-bold text-red-700">{error}</div>}
    {message && <div className="rounded-2xl border border-emerald-200 bg-emerald-50 p-4 text-sm font-bold text-emerald-800">{message}</div>}

    {showForm && <form onSubmit={createCase} className="grid gap-4 rounded-3xl border border-border-light bg-white p-6 shadow-sm md:grid-cols-2"><div className="md:col-span-2"><h2 className="text-lg font-black">New support plan</h2><p className="mt-1 text-xs text-text-muted">Review the student's context before starting a case.</p></div><label className="text-xs font-bold text-text-muted">Student<select required value={form.studentId} onChange={(event) => setForm({ ...form, studentId: event.target.value })} className="mt-2 w-full rounded-xl border border-border-light px-4 py-3 text-sm"><option value="">Choose student</option>{students.map((student) => <option key={student.id} value={student.id}>{student.name} · {student.reg_no}</option>)}</select></label><label className="text-xs font-bold text-text-muted">Review date<input required type="datetime-local" value={form.reviewAt} onChange={(event) => setForm({ ...form, reviewAt: event.target.value })} className="mt-2 w-full rounded-xl border border-border-light px-4 py-3 text-sm"/></label><label className="text-xs font-bold text-text-muted md:col-span-2">Support title<input required value={form.title} onChange={(event) => setForm({ ...form, title: event.target.value })} placeholder="Refresh DBMS evidence with a guided sprint" className="mt-2 w-full rounded-xl border border-border-light px-4 py-3 text-sm outline-none focus:border-primary-purple"/></label><label className="text-xs font-bold text-text-muted">Context<textarea required minLength={10} value={form.context} onChange={(event) => setForm({ ...form, context: event.target.value })} placeholder="What evidence or request led to this plan?" className="mt-2 min-h-28 w-full rounded-xl border border-border-light px-4 py-3 text-sm outline-none focus:border-primary-purple"/></label><label className="text-xs font-bold text-text-muted">Agreed goal<textarea value={form.goal} onChange={(event) => setForm({ ...form, goal: event.target.value })} placeholder="A small, observable outcome" className="mt-2 min-h-28 w-full rounded-xl border border-border-light px-4 py-3 text-sm outline-none focus:border-primary-purple"/></label><button disabled={busy} className="rounded-xl bg-primary-purple px-5 py-3 text-sm font-black text-white disabled:opacity-50 md:col-span-2">{busy ? 'Starting…' : 'Start private support plan'}</button></form>}

    <div className="flex flex-col gap-3 rounded-2xl border border-border-light bg-white p-3 sm:flex-row"><label className="relative flex-1"><Search className="absolute left-3 top-3 h-4 w-4 text-text-muted"/><input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Search student or support context" className="w-full rounded-xl bg-page-bg py-2.5 pl-10 pr-4 text-sm outline-none"/></label><select value={status} onChange={(event) => setStatus(event.target.value)} className="rounded-xl border border-border-light px-4 py-2.5 text-sm font-bold"><option value="open">Open work</option><option value="requested">Requested</option><option value="active">Active</option><option value="review_due">Review due</option><option value="resolved">Resolved</option><option value="all">All cases</option></select></div>

    {loading && <div className="h-44 animate-pulse rounded-3xl bg-white"/>}
    {!loading && filtered.length === 0 && <div className="rounded-3xl border border-dashed border-border-light bg-white p-14 text-center"><CheckCircle2 className="mx-auto h-10 w-10 text-emerald-600"/><h2 className="mt-4 text-lg font-black">No support case needs attention</h2><p className="mt-2 text-sm text-text-muted">Student requests and reviewed evidence gaps will appear here.</p></div>}
    <div className="grid gap-4 lg:grid-cols-2">{filtered.map((item) => { const student = studentMap.get(item.student_id); return <article key={item.id} className="rounded-3xl border border-border-light bg-white p-6 shadow-sm"><div className="flex items-start justify-between gap-4"><div><span className="text-[10px] font-black uppercase tracking-[.14em] text-primary-purple">{item.status.replace('_', ' ')}</span><h2 className="mt-2 text-lg font-black">{item.title}</h2><p className="mt-1 text-xs font-bold text-text-muted">{student?.name ?? 'Student'} · {student?.reg_no ?? 'Register unavailable'}</p></div><HeartHandshake className="h-6 w-6 text-primary-purple"/></div><p className="mt-4 text-sm leading-6 text-text-muted">{item.context}</p>{item.goal && <div className="mt-4 rounded-2xl bg-page-bg p-4"><p className="text-[10px] font-black uppercase tracking-wider text-text-muted">Agreed goal</p><p className="mt-1 text-sm font-semibold">{item.goal}</p></div>}<div className="mt-5 flex flex-wrap items-center gap-3">{item.review_at && <span className="mr-auto flex items-center gap-1.5 text-xs font-bold text-text-muted"><CalendarCheck className="h-4 w-4"/>{new Date(item.review_at).toLocaleDateString('en-IN', { dateStyle: 'medium' })}</span>}{!['resolved','closed'].includes(item.status) && <button onClick={() => void updateCase(item, 'review_due')} className="rounded-xl border border-border-light px-3 py-2 text-xs font-black">Mark review due</button>}{!['resolved','closed'].includes(item.status) && <button onClick={() => void updateCase(item, 'resolved')} className="rounded-xl bg-emerald-600 px-3 py-2 text-xs font-black text-white">Resolve with student</button>}</div></article>})}</div>
  </div>
}
