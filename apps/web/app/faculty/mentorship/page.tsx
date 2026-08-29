'use client'

import React from 'react'
import { CheckCircle2, Clock3, GraduationCap, MessageSquareText, Search, UserRoundCheck, XCircle } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { getCurrentProfile } from '@/lib/current-profile'
import type { Database } from '@/../../supabase/types/database.types'

type Request = Database['public']['Tables']['mentorship_requests']['Row']
type Student = Pick<Database['public']['Tables']['users']['Row'], 'id' | 'name' | 'reg_no'>

export default function FacultyMentorshipPage() {
  const supabase = React.useMemo(() => createClient(), [])
  const [requests, setRequests] = React.useState<Request[]>([])
  const [students, setStudents] = React.useState<Student[]>([])
  const [query, setQuery] = React.useState('')
  const [filter, setFilter] = React.useState('active')
  const [notes, setNotes] = React.useState<Record<string, string>>({})
  const [loading, setLoading] = React.useState(true)
  const [error, setError] = React.useState('')
  const [message, setMessage] = React.useState('')

  const load = React.useCallback(async () => {
    setLoading(true)
    setError('')
    try {
      const [requestResult, studentResult] = await Promise.all([
        supabase.from('mentorship_requests').select('*').order('updated_at', { ascending: false }),
        supabase.from('users').select('id,name,reg_no').eq('role_label', 'Student').order('name'),
      ])
      if (requestResult.error) throw requestResult.error
      if (studentResult.error) throw studentResult.error
      setRequests(requestResult.data ?? [])
      setStudents(studentResult.data ?? [])
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : 'Mentorship requests could not be loaded.')
    } finally {
      setLoading(false)
    }
  }, [supabase])

  React.useEffect(() => { void load() }, [load])

  async function transition(item: Request, status: Request['status']) {
    setError('')
    setMessage('')
    try {
      const me = await getCurrentProfile(supabase)
      if (!me) throw new Error('Your faculty profile could not be loaded.')
      const resolution = notes[item.id]?.trim() || null
      const { error: updateError } = await supabase.from('mentorship_requests').update({
        mentor_id: status === 'accepted' || status === 'answered' ? me.id : item.mentor_id,
        status,
        resolution_note: resolution,
        resolved_at: ['answered', 'declined', 'redirected'].includes(status) ? new Date().toISOString() : null,
        updated_at: new Date().toISOString(),
      }).eq('id', item.id)
      if (updateError) throw updateError
      setMessage(status === 'accepted' ? 'Mentorship request accepted. Agree one small next step with the student.' : 'Mentorship request updated.')
      await load()
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : 'The mentorship request could not be updated.')
    }
  }

  const studentMap = new Map(students.map((student) => [student.id, student]))
  const filtered = requests.filter((item) => {
    const student = studentMap.get(item.requester_id)
    const matchesQuery = `${item.topic} ${item.context} ${student?.name ?? ''} ${student?.reg_no ?? ''}`.toLowerCase().includes(query.toLowerCase())
    const matchesFilter = filter === 'all' || (filter === 'active'
      ? ['requested', 'accepted'].includes(item.status)
      : item.status === filter)
    return matchesQuery && matchesFilter
  })
  const awaiting = requests.filter((item) => item.status === 'requested').length
  const active = requests.filter((item) => item.status === 'accepted').length
  const resolved = requests.filter((item) => item.status === 'answered').length

  return <div className="mx-auto max-w-7xl space-y-6">
    <header><div className="mb-2 flex items-center gap-2 text-xs font-black uppercase tracking-[.16em] text-primary-purple"><GraduationCap className="h-4 w-4"/> Structured support</div><h1 className="text-3xl font-black tracking-tight">Mentorship</h1><p className="mt-2 max-w-3xl text-sm leading-6 text-text-muted">Respond to a real topic, agree one useful next step, and close the loop. Private conversation content is not exposed to PR or peers.</p></header>
    {error && <div role="alert" className="rounded-2xl border border-red-200 bg-red-50 p-4 text-sm font-bold text-red-700">{error}</div>}
    {message && <div className="rounded-2xl border border-emerald-200 bg-emerald-50 p-4 text-sm font-bold text-emerald-800">{message}</div>}

    <section className="grid gap-4 sm:grid-cols-3"><Metric icon={Clock3} label="Awaiting response" value={awaiting}/><Metric icon={UserRoundCheck} label="Active conversations" value={active}/><Metric icon={CheckCircle2} label="Questions resolved" value={resolved}/></section>
    <div className="flex flex-col gap-3 rounded-2xl border border-border-light bg-white p-3 sm:flex-row"><label className="relative flex-1"><Search className="absolute left-3 top-3 h-4 w-4 text-text-muted"/><input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Search student, topic or context" className="w-full rounded-xl bg-page-bg py-2.5 pl-10 pr-4 text-sm outline-none"/></label><select value={filter} onChange={(event) => setFilter(event.target.value)} className="rounded-xl border border-border-light px-4 py-2.5 text-sm font-bold"><option value="active">Needs attention</option><option value="requested">Requested</option><option value="accepted">Accepted</option><option value="answered">Resolved</option><option value="declined">Declined</option><option value="all">All</option></select></div>

    {loading && <div className="h-44 animate-pulse rounded-3xl bg-white"/>}
    {!loading && filtered.length === 0 && <div className="rounded-3xl border border-dashed border-border-light bg-white p-14 text-center"><CheckCircle2 className="mx-auto h-10 w-10 text-emerald-600"/><h2 className="mt-4 text-lg font-black">No mentorship request needs attention</h2><p className="mt-2 text-sm text-text-muted">New structured student requests will appear here.</p></div>}
    <div className="grid gap-4 lg:grid-cols-2">{filtered.map((item) => { const student = studentMap.get(item.requester_id); return <article key={item.id} className="rounded-3xl border border-border-light bg-white p-6 shadow-sm"><div className="flex items-start justify-between gap-4"><div><span className="text-[10px] font-black uppercase tracking-[.14em] text-primary-purple">{item.status} · {item.preferred_response.replace('_', ' ')}</span><h2 className="mt-2 text-lg font-black">{item.topic}</h2><p className="mt-1 text-xs font-bold text-text-muted">{student?.name ?? 'Student'} · {student?.reg_no ?? 'Register unavailable'}</p></div><MessageSquareText className="h-6 w-6 text-primary-purple"/></div><div className="mt-4 rounded-2xl bg-page-bg p-4 text-sm leading-6 text-text-muted">{item.context}</div>{item.resolution_note && <div className="mt-4 rounded-2xl border border-emerald-100 bg-emerald-50 p-4"><p className="text-[10px] font-black uppercase tracking-wider text-emerald-700">Recorded outcome</p><p className="mt-1 text-sm font-semibold text-emerald-900">{item.resolution_note}</p></div>}{['requested','accepted'].includes(item.status) && <><label className="mt-4 block text-xs font-bold text-text-muted">Response or agreed next step<textarea value={notes[item.id] ?? ''} onChange={(event) => setNotes({ ...notes, [item.id]: event.target.value })} placeholder="Record only the useful next step; keep sensitive notes elsewhere." className="mt-2 min-h-20 w-full rounded-xl border border-border-light px-3 py-2.5 text-sm outline-none focus:border-primary-purple"/></label><div className="mt-4 flex flex-wrap justify-end gap-2">{item.status === 'requested' && <button onClick={() => void transition(item, 'declined')} className="inline-flex items-center gap-1.5 rounded-xl border border-border-light px-3 py-2 text-xs font-black text-text-muted"><XCircle className="h-4 w-4"/>Decline</button>}{item.status === 'requested' && <button onClick={() => void transition(item, 'accepted')} className="inline-flex items-center gap-1.5 rounded-xl bg-primary-purple px-3 py-2 text-xs font-black text-white"><UserRoundCheck className="h-4 w-4"/>Accept</button>}{item.status === 'accepted' && <button onClick={() => void transition(item, 'answered')} disabled={!notes[item.id]?.trim()} className="inline-flex items-center gap-1.5 rounded-xl bg-emerald-600 px-3 py-2 text-xs font-black text-white disabled:opacity-50"><CheckCircle2 className="h-4 w-4"/>Resolve with next step</button>}</div></>}</article>})}</div>
  </div>
}

function Metric({ icon: Icon, label, value }: { icon: React.ComponentType<{ className?: string }>; label: string; value: number }) {
  return <div className="rounded-3xl border border-border-light bg-white p-5 shadow-sm"><Icon className="h-5 w-5 text-primary-purple"/><div className="mt-4 text-3xl font-black">{value}</div><div className="mt-1 text-xs font-bold text-text-muted">{label}</div></div>
}
