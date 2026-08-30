'use client'

import React from 'react'
import { Bell, CheckCheck, Inbox, Loader2, Megaphone, Zap } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { getCurrentProfile } from '@/lib/current-profile'

type Item = { id: string; title: string; message: string; notification_type: string; generated_at: string; read: boolean }

export default function StudentInboxPage() {
  const supabase = React.useMemo(() => createClient(), [])
  const [userId, setUserId] = React.useState('')
  const [items, setItems] = React.useState<Item[]>([])
  const [filter, setFilter] = React.useState<'all' | 'unread'>('all')
  const [loading, setLoading] = React.useState(true)
  const [error, setError] = React.useState('')

  const load = React.useCallback(async () => {
    setLoading(true); setError('')
    try {
      const me = await getCurrentProfile(supabase)
      if (!me?.id) throw new Error('Sign in again to load your inbox.')
      setUserId(me.id)
      const [{ data: notifications, error: notificationError }, { data: reads, error: readError }] = await Promise.all([
        supabase.from('notifications').select('id,title,message,notification_type,generated_at').eq('is_active', true).or(`valid_until.is.null,valid_until.gt.${new Date().toISOString()}`).order('generated_at', { ascending: false }).limit(100),
        supabase.from('notification_reads').select('notification_id').eq('user_id', me.id),
      ])
      if (notificationError || readError) throw notificationError || readError
      const readSet = new Set((reads ?? []).map((row) => row.notification_id))
      setItems((notifications ?? []).map((row) => ({ ...row, read: readSet.has(row.id) })) as Item[])
    } catch (cause) { setError(cause instanceof Error ? cause.message : 'Inbox could not be loaded.') }
    finally { setLoading(false) }
  }, [supabase])
  React.useEffect(() => { void load() }, [load])

  async function markRead(ids: string[]) {
    if (!userId) return
    const unread = ids.filter((id) => !items.find((item) => item.id === id)?.read)
    if (!unread.length) return
    const { error: saveError } = await supabase.from('notification_reads').upsert(unread.map((notification_id) => ({ notification_id, user_id: userId })), { onConflict: 'notification_id,user_id' })
    if (saveError) return setError(saveError.message)
    setItems((current) => current.map((item) => unread.includes(item.id) ? { ...item, read: true } : item))
  }

  if (loading) return <div className="grid min-h-64 place-items-center"><Loader2 className="h-6 w-6 animate-spin text-primary-purple" /></div>
  const unreadCount = items.filter((item) => !item.read).length
  const visible = filter === 'unread' ? items.filter((item) => !item.read) : items
  return <div className="mx-auto max-w-4xl space-y-7 pb-12">
    <header className="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between"><div><h1 className="flex items-center gap-2 text-2xl font-black"><Inbox className="h-6 w-6 text-primary-purple" />Your inbox</h1><p className="mt-1 text-sm text-text-muted">Personal reminders, preparation updates, and department messages.</p></div>{unreadCount > 0 && <button onClick={() => void markRead(items.map((item) => item.id))} className="inline-flex items-center gap-1 text-xs font-black text-primary-purple"><CheckCheck className="h-4 w-4" />Mark all read</button>}</header>
    {error && <div className="rounded-xl bg-red-50 p-4 text-sm font-bold text-red-700">{error} <button onClick={() => void load()} className="underline">Retry</button></div>}
    <div className="flex gap-2">{(['all','unread'] as const).map((value) => <button key={value} onClick={() => setFilter(value)} className={`rounded-xl px-4 py-2 text-xs font-bold capitalize ${filter === value ? 'bg-primary-purple text-white' : 'border border-border-light bg-white'}`}>{value} ({value === 'all' ? items.length : unreadCount})</button>)}</div>
    <div className="space-y-3">{visible.map((item) => <button key={item.id} onClick={() => void markRead([item.id])} className={`w-full rounded-2xl border p-5 text-left ${item.read ? 'border-border-light bg-white' : 'border-primary-purple/40 bg-violet-50/20 shadow-sm'}`}><div className="flex gap-4"><div className="grid h-10 w-10 shrink-0 place-items-center rounded-xl bg-violet-50 text-primary-purple">{item.notification_type === 'announcement' ? <Megaphone className="h-5 w-5" /> : item.notification_type === 'reminder' ? <Zap className="h-5 w-5" /> : <Bell className="h-5 w-5" />}</div><div className="min-w-0 flex-1"><div className="flex flex-wrap items-start justify-between gap-2"><h2 className="font-black">{item.title}</h2><span className="text-xs text-text-muted">{new Intl.DateTimeFormat('en-IN', { dateStyle: 'short', timeStyle: 'short' }).format(new Date(item.generated_at))}</span></div><p className="mt-2 text-sm leading-6 text-text-muted">{item.message}</p></div></div></button>)}{!visible.length && <div className="rounded-3xl border border-dashed border-border-light bg-white p-10 text-center text-sm text-text-muted">No notifications in this view.</div>}</div>
  </div>
}
