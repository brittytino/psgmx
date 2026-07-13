'use client';

import React from 'react';
import { motion } from 'framer-motion';
import { Award, TrendingUp, Target, Zap, BookOpen, Users, Info } from 'lucide-react';
import Link from 'next/link';

const ComponentCard = ({ title, score, max, color, children, delay }: any) => (
  <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay }} className="bg-white rounded-[20px] border border-border-light shadow-[0_2px_12px_rgba(0,0,0,0.02)] p-6">
    <div className="flex items-center justify-between mb-5">
      <h3 className="text-[16px] font-bold text-text-main">{title}</h3>
      <div className="text-right">
        <span className="text-[28px] font-black text-text-main leading-none">{score}</span>
        <span className="text-[14px] text-text-muted font-semibold">/{max}</span>
      </div>
    </div>
    <div className="h-3 bg-border-light rounded-full mb-6 overflow-hidden">
      <motion.div initial={{ width: 0 }} animate={{ width: `${(score / max) * 100}%` }} transition={{ delay: delay + 0.2, duration: 0.8, ease: 'easeOut' }} className={`h-full rounded-full ${color}`} />
    </div>
    {children}
  </motion.div>
);

export default function ReadinessPage() {
  const score = 72;
  const band = score >= 80 ? 'STRONG' : score >= 60 ? 'BUILDING' : score >= 40 ? 'NEEDS ATTENTION' : 'AT RISK';
  const bandColor = score >= 80 ? 'text-electric-blue' : score >= 60 ? 'text-illus-gold' : score >= 40 ? 'text-primary-purple' : 'text-deep-violet';

  const heatmapDays = Array.from({ length: 30 }, (_, i) => ({
    day: i + 1,
    status: Math.random() > 0.2 ? (Math.random() > 0.1 ? 'completed' : 'frozen') : 'missed',
  }));

  return (
    <div className="max-w-[1200px] mx-auto space-y-8 pb-8">

      {/* Header */}
      <div>
        <h1 className="text-[24px] font-black text-text-main tracking-tight flex items-center gap-2">
          <Award className="w-6 h-6 text-primary-purple" /> Readiness Score
        </h1>
        <p className="text-[13px] text-text-muted mt-0.5">Your placement readiness, measured across four dimensions. Last updated just now.</p>
      </div>

      {/* Hero Score */}
      <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} className="bg-white rounded-[24px] border border-border-light shadow-[0_4px_20px_rgba(0,0,0,0.04)] p-8">
        <div className="flex flex-col md:flex-row items-center gap-10">
          {/* Big Gauge */}
          <div className="relative w-52 h-52 shrink-0">
            <svg viewBox="0 0 100 100" className="w-full h-full -rotate-90">
              <circle cx="50" cy="50" r="44" fill="none" stroke="#EFE9E0" strokeWidth="8" />
              <motion.circle
                cx="50" cy="50" r="44" fill="none" stroke="var(--primary-purple)" strokeWidth="8" strokeLinecap="round"
                initial={{ strokeDasharray: '0 276.46' }}
                animate={{ strokeDasharray: `${(score / 100) * 276.46} 276.46` }}
                transition={{ duration: 1.2, ease: 'easeOut', delay: 0.2 }}
              />
            </svg>
            <div className="absolute inset-0 flex flex-col items-center justify-center">
              <motion.span initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: 0.5 }} className="text-[52px] font-black text-text-main leading-none">{score}</motion.span>
              <span className="text-[11px] font-bold text-text-muted uppercase tracking-wider">/ 100</span>
            </div>
          </div>

          {/* Band + Info */}
          <div className="flex-1 space-y-5">
            <div>
              <p className="text-[12px] font-bold text-text-muted uppercase tracking-wider mb-1">Current Band</p>
              <p className={`text-[36px] font-black ${bandColor}`}>{band}</p>
            </div>
            <div className="grid grid-cols-2 gap-4">
              {[
                { label: 'Active since', value: 'June 2025' },
                { label: 'Batch', value: '25MX' },
                { label: 'Score last week', value: '64' },
                { label: 'Score change', value: '↑ 8 points' },
              ].map((item, i) => (
                <div key={i} className="p-3 bg-page-bg rounded-xl">
                  <p className="text-[11px] font-bold text-text-muted uppercase">{item.label}</p>
                  <p className="text-[16px] font-black text-text-main mt-0.5">{item.value}</p>
                </div>
              ))}
            </div>
          </div>

          {/* 90-day Chart */}
          <div className="shrink-0 flex flex-col items-center gap-2">
            <p className="text-[11px] font-bold text-text-muted uppercase tracking-wider">90-Day Trend</p>
            <svg viewBox="0 0 180 80" className="w-48 h-20 fill-none" strokeLinecap="round" strokeLinejoin="round">
              <path d="M0,75 C10,70 20,65 35,55 C50,45 55,50 70,42 C85,34 90,38 105,30 C120,22 130,18 150,12 C160,9 170,7 180,5" stroke="#EFE9E0" strokeWidth="2" />
              <path d="M0,75 C10,70 20,65 35,55 C50,45 55,50 70,42 C85,34 90,38 105,30 C120,22 130,18 150,12 C160,9 170,7 180,5" stroke="var(--primary-purple)" strokeWidth="2.5" />
            </svg>
            <div className="flex items-center gap-1.5">
              <TrendingUp className="w-4 h-4 text-electric-blue" />
              <span className="text-[12px] font-bold text-electric-blue">↑ 8 pts this month</span>
            </div>
          </div>
        </div>
      </motion.div>

      {/* Score Bands Info */}
      <div className="grid grid-cols-4 gap-4">
        {[
          { band: 'STRONG', range: '80–100', color: 'border-electric-blue bg-electric-blue/5', text: 'text-electric-blue' },
          { band: 'BUILDING', range: '60–79', color: 'border-illus-gold bg-illus-gold/5', text: 'text-illus-gold' },
          { band: 'NEEDS ATTENTION', range: '40–59', color: 'border-primary-purple bg-primary-purple/5', text: 'text-primary-purple' },
          { band: 'AT RISK', range: '0–39', color: 'border-deep-violet bg-deep-violet/5', text: 'text-deep-violet' },
        ].map((b, i) => (
          <motion.div key={i} initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.1 + i * 0.05 }} className={`p-4 rounded-[16px] border-2 ${b.color} ${score >= parseInt(b.range) ? 'ring-2 ring-offset-2' : ''}`}>
            <p className={`text-[11px] font-black uppercase tracking-wider ${b.text}`}>{b.band}</p>
            <p className="text-[20px] font-black text-text-main mt-1">{b.range}</p>
          </motion.div>
        ))}
      </div>

      {/* Four Component Cards */}

      {/* Component 1: Daily Five */}
      <ComponentCard title="Daily Five Engagement" score={21} max={30} color="bg-primary-purple" delay={0.1}>
        <div className="grid grid-cols-2 gap-4 mb-5">
          <div className="p-4 bg-page-bg rounded-xl">
            <p className="text-[11px] font-bold text-text-muted uppercase">Adherence Rate</p>
            <p className="text-[24px] font-black text-text-main">87%</p>
            <p className="text-[11px] text-text-muted">Points: 17.4/20</p>
          </div>
          <div className="p-4 bg-page-bg rounded-xl">
            <p className="text-[11px] font-bold text-text-muted uppercase">Accuracy Rate</p>
            <p className="text-[24px] font-black text-text-main">73%</p>
            <p className="text-[11px] text-text-muted">Points: 7.3/10</p>
          </div>
        </div>
        <div>
          <p className="text-[12px] font-bold text-text-muted uppercase mb-3">30-Day Activity (Flutter App)</p>
          <div className="flex flex-wrap gap-1.5">
            {heatmapDays.map((day) => (
              <div
                key={day.day}
                title={`Day ${day.day}: ${day.status}`}
                className={`w-7 h-7 rounded-lg flex items-center justify-center text-[9px] font-bold ${
                  day.status === 'completed' ? 'bg-primary-purple text-white' :
                  day.status === 'frozen' ? 'bg-illus-gold text-white' : 'bg-border-light text-text-muted'
                }`}
              >
                {day.day}
              </div>
            ))}
          </div>
          <div className="flex gap-4 mt-3">
            <div className="flex items-center gap-1.5"><div className="w-3 h-3 rounded bg-primary-purple" /><span className="text-[11px] text-text-muted">Completed</span></div>
            <div className="flex items-center gap-1.5"><div className="w-3 h-3 rounded bg-illus-gold" /><span className="text-[11px] text-text-muted">Freeze used</span></div>
            <div className="flex items-center gap-1.5"><div className="w-3 h-3 rounded bg-border-light" /><span className="text-[11px] text-text-muted">Missed</span></div>
          </div>
          <p className="text-[11px] text-text-muted mt-3 flex items-center gap-1.5"><Info className="w-3.5 h-3.5" /> Updated daily via PSGMX Flutter App. Open the app to complete today's quiz.</p>
        </div>
      </ComponentCard>

      {/* Component 2: LeetCode */}
      <ComponentCard title="LeetCode Progress" score={16} max={25} color="bg-electric-blue" delay={0.2}>
        <div className="grid grid-cols-3 gap-4 mb-5">
          {[
            { label: 'Easy', value: 48, weight: '×1', pts: 48 },
            { label: 'Medium', value: 22, weight: '×2', pts: 44 },
            { label: 'Hard', value: 4, weight: '×3', pts: 12 },
          ].map((lc, i) => (
            <div key={i} className="p-4 bg-page-bg rounded-xl">
              <p className="text-[11px] font-bold text-text-muted uppercase">{lc.label} <span className="text-text-main">{lc.weight}</span></p>
              <p className="text-[22px] font-black text-text-main">{lc.value}</p>
              <p className="text-[10px] text-text-muted">{lc.pts} weighted pts</p>
            </div>
          ))}
        </div>
        <div className="p-4 bg-page-bg rounded-xl flex items-center gap-4">
          <Zap className="w-6 h-6 text-electric-blue shrink-0" />
          <div>
            <p className="text-[12px] font-bold text-text-muted uppercase">Batch Percentile</p>
            <p className="text-[22px] font-black text-text-main">73<span className="text-[14px] text-text-muted">th percentile</span></p>
            <p className="text-[11px] text-text-muted">You rank higher than 73% of 25MX batch in LeetCode</p>
          </div>
        </div>
        <p className="text-[11px] text-text-muted mt-3 flex items-center gap-1.5"><Info className="w-3.5 h-3.5" /> Synced every 6 hours from LeetCode. Solve today's problem in the Flutter app's Quests tab.</p>
      </ComponentCard>

      {/* Component 3: Mock Exams */}
      <ComponentCard title="Mock Exam Performance" score={28} max={35} color="bg-illus-gold" delay={0.3}>
        <div className="overflow-x-auto">
          <table className="w-full mb-4">
            <thead>
              <tr className="border-b border-border-light">
                {['Exam', 'Date', 'Score', 'Weight', 'Contribution'].map(h => (
                  <th key={h} className="pb-3 text-[10px] font-bold text-text-muted uppercase text-left pr-4 first:pl-0">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {[
                { name: 'DS — Full Mock', date: 'Dec 15', score: 82, weight: '100%', contribution: 28.7 },
                { name: 'Python Mock', date: 'Nov 20', score: 67, weight: '100%', contribution: 23.45 },
                { name: 'DS — Mid Mock', date: 'Oct 10', score: 91, weight: '70%', contribution: 31.85 },
                { name: 'Aptitude Q2', date: 'Sep 25', score: 72, weight: '40%', contribution: 28.8 },
                { name: 'Aptitude Q1', date: 'Sep 5', score: 54, weight: '40%', contribution: 21.6 },
              ].map((e, i) => (
                <tr key={i} className="border-b border-border-light last:border-0">
                  <td className="py-3 text-[13px] font-bold text-text-main pr-4">{e.name}</td>
                  <td className="py-3 text-[12px] text-text-muted pr-4">{e.date}</td>
                  <td className="py-3 text-[13px] font-bold text-text-main pr-4">{e.score}%</td>
                  <td className="py-3 text-[12px] text-text-muted pr-4">{e.weight}</td>
                  <td className="py-3 text-[13px] font-bold text-illus-gold">{e.contribution.toFixed(1)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <div className="p-4 bg-page-bg rounded-xl">
          <p className="text-[12px] font-bold text-text-muted mb-2">Decaying Weight Note</p>
          <p className="text-[12px] text-text-muted">Exams taken within 30 days: 100% weight · 1–3 months: 70% weight · 3–6 months: 40% weight. Recent performance matters more.</p>
        </div>
        <Link href="/student/exams" className="mt-3 flex items-center gap-1.5 text-[13px] font-bold text-primary-purple hover:underline">
          View Upcoming Exams <Award className="w-4 h-4" />
        </Link>
      </ComponentCard>

      {/* Component 4: Session Attendance */}
      <ComponentCard title="Placement Session Attendance" score={7} max={10} color="bg-deep-violet" delay={0.4}>
        <div className="grid grid-cols-3 gap-4">
          <div className="p-4 bg-page-bg rounded-xl">
            <p className="text-[11px] font-bold text-text-muted uppercase">Sessions Eligible</p>
            <p className="text-[24px] font-black text-text-main">14</p>
          </div>
          <div className="p-4 bg-page-bg rounded-xl">
            <p className="text-[11px] font-bold text-text-muted uppercase">Sessions Attended</p>
            <p className="text-[24px] font-black text-electric-blue">10</p>
          </div>
          <div className="p-4 bg-page-bg rounded-xl">
            <p className="text-[11px] font-bold text-text-muted uppercase">Attendance Rate</p>
            <p className="text-[24px] font-black text-text-main">71%</p>
          </div>
        </div>
        <p className="text-[11px] text-text-muted mt-3 flex items-center gap-1.5"><Info className="w-3.5 h-3.5" /> Marked by your Team Leader via the Flutter App. You cannot mark your own attendance here.</p>
      </ComponentCard>
    </div>
  );
}
