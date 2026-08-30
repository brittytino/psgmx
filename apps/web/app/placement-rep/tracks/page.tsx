'use client'

import React from 'react'
import { BookOpenCheck, CalendarRange, CirclePause, CirclePlay, Plus, Route, ShieldCheck } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { getCurrentProfile } from '@/lib/current-profile'
import type { Database } from '@/../../supabase/types/database.types'

type Track = Database['public']['Tables']['preparation_tracks']['Row']

const emptyForm = {
  title: '',
  summary: '',
  stage: 'all' as Track['stage'],
  difficulty: 'adaptive' as Track['difficulty'],
  skillDomains: '',
  estimatedWeeks: 4,
}

export default function PreparationTracksPage() {
  const supabase = React.useMemo(() => createClient(), [])
  const [tracks, setTracks] = React.useState<Track[]>([])
  const [profile, setProfile] = React.useState<{ id: string; batch_id: string | null } | null>(null)
  const [form, setForm] = React.useState(emptyForm)
  const [loading, setLoading] = React.useState(true)
  const [busy, setBusy] = React.useState(false)
  const [error, setError] = React.useState('')
  const [message, setMessage] = React.useState('')

  const load = React.useCallback(async () => {
    setLoading(true)
    setError('')
    try {
      const me = await getCurrentProfile(supabase)
      if (!me) throw new Error('Your PSGMX profile could not be loaded.')
      setProfile({ id: me.id, batch_id: me.batch_id })
      let query = supabase.from('preparation_tracks').select('*').order('created_at', { ascending: false })
      if (me.batch_id) query = query.or(`batch_id.is.null,batch_id.eq.${me.batch_id}`)
      const { data, error: loadError } = await query
      if (loadError) throw loadError
      setTracks(data ?? [])
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : 'Preparation tracks could not be loaded.')
    } finally {
      setLoading(false)
    }
  }, [supabase])

  React.useEffect(() => { void load() }, [load])

  async function createTrack(event: React.FormEvent) {
    event.preventDefault()
    if (!profile) return
    setBusy(true)
    setError('')
    setMessage('')
    const skillDomains = form.skillDomains.split(',').map((item) => item.trim()).filter(Boolean)
    const { error: insertError } = await supabase.from('preparation_tracks').insert({
      batch_id: profile.batch_id,
      title: form.title.trim(),
      summary: form.summary.trim(),
      stage: form.stage,
      difficulty: form.difficulty,
      skill_domains: skillDomains,
      estimated_weeks: form.estimatedWeeks,
      created_by: profile.id,
    })
    if (insertError) setError(insertError.message)
    else {
      setMessage('Preparation track published for this batch.')
      setForm(emptyForm)
      await load()
    }
    setBusy(false)
  }

  async function toggleTrack(track: Track) {
    setError('')
    const { error: updateError } = await supabase
      .from('preparation_tracks')
      .update({ is_active: !track.is_active, updated_at: new Date().toISOString() })
      .eq('id', track.id)
    if (updateError) return setError(updateError.message)
    setTracks((current) => current.map((item) => item.id === track.id
      ? { ...item, is_active: !item.is_active, updated_at: new Date().toISOString() }
      : item))
  }

  return <div className="mx-auto max-w-6xl space-y-6">
    <header className="flex flex-col gap-4 lg:flex-row lg:items-end lg:justify-between">
      <div>
        <div className="mb-2 flex items-center gap-2 text-xs font-black uppercase tracking-[.16em] text-primary-purple">
          <Route className="h-4 w-4" /> Preparation programme
        </div>
        <h1 className="text-3xl font-black tracking-tight">Preparation Tracks</h1>
        <p className="mt-2 max-w-2xl text-sm leading-6 text-text-muted">Build reusable readiness journeys by stage and skill. PSGMX does not create or manage official placement drives.</p>
      </div>
      <div className="flex max-w-md gap-3 rounded-2xl border border-amber-200 bg-amber-50 p-4 text-xs font-semibold leading-5 text-amber-900">
        <ShieldCheck className="mt-0.5 h-5 w-5 shrink-0" />
        Official company, eligibility, application and shortlist information stays in NEO PAT.
      </div>
    </header>

    {error && <div role="alert" className="flex items-center justify-between rounded-2xl border border-red-200 bg-red-50 p-4 text-sm font-bold text-red-700"><span>{error}</span><button onClick={() => void load()} className="rounded-lg px-3 py-1.5 hover:bg-red-100">Retry</button></div>}
    {message && <div className="rounded-2xl border border-emerald-200 bg-emerald-50 p-4 text-sm font-bold text-emerald-800">{message}</div>}

    <section className="grid gap-6 xl:grid-cols-[.9fr_1.5fr]">
      <form onSubmit={createTrack} className="h-fit space-y-4 rounded-3xl border border-border-light bg-white p-6 shadow-sm">
        <div>
          <h2 className="text-lg font-black">Create a track</h2>
          <p className="mt-1 text-xs text-text-muted">One clear outcome, a realistic duration and reusable skills.</p>
        </div>
        <label className="block text-xs font-bold text-text-muted">Track title<input required minLength={3} maxLength={120} value={form.title} onChange={(event) => setForm({ ...form, title: event.target.value })} placeholder="Core CS interview foundation" className="mt-2 w-full rounded-xl border border-border-light px-4 py-3 text-sm text-text-main outline-none focus:border-primary-purple" /></label>
        <label className="block text-xs font-bold text-text-muted">Preparation outcome<textarea required minLength={10} maxLength={1000} value={form.summary} onChange={(event) => setForm({ ...form, summary: event.target.value })} placeholder="What will students be able to demonstrate?" className="mt-2 min-h-28 w-full resize-y rounded-xl border border-border-light px-4 py-3 text-sm text-text-main outline-none focus:border-primary-purple" /></label>
        <div className="grid gap-3 sm:grid-cols-2">
          <label className="text-xs font-bold text-text-muted">Stage<select value={form.stage} onChange={(event) => setForm({ ...form, stage: event.target.value as Track['stage'] })} className="mt-2 w-full rounded-xl border border-border-light px-3 py-3 text-sm text-text-main"><option value="all">All stages</option><option value="foundation">Junior · Foundation</option><option value="proof">Senior · Proof</option></select></label>
          <label className="text-xs font-bold text-text-muted">Difficulty<select value={form.difficulty} onChange={(event) => setForm({ ...form, difficulty: event.target.value as Track['difficulty'] })} className="mt-2 w-full rounded-xl border border-border-light px-3 py-3 text-sm text-text-main"><option value="adaptive">Adaptive</option><option value="foundation">Foundation</option><option value="intermediate">Intermediate</option><option value="advanced">Advanced</option></select></label>
        </div>
        <label className="block text-xs font-bold text-text-muted">Skill domains<input value={form.skillDomains} onChange={(event) => setForm({ ...form, skillDomains: event.target.value })} placeholder="DBMS, OS, communication" className="mt-2 w-full rounded-xl border border-border-light px-4 py-3 text-sm text-text-main outline-none focus:border-primary-purple" /></label>
        <label className="block text-xs font-bold text-text-muted">Estimated weeks<input required type="number" min={1} max={24} value={form.estimatedWeeks} onChange={(event) => setForm({ ...form, estimatedWeeks: Number(event.target.value) })} className="mt-2 w-full rounded-xl border border-border-light px-4 py-3 text-sm text-text-main outline-none focus:border-primary-purple" /></label>
        <button disabled={busy || !profile} className="flex w-full items-center justify-center gap-2 rounded-xl bg-primary-purple px-5 py-3 text-sm font-black text-white disabled:opacity-50"><Plus className="h-4 w-4" />{busy ? 'Publishing…' : 'Publish preparation track'}</button>
      </form>

      <div className="space-y-4">
        {loading && <div className="rounded-3xl border border-border-light bg-white p-8"><div className="h-4 w-40 animate-pulse rounded bg-page-bg"/><div className="mt-4 h-24 animate-pulse rounded-2xl bg-page-bg"/></div>}
        {!loading && tracks.length === 0 && <div className="rounded-3xl border border-dashed border-border-light bg-white p-14 text-center"><BookOpenCheck className="mx-auto h-10 w-10 text-primary-purple"/><h2 className="mt-4 text-lg font-black">No preparation tracks yet</h2><p className="mt-2 text-sm text-text-muted">Create the first readiness journey for this batch.</p></div>}
        {tracks.map((track) => <article key={track.id} className={`rounded-3xl border bg-white p-6 shadow-sm ${track.is_active ? 'border-border-light' : 'border-dashed border-border-light opacity-70'}`}>
          <div className="flex items-start justify-between gap-4">
            <div><div className="flex flex-wrap items-center gap-2"><span className="rounded-full bg-primary-purple/10 px-2.5 py-1 text-[10px] font-black uppercase tracking-wider text-primary-purple">{track.stage}</span><span className="rounded-full bg-page-bg px-2.5 py-1 text-[10px] font-black uppercase tracking-wider text-text-muted">{track.difficulty}</span></div><h2 className="mt-3 text-xl font-black">{track.title}</h2></div>
            <button onClick={() => void toggleTrack(track)} className="rounded-xl border border-border-light p-2.5 text-text-muted transition hover:text-primary-purple" title={track.is_active ? 'Pause track' : 'Activate track'}>{track.is_active ? <CirclePause className="h-5 w-5"/> : <CirclePlay className="h-5 w-5"/>}</button>
          </div>
          <p className="mt-3 text-sm leading-6 text-text-muted">{track.summary}</p>
          <div className="mt-5 flex flex-wrap items-center gap-3 text-xs font-bold text-text-muted"><span className="flex items-center gap-1.5"><CalendarRange className="h-4 w-4"/>{track.estimated_weeks} weeks</span>{track.skill_domains.map((skill) => <span key={skill} className="rounded-lg bg-page-bg px-2.5 py-1.5">{skill}</span>)}</div>
        </article>)}
      </div>
    </section>
  </div>
}
