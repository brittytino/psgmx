'use client';

import React from 'react';
import { motion } from 'framer-motion';
import { Megaphone, Plus, Calendar, Folder, AlertTriangle, Users, Search, Filter, ChevronDown, MoreVertical, Send, FileText, Settings, Archive, Sparkles, CheckCircle, Clock } from 'lucide-react';
import Link from 'next/link';

import { AnimatePresence } from 'framer-motion';

export default function FacultyAnnouncementsDashboard() {
  const [activeTab, setActiveTab] = React.useState('All Broadcasts');
  const [searchQuery, setSearchQuery] = React.useState('');
  const [showNewModal, setShowNewModal] = React.useState(false);
  const [visibleCount, setVisibleCount] = React.useState(2);
  const [toastMessage, setToastMessage] = React.useState('');

  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(''), 3000);
  };

  const announcements = [
    { id: 1, title: 'Internal Assessment Schedule - May 2025', desc: 'The detailed schedule for the upcoming internal assessments has been finalized. Please review the timetable and ensure all project submissions are completed prior to your scheduled slots.', icon: Calendar, color: '#6C3DFF', bg: 'bg-[#F5F3FF]', badge: 'Published', badgeColor: 'bg-[#ECFDF5] text-[#059669]', meta: 'Published 2 hours ago • Seen by 112 students' },
    { id: 2, title: 'Mini Project Submission Guidelines', desc: 'Final guidelines for formatting your mini project documentation. Ensure you follow the IEEE format strictly. Submissions not adhering to the format will be returned.', icon: Folder, color: '#F59E0B', bg: 'bg-[#FFFBEB]', badge: 'Scheduled', badgeColor: 'bg-[#FFFBEB] text-[#D97706]', meta: 'Scheduled for May 18, 10:00 AM • 25 recipients' },
    { id: 3, title: 'Emergency Server Maintenance Notice', desc: 'The department servers will be undergoing emergency maintenance tonight from 10 PM to 2 AM. During this time, the FYP repository will be inaccessible.', icon: AlertTriangle, color: '#F43F5E', bg: 'bg-[#FFF1F2]', badge: 'Active Alert', badgeColor: 'bg-[#FEF2F2] text-[#DC2626]', meta: 'Published 1 day ago • Seen by 142 students' },
    { id: 4, title: 'Guest Lecture on Artificial Intelligence', desc: 'Join us for a special guest lecture by Dr. Ramesh from IIT Madras on recent advancements in Large Language Models and their applications.', icon: Users, color: '#06B6D4', bg: 'bg-[#ECFEFF]', badge: 'Published', badgeColor: 'bg-[#ECFDF5] text-[#059669]', meta: 'Published 2 days ago • Seen by 135 students' },
  ];

  const filteredAnnouncements = announcements.filter(a => {
    const matchesSearch = a.title.toLowerCase().includes(searchQuery.toLowerCase()) || a.desc.toLowerCase().includes(searchQuery.toLowerCase());
    if (!matchesSearch) return false;
    
    if (activeTab === 'Published') return a.badge === 'Published' || a.badge === 'Active Alert';
    if (activeTab === 'Scheduled') return a.badge === 'Scheduled';
    if (activeTab === 'Drafts') return false; // Simulated empty state
    return true; // All Broadcasts
  });

  const displayedAnnouncements = filteredAnnouncements.slice(0, visibleCount);

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
            <Megaphone className="w-6 h-6 text-white" />
          </div>
          <div>
            <motion.h1 
              initial={{ opacity: 0, y: -10 }}
              animate={{ opacity: 1, y: 0 }}
              className="text-[26px] font-bold text-[#1E293B] tracking-tight mb-0.5"
            >
              Announcements
            </motion.h1>
            <motion.p 
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 0.1 }}
              className="text-[14px] text-[#64748B]"
            >
              Broadcast important updates, schedules, and alerts to students.
            </motion.p>
          </div>
        </div>
        <button onClick={() => setShowNewModal(true)} className="flex items-center gap-2 px-6 py-3 bg-[#6C3DFF] text-white rounded-xl text-[14px] font-bold shadow-md shadow-[#6C3DFF]/20 hover:bg-[#5B21B6] transition-colors shrink-0">
          <Plus className="w-4 h-4" /> New Announcement
        </button>
      </div>

      {/* New Announcement Modal */}
      <AnimatePresence>
        {showNewModal && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
            <div className="absolute inset-0 bg-[#1E293B]/20 backdrop-blur-sm" onClick={() => setShowNewModal(false)}></div>
            <motion.div initial={{ opacity: 0, scale: 0.95 }} animate={{ opacity: 1, scale: 1 }} exit={{ opacity: 0, scale: 0.95 }} className="bg-white rounded-2xl shadow-xl w-full max-w-lg p-6 relative z-10 border border-[#F1F5F9]">
              <h3 className="text-[18px] font-bold text-[#1E293B] mb-4">Create New Announcement</h3>
              <div className="space-y-4">
                <div>
                  <label className="text-[12px] font-bold text-[#475569] block mb-1">Title</label>
                  <input type="text" placeholder="Enter title" className="w-full border border-[#E2E8F0] rounded-xl px-4 py-3 text-[14px] font-semibold text-[#1E293B] outline-none focus:border-[#6C3DFF]" />
                </div>
                <div>
                  <label className="text-[12px] font-bold text-[#475569] block mb-1">Message</label>
                  <textarea placeholder="Type your message here..." rows={4} className="w-full border border-[#E2E8F0] rounded-xl px-4 py-3 text-[14px] font-semibold text-[#1E293B] outline-none focus:border-[#6C3DFF] resize-none"></textarea>
                </div>
                <div className="flex justify-end gap-3 pt-2">
                  <button onClick={() => setShowNewModal(false)} className="px-5 py-2.5 bg-[#F8F9FC] text-[#1E293B] rounded-xl text-[13px] font-bold hover:bg-[#F1F5F9] transition-colors">Cancel</button>
                  <button onClick={() => setShowNewModal(false)} className="px-5 py-2.5 bg-[#6C3DFF] text-white rounded-xl text-[13px] font-bold shadow-md hover:bg-[#5B21B6] transition-colors flex items-center gap-2"><Send className="w-4 h-4" /> Publish Now</button>
                </div>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

      {/* 4 Stat Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {[
          { title: 'Total Broadcasts', value: '48', trend: '↑ 5 this month', color: '#6C3DFF', bg: 'bg-[#F5F3FF]', icon: Send },
          { title: 'Read Rate', value: '86%', trend: '↑ 2% vs last month', color: '#06B6D4', bg: 'bg-[#ECFEFF]', icon: CheckCircle },
          { title: 'Scheduled', value: '3', trend: 'Next: Tomorrow, 10 AM', color: '#F59E0B', bg: 'bg-[#FFFBEB]', icon: Clock },
          { title: 'Active Alerts', value: '1', trend: 'Urgent notice active', color: '#F43F5E', bg: 'bg-[#FFF1F2]', icon: AlertTriangle },
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
                <p className={`text-[11px] font-bold ${stat.trend.includes('Urgent') || stat.trend.includes('↓') ? 'text-[#F43F5E]' : stat.color === '#F59E0B' ? 'text-[#F59E0B]' : 'text-[#10B981]'}`}>{stat.trend}</p>
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

      {/* Main Content Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        
        {/* Left Column - Announcements List */}
        <div className="lg:col-span-2 space-y-6">
          <div className="bg-white rounded-[20px] shadow-[0_2px_12px_rgba(0,0,0,0.02)] border border-[#F1F5F9] p-6 flex flex-col h-full">
            
            {/* Tabs & Controls */}
            <div className="border-b border-[#E2E8F0] flex flex-col md:flex-row md:items-end justify-between gap-4 pb-0 mb-6">
              <div className="flex items-center gap-6 overflow-x-auto custom-scrollbar pb-[-1px]">
                {['All Broadcasts', 'Published', 'Scheduled', 'Drafts'].map(tab => (
                  <button 
                    key={tab}
                    onClick={() => setActiveTab(tab)}
                    className={`text-[14px] pb-4 px-1 whitespace-nowrap transition-colors ${activeTab === tab ? 'font-bold text-[#6C3DFF] border-b-2 border-[#6C3DFF]' : 'font-semibold text-[#64748B] hover:text-[#1E293B] border-b-2 border-transparent'}`}
                  >
                    {tab}
                  </button>
                ))}
              </div>
              <div className="flex items-center gap-3 pb-4">
                <div className="relative">
                  <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-[#94A3B8]" />
                  <input type="text" value={searchQuery} onChange={(e) => setSearchQuery(e.target.value)} placeholder="Search broadcasts..." className="pl-9 pr-4 py-2 border border-[#E2E8F0] rounded-xl text-[13px] w-[200px] outline-none focus:border-[#6C3DFF] transition-colors bg-white" />
                </div>
                <button className="flex items-center gap-2 px-3 py-2 border border-[#E2E8F0] rounded-xl text-[13px] font-bold text-[#1E293B] hover:bg-[#F8F9FC] transition-colors">
                  <Filter className="w-4 h-4" />
                </button>
              </div>
            </div>

            {/* List */}
            <div className="space-y-4">
              <AnimatePresence mode="popLayout">
                {displayedAnnouncements.length === 0 ? (
                  <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="py-8 text-center text-[#94A3B8] text-[13px] font-semibold">
                    No announcements found for this tab.
                  </motion.div>
                ) : (
                  displayedAnnouncements.map((item) => (
                    <motion.div layout initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, scale: 0.95 }} key={item.id} className="p-5 rounded-[16px] border border-[#F1F5F9] hover:border-[#E2E8F0] hover:shadow-sm transition-all flex flex-col sm:flex-row sm:items-start gap-4 cursor-pointer bg-white">
                      <div className={`w-12 h-12 rounded-[12px] ${item.bg} flex items-center justify-center shrink-0`}>
                        <item.icon className="w-5 h-5" style={{ color: item.color }} />
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2 mb-1.5 flex-wrap">
                          <h4 className="text-[15px] font-bold text-[#1E293B] truncate">{item.title}</h4>
                          <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold border border-transparent ${item.badgeColor}`}>{item.badge}</span>
                        </div>
                        <p className="text-[13px] text-[#64748B] leading-relaxed line-clamp-2 max-w-2xl mb-3">{item.desc}</p>
                        <p className="text-[11px] font-semibold text-[#94A3B8] flex items-center gap-1.5">
                          {item.badge === 'Scheduled' ? <Clock className="w-3.5 h-3.5" /> : item.badge === 'Active Alert' ? <AlertTriangle className="w-3.5 h-3.5 text-[#F43F5E]" /> : <CheckCircle className="w-3.5 h-3.5 text-[#059669]" />}
                          {item.meta}
                        </p>
                      </div>
                      <div className="shrink-0">
                        <button className="p-2 text-[#94A3B8] hover:text-[#1E293B] hover:bg-[#F8F9FC] rounded-lg transition-colors">
                          <MoreVertical className="w-4 h-4" />
                        </button>
                      </div>
                    </motion.div>
                  ))
                )}
              </AnimatePresence>
            </div>

            <AnimatePresence>
              {visibleCount < filteredAnnouncements.length && (
                <motion.button layout initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} onClick={() => setVisibleCount(prev => prev + 2)} className="mt-6 w-full py-3.5 bg-[#F8F9FC] text-[#6C3DFF] rounded-[12px] text-[13px] font-bold flex items-center justify-center gap-2 hover:bg-[#F1F5F9] transition-colors">
                  Load More Announcements <ChevronDown className="w-4 h-4" />
                </motion.button>
              )}
            </AnimatePresence>
          </div>
        </div>

        {/* Right Column */}
        <div className="space-y-6">
          
          {/* Quick Actions */}
          <div className="bg-white rounded-[20px] shadow-[0_2px_12px_rgba(0,0,0,0.02)] border border-[#F1F5F9] p-6">
            <h3 className="text-[16px] font-bold text-[#1E293B] mb-5">Quick Actions</h3>
            <div className="grid grid-cols-2 gap-4">
              <button onClick={() => showToast('Draft Created')} className="p-4 rounded-[16px] bg-[#F8F6FF] border border-[#E5D4FF]/50 flex flex-col items-center justify-center gap-2 hover:bg-[#E5D4FF]/40 transition-colors group">
                <div className="w-8 h-8 rounded-full bg-white flex items-center justify-center shadow-sm">
                  <PenToolIcon className="w-4 h-4 text-[#6C3DFF]" />
                </div>
                <span className="text-[13px] font-bold text-[#6C3DFF]">Create<br/>Draft</span>
              </button>
              <button onClick={() => showToast('Message Templates Loaded')} className="p-4 rounded-[16px] bg-[#EFF6FF] border border-[#BFDBFE]/50 flex flex-col items-center justify-center gap-2 hover:bg-[#DBEAFE]/50 transition-colors">
                <div className="w-8 h-8 rounded-full bg-white flex items-center justify-center shadow-sm">
                  <FileText className="w-4 h-4 text-[#3B82F6]" />
                </div>
                <span className="text-[13px] font-bold text-[#3B82F6]">Message<br/>Templates</span>
              </button>
              <button onClick={() => showToast('Viewing Archives...')} className="p-4 rounded-[16px] bg-[#ECFEFF] border border-[#A5F3FC]/50 flex flex-col items-center justify-center gap-2 hover:bg-[#CFFAFE]/50 transition-colors">
                <div className="w-8 h-8 rounded-full bg-white flex items-center justify-center shadow-sm">
                  <Archive className="w-4 h-4 text-[#06B6D4]" />
                </div>
                <span className="text-[13px] font-bold text-[#06B6D4]">View<br/>Archive</span>
              </button>
              <button onClick={() => showToast('Opening Settings...')} className="p-4 rounded-[16px] bg-[#FFFBEB] border border-[#FDE68A]/50 flex flex-col items-center justify-center gap-2 hover:bg-[#FEF3C7]/50 transition-colors">
                <div className="w-8 h-8 rounded-full bg-white flex items-center justify-center shadow-sm">
                  <Settings className="w-4 h-4 text-[#F59E0B]" />
                </div>
                <span className="text-[13px] font-bold text-[#F59E0B]">Channel<br/>Settings</span>
              </button>
            </div>
          </div>

          {/* Announcement Impact Chart */}
          <div className="bg-white rounded-[20px] shadow-[0_2px_12px_rgba(0,0,0,0.02)] border border-[#F1F5F9] p-6">
            <h3 className="text-[16px] font-bold text-[#1E293B] mb-6">Announcement Reach</h3>
            <div className="relative h-[200px] mt-2">
              <div className="absolute left-0 top-0 bottom-6 w-8 flex flex-col justify-between text-[10px] font-semibold text-[#94A3B8]">
                <span>100%</span><span>75%</span><span>50%</span><span>25%</span><span>0%</span>
              </div>
              <div className="absolute left-10 right-0 top-2 bottom-6">
                <div className="absolute inset-0 flex flex-col justify-between">
                  {[...Array(5)].map((_, i) => (
                    <div key={i} className="w-full border-t border-[#F8F9FC] h-0"></div>
                  ))}
                </div>
                <svg viewBox="0 0 1000 200" preserveAspectRatio="none" className="absolute inset-0 w-full h-full overflow-visible">
                  <defs>
                    <linearGradient id="reachGrad" x1="0%" y1="0%" x2="0%" y2="100%">
                      <stop offset="0%" stopColor="#06B6D4" stopOpacity="0.3" />
                      <stop offset="100%" stopColor="#06B6D4" stopOpacity="0" />
                    </linearGradient>
                  </defs>
                  <path d="M0,150 C200,140 300,180 500,120 C700,60 800,90 1000,40 L1000,200 L0,200 Z" fill="url(#reachGrad)" />
                  <path d="M0,150 C200,140 300,180 500,120 C700,60 800,90 1000,40" fill="none" stroke="#06B6D4" strokeWidth="4" />
                  
                  <circle cx="500" cy="120" r="4" fill="white" stroke="#06B6D4" strokeWidth="2" />
                  <circle cx="1000" cy="40" r="6" fill="#06B6D4" stroke="white" strokeWidth="3" />
                </svg>
                
                <div className="absolute left-[100%] top-[30px] -translate-x-1/2 -translate-y-full mb-2 bg-white border border-[#E2E8F0] shadow-md rounded-xl px-3 py-1.5 text-center pointer-events-none z-10">
                  <p className="text-[12px] font-black text-[#1E293B]">86% <span className="text-[10px] font-semibold text-[#64748B]">Read</span></p>
                  <div className="absolute -bottom-1.5 left-1/2 -translate-x-1/2 w-3 h-3 bg-white border-b border-r border-[#E2E8F0] rotate-45"></div>
                </div>
              </div>
              <div className="absolute left-10 right-0 bottom-0 flex justify-between text-[10px] font-semibold text-[#94A3B8]">
                <span>Mon</span><span>Tue</span><span>Wed</span><span>Thu</span><span>Fri</span><span>Sat</span><span>Sun</span>
              </div>
            </div>
          </div>

          {/* Bottom Banner */}
          <div className="bg-[#FFF1F2] rounded-[20px] p-6 border border-[#FDA4AF]/50 relative overflow-hidden group cursor-pointer hover:border-[#FDA4AF] transition-colors">
            <div className="flex items-start gap-4 relative z-10">
              <div className="w-10 h-10 rounded-full bg-white flex items-center justify-center shrink-0 shadow-sm">
                <AlertTriangle className="w-5 h-5 text-[#F43F5E]" />
              </div>
              <div>
                <h4 className="text-[15px] font-bold text-[#F43F5E] mb-1">Important Notice</h4>
                <p className="text-[13px] text-[#881337] font-medium leading-snug">The upcoming internal assessment dates have changed. Need to inform the 2025 batch immediately?</p>
                <button onClick={() => setShowNewModal(true)} className="mt-4 px-4 py-2 bg-[#F43F5E] text-white rounded-lg text-[12px] font-bold shadow-sm">Draft Broadcast</button>
              </div>
            </div>
            <div className="absolute -right-10 -bottom-10 opacity-10 transform rotate-12 group-hover:rotate-0 transition-transform duration-500">
              <Megaphone className="w-40 h-40 text-[#F43F5E]" />
            </div>
          </div>

        </div>

      </div>
    </div>
  );
}

function PenToolIcon(props: any) {
  return <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...props}><path d="m12 19 7-7 3 3-7 7-3-3z"/><path d="m18 13-1.5-7.5L2 2l3.5 14.5L13 18l5-5z"/><path d="m2 2 7.586 7.586"/><circle cx="11" cy="11" r="2"/></svg>
}
