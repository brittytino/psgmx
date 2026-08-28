'use client'

import React from 'react'
import { CheckCircle2, CircleAlert, Loader2, Rocket, Save, ShieldCheck, Users } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { getCurrentProfile } from '@/lib/current-profile'

type Batch = { id: string; batch_code: string; status: string }
type LaunchMetric = { label: string; value: number; ready: boolean; hint: string }

const stages = [
  { value: 'internal', label: 'Internal', help: 'Staff and Placement Reps validate the complete flow.' },
  { value: 'pilot', label: 'Pilot', help: 'A small student group validates real daily usage.' },
  { value: 'batch', label: 'Selected batches', help: 'Enable only the batches chosen below.' },
  { value: 'full', label: 'Everyone', help: 'Open the experience to every active batch.' },
]

export default function RolloutPage() {
  const supabase = React.useMemo(() => createClient(), [])
  const [configId, setConfigId] = React.useState('')
  const [stage, setStage] = React.useState('internal')
  const [enabled, setEnabled] = React.useState<string[]>([])
  const [batches, setBatches] = React.useState<Batch[]>([])
  const [batchCode, setBatchCode] = React.useState('Your batch')
  const [metrics, setMetrics] = React.useState<LaunchMetric[]>([])
  const [loading, setLoading] = React.useState(true)
  const [saving, setSaving] = React.useState(false)
  const [message, setMessage] = React.useState('')

  const load = React.useCallback(async () => {
    setLoading(true)
    setMessage('')
    const me = await getCurrentProfile(supabase)
    const batchId = me?.batch_id
    const [{ data: config, error: configError }, { data: batchRows, error: batchError }] = await Promise.all([
      supabase.from('app_config').select('id,rollout_stage,enabled_batch_ids').limit(1).single(),
      supabase.from('batches').select('id,batch_code,status').neq('status', 'graduated').order('start_year'),
    ])

    if (configError || batchError) {
      setMessage('Rollout status could not be loaded. Please retry.')
      setLoading(false)
      return
    }
    if (config) {
      setConfigId(config.id)
      setStage(config.rollout_stage)
      setEnabled(config.enabled_batch_ids ?? [])
    }
    setBatches(batchRows ?? [])

    if (batchId) {
      const ownBatch = (batchRows ?? []).find((batch) => batch.id === batchId)
      setBatchCode(ownBatch?.batch_code ?? 'Your batch')
      const today = new Date().toISOString().slice(0, 10)
      const [{ count: rostered }, { count: activated }, { count: teams }, { count: tasks }, { count: sessions }, { count: announcements }] = await Promise.all([
        supabase.from('whitelist').select('email', { count: 'exact', head: true }).eq('batch_id', batchId),
        supabase.from('users').select('id', { count: 'exact', head: true }).eq('batch_id', batchId).eq('role_label', 'Student'),
        supabase.from('teams').select('id', { count: 'exact', head: true }).eq('batch_id', batchId),
        supabase.from('daily_tasks').select('id', { count: 'exact', head: true }).eq('batch_id', batchId).gte('date', today),
        supabase.from('placement_sessions').select('id', { count: 'exact', head: true }).eq('batch_id', batchId),
        supabase.from('announcements').select('id', { count: 'exact', head: true }).eq('batch_id', batchId),
      ])
      const rosterCount = rostered ?? 0
      const activatedCount = activated ?? 0
      setMetrics([
        { label: 'Roster loaded', value: rosterCount, ready: rosterCount > 0, hint: 'Import the complete student roster.' },
        { label: 'First logins', value: activatedCount, ready: rosterCount > 0 && activatedCount / rosterCount >= 0.8, hint: 'Target at least 80% activation.' },
        { label: 'Teams configured', value: teams ?? 0, ready: (teams ?? 0) > 0, hint: 'Create teams and assign leaders.' },
        { label: 'Daily work ready', value: tasks ?? 0, ready: (tasks ?? 0) > 0, hint: 'Publish at least one current quest.' },
        { label: 'Sessions created', value: sessions ?? 0, ready: (sessions ?? 0) > 0, hint: 'Create the first placement session.' },
        { label: 'Welcome update', value: announcements ?? 0, ready: (announcements ?? 0) > 0, hint: 'Publish a useful batch announcement.' },
      ])
    }
    setLoading(false)
  }, [supabase])

  React.useEffect(() => { void load() }, [load])

  async function save() {
    if (!configId) return
    setSaving(true)
    setMessage('')
    const { error } = await supabase.from('app_config').update({
      rollout_stage: stage,
      enabled_batch_ids: enabled,
      updated_by: 'placement-rep-console',
    }).eq('id', configId)
    setMessage(error ? error.message : 'Rollout settings saved. The new access stage is now active.')
    setSaving(false)
  }

  if (loading) return <div className="flex min-h-64 items-center justify-center"><Loader2 className="h-6 w-6 animate-spin text-primary-purple" /></div>

  const readyCount = metrics.filter((metric) => metric.ready).length
  const canAdvance = metrics.length > 0 && readyCount === metrics.length

  return <div className="max-w-6xl space-y-7 pb-10">
    <div className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
      <div><p className="text-xs font-black uppercase tracking-[0.18em] text-primary-purple">Launch control</p><h1 className="mt-1 text-2xl font-black">Rollout & readiness</h1><p className="mt-1 text-sm text-text-muted">Move from setup to daily adoption with evidence, not guesswork.</p></div>
      <div className={`rounded-2xl border px-4 py-3 ${canAdvance ? 'border-emerald-200 bg-emerald-50' : 'border-amber-200 bg-amber-50'}`}><p className="text-xs font-bold text-text-muted">{batchCode} launch health</p><p className="mt-0.5 text-lg font-black">{readyCount}/{metrics.length} checks ready</p></div>
    </div>

    <section className="rounded-3xl border border-border-light bg-white p-5 sm:p-6">
      <div className="flex items-start gap-3"><ShieldCheck className="mt-0.5 h-5 w-5 text-primary-purple"/><div><h2 className="font-black">Before students are invited</h2><p className="text-sm text-text-muted">These checks use live records from your batch.</p></div></div>
      <div className="mt-5 grid gap-3 sm:grid-cols-2 lg:grid-cols-3">{metrics.map((metric) => <div key={metric.label} className="rounded-2xl bg-page-bg p-4"><div className="flex items-center justify-between"><p className="text-sm font-black">{metric.label}</p>{metric.ready ? <CheckCircle2 className="h-5 w-5 text-emerald-600"/> : <CircleAlert className="h-5 w-5 text-amber-600"/>}</div><p className="mt-3 text-2xl font-black">{metric.value}</p><p className="mt-1 text-xs text-text-muted">{metric.hint}</p></div>)}</div>
    </section>

    <section>
      <h2 className="font-black">Access stage</h2><p className="mt-1 text-sm text-text-muted">Advance one stage at a time after a real login and daily-flow check.</p>
      <div className="mt-4 grid gap-3 sm:grid-cols-2 lg:grid-cols-4">{stages.map((item, index) => <button key={item.value} onClick={() => setStage(item.value)} className={`min-h-36 rounded-2xl border p-5 text-left transition ${stage === item.value ? 'border-primary-purple bg-primary-purple text-white shadow-lg shadow-primary-purple/15' : 'border-border-light bg-white hover:border-primary-purple/40'}`}><p className="text-xs font-black uppercase opacity-70">Stage {index + 1}</p><p className="mt-2 text-lg font-black">{item.label}</p><p className="mt-2 text-xs leading-5 opacity-75">{item.help}</p></button>)}</div>
    </section>

    <section className="rounded-3xl border border-border-light bg-white p-5 sm:p-6"><div className="flex items-center gap-3"><Users className="h-5 w-5 text-primary-purple"/><div><h2 className="font-black">Batch access</h2><p className="text-sm text-text-muted">Applies during the “Selected batches” stage. Future batches appear automatically.</p></div></div><div className="mt-5 grid gap-3 sm:grid-cols-2">{batches.map((batch) => <label key={batch.id} className="flex cursor-pointer items-center justify-between rounded-2xl bg-page-bg p-4"><div><p className="font-black">{batch.batch_code}</p><p className="text-xs capitalize text-text-muted">{batch.status.replaceAll('_', ' ')}</p></div><input type="checkbox" checked={enabled.includes(batch.id)} onChange={(event) => setEnabled((old) => event.target.checked ? [...new Set([...old, batch.id])] : old.filter((id) => id !== batch.id))} className="h-5 w-5 accent-[#5B3FD1]" /></label>)}</div>{batches.length === 0 && <p className="mt-5 text-sm text-text-muted">No active or onboarding batches are available.</p>}</section>

    <div className="flex flex-col gap-3 rounded-2xl border border-amber-200 bg-amber-50 p-5 sm:flex-row sm:items-center sm:justify-between"><div className="text-sm"><Rocket className="mr-2 inline h-4 w-4 text-amber-700"/><strong>Release rule:</strong> verify OTP, Today, attendance, Daily Five and one PR workflow on a real phone before advancing.</div><button onClick={save} disabled={!configId || saving || (stage === 'batch' && enabled.length === 0)} className="flex shrink-0 items-center justify-center gap-2 rounded-xl bg-primary-purple px-5 py-3 text-sm font-bold text-white disabled:opacity-50">{saving ? <Loader2 className="h-4 w-4 animate-spin"/> : <Save className="h-4 w-4"/>}{saving ? 'Saving…' : 'Save rollout'}</button></div>
    {message && <p className="rounded-xl bg-page-bg px-4 py-3 text-sm font-semibold" role="status">{message}</p>}
  </div>
}
