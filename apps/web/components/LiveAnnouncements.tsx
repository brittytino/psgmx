'use client'

import React from 'react'
import { AlertTriangle, Bell, Loader2, Megaphone } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { getCurrentProfile } from '@/lib/current-profile'

type Row = {
  id: string
  title: string
  message: string
  is_priority: boolean
  created_at: string
  batch_id: string | null
}

export function LiveAnnouncements({ audience = 'my-batch' }: { audience?: 'my-batch' | 'all-visible' }) {
  const supabase = React.useMemo(() => createClient(), [])
  const [rows, setRows] = React.useState<Row[]>([])
  const [batchNames, setBatchNames] = React.useState<Map<string, string>>(new Map())
  const [loading, setLoading] = React.useState(true)
  const [error, setError] = React.useState('')
  const [expanded, setExpanded] = React.useState<string | null>(null)

  const load = React.useCallback(async () => {
    setLoading(true)
    setError('')
    try {
      let query = supabase
        .from('announcements')
        .select('id,title,message,is_priority,created_at,batch_id')
        .or(`expiry_date.is.null,expiry_date.gte.${new Date().toISOString()}`)
        .order('is_priority', { ascending: false })
        .order('created_at', { ascending: false })
        .limit(100)
      if (audience === 'my-batch') {
        const me = await getCurrentProfile(supabase)
        if (!me?.batch_id) throw new Error('No batch is linked to this profile yet.')
        query = query.eq('batch_id', me.batch_id)
      }
      const { data, error: queryError } = await query
      if (queryError) throw queryError
      const announcements = (data ?? []) as Row[]
      setRows(announcements)
      const ids = [...new Set(announcements.map((row) => row.batch_id).filter((id): id is string => Boolean(id)))]
      if (ids.length) {
        const { data: batches } = await supabase.from('batches').select('id,batch_code').in('id', ids)
        setBatchNames(new Map((batches ?? []).map((batch) => [batch.id, batch.batch_code])))
      }
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : 'Updates could not be loaded.')
    } finally {
      setLoading(false)
    }
  }, [audience, supabase])

  React.useEffect(() => { void load() }, [load])

  if (loading) return <div className="flex min-h-56 items-center justify-center"><Loader2 className="h-6 w-6 animate-spin text-primary-purple"/></div>

  return <div className="space-y-3">
    {error && <div className="rounded-2xl border border-amber-200 bg-amber-50 p-5 text-sm"><strong>{error}</strong><button onClick={load} className="ml-2 font-black text-primary-purple">Retry</button></div>}
    {!error && rows.length === 0 && <div className="rounded-3xl border border-dashed border-border-light bg-white p-14 text-center"><Megaphone className="mx-auto h-10 w-10 text-text-muted"/><h2 className="mt-4 font-black">No updates published yet</h2><p className="mt-2 text-sm text-text-muted">New department and placement notices will appear here.</p></div>}
    {rows.map((row) => {
      const batchCode = row.batch_id ? batchNames.get(row.batch_id) : null
      return <button key={row.id} onClick={() => setExpanded((value) => value === row.id ? null : row.id)} className="w-full rounded-2xl border border-border-light bg-white p-5 text-left transition hover:border-primary-purple/40">
        <div className="flex gap-4">
          <div className={`flex h-10 w-10 shrink-0 items-center justify-center rounded-xl ${row.is_priority ? 'bg-amber-50 text-amber-700' : 'bg-violet-50 text-primary-purple'}`}>{row.is_priority ? <AlertTriangle className="h-5 w-5"/> : <Bell className="h-5 w-5"/>}</div>
          <div className="min-w-0 flex-1">
            <div className="flex flex-wrap gap-2">{row.is_priority && <span className="rounded-full bg-amber-50 px-2 py-1 text-[10px] font-black uppercase text-amber-700">Priority</span>}{batchCode && <span className="rounded-full bg-page-bg px-2 py-1 text-[10px] font-black text-text-muted">{batchCode}</span>}</div>
            <h2 className="mt-1 font-black">{row.title}</h2>
            <p className="mt-1 text-xs text-text-muted">{new Intl.DateTimeFormat('en-IN', { dateStyle: 'medium', timeStyle: 'short' }).format(new Date(row.created_at))}</p>
            {expanded === row.id && <p className="mt-4 whitespace-pre-wrap text-sm leading-6">{row.message}</p>}
          </div>
        </div>
      </button>
    })}
  </div>
}
