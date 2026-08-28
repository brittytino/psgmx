'use client'

import React from 'react'
import { AlertTriangle, Bell, CheckCircle2, Loader2, Megaphone } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { getCurrentProfile } from '@/lib/current-profile'

type Announcement = {
  id: string
  title: string
  message: string
  is_priority: boolean
  expiry_date: string | null
  created_at: string
}

const readStorageKey = 'psgmx:read-announcements'

export default function AnnouncementsPage() {
  const supabase = React.useMemo(() => createClient(), [])
  const [rows, setRows] = React.useState<Announcement[]>([])
  const [readIds, setReadIds] = React.useState<Set<string>>(new Set())
  const [filter, setFilter] = React.useState<'all' | 'unread' | 'priority'>('all')
  const [expanded, setExpanded] = React.useState<string | null>(null)
  const [loading, setLoading] = React.useState(true)
  const [error, setError] = React.useState('')

  const load = React.useCallback(async () => {
    setLoading(true)
    setError('')
    try {
      const me = await getCurrentProfile(supabase)
      if (!me?.batch_id) throw new Error('Your batch is not assigned yet.')
      const { data, error: queryError } = await supabase
        .from('announcements')
        .select('id,title,message,is_priority,expiry_date,created_at')
        .eq('batch_id', me.batch_id)
        .or(`expiry_date.is.null,expiry_date.gte.${new Date().toISOString()}`)
        .order('is_priority', { ascending: false })
        .order('created_at', { ascending: false })
      if (queryError) throw queryError
      setRows(data ?? [])
      const stored = JSON.parse(localStorage.getItem(readStorageKey) ?? '[]')
      setReadIds(new Set(Array.isArray(stored) ? stored : []))
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : 'Announcements could not be loaded.')
    } finally {
      setLoading(false)
    }
  }, [supabase])

  React.useEffect(() => { void load() }, [load])

  function remember(next: Set<string>) {
    setReadIds(next)
    localStorage.setItem(readStorageKey, JSON.stringify([...next]))
  }

  function open(id: string) {
    remember(new Set([...readIds, id]))
    setExpanded((current) => current === id ? null : id)
  }

  const filtered = rows.filter((row) =>
    filter === 'unread' ? !readIds.has(row.id) : filter === 'priority' ? row.is_priority : true)
  const unread = rows.filter((row) => !readIds.has(row.id)).length

  if (loading) return <div className="flex min-h-64 items-center justify-center"><Loader2 className="h-6 w-6 animate-spin text-primary-purple" /></div>

  return <div className="mx-auto max-w-4xl space-y-7 pb-10">
    <div className="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
      <div><h1 className="flex items-center gap-2 text-2xl font-black"><Megaphone className="h-6 w-6 text-primary-purple"/>Announcements</h1><p className="mt-1 text-sm text-text-muted">{unread ? `${unread} unread update${unread === 1 ? '' : 's'}` : 'You are caught up.'}</p></div>
      {rows.length > 0 && <button onClick={() => remember(new Set(rows.map((row) => row.id)))} className="text-sm font-bold text-primary-purple">Mark all read</button>}
    </div>

    <div className="flex flex-wrap gap-2">{(['all', 'unread', 'priority'] as const).map((value) => <button key={value} onClick={() => setFilter(value)} className={`rounded-full px-4 py-2 text-xs font-bold capitalize ${filter === value ? 'bg-primary-purple text-white' : 'border border-border-light bg-white text-text-muted'}`}>{value}</button>)}</div>

    {error && <div className="rounded-2xl border border-amber-200 bg-amber-50 p-5"><p className="font-bold text-amber-900">{error}</p><button onClick={load} className="mt-2 text-sm font-bold text-primary-purple">Try again</button></div>}

    {!error && filtered.length === 0 && <div className="rounded-3xl border border-dashed border-border-light bg-white px-6 py-16 text-center"><Bell className="mx-auto h-10 w-10 text-text-muted"/><h2 className="mt-4 font-black">{rows.length === 0 ? 'No announcements yet' : 'Nothing in this view'}</h2><p className="mx-auto mt-2 max-w-md text-sm text-text-muted">{rows.length === 0 ? 'Your Placement Rep and faculty updates will appear here as soon as they are published.' : 'You have already read everything in this filter.'}</p></div>}

    <div className="space-y-3">{filtered.map((row) => {
      const isRead = readIds.has(row.id)
      const isOpen = expanded === row.id
      return <button key={row.id} onClick={() => open(row.id)} className={`w-full rounded-2xl border bg-white p-5 text-left transition ${isRead ? 'border-border-light' : 'border-primary-purple/30 shadow-sm'}`}>
        <div className="flex items-start gap-4">
          <div className={`flex h-10 w-10 shrink-0 items-center justify-center rounded-xl ${row.is_priority ? 'bg-amber-50 text-amber-700' : 'bg-violet-50 text-primary-purple'}`}>{row.is_priority ? <AlertTriangle className="h-5 w-5"/> : <Bell className="h-5 w-5"/>}</div>
          <div className="min-w-0 flex-1"><div className="flex flex-wrap items-center gap-2">{row.is_priority && <span className="rounded-full bg-amber-50 px-2 py-1 text-[10px] font-black uppercase text-amber-700">Priority</span>}{isRead && <span className="flex items-center gap-1 text-[10px] font-bold text-emerald-700"><CheckCircle2 className="h-3 w-3"/>Read</span>}</div><h2 className="mt-1 font-black text-text-main">{row.title}</h2><p className="mt-1 text-xs text-text-muted">{new Intl.DateTimeFormat('en-IN', { dateStyle: 'medium', timeStyle: 'short' }).format(new Date(row.created_at))}</p>{isOpen && <p className="mt-4 whitespace-pre-wrap text-sm leading-6 text-text-main">{row.message}</p>}</div>
        </div>
      </button>
    })}</div>
  </div>
}
