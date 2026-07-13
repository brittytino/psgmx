'use client';

import React from 'react';
import { motion } from 'framer-motion';
import { Award, Trophy, Flame, Target, Zap, BookOpen, Star, Calendar } from 'lucide-react';

const milestones = [
  { icon: '🎓', label: 'Batch joined', detail: 'Calibration score: 34/100', date: 'June 2023', color: 'bg-page-bg border-border-light' },
  { icon: '📝', label: 'First mock exam', detail: 'Python Mock — Score: 72/100', date: 'Aug 2023', color: 'bg-page-bg border-border-light' },
  { icon: '🔥', label: 'Longest streak', detail: '47 consecutive days of Daily Five', date: 'Oct–Dec 2023', color: 'bg-primary-purple/10 border-primary-purple/30' },
  { icon: '💼', label: 'First placement drive', detail: 'Attended TCS Digital campus drive', date: 'Jan 2024', color: 'bg-page-bg border-border-light' },
  { icon: '📈', label: 'Reached STRONG band', detail: 'Score crossed 80 for the first time', date: 'Mar 2024', color: 'bg-electric-blue/10 border-electric-blue/30' },
  { icon: '🏆', label: 'Top 5 batch leaderboard', detail: 'Ranked 3rd in 23MX for readiness', date: 'May 2024', color: 'bg-illus-gold/10 border-illus-gold/30' },
  { icon: '✅', label: 'Graduation', detail: 'Final readiness score locked: 88/100 · STRONG', date: 'June 2025', color: 'bg-primary-purple/10 border-primary-purple/30' },
  { icon: '🌟', label: 'First alumni article', detail: '"How I cracked Zoho\'s 5-round process"', date: 'Jul 2025', color: 'bg-electric-blue/10 border-electric-blue/30' },
];

const trophies = [
  { icon: Flame, label: 'Best Streak', value: '47 days', color: 'text-deep-violet' },
  { icon: Target, label: 'Exams Taken', value: '9', color: 'text-primary-purple' },
  { icon: Zap, label: 'LeetCode (batch)', value: '147 problems', color: 'text-electric-blue' },
  { icon: BookOpen, label: 'Articles Written', value: '3', color: 'text-illus-gold' },
  { icon: Star, label: 'Batch Rank (final)', value: '#3', color: 'text-primary-purple' },
  { icon: Award, label: 'Final Band', value: 'STRONG', color: 'text-electric-blue' },
];

export default function JourneyPage() {
  const finalScore = 88;

  return (
    <div className="max-w-[1100px] mx-auto space-y-8 pb-8">

      {/* Header */}
      <div>
        <h1 className="text-[24px] font-black text-text-main tracking-tight flex items-center gap-2">
          <Award className="w-6 h-6 text-primary-purple" /> My Journey
        </h1>
        <p className="text-[13px] text-text-muted mt-0.5">Your 2-year PSGMX journey — permanently archived.</p>
      </div>

      {/* Archive Banner */}
      <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} className="bg-white rounded-[24px] border border-border-light shadow-[0_4px_20px_rgba(0,0,0,0.04)] p-8">
        <div className="flex flex-col md:flex-row items-center gap-8">
          {/* Final Score Gauge */}
          <div className="relative w-48 h-48 shrink-0">
            <div className="absolute inset-0 flex items-center justify-center">
              <div className="absolute inset-0 rounded-full bg-primary-purple/5" />
            </div>
            <svg viewBox="0 0 100 100" className="w-full h-full -rotate-90">
              <circle cx="50" cy="50" r="44" fill="none" stroke="#EFE9E0" strokeWidth="8" />
              <motion.circle
                cx="50" cy="50" r="44" fill="none" stroke="var(--primary-purple)" strokeWidth="8" strokeLinecap="round"
                initial={{ strokeDasharray: '0 276.46' }}
                animate={{ strokeDasharray: `${(finalScore / 100) * 276.46} 276.46` }}
                transition={{ duration: 1.2, ease: 'easeOut', delay: 0.3 }}
              />
            </svg>
            <div className="absolute inset-0 flex flex-col items-center justify-center">
              <span className="text-[48px] font-black text-text-main leading-none">{finalScore}</span>
              <span className="text-[10px] font-bold text-text-muted">/100</span>
              <span className="text-[10px] font-black text-electric-blue mt-1 bg-electric-blue/10 px-2 py-0.5 rounded-full">STRONG</span>
            </div>
            <div className="absolute top-2 right-2 bg-illus-gold rounded-full p-1.5">
              <Trophy className="w-4 h-4 text-white" />
            </div>
          </div>

          {/* Archive Info */}
          <div className="flex-1">
            <div className="flex items-center gap-2 mb-3">
              <span className="text-[10px] font-bold bg-primary-purple/10 text-primary-purple px-3 py-1 rounded-full uppercase tracking-wider">ARCHIVED · FINAL SCORE</span>
            </div>
            <h2 className="text-[26px] font-black text-text-main">Your 2-Year PSGMX Journey</h2>
            <p className="text-[14px] text-text-muted mt-1">Batch 23MX · <strong className="text-text-main">June 2023 — June 2025</strong></p>
            <p className="text-[13px] text-text-muted mt-3 leading-relaxed">
              This record is permanent and will remain visible to all future batches. Your placement experiences and articles are indexed in the Knowledge Brain and read by every junior who joins the department.
            </p>
            <div className="flex gap-3 mt-4">
              <div className="p-3 bg-page-bg rounded-xl text-center">
                <p className="text-[20px] font-black text-text-main">9</p>
                <p className="text-[10px] font-bold text-text-muted uppercase">Mock Exams</p>
              </div>
              <div className="p-3 bg-page-bg rounded-xl text-center">
                <p className="text-[20px] font-black text-text-main">147</p>
                <p className="text-[10px] font-bold text-text-muted uppercase">LeetCode</p>
              </div>
              <div className="p-3 bg-page-bg rounded-xl text-center">
                <p className="text-[20px] font-black text-text-main">47d</p>
                <p className="text-[10px] font-bold text-text-muted uppercase">Best Streak</p>
              </div>
              <div className="p-3 bg-page-bg rounded-xl text-center">
                <p className="text-[20px] font-black text-text-main">#3</p>
                <p className="text-[10px] font-bold text-text-muted uppercase">Final Rank</p>
              </div>
            </div>
          </div>
        </div>
      </motion.div>

      {/* Trophy Shelf */}
      <div>
        <h2 className="text-[18px] font-bold text-text-main mb-4">Achievement Shelf</h2>
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
          {trophies.map((t, i) => (
            <motion.div key={i} initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.07 }} className="bg-white rounded-[16px] border border-border-light p-4 text-center hover:shadow-md transition-shadow">
              <t.icon className={`w-8 h-8 mx-auto mb-2 ${t.color}`} />
              <p className="text-[16px] font-black text-text-main">{t.value}</p>
              <p className="text-[10px] font-bold text-text-muted mt-0.5">{t.label}</p>
            </motion.div>
          ))}
        </div>
      </div>

      {/* Journey Timeline */}
      <div>
        <h2 className="text-[18px] font-bold text-text-main mb-6">Journey Timeline</h2>
        <div className="relative">
          <div className="absolute left-8 top-0 bottom-0 w-px bg-border-light" />
          <div className="space-y-6 pl-20">
            {milestones.map((m, i) => (
              <motion.div key={i} initial={{ opacity: 0, x: -15 }} animate={{ opacity: 1, x: 0 }} transition={{ delay: i * 0.08 }} className="relative">
                <div className={`absolute -left-[52px] w-8 h-8 rounded-full border-2 flex items-center justify-center text-[16px] bg-white ${m.color.includes('border-primary') ? 'border-primary-purple' : m.color.includes('border-electric') ? 'border-electric-blue' : m.color.includes('border-illus') ? 'border-illus-gold' : 'border-border-light'}`}>
                  {m.icon}
                </div>
                <div className={`p-5 rounded-[16px] border-2 ${m.color}`}>
                  <div className="flex items-center justify-between">
                    <h4 className="text-[15px] font-bold text-text-main">{m.label}</h4>
                    <span className="text-[11px] font-semibold text-text-muted flex items-center gap-1"><Calendar className="w-3 h-3" /> {m.date}</span>
                  </div>
                  <p className="text-[13px] text-text-muted mt-1">{m.detail}</p>
                </div>
              </motion.div>
            ))}
          </div>
        </div>
      </div>

      {/* Component Archive (read-only) */}
      <div>
        <h2 className="text-[18px] font-bold text-text-main mb-4">Final Score Breakdown <span className="text-[12px] font-normal text-text-muted">(Archived)</span></h2>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          {[
            { label: 'Daily Five', score: 26, max: 30 },
            { label: 'LeetCode', score: 22, max: 25 },
            { label: 'Mock Exams', score: 32, max: 35 },
            { label: 'Attendance', score: 8, max: 10 },
          ].map((comp, i) => (
            <div key={i} className="bg-white rounded-[16px] border border-border-light p-5">
              <div className="flex justify-between mb-3">
                <p className="text-[12px] font-bold text-text-muted">{comp.label}</p>
                <p className="text-[14px] font-black text-text-main">{comp.score}/{comp.max}</p>
              </div>
              <div className="h-2.5 bg-border-light rounded-full overflow-hidden">
                <div className="h-full rounded-full bg-primary-purple" style={{ width: `${(comp.score / comp.max) * 100}%` }} />
              </div>
              <p className="text-[10px] text-text-muted mt-2">ARCHIVED · READ-ONLY</p>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
