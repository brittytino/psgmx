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

  // Realtime subscription for live student notifications
  useEffect(() => {
    if (!userId) return
    const channel = supabase
      .channel('student-notifications-realtime')
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'notifications' },
        () => {
          void loadNotifications()
        }
      )
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'notification_reads', filter: `user_id=eq.${userId}` },
        () => {
          void loadNotifications()
        }
      )
      .subscribe()

    return () => {
      void supabase.removeChannel(channel)
    }
  }, [supabase, userId, loadNotifications])

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
          <div className="fixed inset-y-0 right-0 flex max-w-full pl-6 sm:pl-10 z-50">
            <motion.div
              initial={{ x: '100%' }}
              animate={{ x: 0 }}
              exit={{ x: '100%' }}
              transition={{ type: 'spring', damping: 30, stiffness: 300 }}
              className="w-screen max-w-md h-full bg-white shadow-2xl flex flex-col border-l border-[#EFE9E0] overflow-hidden"
            >
              {/* Drawer Header */}
              <div className="p-5 border-b border-[#EFE9E0] bg-[#FAF6F0] shrink-0">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-2xl bg-[#FF6B4A]/10 flex items-center justify-center text-[#FF6B4A] shadow-2xs">
                      <Bell className="w-5 h-5" />
                    </div>
                    <div>
                      <h2 className="text-base font-black text-[#1A1A1A] leading-tight">Notifications</h2>
                      <p className="text-xs font-semibold text-[#8C877E]">
                        {unreadCount > 0 ? `${unreadCount} unread update${unreadCount === 1 ? '' : 's'}` : 'All caught up'}
                      </p>
                    </div>
                  </div>

                  <button
                    type="button"
                    aria-label="Close notifications"
                    onClick={onClose}
                    className="w-8 h-8 flex items-center justify-center rounded-xl hover:bg-[#F5EFE6] text-[#8C877E] hover:text-[#1A1A1A] transition-colors cursor-pointer"
                  >
                    <X className="w-4 h-4" />
                  </button>
                </div>

                {/* Filter Tabs & Mark as read */}
                <div className="mt-4 flex items-center justify-between gap-2">
                  <div className="flex items-center gap-1 bg-white p-1 rounded-xl border border-[#EFE9E0] shadow-2xs">
                    <button
                      type="button"
                      onClick={() => setActiveTab('all')}
                      className={`px-3 py-1 text-xs font-bold rounded-lg transition-all cursor-pointer ${
                        activeTab === 'all'
                          ? 'bg-[#FF6B4A] text-white shadow-2xs'
                          : 'text-[#706E6B] hover:text-[#1A1A1A]'
                      }`}
                    >
                      All
                    </button>
                    <button
                      type="button"
                      onClick={() => setActiveTab('announcement')}
                      className={`px-3 py-1 text-xs font-bold rounded-lg transition-all cursor-pointer ${
                        activeTab === 'announcement'
                          ? 'bg-[#FF6B4A] text-white shadow-2xs'
                          : 'text-[#706E6B] hover:text-[#1A1A1A]'
                      }`}
                    >
                      Notices
                    </button>
                    <button
                      type="button"
                      onClick={() => setActiveTab('quest')}
                      className={`px-3 py-1 text-xs font-bold rounded-lg transition-all cursor-pointer ${
                        activeTab === 'quest'
                          ? 'bg-[#FF6B4A] text-white shadow-2xs'
                          : 'text-[#706E6B] hover:text-[#1A1A1A]'
                      }`}
                    >
                      Quests
                    </button>
                  </div>

                  {unreadCount > 0 && (
                    <button
                      type="button"
                      onClick={() => void markAllAsRead()}
                      className="text-xs font-bold text-[#FF6B4A] hover:text-[#E4572E] hover:underline flex items-center gap-1 cursor-pointer"
                    >
                      <CheckCheck className="w-3.5 h-3.5" /> Mark read
                    </button>
                  )}
                </div>
              </div>

              {/* Drawer Content Body: min-h-0 prevents overflow/clipping */}
              <div className="flex-1 min-h-0 overflow-y-auto p-4 sm:p-5 space-y-2.5 custom-scrollbar">
                {loading ? (
                  <div className="grid min-h-48 place-items-center"><Loader2 className="h-6 w-6 animate-spin text-[#FF6B4A]" /></div>
                ) : loadError ? (
                  <div className="rounded-2xl bg-red-50 p-4 text-center text-xs font-bold text-red-700">
                    {loadError} <button onClick={() => void loadNotifications()} className="underline cursor-pointer">Retry</button>
                  </div>
                ) : filtered.length === 0 ? (
                  <div className="text-center py-16 space-y-3">
                    <div className="w-14 h-14 rounded-full bg-[#FAF6F0] border border-[#EFE9E0] flex items-center justify-center mx-auto text-[#8C877E] shadow-2xs">
                      <Bell className="w-6 h-6" />
                    </div>
                    <p className="font-bold text-[#1A1A1A] text-sm">No notifications found</p>
                    <p className="text-xs text-[#8C877E] max-w-xs mx-auto">
                      All new department broadcasts, mock tests, and daily streaks will appear right here.
                    </p>
                  </div>
                ) : (
                  filtered.map((item) => (
                    <Link
                      key={item.id}
                      href={item.link}
                      onClick={() => { void markAsRead(item.id); onClose(); }}
                      className={`group relative block p-3.5 rounded-2xl border transition-all cursor-pointer ${
                        item.unread
                          ? 'bg-[#FFF9F6] border-[#FF6B4A]/30 border-l-4 border-l-[#FF6B4A] shadow-2xs'
                          : 'bg-white border-[#EFE9E0] hover:border-[#E2D8C9] hover:bg-[#FAF6F0]'
                      }`}
                    >
                      <div className="flex items-start gap-3">
                        <div className="w-8 h-8 rounded-xl bg-white border border-[#EFE9E0] flex items-center justify-center shrink-0 shadow-2xs mt-0.5">
                          {getIcon(item.type)}
                        </div>

                        <div className="flex-1 min-w-0">
                          <div className="flex items-center justify-between gap-2">
                            <h3 className={`text-xs font-bold truncate ${item.unread ? 'text-[#FF6B4A]' : 'text-[#1A1A1A]'}`}>
                              {item.title}
                            </h3>
                            <span className="text-[10px] font-medium text-[#8C877E] shrink-0 flex items-center gap-1">
                              <Clock className="w-2.5 h-2.5" />
                              {item.timeAgo}
                            </span>
                          </div>

                          <p className="mt-1 text-xs text-[#706E6B] leading-relaxed line-clamp-2">
                            {item.description}
                          </p>

                          <div className="mt-2.5 flex items-center justify-between">
                            <span className="inline-flex items-center gap-1 text-xs font-bold text-[#FF6B4A] group-hover:translate-x-0.5 transition-transform">
                              {item.actionLabel}
                              <ArrowRight className="w-3 h-3" />
                            </span>

                            {item.unread && (
                              <span className="w-2 h-2 rounded-full bg-[#FF6B4A] animate-pulse" />
                            )}
                          </div>
                        </div>
                      </div>
                    </Link>
                  ))
                )}
              </div>

              {/* Drawer Footer Actions */}
              <div className="p-4 border-t border-[#EFE9E0] bg-[#FAF6F0] shrink-0 space-y-2">
                <Link
                  href="/student/announcements"
                  onClick={onClose}
                  className="w-full flex items-center justify-center gap-2 py-2.5 px-4 rounded-xl bg-white hover:bg-[#F5EFE6] border border-[#EFE9E0] text-xs font-bold text-[#1A1A1A] transition-colors shadow-2xs cursor-pointer"
                >
                  <Megaphone className="w-3.5 h-3.5 text-[#FF6B4A]" />
                  View Full Department Announcements
                </Link>

                <div className="flex items-center justify-between px-2 pt-1 text-[11px] text-[#8C877E]">
                  <span className="flex items-center gap-1.5 font-medium">
                    <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" /> Real-Time Live Feed
                  </span>
                  <Link
                    href="/student/settings"
                    onClick={onClose}
                    className="hover:underline font-semibold hover:text-[#1A1A1A]"
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
