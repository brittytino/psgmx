'use client';

import React from 'react';
import { motion } from 'framer-motion';
import { Target, Plus, Search, Filter, Phone, Mail, BookOpen, Clock, HeartHandshake, FileText, ChevronRight, Activity, CheckCircle, AlertTriangle } from 'lucide-react';
import Link from 'next/link';

import { AnimatePresence } from 'framer-motion';

export default function FacultyRecoveryHubDashboard() {
  const [searchQuery, setSearchQuery] = React.useState('');

  const cases = [
    { id: 1, name: 'Rohan Verma', issue: 'Consistent low attendance and poor performance in OS.', status: 'High Priority', color: 'bg-[#FEF2F2] text-[#DC2626] border-[#FECACA]', date: 'Opened May 10' },
    { id: 2, name: 'Ali Raza', issue: 'Struggling with FYP progress. Needs technical guidance.', status: 'In Progress', color: 'bg-[#EFF6FF] text-[#3B82F6] border-[#BFDBFE]', date: 'Opened May 12' },
    { id: 3, name: 'Zoya Fatima', issue: 'Requested extension due to health reasons.', status: 'Resolved', color: 'bg-[#ECFDF5] text-[#059669] border-[#A7F3D0]', date: 'Closed May 15' },
  ];

  const filteredCases = cases.filter(c => 
    c.name.toLowerCase().includes(searchQuery.toLowerCase()) || 
    c.issue.toLowerCase().includes(searchQuery.toLowerCase()) ||
    c.status.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="max-w-[1400px] mx-auto space-y-8 pb-8">
      
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div className="flex items-center gap-4">
          <div className="w-12 h-12 rounded-2xl bg-[#6C3DFF] flex items-center justify-center shadow-lg shadow-[#6C3DFF]/20 shrink-0">
            <Target className="w-6 h-6 text-white" />
          </div>
          <div>
            <motion.h1 
              initial={{ opacity: 0, y: -10 }}
              animate={{ opacity: 1, y: 0 }}
              className="text-[26px] font-bold text-[#1E293B] tracking-tight mb-0.5"
            >
              Recovery Hub
            </motion.h1>
            <motion.p 
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 0.1 }}
              className="text-[14px] text-[#64748B]"
            >
              Identify at-risk students, provide interventions, and track recovery progress.
            </motion.p>
          </div>
        </div>
        <button className="flex items-center gap-2 px-6 py-3 bg-[#6C3DFF] text-white rounded-xl text-[14px] font-bold shadow-md shadow-[#6C3DFF]/20 hover:bg-[#5B21B6] transition-colors shrink-0">
          <Plus className="w-4 h-4" /> Add Resource
        </button>
      </div>

      {/* 4 Stat Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {[
          { title: 'Students Assisted', value: '45', trend: '↑ 12 this semester', color: '#6C3DFF', bg: 'bg-[#F5F3FF]', icon: HeartHandshake },
          { title: 'Active Interventions', value: '12', trend: 'In progress', color: '#06B6D4', bg: 'bg-[#ECFEFF]', icon: Activity },
          { title: 'Resolved Cases', value: '28', trend: '↑ 8% recovery rate', color: '#10B981', bg: 'bg-[#ECFDF5]', icon: CheckCircle },
          { title: 'High Priority', value: '5', trend: 'Needs immediate action', color: '#F43F5E', bg: 'bg-[#FFF1F2]', icon: AlertTriangle },
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
                <p className={`text-[11px] font-bold ${stat.trend.includes('Needs') ? 'text-[#F43F5E]' : stat.trend.includes('progress') ? 'text-[#06B6D4]' : 'text-[#10B981]'}`}>{stat.trend}</p>
              </div>
            </div>
          </motion.div>
        ))}
      </div>

      {/* Main Content Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        
        {/* Left Column */}
        <div className="lg:col-span-2 space-y-8">
          
          {/* Support Resources */}
          <div>
            <h3 className="text-[18px] font-bold text-[#1E293B] mb-4">Support Resources</h3>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              {[
                { title: 'Academic Tutoring', desc: 'Connect students with peer tutors for difficult subjects.', icon: BookOpen, color: '#6C3DFF', bg: 'bg-[#F5F3FF]' },
                { title: 'Mental Health Support', desc: 'Confidential counseling services for stress and anxiety.', icon: HeartHandshake, color: '#10B981', bg: 'bg-[#ECFDF5]' },
                { title: 'Time Management Workshop', desc: 'Resources to help students balance coursework and projects.', icon: Clock, color: '#F59E0B', bg: 'bg-[#FFFBEB]' },
                { title: 'Study Material Archive', desc: 'Access to simplified notes and past question papers.', icon: FileText, color: '#3B82F6', bg: 'bg-[#EFF6FF]' },
              ].map((res, i) => (
                <div key={i} className="bg-white p-5 rounded-[20px] border border-[#F1F5F9] shadow-[0_2px_12px_rgba(0,0,0,0.02)] hover:border-[#E2E8F0] hover:shadow-sm transition-all cursor-pointer group">
                  <div className={`w-12 h-12 rounded-[12px] ${res.bg} flex items-center justify-center mb-4`}>
                    <res.icon className="w-6 h-6" style={{ color: res.color }} />
                  </div>
                  <h4 className="text-[15px] font-bold text-[#1E293B] mb-1 group-hover:text-[#6C3DFF] transition-colors">{res.title}</h4>
                  <p className="text-[13px] text-[#64748B] leading-relaxed mb-4">{res.desc}</p>
                  <div className="text-[12px] font-bold text-[#6C3DFF] flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity transform translate-x-[-10px] group-hover:translate-x-0">
                    Explore Resource <ChevronRight className="w-3.5 h-3.5" />
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Recent Support Cases */}
          <div className="bg-white rounded-[20px] shadow-[0_2px_12px_rgba(0,0,0,0.02)] border border-[#F1F5F9] overflow-hidden flex flex-col">
            <div className="p-6 border-b border-[#E2E8F0] flex flex-col md:flex-row md:items-center justify-between gap-4">
              <h3 className="text-[18px] font-bold text-[#1E293B]">Recent Support Cases</h3>
              <div className="flex items-center gap-3">
                <div className="relative">
                  <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-[#94A3B8]" />
                  <input type="text" value={searchQuery} onChange={(e) => setSearchQuery(e.target.value)} placeholder="Search cases..." className="pl-9 pr-4 py-2 border border-[#E2E8F0] rounded-xl text-[13px] w-[200px] outline-none focus:border-[#6C3DFF] transition-colors bg-white" />
                </div>
                <button className="flex items-center gap-2 px-3 py-2 border border-[#E2E8F0] rounded-xl text-[13px] font-bold text-[#1E293B] hover:bg-[#F8F9FC] transition-colors">
                  <Filter className="w-4 h-4" />
                </button>
              </div>
            </div>
            
            <div className="p-6 space-y-4">
              <AnimatePresence mode="popLayout">
                {filteredCases.length === 0 ? (
                  <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="py-8 text-center text-[#94A3B8] text-[13px] font-semibold">
                    No support cases match your search.
                  </motion.div>
                ) : (
                  filteredCases.map((case_) => (
                    <motion.div layout initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, scale: 0.95 }} key={case_.id} className="p-4 rounded-[16px] border border-[#F1F5F9] hover:border-[#E2E8F0] transition-colors flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white">
                      <div className="flex items-center gap-4">
                        <img src={`https://ui-avatars.com/api/?name=${encodeURIComponent(case_.name)}&background=random`} alt="" className="w-10 h-10 rounded-full" />
                        <div>
                          <h4 className="text-[14px] font-bold text-[#1E293B]">{case_.name}</h4>
                          <p className="text-[12px] text-[#64748B] mt-0.5">{case_.issue}</p>
                        </div>
                      </div>
                      <div className="flex items-center justify-between sm:justify-end gap-4 shrink-0">
                        <span className="text-[11px] font-semibold text-[#94A3B8] hidden md:block">{case_.date}</span>
                        <span className={`px-3 py-1 rounded-full text-[11px] font-bold border ${case_.color} w-[110px] text-center`}>
                          {case_.status}
                        </span>
                      </div>
                    </motion.div>
                  ))
                )}
              </AnimatePresence>
            </div>
          </div>

        </div>

        {/* Right Column */}
        <div className="space-y-6">
          
          {/* Need Immediate Help? */}
          <div className="bg-[#6C3DFF] rounded-[20px] p-6 text-white relative overflow-hidden">
            <div className="relative z-10">
              <div className="w-12 h-12 rounded-[14px] bg-white/20 flex items-center justify-center mb-5 backdrop-blur-sm">
                <Target className="w-6 h-6 text-white" />
              </div>
              <h3 className="text-[18px] font-bold mb-2">Need Immediate Help?</h3>
              <p className="text-[13px] text-white/80 leading-relaxed mb-6">If you or a student are experiencing an emergency, please contact the campus support services immediately.</p>
              
              <div className="space-y-3">
                <button className="w-full py-3 bg-white text-[#6C3DFF] rounded-xl text-[13px] font-bold flex items-center justify-center gap-2 hover:bg-[#F8F9FC] transition-colors">
                  <Phone className="w-4 h-4" /> Call Campus Security
                </button>
                <button className="w-full py-3 bg-white/10 text-white border border-white/20 rounded-xl text-[13px] font-bold flex items-center justify-center gap-2 hover:bg-white/20 transition-colors">
                  <Mail className="w-4 h-4" /> Email Counselor
                </button>
              </div>
            </div>
            
            <div className="absolute -bottom-10 -right-10 w-48 h-48 bg-white/10 rounded-full blur-3xl"></div>
            <div className="absolute -top-10 -left-10 w-32 h-32 bg-[#8B5CF6]/50 rounded-full blur-2xl"></div>
          </div>

          {/* Intervention Success Rate */}
          <div className="bg-white rounded-[20px] shadow-[0_2px_12px_rgba(0,0,0,0.02)] border border-[#F1F5F9] p-6">
            <h3 className="text-[16px] font-bold text-[#1E293B] mb-6">Intervention Success Rate</h3>
            
            <div className="flex flex-col items-center">
              {/* Fake Donut Chart via CSS SVG */}
              <div className="relative w-36 h-36 shrink-0 mb-6">
                <svg viewBox="0 0 36 36" className="w-full h-full -rotate-90">
                  <circle cx="18" cy="18" r="16" fill="none" className="stroke-[#F1F5F9]" strokeWidth="4"></circle>
                  <circle cx="18" cy="18" r="16" fill="none" className="stroke-[#10B981]" strokeWidth="4" strokeDasharray="72 100" strokeDashoffset="0"></circle>
                </svg>
                <div className="absolute inset-0 flex flex-col items-center justify-center">
                  <span className="text-[28px] font-black text-[#1E293B] leading-none">72%</span>
                  <span className="text-[9px] font-bold text-[#94A3B8] uppercase mt-1">Success Rate</span>
                </div>
              </div>
              
              <div className="w-full space-y-4">
                {[
                  { label: 'Successful Interventions', val: '28 cases', color: 'bg-[#10B981]' },
                  { label: 'Ongoing Support', val: '12 cases', color: 'bg-[#3B82F6]' },
                  { label: 'Unsuccessful/Dropped', val: '5 cases', color: 'bg-[#94A3B8]' },
                ].map((s, i) => (
                  <div key={i} className="flex items-center justify-between">
                    <div className="flex items-center gap-2"><div className={`w-2.5 h-2.5 rounded-full ${s.color}`}></div><span className="text-[12px] font-bold text-[#1E293B]">{s.label}</span></div>
                    <span className="text-[12px] text-[#64748B] font-semibold">{s.val}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* Bottom Banner */}
          <div className="w-full bg-[#F5F3FF] rounded-[20px] p-6 border border-[#E5D4FF]/50 relative overflow-hidden group">
            <div className="relative z-10">
              <h4 className="text-[15px] font-bold text-[#6C3DFF] mb-1 flex items-center gap-2"><Target className="w-4 h-4" /> It's okay to take a step back.</h4>
              <p className="text-[12px] text-[#475569] font-medium leading-relaxed">Encourage students to use the wellness room in Block B if they are feeling overwhelmed.</p>
            </div>
          </div>

        </div>

      </div>
    </div>
  );
}
