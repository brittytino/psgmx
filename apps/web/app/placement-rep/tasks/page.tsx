'use client'

import React from 'react'
import { Plus, Trash2, ListTodo } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { getCurrentProfile } from '@/lib/current-profile'

type Task = { id: string; date: string; topic_type: string; title: string; subject: string | null; reference_link: string | null }

export default function TasksPage() {
  const supabase = React.useMemo(() => createClient(), [])
  const [tasks, setTasks] = React.useState<Task[]>([])
  const [me, setMe] = React.useState<{ id: string; batch_id: string } | null>(null)
  const [form, setForm] = React.useState({ date: new Date().toISOString().slice(0, 10), topic_type: 'leetcode', title: '', subject: '', reference_link: '' })
  const [message, setMessage] = React.useState('')

  const load = React.useCallback(async () => {
    const profile = await getCurrentProfile(supabase)
    if (!profile?.batch_id) return
    setMe({ id: profile.id, batch_id: profile.batch_id })
    const { data } = await supabase.from('daily_tasks').select('id,date,topic_type,title,subject,reference_link').eq('batch_id', profile.batch_id).order('date', { ascending: false }).limit(60)
    setTasks(data ?? [])
  }, [supabase])
  React.useEffect(() => { void load() }, [load])

  async function createTask(event: React.FormEvent) {
    event.preventDefault()
    if (!me || !form.title.trim()) return
    const { error } = await supabase.from('daily_tasks').upsert({ ...form, title: form.title.trim(), subject: form.subject || null, reference_link: form.reference_link || null, uploaded_by: me.id, batch_id: me.batch_id }, { onConflict: 'batch_id,date,topic_type' })
    setMessage(error ? error.message : 'Task published to your batch.')
    if (!error) { setForm((old) => ({ ...old, title: '', subject: '', reference_link: '' })); await load() }
  }

  async function remove(id: string) { await supabase.from('daily_tasks').delete().eq('id', id); await load() }

  return <div className="max-w-5xl space-y-6">
    <div><h1 className="text-2xl font-black">Daily Tasks</h1><p className="mt-1 text-sm text-text-muted">One LeetCode and one core task can be published per batch each day.</p></div>
    <form onSubmit={createTask} className="grid gap-4 rounded-2xl border border-border-light bg-white p-5 sm:grid-cols-2">
      <input type="date" value={form.date} onChange={(e) => setForm({ ...form, date: e.target.value })} className="rounded-xl border border-border-light px-4 py-3 text-sm" />
      <select value={form.topic_type} onChange={(e) => setForm({ ...form, topic_type: e.target.value })} className="rounded-xl border border-border-light px-4 py-3 text-sm"><option value="leetcode">LeetCode</option><option value="core">Core subject</option></select>
      <input required value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })} placeholder="Task title" className="rounded-xl border border-border-light px-4 py-3 text-sm sm:col-span-2" />
      <input value={form.subject} onChange={(e) => setForm({ ...form, subject: e.target.value })} placeholder="Subject / topic" className="rounded-xl border border-border-light px-4 py-3 text-sm" />
      <input type="url" value={form.reference_link} onChange={(e) => setForm({ ...form, reference_link: e.target.value })} placeholder="Reference link" className="rounded-xl border border-border-light px-4 py-3 text-sm" />
      <div className="flex items-center justify-between sm:col-span-2"><p className="text-sm text-text-muted">{message}</p><button className="flex items-center gap-2 rounded-xl bg-primary-purple px-5 py-3 text-sm font-bold text-white"><Plus className="h-4 w-4" />Publish</button></div>
    </form>
    <div className="space-y-3">{tasks.map((task) => <div key={task.id} className="flex items-center justify-between rounded-2xl border border-border-light bg-white p-5"><div className="flex gap-3"><ListTodo className="mt-0.5 h-5 w-5 text-primary-purple" /><div><p className="text-sm font-bold">{task.title}</p><p className="text-xs text-text-muted">{task.date} · {task.topic_type} {task.subject ? `· ${task.subject}` : ''}</p></div></div><button onClick={() => remove(task.id)} className="rounded-lg p-2 text-text-muted hover:bg-red-50 hover:text-red-600"><Trash2 className="h-4 w-4" /></button></div>)}</div>
  </div>
}
