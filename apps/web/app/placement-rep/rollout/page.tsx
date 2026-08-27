'use client'

import React from 'react'
import { Rocket, Save, ShieldCheck } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'

type Batch = { id: string; batch_code: string; status: string }

export default function RolloutPage() {
  const supabase = React.useMemo(() => createClient(), [])
  const [configId, setConfigId] = React.useState('')
  const [stage, setStage] = React.useState('internal')
  const [enabled, setEnabled] = React.useState<string[]>([])
  const [batches, setBatches] = React.useState<Batch[]>([])
  const [message, setMessage] = React.useState('')

  React.useEffect(() => { void (async () => {
    const [{ data: config }, { data: batchRows }] = await Promise.all([
      supabase.from('app_config').select('id,rollout_stage,enabled_batch_ids').limit(1).single(),
      supabase.from('batches').select('id,batch_code,status').in('batch_code', ['25MX','26MX']).order('batch_code'),
    ])
    if (config) { setConfigId(config.id); setStage(config.rollout_stage); setEnabled(config.enabled_batch_ids ?? []) }
    setBatches(batchRows ?? [])
  })() }, [supabase])

  async function save() {
    const { error } = await supabase.from('app_config').update({ rollout_stage: stage, enabled_batch_ids: enabled, updated_by: 'placement-rep-console' }).eq('id', configId)
    setMessage(error ? error.message : 'Rollout controls saved.')
  }

  return <div className="max-w-4xl space-y-6">
    <div><h1 className="text-2xl font-black">Staged Rollout</h1><p className="mt-1 text-sm text-text-muted">Release safely from internal checks to pilot users, selected batches, then everyone.</p></div>
    <div className="grid gap-4 sm:grid-cols-4">{['internal','pilot','batch','full'].map((value, index) => <button key={value} onClick={() => setStage(value)} className={`rounded-2xl border p-5 text-left ${stage === value ? 'border-primary-purple bg-primary-purple text-white' : 'border-border-light bg-white'}`}><p className="text-xs font-black uppercase opacity-70">Stage {index + 1}</p><p className="mt-2 text-lg font-black capitalize">{value}</p></button>)}</div>
    <section className="rounded-2xl border border-border-light bg-white p-6"><div className="flex items-center gap-3"><Rocket className="h-5 w-5 text-primary-purple" /><div><h2 className="font-black">Batch targets</h2><p className="text-sm text-text-muted">Used when the rollout stage is “batch”.</p></div></div><div className="mt-5 space-y-3">{batches.map((batch) => <label key={batch.id} className="flex cursor-pointer items-center justify-between rounded-xl bg-page-bg p-4"><div><p className="font-black">{batch.batch_code}</p><p className="text-xs capitalize text-text-muted">{batch.status.replaceAll('_',' ')}</p></div><input type="checkbox" checked={enabled.includes(batch.id)} onChange={(event) => setEnabled((old) => event.target.checked ? [...old, batch.id] : old.filter((id) => id !== batch.id))} className="h-5 w-5" /></label>)}</div></section>
    <div className="rounded-2xl border border-amber-200 bg-amber-50 p-5 text-sm"><ShieldCheck className="mr-2 inline h-4 w-4 text-amber-700" /><strong>Release rule:</strong> advance only after health checks, login, attendance sync, Daily Five, and PR workflows pass for the current stage.</div>
    <div className="flex items-center justify-between"><p className="text-sm font-semibold text-text-muted">{message}</p><button onClick={save} disabled={!configId} className="flex items-center gap-2 rounded-xl bg-primary-purple px-5 py-3 text-sm font-bold text-white disabled:opacity-50"><Save className="h-4 w-4" />Save rollout</button></div>
  </div>
}
