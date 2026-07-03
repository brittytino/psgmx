'use client';

import React from 'react';
import { motion } from 'framer-motion';
import { Folder, Plus, Download, Search, Filter, ChevronDown, MoreVertical, Shield, FileCode, CheckSquare, Target, Activity, CheckCircle, BrainCircuit, Clock } from 'lucide-react';
import Link from 'next/link';

import { AnimatePresence } from 'framer-motion';

export default function FacultyFYPRepositoryDashboard() {
  const [activeTab, setActiveTab] = React.useState('All Projects');
  
  const [projects, setProjects] = React.useState([
    { id: 1, title: 'AI-Powered Code Quality Analysis Tool', domain: 'Web Application', rollId: '25MX301', guide: 'Dr. Arunkumar', members: 3, batch: '2025-2027', status: 'Active', statusColor: 'border-[#6C3DFF] text-[#6C3DFF] bg-[#F5F3FF]', icon: BrainCircuit, bg: 'bg-[#F5F3FF]', color: '#6C3DFF' },
    { id: 2, title: 'Blockchain-Based Academic Certificate Verification', domain: 'Blockchain', rollId: '25MX114', guide: 'Dr. Pavithra', members: 4, batch: '2025-2027', status: 'Review', statusColor: 'border-[#3B82F6] text-[#3B82F6] bg-[#EFF6FF]', icon: Shield, bg: 'bg-[#EFF6FF]', color: '#3B82F6' },
    { id: 3, title: 'Smart Hydroponics Monitoring System', domain: 'IoT', rollId: '25MX205', guide: 'Dr. Karthikeyan', members: 3, batch: '2025-2027', status: 'Completed', statusColor: 'border-[#10B981] text-[#10B981] bg-[#ECFDF5]', icon: CheckSquare, bg: 'bg-[#ECFDF5]', color: '#10B981' },
    { id: 4, title: 'E-Commerce Recommendation System', domain: 'Machine Learning', rollId: '25MX114', guide: 'Dr. Arunkumar', members: 4, batch: '2024-2026', status: 'Active', statusColor: 'border-[#F59E0B] text-[#F59E0B] bg-[#FFFBEB]', icon: FileCode, bg: 'bg-[#FFFBEB]', color: '#F59E0B' },
    { id: 5, title: 'AI-Based Diabetes Prediction Model', domain: 'Machine Learning', rollId: '25MX301', guide: 'Dr. Pavithra', members: 3, batch: '2024-2026', status: 'Completed', statusColor: 'border-[#F43F5E] text-[#F43F5E] bg-[#FFF1F2]', icon: Activity, bg: 'bg-[#FFF1F2]', color: '#F43F5E' },
  ]);

  const [isLoadingMore, setIsLoadingMore] = React.useState(false);
  const [visibleCount, setVisibleCount] = React.useState(3);
  const [searchQuery, setSearchQuery] = React.useState('');
  const [toastMessage, setToastMessage] = React.useState('');

  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(''), 3000);
  };

  const filteredProjects = projects.filter(p => {
    const matchesSearch = p.title.toLowerCase().includes(searchQuery.toLowerCase()) || p.rollId.toLowerCase().includes(searchQuery.toLowerCase()) || p.guide.toLowerCase().includes(searchQuery.toLowerCase());
    if (!matchesSearch) return false;

    if (activeTab === 'My Mentored') return p.guide === 'Dr. Arunkumar';
    if (activeTab === 'Active') return p.status === 'Active';
    if (activeTab === 'Review') return p.status === 'Review';
    if (activeTab === 'Completed') return p.status === 'Completed';
    if (activeTab === 'Archived') return false; // simulated empty
    return true; // 'All Projects'
  });

  const displayedProjects = filteredProjects.slice(0, visibleCount);

  const handleLoadMore = () => {
    setIsLoadingMore(true);
    setTimeout(() => {
      setIsLoadingMore(false);
    }, 1000);
  };

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
        <div className="flex items-center gap-4">
          <div className="w-12 h-12 rounded-2xl bg-[#6C3DFF] flex items-center justify-center shadow-lg shadow-[#6C3DFF]/20 shrink-0">
            <Folder className="w-6 h-6 text-white" />
          </div>
          <div>
            <motion.h1 
              initial={{ opacity: 0, y: -10 }}
              animate={{ opacity: 1, y: 0 }}
              className="text-[26px] font-bold text-[#1E293B] tracking-tight mb-0.5"
            >
              FYP Repository
            </motion.h1>
            <motion.p 
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 0.1 }}
              className="text-[14px] text-[#64748B]"
            >
              Track, manage and evaluate Final Year Projects across batches.
            </motion.p>
          </div>
        </div>
        <div className="flex items-center gap-3 shrink-0">
          <button onClick={() => showToast('Exporting Report...')} className="flex items-center gap-2 px-6 py-3 bg-white border border-[#E2E8F0] text-[#1E293B] rounded-xl text-[14px] font-bold shadow-sm hover:bg-[#F8F9FC] transition-colors">
            <Download className="w-4 h-4" /> Export Reports
          </button>
          <button onClick={() => showToast('Opening Registration Form...')} className="flex items-center gap-2 px-6 py-3 bg-[#6C3DFF] text-white rounded-xl text-[14px] font-bold shadow-md shadow-[#6C3DFF]/20 hover:bg-[#5B21B6] transition-colors">
            <Plus className="w-4 h-4" /> Register New Project
          </button>
        </div>
      </div>

      {/* 4 Stat Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {[
          { title: 'Total Projects', value: '64', trend: '↑ 18% this month', color: '#6C3DFF', bg: 'bg-[#F5F3FF]', icon: FileCode },
          { title: 'Active Projects', value: '28', trend: '↑ 12% this month', color: '#06B6D4', bg: 'bg-[#ECFEFF]', icon: Activity },
          { title: 'Completed Projects', value: '23', trend: '↑ 8% this month', color: '#10B981', bg: 'bg-[#ECFDF5]', icon: CheckCircle },
          { title: 'Domains Covered', value: '12', trend: '↑ 2 new this month', color: '#F59E0B', bg: 'bg-[#FFFBEB]', icon: Target },
        ].map((stat, i) => (
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
                <p className="text-[11px] font-bold text-[#10B981]">{stat.trend}</p>
              </div>
              <div className="w-24 h-8">
                <svg viewBox="0 0 100 30" className="w-full h-full fill-none" style={{ stroke: stat.color }} strokeWidth="3" strokeLinecap="round" strokeLinejoin="round">
                  <path d={i === 0 ? "M0,25 C20,25 30,15 50,15 C70,15 80,5 100,5" : i === 1 ? "M0,20 C20,25 40,5 60,15 C80,25 90,10 100,5" : i === 2 ? "M0,5 C10,5 30,20 50,10 C70,0 80,25 100,25" : "M0,20 C20,10 40,25 60,15 C80,5 90,20 100,10"} />
                </svg>
              </div>
            </div>
          </motion.div>
        ))}
      </div>

      {/* Main Content Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        
        {/* Left Column - Projects */}
        <div className="lg:col-span-2 space-y-6">
          <div className="bg-white rounded-[20px] shadow-[0_2px_12px_rgba(0,0,0,0.02)] border border-[#F1F5F9] p-6 flex flex-col h-full">
            
            {/* Tabs & Controls */}
            <div className="border-b border-[#E2E8F0] flex flex-col md:flex-row md:items-end justify-between gap-4 pb-0 mb-6">
              <div className="flex items-center gap-6 overflow-x-auto custom-scrollbar pb-[-1px]">
                {['All Projects', 'My Mentored', 'Active', 'Review', 'Completed', 'Archived'].map(tab => (
                  <button 
                    key={tab}
                    onClick={() => setActiveTab(tab)}
                    className={`text-[14px] pb-4 px-1 whitespace-nowrap transition-colors ${activeTab === tab ? 'font-bold text-[#6C3DFF] border-b-2 border-[#6C3DFF]' : 'font-semibold text-[#64748B] hover:text-[#1E293B] border-b-2 border-transparent'}`}
                  >
                    {tab}
                  </button>
                ))}
              </div>
              <div className="flex flex-col sm:flex-row sm:items-center gap-3 pb-4 w-full md:w-auto">
                <div className="relative flex-1 md:w-[200px]">
                  <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-[#94A3B8]" />
                  <input type="text" value={searchQuery} onChange={(e) => setSearchQuery(e.target.value)} placeholder="Search projects..." className="pl-9 pr-4 py-2 border border-[#E2E8F0] rounded-xl text-[13px] w-full outline-none focus:border-[#6C3DFF] transition-colors" />
                </div>
                <div className="flex items-center gap-1 border border-[#E2E8F0] rounded-xl px-3 py-2 text-[13px] font-bold text-[#1E293B] cursor-pointer hover:bg-[#F8F9FC] shrink-0">
                  Batch <ChevronDown className="w-4 h-4 ml-1" />
                </div>
                <div className="flex items-center gap-1 border border-[#E2E8F0] rounded-xl px-3 py-2 text-[13px] font-bold text-[#1E293B] cursor-pointer hover:bg-[#F8F9FC] shrink-0">
                  Domain <ChevronDown className="w-4 h-4 ml-1" />
                </div>
                <button className="flex items-center gap-2 px-3 py-2 border border-[#E2E8F0] rounded-xl text-[13px] font-bold text-[#1E293B] hover:bg-[#F8F9FC] transition-colors shrink-0">
                  <Filter className="w-4 h-4" /> Filters
                </button>
              </div>
            </div>

            <div className="space-y-4">
              <AnimatePresence mode="popLayout">
                {displayedProjects.length === 0 ? (
                  <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="py-12 text-center text-[#94A3B8] text-[13px] font-semibold">
                    No projects found for this tab.
                  </motion.div>
                ) : (
                  displayedProjects.map((project) => (
                    <motion.div 
                      layout
                      initial={{ opacity: 0, y: 10 }}
                      animate={{ opacity: 1, y: 0 }}
                      exit={{ opacity: 0, scale: 0.95 }}
                      key={project.id} 
                      className="p-5 rounded-[16px] border border-[#F1F5F9] hover:border-[#E2E8F0] hover:shadow-sm transition-all flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white"
                    >
                      <div className="flex items-center gap-4 flex-1 min-w-0">
                        <div className={`w-14 h-14 rounded-[16px] ${project.bg} flex items-center justify-center shrink-0`}>
                          <project.icon className="w-6 h-6" style={{ color: project.color }} />
                        </div>
                        <div>
                          <h4 className="text-[15px] font-bold text-[#1E293B] truncate mb-1">{project.title}</h4>
                          <p className="text-[12px] font-semibold text-[#64748B]">
                            {project.domain} • {project.rollId}
                          </p>
                          <p className="text-[11px] text-[#94A3B8] font-bold mt-1">
                            Guide: {project.guide} • {project.members} Members
                          </p>
                        </div>
                      </div>
                      
                      <div className="flex items-center gap-8 shrink-0">
                        <div className="hidden md:block text-center">
                          <p className="text-[10px] font-bold text-[#94A3B8] uppercase mb-0.5">Batch</p>
                          <p className="text-[13px] font-bold text-[#1E293B]">{project.batch}</p>
                        </div>
                        <div className={`px-4 py-1.5 rounded-full border text-[11px] font-bold w-24 text-center ${project.statusColor}`}>
                          {project.status}
                        </div>
                        <div className="flex items-center -space-x-2">
                          <img src="https://ui-avatars.com/api/?name=St1&background=random" className="w-8 h-8 rounded-full border-2 border-white" alt="" />
                          <img src="https://ui-avatars.com/api/?name=St2&background=random" className="w-8 h-8 rounded-full border-2 border-white" alt="" />
                          <img src="https://ui-avatars.com/api/?name=St3&background=random" className="w-8 h-8 rounded-full border-2 border-white" alt="" />
                          {project.members > 3 && (
                            <div className="w-8 h-8 rounded-full border-2 border-white bg-[#F1F5F9] text-[#64748B] text-[10px] font-bold flex items-center justify-center z-10">
                              +{project.members - 3}
                            </div>
                          )}
                        </div>
                        <MoreVertical className="w-5 h-5 text-[#94A3B8] cursor-pointer hover:text-[#1E293B]" />
                      </div>
                    </motion.div>
                  ))
                )}
              </AnimatePresence>
            </div>

            <AnimatePresence>
              {visibleCount < filteredProjects.length && (
                <motion.button layout initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} onClick={() => setVisibleCount(prev => prev + 3)} className="mt-6 w-full py-3.5 bg-[#F8F9FC] text-[#6C3DFF] rounded-[12px] text-[13px] font-bold flex items-center justify-center gap-2 hover:bg-[#F1F5F9] transition-colors">
                  Load More Projects <ChevronDown className="w-4 h-4" />
                </motion.button>
              )}
            </AnimatePresence>
          </div>
        </div>

        {/* Right Column - Status & Domains */}
        <div className="space-y-6">
          
          {/* Project Status Overview */}
          <div className="bg-white rounded-[20px] shadow-[0_2px_12px_rgba(0,0,0,0.02)] border border-[#F1F5F9] p-6">
            <h3 className="text-[16px] font-bold text-[#1E293B] mb-6">Project Status Overview</h3>
            <div className="flex items-center gap-6">
              {/* Fake Donut Chart SVG */}
              <div className="relative w-28 h-28 shrink-0">
                <svg viewBox="0 0 36 36" className="w-full h-full -rotate-90">
                  <circle cx="18" cy="18" r="16" fill="none" className="stroke-[#6C3DFF]" strokeWidth="6" strokeDasharray="44 100" strokeDashoffset="0"></circle>
                  <circle cx="18" cy="18" r="16" fill="none" className="stroke-[#3B82F6]" strokeWidth="6" strokeDasharray="19 100" strokeDashoffset="-44"></circle>
                  <circle cx="18" cy="18" r="16" fill="none" className="stroke-[#10B981]" strokeWidth="6" strokeDasharray="36 100" strokeDashoffset="-63"></circle>
                  <circle cx="18" cy="18" r="16" fill="none" className="stroke-[#F59E0B]" strokeWidth="6" strokeDasharray="2 100" strokeDashoffset="-99"></circle>
                </svg>
              </div>
              <div className="flex-1 space-y-2.5">
                {[
                  { label: 'Active', pct: '44%', val: 28, color: 'bg-[#6C3DFF]' },
                  { label: 'Review', pct: '19%', val: 12, color: 'bg-[#3B82F6]' },
                  { label: 'Completed', pct: '36%', val: 23, color: 'bg-[#10B981]' },
                  { label: 'On Hold', pct: '2%', val: 1, color: 'bg-[#F59E0B]' },
                  { label: 'Archived', pct: '0%', val: 0, color: 'bg-[#F43F5E]' },
                ].map((s, i) => (
                  <div key={i} className="flex items-center justify-between">
                    <div className="flex items-center gap-2"><div className={`w-2.5 h-2.5 rounded-full ${s.color}`}></div><span className="text-[12px] font-bold text-[#1E293B]">{s.label}</span></div>
                    <span className="text-[11px] text-[#64748B] font-semibold">{s.val} ({s.pct})</span>
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* Top Domains */}
          <div className="bg-white rounded-[20px] shadow-[0_2px_12px_rgba(0,0,0,0.02)] border border-[#F1F5F9] p-6">
            <div className="flex justify-between items-center mb-6">
              <h3 className="text-[16px] font-bold text-[#1E293B]">Top Domains</h3>
              <Link href="#" className="text-[12px] font-bold text-[#6C3DFF]">View All</Link>
            </div>
            <div className="space-y-4">
              {[
                { name: 'Artificial Intelligence', val: 18, pct: 100, color: 'bg-gradient-to-r from-[#6C3DFF] to-[#A78BFA]', icon: '🤖' },
                { name: 'Web Development', val: 14, pct: 80, color: 'bg-gradient-to-r from-[#3B82F6] to-[#93C5FD]', icon: '🌐' },
                { name: 'Machine Learning', val: 10, pct: 60, color: 'bg-gradient-to-r from-[#10B981] to-[#6EE7B7]', icon: '🧠' },
                { name: 'IoT & Embedded', val: 8, pct: 45, color: 'bg-gradient-to-r from-[#F59E0B] to-[#FCD34D]', icon: '🔌' },
                { name: 'Blockchain', val: 7, pct: 35, color: 'bg-gradient-to-r from-[#F43F5E] to-[#FDA4AF]', icon: '⛓️' },
                { name: 'Other Domains', val: 7, pct: 35, color: 'bg-gradient-to-r from-[#94A3B8] to-[#CBD5E1]', icon: '📂' },
              ].map((domain, i) => (
                <div key={i}>
                  <div className="flex items-center justify-between mb-1.5">
                    <div className="flex items-center gap-1.5">
                      <div className="w-5 h-5 rounded bg-[#F8F9FC] flex items-center justify-center text-[10px]">{domain.icon}</div>
                      <span className="text-[12px] font-bold text-[#1E293B]">{domain.name}</span>
                    </div>
                    <span className="text-[12px] font-bold text-[#64748B]">{domain.val}</span>
                  </div>
                  <div className="w-full h-1.5 bg-[#F1F5F9] rounded-full overflow-hidden">
                    <div className={`h-full rounded-full ${domain.color}`} style={{ width: `${domain.pct}%` }}></div>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Recent Project Updates */}
          <div className="bg-white rounded-[20px] shadow-[0_2px_12px_rgba(0,0,0,0.02)] border border-[#F1F5F9] p-6">
            <div className="flex justify-between items-center mb-6">
              <h3 className="text-[16px] font-bold text-[#1E293B]">Recent Project Updates</h3>
              <Link href="#" className="text-[12px] font-bold text-[#6C3DFF]">View All</Link>
            </div>
            <div className="space-y-5">
              {[
                { title: 'AI-Powered Code Quality Analysis Tool', desc: 'Report submitted for review', time: '2h ago', bg: 'bg-[#F5F3FF]', color: 'text-[#6C3DFF]' },
                { title: 'Smart Hydroponics Monitoring System', desc: 'Presentation scheduled', time: '5h ago', bg: 'bg-[#ECFDF5]', color: 'text-[#10B981]' },
                { title: 'E-Commerce Recommendation System', desc: 'Guide feedback added', time: '1d ago', bg: 'bg-[#FFFBEB]', color: 'text-[#F59E0B]' },
              ].map((upd, i) => (
                <div key={i} className="flex items-start gap-3 relative before:absolute before:left-4 before:top-8 before:bottom-[-20px] before:w-[2px] before:bg-[#F1F5F9] last:before:hidden">
                  <div className={`w-8 h-8 rounded-full ${upd.bg} flex items-center justify-center shrink-0 z-10 border border-white shadow-sm`}>
                    <Clock className={`w-3.5 h-3.5 ${upd.color}`} />
                  </div>
                  <div>
                    <p className="text-[13px] font-bold text-[#1E293B] leading-snug">{upd.title}</p>
                    <p className="text-[11px] font-semibold text-[#64748B] mt-0.5">{upd.desc}</p>
                  </div>
                  <span className="text-[10px] font-bold text-[#94A3B8] ml-auto shrink-0 flex items-center gap-1">{upd.time} <span className={`w-1.5 h-1.5 rounded-full ${upd.bg.replace('bg-', 'bg-').replace('50', '500')}`} style={{backgroundColor: upd.color.replace('text-[', '').replace(']', '')}}></span></span>
                </div>
              ))}
            </div>
            
            <div className="mt-8 pt-4 border-t border-[#F1F5F9] flex justify-center">
              <Link href="#" className="text-[12px] font-bold text-[#6C3DFF] flex items-center gap-1.5">View All Updates →</Link>
            </div>
          </div>

        </div>

      </div>
    </div>
  );
}
