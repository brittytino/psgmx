'use client'

import React from 'react'
import { Linkedin, Save, Settings, ShieldCheck, ToggleLeft, ToggleRight } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { getCurrentProfile } from '@/lib/current-profile'

type ProfileForm = { id: string; name: string; regNo: string; batch: string; email: string; company: string; role: string; linkedin: string; github: string; skills: string; mentorshipOpen: boolean }

export default function AlumniSettingsPage() {
  const supabase = React.useMemo(() => createClient(), [])
  const [form, setForm] = React.useState<ProfileForm | null>(null)
  const [loading, setLoading] = React.useState(true)
  const [busy, setBusy] = React.useState(false)
  const [message, setMessage] = React.useState('')
  const [error, setError] = React.useState('')

  React.useEffect(() => { void (async () => {
    try {
      const me = await getCurrentProfile(supabase)
      if (!me) throw new Error('Your alumni profile could not be loaded.')
      setForm({ id: me.id, name: me.name, regNo: me.reg_no, batch: me.batch, email: me.email, company: me.current_company ?? '', role: me.current_role_title ?? '', linkedin: me.linkedin_url ?? '', github: me.github_url ?? '', skills: (me.skills ?? []).join(', '), mentorshipOpen: me.mentorship_open })
    } catch (cause) { setError(cause instanceof Error ? cause.message : 'Your profile could not be loaded.') }
    finally { setLoading(false) }
  })() }, [supabase])

  async function save() {
    if (!form) return
    setBusy(true); setError(''); setMessage('')
    const { error: updateError } = await supabase.from('users').update({ name: form.name.trim(), current_company: form.company.trim() || null, current_role_title: form.role.trim() || null, linkedin_url: form.linkedin.trim() || null, github_url: form.github.trim() || null, skills: form.skills.split(',').map((skill) => skill.trim()).filter(Boolean), mentorship_open: form.mentorshipOpen }).eq('id', form.id)
    if (updateError) setError(updateError.message)
    else setMessage('Your alumni profile and mentorship preference are up to date.')
    setBusy(false)
  }

  if (loading) return <div className="mx-auto h-96 max-w-4xl animate-pulse rounded-3xl bg-white" />
  if (!form) return <div role="alert" className="mx-auto max-w-4xl rounded-2xl border border-red-200 bg-red-50 p-5 text-sm font-bold text-red-700">{error}</div>

  return <div className="mx-auto max-w-4xl space-y-6 pb-10">
    <header><div className="mb-2 flex items-center gap-2 text-xs font-black uppercase tracking-[.16em] text-primary-purple"><Settings className="h-4 w-4"/> Alumni identity</div><h1 className="text-3xl font-black tracking-tight">Account & mentorship</h1><p className="mt-2 text-sm text-text-muted">Keep the professional context juniors rely on accurate. Identity fields remain tied to the verified roster.</p></header>
    {error && <div role="alert" className="rounded-2xl border border-red-200 bg-red-50 p-4 text-sm font-bold text-red-700">{error}</div>}
    {message && <div className="rounded-2xl border border-emerald-200 bg-emerald-50 p-4 text-sm font-bold text-emerald-800">{message}</div>}
    <section className="rounded-3xl border border-border-light bg-white p-6 shadow-sm"><h2 className="text-lg font-black">Verified identity</h2><div className="mt-4 grid gap-3 sm:grid-cols-3">{[['Register number', form.regNo], ['Batch', form.batch], ['Login email', form.email]].map(([label, value]) => <div key={label} className="rounded-2xl bg-page-bg p-4"><p className="text-[10px] font-black uppercase tracking-wider text-text-muted">{label}</p><p className="mt-1 break-all text-sm font-bold">{value}</p></div>)}</div></section>
    <section className="rounded-3xl border border-border-light bg-white p-6 shadow-sm"><h2 className="text-lg font-black">Professional context</h2><div className="mt-5 grid gap-4 sm:grid-cols-2"><Field label="Display name" value={form.name} onChange={(name) => setForm({...form, name})}/><Field label="Current organisation" value={form.company} onChange={(company) => setForm({...form, company})}/><Field label="Current role" value={form.role} onChange={(role) => setForm({...form, role})}/><Field label="Skills (comma separated)" value={form.skills} onChange={(skills) => setForm({...form, skills})}/><Field label="LinkedIn URL" value={form.linkedin} onChange={(linkedin) => setForm({...form, linkedin})} icon={<Linkedin className="h-3.5 w-3.5"/>}/><Field label="GitHub URL" value={form.github} onChange={(github) => setForm({...form, github})}/></div></section>
    <section className="rounded-3xl border border-border-light bg-white p-6 shadow-sm"><div className="flex items-center justify-between gap-5"><div><h2 className="text-lg font-black">Open to mentorship</h2><p className="mt-1 text-sm leading-6 text-text-muted">Students can send structured requests inside PSGMX. Your private contact details are never published by this switch.</p></div><button aria-pressed={form.mentorshipOpen} onClick={() => setForm({...form, mentorshipOpen: !form.mentorshipOpen})}>{form.mentorshipOpen ? <ToggleRight className="h-11 w-11 text-emerald-600"/> : <ToggleLeft className="h-11 w-11 text-text-muted"/>}</button></div></section>
    <div className="flex flex-col gap-3 rounded-2xl border border-blue-200 bg-blue-50 p-4 text-sm text-blue-900 sm:flex-row sm:items-center sm:justify-between"><div className="flex gap-3"><ShieldCheck className="h-5 w-5 shrink-0"/><p>PSGMX uses email OTP. There is no password to create or manage here.</p></div><button disabled={busy} onClick={() => void save()} className="inline-flex shrink-0 items-center justify-center gap-2 rounded-xl bg-primary-purple px-5 py-3 text-sm font-black text-white disabled:opacity-50"><Save className="h-4 w-4"/>{busy ? 'Saving…' : 'Save changes'}</button></div>
  </div>
}

function Field({ label, value, onChange, icon }: { label: string; value: string; onChange: (value: string) => void; icon?: React.ReactNode }) {
  return <label><span className="mb-2 flex items-center gap-2 text-[11px] font-black uppercase tracking-wider text-text-muted">{icon}{label}</span><input value={value} onChange={(event) => onChange(event.target.value)} className="w-full rounded-xl border border-border-light bg-page-bg px-4 py-3 text-sm outline-none focus:border-primary-purple"/></label>
}
