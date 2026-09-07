'use client'

import React, { useState, useEffect, useCallback, useMemo } from 'react'
import { AlertTriangle, Bell, Loader2, Megaphone, Search, ChevronDown } from 'lucide-react'
import { motion, AnimatePresence } from 'framer-motion'
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
  const supabase = useMemo(() => createClient(), [])
  const [rows, setRows] = useState<Row[]>([])
  const [batchNames, setBatchNames] = useState<Map<string, string>>(new Map())
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [expanded, setExpanded] = useState<string | null>(null)
  const [query, setQuery] = useState('')
  const [priorityOnly, setPriorityOnly] = useState(false)

  const load = useCallback(async () => {
    setLoading(true)
    setError('')
    try {
      let queryBuilder = supabase
        .from('announcements')
        .select('id,title,message,is_priority,created_at,batch_id')
        .or(`expiry_date.is.null,expiry_date.gte.${new Date().toISOString()}`)
        .order('is_priority', { ascending: false })
        .order('created_at', { ascending: false })
        .limit(100)

      if (audience === 'my-batch') {
        const me = await getCurrentProfile(supabase)
        if (me?.batch_id) {
          queryBuilder = queryBuilder.or(`batch_id.is.null,batch_id.eq.${me.batch_id}`)
        }
      }

      const { data, error: queryError } = await queryBuilder
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

  useEffect(() => {
    void load()
  }, [load])

  // Realtime subscription for live updates
  useEffect(() => {
    const channel = supabase
      .channel('announcements-live-sync')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'announcements' }, () => {
        void load()
      })
      .subscribe()

    return () => {
      void supabase.removeChannel(channel)
    }
  }, [supabase, load])

  const filtered = useMemo(() => {
    return rows.filter((row) => {
      const matchesText =
        row.title.toLowerCase().includes(query.toLowerCase()) ||
        row.message.toLowerCase().includes(query.toLowerCase())
      const matchesPriority = !priorityOnly || row.is_priority
      return matchesText && matchesPriority
    })
  }, [rows, query, priorityOnly])

  if (loading) {
    return (
      <div className="flex min-h-56 items-center justify-center">
        <Loader2 className="h-6 w-6 animate-spin text-primary-purple" />
      </div>
    )
  }

  return (
    <div className="space-y-4">
      {/* Controls: Search & Priority Filter */}
      <div className="flex flex-col sm:flex-row items-center gap-3">
        <div className="relative flex-1 w-full">
          <Search className="absolute left-3.5 top-3 h-4 w-4 text-text-muted" />
          <input
            type="text"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Search announcements..."
            className="w-full rounded-xl border border-border-light bg-white py-2.5 pl-10 pr-4 text-xs font-semibold outline-none focus:border-primary-purple shadow-sm"
          />
        </div>
        <div className="flex items-center gap-2 w-full sm:w-auto">
          <button
            type="button"
            onClick={() => setPriorityOnly(!priorityOnly)}
            className={`px-3.5 py-2.5 rounded-xl text-xs font-bold border transition-colors shadow-sm shrink-0 ${
              priorityOnly
                ? 'bg-amber-500 text-white border-amber-500'
                : 'bg-white text-text-muted border-border-light hover:text-text-main'
            }`}
          >
            {priorityOnly ? '★ Priority Only' : 'Show All'}
          </button>
        </div>
      </div>

      {error && (
        <div className="rounded-2xl border border-amber-200 bg-amber-50 p-5 text-sm">
          <strong>{error}</strong>
          <button onClick={load} className="ml-2 font-black text-primary-purple">
            Retry
          </button>
        </div>
      )}

      {!error && filtered.length === 0 && (
        <div className="rounded-3xl border border-dashed border-border-light bg-white p-14 text-center">
          <Megaphone className="mx-auto h-10 w-10 text-text-muted" />
          <h2 className="mt-4 font-black text-text-main text-base">No announcements found</h2>
          <p className="mt-1 text-xs text-text-muted">
            {query ? 'No notices matched your search query.' : 'New department and placement notices will appear here.'}
          </p>
        </div>
      )}

      <div className="space-y-3">
        {filtered.map((row) => {
          const batchCode = row.batch_id ? batchNames.get(row.batch_id) : null
          const isExp = expanded === row.id

          return (
            <div
              key={row.id}
              className={`rounded-2xl border bg-white shadow-sm transition-all duration-200 overflow-hidden ${
                row.is_priority
                  ? 'border-amber-200/80 bg-gradient-to-r from-amber-50/20 to-white'
                  : 'border-border-light hover:border-primary-purple/40'
              }`}
            >
              <button
                onClick={() => setExpanded(isExp ? null : row.id)}
                className="w-full p-5 text-left flex items-start justify-between gap-4"
              >
                <div className="flex gap-4 min-w-0">
                  <div
                    className={`flex h-10 w-10 shrink-0 items-center justify-center rounded-xl shadow-sm ${
                      row.is_priority
                        ? 'bg-amber-100 text-amber-800'
                        : 'bg-violet-50 text-primary-purple'
                    }`}
                  >
                    {row.is_priority ? <AlertTriangle className="h-5 w-5" /> : <Bell className="h-5 w-5" />}
                  </div>

                  <div className="min-w-0 flex-1">
                    <div className="flex flex-wrap items-center gap-2">
                      {row.is_priority && (
                        <span className="rounded-full bg-amber-100 px-2.5 py-0.5 text-[10px] font-black uppercase tracking-wider text-amber-800">
                          Priority Notice
                        </span>
                      )}
                      {batchCode && (
                        <span className="rounded-full bg-page-bg px-2.5 py-0.5 text-[10px] font-black text-text-muted">
                          {batchCode}
                        </span>
                      )}
                      {!batchCode && (
                        <span className="rounded-full bg-slate-100 px-2.5 py-0.5 text-[10px] font-bold text-slate-600">
                          Department-wide
                        </span>
                      )}
                    </div>

                    <h2 className="mt-1.5 font-bold text-sm text-text-main leading-snug">{row.title}</h2>
                    <p className="mt-1 text-[11px] font-medium text-text-muted">
                      {new Intl.DateTimeFormat('en-IN', {
                        dateStyle: 'medium',
                        timeStyle: 'short',
                      }).format(new Date(row.created_at))}
                    </p>
                  </div>
                </div>

                <div className="flex items-center gap-1 text-text-muted shrink-0 mt-1">
                  <span className="text-[11px] font-semibold hidden sm:inline">{isExp ? 'Collapse' : 'Expand'}</span>
                  <ChevronDown className={`h-4 w-4 transition-transform duration-200 ${isExp ? 'rotate-180' : ''}`} />
                </div>
              </button>

              <AnimatePresence>
                {isExp && (
                  <motion.div
                    initial={{ height: 0, opacity: 0 }}
                    animate={{ height: 'auto', opacity: 1 }}
                    exit={{ height: 0, opacity: 0 }}
                    transition={{ duration: 0.2 }}
                    className="overflow-hidden border-t border-border-light/60 bg-page-bg/40 px-6 py-4"
                  >
                    <p className="whitespace-pre-wrap text-sm leading-relaxed text-text-main">{row.message}</p>
                  </motion.div>
                )}
              </AnimatePresence>
            </div>
          )
        })}
      </div>
    </div>
  )
}
