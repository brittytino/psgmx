'use client';

import React from 'react';
import { motion } from 'framer-motion';
import { BarChart2, Calendar, ChevronDown, Download, Users, FolderOpen, CheckCircle2, Star, TrendingUp, Trophy } from 'lucide-react';
import Link from 'next/link';

import { AnimatePresence } from 'framer-motion';

export default function FacultyAnalyticsDashboard() {
  const [timeframe, setTimeframe] = React.useState('This Semester');
  const [dateRange, setDateRange] = React.useState({ start: '2025-05-12', end: '2025-06-12' });
  const [showDatePicker, setShowDatePicker] = React.useState(false);
  const [toastMessage, setToastMessage] = React.useState('');

  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(''), 3000);
  };

  const stats = timeframe === 'This Semester' ? [
    { title: 'Active Students', value: '142', trend: '↑ 12% from last 30 days', color: '#6C3DFF', bg: 'bg-[#F5F3FF]', icon: GraduationCapIcon },
    { title: 'Active Projects', value: '28', trend: '↑ 15% from last 30 days', color: '#3B82F6', bg: 'bg-[#EFF6FF]', icon: FolderOpen },
    { title: 'Projects Completed', value: '23', trend: '↑ 18% from last 30 days', color: '#10B981', bg: 'bg-[#ECFDF5]', icon: CheckCircle2 },
    { title: 'Avg. Progress', value: '68%', trend: '↑ 9% from last 30 days', color: '#F59E0B', bg: 'bg-[#FFFBEB]', icon: Star },
  ] : [
    { title: 'Active Students', value: '135', trend: '↑ 5% from previous', color: '#6C3DFF', bg: 'bg-[#F5F3FF]', icon: GraduationCapIcon },
    { title: 'Active Projects', value: '35', trend: '↑ 8% from previous', color: '#3B82F6', bg: 'bg-[#EFF6FF]', icon: FolderOpen },
    { title: 'Projects Completed', value: '32', trend: '↑ 10% from previous', color: '#10B981', bg: 'bg-[#ECFDF5]', icon: CheckCircle2 },
    { title: 'Avg. Progress', value: '85%', trend: '↑ 15% from previous', color: '#F59E0B', bg: 'bg-[#FFFBEB]', icon: Star },
  ];

  return (
    <div className="max-w-[1400px] mx-auto space-y-8 pb-8 relative">
      <AnimatePresence>
        {toastMessage && (
          <motion.div initial={{ opacity: 0, y: 50 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: 50 }} className="fixed bottom-8 left-1/2 -translate-x-1/2 z-50 bg-[#1E293B] text-white px-6 py-3 rounded-xl shadow-xl flex items-center gap-3">
            <div className="w-2 h-2 rounded-full bg-[#10B981]"></div>
            <span className="text-[13px] font-bold">{toastMessage}</span>
          </motion.div>
        )}
      </AnimatePresence>
      
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <motion.h1 
            initial={{ opacity: 0, y: -10 }}
            animate={{ opacity: 1, y: 0 }}
            className="text-[26px] font-bold text-[#1E293B] tracking-tight mb-0.5"
          >
            Analytics
          </motion.h1>
          <motion.p 
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.1 }}
            className="text-[14px] text-[#64748B]"
          >
            Comprehensive insights into student progress, projects, and mentorship impact.
          </motion.p>
        </div>
        <div className="flex items-center gap-3 shrink-0 relative">
          <div onClick={() => setShowDatePicker(!showDatePicker)} className="flex items-center gap-2 px-4 py-2.5 bg-white border border-[#E2E8F0] rounded-xl text-[13px] font-bold text-[#1E293B] cursor-pointer hover:bg-[#F8F9FC] shadow-sm transition-colors">
            <Calendar className="w-4 h-4 text-[#94A3B8]" />
            {new Date(dateRange.start).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })} – {new Date(dateRange.end).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })} <ChevronDown className={`w-4 h-4 ml-1 transition-transform ${showDatePicker ? 'rotate-180 text-[#6C3DFF]' : 'text-[#94A3B8]'}`} />
          </div>

          <AnimatePresence>
            {showDatePicker && (
              <>
                <div className="fixed inset-0 z-40" onClick={() => setShowDatePicker(false)}></div>
                <motion.div initial={{ opacity: 0, y: 10, scale: 0.95 }} animate={{ opacity: 1, y: 0, scale: 1 }} exit={{ opacity: 0, y: 10, scale: 0.95 }} className="absolute right-0 top-14 bg-white border border-[#E2E8F0] shadow-xl rounded-2xl p-4 z-50 w-[280px]">
                  <h4 className="text-[14px] font-bold text-[#1E293B] mb-3">Custom Date Range</h4>
                  <div className="space-y-3">
                    <div>
                      <label className="text-[11px] font-bold text-[#94A3B8] uppercase block mb-1">Start Date</label>
                      <input type="date" value={dateRange.start} onChange={(e) => setDateRange(prev => ({ ...prev, start: e.target.value }))} className="w-full border border-[#E2E8F0] rounded-lg px-3 py-2 text-[13px] font-semibold text-[#1E293B] outline-none focus:border-[#6C3DFF]" />
                    </div>
                    <div>
                      <label className="text-[11px] font-bold text-[#94A3B8] uppercase block mb-1">End Date</label>
                      <input type="date" value={dateRange.end} onChange={(e) => setDateRange(prev => ({ ...prev, end: e.target.value }))} className="w-full border border-[#E2E8F0] rounded-lg px-3 py-2 text-[13px] font-semibold text-[#1E293B] outline-none focus:border-[#6C3DFF]" />
                    </div>
                    <button onClick={() => setShowDatePicker(false)} className="w-full py-2 bg-[#6C3DFF] text-white text-[13px] font-bold rounded-lg mt-2">Apply</button>
                  </div>
                </motion.div>
              </>
            )}
          </AnimatePresence>
          <button onClick={() => showToast('Exporting Analytics Report...')} className="flex items-center gap-2 px-4 py-2.5 bg-white border border-[#E2E8F0] text-[#1E293B] rounded-xl text-[13px] font-bold shadow-sm hover:bg-[#F8F9FC] transition-colors">
            <Download className="w-4 h-4" /> Export Report
          </button>
        </div>
      </div>

      {/* 4 Stat Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {stats.map((stat, i) => (
          <motion.div key={i} initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.1 * i }} className="bg-white rounded-[20px] p-6 shadow-[0_2px_12px_rgba(0,0,0,0.03)] border border-[#F1F5F9] relative overflow-hidden flex flex-col justify-between h-[140px]">
            <div className="flex justify-between items-start">
              <div className="flex items-center gap-3">
                <div className={`w-10 h-10 rounded-full ${stat.bg} flex items-center justify-center`}>
                  <stat.icon className="w-5 h-5" style={{ color: stat.color }} />
                </div>
                <p className="text-[12px] font-bold text-[#64748B]">{stat.title}</p>
              </div>
            </div>
            <div className="flex items-end justify-between mt-auto">
              <div>
                <h3 className="text-[32px] font-black text-[#1E293B] leading-none mb-2">{stat.value}</h3>
                <p className={`text-[11px] font-bold ${stat.trend.includes('↓') ? 'text-[#10B981]' : 'text-[#10B981]'}`}>{stat.trend}</p>
              </div>
              <div className="w-24 h-8">
                <svg viewBox="0 0 100 30" className="w-full h-full fill-none" style={{ stroke: stat.color }} strokeWidth="3" strokeLinecap="round" strokeLinejoin="round">
                  <path d={i === 0 ? "M0,25 C20,25 30,15 50,20 C70,25 80,5 100,0" : i === 1 ? "M0,20 C20,25 40,5 60,15 C80,25 90,10 100,5" : i === 2 ? "M0,5 C10,5 30,20 50,10 C70,0 80,25 100,10" : "M0,20 C20,10 40,25 60,15 C80,5 90,20 100,0"} />
                </svg>
              </div>
            </div>
          </motion.div>
        ))}
      </div>

      {/* Row 2: Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        {/* Project Progress Overview */}
        <div className="lg:col-span-2 bg-white rounded-[20px] shadow-[0_2px_12px_rgba(0,0,0,0.02)] border border-[#F1F5F9] p-6">
          <div className="flex justify-between items-center mb-6">
            <h3 className="text-[16px] font-bold text-[#1E293B]">Project Progress Overview</h3>
            <select value={timeframe} onChange={(e) => setTimeframe(e.target.value)} className="border border-[#E2E8F0] rounded-xl px-3 py-1.5 text-[11px] font-bold text-[#64748B] cursor-pointer hover:bg-[#F8F9FC] outline-none focus:border-[#6C3DFF] bg-white">
              <option>This Semester</option>
              <option>Last Semester</option>
            </select>
          </div>
          <div className="relative h-[250px] mt-4">
            {/* Y Axis */}
            <div className="absolute left-0 top-0 bottom-8 w-10 flex flex-col justify-between text-[11px] font-semibold text-[#94A3B8]">
              <span>100%</span><span>75%</span><span>50%</span><span>25%</span><span>0%</span>
            </div>
            {/* Chart Area */}
            <div className="absolute left-12 right-0 top-2 bottom-8">
              <div className="absolute inset-0 flex flex-col justify-between">
                {[...Array(5)].map((_, i) => (
                  <div key={i} className="w-full border-t border-[#F8F9FC] h-0"></div>
                ))}
              </div>
              <svg viewBox="0 0 1000 200" preserveAspectRatio="none" className="absolute inset-0 w-full h-full overflow-visible">
                <defs>
                  <linearGradient id="analyticsGrad" x1="0%" y1="0%" x2="0%" y2="100%">
                    <stop offset="0%" stopColor="#8B5CF6" stopOpacity="0.3" />
                    <stop offset="100%" stopColor="#8B5CF6" stopOpacity="0" />
                  </linearGradient>
                </defs>
                <path d="M0,180 C200,160 400,130 600,110 C800,80 900,40 1000,50 L1000,200 L0,200 Z" fill="url(#analyticsGrad)" />
                <path d="M0,180 C200,160 400,130 600,110 C800,80 900,40 1000,50" fill="none" stroke="#8B5CF6" strokeWidth="4" />
                
                <circle cx="200" cy="160" r="4" fill="white" stroke="#8B5CF6" strokeWidth="2" />
                <circle cx="400" cy="130" r="4" fill="white" stroke="#8B5CF6" strokeWidth="2" />
                <circle cx="600" cy="110" r="4" fill="white" stroke="#8B5CF6" strokeWidth="2" />
                <circle cx="800" cy="80" r="4" fill="white" stroke="#8B5CF6" strokeWidth="2" />
                <circle cx="900" cy="40" r="6" fill="#8B5CF6" stroke="white" strokeWidth="3" />
                <circle cx="1000" cy="50" r="4" fill="white" stroke="#8B5CF6" strokeWidth="2" />
              </svg>
              
              <div className="absolute left-[90%] top-[40px] -translate-x-1/2 -translate-y-full mb-3 bg-white border border-[#E2E8F0] shadow-md rounded-xl px-3 py-2 text-center pointer-events-none z-10 w-[110px]">
                <p className="text-[10px] font-bold text-[#94A3B8] mb-0.5">Jun 12, 2025</p>
                <p className="text-[12px] font-black text-[#1E293B]">68% <span className="text-[10px] font-semibold text-[#64748B]">Avg. Progress</span></p>
                <div className="absolute -bottom-1.5 left-1/2 -translate-x-1/2 w-3 h-3 bg-white border-b border-r border-[#E2E8F0] rotate-45"></div>
              </div>
            </div>
            {/* X Axis */}
            <div className="absolute left-12 right-0 bottom-0 flex justify-between text-[11px] font-semibold text-[#94A3B8]">
              <span>May 12</span><span>May 19</span><span>May 26</span><span>Jun 2</span><span>Jun 9</span><span>Jun 12</span>
            </div>
          </div>
        </div>

        {/* Projects by Domain */}
        <div className="bg-white rounded-[20px] shadow-[0_2px_12px_rgba(0,0,0,0.02)] border border-[#F1F5F9] p-6">
          <div className="flex justify-between items-center mb-6">
            <h3 className="text-[16px] font-bold text-[#1E293B]">Projects by Domain</h3>
            <Link href="#" className="text-[12px] font-bold text-[#6C3DFF]">View All</Link>
          </div>
          
          <div className="flex flex-col items-center gap-6 mt-4">
            <div className="relative w-[180px] h-[180px]">
              <svg viewBox="0 0 36 36" className="w-full h-full -rotate-90">
                <circle cx="18" cy="18" r="14" fill="none" className="stroke-[#8B5CF6]" strokeWidth="8" strokeDasharray="30 100" strokeDashoffset="0"></circle>
                <circle cx="18" cy="18" r="14" fill="none" className="stroke-[#3B82F6]" strokeWidth="8" strokeDasharray="21 100" strokeDashoffset="-30"></circle>
                <circle cx="18" cy="18" r="14" fill="none" className="stroke-[#64748B]" strokeWidth="8" strokeDasharray="18 100" strokeDashoffset="-51"></circle>
                <circle cx="18" cy="18" r="14" fill="none" className="stroke-[#F59E0B]" strokeWidth="8" strokeDasharray="14 100" strokeDashoffset="-69"></circle>
                <circle cx="18" cy="18" r="14" fill="none" className="stroke-[#F43F5E]" strokeWidth="8" strokeDasharray="11 100" strokeDashoffset="-83"></circle>
              </svg>
              <div className="absolute inset-0 flex flex-col items-center justify-center">
                <span className="text-[28px] font-black text-[#1E293B] leading-none">28</span>
                <span className="text-[11px] font-bold text-[#64748B]">Projects</span>
              </div>
            </div>
            
            <div className="w-full space-y-2.5">
              {[
                { label: 'Artificial Intelligence', val: '8 (29%)', color: 'bg-[#8B5CF6]' },
                { label: 'Web Development', val: '6 (21%)', color: 'bg-[#3B82F6]' },
                { label: 'Data Science', val: '5 (18%)', color: 'bg-[#64748B]' },
                { label: 'Machine Learning', val: '4 (14%)', color: 'bg-[#F59E0B]' },
                { label: 'IoT & Embedded', val: '3 (11%)', color: 'bg-[#F43F5E]' },
              ].map((item, i) => (
                <div key={i} className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <div className={`w-2.5 h-2.5 rounded-full ${item.color}`}></div>
                    <span className="text-[12px] font-bold text-[#1E293B]">{item.label}</span>
                  </div>
                  <span className="text-[12px] font-bold text-[#64748B]">{item.val}</span>
                </div>
              ))}
            </div>
          </div>
        </div>

      </div>

      {/* Row 3: 3 Columns */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        {/* Student Engagement */}
        <div className="bg-white rounded-[20px] shadow-[0_2px_12px_rgba(0,0,0,0.02)] border border-[#F1F5F9] p-6 flex flex-col">
          <h3 className="text-[16px] font-bold text-[#1E293B] mb-6">Student Engagement</h3>
          <div className="flex-1 flex flex-col justify-center">
            <div className="flex gap-2">
              <div className="flex flex-col justify-between text-[10px] font-bold text-[#94A3B8] h-[140px] pr-2">
                <span>Mon</span><span>Tue</span><span>Wed</span><span>Thu</span><span>Fri</span><span>Sat</span><span>Sun</span>
              </div>
              <div className="flex-1 grid grid-cols-7 gap-1 h-[140px]">
                {[...Array(49)].map((_, i) => {
                  const r = Math.sin(i * 10) * 0.5 + 0.5; // Deterministic pseudo-random
                  const bg = r > 0.8 ? 'bg-[#6C3DFF]' : r > 0.6 ? 'bg-[#8B5CF6]' : r > 0.4 ? 'bg-[#A78BFA]' : r > 0.2 ? 'bg-[#C4B5FD]' : 'bg-[#EDE9FE]';
                  return <div key={i} className={`rounded-sm ${bg} hover:ring-1 hover:ring-[#1E293B] cursor-pointer transition-all`}></div>;
                })}
              </div>
            </div>
            <div className="flex justify-between items-center text-[10px] font-bold text-[#94A3B8] pl-8 mt-2">
              <span>12 May</span><span>19 May</span><span>26 May</span><span>2 Jun</span><span>9 Jun</span><span>12 Jun</span>
            </div>
            <div className="flex items-center justify-between mt-4 pl-8">
              <span className="text-[10px] font-bold text-[#94A3B8]">Low</span>
              <div className="flex gap-1">
                <div className="w-6 h-2 bg-[#EDE9FE] rounded-sm"></div>
                <div className="w-6 h-2 bg-[#C4B5FD] rounded-sm"></div>
                <div className="w-6 h-2 bg-[#A78BFA] rounded-sm"></div>
                <div className="w-6 h-2 bg-[#8B5CF6] rounded-sm"></div>
                <div className="w-6 h-2 bg-[#6C3DFF] rounded-sm"></div>
              </div>
              <span className="text-[10px] font-bold text-[#94A3B8]">High</span>
            </div>
          </div>
        </div>

        {/* Mentorship Impact */}
        <div className="bg-white rounded-[20px] shadow-[0_2px_12px_rgba(0,0,0,0.02)] border border-[#F1F5F9] p-6">
          <h3 className="text-[16px] font-bold text-[#1E293B] mb-2">Mentorship Impact</h3>
          <div className="flex flex-col items-center">
            {/* Arc Chart */}
            <div className="relative w-40 h-24 overflow-hidden mt-6">
              <svg viewBox="0 0 100 50" className="w-full h-full transform scale-150 origin-bottom">
                <path d="M 10 50 A 40 40 0 0 1 90 50" fill="none" className="stroke-[#F1F5F9]" strokeWidth="12" strokeLinecap="round" />
                <path d="M 10 50 A 40 40 0 0 1 90 50" fill="none" className="stroke-[#6C3DFF]" strokeWidth="12" strokeLinecap="round" strokeDasharray="125" strokeDashoffset="25" />
              </svg>
              <div className="absolute bottom-0 left-0 right-0 flex flex-col items-center justify-end pb-2">
                <h4 className="text-[28px] font-black text-[#1E293B] leading-none">4.7 <span className="text-[16px] text-[#64748B]">/ 5</span></h4>
                <p className="text-[10px] font-bold text-[#64748B] mt-1">Avg. Satisfaction</p>
                <p className="text-[9px] font-bold text-[#10B981] mt-0.5">↑ 8% from last 30 days</p>
              </div>
            </div>
            
            <div className="grid grid-cols-3 gap-2 w-full mt-10">
              <div className="text-center">
                <div className="w-8 h-8 mx-auto rounded-lg bg-[#F5F3FF] text-[#6C3DFF] flex items-center justify-center mb-1"><Calendar className="w-4 h-4" /></div>
                <p className="text-[14px] font-black text-[#1E293B]">24</p>
                <p className="text-[9px] font-bold text-[#64748B]">Sessions</p>
                <p className="text-[9px] font-bold text-[#10B981] mt-0.5">↑ 25%</p>
              </div>
              <div className="text-center">
                <div className="w-8 h-8 mx-auto rounded-lg bg-[#ECFDF5] text-[#10B981] flex items-center justify-center mb-1"><TrendingUp className="w-4 h-4" /></div>
                <p className="text-[14px] font-black text-[#1E293B]">16</p>
                <p className="text-[9px] font-bold text-[#64748B]">Mentees Improved</p>
                <p className="text-[9px] font-bold text-[#10B981] mt-0.5">↑ 20%</p>
              </div>
              <div className="text-center">
                <div className="w-8 h-8 mx-auto rounded-lg bg-[#FFFBEB] text-[#F59E0B] flex items-center justify-center mb-1"><Star className="w-4 h-4" /></div>
                <p className="text-[14px] font-black text-[#1E293B]">4.7 / 5</p>
                <p className="text-[9px] font-bold text-[#64748B]">Satisfaction</p>
                <p className="text-[9px] font-bold text-[#10B981] mt-0.5">↑ 8%</p>
              </div>
            </div>
          </div>
        </div>

        {/* Project Status */}
        <div className="bg-white rounded-[20px] shadow-[0_2px_12px_rgba(0,0,0,0.02)] border border-[#F1F5F9] p-6 flex flex-col">
          <h3 className="text-[16px] font-bold text-[#1E293B] mb-6">Project Status</h3>
          <div className="flex-1 space-y-4">
            {[
              { label: 'Active', val: '28 (44%)', pct: 44, color: 'bg-[#6C3DFF]' },
              { label: 'In Review', val: '12 (19%)', pct: 19, color: 'bg-[#3B82F6]' },
              { label: 'Completed', val: '23 (36%)', pct: 36, color: 'bg-[#10B981]' },
              { label: 'On Hold', val: '1 (2%)', pct: 2, color: 'bg-[#F59E0B]' },
              { label: 'Archived', val: '0 (0%)', pct: 0, color: 'bg-[#F43F5E]' },
            ].map((status, i) => (
              <div key={i} className="flex items-center gap-4">
                <div className="w-24 shrink-0 flex items-center gap-2">
                  <div className={`w-2.5 h-2.5 rounded-full ${status.color}`}></div>
                  <span className="text-[12px] font-bold text-[#1E293B]">{status.label}</span>
                </div>
                <div className="flex-1 h-2 bg-[#F1F5F9] rounded-full overflow-hidden">
                  <div className={`h-full rounded-full ${status.color}`} style={{ width: `${status.pct}%` }}></div>
                </div>
                <span className="text-[11px] font-bold text-[#64748B] w-12 text-right">{status.val}</span>
              </div>
            ))}
          </div>
          <div className="mt-auto pt-4 border-t border-[#F1F5F9] flex justify-between items-center">
            <span className="text-[12px] font-bold text-[#64748B]">Total Projects: 64</span>
            <Link href="#" className="text-[12px] font-bold text-[#6C3DFF]">View All</Link>
          </div>
        </div>

      </div>

      {/* Bottom Banner */}
      <div className="w-full bg-[#F5F3FF] rounded-[20px] p-6 border border-[#E5D4FF]/50 flex items-center justify-between overflow-hidden relative">
        <div className="flex items-center gap-4 relative z-10">
          <div className="w-12 h-12 rounded-[14px] bg-[#6C3DFF] flex items-center justify-center shadow-lg shadow-[#6C3DFF]/20 text-white">
            <Trophy className="w-6 h-6" />
          </div>
          <div>
            <h4 className="text-[16px] font-bold text-[#1E293B] mb-0.5">Great Progress!</h4>
            <p className="text-[13px] text-[#475569] font-medium">Projects completion rate increased by 18% this month. Keep up the excellent work!</p>
          </div>
        </div>
        {/* Fake decorative graph background */}
        <div className="absolute right-0 bottom-0 opacity-50 pointer-events-none w-[300px] h-[100px]">
           <svg viewBox="0 0 100 30" className="w-full h-full fill-none" stroke="#A78BFA" strokeWidth="1">
             <path d="M0,30 L20,20 L40,25 L60,10 L80,15 L100,0 L100,30 Z" fill="#E5D4FF" />
             <path d="M0,30 L20,20 L40,25 L60,10 L80,15 L100,0" />
           </svg>
        </div>
      </div>

    </div>
  );
}

// Icon Fallback Component for missing graduation cap inside stats loop
function GraduationCapIcon(props: any) {
  return <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...props}><path d="M21.42 10.922a2 2 0 0 1-.019 3.07l-9.28 8.1a2 2 0 0 1-2.634.024l-9.26-8.05a2.043 2.043 0 0 1 .023-3.092l9.27-8.01a2 2 0 0 1 2.628-.018z"/><path d="M14 11.6V17"/><path d="M10 11.6V17"/></svg>
}
