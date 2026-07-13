'use client';

import React from 'react';
import { motion } from 'framer-motion';
import { Users, BookOpen, Target, ClipboardList, FileText, Calendar, ChevronRight, ChevronDown, ArrowRight } from 'lucide-react';
import Link from 'next/link';

import { AnimatePresence } from 'framer-motion';

export default function FacultyDashboardHome() {
  const [reviewQueue, setReviewQueue] = React.useState([
    { id: 1, title: 'Dynamic Programming – Problem Solving Guide', author: '25MX301', time: '2 hours ago' },
    { id: 2, title: 'Database Normalization – Quick Notes', author: '25MX205', time: '5 hours ago' },
    { id: 3, title: 'Operating Systems – Important Concepts', author: '25MX114', time: '1 day ago' },
  ]);

  const [toastMessage, setToastMessage] = React.useState('');

  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(''), 3000);
  };

  const handleReviewAction = (id: number, action: 'Approve' | 'Reject') => {
    setReviewQueue(prev => prev.filter(item => item.id !== id));
    showToast(`Article ${action}d successfully`);
  };

  return (
    <div className="max-w-[1400px] mx-auto space-y-8 pb-8 relative">
      <AnimatePresence>
        {toastMessage && (
          <motion.div initial={{ opacity: 0, y: 50 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: 50 }} className="fixed bottom-8 left-1/2 -translate-x-1/2 z-50 bg-rich-black text-white px-6 py-3 rounded-xl shadow-xl flex items-center gap-3">
            <div className="w-2 h-2 rounded-full bg-electric-blue"></div>
            <span className="text-[13px] font-bold">{toastMessage}</span>
          </motion.div>
        )}
      </AnimatePresence>
      
      {/* Header & Date */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <motion.h1 
            initial={{ opacity: 0, y: -10 }}
            animate={{ opacity: 1, y: 0 }}
            className="text-[26px] font-bold text-text-main tracking-tight mb-1"
          >
            Welcome back, Dr. Arunkumar <span className="inline-block animate-wave">👋</span>
          </motion.h1>
          <motion.p 
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.1 }}
            className="text-[14px] text-text-muted"
          >
            Here's what's happening in the MCA Department today.
          </motion.p>
        </div>
        <div className="flex items-center gap-3 bg-white border border-border-light rounded-2xl px-5 py-3 shadow-sm shrink-0">
          <Calendar className="w-5 h-5 text-text-muted" />
          <div>
            <p className="text-[13px] font-bold text-text-main">May 16, 2025</p>
            <p className="text-[11px] font-semibold text-text-muted">Friday</p>
          </div>
        </div>
      </div>

      {/* 4 Stat Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {/* Card 1 */}
        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.1 }} className="bg-white rounded-[20px] p-6 shadow-[0_2px_12px_rgba(0,0,0,0.03)] border border-border-light relative overflow-hidden flex flex-col justify-between h-[140px]">
          <div className="flex justify-between items-start">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-primary-purple flex items-center justify-center shadow-md shadow-md shadow-primary-purple/10">
                <Users className="w-5 h-5 text-white" />
              </div>
              <p className="text-[12px] font-bold text-text-muted">Mentored Students</p>
            </div>
          </div>
          <div className="flex items-end justify-between mt-auto">
            <div>
              <h3 className="text-[32px] font-black text-text-main leading-none mb-2">24</h3>
              <p className="text-[11px] font-bold text-electric-blue">↑ 12% this month</p>
            </div>
            {/* Fake Sparkline SVG */}
            <div className="w-24 h-8">
              <svg viewBox="0 0 100 30" className="w-full h-full stroke-primary-purple fill-none" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round">
                <path d="M0,25 C20,25 30,15 50,15 C70,15 80,5 100,5" />
              </svg>
            </div>
          </div>
        </motion.div>

        {/* Card 2 */}
        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.2 }} className="bg-white rounded-[20px] p-6 shadow-[0_2px_12px_rgba(0,0,0,0.03)] border border-border-light relative overflow-hidden flex flex-col justify-between h-[140px]">
          <div className="flex justify-between items-start">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-primary-purple flex items-center justify-center shadow-md shadow-[#06B6D4]/20">
                <BookOpen className="w-5 h-5 text-white" />
              </div>
              <p className="text-[12px] font-bold text-text-muted">Knowledge Approvals</p>
            </div>
          </div>
          <div className="flex items-end justify-between mt-auto">
            <div>
              <h3 className="text-[32px] font-black text-text-main leading-none mb-2">8</h3>
              <p className="text-[11px] font-bold text-electric-blue">↑ 33% this month</p>
            </div>
            <div className="w-24 h-8">
              <svg viewBox="0 0 100 30" className="w-full h-full stroke-[#06B6D4] fill-none" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round">
                <path d="M0,20 C20,25 40,5 60,15 C80,25 90,10 100,5" />
              </svg>
            </div>
          </div>
        </motion.div>

        {/* Card 3 */}
        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.3 }} className="bg-white rounded-[20px] p-6 shadow-[0_2px_12px_rgba(0,0,0,0.03)] border border-border-light relative overflow-hidden flex flex-col justify-between h-[140px]">
          <div className="flex justify-between items-start">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-deep-violet flex items-center justify-center shadow-md shadow-[#F43F5E]/20">
                <Target className="w-5 h-5 text-white" />
              </div>
              <p className="text-[12px] font-bold text-text-muted">AI Queries Handled</p>
            </div>
          </div>
          <div className="flex items-end justify-between mt-auto">
            <div>
              <h3 className="text-[32px] font-black text-text-main leading-none mb-2">156</h3>
              <p className="text-[11px] font-bold text-electric-blue">↑ 18% this week</p>
            </div>
            <div className="w-24 h-8">
              <svg viewBox="0 0 100 30" className="w-full h-full stroke-deep-violet fill-none" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round">
                <path d="M0,25 C10,25 30,10 50,20 C70,30 80,5 100,5" />
              </svg>
            </div>
          </div>
        </motion.div>

        {/* Card 4 */}
        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.4 }} className="bg-white rounded-[20px] p-6 shadow-[0_2px_12px_rgba(0,0,0,0.03)] border border-border-light relative overflow-hidden flex flex-col justify-between h-[140px]">
          <div className="flex justify-between items-start">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-illus-gold flex items-center justify-center shadow-md shadow-[#F59E0B]/20">
                <ClipboardList className="w-5 h-5 text-white" />
              </div>
              <p className="text-[12px] font-bold text-text-muted">Pending Actions</p>
            </div>
          </div>
          <div className="flex items-end justify-between mt-auto">
            <div>
              <h3 className="text-[32px] font-black text-text-main leading-none mb-2">6</h3>
              <Link href="/faculty" className="text-[11px] font-bold text-primary-purple hover:underline">View all tasks</Link>
            </div>
            <div className="w-24 h-8">
              <svg viewBox="0 0 100 30" className="w-full h-full stroke-illus-gold fill-none" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round">
                <path d="M0,20 C20,10 40,25 60,15 C80,5 90,20 100,10" />
              </svg>
            </div>
          </div>
        </motion.div>
      </div>

      {/* Row 2: Knowledge Brain & Upcoming Deadlines */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        {/* Knowledge Brain Review Queue */}
        <div className="lg:col-span-2 bg-white rounded-[20px] border border-border-light shadow-[0_2px_12px_rgba(0,0,0,0.02)] flex flex-col">
          <div className="p-6 border-b border-[#F8F9FC] flex justify-between items-center">
            <div className="flex items-center gap-2">
              <BookOpen className="w-5 h-5 text-primary-purple" />
              <h3 className="text-[16px] font-bold text-text-main">Knowledge Brain – Review Queue</h3>
            </div>
            <span className="text-[13px] font-bold text-primary-purple">{reviewQueue.length} Pending</span>
          </div>
          <div className="p-6 flex-1 flex flex-col gap-4">
            <AnimatePresence>
              {reviewQueue.length === 0 ? (
                <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="flex-1 flex items-center justify-center text-[13px] font-semibold text-text-muted py-8">
                  All caught up! No pending reviews.
                </motion.div>
              ) : (
                reviewQueue.map((item) => (
                  <motion.div 
                    key={item.id}
                    initial={{ opacity: 0, height: 0, scale: 0.95 }}
                    animate={{ opacity: 1, height: 'auto', scale: 1 }}
                    exit={{ opacity: 0, height: 0, scale: 0.95, overflow: 'hidden', padding: 0, margin: 0 }}
                    transition={{ duration: 0.2 }}
                    className="flex items-center justify-between p-4 rounded-[16px] border border-border-light hover:border-border-light transition-colors"
                  >
                    <div className="flex items-center gap-4">
                      <div className="w-12 h-12 rounded-[12px] bg-white/40 backdrop-blur-md border border-white/20 flex items-center justify-center shrink-0">
                        <FileText className="w-5 h-5 text-primary-purple" />
                      </div>
                      <div>
                        <h4 className="text-[14px] font-bold text-text-main mb-0.5">{item.title}</h4>
                        <p className="text-[11px] font-semibold text-text-muted">
                          AI Generated • By {item.author} • {item.time}
                        </p>
                      </div>
                    </div>
                    <div className="flex items-center gap-2 shrink-0">
                      <button onClick={() => handleReviewAction(item.id, 'Approve')} className="px-5 py-2.5 bg-primary-purple text-white rounded-[10px] text-[13px] font-bold hover:bg-[#5B21B6] transition-colors shadow-sm">Approve</button>
                      <button onClick={() => handleReviewAction(item.id, 'Reject')} className="px-5 py-2.5 bg-white border border-border-light text-text-muted rounded-[10px] text-[13px] font-bold hover:bg-page-bg hover:text-text-main transition-colors shadow-sm">Reject</button>
                    </div>
                  </motion.div>
                ))
              )}
            </AnimatePresence>
            <Link href="/faculty/knowledge-brain" className="mt-2 w-full py-3.5 bg-white/40 backdrop-blur-md border border-white/20 text-primary-purple rounded-[12px] text-[13px] font-bold flex items-center justify-center gap-2 hover:bg-page-bg transition-colors">
              View All Pending Articles <ArrowRight className="w-4 h-4" />
            </Link>
          </div>
        </div>

        {/* Upcoming Deadlines */}
        <div className="bg-white rounded-[20px] border border-border-light shadow-[0_2px_12px_rgba(0,0,0,0.02)] flex flex-col">
          <div className="p-6 border-b border-[#F8F9FC] flex items-center gap-2">
            <Calendar className="w-5 h-5 text-primary-purple" />
            <h3 className="text-[16px] font-bold text-text-main">Upcoming Deadlines</h3>
          </div>
          <div className="p-6 flex-1 flex flex-col gap-4">
            {[
              { title: 'FYP Phase 2 Review', date: 'May 20, 2025' },
              { title: 'Mini Project Evaluation', date: 'May 23, 2025' },
              { title: 'Internal Assessment', date: 'May 30, 2025' },
            ].map((item, i) => (
              <div key={i} className="flex items-center gap-4 p-4 rounded-[16px] border border-border-light hover:border-border-light transition-colors">
                <div className="w-12 h-12 rounded-[12px] bg-white flex items-center justify-center shrink-0">
                  <Calendar className="w-5 h-5 text-electric-blue" />
                </div>
                <div>
                  <h4 className="text-[14px] font-bold text-text-main mb-0.5">{item.title}</h4>
                  <p className="text-[12px] font-semibold text-text-muted">{item.date}</p>
                </div>
              </div>
            ))}
            <div className="mt-auto pt-2 flex justify-center">
              <Link href="/faculty" className="text-[13px] font-bold text-primary-purple hover:underline flex items-center gap-1.5">
                View Calendar <ArrowRight className="w-4 h-4" />
              </Link>
            </div>
          </div>
        </div>

      </div>

      {/* Row 3: FYP Overview, Mentorship Activities, AI Senior Queries */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        {/* FYP Overview */}
        <div className="bg-white rounded-[20px] border border-border-light shadow-[0_2px_12px_rgba(0,0,0,0.02)] p-6">
          <div className="flex justify-between items-center mb-8">
            <div className="flex items-center gap-2">
              <ClipboardList className="w-5 h-5 text-primary-purple" />
              <h3 className="text-[16px] font-bold text-text-main">FYP Overview</h3>
            </div>
            <Link href="/faculty/fyp-repository" className="text-[12px] font-bold text-primary-purple flex items-center gap-1">View All <ArrowRight className="w-3.5 h-3.5" /></Link>
          </div>
          
          <div className="flex items-center gap-8">
            {/* Fake Donut Chart via CSS SVG */}
            <div className="relative w-32 h-32 shrink-0">
              <svg viewBox="0 0 36 36" className="w-full h-full -rotate-90">
                {/* Background */}
                <circle cx="18" cy="18" r="16" fill="none" className="stroke-[#F1F5F9]" strokeWidth="4"></circle>
                {/* Active (Purple 56%) */}
                <circle cx="18" cy="18" r="16" fill="none" className="stroke-primary-purple" strokeWidth="4" strokeDasharray="56 100" strokeDashoffset="0"></circle>
                {/* Review (Blue 22%) */}
                <circle cx="18" cy="18" r="16" fill="none" className="stroke-electric-blue" strokeWidth="4" strokeDasharray="22 100" strokeDashoffset="-56"></circle>
                {/* Completed (Green 22%) */}
                <circle cx="18" cy="18" r="16" fill="none" className="stroke-electric-blue" strokeWidth="4" strokeDasharray="22 100" strokeDashoffset="-78"></circle>
              </svg>
              <div className="absolute inset-0 flex flex-col items-center justify-center">
                <span className="text-[22px] font-black text-text-main leading-none">32</span>
                <span className="text-[9px] font-bold text-text-muted uppercase">Total Projects</span>
              </div>
            </div>
            
            <div className="flex-1 space-y-4">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2"><div className="w-2.5 h-2.5 rounded-full bg-primary-purple"></div><span className="text-[13px] font-bold text-text-main">Active</span></div>
                <div className="text-[13px] text-text-muted font-semibold">18 (56%)</div>
              </div>
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2"><div className="w-2.5 h-2.5 rounded-full bg-electric-blue"></div><span className="text-[13px] font-bold text-text-main">Review</span></div>
                <div className="text-[13px] text-text-muted font-semibold">7 (22%)</div>
              </div>
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2"><div className="w-2.5 h-2.5 rounded-full bg-electric-blue"></div><span className="text-[13px] font-bold text-text-main">Completed</span></div>
                <div className="text-[13px] text-text-muted font-semibold">7 (22%)</div>
              </div>
            </div>
          </div>
        </div>

        {/* Recent Mentorship Activities */}
        <div className="bg-white rounded-[20px] border border-border-light shadow-[0_2px_12px_rgba(0,0,0,0.02)] p-6 flex flex-col">
          <div className="flex items-center gap-2 mb-6">
            <Users className="w-5 h-5 text-primary-purple" />
            <h3 className="text-[16px] font-bold text-text-main">Recent Mentorship Activities</h3>
          </div>
          
          <div className="flex-1 space-y-5">
            {[
              { action: 'Guided 25MX301 on Dynamic Programming', time: '2 hours ago', bg: 'bg-[#C4B5FD]' },
              { action: 'Reviewed project report for 25MX114', time: '5 hours ago', bg: 'bg-[#93C5FD]' },
              { action: 'Mentorship session with 25MX205', time: '1 day ago', bg: 'bg-[#FCA5A5]' },
            ].map((item, i) => (
              <div key={i} className="flex items-start gap-3">
                <div className={`w-8 h-8 rounded-full ${item.bg} border-2 border-white shadow-sm shrink-0 flex items-center justify-center text-white text-[10px] font-bold overflow-hidden`}>
                  {/* Generic avatar simulation */}
                  <img src="https://ui-avatars.com/api/?name=Student&background=random&color=fff" alt="Avatar" className="w-full h-full object-cover" />
                </div>
                <div>
                  <p className="text-[13px] font-bold text-text-main leading-snug">{item.action}</p>
                  <p className="text-[11px] font-semibold text-text-muted mt-0.5">{item.time}</p>
                </div>
              </div>
            ))}
          </div>
          
          <Link href="/faculty/mentorship" className="mt-4 w-full py-3.5 bg-page-bg text-primary-purple rounded-[12px] text-[13px] font-bold flex items-center justify-center gap-2 hover:bg-page-bg transition-colors">
            View All Activities <ArrowRight className="w-4 h-4" />
          </Link>
        </div>

        {/* AI Senior - Top Queries */}
        <div className="bg-white rounded-[20px] border border-border-light shadow-[0_2px_12px_rgba(0,0,0,0.02)] p-6 flex flex-col">
          <div className="flex justify-between items-center mb-6">
            <div className="flex items-center gap-2">
              <Users className="w-5 h-5 text-deep-violet" />
              <h3 className="text-[16px] font-bold text-text-main">AI Senior – Top Queries</h3>
            </div>
            <div className="flex items-center gap-1 text-[11px] font-bold text-text-muted border border-border-light px-2 py-1 rounded-lg cursor-pointer hover:bg-page-bg">
              This Week <ChevronDown className="w-3 h-3" />
            </div>
          </div>
          
          <div className="flex-1 space-y-5">
            {[
              { num: 1, title: 'How to optimize code in Python?', queries: '18 queries' },
              { num: 2, title: 'DBMS normalization types', queries: '14 queries' },
              { num: 3, title: 'OS deadlock detection', queries: '11 queries' },
            ].map((item, i) => (
              <div key={i} className="flex items-start gap-3">
                <div className="w-7 h-7 rounded-full bg-page-bg text-primary-purple text-[12px] font-black flex items-center justify-center shrink-0">
                  {item.num}
                </div>
                <div>
                  <p className="text-[13px] font-bold text-text-main leading-snug">{item.title}</p>
                  <p className="text-[11px] font-semibold text-text-muted mt-0.5">{item.queries}</p>
                </div>
              </div>
            ))}
          </div>
          
          <div className="mt-auto pt-4 flex justify-center">
            <Link href="/faculty/ai-insights" className="text-[13px] font-bold text-primary-purple hover:underline flex items-center gap-1.5">
              View All Insights <ArrowRight className="w-4 h-4" />
            </Link>
          </div>
        </div>

      </div>
    </div>
  );
}
