'use client';

import React, { useState } from 'react';
import { Bell, CheckCircle2, Clock, AlertCircle, Sparkles, Inbox, Filter } from 'lucide-react';

interface NotificationItem {
  id: string;
  title: string;
  body: string;
  category: 'quest' | 'session' | 'digest' | 'system';
  created_at: string;
  read: boolean;
  priority: 'high' | 'normal';
}

export default function StudentInboxPage() {
  const [filter, setFilter] = useState<'all' | 'unread'>('all');
  const [notifications, setNotifications] = useState<NotificationItem[]>([
    {
      id: '1',
      title: 'DBMS ACID Sprint Available',
      body: 'Your Core CS evidence is 18 days old. Complete the 7-minute sprint to refresh your readiness dimension.',
      category: 'quest',
      created_at: '2 hours ago',
      read: false,
      priority: 'high',
    },
    {
      id: '2',
      title: 'Coding Lab Session Tomorrow 08:30 AM',
      body: 'Placement readiness coding session scheduled at Lab 3 (F Block). Bring your laptop ready for CodeBox tasks.',
      category: 'session',
      created_at: '5 hours ago',
      read: false,
      priority: 'high',
    },
    {
      id: '3',
      title: 'Weekly Readiness Digest Generated',
      body: 'You completed 4 quests this week with 100% Daily Five streak. Check your readiness movement report.',
      category: 'digest',
      created_at: 'Yesterday',
      read: true,
      priority: 'normal',
    },
    {
      id: '4',
      title: 'LeetCode Stats Synced',
      body: 'Successfully synced 3 new problem solves from your LeetCode handle. Coding dimension updated.',
      category: 'system',
      created_at: '2 days ago',
      read: true,
      priority: 'normal',
    },
  ]);

  const markAllAsRead = () => {
    setNotifications(notifications.map(n => ({ ...n, read: true })));
  };

  const markAsRead = (id: string) => {
    setNotifications(notifications.map(n => n.id === id ? ({ ...n, read: true }) : n));
  };

  const filtered = filter === 'unread' ? notifications.filter(n => !n.read) : notifications;

  return (
    <div className="max-w-4xl mx-auto space-y-6 pb-12">
      <div className="flex items-center justify-between">
        <div>
          <span className="text-xs font-bold text-electric-blue uppercase tracking-wider block">
            Notifications & Alerts · PRD Chapter 13
          </span>
          <h1 className="text-2xl font-black text-white mt-1 flex items-center gap-2">
            <Inbox className="w-6 h-6 text-electric-blue" />
            Unified Inbox
          </h1>
          <p className="text-sm text-slate-400">
            FCM push and in-app alerts. Read states synchronize seamlessly across web and mobile.
          </p>
        </div>
        <button
          onClick={markAllAsRead}
          className="text-xs font-bold text-slate-400 hover:text-white px-3 py-1.5 bg-slate-900 border border-slate-800 rounded-lg transition-colors"
        >
          Mark all as read
        </button>
      </div>

      {/* Filter Tabs */}
      <div className="flex gap-2 border-b border-slate-800 pb-3">
        <button
          onClick={() => setFilter('all')}
          className={`px-4 py-1.5 text-xs font-bold rounded-lg transition-all ${
            filter === 'all' ? 'bg-electric-blue text-white' : 'text-slate-400 hover:bg-slate-900'
          }`}
        >
          All ({notifications.length})
        </button>
        <button
          onClick={() => setFilter('unread')}
          className={`px-4 py-1.5 text-xs font-bold rounded-lg transition-all ${
            filter === 'unread' ? 'bg-electric-blue text-white' : 'text-slate-400 hover:bg-slate-900'
          }`}
        >
          Unread ({notifications.filter(n => !n.read).length})
        </button>
      </div>

      {/* Notifications List */}
      <div className="space-y-3">
        {filtered.map((item) => (
          <div
            key={item.id}
            onClick={() => markAsRead(item.id)}
            className={`p-4 rounded-xl border cursor-pointer transition-all flex items-start gap-4 ${
              !item.read
                ? 'bg-slate-900 border-electric-blue/40 shadow-sm'
                : 'bg-slate-950 border-slate-800/80 opacity-80'
            }`}
          >
            <div className={`w-9 h-9 rounded-lg flex items-center justify-center shrink-0 ${
              item.priority === 'high' ? 'bg-electric-blue/10 text-electric-blue' : 'bg-slate-800 text-slate-400'
            }`}>
              <Bell className="w-4 h-4" />
            </div>

            <div className="flex-1 space-y-1">
              <div className="flex items-center justify-between">
                <h4 className="text-sm font-bold text-white flex items-center gap-2">
                  {item.title}
                  {!item.read && (
                    <span className="w-2 h-2 rounded-full bg-electric-blue inline-block" />
                  )}
                </h4>
                <span className="text-[11px] text-slate-500 font-mono">{item.created_at}</span>
              </div>
              <p className="text-xs text-slate-400 leading-relaxed">{item.body}</p>
            </div>
          </div>
        ))}

        {filtered.length === 0 && (
          <div className="text-center py-12 text-slate-500 text-sm bg-slate-900/50 rounded-2xl border border-slate-800">
            No notifications to display.
          </div>
        )}
      </div>
    </div>
  );
}
