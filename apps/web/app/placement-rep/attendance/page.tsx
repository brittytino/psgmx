'use client'

import React from 'react'
import { CheckCircle2, CircleX, Save, CalendarDays } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { getCurrentProfile } from '@/lib/current-profile'

type Session = { id: string; topic: string; session_datetime: string; is_locked: boolean | null }
type Student = { id: string; name: string; reg_no: string }
type AttendanceStatus = 'present' | 'absent' | 'excused'

export default function AttendancePage() {
  const supabase = React.useMemo(() => createClient(), [])
  const [sessions, setSessions] = React.useState<Session[]>([])
  const [students, setStudents] = React.useState<Student[]>([])
  const [selected, setSelected] = React.useState('')
  const [statuses, setStatuses] = React.useState<Record<string, AttendanceStatus>>({})
  const [actorId, setActorId] = React.useState('')
  const [saving, setSaving] = React.useState(false)
  const [message, setMessage] = React.useState('')

  React.useEffect(() => {
    void (async () => {
      const me = await getCurrentProfile(supabase)
      if (!me?.batch_id) return
      setActorId(me.id)
      const teamLeaderOnly = Boolean(me.roles?.isTeamLeader) && !me.roles?.isPlacementRep
      let studentQuery = supabase.from('users').select('id,name,reg_no').eq('batch_id', me.batch_id).eq('role_label', 'Student').order('reg_no')
      if (teamLeaderOnly && me.team_uuid) studentQuery = studentQuery.eq('team_uuid', me.team_uuid)
      const [{ data: sessionRows }, { data: studentRows }] = await Promise.all([
        supabase.from('placement_sessions').select('id,topic,session_datetime,is_locked').eq('batch_id', me.batch_id).order('session_datetime', { ascending: false }).limit(30),
        studentQuery,
      ])
      setSessions(sessionRows ?? [])
      setStudents(studentRows ?? [])
      if (sessionRows?.[0]) setSelected(sessionRows[0].id)
    })()
  }, [supabase])

  React.useEffect(() => {
    if (!selected) return
    void (async () => {
      const { data } = await supabase.from('placement_attendance').select('user_id,status').eq('session_id', selected)
      setStatuses(Object.fromEntries((data ?? []).map((row) => [row.user_id, row.status as AttendanceStatus])))
    })()
  }, [selected, supabase])

  function markAll(status: AttendanceStatus) {
    setStatuses(Object.fromEntries(students.map((student) => [student.id, status])))
  }

  async function save() {
    if (!selected || !actorId) return
    setSaving(true)
    setMessage('')
    const rows = students.map((student) => ({
      session_id: selected,
      user_id: student.id,
      status: statuses[student.id] ?? 'absent',
      marked_by: actorId,
      marked_at: new Date().toISOString(),
    }))
    const { error } = await supabase.from('placement_attendance').upsert(rows, { onConflict: 'session_id,user_id' })
    setMessage(error ? error.message : `Participation saved for ${rows.length} students.`)
    setSaving(false)
  }

  const session = sessions.find((item) => item.id === selected)
  return <div className="max-w-5xl space-y-6">
    <div><h1 className="text-2xl font-black">Preparation Participation</h1><p className="mt-1 text-sm text-text-muted">Record participation for one preparation session. Team leaders only manage their assigned squad.</p></div>
    <div className="rounded-2xl border border-border-light bg-white p-5">
      <label className="mb-2 block text-xs font-bold uppercase text-text-muted">Session</label>
      <select value={selected} onChange={(e) => setSelected(e.target.value)} className="w-full rounded-xl border border-border-light px-4 py-3 text-sm outline-none">
        {sessions.map((item) => <option key={item.id} value={item.id}>{new Date(item.session_datetime).toLocaleString()} — {item.topic}</option>)}
      </select>
      {sessions.length === 0 && <p className="text-sm text-text-muted">Schedule a preparation session first.</p>}
    </div>

    {session && <div className="rounded-2xl border border-border-light bg-white">
      <div className="flex flex-col gap-3 border-b border-border-light p-5 sm:flex-row sm:items-center sm:justify-between">
        <div className="flex items-center gap-2"><CalendarDays className="h-5 w-5 text-primary-purple" /><p className="font-bold">{session.topic}</p></div>
        <div className="flex gap-2"><button onClick={() => markAll('present')} className="rounded-lg bg-green-50 px-3 py-2 text-xs font-bold text-green-700">All present</button><button onClick={() => markAll('absent')} className="rounded-lg bg-red-50 px-3 py-2 text-xs font-bold text-red-700">Reset absent</button></div>
      </div>
      <div className="divide-y divide-border-light">
        {students.map((student) => <div key={student.id} className="flex items-center justify-between p-4">
          <div><p className="text-sm font-bold">{student.name}</p><p className="text-xs text-text-muted">{student.reg_no}</p></div>
          <div className="flex gap-2">{(['present', 'absent', 'excused'] as const).map((status) => <button key={status} onClick={() => setStatuses((old) => ({ ...old, [student.id]: status }))} className={`rounded-lg px-3 py-2 text-xs font-bold capitalize ${statuses[student.id] === status ? status === 'present' ? 'bg-green-600 text-white' : status === 'absent' ? 'bg-red-600 text-white' : 'bg-amber-500 text-white' : 'bg-page-bg text-text-muted'}`}>{status === 'present' ? <CheckCircle2 className="mr-1 inline h-3.5 w-3.5" /> : status === 'absent' ? <CircleX className="mr-1 inline h-3.5 w-3.5" /> : null}{status}</button>)}</div>
        </div>)}
      </div>
      <div className="flex items-center justify-between border-t border-border-light p-5"><p className="text-sm font-semibold text-text-muted">{message}</p><button onClick={save} disabled={saving || session.is_locked === true} className="flex items-center gap-2 rounded-xl bg-primary-purple px-5 py-3 text-sm font-bold text-white disabled:opacity-50"><Save className="h-4 w-4" />{saving ? 'Saving…' : session.is_locked ? 'Session locked' : 'Save participation'}</button></div>
    </div>}
  </div>
}
