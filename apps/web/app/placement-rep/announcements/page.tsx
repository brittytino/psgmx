'use client'

import React from 'react'
import { Megaphone, Plus, Trash2 } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { getCurrentProfile } from '@/lib/current-profile'

type Announcement = { id: string; title: string; message: string; is_priority: boolean; expiry_date: string | null; created_at: string }

export default function AnnouncementsPage() {
  const supabase = React.useMemo(() => createClient(), [])
  const [me, setMe] = React.useState<{ id: string; batch_id: string } | null>(null)
  const [rows, setRows] = React.useState<Announcement[]>([])
  const [form, setForm] = React.useState({ title: '', message: '', is_priority: false, expiry_date: '' })
  const [status, setStatus] = React.useState('')
  const load = React.useCallback(async () => {
    const profile = await getCurrentProfile(supabase)
    if (!profile?.batch_id) return
    setMe({ id: profile.id, batch_id: profile.batch_id })
    const { data } = await supabase.from('announcements').select('id,title,message,is_priority,expiry_date,created_at').eq('batch_id', profile.batch_id).order('created_at', { ascending: false })
    setRows(data ?? [])
  }, [supabase])
  React.useEffect(() => { void load() }, [load])
  async function publish(event: React.FormEvent) {
    event.preventDefault(); if (!me) return
    const { error } = await supabase.from('announcements').insert({ ...form, expiry_date: form.expiry_date ? new Date(form.expiry_date).toISOString() : null, batch_id: me.batch_id, created_by: me.id })
    setStatus(error ? error.message : 'Announcement published.')
    if (!error) { setForm({ title: '', message: '', is_priority: false, expiry_date: '' }); await load() }
  }
  async function remove(id: string) { await supabase.from('announcements').delete().eq('id', id); await load() }
  return <div className="max-w-5xl space-y-6">
    <div><h1 className="text-2xl font-black">Announcements</h1><p className="mt-1 text-sm text-text-muted">Publish concise, batch-specific updates that appear in the mobile Today feed.</p></div>
    <form onSubmit={publish} className="space-y-4 rounded-2xl border border-border-light bg-white p-5"><input required value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })} placeholder="Announcement title" className="w-full rounded-xl border border-border-light px-4 py-3 text-sm" /><textarea required value={form.message} onChange={(e) => setForm({ ...form, message: e.target.value })} placeholder="What students need to know" className="min-h-28 w-full rounded-xl border border-border-light px-4 py-3 text-sm" /><div className="flex flex-wrap items-center gap-4"><label className="flex items-center gap-2 text-sm font-semibold"><input type="checkbox" checked={form.is_priority} onChange={(e) => setForm({ ...form, is_priority: e.target.checked })} /> Priority</label><input type="datetime-local" value={form.expiry_date} onChange={(e) => setForm({ ...form, expiry_date: e.target.value })} className="rounded-xl border border-border-light px-3 py-2 text-sm" /><button className="ml-auto flex items-center gap-2 rounded-xl bg-primary-purple px-5 py-3 text-sm font-bold text-white"><Plus className="h-4 w-4" />Publish</button></div>{status && <p className="text-sm text-text-muted">{status}</p>}</form>
    <div className="space-y-3">{rows.map((row) => <article key={row.id} className="rounded-2xl border border-border-light bg-white p-5"><div className="flex items-start justify-between"><div className="flex gap-3"><Megaphone className={`mt-0.5 h-5 w-5 ${row.is_priority ? 'text-red-600' : 'text-primary-purple'}`} /><div><h2 className="font-black">{row.title}</h2><p className="mt-1 text-sm text-text-muted">{row.message}</p><p className="mt-2 text-xs text-text-muted">{new Date(row.created_at).toLocaleString()}</p></div></div><button onClick={() => remove(row.id)} className="p-2 text-text-muted hover:text-red-600"><Trash2 className="h-4 w-4" /></button></div></article>)}</div>
  </div>
}
