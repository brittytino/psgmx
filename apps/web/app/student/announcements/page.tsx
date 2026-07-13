'use client';

import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { Megaphone, Bell, AlertTriangle, Calendar, CheckCircle, BookOpen } from 'lucide-react';

const announcements = [
  { id: 1, title: 'Mock Exam Scheduled — Data Structures', from: 'Dr. Arunkumar', role: 'Faculty', date: 'Jan 15, 2025', tag: 'EXAM', tagColor: 'bg-primary-purple/10 text-primary-purple', read: false, body: 'A full mock exam on Data Structures will be conducted on January 20th at 10:00 AM. Please ensure you log in with a laptop and allow camera access for proctoring. Duration: 90 minutes. The exam includes 40 questions — MCQ and one coding problem.' },
  { id: 2, title: 'Zoho Campus Drive — Registration Open', from: 'Placement Team', role: 'Admin', date: 'Jan 12, 2025', tag: 'URGENT', tagColor: 'bg-deep-violet/10 text-deep-violet', read: false, body: 'Zoho Corporation will be visiting the campus on February 5, 2025. Registration is mandatory and must be completed before January 25. Role: Software Engineer. Package: 6.5 LPA. Open to 2nd year MCA students with 60%+ CGPA.' },
  { id: 3, title: 'New Articles Approved in Knowledge Brain', from: 'Faculty Review Team', role: 'Faculty', date: 'Jan 10, 2025', tag: 'KNOWLEDGE', tagColor: 'bg-electric-blue/10 text-electric-blue', read: true, body: '5 new articles have been approved and indexed in the Knowledge Brain: "How I cracked Zoho", "TCS NQT Deep Dive", "My 2-Year Strategy", "SQL Interview Patterns", and "Capgemini GameChallenge". Search for these in the Knowledge Brain.' },
  { id: 4, title: 'FYP Mid-Review Dates Announced', from: 'Dr. Priya', role: 'Faculty', date: 'Jan 8, 2025', tag: 'DEADLINE', tagColor: 'bg-illus-gold/10 text-illus-gold', read: true, body: 'FYP mid-reviews will be conducted between January 20–25. Please ensure your progress log is updated and your documentation is ready. Your guide will review entries before the session.' },
  { id: 5, title: 'PSGMX App — Streak Freeze Feature Now Live', from: 'Tech Team', role: 'Admin', date: 'Jan 5, 2025', tag: 'UPDATE', tagColor: 'bg-page-bg text-text-muted', read: true, body: 'You now get 2 streak freeze tokens per month in the Flutter app. Use them on days you genuinely can\'t complete the Daily Five. They reset on the 1st of every month. Open the Flutter app to claim your tokens.' },
];

const tagIcons: Record<string, any> = {
  'EXAM': BookOpen,
  'URGENT': AlertTriangle,
  'KNOWLEDGE': BookOpen,
  'DEADLINE': Calendar,
  'UPDATE': Bell,
};

export default function AnnouncementsPage() {
  const [filter, setFilter] = useState('All');
  const [expandedId, setExpandedId] = useState<number | null>(null);
  const [readIds, setReadIds] = useState<Set<number>>(new Set(announcements.filter(a => a.read).map(a => a.id)));

  const filters = ['All', 'Unread', 'EXAM', 'URGENT', 'DEADLINE'];
  const filtered = announcements.filter(a =>
    filter === 'All' ? true :
    filter === 'Unread' ? !readIds.has(a.id) :
    a.tag === filter
  );

  const markRead = (id: number) => {
    setReadIds(prev => new Set([...prev, id]));
    setExpandedId(expandedId === id ? null : id);
  };

  return (
    <div className="max-w-[900px] mx-auto space-y-8 pb-8">

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-[24px] font-black text-text-main tracking-tight flex items-center gap-2">
            <Megaphone className="w-6 h-6 text-primary-purple" /> Announcements
          </h1>
          <p className="text-[13px] text-text-muted mt-0.5">{announcements.filter(a => !readIds.has(a.id)).length} unread · Department updates from faculty and placement team.</p>
        </div>
        <button onClick={() => setReadIds(new Set(announcements.map(a => a.id)))} className="text-[13px] font-bold text-primary-purple hover:underline">
          Mark all read
        </button>
      </div>

      {/* Filters */}
      <div className="flex gap-2 flex-wrap">
        {filters.map((f) => (
          <button key={f} onClick={() => setFilter(f)} className={`px-4 py-2 rounded-full text-[12px] font-bold transition-colors ${filter === f ? 'bg-primary-purple text-white' : 'bg-white border border-border-light text-text-muted hover:bg-page-bg'}`}>
            {f}
          </button>
        ))}
      </div>

      {/* Announcement List */}
      <div className="space-y-3">
        {filtered.map((ann, i) => {
          const TagIcon = tagIcons[ann.tag] || Bell;
          const isRead = readIds.has(ann.id);
          const isExpanded = expandedId === ann.id;
          return (
            <motion.div
              key={ann.id}
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: i * 0.05 }}
              className={`bg-white rounded-[20px] border transition-all cursor-pointer shadow-[0_2px_12px_rgba(0,0,0,0.02)] ${isRead ? 'border-border-light' : 'border-primary-purple/30 shadow-primary-purple/5'}`}
              onClick={() => markRead(ann.id)}
            >
              <div className="p-5 flex items-start gap-4">
                {!isRead && <div className="w-2 h-2 rounded-full bg-primary-purple shrink-0 mt-2" />}
                <div className={`w-10 h-10 rounded-[10px] flex items-center justify-center shrink-0 ${ann.tagColor.split(' ')[0]}`}>
                  <TagIcon className={`w-5 h-5 ${ann.tagColor.split(' ')[1]}`} />
                </div>
                <div className="flex-1">
                  <div className="flex items-center gap-2 mb-1">
                    <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${ann.tagColor}`}>{ann.tag}</span>
                    {isRead && <CheckCircle className="w-3.5 h-3.5 text-electric-blue" />}
                  </div>
                  <h4 className="text-[15px] font-bold text-text-main">{ann.title}</h4>
                  <p className="text-[12px] text-text-muted mt-0.5">{ann.from} · {ann.role} · {ann.date}</p>
                  {isExpanded && (
                    <motion.p initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="text-[13px] text-text-main mt-3 leading-relaxed">
                      {ann.body}
                    </motion.p>
                  )}
                </div>
              </div>
            </motion.div>
          );
        })}
        {filtered.length === 0 && (
          <div className="text-center py-16">
            <Megaphone className="w-12 h-12 text-border-light mx-auto mb-3" />
            <p className="text-[15px] font-bold text-text-muted">No announcements here</p>
          </div>
        )}
      </div>
    </div>
  );
}
