'use client'

import React, { useState, useEffect } from 'react'
import { Bell, CheckCircle2, Clock, Sparkles, Inbox, CheckCheck, Megaphone, Zap, ShieldCheck } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { getCurrentProfile } from '@/lib/current-profile'

interface NotificationItem {
  id: string
  title: string
  body: string
  category: 'announcement' | 'quest' | 'session' | 'system'
  created_at: string
  read: boolean
  priority: 'high' | 'normal'
}

const DEFAULT_INBOX_ITEMS: NotificationItem[] = [
  {
    id: 'inb-1',
    title: 'Zoho Corporation On-Campus Recruitment Drive',
    body: 'Zoho Corporation placement process is scheduled for the MCA cohort. All eligible candidates must complete basic matrix manipulation and OOP CLI practice.',
    category: 'announcement',
    created_at: '15m ago',
    read: false,
    priority: 'high',
  },
  {
    id: 'inb-2',
    title: 'Daily Five Gymnasium Streak Active',
    body: 'Solve today’s 5 curated placement questions in the Train Gymnasium to boost your readiness index and maintain your streak.',
    category: 'quest',
    created_at: '2 hours ago',
    read: false,
    priority: 'high',
  },
  {
    id: 'inb-3',
    title: 'TCS Digital / Prime Mock Assessment Open',
    body: 'Proctored speed assessment is ready. Test your problem-solving accuracy and time complexity instincts.',
    category: 'session',
    created_at: '5 hours ago',
    read: false,
    priority: 'high',
  },
  {
    id: 'inb-4',
    title: 'Weekly Readiness Movement Digest',
    body: 'You completed 4 quests this week with 100% Daily Five consistency. Your overall readiness score is tracking at 78.',
    category: 'system',
    created_at: 'Yesterday',
    read: true,
    priority: 'normal',
  },
]

export default function StudentInboxPage() {
  const supabase = React.useMemo(() => createClient(), [])
  const [filter, setFilter] = useState<'all' | 'unread'>('all')
  const [notifications, setNotifications] = useState<NotificationItem[]>(DEFAULT_INBOX_ITEMS)

  useEffect(() => {
    async function loadInbox() {
      try {
        const me = await getCurrentProfile(supabase)
        let query = supabase
          .from('announcements')
          .select('id, title, message, is_priority, created_at')
          .order('created_at', { ascending: false })
          .limit(10)

        if (me?.batch_id) {
          query = query.or(`batch_id.eq.${me.batch_id},batch_id.is.null`)
        }

        const { data } = await query
        if (data && data.length > 0) {
          const mapped: NotificationItem[] = data.map((row: any) => ({
            id: row.id,
            title: row.title,
            body: row.message,
            category: 'announcement',
            created_at: new Intl.DateTimeFormat('en-IN', { dateStyle: 'short', timeStyle: 'short' }).format(new Date(row.created_at)),
            read: false,
            priority: row.is_priority ? 'high' : 'normal',
          }))
          setNotifications(mapped)
        }
      } catch (err) {
        console.warn('Inbox DB query fallback:', err)
      }
    }
    loadInbox()
  }, [supabase])

  const markAllAsRead = () => {
    setNotifications((prev) => prev.map((n) => ({ ...n, read: true })))
  }

  const markAsRead = (id: string) => {
    setNotifications((prev) => prev.map((n) => (n.id === id ? { ...n, read: true } : n)))
  }

  const filtered = filter === 'unread' ? notifications.filter((n) => !n.read) : notifications
  const unreadCount = notifications.filter((n) => !n.read).length

  return (
    <div className="mx-auto max-w-4xl space-y-7 pb-12 font-sans">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="flex items-center gap-2.5 text-2xl font-black text-text-main">
            <Inbox className="h-6 w-6 text-primary-purple"/>
            Unified Notification Inbox
          </h1>
          <p className="mt-1 text-sm text-text-muted">
            All department broadcasts, quest reminders, and mock test updates in one unified feed.
          </p>
        </div>
        {unreadCount > 0 && (
          <button
            onClick={markAllAsRead}
            className="flex items-center gap-1.5 rounded-xl border border-border-light bg-white px-4 py-2 text-xs font-bold text-primary-purple hover:bg-page-bg transition-colors shadow-sm"
          >
            <CheckCheck className="h-4 w-4"/> Mark all as read
          </button>
        )}
      </div>

      {/* Filter Tabs */}
      <div className="flex gap-2">
        <button
          onClick={() => setFilter('all')}
          className={`rounded-xl px-4 py-2 text-xs font-bold transition-all ${
            filter === 'all'
              ? 'bg-primary-purple text-white shadow-sm'
              : 'border border-border-light bg-white text-text-muted hover:text-text-main'
          }`}
        >
          All ({notifications.length})
        </button>
        <button
          onClick={() => setFilter('unread')}
          className={`rounded-xl px-4 py-2 text-xs font-bold transition-all ${
            filter === 'unread'
              ? 'bg-primary-purple text-white shadow-sm'
              : 'border border-border-light bg-white text-text-muted hover:text-text-main'
          }`}
        >
          Unread ({unreadCount})
        </button>
      </div>

      {/* Notifications List */}
      <div className="space-y-3">
        {filtered.map((item) => (
          <div
            key={item.id}
            onClick={() => markAsRead(item.id)}
            className={`cursor-pointer rounded-2xl border p-5 transition-all duration-200 ${
              !item.read
                ? 'border-primary-purple/40 bg-violet-50/20 shadow-sm'
                : 'border-border-light bg-white hover:border-border-light/80'
            }`}
          >
            <div className="flex items-start gap-4">
              <div
                className={`flex h-10 w-10 shrink-0 items-center justify-center rounded-xl ${
                  item.priority === 'high'
                    ? 'bg-amber-50 text-amber-700 border border-amber-200'
                    : 'bg-violet-50 text-primary-purple border border-violet-100'
                }`}
              >
                {item.category === 'announcement' ? (
                  <Megaphone className="h-5 w-5"/>
                ) : item.category === 'quest' ? (
                  <Zap className="h-5 w-5"/>
                ) : (
                  <Bell className="h-5 w-5"/>
                )}
              </div>

              <div className="min-w-0 flex-1 space-y-1.5">
                <div className="flex items-center justify-between gap-2">
                  <h2 className="text-sm font-black text-text-main flex items-center gap-2">
                    {item.title}
                    {!item.read && <span className="h-2 w-2 rounded-full bg-primary-purple animate-pulse"/>}
                  </h2>
                  <span className="text-xs text-text-muted font-medium">{item.created_at}</span>
                </div>
                <p className="text-xs leading-relaxed text-text-muted">{item.body}</p>
              </div>
            </div>
          </div>
        ))}

        {filtered.length === 0 && (
          <div className="rounded-3xl border border-dashed border-border-light bg-white p-12 text-center text-sm text-text-muted">
            No notifications in this view.
          </div>
        )}
      </div>
    </div>
  )
}
