'use client'

import React from 'react'
import { Building2, Plus, Trash2 } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { getCurrentProfile } from '@/lib/current-profile'

type Company = { id: string; name: string; visit_date: string; package_band: string | null; roles_offered: string[]; eligibility: string | null }

export default function CompaniesPage() {
  const supabase = React.useMemo(() => createClient(), [])
  const [batchId, setBatchId] = React.useState('')
  const [actorId, setActorId] = React.useState('')
  const [companies, setCompanies] = React.useState<Company[]>([])
  const [form, setForm] = React.useState({ name: '', visit_date: '', roles: '', package_band: '', eligibility: '' })
  const [message, setMessage] = React.useState('')

  const load = React.useCallback(async () => {
    const me = await getCurrentProfile(supabase)
    if (!me?.batch_id) return
    setBatchId(me.batch_id); setActorId(me.id)
    const { data } = await supabase.from('companies').select('id,name,visit_date,package_band,roles_offered,eligibility').eq('batch_id', me.batch_id).order('visit_date', { ascending: false })
    setCompanies(data ?? [])
  }, [supabase])
  React.useEffect(() => { void load() }, [load])

  async function add(event: React.FormEvent) {
    event.preventDefault()
    const { error } = await supabase.from('companies').insert({
      batch_id: batchId, created_by: actorId, name: form.name.trim(), visit_date: form.visit_date,
      roles_offered: form.roles.split(',').map((item) => item.trim()).filter(Boolean),
      package_band: form.package_band || null, eligibility: form.eligibility || null, rounds: [],
    })
    setMessage(error ? error.message : 'Company drive added.')
    if (!error) { setForm({ name: '', visit_date: '', roles: '', package_band: '', eligibility: '' }); await load() }
  }
  async function remove(id: string) { if (window.confirm('Delete this company drive and linked experiences?')) { await supabase.from('companies').delete().eq('id', id); await load() } }

  return <div className="max-w-5xl space-y-6">
    <div><h1 className="text-2xl font-black">Companies & Drives</h1><p className="mt-1 text-sm text-text-muted">Maintain the placement pipeline and eligibility information for your batch.</p></div>
    <form onSubmit={add} className="grid gap-4 rounded-2xl border border-border-light bg-white p-5 sm:grid-cols-2">
      <input required value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} placeholder="Company name" className="rounded-xl border border-border-light px-4 py-3 text-sm" />
      <input required type="date" value={form.visit_date} onChange={(e) => setForm({ ...form, visit_date: e.target.value })} className="rounded-xl border border-border-light px-4 py-3 text-sm" />
      <input value={form.roles} onChange={(e) => setForm({ ...form, roles: e.target.value })} placeholder="Roles, comma separated" className="rounded-xl border border-border-light px-4 py-3 text-sm" />
      <input value={form.package_band} onChange={(e) => setForm({ ...form, package_band: e.target.value })} placeholder="Package band, e.g. 8–12 LPA" className="rounded-xl border border-border-light px-4 py-3 text-sm" />
      <textarea value={form.eligibility} onChange={(e) => setForm({ ...form, eligibility: e.target.value })} placeholder="Eligibility criteria" className="min-h-24 rounded-xl border border-border-light px-4 py-3 text-sm sm:col-span-2" />
      <div className="flex items-center justify-between sm:col-span-2"><p className="text-sm text-text-muted">{message}</p><button className="flex items-center gap-2 rounded-xl bg-primary-purple px-5 py-3 text-sm font-bold text-white"><Plus className="h-4 w-4" />Add drive</button></div>
    </form>
    <div className="grid gap-4 md:grid-cols-2">{companies.map((company) => <div key={company.id} className="rounded-2xl border border-border-light bg-white p-5"><div className="flex justify-between"><Building2 className="h-5 w-5 text-primary-purple" /><button onClick={() => remove(company.id)} className="text-text-muted hover:text-red-600"><Trash2 className="h-4 w-4" /></button></div><h2 className="mt-4 text-lg font-black">{company.name}</h2><p className="text-sm text-text-muted">{company.visit_date} · {company.package_band || 'Package pending'}</p><div className="mt-3 flex flex-wrap gap-2">{company.roles_offered.map((role) => <span key={role} className="rounded-full bg-page-bg px-3 py-1 text-xs font-bold">{role}</span>)}</div>{company.eligibility && <p className="mt-3 text-sm">{company.eligibility}</p>}</div>)}</div>
  </div>
}
