'use client'

import React from 'react'
import { AlertTriangle, Bell, CheckCircle2, Loader2, Megaphone, Sparkles } from 'lucide-react'
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

const DEFAULT_ANNOUNCEMENTS: Announcement[] = [
  {
    id: 'ann-zoho-bootcamp',
    title: 'Zoho Corporation On-Campus Recruitment Drive',
    message: 'Zoho Corporation placement process is scheduled for the MCA cohort. All eligible candidates must complete basic matrix manipulation and OOP CLI practice. Check the Interview Patterns tab for round-by-round tips.',
    is_priority: true,
    expiry_date: null,
    created_at: new Date(Date.now() - 3600000).toISOString(),
  },
  {
    id: 'ann-tcs-digital',
    title: 'TCS Digital / Prime Mock Assessment Live',
    message: 'The proctored TCS Digital speed assessment is now open in Mock Assessments. Test your problem-solving accuracy and time complexity instincts.',
    is_priority: true,
    expiry_date: null,
    created_at: new Date(Date.now() - 14400000).toISOString(),
  },
  {
    id: 'ann-daily-five-streak',
    title: 'Daily Five Gymnasium Streak Challenge',
    message: 'Complete today’s 5 curated placement questions in the Train Gymnasium. Maintaining a continuous streak is the fastest way to boost your Readiness Score.',
    is_priority: false,
    expiry_date: null,
    created_at: new Date(Date.now() - 86400000).toISOString(),
  },
  {
    id: 'ann-fyp-checkpoints',
    title: 'Final Year Project (FYP) Technical Milestones',
    message: 'Please link your GitHub repository and log your weekly project milestones in the FYP Portfolio section for faculty guide review.',
    is_priority: false,
    expiry_date: null,
    created_at: new Date(Date.now() - 172800000).toISOString(),
  },
]

const readStorageKey = 'psgmx:read-announcements'

export default function AnnouncementsPage() {
  const supabase = React.useMemo(() => createClient(), [])
  const [rows, setRows] = React.useState<Announcement[]>([])
  const [readIds, setReadIds] = React.useState<Set<string>>(new Set())
  const [filter, setFilter] = React.useState<'all' | 'unread' | 'priority'>('all')
  const [expanded, setExpanded] = React.useState<string | null>(null)
  const [loading, setLoading] = React.useState(true)

  const load = React.useCallback(async () => {
    setLoading(true)
    try {
      const me = await getCurrentProfile(supabase)
      let list: Announcement[] = []

      try {
        let query = supabase
          .from('announcements')
          .select('id,title,message,is_priority,expiry_date,created_at')
          .order('is_priority', { ascending: false })
          .order('created_at', { ascending: false })

        if (me?.batch_id) {
          query = query.or(`batch_id.eq.${me.batch_id},batch_id.is.null`)
        }

        const { data } = await query
        if (data && data.length > 0) {
          list = data as Announcement[]
        }
      } catch (dbErr) {
        console.warn('Announcements DB query fallback:', dbErr)
      }

      setRows(list.length > 0 ? list : DEFAULT_ANNOUNCEMENTS)
      const stored = JSON.parse(localStorage.getItem(readStorageKey) ?? '[]')
      setReadIds(new Set(Array.isArray(stored) ? stored : []))
    } catch (err) {
      console.warn('Announcements load error:', err)
      setRows(DEFAULT_ANNOUNCEMENTS)
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

  return (
    <div className="mx-auto max-w-4xl space-y-7 pb-10 font-sans">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
        <div>
          <h1 className="flex items-center gap-2 text-2xl font-black text-text-main">
            <Megaphone className="h-6 w-6 text-primary-purple"/>
            Department Announcements & Notices
          </h1>
          <p className="mt-1 text-sm text-text-muted">
            {unread ? `${unread} unread update${unread === 1 ? '' : 's'}` : 'You are caught up with all batch broadcasts.'}
          </p>
        </div>
        {rows.length > 0 && (
          <button 
            onClick={() => remember(new Set(rows.map((row) => row.id)))} 
            className="text-xs font-black text-primary-purple hover:underline"
          >
            Mark all as read
          </button>
        )}
      </div>

      <div className="flex flex-wrap gap-2">
        {(['all', 'unread', 'priority'] as const).map((value) => (
          <button 
            key={value} 
            onClick={() => setFilter(value)} 
            className={`rounded-xl px-4 py-2 text-xs font-bold capitalize transition-all ${
              filter === value 
                ? 'bg-primary-purple text-white shadow-sm' 
                : 'border border-border-light bg-white text-text-muted hover:text-text-main'
            }`}
          >
            {value}
          </button>
        ))}
      </div>

      <div className="space-y-3">
        {filtered.map((row) => {
          const isRead = readIds.has(row.id)
          const isOpen = expanded === row.id
          return (
            <button 
              key={row.id} 
              onClick={() => open(row.id)} 
              className={`w-full rounded-2xl border bg-white p-5 text-left transition-all duration-200 ${
                isRead ? 'border-border-light hover:border-border-light/80' : 'border-primary-purple/40 shadow-sm bg-violet-50/20'
              }`}
            >
              <div className="flex items-start gap-4">
                <div className={`flex h-10 w-10 shrink-0 items-center justify-center rounded-xl ${
                  row.is_priority ? 'bg-amber-50 text-amber-700 border border-amber-200' : 'bg-violet-50 text-primary-purple border border-violet-100'
                }`}>
                  {row.is_priority ? <AlertTriangle className="h-5 w-5"/> : <Bell className="h-5 w-5"/>}
                </div>
                <div className="min-w-0 flex-1">
                  <div className="flex flex-wrap items-center gap-2">
                    {row.is_priority && (
                      <span className="rounded-full bg-amber-100 text-amber-800 px-2.5 py-0.5 text-[10px] font-black uppercase tracking-wide">
                        Priority Broadcast
                      </span>
                    )}
                    {isRead ? (
                      <span className="flex items-center gap-1 text-[10px] font-bold text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded-full">
                        <CheckCircle2 className="h-3 w-3"/> Read
                      </span>
                    ) : (
                      <span className="h-2 w-2 rounded-full bg-primary-purple animate-pulse" />
                    )}
                  </div>
                  <h2 className="mt-1.5 font-black text-text-main text-base">{row.title}</h2>
                  <p className="mt-1 text-xs text-text-muted">
                    {new Intl.DateTimeFormat('en-IN', { dateStyle: 'medium', timeStyle: 'short' }).format(new Date(row.created_at))}
                  </p>
                  {isOpen ? (
                    <p className="mt-4 whitespace-pre-wrap text-sm leading-relaxed text-text-main bg-page-bg p-4 rounded-xl border border-border-light">
                      {row.message}
                    </p>
                  ) : (
                    <p className="mt-2 text-xs text-text-muted line-clamp-1">
                      {row.message}
                    </p>
                  )}
                </div>
              </div>
            </button>
          )
        })}
      </div>
    </div>
  )
}
