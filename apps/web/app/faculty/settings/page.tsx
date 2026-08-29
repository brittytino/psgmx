'use client'

import React from 'react'
import { Bell, Check, LogOut, Save, Settings, ShieldCheck, UserRound } from 'lucide-react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { getCurrentProfile } from '@/lib/current-profile'

type FacultyForm = {
  id: string; name: string; email: string; regNo: string; role: string
  announcements: boolean; taskReminders: boolean; leetcode: boolean; attendance: boolean
}
type NotificationKey = 'announcements' | 'taskReminders' | 'leetcode' | 'attendance'

export default function FacultySettingsPage() {
  const router = useRouter()
  const supabase = React.useMemo(() => createClient(), [])
  const [form, setForm] = React.useState<FacultyForm | null>(null)
  const [loading, setLoading] = React.useState(true)
  const [busy, setBusy] = React.useState(false)
  const [message, setMessage] = React.useState('')
  const [error, setError] = React.useState('')

  React.useEffect(() => { void (async () => {
    try {
      const me = await getCurrentProfile(supabase)
      if (!me) throw new Error('Your faculty profile could not be loaded.')
      setForm({ id: me.id, name: me.name, email: me.email, regNo: me.reg_no, role: me.role_label, announcements: me.announcements_enabled ?? true, taskReminders: me.task_reminders_enabled ?? true, leetcode: me.leetcode_notifications_enabled ?? false, attendance: me.attendance_alerts_enabled ?? true })
    } catch (cause) { setError(cause instanceof Error ? cause.message : 'Settings could not be loaded.') }
    finally { setLoading(false) }
  })() }, [supabase])

  async function save() {
    if (!form) return
    setBusy(true); setError(''); setMessage('')
    const { error: updateError } = await supabase.from('users').update({ name: form.name.trim(), announcements_enabled: form.announcements, task_reminders_enabled: form.taskReminders, leetcode_notifications_enabled: form.leetcode, attendance_alerts_enabled: form.attendance }).eq('id', form.id)
    if (updateError) setError(updateError.message)
    else setMessage('Your faculty preferences were saved.')
    setBusy(false)
  }

  if (loading) return <div className="mx-auto h-96 max-w-4xl animate-pulse rounded-3xl bg-white"/>
  if (!form) return <div role="alert" className="mx-auto max-w-4xl rounded-2xl border border-red-200 bg-red-50 p-5 text-sm font-bold text-red-700">{error}</div>

  return <div className="mx-auto max-w-4xl space-y-6 pb-10">
    <header><div className="mb-2 flex items-center gap-2 text-xs font-black uppercase tracking-[.16em] text-primary-purple"><Settings className="h-4 w-4"/> Faculty account</div><h1 className="text-3xl font-black tracking-tight">Identity & preferences</h1><p className="mt-2 text-sm text-text-muted">Live settings for your verified department account.</p></header>
    {error && <div role="alert" className="rounded-2xl border border-red-200 bg-red-50 p-4 text-sm font-bold text-red-700">{error}</div>}
    {message && <div className="flex items-center gap-2 rounded-2xl border border-emerald-200 bg-emerald-50 p-4 text-sm font-bold text-emerald-800"><Check className="h-4 w-4"/>{message}</div>}
    <section className="rounded-3xl border border-border-light bg-white p-6 shadow-sm"><div className="flex items-center gap-2"><UserRound className="h-5 w-5 text-primary-purple"/><h2 className="text-lg font-black">Verified profile</h2></div><div className="mt-5 grid gap-4 sm:grid-cols-2"><label className="text-xs font-black text-text-muted">Display name<input value={form.name} onChange={(event) => setForm({...form, name: event.target.value})} className="mt-2 w-full rounded-xl border border-border-light bg-page-bg px-4 py-3 text-sm outline-none focus:border-primary-purple"/></label>{[['Department email', form.email], ['Faculty identifier', form.regNo], ['Access role', form.role]].map(([label, value]) => <div key={label} className="rounded-xl bg-page-bg px-4 py-3"><p className="text-[10px] font-black uppercase tracking-wider text-text-muted">{label}</p><p className="mt-1 break-all text-sm font-bold">{value}</p></div>)}</div></section>
    <section className="rounded-3xl border border-border-light bg-white p-6 shadow-sm"><div className="flex items-center gap-2"><Bell className="h-5 w-5 text-primary-purple"/><h2 className="text-lg font-black">Notification preferences</h2></div><div className="mt-5 divide-y divide-border-light">{[
      ['Approved announcements', 'Department communication and action-required notices.', 'announcements' as const],
      ['Preparation reminders', 'Assessment, quest and review reminders.', 'taskReminders' as const],
      ['Coding progress', 'LeetCode freshness and identity notifications.', 'leetcode' as const],
      ['Participation alerts', 'Preparation participation signals requiring review.', 'attendance' as const],
    ].map(([title, description, rawKey]) => { const key = rawKey as NotificationKey; return <label key={key} className="flex cursor-pointer items-center justify-between gap-5 py-4"><span><span className="block text-sm font-black">{title}</span><span className="mt-1 block text-xs text-text-muted">{description}</span></span><input type="checkbox" checked={form[key]} onChange={(event) => setForm({...form, [key]: event.target.checked})} className="h-5 w-5 accent-primary-purple"/></label> })}</div></section>
    <section className="flex flex-col gap-4 rounded-3xl border border-blue-200 bg-blue-50 p-6 sm:flex-row sm:items-center sm:justify-between"><div className="flex gap-3"><ShieldCheck className="h-5 w-5 shrink-0 text-blue-800"/><div><h2 className="text-sm font-black text-blue-900">OTP-protected account</h2><p className="mt-1 text-xs leading-5 text-blue-800">Faculty access uses a one-time code sent to your rostered email. PSGMX does not store an account password.</p></div></div><button onClick={async () => { await supabase.auth.signOut(); router.replace('/login') }} className="inline-flex shrink-0 items-center justify-center gap-2 rounded-xl border border-blue-300 px-4 py-2.5 text-sm font-black text-blue-900"><LogOut className="h-4 w-4"/>Sign out</button></section>
    <div className="flex justify-end"><button disabled={busy} onClick={() => void save()} className="inline-flex items-center gap-2 rounded-xl bg-primary-purple px-6 py-3 text-sm font-black text-white disabled:opacity-50"><Save className="h-4 w-4"/>{busy ? 'Saving…' : 'Save preferences'}</button></div>
  </div>
}
