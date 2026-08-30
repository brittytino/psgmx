'use client'

import React from 'react'
import { ExternalLink, Folder, Loader2, Plus, Save, GitBranch, Sparkles } from 'lucide-react'
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
    try {
      const me = await getCurrentProfile(supabase)
      if (!me?.id) throw new Error('Sign in again to load your project portfolio.')
      const validId = me.id
      setUserId(validId)
      setBatchId(me?.batch_id || null)

      const { data: projectRow, error: projectError } = await supabase
          .from('fyp_projects')
          .select('id,title,description,guide_name,team_members_count,status,repository_url,updated_at')
          .eq('student_id', validId)
          .order('updated_at', { ascending: false })
          .limit(1)
          .maybeSingle()

      if (projectError) throw projectError
      if (projectRow) {
          setProject(projectRow)
          const [{ data: logRows, error: logError }, { data: feedbackRows, error: feedbackError }] = await Promise.all([
            supabase.from('fyp_progress_logs').select('id,note,created_at').eq('project_id', projectRow.id).order('created_at', { ascending: false }),
            supabase.from('fyp_feedback').select('id,comment,created_at').eq('project_id', projectRow.id).order('created_at', { ascending: false }),
          ])
          if (logError || feedbackError) throw logError || feedbackError
          setLogs(logRows ?? [])
          setFeedback(feedbackRows ?? [])
      }
    } catch (cause) { setMessage(cause instanceof Error ? cause.message : 'Project portfolio could not be loaded.') }
    setLoading(false)
  }, [supabase])

  React.useEffect(() => { void load() }, [load])

  async function createProject() {
    if (!form.title.trim()) return
    setBusy(true)
    if (!userId) { setBusy(false); return setMessage('Sign in again before creating a project.') }
    try {
      const { error } = await supabase.from('fyp_projects').insert({
        student_id: userId,
        batch_id: batchId,
        title: form.title.trim(),
        description: form.description.trim() || null,
        guide_name: form.guide_name.trim() || null,
        repository_url: form.repository_url.trim() || null,
      })
      if (error) throw error
      setMessage('Your FYP portfolio is ready.')
      await load()
    } catch (cause) { setMessage(cause instanceof Error ? cause.message : 'Project could not be created.') }
    setBusy(false)
  }

  async function addLog() {
    if (!project || !note.trim()) return
    if (!userId) return setMessage('Sign in again before adding progress.')
    try {
      const { data, error } = await supabase.from('fyp_progress_logs').insert({
        project_id: project.id, 
        student_id: userId,
        note: note.trim() 
      } as any).select('id,note,created_at').single()
      if (error || !data) throw error || new Error('Progress was not recorded.')
      setLogs((prev) => [data as Log, ...prev])
      setNote('')
      setMessage('Progress logged.')
    } catch (cause) { setMessage(cause instanceof Error ? cause.message : 'Progress could not be saved.') }
    setBusy(false)
  }

  if (loading) {
    return <div className="flex min-h-64 items-center justify-center"><Loader2 className="h-6 w-6 animate-spin text-primary-purple"/></div>
  }

  return (
    <div className="mx-auto max-w-4xl space-y-7 pb-10">
      <div>
        <h1 className="flex items-center gap-2 text-2xl font-black text-text-main">
          <Folder className="h-6 w-6 text-primary-purple"/>
          Final Year Project (FYP) Portfolio
        </h1>
        <p className="mt-1 text-sm text-text-muted">
          Maintain a durable project record with versioned updates, guide reviews, and proof of work for placement technical rounds.
        </p>
      </div>

      {!project ? (
        <section className="rounded-3xl border border-border-light bg-white p-7 shadow-sm space-y-4">
          <h2 className="font-black text-text-main text-base">Create Your FYP Project Record</h2>
          <div className="space-y-3">
            <div>
              <label className="text-xs font-bold text-text-muted">Project Title</label>
              <input value={form.title} onChange={(e) => setForm({...form, title: e.target.value})} className={inputClass} placeholder="Official project title" />
            </div>
            <div>
              <label className="text-xs font-bold text-text-muted">Description & Problem Statement</label>
              <textarea rows={3} value={form.description} onChange={(e) => setForm({...form, description: e.target.value})} className={inputClass} placeholder="Core problem, solution architecture, and technologies used" />
            </div>
            <div className="grid gap-3 sm:grid-cols-2">
              <div>
                <label className="text-xs font-bold text-text-muted">Faculty Guide Name</label>
                <input value={form.guide_name} onChange={(e) => setForm({...form, guide_name: e.target.value})} className={inputClass} placeholder="Dr. Guide Name" />
              </div>
              <div>
                <label className="text-xs font-bold text-text-muted">Repository URL (GitHub / GitLab)</label>
                <input value={form.repository_url} onChange={(e) => setForm({...form, repository_url: e.target.value})} className={inputClass} placeholder="https://github.com/..." />
              </div>
            </div>
            <button 
              disabled={busy} 
              onClick={createProject} 
              className="flex items-center gap-2 rounded-xl bg-primary-purple px-6 py-3 text-xs font-black text-white hover:bg-violet-700 transition-colors disabled:opacity-50 shadow-sm"
            >
              <Plus className="h-4 w-4"/> {busy ? 'Creating…' : 'Create Portfolio Record'}
            </button>
          </div>
        </section>
      ) : (
        <div className="space-y-6">
          <section className="rounded-3xl border border-border-light bg-white p-7 shadow-sm space-y-4">
            <div className="flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between">
              <div>
                <span className="inline-block rounded-full bg-emerald-50 text-emerald-700 px-3 py-0.5 text-[10px] font-black uppercase tracking-wider mb-2">
                  {project.status.replaceAll('_', ' ')}
                </span>
                <h2 className="text-xl font-black text-text-main">{project.title}</h2>
              </div>
              {project.repository_url && (
                <a 
                  href={project.repository_url} 
                  target="_blank" 
                  rel="noopener noreferrer" 
                  className="flex items-center gap-1.5 text-xs font-bold text-primary-purple hover:underline"
                >
                  <ExternalLink className="h-3.5 w-3.5"/> GitHub Repository
                </a>
              )}
            </div>
            <p className="text-sm leading-relaxed text-text-muted">{project.description}</p>
            <p className="text-xs font-bold text-text-muted">Guide: {project.guide_name || 'Assigned faculty guide'}</p>
          </section>

          <section className="rounded-3xl border border-border-light bg-white p-7 shadow-sm space-y-4">
            <h3 className="font-black text-text-main text-base">Weekly Progress Log</h3>
            <div className="flex gap-2">
              <input value={note} onChange={(e) => setNote(e.target.value)} placeholder="e.g. Implemented JWT authentication and PostgreSQL indexes..." className={inputClass} />
              <button disabled={busy} onClick={addLog} className="flex shrink-0 items-center gap-2 rounded-xl bg-primary-purple px-5 py-3 text-xs font-black text-white hover:bg-violet-700 disabled:opacity-50">
                <Save className="h-4 w-4"/> Save Log
              </button>
            </div>
            <div className="space-y-3 pt-2">
              {logs.map((log) => (
                <div key={log.id} className="rounded-2xl bg-page-bg p-4 border border-border-light text-xs font-medium text-text-main flex justify-between items-center">
                  <span>{log.note}</span>
                  <span className="text-text-muted font-bold ml-4">{new Intl.DateTimeFormat('en-IN', { dateStyle: 'short' }).format(new Date(log.created_at))}</span>
                </div>
              ))}
            </div>
          </section>
        </div>
      )}

      {message && (
        <div className="rounded-2xl border border-emerald-200 bg-emerald-50 p-4 text-xs font-bold text-emerald-900">
          {message}
        </div>
      )}
    </div>
  )
}
