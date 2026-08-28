'use client'

import React from 'react'
import { Bell, Github, Linkedin, Loader2, LogOut, Save, Settings, ShieldCheck, UserRound } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { getCurrentProfile } from '@/lib/current-profile'

type Profile = {
  id: string
  name: string
  email: string
  reg_no: string
  role_label: string
  batch_id: string | null
  linkedin_url: string | null
  github_url: string | null
  task_reminders_enabled: boolean | null
  attendance_alerts_enabled: boolean | null
  announcements_enabled: boolean | null
  leetcode_notifications_enabled: boolean | null
}

export default function StudentSettingsPage() {
  const supabase = React.useMemo(() => createClient(), [])
  const [profile, setProfile] = React.useState<Profile | null>(null)
  const [batchCode, setBatchCode] = React.useState('MCA')
  const [loading, setLoading] = React.useState(true)
  const [saving, setSaving] = React.useState(false)
  const [message, setMessage] = React.useState('')

  React.useEffect(() => { void (async () => {
    try {
      const me = await getCurrentProfile(supabase)
      if (!me) throw new Error('Your profile could not be found.')
      const { data, error } = await supabase.from('users').select('id,name,email,reg_no,role_label,batch_id,linkedin_url,github_url,task_reminders_enabled,attendance_alerts_enabled,announcements_enabled,leetcode_notifications_enabled').eq('id', me.id).single()
      if (error) throw error
      setProfile(data)
      if (data.batch_id) {
        const { data: batch } = await supabase.from('batches').select('batch_code').eq('id', data.batch_id).single()
        if (batch?.batch_code) setBatchCode(batch.batch_code)
      }
    } catch (cause) {
      setMessage(cause instanceof Error ? cause.message : 'Profile could not be loaded.')
    } finally {
      setLoading(false)
    }
  })() }, [supabase])

  async function save() {
    if (!profile) return
    setSaving(true)
    setMessage('')
    const { error } = await supabase.from('users').update({
      name: profile.name.trim(),
      linkedin_url: profile.linkedin_url?.trim() || null,
      github_url: profile.github_url?.trim() || null,
      task_reminders_enabled: profile.task_reminders_enabled,
      attendance_alerts_enabled: profile.attendance_alerts_enabled,
      announcements_enabled: profile.announcements_enabled,
      leetcode_notifications_enabled: profile.leetcode_notifications_enabled,
    }).eq('id', profile.id)
    setMessage(error ? error.message : 'Your profile and preferences are saved.')
    setSaving(false)
  }

  if (loading) return <div className="flex min-h-64 items-center justify-center"><Loader2 className="h-6 w-6 animate-spin text-primary-purple"/></div>

  return <div className="mx-auto max-w-4xl space-y-7 pb-10">
    <div><h1 className="flex items-center gap-2 text-2xl font-black"><Settings className="h-6 w-6 text-primary-purple"/>Your profile</h1><p className="mt-1 text-sm text-text-muted">Keep the details used across placement, lineage and notifications accurate.</p></div>

    {!profile ? <div className="rounded-2xl border border-amber-200 bg-amber-50 p-5"><p className="font-bold">{message || 'Your profile is unavailable.'}</p></div> : <>
      <section className="rounded-3xl border border-border-light bg-white p-5 sm:p-6">
        <div className="flex items-center gap-3"><div className="flex h-14 w-14 items-center justify-center rounded-2xl bg-gradient-to-br from-primary-purple to-deep-violet text-xl font-black text-white">{profile.name.trim().charAt(0).toUpperCase() || 'S'}</div><div><h2 className="font-black">{profile.name}</h2><p className="text-sm text-text-muted">{profile.email}</p></div></div>
        <div className="mt-6 grid gap-3 sm:grid-cols-3">{[
          ['Register number', profile.reg_no],
          ['Batch', batchCode],
          ['Access', profile.role_label],
        ].map(([label, value]) => <div key={label} className="rounded-2xl bg-page-bg p-4"><p className="text-[10px] font-black uppercase tracking-wide text-text-muted">{label}</p><p className="mt-1 font-black">{value}</p></div>)}</div>
        <p className="mt-4 flex items-center gap-2 text-xs text-text-muted"><ShieldCheck className="h-4 w-4"/>Register number and batch are protected. Ask your Placement Rep or faculty coordinator to correct them.</p>
      </section>

      <section className="rounded-3xl border border-border-light bg-white p-5 sm:p-6"><div className="flex items-center gap-2"><UserRound className="h-5 w-5 text-primary-purple"/><h2 className="font-black">Public placement profile</h2></div><div className="mt-5 space-y-4">
        <Field label="Display name"><input value={profile.name} onChange={(event) => setProfile({ ...profile, name: event.target.value })} className="w-full rounded-xl border border-border-light bg-page-bg px-4 py-3 text-sm outline-none focus:border-primary-purple" maxLength={100}/></Field>
        <Field label="LinkedIn URL" icon={<Linkedin className="h-4 w-4"/>}><input type="url" value={profile.linkedin_url ?? ''} onChange={(event) => setProfile({ ...profile, linkedin_url: event.target.value })} placeholder="https://linkedin.com/in/your-name" className="w-full rounded-xl border border-border-light bg-page-bg px-4 py-3 text-sm outline-none focus:border-primary-purple"/></Field>
        <Field label="GitHub URL" icon={<Github className="h-4 w-4"/>}><input type="url" value={profile.github_url ?? ''} onChange={(event) => setProfile({ ...profile, github_url: event.target.value })} placeholder="https://github.com/your-name" className="w-full rounded-xl border border-border-light bg-page-bg px-4 py-3 text-sm outline-none focus:border-primary-purple"/></Field>
      </div></section>

      <section className="rounded-3xl border border-border-light bg-white p-5 sm:p-6"><div className="flex items-center gap-2"><Bell className="h-5 w-5 text-primary-purple"/><h2 className="font-black">Useful reminders</h2></div><div className="mt-5 space-y-3">
        <Toggle label="Daily quest reminders" hint="A short reminder when today’s placement work is still open." checked={profile.task_reminders_enabled ?? true} onChange={(value) => setProfile({ ...profile, task_reminders_enabled: value })}/>
        <Toggle label="Attendance alerts" hint="Notify you when attendance needs attention." checked={profile.attendance_alerts_enabled ?? true} onChange={(value) => setProfile({ ...profile, attendance_alerts_enabled: value })}/>
        <Toggle label="Batch announcements" hint="Important updates from your Placement Rep and department." checked={profile.announcements_enabled ?? true} onChange={(value) => setProfile({ ...profile, announcements_enabled: value })}/>
        <Toggle label="LeetCode progress" hint="Milestones and reminders tied to your connected profile." checked={profile.leetcode_notifications_enabled ?? true} onChange={(value) => setProfile({ ...profile, leetcode_notifications_enabled: value })}/>
      </div></section>

      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between"><div>{message && <p className="text-sm font-semibold" role="status">{message}</p>}</div><button onClick={save} disabled={saving || !profile.name.trim()} className="flex items-center justify-center gap-2 rounded-xl bg-primary-purple px-6 py-3 text-sm font-bold text-white disabled:opacity-50">{saving ? <Loader2 className="h-4 w-4 animate-spin"/> : <Save className="h-4 w-4"/>}{saving ? 'Saving…' : 'Save changes'}</button></div>
    </>}

    <section className="rounded-3xl border border-border-light bg-white p-5 sm:p-6"><h2 className="font-black">Passwordless account</h2><p className="mt-2 text-sm leading-6 text-text-muted">PSGMX uses a one-time code sent to your approved email, so there is no password to remember or reset.</p><button onClick={async () => { try { await fetch('/api/auth/logout', { method: 'POST' }) } finally { window.location.href = '/login' } }} className="mt-5 flex items-center gap-2 rounded-xl border border-border-light px-5 py-3 text-sm font-bold text-deep-violet"><LogOut className="h-4 w-4"/>Sign out securely</button></section>
  </div>
}

function Field({ label, icon, children }: { label: string; icon?: React.ReactNode; children: React.ReactNode }) {
  return <label className="block"><span className="mb-2 flex items-center gap-2 text-xs font-black uppercase tracking-wide text-text-muted">{icon}{label}</span>{children}</label>
}

function Toggle({ label, hint, checked, onChange }: { label: string; hint: string; checked: boolean; onChange: (value: boolean) => void }) {
  return <label className="flex cursor-pointer items-center justify-between gap-4 rounded-2xl bg-page-bg p-4"><span><span className="block text-sm font-black">{label}</span><span className="mt-0.5 block text-xs text-text-muted">{hint}</span></span><input type="checkbox" checked={checked} onChange={(event) => onChange(event.target.checked)} className="h-5 w-5 shrink-0 accent-[#5B3FD1]"/></label>
}
