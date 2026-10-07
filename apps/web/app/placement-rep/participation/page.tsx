'use client'

import React, { useState, useEffect, useMemo, useCallback } from 'react'
import {
  CalendarDays,
  CheckCircle2,
  CircleX,
  AlertCircle,
  Save,
  Plus,
  Download,
  Search,
  Lock,
  Unlock,
  Users,
  Filter,
  Check,
  Clock,
  MapPin,
  Sparkles,
} from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { getCurrentProfile } from '@/lib/current-profile'

type Session = {
  id: string
  topic: string
  session_type: string | null
  session_mode: string | null
  location: string | null
  session_datetime: string
  duration_minutes: number | null
  is_locked: boolean | null
  batch_id: string
}

type Student = {
  id: string
  name: string
  reg_no: string
  batch_id: string | null
  team_uuid: string | null
}

type AttendanceStatus = 'present' | 'absent' | 'excused'

type BatchOption = {
  id: string
  batch_code: string
}

export default function ParticipationPage() {
  const supabase = useMemo(() => createClient(), [])

  const [batches, setBatches] = useState<BatchOption[]>([])
  const [selectedBatchId, setSelectedBatchId] = useState<string>('')
  const [myBatchId, setMyBatchId] = useState<string>('')
  const [actorId, setActorId] = useState<string>('')

  const [sessions, setSessions] = useState<Session[]>([])
  const [selectedSessionId, setSelectedSessionId] = useState<string>('')
  const [students, setStudents] = useState<Student[]>([])
  const [statuses, setStatuses] = useState<Record<string, AttendanceStatus>>({})

  const [searchQuery, setSearchQuery] = useState('')
  const [filterStatus, setFilterStatus] = useState<'all' | 'present' | 'absent' | 'excused'>('all')

  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [message, setMessage] = useState<{ text: string; type: 'success' | 'error' | 'info' } | null>(null)

  // Quick session creation modal
  const [showNewSessionModal, setShowNewSessionModal] = useState(false)
  const [creatingSession, setCreatingSession] = useState(false)
  const [newSessionForm, setNewSessionForm] = useState({
    topic: '',
    session_type: 'Skill Workshop',
    session_mode: 'Offline',
    location: '',
    date: new Date().toISOString().slice(0, 10),
    time: '17:00',
    duration_minutes: 60,
  })

  // 1. Initial Load: Profile & Batches
  useEffect(() => {
    void (async () => {
      setLoading(true)
      try {
        const me = await getCurrentProfile(supabase)
        if (!me?.id) return
        setActorId(me.id)
        if (me.batch_id) setMyBatchId(me.batch_id)

        // Load all available batches (25MX, 26MX)
        const { data: batchList } = await supabase
          .from('batches')
          .select('id, batch_code')
          .order('start_year', { ascending: false })

        const loadedBatches = (batchList ?? []) as BatchOption[]
        setBatches(loadedBatches)

        const defaultBatchId = me.batch_id || loadedBatches[0]?.id || ''
        setSelectedBatchId(defaultBatchId)
      } catch (err) {
        console.warn('Initialization error:', err)
      } finally {
        setLoading(false)
      }
    })()
  }, [supabase])

  // 2. Load Sessions & Students for Selected Batch
  const loadBatchData = useCallback(async (batchId: string) => {
    if (!batchId) return
    setLoading(true)
    setMessage(null)

    try {
      const [{ data: sessionRows }, { data: studentRows }] = await Promise.all([
        supabase
          .from('placement_sessions')
          .select('id, topic, session_type, session_mode, location, session_datetime, duration_minutes, is_locked, batch_id')
          .eq('batch_id', batchId)
          .order('session_datetime', { ascending: false })
          .limit(40),
        supabase
          .from('users')
          .select('id, name, reg_no, batch_id, team_uuid')
          .eq('batch_id', batchId)
          .eq('role_label', 'Student')
          .order('reg_no'),
      ])

      const validSessions = (sessionRows ?? []) as Session[]
      const validStudents = (studentRows ?? []) as Student[]

      setSessions(validSessions)
      setStudents(validStudents)

      // Select first session by default
      if (validSessions.length > 0) {
        setSelectedSessionId(validSessions[0].id)
      } else {
        setSelectedSessionId('')
        setStatuses({})
      }
    } catch (err) {
      console.warn('Batch data fetch error:', err)
    } finally {
      setLoading(false)
    }
  }, [supabase])

  useEffect(() => {
    if (selectedBatchId) {
      void loadBatchData(selectedBatchId)
    }
  }, [selectedBatchId, loadBatchData])

  // 3. Load Existing Attendance For Selected Session
  useEffect(() => {
    if (!selectedSessionId) {
      setStatuses({})
      return
    }

    void (async () => {
      try {
        const { data, error } = await supabase
          .from('placement_attendance')
          .select('user_id, status')
          .eq('session_id', selectedSessionId)

        if (!error && data) {
          const map: Record<string, AttendanceStatus> = {}
          data.forEach((row) => {
            map[row.user_id] = (row.status as AttendanceStatus) || 'absent'
          })
          setStatuses(map)
        }
      } catch (err) {
        console.warn('Attendance load error:', err)
      }
    })()
  }, [selectedSessionId, supabase])

  // Mark all students present or absent
  const markAll = (status: AttendanceStatus) => {
    const updated: Record<string, AttendanceStatus> = {}
    students.forEach((s) => {
      updated[s.id] = status
    })
    setStatuses(updated)
  }

  // Toggle single student
  const setStudentStatus = (studentId: string, status: AttendanceStatus) => {
    setStatuses((prev) => ({ ...prev, [studentId]: status }))
  }

  // Save Participation to Supabase
  const handleSave = async () => {
    if (!selectedSessionId || !actorId || students.length === 0) return
    setSaving(true)
    setMessage(null)

    try {
      const rows = students.map((s) => ({
        session_id: selectedSessionId,
        user_id: s.id,
        status: statuses[s.id] ?? 'absent',
        marked_by: actorId,
        marked_at: new Date().toISOString(),
      }))

      const { error } = await supabase
        .from('placement_attendance')
        .upsert(rows, { onConflict: 'session_id,user_id' })

      if (error) {
        setMessage({ text: `Failed to save: ${error.message}`, type: 'error' })
      } else {
        setMessage({ text: `Participation successfully saved for ${rows.length} students!`, type: 'success' })
      }
    } catch (err) {
      setMessage({
        text: `Error saving: ${err instanceof Error ? err.message : 'Unknown error'}`,
        type: 'error',
      })
    } finally {
      setSaving(false)
    }
  }

  // Quick Create Session
  const handleCreateSession = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!newSessionForm.topic.trim() || !selectedBatchId || !actorId) return

    setCreatingSession(true)
    try {
      const dt = new Date(`${newSessionForm.date}T${newSessionForm.time}`).toISOString()
      const { data, error } = await supabase
        .from('placement_sessions')
        .insert({
          batch_id: selectedBatchId,
          topic: newSessionForm.topic.trim(),
          session_type: newSessionForm.session_type,
          session_mode: newSessionForm.session_mode,
          location: newSessionForm.location.trim() || null,
          session_datetime: dt,
          duration_minutes: newSessionForm.duration_minutes,
          scheduled_by: actorId,
          is_locked: false,
        })
        .select()
        .single()

      if (error) {
        setMessage({ text: `Could not schedule session: ${error.message}`, type: 'error' })
      } else if (data) {
        setShowNewSessionModal(false)
        setNewSessionForm({
          topic: '',
          session_type: 'Skill Workshop',
          session_mode: 'Offline',
          location: '',
          date: new Date().toISOString().slice(0, 10),
          time: '17:00',
          duration_minutes: 60,
        })
        await loadBatchData(selectedBatchId)
        setSelectedSessionId(data.id)
        setMessage({ text: `Scheduled session: ${data.topic}`, type: 'success' })
      }
    } finally {
      setCreatingSession(false)
    }
  }

  // Export Attendance CSV
  const handleExportCsv = () => {
    const session = sessions.find((s) => s.id === selectedSessionId)
    const topic = session?.topic || 'Session'
    const date = session?.session_datetime ? new Date(session.session_datetime).toLocaleDateString() : ''

    const headers = 'Register Number,Student Name,Attendance Status,Session Topic,Session Date\n'
    const rows = students
      .map((s) => {
        const st = statuses[s.id] ?? 'absent'
        return `"${s.reg_no}","${s.name}","${st}","${topic}","${date}"`
      })
      .join('\n')

    const blob = new Blob([headers + rows], { type: 'text/csv;charset=utf-8;' })
    const url = URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = url
    link.setAttribute('download', `PSGMX_Participation_${topic.replace(/\s+/g, '_')}.csv`)
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
  }

  // Computed Values
  const currentSession = sessions.find((s) => s.id === selectedSessionId)

  const stats = useMemo(() => {
    let present = 0
    let absent = 0
    let excused = 0
    students.forEach((s) => {
      const st = statuses[s.id] ?? 'absent'
      if (st === 'present') present++
      else if (st === 'excused') excused++
      else absent++
    })
    const total = students.length
    const pct = total > 0 ? Math.round((present / total) * 100) : 0
    return { present, absent, excused, total, pct }
  }, [students, statuses])

  const filteredStudents = useMemo(() => {
    return students.filter((s) => {
      const matchesQuery =
        !searchQuery ||
        s.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        s.reg_no.toLowerCase().includes(searchQuery.toLowerCase())

      const st = statuses[s.id] ?? 'absent'
      const matchesFilter = filterStatus === 'all' || st === filterStatus

      return matchesQuery && matchesFilter
    })
  }, [students, searchQuery, filterStatus, statuses])

  return (
    <div className="max-w-6xl mx-auto space-y-6 pb-12">
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
        <div>
          <h1 className="text-2xl sm:text-3xl font-black text-slate-900 tracking-tight">
            Preparation Participation
          </h1>
          <p className="mt-1 text-sm text-slate-500">
            Record and audit live attendance for interview preparation, mock drives, and technical workshops.
          </p>
        </div>

        {/* Batch Tab Switcher (25MX / 26MX) */}
        <div className="inline-flex p-1 rounded-2xl bg-slate-100 border border-slate-200">
          {batches.map((b) => {
            const isSelected = b.id === selectedBatchId
            const isMine = b.id === myBatchId
            return (
              <button
                key={b.id}
                onClick={() => setSelectedBatchId(b.id)}
                className={`relative px-4 py-2 rounded-xl text-xs font-black transition-all ${
                  isSelected
                    ? 'bg-white text-violet-700 shadow-sm'
                    : 'text-slate-600 hover:text-slate-900'
                }`}
              >
                {b.batch_code}
                {isMine && (
                  <span className="ml-1.5 text-[10px] font-bold text-violet-500 bg-violet-50 px-1.5 py-0.5 rounded-full">
                    mine
                  </span>
                )}
              </button>
            )
          })}
        </div>
      </div>

      {/* Feedback Banner */}
      {message && (
        <div
          className={`p-4 rounded-2xl text-sm font-semibold flex items-center justify-between transition-all ${
            message.type === 'success'
              ? 'bg-emerald-50 text-emerald-800 border border-emerald-200'
              : 'bg-red-50 text-red-800 border border-red-200'
          }`}
        >
          <span>{message.text}</span>
          <button onClick={() => setMessage(null)} className="text-xs font-bold underline ml-4">
            Dismiss
          </button>
        </div>
      )}

      {/* Session Selector Bar */}
      <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm space-y-4">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
          <label className="text-xs font-black uppercase tracking-wider text-slate-500">
            Preparation Session
          </label>
          <button
            onClick={() => setShowNewSessionModal(true)}
            className="inline-flex items-center gap-1.5 text-xs font-bold text-violet-600 hover:text-violet-700 bg-violet-50 hover:bg-violet-100 px-3 py-1.5 rounded-xl transition-colors"
          >
            <Plus className="w-3.5 h-3.5" />
            Schedule New Session
          </button>
        </div>

        {sessions.length > 0 ? (
          <select
            value={selectedSessionId}
            onChange={(e) => setSelectedSessionId(e.target.value)}
            className="w-full rounded-xl border border-slate-200 bg-slate-50/50 px-4 py-3 text-sm font-medium outline-none focus:border-violet-500 focus:bg-white transition-all"
          >
            {sessions.map((s) => (
              <option key={s.id} value={s.id}>
                {new Date(s.session_datetime).toLocaleDateString('en-IN', {
                  weekday: 'short',
                  month: 'short',
                  day: 'numeric',
                  hour: '2-digit',
                  minute: '2-digit',
                })}{' '}
                — {s.topic} ({s.session_type || 'General'} · {s.session_mode || 'Offline'})
                {s.is_locked ? ' [LOCKED]' : ''}
              </option>
            ))}
          </select>
        ) : (
          <div className="p-6 text-center rounded-xl bg-slate-50 border border-dashed border-slate-200">
            <CalendarDays className="mx-auto h-8 w-8 text-slate-300 mb-2" />
            <p className="text-sm font-bold text-slate-600">No sessions scheduled for this batch yet.</p>
            <p className="text-xs text-slate-400 mt-1 mb-3">
              Click below to schedule the first preparation session.
            </p>
            <button
              onClick={() => setShowNewSessionModal(true)}
              className="inline-flex items-center gap-1.5 text-xs font-bold text-white bg-violet-600 hover:bg-violet-700 px-4 py-2 rounded-xl transition-colors shadow-sm"
            >
              <Plus className="w-3.5 h-3.5" />
              Schedule Session Now
            </button>
          </div>
        )}
      </div>

      {/* Active Session & Attendance Workspace */}
      {currentSession && (
        <div className="space-y-6">
          {/* Session Info & Stats Summary */}
          <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm space-y-5">
            <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4 border-b border-slate-100 pb-4">
              <div>
                <div className="flex items-center gap-2 flex-wrap">
                  <h2 className="text-lg font-black text-slate-900">{currentSession.topic}</h2>
                  <span className="text-[11px] font-bold uppercase tracking-wider px-2.5 py-0.5 rounded-full bg-violet-100 text-violet-700">
                    {currentSession.session_type || 'Session'}
                  </span>
                  {currentSession.is_locked ? (
                    <span className="inline-flex items-center gap-1 text-[11px] font-bold px-2 py-0.5 rounded-full bg-slate-100 text-slate-600">
                      <Lock className="w-3 h-3" /> Locked
                    </span>
                  ) : (
                    <span className="inline-flex items-center gap-1 text-[11px] font-bold px-2 py-0.5 rounded-full bg-emerald-100 text-emerald-700">
                      <Unlock className="w-3 h-3" /> Open
                    </span>
                  )}
                </div>
                <div className="flex items-center gap-4 text-xs text-slate-400 mt-1.5 flex-wrap">
                  <span className="inline-flex items-center gap-1">
                    <Clock className="w-3.5 h-3.5 text-slate-400" />
                    {new Date(currentSession.session_datetime).toLocaleString('en-IN', {
                      dateStyle: 'medium',
                      timeStyle: 'short',
                    })}
                  </span>
                  {currentSession.location && (
                    <span className="inline-flex items-center gap-1">
                      <MapPin className="w-3.5 h-3.5 text-slate-400" />
                      {currentSession.location}
                    </span>
                  )}
                  <span>Mode: {currentSession.session_mode || 'Offline'}</span>
                </div>
              </div>

              {/* Action Buttons */}
              <div className="flex items-center gap-2 flex-wrap">
                <button
                  onClick={() => markAll('present')}
                  disabled={Boolean(currentSession.is_locked)}
                  className="px-3.5 py-2 rounded-xl bg-emerald-50 hover:bg-emerald-100 text-emerald-700 text-xs font-black transition-colors disabled:opacity-50"
                >
                  All Present
                </button>
                <button
                  onClick={() => markAll('absent')}
                  disabled={Boolean(currentSession.is_locked)}
                  className="px-3.5 py-2 rounded-xl bg-red-50 hover:bg-red-100 text-red-700 text-xs font-black transition-colors disabled:opacity-50"
                >
                  Reset Absent
                </button>
                <button
                  onClick={handleExportCsv}
                  className="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 text-xs font-black transition-colors"
                >
                  <Download className="w-3.5 h-3.5" />
                  Export CSV
                </button>
              </div>
            </div>

            {/* Attendance Metrics Bar */}
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
              <div className="p-3.5 rounded-xl bg-slate-50 border border-slate-100">
                <p className="text-[11px] font-bold uppercase tracking-wider text-slate-400">Total</p>
                <p className="text-xl font-black text-slate-800 mt-0.5">{stats.total} students</p>
              </div>
              <div className="p-3.5 rounded-xl bg-emerald-50/70 border border-emerald-100">
                <p className="text-[11px] font-bold uppercase tracking-wider text-emerald-600">Present</p>
                <p className="text-xl font-black text-emerald-700 mt-0.5">{stats.present}</p>
              </div>
              <div className="p-3.5 rounded-xl bg-red-50/70 border border-red-100">
                <p className="text-[11px] font-bold uppercase tracking-wider text-red-600">Absent</p>
                <p className="text-xl font-black text-red-700 mt-0.5">{stats.absent}</p>
              </div>
              <div className="p-3.5 rounded-xl bg-violet-50/70 border border-violet-100">
                <p className="text-[11px] font-bold uppercase tracking-wider text-violet-600">Attendance Rate</p>
                <p className="text-xl font-black text-violet-700 mt-0.5">{stats.pct}%</p>
              </div>
            </div>

            {/* Progress Bar */}
            <div className="w-full bg-slate-100 h-2 rounded-full overflow-hidden">
              <div
                className="bg-emerald-500 h-full transition-all duration-300"
                style={{ width: `${stats.pct}%` }}
              />
            </div>
          </div>

          {/* Student Roster & Marking Table */}
          <div className="rounded-2xl border border-slate-200 bg-white shadow-sm overflow-hidden">
            {/* Filter Bar */}
            <div className="p-4 border-b border-slate-100 flex flex-col sm:flex-row sm:items-center justify-between gap-3 bg-slate-50/50">
              <div className="relative flex-1 max-w-sm">
                <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
                <input
                  type="text"
                  placeholder="Search student or register no..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="w-full pl-9 pr-3 py-2 text-xs rounded-xl border border-slate-200 bg-white outline-none focus:border-violet-500"
                />
              </div>

              {/* Status Filter */}
              <div className="inline-flex rounded-xl bg-slate-200/60 p-1 text-xs font-bold text-slate-600">
                {(['all', 'present', 'absent', 'excused'] as const).map((st) => (
                  <button
                    key={st}
                    onClick={() => setFilterStatus(st)}
                    className={`px-3 py-1 rounded-lg capitalize transition-all ${
                      filterStatus === st ? 'bg-white text-slate-900 shadow-sm' : 'hover:text-slate-900'
                    }`}
                  >
                    {st}
                  </button>
                ))}
              </div>
            </div>

            {/* List */}
            <div className="divide-y divide-slate-100 max-h-[550px] overflow-y-auto">
              {filteredStudents.length > 0 ? (
                filteredStudents.map((student) => {
                  const status = statuses[student.id] ?? 'absent'
                  return (
                    <div
                      key={student.id}
                      className="flex items-center justify-between p-4 hover:bg-slate-50/60 transition-colors gap-3"
                    >
                      <div className="min-w-0">
                        <p className="text-sm font-black text-slate-900 truncate">{student.name}</p>
                        <p className="text-xs text-slate-400 font-semibold">{student.reg_no}</p>
                      </div>

                      {/* Status Toggle Buttons */}
                      <div className="inline-flex rounded-xl bg-slate-100 p-1 gap-1 shrink-0">
                        <button
                          disabled={Boolean(currentSession.is_locked)}
                          onClick={() => setStudentStatus(student.id, 'present')}
                          className={`flex items-center gap-1 px-3 py-1.5 rounded-lg text-xs font-bold transition-all ${
                            status === 'present'
                              ? 'bg-emerald-600 text-white shadow-sm'
                              : 'text-slate-600 hover:bg-slate-200/60'
                          }`}
                        >
                          <CheckCircle2 className="w-3.5 h-3.5" />
                          Present
                        </button>

                        <button
                          disabled={Boolean(currentSession.is_locked)}
                          onClick={() => setStudentStatus(student.id, 'absent')}
                          className={`flex items-center gap-1 px-3 py-1.5 rounded-lg text-xs font-bold transition-all ${
                            status === 'absent'
                              ? 'bg-red-600 text-white shadow-sm'
                              : 'text-slate-600 hover:bg-slate-200/60'
                          }`}
                        >
                          <CircleX className="w-3.5 h-3.5" />
                          Absent
                        </button>

                        <button
                          disabled={Boolean(currentSession.is_locked)}
                          onClick={() => setStudentStatus(student.id, 'excused')}
                          className={`flex items-center gap-1 px-2.5 py-1.5 rounded-lg text-xs font-bold transition-all ${
                            status === 'excused'
                              ? 'bg-amber-500 text-white shadow-sm'
                              : 'text-slate-600 hover:bg-slate-200/60'
                          }`}
                        >
                          <AlertCircle className="w-3.5 h-3.5" />
                          Excused
                        </button>
                      </div>
                    </div>
                  )
                })
              ) : (
                <div className="p-8 text-center text-sm text-slate-400">
                  No students matched your search or filter.
                </div>
              )}
            </div>

            {/* Bottom Save Bar */}
            <div className="flex items-center justify-between border-t border-slate-200 p-5 bg-slate-50/70">
              <p className="text-xs font-semibold text-slate-500">
                {stats.present} of {stats.total} students marked present
              </p>
              <button
                onClick={handleSave}
                disabled={saving || Boolean(currentSession.is_locked)}
                className="inline-flex items-center gap-2 rounded-xl bg-violet-600 hover:bg-violet-700 disabled:opacity-50 px-6 py-3 text-sm font-black text-white shadow-sm transition-all"
              >
                <Save className="w-4 h-4" />
                {saving ? 'Saving…' : currentSession.is_locked ? 'Session Locked' : 'Save Participation'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Modal: Schedule New Session */}
      {showNewSessionModal && (
        <div className="fixed inset-0 z-50 bg-black/50 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-lg w-full p-6 shadow-2xl space-y-4">
            <div className="flex items-center justify-between border-b border-slate-100 pb-3">
              <h3 className="text-lg font-black text-slate-900">Schedule Preparation Session</h3>
              <button
                onClick={() => setShowNewSessionModal(false)}
                className="text-slate-400 hover:text-slate-600 font-bold text-sm"
              >
                ✕
              </button>
            </div>

            <form onSubmit={handleCreateSession} className="space-y-4">
              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 mb-1">
                  Topic / Title *
                </label>
                <input
                  required
                  placeholder="e.g. DSA Mock Interview - Graphs & DP"
                  value={newSessionForm.topic}
                  onChange={(e) => setNewSessionForm({ ...newSessionForm, topic: e.target.value })}
                  className="w-full rounded-xl border border-slate-200 px-4 py-2.5 text-sm outline-none focus:border-violet-500"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 mb-1">
                    Session Type
                  </label>
                  <select
                    value={newSessionForm.session_type}
                    onChange={(e) => setNewSessionForm({ ...newSessionForm, session_type: e.target.value })}
                    className="w-full rounded-xl border border-slate-200 px-3 py-2.5 text-xs outline-none focus:border-violet-500 bg-white"
                  >
                    <option value="Skill Workshop">Skill Workshop</option>
                    <option value="Mock Interview">Mock Interview</option>
                    <option value="Company Briefing">Company Briefing</option>
                    <option value="Peer Review">Peer Review</option>
                  </select>
                </div>

                <div>
                  <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 mb-1">
                    Mode
                  </label>
                  <select
                    value={newSessionForm.session_mode}
                    onChange={(e) => setNewSessionForm({ ...newSessionForm, session_mode: e.target.value })}
                    className="w-full rounded-xl border border-slate-200 px-3 py-2.5 text-xs outline-none focus:border-violet-500 bg-white"
                  >
                    <option value="Offline">Offline</option>
                    <option value="Online">Online</option>
                    <option value="Hybrid">Hybrid</option>
                  </select>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 mb-1">
                    Date *
                  </label>
                  <input
                    type="date"
                    required
                    value={newSessionForm.date}
                    onChange={(e) => setNewSessionForm({ ...newSessionForm, date: e.target.value })}
                    className="w-full rounded-xl border border-slate-200 px-3 py-2.5 text-xs outline-none focus:border-violet-500"
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 mb-1">
                    Time *
                  </label>
                  <input
                    type="time"
                    required
                    value={newSessionForm.time}
                    onChange={(e) => setNewSessionForm({ ...newSessionForm, time: e.target.value })}
                    className="w-full rounded-xl border border-slate-200 px-3 py-2.5 text-xs outline-none focus:border-violet-500"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 mb-1">
                  Location / Room
                </label>
                <input
                  placeholder="e.g. Lab 4 or Google Meet link"
                  value={newSessionForm.location}
                  onChange={(e) => setNewSessionForm({ ...newSessionForm, location: e.target.value })}
                  className="w-full rounded-xl border border-slate-200 px-4 py-2.5 text-sm outline-none focus:border-violet-500"
                />
              </div>

              <div className="flex items-center justify-end gap-3 pt-3 border-t border-slate-100">
                <button
                  type="button"
                  onClick={() => setShowNewSessionModal(false)}
                  className="px-4 py-2.5 rounded-xl text-xs font-bold text-slate-600 hover:bg-slate-100"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={creatingSession || !newSessionForm.topic.trim()}
                  className="px-5 py-2.5 rounded-xl bg-violet-600 hover:bg-violet-700 text-white font-bold text-xs disabled:opacity-50 transition-colors shadow-sm"
                >
                  {creatingSession ? 'Scheduling…' : 'Schedule Session'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  )
}
