'use client'

import React from 'react'
import { ExternalLink, Folder, Loader2, Plus, Save } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { getCurrentProfile } from '@/lib/current-profile'

type Project = { id: string; title: string; description: string | null; guide_name: string | null; team_members_count: number; status: string; repository_url: string | null; updated_at: string }
type Log = { id: string; note: string; created_at: string }
type Feedback = { id: string; comment: string; created_at: string }
const inputClass = 'w-full rounded-xl border border-border-light bg-page-bg px-4 py-3 text-sm outline-none focus:border-primary-purple'

export default function FYPPage() {
  const supabase = React.useMemo(() => createClient(), [])
  const [userId, setUserId] = React.useState('')
  const [batchId, setBatchId] = React.useState<string | null>(null)
  const [project, setProject] = React.useState<Project | null>(null)
  const [logs, setLogs] = React.useState<Log[]>([])
  const [feedback, setFeedback] = React.useState<Feedback[]>([])
  const [form, setForm] = React.useState({ title: '', description: '', guide_name: '', repository_url: '' })
  const [note, setNote] = React.useState('')
  const [loading, setLoading] = React.useState(true)
  const [busy, setBusy] = React.useState(false)
  const [message, setMessage] = React.useState('')

  const load = React.useCallback(async () => {
    setLoading(true)
    const me = await getCurrentProfile(supabase)
    if (!me) {
      setMessage('Your student profile could not be found.')
      setLoading(false)
      return
    }
    setUserId(me.id)
    setBatchId(me.batch_id)
    const { data: projectRow, error } = await supabase
      .from('fyp_projects')
      .select('id,title,description,guide_name,team_members_count,status,repository_url,updated_at')
      .eq('student_id', me.id)
      .order('updated_at', { ascending: false })
      .limit(1)
      .maybeSingle()
    if (error) {
      setMessage(error.message)
      setLoading(false)
      return
    }
    setProject(projectRow)
    if (projectRow) {
      const [{ data: logRows }, { data: feedbackRows }] = await Promise.all([
        supabase.from('fyp_progress_logs').select('id,note,created_at').eq('project_id', projectRow.id).order('created_at', { ascending: false }),
        supabase.from('fyp_feedback').select('id,comment,created_at').eq('project_id', projectRow.id).order('created_at', { ascending: false }),
      ])
      setLogs(logRows ?? [])
      setFeedback(feedbackRows ?? [])
    }
    setLoading(false)
  }, [supabase])

  React.useEffect(() => { void load() }, [load])

  async function createProject() {
    if (!userId || !form.title.trim()) return
    setBusy(true)
    const { error } = await supabase.from('fyp_projects').insert({
      student_id: userId,
      batch_id: batchId,
      title: form.title.trim(),
      description: form.description.trim() || null,
      guide_name: form.guide_name.trim() || null,
      repository_url: form.repository_url.trim() || null,
    })
    setMessage(error ? error.message : 'Your FYP portfolio is ready.')
    if (!error) await load()
    setBusy(false)
  }

  async function addLog() {
    if (!project || !note.trim()) return
    setBusy(true)
    const { error } = await supabase.from('fyp_progress_logs').insert({ project_id: project.id, student_id: userId, note: note.trim() })
    setMessage(error ? error.message : 'Progress update added.')
    if (!error) {
      setNote('')
      await load()
    }
    setBusy(false)
  }

  if (loading) return <div className="flex min-h-64 items-center justify-center"><Loader2 className="h-6 w-6 animate-spin text-primary-purple"/></div>

  return <div className="mx-auto max-w-5xl space-y-7 pb-10">
    <div><h1 className="flex items-center gap-2 text-2xl font-black"><Folder className="h-6 w-6 text-primary-purple"/>FYP portfolio</h1><p className="mt-1 text-sm text-text-muted">Keep a durable project record that your guide can review.</p></div>
    {!project ? <section className="rounded-3xl border border-border-light bg-white p-6">
      <h2 className="font-black">Create your project record</h2>
      <p className="mt-1 text-sm text-text-muted">Use the official project title. You can add progress updates after setup.</p>
      <div className="mt-5 grid gap-4">
        <Field label="Project title"><input value={form.title} onChange={(event) => setForm({ ...form, title: event.target.value })} className={inputClass}/></Field>
        <Field label="Description"><textarea value={form.description} onChange={(event) => setForm({ ...form, description: event.target.value })} className={`${inputClass} min-h-28`}/></Field>
        <div className="grid gap-4 sm:grid-cols-2">
          <Field label="Guide name"><input value={form.guide_name} onChange={(event) => setForm({ ...form, guide_name: event.target.value })} className={inputClass}/></Field>
          <Field label="Repository URL"><input type="url" value={form.repository_url} onChange={(event) => setForm({ ...form, repository_url: event.target.value })} className={inputClass} placeholder="https://github.com/..."/></Field>
        </div>
        <button onClick={createProject} disabled={busy || !form.title.trim()} className="flex w-fit items-center gap-2 rounded-xl bg-primary-purple px-5 py-3 text-sm font-bold text-white disabled:opacity-50">{busy ? <Loader2 className="h-4 w-4 animate-spin"/> : <Save className="h-4 w-4"/>}Create portfolio</button>
      </div>
    </section> : <>
      <section className="rounded-3xl border border-border-light bg-white p-6 sm:p-8">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
          <div><span className="rounded-full bg-violet-50 px-3 py-1 text-[10px] font-black uppercase text-primary-purple">{project.status.replaceAll('_', ' ')}</span><h2 className="mt-3 text-2xl font-black">{project.title}</h2><p className="mt-2 max-w-2xl text-sm leading-6 text-text-muted">{project.description || 'No description added.'}</p><p className="mt-3 text-xs font-bold text-text-muted">Guide: {project.guide_name || 'Not assigned'} · {project.team_members_count} member{project.team_members_count === 1 ? '' : 's'}</p></div>
          {project.repository_url && <a href={project.repository_url} target="_blank" rel="noreferrer" className="flex items-center gap-2 rounded-xl border border-border-light px-4 py-3 text-sm font-bold"><ExternalLink className="h-4 w-4"/>Repository</a>}
        </div>
      </section>
      <section className="grid gap-6 lg:grid-cols-3">
        <div className="lg:col-span-2"><h2 className="font-black">Progress log</h2><div className="mt-3 rounded-2xl border border-border-light bg-white p-4"><textarea value={note} onChange={(event) => setNote(event.target.value)} placeholder="What changed since your last update?" className="min-h-24 w-full resize-y bg-transparent text-sm outline-none"/><button onClick={addLog} disabled={busy || !note.trim()} className="mt-3 flex items-center gap-2 rounded-xl bg-primary-purple px-4 py-2.5 text-sm font-bold text-white disabled:opacity-50"><Plus className="h-4 w-4"/>Add update</button></div><div className="mt-3 space-y-3">{logs.map((log) => <div key={log.id} className="rounded-2xl border border-border-light bg-white p-5"><p className="text-sm leading-6">{log.note}</p><p className="mt-2 text-xs text-text-muted">{new Intl.DateTimeFormat('en-IN', { dateStyle: 'medium', timeStyle: 'short' }).format(new Date(log.created_at))}</p></div>)}{logs.length === 0 && <p className="rounded-2xl bg-page-bg p-5 text-sm text-text-muted">No progress updates yet.</p>}</div></div>
        <div><h2 className="font-black">Guide feedback</h2><div className="mt-3 space-y-3">{feedback.map((item) => <div key={item.id} className="rounded-2xl border border-border-light bg-white p-5"><p className="text-sm leading-6">{item.comment}</p><p className="mt-2 text-xs text-text-muted">{new Intl.DateTimeFormat('en-IN', { dateStyle: 'medium' }).format(new Date(item.created_at))}</p></div>)}{feedback.length === 0 && <p className="rounded-2xl bg-page-bg p-5 text-sm text-text-muted">Faculty feedback will appear here after review.</p>}</div></div>
      </section>
    </>}
    {message && <p className="rounded-xl bg-page-bg p-4 text-sm font-semibold" role="status">{message}</p>}
  </div>
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return <label className="block"><span className="mb-2 block text-xs font-black uppercase tracking-wide text-text-muted">{label}</span>{children}</label>
}
