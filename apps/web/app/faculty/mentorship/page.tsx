'use client';

import React from 'react';
import { motion } from 'framer-motion';
import { Users, Plus, Search, Filter, ChevronDown, MoreVertical, Calendar, Clock, CheckCircle, AlertCircle, FileText, Video, MessageSquare } from 'lucide-react';
import Link from 'next/link';

import { AnimatePresence } from 'framer-motion';

export default function FacultyMentorshipDashboard() {
  const [activeTab, setActiveTab] = React.useState('All Mentees');
  const [searchQuery, setSearchQuery] = React.useState('');
  const [showScheduleModal, setShowScheduleModal] = React.useState(false);
  const [visibleCount, setVisibleCount] = React.useState(3);
  const [toastMessage, setToastMessage] = React.useState('');

  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(''), 3000);
  };

  const mentees = [
    { id: 1, name: 'Arjun Mehta', roll: '25MX301', next: 'May 18, 10:00 AM', status: 'On Track', statusColor: 'bg-white text-electric-blue border-electric-blue/30', progress: 85 },
    { id: 2, name: 'Sara Khan', roll: '25MX205', next: 'May 20, 2:30 PM', status: 'Needs Attention', statusColor: 'bg-white text-illus-gold border-illus-gold/30', progress: 55 },
    { id: 3, name: 'Rohan Verma', roll: '25MX114', next: 'No upcoming sessions', status: 'Critical', statusColor: 'bg-page-bg text-deep-violet border-deep-violet/30', progress: 30 },
    { id: 4, name: 'Neha Sharma', roll: '25MX402', next: 'May 22, 11:00 AM', status: 'On Track', statusColor: 'bg-white text-electric-blue border-electric-blue/30', progress: 92 },
    { id: 5, name: 'Ali Raza', roll: '25MX310', next: 'May 25, 3:00 PM', status: 'On Track', statusColor: 'bg-white text-electric-blue border-electric-blue/30', progress: 78 },
  ];

  const filteredMentees = mentees.filter(m => {
    const matchesSearch = m.name.toLowerCase().includes(searchQuery.toLowerCase()) || m.roll.toLowerCase().includes(searchQuery.toLowerCase());
    if (!matchesSearch) return false;
    
    if (activeTab === 'Needs Attention') return m.status === 'Needs Attention' || m.status === 'Critical';
    if (activeTab === 'Recent Activity') return m.progress > 70; // simulated logic
    return true; // All
  });

  const displayedMentees = filteredMentees.slice(0, visibleCount);

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
            <GraduationCapIcon className="w-6 h-6 text-white" />
          </div>
          <div>
            <motion.h1 
              initial={{ opacity: 0, y: -10 }}
              animate={{ opacity: 1, y: 0 }}
              className="text-[26px] font-bold text-text-main tracking-tight mb-0.5"
            >
              Mentorship
            </motion.h1>
            <motion.p 
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 0.1 }}
              className="text-[14px] text-text-muted"
            >
              Manage mentees, schedule 1-on-1 sessions, and track their holistic progress.
            </motion.p>
          </div>
        </div>
        <div className="flex items-center gap-3 shrink-0">
          <button onClick={() => showToast('Opening Messenger...')} className="flex items-center gap-2 px-6 py-3 bg-white border border-border-light text-text-main rounded-xl text-[14px] font-bold shadow-sm hover:bg-page-bg transition-colors">
            <MessageSquare className="w-4 h-4" /> Message All
          </button>
          <button onClick={() => setShowScheduleModal(true)} className="flex items-center gap-2 px-6 py-3 bg-primary-purple text-white rounded-xl text-[14px] font-bold shadow-md shadow-md shadow-primary-purple/10 hover:bg-[#5B21B6] transition-colors">
            <Plus className="w-4 h-4" /> Schedule Session
          </button>
        </div>
      </div>

      {/* Schedule Modal */}
      <AnimatePresence>
        {showScheduleModal && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
            <div className="absolute inset-0 bg-rich-black/20 backdrop-blur-sm" onClick={() => setShowScheduleModal(false)}></div>
            <motion.div initial={{ opacity: 0, scale: 0.95 }} animate={{ opacity: 1, scale: 1 }} exit={{ opacity: 0, scale: 0.95 }} className="bg-white rounded-2xl shadow-xl w-full max-w-md p-6 relative z-10 border border-border-light">
              <h3 className="text-[18px] font-bold text-text-main mb-4">Schedule a Session</h3>
              <div className="space-y-4">
                <div>
                  <label className="text-[12px] font-bold text-text-muted block mb-1">Select Mentee</label>
                  <select className="w-full border border-border-light rounded-xl px-4 py-3 text-[14px] font-semibold text-text-main outline-none focus:border-primary-purple">
                    <option>Arjun Mehta</option>
                    <option>Sara Khan</option>
                  </select>
                </div>
                <div>
                  <label className="text-[12px] font-bold text-text-muted block mb-1">Date & Time</label>
                  <input type="datetime-local" className="w-full border border-border-light rounded-xl px-4 py-3 text-[14px] font-semibold text-text-main outline-none focus:border-primary-purple" />
                </div>
                <button onClick={() => setShowScheduleModal(false)} className="w-full py-3 bg-primary-purple text-white rounded-xl text-[14px] font-bold shadow-md mt-2">
                  Confirm Schedule
                </button>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

      {/* 4 Stat Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {[
          { title: 'Total Mentees', value: '24', trend: 'Assigned for 2021-2025', color: "var(--primary-purple)", bg: 'bg-page-bg', icon: Users },
          { title: 'Sessions This Month', value: '16', trend: '↑ 4 vs last month', color: "var(--primary-purple)", bg: 'bg-page-bg', icon: Video },
          { title: 'Pending Feedback', value: '3', trend: 'Needs your review', color: "var(--illus-gold)", bg: 'bg-white', icon: FileText },
          { title: 'Avg. Rating', value: '4.8 / 5', trend: '↑ 0.2 from students', color: '#FCD34D', bg: 'bg-page-bg', icon: StarIcon },
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
                <p className={`text-[11px] font-bold ${stat.trend.includes('Needs') ? 'text-illus-gold' : 'text-electric-blue'}`}>{stat.trend}</p>
              </div>
            </div>
          </motion.div>
        ))}
      </div>

      {/* Main Content Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        
        {/* Left Column - Mentees List */}
        <div className="lg:col-span-2 space-y-6">
          <div className="bg-white rounded-[20px] shadow-[0_2px_12px_rgba(0,0,0,0.02)] border border-border-light overflow-hidden flex flex-col h-full">
            
            {/* Tabs & Controls */}
            <div className="px-6 pt-6 border-b border-border-light flex flex-col md:flex-row md:items-end justify-between gap-4">
              <div className="flex items-center gap-6 overflow-x-auto custom-scrollbar pb-[-1px]">
                {['All Mentees', 'Needs Attention', 'Recent Activity'].map(tab => (
                  <button 
                    key={tab}
                    onClick={() => setActiveTab(tab)}
                    className={`text-[14px] pb-4 px-1 whitespace-nowrap transition-colors ${activeTab === tab ? 'font-bold text-primary-purple border-b-2 border-primary-purple' : 'font-semibold text-text-muted hover:text-text-main border-b-2 border-transparent'}`}
                  >
                    {tab}
                  </button>
                ))}
              </div>
              <div className="flex items-center gap-3 pb-4">
                <div className="relative">
                  <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-text-muted" />
                  <input type="text" value={searchQuery} onChange={(e) => setSearchQuery(e.target.value)} placeholder="Search mentees..." className="pl-9 pr-4 py-2 border border-border-light rounded-xl text-[13px] w-[200px] outline-none focus:border-primary-purple transition-colors bg-white" />
                </div>
                <button className="flex items-center gap-2 px-3 py-2 border border-border-light rounded-xl text-[13px] font-bold text-text-main hover:bg-page-bg transition-colors">
                  <Filter className="w-4 h-4" />
                </button>
              </div>
            </div>

            {/* List */}
            <div className="overflow-x-auto p-6">
              <div className="space-y-4">
                <AnimatePresence mode="popLayout">
                  {displayedMentees.length === 0 ? (
                    <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="py-8 text-center text-text-muted text-[13px] font-semibold">
                      No mentees found matching your search.
                    </motion.div>
                  ) : (
                    displayedMentees.map((mentee) => (
                      <motion.div layout initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, scale: 0.95 }} key={mentee.id} className="flex flex-col sm:flex-row sm:items-center justify-between p-4 rounded-[16px] border border-border-light hover:border-border-light hover:shadow-sm transition-all gap-4 bg-white">
                        <div className="flex items-center gap-4">
                          <img src={`https://ui-avatars.com/api/?name=${encodeURIComponent(mentee.name)}&background=random`} alt="" className="w-12 h-12 rounded-full border border-border-light" />
                          <div>
                            <h4 className="text-[14px] font-bold text-text-main cursor-pointer hover:text-primary-purple transition-colors">{mentee.name}</h4>
                            <p className="text-[12px] text-text-muted">{mentee.roll}</p>
                          </div>
                        </div>
                        
                        <div className="flex-1 max-w-[200px] hidden md:block">
                          <p className="text-[11px] font-bold text-text-muted mb-1">Overall Progress</p>
                          <div className="flex items-center gap-2">
                            <div className="flex-1 h-1.5 bg-page-bg rounded-full overflow-hidden">
                              <div className={`h-full rounded-full ${mentee.progress > 80 ? 'bg-electric-blue' : mentee.progress > 50 ? 'bg-illus-gold' : 'bg-deep-violet'}`} style={{ width: `${mentee.progress}%` }}></div>
                            </div>
                            <span className="text-[11px] font-bold text-text-main">{mentee.progress}%</span>
                          </div>
                        </div>

                        <div className="hidden lg:block">
                          <p className="text-[11px] font-bold text-text-muted mb-1">Next Session</p>
                          <p className={`text-[12px] font-semibold ${mentee.next.includes('No') ? 'text-text-muted' : 'text-text-main'}`}>{mentee.next}</p>
                        </div>

                        <div className="flex items-center justify-between sm:justify-end gap-6 shrink-0 w-full sm:w-auto">
                          <span className={`px-3 py-1 rounded-full text-[11px] font-bold border ${mentee.statusColor} flex items-center gap-1.5 w-[120px] justify-center`}>
                            <span className={`w-1.5 h-1.5 rounded-full ${mentee.status === 'On Track' ? 'bg-electric-blue' : mentee.status === 'Needs Attention' ? 'bg-illus-gold' : 'bg-deep-violet'}`}></span>
                            {mentee.status}
                          </span>
                          <button className="p-2 text-text-muted hover:text-text-main hover:bg-page-bg rounded-lg transition-colors">
                            <MoreVertical className="w-4 h-4" />
                          </button>
                        </div>
                      </motion.div>
                    ))
                  )}
                </AnimatePresence>
              </div>
            </div>

            <div className="p-6 pt-0 mt-auto">
              <AnimatePresence>
                {visibleCount < filteredMentees.length && (
                  <motion.button layout initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} onClick={() => setVisibleCount(prev => prev + 3)} className="w-full py-3.5 bg-page-bg text-primary-purple rounded-[12px] text-[13px] font-bold flex items-center justify-center gap-2 hover:bg-page-bg transition-colors">
                    View All {filteredMentees.length} Mentees <ChevronDown className="w-4 h-4" />
                  </motion.button>
                )}
              </AnimatePresence>
            </div>
          </div>
        </div>

        {/* Right Column */}
        <div className="space-y-6">
          
          {/* Mentorship Overview Donut */}
          <div className="bg-white rounded-[20px] shadow-[0_2px_12px_rgba(0,0,0,0.02)] border border-border-light p-6">
            <h3 className="text-[16px] font-bold text-text-main mb-6">Mentee Status Overview</h3>
            
            <div className="flex items-center gap-6">
              <div className="relative w-28 h-28 shrink-0">
                <svg viewBox="0 0 36 36" className="w-full h-full -rotate-90">
                  <circle cx="18" cy="18" r="16" fill="none" className="stroke-[#F1F5F9]" strokeWidth="6"></circle>
                  <circle cx="18" cy="18" r="16" fill="none" className="stroke-electric-blue" strokeWidth="6" strokeDasharray="62 100" strokeDashoffset="0"></circle>
                  <circle cx="18" cy="18" r="16" fill="none" className="stroke-illus-gold" strokeWidth="6" strokeDasharray="25 100" strokeDashoffset="-62"></circle>
                  <circle cx="18" cy="18" r="16" fill="none" className="stroke-deep-violet" strokeWidth="6" strokeDasharray="13 100" strokeDashoffset="-87"></circle>
                </svg>
                <div className="absolute inset-0 flex flex-col items-center justify-center">
                  <span className="text-[24px] font-black text-text-main leading-none">24</span>
                  <span className="text-[9px] font-bold text-text-muted uppercase mt-0.5">Mentees</span>
                </div>
              </div>
              
              <div className="flex-1 space-y-3">
                {[
                  { label: 'On Track', count: 15, color: 'bg-electric-blue' },
                  { label: 'Needs Attention', count: 6, color: 'bg-illus-gold' },
                  { label: 'Critical', count: 3, color: 'bg-deep-violet' },
                ].map((s, i) => (
                  <div key={i} className="flex items-center justify-between">
                    <div className="flex items-center gap-2"><div className={`w-2.5 h-2.5 rounded-full ${s.color}`}></div><span className="text-[12px] font-bold text-text-main">{s.label}</span></div>
                    <span className="text-[12px] text-text-muted font-semibold">{s.count}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* Upcoming Sessions */}
          <div className="bg-white rounded-[20px] shadow-[0_2px_12px_rgba(0,0,0,0.02)] border border-border-light p-6">
            <div className="flex justify-between items-center mb-6">
              <h3 className="text-[16px] font-bold text-text-main">Upcoming Sessions</h3>
              <Link href="#" className="text-[12px] font-bold text-primary-purple">Calendar</Link>
            </div>
            
            <div className="space-y-4">
              {[
                { name: 'Arjun Mehta', topic: 'FYP Topic Discussion', time: 'Tomorrow, 10:00 AM', type: 'Video Call', icon: Video },
                { name: 'Sara Khan', topic: 'Career Guidance', time: 'May 20, 2:30 PM', type: 'In Person', icon: Users },
                { name: 'Neha Sharma', topic: 'Resume Review', time: 'May 22, 11:00 AM', type: 'Video Call', icon: Video },
              ].map((session, i) => (
                <div key={i} className="flex items-start gap-4 p-4 rounded-[16px] border border-border-light bg-page-bg/50 hover:bg-page-bg transition-colors">
                  <div className="w-10 h-10 rounded-full bg-white flex items-center justify-center shadow-sm shrink-0 border border-border-light">
                    <session.icon className="w-4 h-4 text-primary-purple" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-[13px] font-bold text-text-main truncate mb-0.5">{session.topic}</p>
                    <p className="text-[12px] font-semibold text-text-muted mb-2">with {session.name}</p>
                    <div className="flex items-center gap-3">
                      <span className="flex items-center gap-1 text-[11px] font-bold text-text-muted"><Clock className="w-3 h-3" /> {session.time}</span>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>

        </div>

      </div>
    </div>
  );
}

function GraduationCapIcon(props: any) {
  return <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...props}><path d="M21.42 10.922a2 2 0 0 1-.019 3.07l-9.28 8.1a2 2 0 0 1-2.634.024l-9.26-8.05a2.043 2.043 0 0 1 .023-3.092l9.27-8.01a2 2 0 0 1 2.628-.018z"/><path d="M14 11.6V17"/><path d="M10 11.6V17"/></svg>
}

function StarIcon(props: any) {
  return <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...props}><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
}
