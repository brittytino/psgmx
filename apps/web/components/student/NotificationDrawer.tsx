'use client'

import React, { useState, useEffect, useCallback } from 'react'
import Link from 'next/link'
import { motion, AnimatePresence } from 'framer-motion'
import { 
  Bell, 
  X, 
  CheckCheck, 
  Megaphone, 
  Zap, 
  ClipboardList, 
  Users, 
  ArrowRight, 
  Clock,
  ShieldCheck,
  Loader2,
} from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { getCurrentProfile } from '@/lib/current-profile'

export type NotificationItem = {
  id: string
  type: 'announcement' | 'quest' | 'exam' | 'lineage'
  title: string
  description: string
  timeAgo: string
  unread: boolean
  link: string
  actionLabel: string
}

type NotificationRow = {
  id: string
  title: string
  message: string
  notification_type: string
  category: string | null
  generated_at: string
  action_path: string | null
}

function relativeTime(value: string) {
  const elapsed = Math.max(0, Date.now() - new Date(value).getTime())
  const minutes = Math.floor(elapsed / 60_000)
  if (minutes < 1) return 'Now'
  if (minutes < 60) return `${minutes}m ago`
  const hours = Math.floor(minutes / 60)
  if (hours < 24) return `${hours}h ago`
  const days = Math.floor(hours / 24)
  return days === 1 ? 'Yesterday' : `${days}d ago`
}

function displayType(row: NotificationRow): NotificationItem['type'] {
  if (row.category === 'community') return 'lineage'
  if (row.notification_type === 'reminder' || row.category === 'scheduled_reminder') return 'quest'
  if (row.category === 'action_required') return 'exam'
  return 'announcement'
}

interface NotificationDrawerProps {
  isOpen: boolean
  onClose: () => void
  onUnreadCountChange?: (count: number) => void
}

export function NotificationDrawer({ isOpen, onClose, onUnreadCountChange }: NotificationDrawerProps) {
  const supabase = React.useMemo(() => createClient(), [])
  const [userId, setUserId] = useState('')
  const [notifications, setNotifications] = useState<NotificationItem[]>([])
  const [activeTab, setActiveTab] = useState<'all' | 'announcement' | 'quest' | 'exam'>('all')
  const [loading, setLoading] = useState(true)
  const [loadError, setLoadError] = useState('')

  const loadNotifications = useCallback(async () => {
    setLoading(true)
    setLoadError('')
    try {
      const me = await getCurrentProfile(supabase)
      if (!me?.id) throw new Error('Sign in again to load notifications.')
      setUserId(me.id)
      const [{ data: rows, error: rowsError }, { data: reads, error: readsError }] = await Promise.all([
        supabase
          .from('notifications')
          .select('id,title,message,notification_type,category,generated_at,action_path')
          .eq('is_active', true)
          .or(`valid_until.is.null,valid_until.gt.${new Date().toISOString()}`)
          .order('generated_at', { ascending: false })
          .limit(50),
        supabase.from('notification_reads').select('notification_id').eq('user_id', me.id),
      ])
      if (rowsError || readsError) throw rowsError || readsError
      const readIds = new Set((reads ?? []).map((read) => read.notification_id))
      setNotifications(((rows ?? []) as NotificationRow[]).map((row) => ({
        id: row.id,
        type: displayType(row),
        title: row.title,
        description: row.message,
        timeAgo: relativeTime(row.generated_at),
        unread: !readIds.has(row.id),
        link: row.action_path || '/student/inbox',
        actionLabel: row.action_path ? 'Open update' : 'View in inbox',
      })))
    } catch (cause) {
      setLoadError(cause instanceof Error ? cause.message : 'Notifications could not be loaded.')
    } finally {
      setLoading(false)
    }
  }, [supabase])

  useEffect(() => { void loadNotifications() }, [loadNotifications])

  // Close on Escape key
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose()
    }
    if (isOpen) {
      window.addEventListener('keydown', handleKeyDown)
    }
    return () => window.removeEventListener('keydown', handleKeyDown)
  }, [isOpen, onClose])

  const unreadCount = notifications.filter(n => n.unread).length

  useEffect(() => { onUnreadCountChange?.(unreadCount) }, [onUnreadCountChange, unreadCount])

  const markAllAsRead = async () => {
    const unread = notifications.filter((item) => item.unread).map((item) => item.id)
    if (!userId || unread.length === 0) return
    const { error } = await supabase.from('notification_reads').upsert(
      unread.map((notification_id) => ({ notification_id, user_id: userId })),
      { onConflict: 'notification_id,user_id' },
    )
    if (error) return setLoadError(error.message)
    setNotifications(prev => prev.map(n => ({ ...n, unread: false })))
  }

  const markAsRead = async (id: string) => {
    if (!userId || !notifications.find((item) => item.id === id)?.unread) return
    const { error } = await supabase.from('notification_reads').upsert(
      { notification_id: id, user_id: userId },
      { onConflict: 'notification_id,user_id' },
    )
    if (error) return setLoadError(error.message)
    setNotifications(prev => prev.map(n => n.id === id ? ({ ...n, unread: false }) : n))
  }

  const filtered = notifications.filter(n => {
    if (activeTab === 'all') return true
    return n.type === activeTab
  })

  const getIcon = (type: NotificationItem['type']) => {
    switch (type) {
      case 'announcement':
        return <Megaphone className="w-4 h-4 text-primary-purple" />
      case 'quest':
        return <Zap className="w-4 h-4 text-amber-500" />
      case 'exam':
        return <ClipboardList className="w-4 h-4 text-emerald-600" />
      case 'lineage':
        return <Users className="w-4 h-4 text-blue-600" />
    }
  }

  return (
    <AnimatePresence>
      {isOpen && (
        <div className="fixed inset-0 z-50 overflow-hidden font-sans">
          {/* Backdrop overlay */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
            className="absolute inset-0 bg-black/40 backdrop-blur-sm transition-opacity"
          />

          {/* Right Slide-Over Panel */}
          <div className="fixed inset-y-0 right-0 flex max-w-full pl-10">
            <motion.div
              initial={{ x: '100%' }}
              animate={{ x: 0 }}
              exit={{ x: '100%' }}
              transition={{ type: 'spring', damping: 28, stiffness: 260 }}
              className="w-screen max-w-md bg-white shadow-2xl flex flex-col border-l border-border-light"
            >
              {/* Drawer Header */}
              <div className="p-6 border-b border-border-light bg-page-bg/50 shrink-0">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-2xl bg-violet-100 flex items-center justify-center text-primary-purple">
                      <Bell className="w-5 h-5" />
                    </div>
                    <div>
                      <h2 className="text-lg font-black text-text-main leading-tight">Notifications</h2>
                      <p className="text-xs font-semibold text-text-muted">
                        {unreadCount > 0 ? `${unreadCount} unread update${unreadCount === 1 ? '' : 's'}` : 'All caught up'}
                      </p>
                    </div>
                  </div>

                  <button
                    onClick={onClose}
                    className="w-8 h-8 flex items-center justify-center rounded-xl hover:bg-gray-200/70 text-text-muted hover:text-text-main transition-colors"
                  >
                    <X className="w-5 h-5" />
                  </button>
                </div>

                {/* Filter Tabs & Mark as read */}
                <div className="mt-5 flex items-center justify-between gap-2">
                  <div className="flex items-center gap-1 bg-white p-1 rounded-xl border border-border-light">
                    <button
                      onClick={() => setActiveTab('all')}
                      className={`px-3 py-1 text-xs font-bold rounded-lg transition-all ${
                        activeTab === 'all'
                          ? 'bg-primary-purple text-white shadow-sm'
                          : 'text-text-muted hover:text-text-main'
                      }`}
                    >
                      All
                    </button>
                    <button
                      onClick={() => setActiveTab('announcement')}
                      className={`px-3 py-1 text-xs font-bold rounded-lg transition-all ${
                        activeTab === 'announcement'
                          ? 'bg-primary-purple text-white shadow-sm'
                          : 'text-text-muted hover:text-text-main'
                      }`}
                    >
                      Notices
                    </button>
                    <button
                      onClick={() => setActiveTab('quest')}
                      className={`px-3 py-1 text-xs font-bold rounded-lg transition-all ${
                        activeTab === 'quest'
                          ? 'bg-primary-purple text-white shadow-sm'
                          : 'text-text-muted hover:text-text-main'
                      }`}
                    >
                      Quests
                    </button>
                  </div>

                  {unreadCount > 0 && (
                    <button
                      onClick={() => void markAllAsRead()}
                      className="text-xs font-bold text-primary-purple hover:underline flex items-center gap-1"
                    >
                      <CheckCheck className="w-3.5 h-3.5" /> Mark read
                    </button>
                  )}
                </div>
              </div>

              {/* Drawer Content Body */}
              <div className="flex-1 overflow-y-auto p-6 space-y-3 custom-scrollbar">
                {loading ? (
                  <div className="grid min-h-48 place-items-center"><Loader2 className="h-6 w-6 animate-spin text-primary-purple" /></div>
                ) : loadError ? (
                  <div className="rounded-2xl bg-red-50 p-4 text-center text-xs font-bold text-red-700">
                    {loadError} <button onClick={() => void loadNotifications()} className="underline">Retry</button>
                  </div>
                ) : filtered.length === 0 ? (
                  <div className="text-center py-16 space-y-3">
                    <div className="w-14 h-14 rounded-full bg-page-bg flex items-center justify-center mx-auto text-text-muted">
                      <Bell className="w-6 h-6" />
                    </div>
                    <p className="font-bold text-text-main text-sm">No notifications found</p>
                    <p className="text-xs text-text-muted max-w-xs mx-auto">
                      All new department broadcasts, mock tests, and daily streaks will appear right here.
                    </p>
                  </div>
                ) : (
                  filtered.map((item) => (
                    <div
                      key={item.id}
                      onClick={() => void markAsRead(item.id)}
                      className={`group relative p-4 rounded-2xl border transition-all duration-200 ${
                        item.unread
                          ? 'bg-violet-50/40 border-primary-purple/30 shadow-sm'
                          : 'bg-white border-border-light hover:border-border-light/80 hover:bg-page-bg/40'
                      }`}
                    >
                      <div className="flex items-start gap-3.5">
                        <div className="w-8 h-8 rounded-xl bg-white border border-border-light flex items-center justify-center shrink-0 shadow-sm mt-0.5">
                          {getIcon(item.type)}
                        </div>

                        <div className="flex-1 min-w-0">
                          <div className="flex items-center justify-between gap-2">
                            <h3 className={`text-xs font-bold truncate ${item.unread ? 'text-primary-purple' : 'text-text-main'}`}>
                              {item.title}
                            </h3>
                            <span className="text-[10px] font-medium text-text-muted shrink-0 flex items-center gap-1">
                              <Clock className="w-2.5 h-2.5" />
                              {item.timeAgo}
                            </span>
                          </div>

                          <p className="mt-1 text-xs text-text-muted leading-relaxed line-clamp-2">
                            {item.description}
                          </p>

                          <div className="mt-3 flex items-center justify-between">
                            <Link
                              href={item.link}
                              onClick={onClose}
                              className="inline-flex items-center gap-1.5 text-xs font-bold text-primary-purple group-hover:translate-x-0.5 transition-transform"
                            >
                              {item.actionLabel}
                              <ArrowRight className="w-3 h-3" />
                            </Link>

                            {item.unread && (
                              <span className="w-2 h-2 rounded-full bg-primary-purple animate-pulse" />
                            )}
                          </div>
                        </div>
                      </div>
                    </div>
                  ))
                )}
              </div>

              {/* Drawer Footer Actions */}
              <div className="p-5 border-t border-border-light bg-page-bg/40 shrink-0 space-y-2">
                <Link
                  href="/student/announcements"
                  onClick={onClose}
                  className="w-full flex items-center justify-center gap-2 py-2.5 px-4 rounded-xl bg-white border border-border-light text-xs font-bold text-text-main hover:bg-page-bg transition-colors shadow-sm"
                >
                  <Megaphone className="w-3.5 h-3.5 text-primary-purple" />
                  View Full Department Announcements
                </Link>

                <div className="flex items-center justify-between px-2 pt-1 text-[11px] text-text-muted">
                  <span className="flex items-center gap-1">
                    <ShieldCheck className="w-3.5 h-3.5 text-emerald-600" /> Real-Time Live Feed
                  </span>
                  <Link
                    href="/student/settings"
                    onClick={onClose}
                    className="hover:underline font-semibold"
                  >
                    Manage Alerts
                  </Link>
                </div>
              </div>
            </motion.div>
          </div>
        </div>
      )}
    </AnimatePresence>
  )
}
