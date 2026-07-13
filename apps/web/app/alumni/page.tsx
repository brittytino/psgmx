'use client';

import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Award, PenLine, Users, Briefcase, BookOpen, ArrowRight, ToggleLeft, ToggleRight, Calendar, FileText, TrendingUp } from 'lucide-react';
import Link from 'next/link';

const myArticles = [
  { title: 'How I cracked Zoho\'s 5-round process', status: 'APPROVED', views: 243, date: 'Mar 2025' },
  { title: 'My 2-Year MCA Preparation Strategy', status: 'APPROVED', views: 421, date: 'Feb 2025' },
  { title: 'SQL Queries That Actually Appear in Interviews', status: 'PENDING', views: 0, date: 'Jan 2025' },
];

const activityFeed = [
  { text: 'Zoho Corporation campus drive logged for Feb 5, 2025', time: '2 hours ago', icon: Briefcase },
  { text: 'New article approved: "TCS NQT Deep Dive" by Arjun Pillai', time: '5 hours ago', icon: BookOpen },
  { text: 'Mock exam scheduled for batch 25MX — DS Full Mock', time: '1 day ago', icon: Award },
];

export default function AlumniDashboard() {
  const [mentorshipActive, setMentorshipActive] = useState(true);

  return (
    <div className="max-w-[1400px] mx-auto space-y-8 pb-8">

      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <motion.h1 initial={{ opacity: 0, y: -10 }} animate={{ opacity: 1, y: 0 }} className="text-[26px] font-bold text-text-main tracking-tight mb-1">
            Welcome back, Riya 👋
          </motion.h1>
          <motion.p initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: 0.1 }} className="text-[14px] text-text-muted">
            Class of 23MX · Alumni Dashboard
          </motion.p>
        </div>
        <div className="flex items-center gap-3 bg-white border border-border-light rounded-2xl px-5 py-3 shadow-sm shrink-0">
          <Calendar className="w-5 h-5 text-text-muted" />
          <div>
            <p className="text-[13px] font-bold text-text-main">{new Date().toLocaleDateString('en-IN', { month: 'long', day: 'numeric', year: 'numeric' })}</p>
            <p className="text-[11px] font-semibold text-text-muted">{new Date().toLocaleDateString('en-IN', { weekday: 'long' })}</p>
          </div>
        </div>
      </div>

      {/* 4 Stat Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {[
          { title: 'Final Readiness Score', value: '88', sub: 'Batch 23MX · Graduated', icon: Award, color: 'bg-primary-purple', spark: 'M0,25 C20,20 40,10 60,8 C80,6 90,3 100,2' },
          { title: 'Articles Contributed', value: '3', sub: '↑ 664 total reads', icon: PenLine, color: 'bg-electric-blue', spark: 'M0,22 C20,18 40,12 60,14 C80,16 90,8 100,5' },
          { title: 'Mentorship Status', value: mentorshipActive ? 'Active' : 'Off', sub: 'Your junior: 25MX301', icon: Users, color: mentorshipActive ? 'bg-electric-blue' : 'bg-border-light', spark: 'M0,15 C20,15 40,15 60,15 C80,15 90,15 100,15' },
          { title: 'Students in Lineage', value: '4', sub: '1 active junior', icon: Users, color: 'bg-illus-gold', spark: 'M0,25 C25,20 50,15 75,15 C90,15 95,12 100,10' },
        ].map((c, i) => (
          <motion.div key={i} initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.1 }} className="bg-white rounded-[20px] p-6 shadow-[0_2px_12px_rgba(0,0,0,0.03)] border border-border-light flex flex-col justify-between h-[140px]">
            <div className="flex items-center gap-3">
              <div className={`w-10 h-10 rounded-full ${c.color} flex items-center justify-center shadow-sm`}>
                <c.icon className="w-5 h-5 text-white" />
              </div>
              <p className="text-[12px] font-bold text-text-muted">{c.title}</p>
            </div>
            <div className="flex items-end justify-between">
              <div>
                <h3 className="text-[28px] font-black text-text-main leading-none">{c.value}</h3>
                <p className="text-[11px] text-text-muted mt-1">{c.sub}</p>
              </div>
              <svg viewBox="0 0 100 30" className="w-20 h-7 fill-none stroke-primary-purple" strokeWidth="3" strokeLinecap="round">
                <path d={c.spark} />
              </svg>
            </div>
          </motion.div>
        ))}
      </div>

      {/* Main Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">

        {/* Left: 2/3 */}
        <div className="lg:col-span-2 space-y-6">

          {/* Knowledge Contributions */}
          <div className="bg-white rounded-[20px] border border-border-light shadow-[0_2px_12px_rgba(0,0,0,0.02)]">
            <div className="p-6 border-b border-page-bg flex justify-between items-center">
              <div className="flex items-center gap-2">
                <BookOpen className="w-5 h-5 text-primary-purple" />
                <h3 className="text-[16px] font-bold text-text-main">Your Knowledge Contributions</h3>
              </div>
              <Link href="/alumni/contribute" className="flex items-center gap-2 px-4 py-2 bg-primary-purple text-white rounded-xl text-[12px] font-bold hover:bg-deep-violet transition-colors">
                <PenLine className="w-3.5 h-3.5" /> Write Article
              </Link>
            </div>
            <div className="p-6 space-y-3">
              {myArticles.map((a, i) => (
                <div key={i} className="flex items-center justify-between p-4 rounded-[16px] border border-border-light hover:border-primary-purple/30 transition-colors">
                  <div className="flex items-center gap-4">
                    <div className="w-10 h-10 rounded-[10px] bg-page-bg flex items-center justify-center shrink-0">
                      <FileText className="w-4 h-4 text-primary-purple" />
                    </div>
                    <div>
                      <h4 className="text-[14px] font-bold text-text-main">{a.title}</h4>
                      <p className="text-[11px] text-text-muted">{a.date} {a.views > 0 && `· ${a.views} reads`}</p>
                    </div>
                  </div>
                  <span className={`text-[10px] font-bold px-2.5 py-1 rounded-full shrink-0 ${
                    a.status === 'APPROVED' ? 'bg-electric-blue/10 text-electric-blue' : 'bg-illus-gold/10 text-illus-gold'
                  }`}>{a.status}</span>
                </div>
              ))}
              <Link href="/alumni/contribute" className="w-full py-3.5 bg-white/40 backdrop-blur-md border border-white/20 text-primary-purple rounded-[12px] text-[13px] font-bold flex items-center justify-center gap-2 hover:bg-page-bg transition-colors">
                View All Contributions <ArrowRight className="w-4 h-4" />
              </Link>
            </div>
          </div>

          {/* Impact Banner */}
          <div className="bg-gradient-to-r from-primary-purple to-deep-violet rounded-[20px] p-6 flex items-center gap-6">
            <TrendingUp className="w-10 h-10 text-white/60 shrink-0" />
            <div>
              <h3 className="text-[16px] font-bold text-white">Your 3 articles were surfaced by the AI Senior <span className="font-black">87 times</span> this month.</h3>
              <p className="text-[13px] text-white/80 mt-1">200+ students read your placement experience. Your words are actively helping juniors right now.</p>
            </div>
          </div>

          {/* Department Activity Feed */}
          <div className="bg-white rounded-[20px] border border-border-light shadow-[0_2px_12px_rgba(0,0,0,0.02)] p-6">
            <h3 className="text-[16px] font-bold text-text-main mb-5">Department Activity</h3>
            <div className="space-y-4">
              {activityFeed.map((a, i) => (
                <div key={i} className="flex items-start gap-3">
                  <div className="w-8 h-8 rounded-full bg-page-bg flex items-center justify-center shrink-0">
                    <a.icon className="w-4 h-4 text-primary-purple" />
                  </div>
                  <div>
                    <p className="text-[13px] font-semibold text-text-main">{a.text}</p>
                    <p className="text-[11px] text-text-muted mt-0.5">{a.time}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Right: 1/3 */}
        <div className="space-y-6">

          {/* Mentorship Toggle Card */}
          <div className="bg-white rounded-[20px] border border-border-light shadow-[0_2px_12px_rgba(0,0,0,0.02)] p-6">
            <div className="flex items-center gap-2 mb-5">
              <Users className="w-5 h-5 text-primary-purple" />
              <h3 className="text-[14px] font-bold text-text-main">Mentorship</h3>
            </div>
            <div className="flex items-center justify-between p-4 bg-page-bg rounded-xl mb-4">
              <span className="text-[13px] font-bold text-text-main">Available for Mentorship</span>
              <button onClick={() => setMentorshipActive(!mentorshipActive)} className="transition-transform active:scale-95">
                {mentorshipActive
                  ? <ToggleRight className="w-9 h-9 text-electric-blue" />
                  : <ToggleLeft className="w-9 h-9 text-border-light" />}
              </button>
            </div>
            {mentorshipActive && (
              <motion.div initial={{ opacity: 0, y: -5 }} animate={{ opacity: 1, y: 0 }} className="p-4 bg-electric-blue/5 border border-electric-blue/20 rounded-xl">
                <p className="text-[12px] font-bold text-electric-blue mb-2">Your junior can now see you!</p>
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-full bg-gradient-to-br from-primary-purple to-deep-violet flex items-center justify-center text-white font-black text-sm">S</div>
                  <div>
                    <p className="text-[13px] font-bold text-text-main">25MX301</p>
                    <p className="text-[11px] text-text-muted">Batch 2025 · Active Student</p>
                  </div>
                </div>
                <Link href="/alumni/lineage" className="mt-3 flex items-center gap-1.5 text-[12px] font-bold text-primary-purple hover:underline">
                  View Lineage <ArrowRight className="w-3.5 h-3.5" />
                </Link>
              </motion.div>
            )}
          </div>

          {/* Batch Summary */}
          <div className="bg-white rounded-[20px] border border-border-light shadow-[0_2px_12px_rgba(0,0,0,0.02)] p-6">
            <div className="flex items-center gap-2 mb-4">
              <Award className="w-5 h-5 text-primary-purple" />
              <h3 className="text-[14px] font-bold text-text-main">Your Batch Summary</h3>
            </div>
            <div className="text-center mb-4">
              <div className="relative w-20 h-20 mx-auto">
                <svg viewBox="0 0 100 100" className="w-full h-full -rotate-90">
                  <circle cx="50" cy="50" r="44" fill="none" stroke="#EFE9E0" strokeWidth="10" />
                  <circle cx="50" cy="50" r="44" fill="none" stroke="var(--primary-purple)" strokeWidth="10" strokeLinecap="round" strokeDasharray="243 276.46" />
                </svg>
                <div className="absolute inset-0 flex items-center justify-center">
                  <span className="text-[18px] font-black text-text-main">88</span>
                </div>
              </div>
              <p className="text-[11px] font-bold text-text-muted mt-2 uppercase">Final Readiness · STRONG</p>
            </div>
            <div className="space-y-2">
              {[
                { label: 'Best Streak', value: '47 days' },
                { label: 'LeetCode (batch)', value: '147 problems' },
                { label: 'Exams taken', value: '9 exams' },
                { label: 'Graduated', value: 'June 2025' },
              ].map((s, i) => (
                <div key={i} className="flex justify-between text-[12px]">
                  <span className="text-text-muted">{s.label}</span>
                  <span className="font-bold text-text-main">{s.value}</span>
                </div>
              ))}
            </div>
            <Link href="/alumni/journey" className="mt-4 w-full py-2.5 bg-page-bg text-primary-purple rounded-xl text-[13px] font-bold flex items-center justify-center gap-2 hover:bg-border-light transition-colors">
              View Full Journey <ArrowRight className="w-4 h-4" />
            </Link>
          </div>

          {/* Marketplace Quick */}
          <div className="bg-white rounded-[20px] border border-border-light shadow-[0_2px_12px_rgba(0,0,0,0.02)] p-6">
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-2">
                <Briefcase className="w-5 h-5 text-primary-purple" />
                <h3 className="text-[14px] font-bold text-text-main">Marketplace</h3>
              </div>
              <Link href="/alumni/marketplace" className="text-[12px] font-bold text-primary-purple hover:underline">View All</Link>
            </div>
            <button className="w-full py-3 bg-primary-purple text-white rounded-xl text-[13px] font-bold hover:bg-deep-violet transition-colors">
              + Post an Opportunity
            </button>
            <p className="text-[11px] text-text-muted mt-3 text-center">Jobs · Internships · Collaborations · Events</p>
          </div>
        </div>
      </div>
    </div>
  );
}
