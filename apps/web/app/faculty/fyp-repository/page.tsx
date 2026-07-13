'use client';

import React from 'react';
import { motion } from 'framer-motion';
import { Folder, Plus, Download, Search, Filter, ChevronDown, MoreVertical, Shield, FileCode, CheckSquare, Target, Activity, CheckCircle, BrainCircuit, Clock } from 'lucide-react';
import Link from 'next/link';

import { AnimatePresence } from 'framer-motion';

export default function FacultyFYPRepositoryDashboard() {
  const [activeTab, setActiveTab] = React.useState('All Projects');
  
  const [projects, setProjects] = React.useState([
    { id: 1, title: 'AI-Powered Code Quality Analysis Tool', domain: 'Web Application', rollId: '25MX301', guide: 'Dr. Arunkumar', members: 3, batch: '2025-2027', status: 'Active', statusColor: 'border-primary-purple text-primary-purple bg-page-bg', icon: BrainCircuit, bg: 'bg-page-bg', color: "var(--primary-purple)" },
    { id: 2, title: 'Blockchain-Based Academic Certificate Verification', domain: 'Blockchain', rollId: '25MX114', guide: 'Dr. Pavithra', members: 4, batch: '2025-2027', status: 'Review', statusColor: 'border-primary-purple/30 text-electric-blue bg-white', icon: Shield, bg: 'bg-white', color: "var(--primary-purple)" },
    { id: 3, title: 'Smart Hydroponics Monitoring System', domain: 'IoT', rollId: '25MX205', guide: 'Dr. Karthikeyan', members: 3, batch: '2025-2027', status: 'Completed', statusColor: 'border-electric-blue/30 text-electric-blue bg-white', icon: CheckSquare, bg: 'bg-white', color: "var(--electric-blue)" },
    { id: 4, title: 'E-Commerce Recommendation System', domain: 'Machine Learning', rollId: '25MX114', guide: 'Dr. Arunkumar', members: 4, batch: '2024-2026', status: 'Active', statusColor: 'border-illus-gold/30 text-illus-gold bg-white', icon: FileCode, bg: 'bg-white', color: "var(--illus-gold)" },
    { id: 5, title: 'AI-Based Diabetes Prediction Model', domain: 'Machine Learning', rollId: '25MX301', guide: 'Dr. Pavithra', members: 3, batch: '2024-2026', status: 'Completed', statusColor: 'border-deep-violet/30 text-deep-violet bg-page-bg', icon: Activity, bg: 'bg-page-bg', color: "var(--deep-violet)" },
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
          <motion.div initial={{ opacity: 0, y: 50 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: 50 }} className="fixed bottom-8 left-1/2 -translate-x-1/2 z-50 bg-rich-black text-white px-6 py-3 rounded-xl shadow-xl flex items-center gap-3">
            <div className="w-2 h-2 rounded-full bg-electric-blue"></div>
            <span className="text-[13px] font-bold">{toastMessage}</span>
          </motion.div>
        )}
      </AnimatePresence>
      
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div className="flex items-center gap-4">
          <div className="w-12 h-12 rounded-2xl bg-primary-purple flex items-center justify-center shadow-lg shadow-md shadow-primary-purple/10 shrink-0">
            <Folder className="w-6 h-6 text-white" />
          </div>
          <div>
            <motion.h1 
              initial={{ opacity: 0, y: -10 }}
              animate={{ opacity: 1, y: 0 }}
              className="text-[26px] font-bold text-text-main tracking-tight mb-0.5"
            >
              FYP Repository
            </motion.h1>
            <motion.p 
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 0.1 }}
              className="text-[14px] text-text-muted"
            >
              Track, manage and evaluate Final Year Projects across batches.
            </motion.p>
          </div>
        </div>
        <div className="flex items-center gap-3 shrink-0">
          <button onClick={() => showToast('Exporting Report...')} className="flex items-center gap-2 px-6 py-3 bg-white border border-border-light text-text-main rounded-xl text-[14px] font-bold shadow-sm hover:bg-page-bg transition-colors">
            <Download className="w-4 h-4" /> Export Reports
          </button>
          <button onClick={() => showToast('Opening Registration Form...')} className="flex items-center gap-2 px-6 py-3 bg-primary-purple text-white rounded-xl text-[14px] font-bold shadow-md shadow-md shadow-primary-purple/10 hover:bg-[#5B21B6] transition-colors">
            <Plus className="w-4 h-4" /> Register New Project
          </button>
        </div>
      </div>

      {/* 4 Stat Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {[
          { title: 'Total Projects', value: '64', trend: '↑ 18% this month', color: "var(--primary-purple)", bg: 'bg-page-bg', icon: FileCode },
          { title: 'Active Projects', value: '28', trend: '↑ 12% this month', color: "var(--primary-purple)", bg: 'bg-page-bg', icon: Activity },
          { title: 'Completed Projects', value: '23', trend: '↑ 8% this month', color: "var(--electric-blue)", bg: 'bg-white', icon: CheckCircle },
          { title: 'Domains Covered', value: '12', trend: '↑ 2 new this month', color: "var(--illus-gold)", bg: 'bg-white', icon: Target },
        ].map((stat, i) => (
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
                <p className="text-[11px] font-bold text-electric-blue">{stat.trend}</p>
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
          <div className="bg-white rounded-[20px] shadow-[0_2px_12px_rgba(0,0,0,0.02)] border border-border-light p-6 flex flex-col h-full">
            
            {/* Tabs & Controls */}
            <div className="border-b border-border-light flex flex-col md:flex-row md:items-end justify-between gap-4 pb-0 mb-6">
              <div className="flex items-center gap-6 overflow-x-auto custom-scrollbar pb-[-1px]">
                {['All Projects', 'My Mentored', 'Active', 'Review', 'Completed', 'Archived'].map(tab => (
                  <button 
                    key={tab}
                    onClick={() => setActiveTab(tab)}
                    className={`text-[14px] pb-4 px-1 whitespace-nowrap transition-colors ${activeTab === tab ? 'font-bold text-primary-purple border-b-2 border-primary-purple' : 'font-semibold text-text-muted hover:text-text-main border-b-2 border-transparent'}`}
                  >
                    {tab}
                  </button>
                ))}
              </div>
              <div className="flex flex-col sm:flex-row sm:items-center gap-3 pb-4 w-full md:w-auto">
                <div className="relative flex-1 md:w-[200px]">
                  <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-text-muted" />
                  <input type="text" value={searchQuery} onChange={(e) => setSearchQuery(e.target.value)} placeholder="Search projects..." className="pl-9 pr-4 py-2 border border-border-light rounded-xl text-[13px] w-full outline-none focus:border-primary-purple transition-colors" />
                </div>
                <div className="flex items-center gap-1 border border-border-light rounded-xl px-3 py-2 text-[13px] font-bold text-text-main cursor-pointer hover:bg-page-bg shrink-0">
                  Batch <ChevronDown className="w-4 h-4 ml-1" />
                </div>
                <div className="flex items-center gap-1 border border-border-light rounded-xl px-3 py-2 text-[13px] font-bold text-text-main cursor-pointer hover:bg-page-bg shrink-0">
                  Domain <ChevronDown className="w-4 h-4 ml-1" />
                </div>
                <button className="flex items-center gap-2 px-3 py-2 border border-border-light rounded-xl text-[13px] font-bold text-text-main hover:bg-page-bg transition-colors shrink-0">
                  <Filter className="w-4 h-4" /> Filters
                </button>
              </div>
            </div>

            <div className="space-y-4">
              <AnimatePresence mode="popLayout">
                {displayedProjects.length === 0 ? (
                  <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="py-12 text-center text-text-muted text-[13px] font-semibold">
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
                      className="p-5 rounded-[16px] border border-border-light hover:border-border-light hover:shadow-sm transition-all flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white"
                    >
                      <div className="flex items-center gap-4 flex-1 min-w-0">
                        <div className={`w-14 h-14 rounded-[16px] ${project.bg} flex items-center justify-center shrink-0`}>
                          <project.icon className="w-6 h-6" style={{ color: project.color }} />
                        </div>
                        <div>
                          <h4 className="text-[15px] font-bold text-text-main truncate mb-1">{project.title}</h4>
                          <p className="text-[12px] font-semibold text-text-muted">
                            {project.domain} • {project.rollId}
                          </p>
                          <p className="text-[11px] text-text-muted font-bold mt-1">
                            Guide: {project.guide} • {project.members} Members
                          </p>
                        </div>
                      </div>
                      
                      <div className="flex items-center gap-8 shrink-0">
                        <div className="hidden md:block text-center">
                          <p className="text-[10px] font-bold text-text-muted uppercase mb-0.5">Batch</p>
                          <p className="text-[13px] font-bold text-text-main">{project.batch}</p>
                        </div>
                        <div className={`px-4 py-1.5 rounded-full border text-[11px] font-bold w-24 text-center ${project.statusColor}`}>
                          {project.status}
                        </div>
                        <div className="flex items-center -space-x-2">
                          <img src="https://ui-avatars.com/api/?name=St1&background=random" className="w-8 h-8 rounded-full border-2 border-white" alt="" />
                          <img src="https://ui-avatars.com/api/?name=St2&background=random" className="w-8 h-8 rounded-full border-2 border-white" alt="" />
                          <img src="https://ui-avatars.com/api/?name=St3&background=random" className="w-8 h-8 rounded-full border-2 border-white" alt="" />
                          {project.members > 3 && (
                            <div className="w-8 h-8 rounded-full border-2 border-white bg-page-bg text-text-muted text-[10px] font-bold flex items-center justify-center z-10">
                              +{project.members - 3}
                            </div>
                          )}
                        </div>
                        <MoreVertical className="w-5 h-5 text-text-muted cursor-pointer hover:text-text-main" />
                      </div>
                    </motion.div>
                  ))
                )}
              </AnimatePresence>
            </div>

            <AnimatePresence>
              {visibleCount < filteredProjects.length && (
                <motion.button layout initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} onClick={() => setVisibleCount(prev => prev + 3)} className="mt-6 w-full py-3.5 bg-page-bg text-primary-purple rounded-[12px] text-[13px] font-bold flex items-center justify-center gap-2 hover:bg-page-bg transition-colors">
                  Load More Projects <ChevronDown className="w-4 h-4" />
                </motion.button>
              )}
            </AnimatePresence>
          </div>
        </div>

        {/* Right Column - Status & Domains */}
        <div className="space-y-6">
          
          {/* Project Status Overview */}
          <div className="bg-white rounded-[20px] shadow-[0_2px_12px_rgba(0,0,0,0.02)] border border-border-light p-6">
            <h3 className="text-[16px] font-bold text-text-main mb-6">Project Status Overview</h3>
            <div className="flex items-center gap-6">
              {/* Fake Donut Chart SVG */}
              <div className="relative w-28 h-28 shrink-0">
                <svg viewBox="0 0 36 36" className="w-full h-full -rotate-90">
                  <circle cx="18" cy="18" r="16" fill="none" className="stroke-primary-purple" strokeWidth="6" strokeDasharray="44 100" strokeDashoffset="0"></circle>
                  <circle cx="18" cy="18" r="16" fill="none" className="stroke-electric-blue" strokeWidth="6" strokeDasharray="19 100" strokeDashoffset="-44"></circle>
                  <circle cx="18" cy="18" r="16" fill="none" className="stroke-electric-blue" strokeWidth="6" strokeDasharray="36 100" strokeDashoffset="-63"></circle>
                  <circle cx="18" cy="18" r="16" fill="none" className="stroke-illus-gold" strokeWidth="6" strokeDasharray="2 100" strokeDashoffset="-99"></circle>
                </svg>
              </div>
              <div className="flex-1 space-y-2.5">
                {[
                  { label: 'Active', pct: '44%', val: 28, color: 'bg-primary-purple' },
                  { label: 'Review', pct: '19%', val: 12, color: 'bg-electric-blue' },
                  { label: 'Completed', pct: '36%', val: 23, color: 'bg-electric-blue' },
                  { label: 'On Hold', pct: '2%', val: 1, color: 'bg-illus-gold' },
                  { label: 'Archived', pct: '0%', val: 0, color: 'bg-deep-violet' },
                ].map((s, i) => (
                  <div key={i} className="flex items-center justify-between">
                    <div className="flex items-center gap-2"><div className={`w-2.5 h-2.5 rounded-full ${s.color}`}></div><span className="text-[12px] font-bold text-text-main">{s.label}</span></div>
                    <span className="text-[11px] text-text-muted font-semibold">{s.val} ({s.pct})</span>
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* Top Domains */}
          <div className="bg-white rounded-[20px] shadow-[0_2px_12px_rgba(0,0,0,0.02)] border border-border-light p-6">
            <div className="flex justify-between items-center mb-6">
              <h3 className="text-[16px] font-bold text-text-main">Top Domains</h3>
              <Link href="#" className="text-[12px] font-bold text-primary-purple">View All</Link>
            </div>
            <div className="space-y-4">
              {[
                { name: 'Artificial Intelligence', val: 18, pct: 100, color: 'bg-gradient-to-r from-primary-purple to-[#A78BFA]', icon: '🤖' },
                { name: 'Web Development', val: 14, pct: 80, color: 'bg-gradient-to-r from-[#3B82F6] to-[#93C5FD]', icon: '🌐' },
                { name: 'Machine Learning', val: 10, pct: 60, color: 'bg-gradient-to-r from-[#10B981] to-[#6EE7B7]', icon: '🧠' },
                { name: 'IoT & Embedded', val: 8, pct: 45, color: 'bg-gradient-to-r from-[#F59E0B] to-[#FCD34D]', icon: '🔌' },
                { name: 'Blockchain', val: 7, pct: 35, color: 'bg-gradient-to-r from-[#F43F5E] to-[#FDA4AF]', icon: '⛓️' },
                { name: 'Other Domains', val: 7, pct: 35, color: 'bg-gradient-to-r from-[#94A3B8] to-[#CBD5E1]', icon: '📂' },
              ].map((domain, i) => (
                <div key={i}>
                  <div className="flex items-center justify-between mb-1.5">
                    <div className="flex items-center gap-1.5">
                      <div className="w-5 h-5 rounded bg-page-bg flex items-center justify-center text-[10px]">{domain.icon}</div>
                      <span className="text-[12px] font-bold text-text-main">{domain.name}</span>
                    </div>
                    <span className="text-[12px] font-bold text-text-muted">{domain.val}</span>
                  </div>
                  <div className="w-full h-1.5 bg-page-bg rounded-full overflow-hidden">
                    <div className={`h-full rounded-full ${domain.color}`} style={{ width: `${domain.pct}%` }}></div>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Recent Project Updates */}
          <div className="bg-white rounded-[20px] shadow-[0_2px_12px_rgba(0,0,0,0.02)] border border-border-light p-6">
            <div className="flex justify-between items-center mb-6">
              <h3 className="text-[16px] font-bold text-text-main">Recent Project Updates</h3>
              <Link href="#" className="text-[12px] font-bold text-primary-purple">View All</Link>
            </div>
            <div className="space-y-5">
              {[
                { title: 'AI-Powered Code Quality Analysis Tool', desc: 'Report submitted for review', time: '2h ago', bg: 'bg-page-bg', color: 'text-primary-purple' },
                { title: 'Smart Hydroponics Monitoring System', desc: 'Presentation scheduled', time: '5h ago', bg: 'bg-white', color: 'text-electric-blue' },
                { title: 'E-Commerce Recommendation System', desc: 'Guide feedback added', time: '1d ago', bg: 'bg-white', color: 'text-illus-gold' },
              ].map((upd, i) => (
                <div key={i} className="flex items-start gap-3 relative before:absolute before:left-4 before:top-8 before:bottom-[-20px] before:w-[2px] before:bg-page-bg last:before:hidden">
                  <div className={`w-8 h-8 rounded-full ${upd.bg} flex items-center justify-center shrink-0 z-10 border border-white shadow-sm`}>
                    <Clock className={`w-3.5 h-3.5 ${upd.color}`} />
                  </div>
                  <div>
                    <p className="text-[13px] font-bold text-text-main leading-snug">{upd.title}</p>
                    <p className="text-[11px] font-semibold text-text-muted mt-0.5">{upd.desc}</p>
                  </div>
                  <span className="text-[10px] font-bold text-text-muted ml-auto shrink-0 flex items-center gap-1">{upd.time} <span className={`w-1.5 h-1.5 rounded-full ${upd.bg.replace('bg-', 'bg-').replace('50', '500')}`} style={{backgroundColor: upd.color.replace('text-[', '').replace(']', '')}}></span></span>
                </div>
              ))}
            </div>
            
            <div className="mt-8 pt-4 border-t border-border-light flex justify-center">
              <Link href="#" className="text-[12px] font-bold text-primary-purple flex items-center gap-1.5">View All Updates →</Link>
            </div>
          </div>

        </div>

      </div>
    </div>
  );
}
