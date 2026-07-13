'use client';

import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { Megaphone, Bell, Calendar, BookOpen, Users, CheckCircle } from 'lucide-react';

const announcements = [
  { id: 1, title: 'Alumni Reunion — Batch 23MX', from: 'Department', tag: 'ALUMNI EVENT', date: 'Jan 15, 2025', read: false, body: 'The Batch 23MX reunion is being planned for February 2025 at PSG College of Technology. All graduates from the 2023 batch are invited. Details will be shared closer to the date. Please fill the RSVP form linked in the department WhatsApp group.' },
  { id: 2, title: 'New Student Batch Intake — 26MX', from: 'Department', tag: 'DEPT NEWS', date: 'Jan 10, 2025', read: false, body: 'The new 26MX batch has been onboarded to PSGMX. If you\'d like to volunteer as a guest speaker for an orientation session about your placement journey, please contact the placement team.' },
  { id: 3, title: 'Knowledge Brain: Alumni Contribution Drive', from: 'Placement Team', tag: 'CONTRIBUTION', date: 'Jan 5, 2025', read: true, body: 'We\'re running a drive to expand the Knowledge Brain with more alumni-written content. Alumni who contribute at least 2 approved articles this January will be featured on the department website. Contribute via your alumni portal.' },
  { id: 4, title: 'New Lineage System — Your Junior is Live', from: 'Tech Team', tag: 'UPDATE', date: 'Dec 28, 2024', read: true, body: 'The PSGMX lineage system is now active for all alumni. Your junior (25MX301) can now see your mentorship status. Toggle availability in your Settings → Mentorship tab.' },
];

const tagColors: Record<string, string> = {
  'ALUMNI EVENT': 'bg-primary-purple/10 text-primary-purple',
  'DEPT NEWS': 'bg-electric-blue/10 text-electric-blue',
  'CONTRIBUTION': 'bg-illus-gold/10 text-illus-gold',
  'UPDATE': 'bg-page-bg text-text-muted',
};

export default function AlumniAnnouncementsPage() {
  const [expandedId, setExpandedId] = useState<number | null>(null);
  const [readIds, setReadIds] = useState<Set<number>>(new Set(announcements.filter(a => a.read).map(a => a.id)));

  const markRead = (id: number) => {
    setReadIds(prev => new Set([...prev, id]));
    setExpandedId(expandedId === id ? null : id);
  };

  return (
    <div className="max-w-[900px] mx-auto space-y-8 pb-8">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-[24px] font-black text-text-main tracking-tight flex items-center gap-2">
            <Megaphone className="w-6 h-6 text-primary-purple" /> Announcements
          </h1>
          <p className="text-[13px] text-text-muted mt-0.5">Department news, alumni network events, and platform updates.</p>
        </div>
        <button onClick={() => setReadIds(new Set(announcements.map(a => a.id)))} className="text-[13px] font-bold text-primary-purple hover:underline">Mark all read</button>
      </div>

      <div className="space-y-3">
        {announcements.map((ann, i) => {
          const isRead = readIds.has(ann.id);
          return (
            <motion.div key={ann.id} initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.06 }}
              className={`bg-white rounded-[20px] border cursor-pointer shadow-[0_2px_12px_rgba(0,0,0,0.02)] transition-all ${isRead ? 'border-border-light' : 'border-primary-purple/30'}`}
              onClick={() => markRead(ann.id)}>
              <div className="p-5 flex items-start gap-4">
                {!isRead && <div className="w-2 h-2 rounded-full bg-primary-purple shrink-0 mt-2" />}
                <div className="flex-1">
                  <div className="flex items-center gap-2 mb-1">
                    <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${tagColors[ann.tag] || 'bg-page-bg text-text-muted'}`}>{ann.tag}</span>
                    {isRead && <CheckCircle className="w-3.5 h-3.5 text-electric-blue" />}
                  </div>
                  <h4 className="text-[15px] font-bold text-text-main">{ann.title}</h4>
                  <p className="text-[12px] text-text-muted mt-0.5">{ann.from} · {ann.date}</p>
                  {expandedId === ann.id && (
                    <motion.p initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="text-[13px] text-text-main mt-3 leading-relaxed">{ann.body}</motion.p>
                  )}
                </div>
              </div>
            </motion.div>
          );
        })}
      </div>
    </div>
  );
}
