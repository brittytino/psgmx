'use client';

import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { Folder, CheckCircle, Clock, Plus, ChevronRight, Calendar, MessageSquare } from 'lucide-react';

const milestones = [
  { label: 'Topic Finalization', status: 'done', date: 'Jul 10, 2024' },
  { label: 'Proposal Submission', status: 'done', date: 'Aug 5, 2024' },
  { label: 'Mid-Review', status: 'done', date: 'Oct 20, 2024' },
  { label: 'Development Phase', status: 'active', date: 'Jan 20, 2025' },
  { label: 'Testing & QA', status: 'pending', date: 'Mar 15, 2025' },
  { label: 'Final Submission', status: 'pending', date: 'Apr 30, 2025' },
];

const progressLog = [
  { date: 'Jan 12, 2025', note: 'Completed authentication module with JWT and role-based access control.', author: 'You' },
  { date: 'Jan 5, 2025', note: 'Set up the Next.js project with Supabase integration. Initial DB schema finalized.', author: 'You' },
  { date: 'Dec 20, 2024', note: 'Mid-review cleared. Faculty suggested adding a performance dashboard.', author: 'You' },
  { date: 'Nov 15, 2024', note: 'Proposal approved by Dr. Arunkumar. Team formed with 3 members.', author: 'You' },
];

const facultyComments = [
  { date: 'Jan 10, 2025', comment: 'Good progress on authentication. Make sure to add proper error handling and validation.', faculty: 'Dr. Arunkumar' },
  { date: 'Dec 22, 2024', comment: 'Mid-review performance was excellent. Focus on the frontend polish in next phase.', faculty: 'Dr. Priya' },
];

export default function FYPPage() {
  const [showAddLog, setShowAddLog] = useState(false);
  const [newNote, setNewNote] = useState('');

  const currentPhaseIdx = milestones.findIndex(m => m.status === 'active');
  const progress = Math.round(((currentPhaseIdx) / (milestones.length - 1)) * 100);

  return (
    <div className="max-w-[1100px] mx-auto space-y-8 pb-8">

      {/* Header */}
      <div>
        <h1 className="text-[24px] font-black text-text-main tracking-tight flex items-center gap-2">
          <Folder className="w-6 h-6 text-primary-purple" /> FYP Portfolio
        </h1>
        <p className="text-[13px] text-text-muted mt-0.5">Your Final Year Project progress — tracked and documented.</p>
      </div>

      {/* Project Hero Card */}
      <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} className="bg-white rounded-[24px] border border-border-light shadow-[0_4px_20px_rgba(0,0,0,0.04)] p-8">
        <div className="flex items-start justify-between mb-6">
          <div>
            <span className="text-[10px] font-bold text-primary-purple uppercase tracking-wider bg-primary-purple/10 px-2.5 py-1 rounded-full">ACTIVE PROJECT</span>
            <h2 className="text-[22px] font-black text-text-main mt-3 mb-1">PSGMX — Placement Readiness Ecosystem</h2>
            <p className="text-[13px] text-text-muted">MCA Department · PSG College of Technology</p>
            <div className="flex gap-4 mt-3">
              <p className="text-[13px] text-text-muted">Guide: <span className="font-bold text-text-main">Dr. Arunkumar</span></p>
              <p className="text-[13px] text-text-muted">Team: <span className="font-bold text-text-main">3 members</span></p>
            </div>
          </div>
          <div className="relative w-20 h-20 shrink-0">
            <svg viewBox="0 0 100 100" className="w-full h-full -rotate-90">
              <circle cx="50" cy="50" r="44" fill="none" stroke="#EFE9E0" strokeWidth="10" />
              <motion.circle cx="50" cy="50" r="44" fill="none" stroke="var(--primary-purple)" strokeWidth="10" strokeLinecap="round"
                initial={{ strokeDasharray: '0 276.46' }}
                animate={{ strokeDasharray: `${(progress / 100) * 276.46} 276.46` }}
                transition={{ duration: 1, ease: 'easeOut', delay: 0.3 }}
              />
            </svg>
            <div className="absolute inset-0 flex flex-col items-center justify-center">
              <span className="text-[18px] font-black text-text-main">{progress}%</span>
            </div>
          </div>
        </div>

        {/* Phase Stepper */}
        <div className="relative">
          <div className="flex items-center gap-0">
            {milestones.map((m, i) => (
              <React.Fragment key={i}>
                <div className="flex flex-col items-center flex-1">
                  <div className={`w-8 h-8 rounded-full flex items-center justify-center border-2 transition-colors z-10 ${
                    m.status === 'done' ? 'bg-primary-purple border-primary-purple' :
                    m.status === 'active' ? 'bg-white border-primary-purple' : 'bg-white border-border-light'
                  }`}>
                    {m.status === 'done' ? <CheckCircle className="w-4 h-4 text-white" /> :
                     m.status === 'active' ? <div className="w-3 h-3 rounded-full bg-primary-purple" /> :
                     <div className="w-3 h-3 rounded-full bg-border-light" />}
                  </div>
                  <p className={`text-[9px] font-bold mt-2 text-center leading-tight ${
                    m.status === 'done' ? 'text-primary-purple' : m.status === 'active' ? 'text-text-main' : 'text-text-muted'
                  }`}>{m.label}</p>
                  <p className="text-[8px] text-text-muted mt-0.5">{m.date}</p>
                </div>
                {i < milestones.length - 1 && (
                  <div className={`h-0.5 flex-1 -mx-1 mb-8 ${milestones[i + 1].status !== 'pending' ? 'bg-primary-purple' : 'bg-border-light'}`} />
                )}
              </React.Fragment>
            ))}
          </div>
        </div>
      </motion.div>

      {/* Main Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">

        {/* Progress Log */}
        <div className="lg:col-span-2 bg-white rounded-[20px] border border-border-light shadow-[0_2px_12px_rgba(0,0,0,0.02)]">
          <div className="p-6 border-b border-page-bg flex justify-between items-center">
            <h3 className="text-[16px] font-bold text-text-main">Progress Log</h3>
            <button onClick={() => setShowAddLog(!showAddLog)} className="flex items-center gap-2 px-4 py-2 bg-primary-purple text-white rounded-xl text-[12px] font-bold hover:bg-deep-violet transition-colors">
              <Plus className="w-3.5 h-3.5" /> Add Entry
            </button>
          </div>
          <div className="p-6">
            {showAddLog && (
              <motion.div initial={{ opacity: 0, y: -10 }} animate={{ opacity: 1, y: 0 }} className="mb-6 p-5 bg-page-bg rounded-[16px] border border-border-light">
                <textarea
                  value={newNote}
                  onChange={(e) => setNewNote(e.target.value)}
                  placeholder="Describe what you accomplished today..."
                  rows={3}
                  className="w-full bg-white border border-border-light rounded-xl px-4 py-3 text-[14px] text-text-main outline-none focus:border-primary-purple transition-colors resize-none"
                />
                <div className="flex gap-3 mt-3">
                  <button className="px-5 py-2 bg-primary-purple text-white rounded-xl text-[13px] font-bold hover:bg-deep-violet transition-colors">Save Entry</button>
                  <button onClick={() => setShowAddLog(false)} className="px-5 py-2 bg-white border border-border-light text-text-muted rounded-xl text-[13px] font-bold hover:bg-page-bg transition-colors">Cancel</button>
                </div>
              </motion.div>
            )}

            {/* Timeline */}
            <div className="relative">
              <div className="absolute left-4 top-0 bottom-0 w-px bg-border-light" />
              <div className="space-y-6 pl-12">
                {progressLog.map((entry, i) => (
                  <motion.div key={i} initial={{ opacity: 0, x: -10 }} animate={{ opacity: 1, x: 0 }} transition={{ delay: i * 0.1 }} className="relative">
                    <div className="absolute -left-[44px] w-8 h-8 rounded-full bg-primary-purple flex items-center justify-center shadow-sm border-2 border-white">
                      <span className="text-[10px] font-black text-white">{String(progressLog.length - i).padStart(2, '0')}</span>
                    </div>
                    <div className="p-4 bg-page-bg rounded-[16px] border border-border-light">
                      <p className="text-[14px] text-text-main leading-relaxed">{entry.note}</p>
                      <div className="flex items-center gap-3 mt-2">
                        <Calendar className="w-3.5 h-3.5 text-text-muted" />
                        <span className="text-[11px] font-semibold text-text-muted">{entry.date} · {entry.author}</span>
                      </div>
                    </div>
                  </motion.div>
                ))}
              </div>
            </div>
          </div>
        </div>

        {/* Right: Faculty Comments + Milestones */}
        <div className="space-y-6">
          <div className="bg-white rounded-[20px] border border-border-light shadow-[0_2px_12px_rgba(0,0,0,0.02)] p-6">
            <div className="flex items-center gap-2 mb-5">
              <MessageSquare className="w-5 h-5 text-primary-purple" />
              <h3 className="text-[14px] font-bold text-text-main">Faculty Comments</h3>
            </div>
            <div className="space-y-4">
              {facultyComments.map((c, i) => (
                <div key={i} className="p-4 bg-page-bg rounded-[14px] border-l-4 border-primary-purple">
                  <p className="text-[13px] text-text-main leading-relaxed">{c.comment}</p>
                  <p className="text-[11px] font-bold text-primary-purple mt-2">{c.faculty} · {c.date}</p>
                </div>
              ))}
              {facultyComments.length === 0 && (
                <p className="text-[13px] text-text-muted text-center py-4">No faculty comments yet. Add progress entries to get feedback.</p>
              )}
            </div>
          </div>

          <div className="bg-white rounded-[20px] border border-border-light shadow-[0_2px_12px_rgba(0,0,0,0.02)] p-6">
            <h3 className="text-[14px] font-bold text-text-main mb-4">Upcoming Milestones</h3>
            {milestones.filter(m => m.status !== 'done').map((m, i) => (
              <div key={i} className="flex items-center gap-3 mb-3 last:mb-0">
                <div className={`w-2 h-2 rounded-full shrink-0 ${m.status === 'active' ? 'bg-primary-purple' : 'bg-border-light'}`} />
                <div className="flex-1">
                  <p className={`text-[13px] font-bold ${m.status === 'active' ? 'text-text-main' : 'text-text-muted'}`}>{m.label}</p>
                  <p className="text-[11px] text-text-muted">{m.date}</p>
                </div>
                {m.status === 'active' && <span className="text-[9px] font-bold bg-primary-purple text-white px-2 py-0.5 rounded-full">NOW</span>}
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
