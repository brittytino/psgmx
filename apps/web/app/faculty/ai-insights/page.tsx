'use client';

import React from 'react';
import { motion } from 'framer-motion';
import { BrainCircuit, Calendar, ChevronDown, Users, Clock, Star, TrendingUp, ExternalLink, PenTool, Sparkles, MessageSquare, MoreVertical } from 'lucide-react';
import Link from 'next/link';

import { AnimatePresence } from 'framer-motion';

export default function FacultyAIInsightsDashboard() {
  const [timeframe, setTimeframe] = React.useState('This Week');
  const [dateRange, setDateRange] = React.useState({ start: '2025-05-09', end: '2025-05-16' });
  const [showDatePicker, setShowDatePicker] = React.useState(false);

  // Simulated dynamic data based on timeframe
  const stats = timeframe === 'This Week' ? [
    { title: 'Total AI Queries', value: '256', trend: '↑ 18% vs last week', color: "var(--primary-purple)", bg: 'bg-page-bg', icon: MessageSquare },
    { title: 'Unique Students', value: '128', trend: '↑ 15% vs last week', color: "var(--primary-purple)", bg: 'bg-page-bg', icon: Users },
    { title: 'Avg. Response Time', value: '2.3s', trend: '↓ 8% faster', color: "var(--deep-violet)", bg: 'bg-page-bg', icon: Clock },
    { title: 'Satisfaction Score', value: '4.7 / 5', trend: '↑ 6% vs last week', color: "var(--illus-gold)", bg: 'bg-white', icon: Star },
  ] : [
    { title: 'Total AI Queries', value: '1,024', trend: '↑ 24% vs last month', color: "var(--primary-purple)", bg: 'bg-page-bg', icon: MessageSquare },
    { title: 'Unique Students', value: '412', trend: '↑ 10% vs last month', color: "var(--primary-purple)", bg: 'bg-page-bg', icon: Users },
    { title: 'Avg. Response Time', value: '2.1s', trend: '↓ 12% faster', color: "var(--deep-violet)", bg: 'bg-page-bg', icon: Clock },
    { title: 'Satisfaction Score', value: '4.8 / 5', trend: '↑ 2% vs last month', color: "var(--illus-gold)", bg: 'bg-white', icon: Star },
  ];

  return (
    <div className="max-w-[1400px] mx-auto space-y-8 pb-8">
      
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div className="flex items-center gap-4">
          <div className="w-12 h-12 rounded-2xl bg-primary-purple flex items-center justify-center shadow-lg shadow-md shadow-primary-purple/10 shrink-0">
            <BrainCircuit className="w-6 h-6 text-white" />
          </div>
          <div>
            <motion.h1 
              initial={{ opacity: 0, y: -10 }}
              animate={{ opacity: 1, y: 0 }}
              className="text-[26px] font-bold text-text-main tracking-tight mb-0.5"
            >
              AI Senior Insights
            </motion.h1>
            <motion.p 
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 0.1 }}
              className="text-[14px] text-text-muted"
            >
              Track AI interactions, student queries, and mentorship impact.
            </motion.p>
          </div>
        </div>
        <div className="relative">
          <div onClick={() => setShowDatePicker(!showDatePicker)} className="flex items-center gap-2 px-4 py-3 bg-white border border-border-light rounded-xl text-[13px] font-bold text-text-main cursor-pointer hover:bg-page-bg shadow-sm shrink-0 transition-colors">
            <Calendar className="w-4 h-4 text-text-muted" />
            {new Date(dateRange.start).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })} – {new Date(dateRange.end).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })} <ChevronDown className={`w-4 h-4 ml-1 transition-transform ${showDatePicker ? 'rotate-180 text-primary-purple' : 'text-text-muted'}`} />
          </div>
          
          <AnimatePresence>
            {showDatePicker && (
              <>
                <div className="fixed inset-0 z-40" onClick={() => setShowDatePicker(false)}></div>
                <motion.div initial={{ opacity: 0, y: 10, scale: 0.95 }} animate={{ opacity: 1, y: 0, scale: 1 }} exit={{ opacity: 0, y: 10, scale: 0.95 }} className="absolute right-0 top-14 bg-white border border-border-light shadow-xl rounded-2xl p-4 z-50 w-[280px]">
                  <h4 className="text-[14px] font-bold text-text-main mb-3">Custom Date Range</h4>
                  <div className="space-y-3">
                    <div>
                      <label className="text-[11px] font-bold text-text-muted uppercase block mb-1">Start Date</label>
                      <input type="date" value={dateRange.start} onChange={(e) => setDateRange(prev => ({ ...prev, start: e.target.value }))} className="w-full border border-border-light rounded-lg px-3 py-2 text-[13px] font-semibold text-text-main outline-none focus:border-primary-purple" />
                    </div>
                    <div>
                      <label className="text-[11px] font-bold text-text-muted uppercase block mb-1">End Date</label>
                      <input type="date" value={dateRange.end} onChange={(e) => setDateRange(prev => ({ ...prev, end: e.target.value }))} className="w-full border border-border-light rounded-lg px-3 py-2 text-[13px] font-semibold text-text-main outline-none focus:border-primary-purple" />
                    </div>
                    <button onClick={() => setShowDatePicker(false)} className="w-full py-2 bg-primary-purple text-white text-[13px] font-bold rounded-lg mt-2">Apply</button>
                  </div>
                </motion.div>
              </>
            )}
          </AnimatePresence>
        </div>
      </div>

      {/* 4 Stat Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {stats.map((stat, i) => (
          <motion.div key={i} initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.1 * i }} className="bg-white rounded-[20px] p-6 shadow-[0_2px_12px_rgba(0,0,0,0.03)] border border-border-light relative overflow-hidden flex flex-col justify-between h-[140px]">
            <div className="flex justify-between items-start">
              <div className="flex items-center gap-3">
                <div className={`w-10 h-10 rounded-full ${stat.bg} flex items-center justify-center`}>
                  <stat.icon className="w-5 h-5" style={{ color: stat.color }} />
                </div>
                <p className="text-[12px] font-bold text-text-muted">{stat.title}</p>
              </div>
            </div>
            <div className="flex items-end justify-between mt-auto">
              <div>
                <h3 className="text-[32px] font-black text-text-main leading-none mb-2">{stat.value}</h3>
                <p className={`text-[11px] font-bold ${stat.trend.includes('↓') ? 'text-electric-blue' : 'text-electric-blue'}`}>{stat.trend}</p>
              </div>
              <div className="w-24 h-8">
                <svg viewBox="0 0 100 30" className="w-full h-full fill-none" style={{ stroke: stat.color }} strokeWidth="3" strokeLinecap="round" strokeLinejoin="round">
                  <path d={i === 0 ? "M0,25 C20,25 30,15 50,5 C70,15 80,5 100,0" : i === 1 ? "M0,20 C20,25 40,5 60,15 C80,25 90,10 100,5" : i === 2 ? "M0,5 C10,5 30,20 50,10 C70,0 80,25 100,10" : "M0,20 C20,10 40,25 60,15 C80,5 90,20 100,5"} />
                </svg>
              </div>
            </div>
          </motion.div>
        ))}
      </div>

      {/* Row 2: Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        {/* Area Chart: AI Queries Over Time */}
        <div className="lg:col-span-2 bg-white rounded-[20px] shadow-[0_2px_12px_rgba(0,0,0,0.02)] border border-border-light p-6">
          <div className="flex justify-between items-center mb-6">
            <h3 className="text-[16px] font-bold text-text-main">AI Queries Over Time</h3>
            <select value={timeframe} onChange={(e) => setTimeframe(e.target.value)} className="border border-border-light rounded-xl px-3 py-1.5 text-[11px] font-bold text-text-muted cursor-pointer hover:bg-page-bg outline-none focus:border-primary-purple bg-white">
              <option>This Week</option>
              <option>This Month</option>
            </select>
          </div>
          <div className="relative h-[250px] mt-4">
            {/* Y Axis */}
            <div className="absolute left-0 top-0 bottom-8 w-8 flex flex-col justify-between text-[11px] font-semibold text-text-muted">
              <span>100</span><span>80</span><span>60</span><span>40</span><span>20</span><span>0</span>
            </div>
            {/* Chart Area */}
            <div className="absolute left-10 right-0 top-2 bottom-8">
              {/* Horizontal Lines */}
              <div className="absolute inset-0 flex flex-col justify-between">
                {[...Array(6)].map((_, i) => (
                  <div key={i} className="w-full border-t border-[#F8F9FC] h-0"></div>
                ))}
              </div>
              {/* SVG Area Chart */}
              <svg viewBox="0 0 1000 200" preserveAspectRatio="none" className="absolute inset-0 w-full h-full overflow-visible">
                <defs>
                  <linearGradient id="gradient" x1="0%" y1="0%" x2="0%" y2="100%">
                    <stop offset="0%" stopColor="#6C3DFF" stopOpacity="0.2" />
                    <stop offset="100%" stopColor="#6C3DFF" stopOpacity="0" />
                  </linearGradient>
                </defs>
                <path d="M0,170 C100,160 150,140 250,145 C350,150 400,90 500,40 C600,-10 650,50 750,70 C850,90 900,80 1000,100 L1000,200 L0,200 Z" fill="url(#gradient)" />
                <path d="M0,170 C100,160 150,140 250,145 C350,150 400,90 500,40 C600,-10 650,50 750,70 C850,90 900,80 1000,100" fill="none" stroke="#6C3DFF" strokeWidth="4" />
                
                {/* Data Points */}
                <circle cx="0" cy="170" r="4" fill="white" stroke="#6C3DFF" strokeWidth="2" />
                <circle cx="250" cy="145" r="4" fill="white" stroke="#6C3DFF" strokeWidth="2" />
                <circle cx="500" cy="40" r="6" fill="#6C3DFF" stroke="white" strokeWidth="3" /> {/* Highlight point */}
                <circle cx="750" cy="70" r="4" fill="white" stroke="#6C3DFF" strokeWidth="2" />
                <circle cx="1000" cy="100" r="4" fill="white" stroke="#6C3DFF" strokeWidth="2" />
              </svg>
              
              {/* Tooltip Simulation */}
              <div className="absolute left-[50%] top-[40px] -translate-x-1/2 -translate-y-full mb-3 bg-white border border-border-light shadow-md rounded-xl px-3 py-2 text-center pointer-events-none z-10">
                <p className="text-[10px] font-bold text-text-muted mb-0.5">May 13, 2025</p>
                <p className="text-[12px] font-black text-primary-purple">78 Queries</p>
                {/* Arrow */}
                <div className="absolute -bottom-1.5 left-1/2 -translate-x-1/2 w-3 h-3 bg-white border-b border-r border-border-light rotate-45"></div>
              </div>
            </div>
            
            {/* X Axis */}
            <div className="absolute left-10 right-0 bottom-0 flex justify-between text-[11px] font-semibold text-text-muted">
              <span>May 9</span><span>May 10</span><span>May 11</span><span>May 12</span><span>May 13</span><span>May 14</span><span>May 15</span><span>May 16</span>
            </div>
          </div>
        </div>

        {/* Donut Chart: Top Query Topics */}
        <div className="bg-white rounded-[20px] shadow-[0_2px_12px_rgba(0,0,0,0.02)] border border-border-light p-6">
          <div className="flex justify-between items-center mb-6">
            <h3 className="text-[16px] font-bold text-text-main">Top Query Topics</h3>
            <select value={timeframe} onChange={(e) => setTimeframe(e.target.value)} className="border border-border-light rounded-xl px-3 py-1.5 text-[11px] font-bold text-text-muted cursor-pointer hover:bg-page-bg outline-none focus:border-primary-purple bg-white">
              <option>This Week</option>
              <option>This Month</option>
            </select>
          </div>
          
          <div className="flex flex-col items-center gap-6 mt-4">
            {/* SVG Donut */}
            <div className="relative w-[180px] h-[180px]">
              <svg viewBox="0 0 36 36" className="w-full h-full -rotate-90">
                <circle cx="18" cy="18" r="14" fill="none" className="stroke-[#F1F5F9]" strokeWidth="8"></circle>
                <circle cx="18" cy="18" r="14" fill="none" className="stroke-primary-purple" strokeWidth="8" strokeDasharray="42 100" strokeDashoffset="0"></circle>
                <circle cx="18" cy="18" r="14" fill="none" className="stroke-electric-blue" strokeWidth="8" strokeDasharray="24 100" strokeDashoffset="-42"></circle>
                <circle cx="18" cy="18" r="14" fill="none" className="stroke-[#06B6D4]" strokeWidth="8" strokeDasharray="16 100" strokeDashoffset="-66"></circle>
                <circle cx="18" cy="18" r="14" fill="none" className="stroke-illus-gold" strokeWidth="8" strokeDasharray="10 100" strokeDashoffset="-82"></circle>
                <circle cx="18" cy="18" r="14" fill="none" className="stroke-[#CBD5E1]" strokeWidth="8" strokeDasharray="8 100" strokeDashoffset="-92"></circle>
              </svg>
            </div>
            
            <div className="w-full space-y-2.5">
              {[
                { label: 'Programming Help', pct: '42%', color: 'bg-primary-purple' },
                { label: 'Debugging', pct: '24%', color: 'bg-electric-blue' },
                { label: 'Concept Explanation', pct: '16%', color: 'bg-primary-purple' },
                { label: 'Project Guidance', pct: '10%', color: 'bg-illus-gold' },
                { label: 'Others', pct: '8%', color: 'bg-[#CBD5E1]' },
              ].map((item, i) => (
                <div key={i} className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <div className={`w-2.5 h-2.5 rounded-full ${item.color}`}></div>
                    <span className="text-[12px] font-bold text-text-main">{item.label}</span>
                  </div>
                  <span className="text-[12px] font-bold text-text-muted">{item.pct}</span>
                </div>
              ))}
            </div>
          </div>
        </div>

      </div>

      {/* Row 3: 3 Columns */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        {/* Top Questions This Week */}
        <div className="bg-white rounded-[20px] shadow-[0_2px_12px_rgba(0,0,0,0.02)] border border-border-light p-6 flex flex-col">
          <h3 className="text-[16px] font-bold text-text-main mb-6">Top Questions This Week</h3>
          <div className="flex-1 space-y-4">
            {[
              { num: 1, title: 'How to optimize code in Python?', students: '23 students asked' },
              { num: 2, title: 'DBMS normalization types', students: '18 students asked' },
              { num: 3, title: 'OS deadlock detection', students: '15 students asked' },
              { num: 4, title: 'React useEffect infinite loop', students: '12 students asked' },
              { num: 5, title: 'Git merge vs rebase', students: '10 students asked' },
            ].map((q, i) => (
              <div key={i} className="flex items-center justify-between group cursor-pointer hover:bg-page-bg p-2 -mx-2 rounded-xl transition-colors">
                <div className="flex items-start gap-3">
                  <div className="w-6 h-6 rounded-md bg-white/40 backdrop-blur-md border border-white/20 text-primary-purple text-[11px] font-black flex items-center justify-center shrink-0">
                    {q.num}
                  </div>
                  <div>
                    <p className="text-[13px] font-bold text-text-main leading-snug group-hover:text-primary-purple transition-colors">{q.title}</p>
                    <p className="text-[11px] font-semibold text-text-muted">{q.students}</p>
                  </div>
                </div>
                <ExternalLink className="w-4 h-4 text-[#CBD5E1] opacity-0 group-hover:opacity-100 transition-opacity" />
              </div>
            ))}
          </div>
          <button className="mt-4 w-full py-3 bg-page-bg text-primary-purple rounded-[12px] text-[13px] font-bold flex items-center justify-center gap-2 hover:bg-page-bg transition-colors">
            View All Queries →
          </button>
        </div>

        {/* Query Intent Distribution */}
        <div className="bg-white rounded-[20px] shadow-[0_2px_12px_rgba(0,0,0,0.02)] border border-border-light p-6">
          <div className="flex justify-between items-center mb-6">
            <h3 className="text-[16px] font-bold text-text-main">Query Intent Distribution</h3>
            <MoreVertical className="w-4 h-4 text-text-muted cursor-pointer" />
          </div>
          <div className="space-y-6">
            {[
              { label: 'Get Help', pct: 48, color: 'bg-gradient-to-r from-primary-purple to-[#A78BFA]' },
              { label: 'Learn Concept', pct: 24, color: 'bg-gradient-to-r from-[#3B82F6] to-[#93C5FD]' },
              { label: 'Debug Issue', pct: 16, color: 'bg-gradient-to-r from-[#06B6D4] to-[#67E8F9]' },
              { label: 'Project Guidance', pct: 8, color: 'bg-gradient-to-r from-[#F59E0B] to-[#FCD34D]' },
              { label: 'Others', pct: 4, color: 'bg-gradient-to-r from-[#CBD5E1] to-[#E2E8F0]' },
            ].map((intent, i) => (
              <div key={i}>
                <div className="flex items-center justify-between mb-2">
                  <span className="text-[13px] font-bold text-text-main">{intent.label}</span>
                  <span className="text-[12px] font-bold text-text-muted">{intent.pct}%</span>
                </div>
                <div className="w-full h-2 bg-page-bg rounded-full overflow-hidden">
                  <div className={`h-full rounded-full ${intent.color}`} style={{ width: `${intent.pct}%` }}></div>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Recent AI Interactions */}
        <div className="bg-white rounded-[20px] shadow-[0_2px_12px_rgba(0,0,0,0.02)] border border-border-light p-6 flex flex-col">
          <h3 className="text-[16px] font-bold text-text-main mb-6">Recent AI Interactions</h3>
          <div className="flex-1 space-y-6">
            {[
              { student: '25MX301', tag: 'Programming Help', tagColor: 'bg-page-bg text-primary-purple', q: 'How to reverse a linked list in Java?', time: '2m ago' },
              { student: '25MX205', tag: 'Debugging', tagColor: 'bg-white text-electric-blue', q: 'Why is my loop not executing?', time: '15m ago' },
              { student: '25MX114', tag: 'Concept Explanation', tagColor: 'bg-page-bg text-electric-blue', q: 'Explain quick sort with example', time: '32m ago' },
              { student: '25MX402', tag: 'Project Guidance', tagColor: 'bg-white text-illus-gold', q: 'Help with FYP idea validation', time: '1h ago' },
            ].map((interaction, i) => (
              <div key={i} className="flex items-start justify-between">
                <div className="flex items-start gap-3">
                  <div className="relative">
                    <img src={`https://ui-avatars.com/api/?name=${interaction.student}&background=random`} alt="" className="w-8 h-8 rounded-full" />
                    <div className="absolute -bottom-1 -right-1 w-3 h-3 bg-primary-purple rounded-full border-2 border-white flex items-center justify-center"><BrainCircuit className="w-[8px] h-[8px] text-white" /></div>
                  </div>
                  <div>
                    <div className="flex items-center gap-2 mb-1">
                      <p className="text-[12px] font-bold text-text-main">{interaction.student}</p>
                      <span className={`px-2 py-0.5 rounded-[6px] text-[9px] font-bold ${interaction.tagColor}`}>{interaction.tag}</span>
                    </div>
                    <p className="text-[12px] text-text-muted">{interaction.q}</p>
                  </div>
                </div>
                <span className="text-[10px] font-semibold text-text-muted whitespace-nowrap">{interaction.time}</span>
              </div>
            ))}
          </div>
          <button className="mt-4 w-full py-3 bg-white/40 backdrop-blur-md border border-white/20 text-primary-purple rounded-[12px] text-[13px] font-bold flex items-center justify-center gap-2 hover:bg-page-bg transition-colors">
            View All Interactions →
          </button>
        </div>

      </div>

      {/* Bottom Banner */}
      <div className="w-full bg-white/40 backdrop-blur-md border border-white/20 rounded-[20px] p-6 border border-primary-purple/20 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div className="flex items-center gap-4">
          <div className="w-12 h-12 rounded-[14px] bg-white flex items-center justify-center shadow-sm">
            <Sparkles className="w-6 h-6 text-primary-purple" />
          </div>
          <div>
            <h4 className="text-[15px] font-bold text-primary-purple mb-1">Insight of the Week</h4>
            <p className="text-[13px] text-text-muted font-medium">Students are asking more programming and debugging questions this week. Consider creating a guide on "Python Optimization".</p>
          </div>
        </div>
        <button className="px-5 py-2.5 bg-[#C4B5FD] text-white hover:bg-[#A78BFA] transition-colors rounded-[12px] text-[13px] font-bold shadow-sm flex items-center gap-2 whitespace-nowrap">
          <PenTool className="w-4 h-4" /> Create Guide
        </button>
      </div>

    </div>
  );
}
