'use client'

import React from 'react'
import { AlertTriangle, Bell, CheckCircle2, Loader2, Megaphone } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { getCurrentProfile } from '@/lib/current-profile'

type Announcement = { id: string; title: string; message: string; is_priority: boolean; expiry_date: string | null; created_at: string }

export default function AnnouncementsPage() {
  const supabase = React.useMemo(() => createClient(), [])
  const db = supabase as any
  const [userId, setUserId] = React.useState('')
  const [rows, setRows] = React.useState<Announcement[]>([])
  const [readIds, setReadIds] = React.useState<Set<string>>(new Set())
  const [filter, setFilter] = React.useState<'all' | 'unread' | 'priority'>('all')
  const [expanded, setExpanded] = React.useState<string | null>(null)
  const [loading, setLoading] = React.useState(true)
  const [error, setError] = React.useState('')

  const load = React.useCallback(async () => {
    setLoading(true); setError('')
    try {
      const me = await getCurrentProfile(supabase)
      if (!me?.id) throw new Error('Sign in again to load announcements.')
      setUserId(me.id)
      const [{ data, error: rowError }, { data: reads, error: readError }] = await Promise.all([
        db.from('announcements').select('id,title,message,is_priority,expiry_date,created_at').or(`expiry_date.is.null,expiry_date.gt.${new Date().toISOString()}`).order('is_priority', { ascending: false }).order('created_at', { ascending: false }),
        db.from('announcement_reads').select('announcement_id').eq('user_id', me.id),
      ])
      if (rowError || readError) throw rowError || readError
      setRows((data ?? []) as Announcement[])
      setReadIds(new Set((reads ?? []).map((item: { announcement_id: string }) => item.announcement_id)))
    } catch (cause) { setError(cause instanceof Error ? cause.message : 'Announcements could not be loaded.') }
    finally { setLoading(false) }
  }, [db, supabase])
  React.useEffect(() => { void load() }, [load])

  async function remember(ids: string[]) {
    if (!userId || !ids.length) return
    const unreadIds = ids.filter((id) => !readIds.has(id))
    if (!unreadIds.length) return
    const { error: saveError } = await db.from('announcement_reads').upsert(unreadIds.map((announcement_id) => ({ announcement_id, user_id: userId })), { onConflict: 'announcement_id,user_id' })
    if (saveError) return setError(saveError.message)
    setReadIds((current) => new Set([...current, ...unreadIds]))
  }

  const filtered = rows.filter((row) => filter === 'unread' ? !readIds.has(row.id) : filter === 'priority' ? row.is_priority : true)
  const unread = rows.filter((row) => !readIds.has(row.id)).length
  if (loading) return <div className="grid min-h-64 place-items-center"><Loader2 className="h-6 w-6 animate-spin text-primary-purple" /></div>

  return <div className="mx-auto max-w-4xl space-y-7 pb-10">
    <header className="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between"><div><h1 className="flex items-center gap-2 text-2xl font-black"><Megaphone className="h-6 w-6 text-primary-purple" />Department announcements</h1><p className="mt-1 text-sm text-text-muted">{unread ? `${unread} unread update${unread === 1 ? '' : 's'}` : 'You are caught up.'}</p></div>{unread > 0 && <button onClick={() => void remember(rows.map((row) => row.id))} className="text-xs font-black text-primary-purple">Mark all as read</button>}</header>
    {error && <div className="rounded-xl bg-red-50 p-4 text-sm font-bold text-red-700">{error} <button onClick={() => void load()} className="underline">Retry</button></div>}
    <div className="flex gap-2">{(['all','unread','priority'] as const).map((value) => <button key={value} onClick={() => setFilter(value)} className={`rounded-xl px-4 py-2 text-xs font-bold capitalize ${filter === value ? 'bg-primary-purple text-white' : 'border border-border-light bg-white text-text-muted'}`}>{value}</button>)}</div>
    <div className="space-y-3">{filtered.map((row) => { const read = readIds.has(row.id); const open = expanded === row.id; return <button key={row.id} onClick={() => { setExpanded(open ? null : row.id); void remember([row.id]) }} className={`w-full rounded-2xl border bg-white p-5 text-left ${read ? 'border-border-light' : 'border-primary-purple/40 shadow-sm'}`}><div className="flex items-start gap-4"><div className={`grid h-10 w-10 place-items-center rounded-xl ${row.is_priority ? 'bg-amber-50 text-amber-700' : 'bg-violet-50 text-primary-purple'}`}>{row.is_priority ? <AlertTriangle className="h-5 w-5" /> : <Bell className="h-5 w-5" />}</div><div className="min-w-0 flex-1"><div className="flex items-center gap-2">{row.is_priority && <span className="rounded-full bg-amber-100 px-2 py-0.5 text-[10px] font-black text-amber-800">Priority</span>}{read && <span className="inline-flex items-center gap-1 text-[10px] font-bold text-emerald-700"><CheckCircle2 className="h-3 w-3" />Read</span>}</div><h2 className="mt-2 font-black">{row.title}</h2><p className="mt-1 text-xs text-text-muted">{new Intl.DateTimeFormat('en-IN', { dateStyle: 'medium', timeStyle: 'short' }).format(new Date(row.created_at))}</p><p className={`mt-3 text-sm leading-6 text-text-muted ${open ? 'whitespace-pre-wrap' : 'line-clamp-2'}`}>{row.message}</p></div></div></button> })}{!filtered.length && <div className="rounded-3xl border border-dashed border-border-light bg-white p-10 text-center text-sm text-text-muted">No announcements in this view.</div>}</div>
  </div>
}
