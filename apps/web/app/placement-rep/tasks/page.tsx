'use client'

import React, { useState, useEffect, useMemo, useCallback } from 'react'
import { Plus, Trash2, ListTodo, CheckCircle2, ExternalLink, Calendar, AlertCircle } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { getCurrentProfile } from '@/lib/current-profile'

type Task = {
  id: string
  date: string
  topic_type: string
  title: string
  subject: string | null
  reference_link: string | null
  uploaded_by: string
  batch_id?: string | null
}

type BatchOption = {
  id: string
  batch_code: string
}

const TOPIC_LABELS: Record<string, string> = {
  leetcode: 'LeetCode',
  core: 'Core Subject',
}

const TOPIC_COLORS: Record<string, string> = {
  leetcode: 'bg-orange-100 text-orange-700 border-orange-200',
  core: 'bg-blue-100 text-blue-700 border-blue-200',
}

export default function TasksPage() {
  const supabase = useMemo(() => createClient(), [])
  const [tasks, setTasks] = useState<Task[]>([])
  const [batches, setBatches] = useState<BatchOption[]>([])
  const [selectedBatchId, setSelectedBatchId] = useState<string>('')
  const [myBatchId, setMyBatchId] = useState<string>('')
  const [me, setMe] = useState<{ id: string; batch_id: string } | null>(null)

  const [form, setForm] = useState({
    date: new Date().toISOString().slice(0, 10),
    topic_type: 'leetcode',
    title: '',
    subject: '',
    reference_link: '',
  })

  const [message, setMessage] = useState('')
  const [messageType, setMessageType] = useState<'success' | 'error'>('success')
  const [submitting, setSubmitting] = useState(false)
  const [loading, setLoading] = useState(true)

  // Initial load: Profile & Batches
  useEffect(() => {
    void (async () => {
      try {
        const profile = await getCurrentProfile(supabase)
        if (!profile?.id) return
        setMe({ id: profile.id, batch_id: profile.batch_id || '' })
        if (profile.batch_id) setMyBatchId(profile.batch_id)

        const { data: batchList } = await supabase
          .from('batches')
          .select('id, batch_code')
          .order('start_year', { ascending: false })

        const loadedBatches = (batchList ?? []) as BatchOption[]
        setBatches(loadedBatches)

        const defaultBatchId = profile.batch_id || loadedBatches[0]?.id || ''
        setSelectedBatchId(defaultBatchId)
      } catch (e) {
        console.warn('Initial load error:', e)
      }
    })()
  }, [supabase])

  // Load tasks for selected batch
  const loadTasks = useCallback(async (batchId: string) => {
    if (!batchId) return
    setLoading(true)
    try {
      // 1. Try querying with batch_id column
      const { data: batchTasks, error: batchTasksErr } = await supabase
        .from('daily_tasks')
        .select('id,date,topic_type,title,subject,reference_link,uploaded_by,batch_id')
        .eq('batch_id', batchId)
        .order('date', { ascending: false })
        .limit(60)

      if (!batchTasksErr && batchTasks && batchTasks.length > 0) {
        setTasks(batchTasks as Task[])
        setLoading(false)
        return
      }

      // 2. Fallback: Find tasks uploaded by users of this batch
      const { data: batchUsers } = await supabase
        .from('users')
        .select('id')
        .eq('batch_id', batchId)

      const userIds = (batchUsers ?? []).map((u) => u.id)
      let query = supabase
        .from('daily_tasks')
        .select('id,date,topic_type,title,subject,reference_link,uploaded_by')
        .order('date', { ascending: false })
        .limit(60)

      if (userIds.length > 0) {
        query = query.in('uploaded_by', userIds)
      }

      const { data, error } = await query
      if (error) {
        console.warn('daily_tasks query error:', error.message)
        setTasks([])
      } else {
        setTasks((data ?? []) as Task[])
      }
    } catch (e) {
      console.warn('Tasks load error:', e)
    } finally {
      setLoading(false)
    }
  }, [supabase])

  useEffect(() => {
    if (selectedBatchId) {
      void loadTasks(selectedBatchId)
    }
  }, [selectedBatchId, loadTasks])

  async function createTask(event: React.FormEvent) {
    event.preventDefault()
    if (!me || !form.title.trim() || submitting || !selectedBatchId) return
    setSubmitting(true)
    setMessage('')

    try {
      // Build task insert payload
      const insertPayload: Record<string, any> = {
        date: form.date,
        topic_type: form.topic_type,
        title: form.title.trim(),
        subject: form.subject || null,
        reference_link: form.reference_link || null,
        uploaded_by: me.id,
        batch_id: selectedBatchId,
      }

      // Attempt insert
      let { error } = await (supabase.from('daily_tasks') as any).insert(insertPayload)

      // If batch_id column doesn't exist on older schema, retry without batch_id
      if (error && error.message.includes('batch_id')) {
        delete insertPayload.batch_id
        const retry = await (supabase.from('daily_tasks') as any).insert(insertPayload)
        error = retry.error
      }

      // Handle duplicate date + topic_type: update instead
      if (error && (error.code === '23505' || error.message.includes('unique'))) {
        const updatePayload: Record<string, any> = {
          title: form.title.trim(),
          subject: form.subject || null,
          reference_link: form.reference_link || null,
          uploaded_by: me.id,
        }
        if (selectedBatchId) updatePayload.batch_id = selectedBatchId

        const { error: updateError } = await (supabase.from('daily_tasks') as any)
          .update(updatePayload)
          .eq('date', form.date)
          .eq('topic_type', form.topic_type)

        if (updateError) {
          setMessage(`Error: ${updateError.message}`)
          setMessageType('error')
        } else {
          setMessage('Task updated for this date.')
          setMessageType('success')
          setForm((old) => ({ ...old, title: '', subject: '', reference_link: '' }))
          await loadTasks(selectedBatchId)
        }
      } else if (error) {
        if (error.message.includes('completed')) {
          setMessage(
            `Database trigger note: ${error.message}. Please apply migration 13 to resolve the completed column mismatch.`
          )
        } else {
          setMessage(`Error: ${error.message}`)
        }
        setMessageType('error')
      } else {
        setMessage('Task published successfully.')
        setMessageType('success')
        setForm((old) => ({ ...old, title: '', subject: '', reference_link: '' }))
        await loadTasks(selectedBatchId)
      }
    } catch (err) {
      setMessage(`Unexpected error: ${err instanceof Error ? err.message : String(err)}`)
      setMessageType('error')
    } finally {
      setSubmitting(false)
    }
  }

  async function remove(id: string) {
    if (!confirm('Are you sure you want to delete this task?')) return
    const { error } = await supabase.from('daily_tasks').delete().eq('id', id)
    if (error) {
      setMessage(`Delete failed: ${error.message}`)
      setMessageType('error')
    } else {
      setMessage('Task deleted.')
      setMessageType('success')
      await loadTasks(selectedBatchId)
    }
  }

  // Group tasks by date
  const groupedByDate = useMemo(() => {
    return tasks.reduce((acc, task) => {
      if (!acc[task.date]) acc[task.date] = []
      acc[task.date].push(task)
      return acc
    }, {} as Record<string, Task[]>)
  }, [tasks])

  return (
    <div className="max-w-5xl mx-auto space-y-6 pb-12">
      {/* Header with Batch Tab Switcher */}
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
        <div>
          <h1 className="text-2xl sm:text-3xl font-black text-slate-900 tracking-tight">Daily Tasks</h1>
          <p className="mt-1 text-sm text-slate-500">
            Publish daily coding challenges and core computer science tasks for both batches.
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

      {/* Task Creation Form */}
      <div className="rounded-2xl border border-slate-200 bg-white shadow-sm overflow-hidden">
        <div className="px-5 pt-5 pb-4 border-b border-slate-100 flex items-center justify-between">
          <h2 className="text-xs font-black text-slate-900 uppercase tracking-wider">
            Publish New Task ({batches.find((b) => b.id === selectedBatchId)?.batch_code || 'Selected Batch'})
          </h2>
        </div>
        <form onSubmit={createTask} className="p-5 grid gap-4 sm:grid-cols-2">
          <div className="flex flex-col gap-1">
            <label className="text-xs font-bold text-slate-500 uppercase tracking-wider">Date</label>
            <input
              type="date"
              value={form.date}
              onChange={(e) => setForm({ ...form, date: e.target.value })}
              className="rounded-xl border border-slate-200 px-4 py-3 text-sm outline-none focus:border-violet-400 focus:ring-2 focus:ring-violet-100 transition-all"
            />
          </div>
          <div className="flex flex-col gap-1">
            <label className="text-xs font-bold text-slate-500 uppercase tracking-wider">Task Type</label>
            <select
              value={form.topic_type}
              onChange={(e) => setForm({ ...form, topic_type: e.target.value })}
              className="rounded-xl border border-slate-200 px-4 py-3 text-sm outline-none focus:border-violet-400 focus:ring-2 focus:ring-violet-100 transition-all bg-white"
            >
              <option value="leetcode">LeetCode Problem</option>
              <option value="core">Core Subject</option>
            </select>
          </div>
          <div className="sm:col-span-2 flex flex-col gap-1">
            <label className="text-xs font-bold text-slate-500 uppercase tracking-wider">Task Title *</label>
            <input
              required
              value={form.title}
              onChange={(e) => setForm({ ...form, title: e.target.value })}
              placeholder={form.topic_type === 'leetcode' ? 'e.g. Two Sum (Easy)' : 'e.g. Explain ACID properties in DBMS'}
              className="rounded-xl border border-slate-200 px-4 py-3 text-sm outline-none focus:border-violet-400 focus:ring-2 focus:ring-violet-100 transition-all"
            />
          </div>
          <div className="flex flex-col gap-1">
            <label className="text-xs font-bold text-slate-500 uppercase tracking-wider">Subject / Topic</label>
            <input
              value={form.subject}
              onChange={(e) => setForm({ ...form, subject: e.target.value })}
              placeholder="e.g. Arrays, DBMS, OS, Networks"
              className="rounded-xl border border-slate-200 px-4 py-3 text-sm outline-none focus:border-violet-400 focus:ring-2 focus:ring-violet-100 transition-all"
            />
          </div>
          <div className="flex flex-col gap-1">
            <label className="text-xs font-bold text-slate-500 uppercase tracking-wider">Reference Link</label>
            <input
              type="url"
              value={form.reference_link}
              onChange={(e) => setForm({ ...form, reference_link: e.target.value })}
              placeholder="https://leetcode.com/problems/..."
              className="rounded-xl border border-slate-200 px-4 py-3 text-sm outline-none focus:border-violet-400 focus:ring-2 focus:ring-violet-100 transition-all"
            />
          </div>
          <div className="sm:col-span-2 flex flex-col sm:flex-row sm:items-center justify-between gap-4 pt-2">
            {message ? (
              <p className={`text-xs font-bold ${messageType === 'error' ? 'text-red-600' : 'text-emerald-600'}`}>
                {message}
              </p>
            ) : (
              <p className="text-xs text-slate-400">One LeetCode + one core task per day recommended.</p>
            )}
            <button
              type="submit"
              disabled={submitting || !form.title.trim() || !selectedBatchId}
              className="flex items-center justify-center gap-2 rounded-xl bg-violet-600 hover:bg-violet-700 disabled:opacity-50 px-5 py-3 text-sm font-bold text-white transition-colors"
            >
              <Plus className="h-4 w-4" />
              {submitting ? 'Publishing…' : 'Publish Task'}
            </button>
          </div>
        </form>
      </div>

      {/* Task List */}
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <h2 className="text-xs font-black text-slate-900 uppercase tracking-wider">
            Published Tasks ({tasks.length})
          </h2>
          <span className="text-xs text-slate-400 font-semibold">Last 60 days</span>
        </div>

        {loading ? (
          <div className="rounded-2xl border border-slate-200 bg-white p-8 text-center">
            <div className="text-slate-400 text-sm">Loading tasks…</div>
          </div>
        ) : Object.keys(groupedByDate).length === 0 ? (
          <div className="rounded-2xl border border-slate-200 bg-white p-8 text-center">
            <ListTodo className="mx-auto h-8 w-8 text-slate-300 mb-3" />
            <p className="text-sm font-semibold text-slate-500">No tasks published for this batch yet.</p>
            <p className="text-xs text-slate-400 mt-1">Use the form above to publish the first task.</p>
          </div>
        ) : (
          Object.entries(groupedByDate).map(([date, dayTasks]) => (
            <div key={date} className="rounded-2xl border border-slate-200 bg-white shadow-sm overflow-hidden">
              <div className="flex items-center gap-2 px-5 py-3 bg-slate-50 border-b border-slate-100">
                <Calendar className="h-4 w-4 text-slate-400" />
                <span className="text-xs font-black text-slate-600 uppercase tracking-wider">
                  {new Date(date + 'T00:00:00').toLocaleDateString('en-IN', {
                    weekday: 'long',
                    year: 'numeric',
                    month: 'long',
                    day: 'numeric',
                  })}
                </span>
              </div>
              <div className="divide-y divide-slate-100">
                {dayTasks.map((task) => (
                  <div key={task.id} className="flex items-start justify-between p-5 gap-4">
                    <div className="flex gap-3 items-start min-w-0">
                      <CheckCircle2 className="mt-0.5 h-5 w-5 text-violet-500 shrink-0" />
                      <div className="min-w-0">
                        <div className="flex items-center gap-2 flex-wrap">
                          <p className="text-sm font-bold text-slate-900 break-words">{task.title}</p>
                          <span
                            className={`inline-flex items-center px-2 py-0.5 rounded-full text-[11px] font-bold border ${
                              TOPIC_COLORS[task.topic_type] ?? 'bg-slate-100 text-slate-600 border-slate-200'
                            }`}
                          >
                            {TOPIC_LABELS[task.topic_type] ?? task.topic_type}
                          </span>
                        </div>
                        {task.subject && <p className="text-xs text-slate-500 mt-0.5">{task.subject}</p>}
                        {task.reference_link && (
                          <a
                            href={task.reference_link}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="inline-flex items-center gap-1 text-xs text-violet-600 hover:underline mt-1"
                          >
                            <ExternalLink className="h-3 w-3" /> Reference link
                          </a>
                        )}
                      </div>
                    </div>
                    <button
                      onClick={() => remove(task.id)}
                      className="shrink-0 rounded-lg p-2 text-slate-400 hover:bg-red-50 hover:text-red-600 transition-colors"
                      title="Remove task"
                    >
                      <Trash2 className="h-4 w-4" />
                    </button>
                  </div>
                ))}
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  )
}
