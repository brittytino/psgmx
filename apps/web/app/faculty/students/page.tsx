'use client';

import React from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Users, Filter, Search, MoreVertical, Plus, UploadCloud, Send, FileText, ChevronLeft, ChevronRight, ChevronDown } from 'lucide-react';
import Link from 'next/link';
export default function FacultyStudentsDashboard() {
  const [activeTab, setActiveTab] = React.useState('All Students');
  const [searchQuery, setSearchQuery] = React.useState('');
  const [currentPage, setCurrentPage] = React.useState(1);
  const [itemsPerPage, setItemsPerPage] = React.useState(10);
  const [showFilter, setShowFilter] = React.useState(false);
  const [toastMessage, setToastMessage] = React.useState('');

  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(''), 3000);
  };

  const allStudents = [
    { id: 1, name: 'Arjun Mehta', email: 'arjun.mehta@university.edu', roll: '25MX301', batch: '2021-2025', progress: 78, status: 'Active', activity: '2 hours ago' },
    { id: 2, name: 'Sara Khan', email: 'sara.khan@university.edu', roll: '25MX205', batch: '2021-2025', progress: 65, status: 'Active', activity: '5 hours ago' },
    { id: 3, name: 'Rohan Verma', email: 'rohan.verma@university.edu', roll: '25MX114', batch: '2021-2025', progress: 40, status: 'At Risk', activity: '1 day ago' },
    { id: 4, name: 'Neha Sharma', email: 'neha.sharma@university.edu', roll: '25MX402', batch: '2021-2025', progress: 88, status: 'Active', activity: '3 hours ago' },
    { id: 5, name: 'Ali Raza', email: 'ali.raza@university.edu', roll: '25MX310', batch: '2021-2025', progress: 35, status: 'At Risk', activity: '2 days ago' },
    { id: 6, name: 'Ananya Iyer', email: 'ananya.iyer@university.edu', roll: '25MX205', batch: '2021-2025', progress: 92, status: 'Active', activity: '1 hour ago' },
    { id: 7, name: 'Karan Singh', email: 'karan.singh@university.edu', roll: '25MX118', batch: '2021-2025', progress: 70, status: 'Active', activity: '4 hours ago' },
  ];

  const filteredStudents = allStudents.filter(student => {
    const matchesSearch = student.name.toLowerCase().includes(searchQuery.toLowerCase()) || student.roll.toLowerCase().includes(searchQuery.toLowerCase());
    if (!matchesSearch) return false;
    
    if (activeTab === 'My Mentees') return student.status === 'Active';
    if (activeTab === 'At Risk') return student.status === 'At Risk';
    if (activeTab === 'Top Performers') return student.progress > 80;
    return true;
  });

  const totalPages = Math.ceil(filteredStudents.length / itemsPerPage) || 1;
  const paginatedStudents = filteredStudents.slice((currentPage - 1) * itemsPerPage, currentPage * itemsPerPage);

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
      <div className="flex items-center gap-4">
        <div className="w-12 h-12 rounded-2xl bg-[#6C3DFF] flex items-center justify-center shadow-lg shadow-[#6C3DFF]/20 shrink-0">
          <Users className="w-6 h-6 text-white" />
        </div>
        <div>
          <motion.h1 
            initial={{ opacity: 0, y: -10 }}
            animate={{ opacity: 1, y: 0 }}
            className="text-[26px] font-bold text-[#1E293B] tracking-tight mb-0.5"
          >
            Students
          </motion.h1>
          <motion.p 
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.1 }}
            className="text-[14px] text-[#64748B]"
          >
            Manage and mentor students effectively. Track progress and provide guidance.
          </motion.p>
        </div>
      </div>

      {/* 4 Stat Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {/* Card 1 */}
        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.1 }} className="bg-white rounded-[20px] p-6 shadow-[0_2px_12px_rgba(0,0,0,0.03)] border border-[#F1F5F9] relative overflow-hidden flex flex-col justify-between h-[140px]">
          <div className="flex justify-between items-start">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-[#F5F3FF] flex items-center justify-center">
                <Users className="w-5 h-5 text-[#6C3DFF]" />
              </div>
              <p className="text-[12px] font-bold text-[#64748B]">Total Students</p>
            </div>
          </div>
          <div className="flex items-end justify-between mt-auto">
            <div>
              <h3 className="text-[32px] font-black text-[#1E293B] leading-none mb-2">142</h3>
              <p className="text-[11px] font-bold text-[#10B981]">↑ 12 this semester</p>
            </div>
            <div className="w-24 h-8">
              <svg viewBox="0 0 100 30" className="w-full h-full stroke-[#6C3DFF] fill-none" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round">
                <path d="M0,25 C20,25 30,15 50,15 C70,15 80,5 100,5" />
              </svg>
            </div>
          </div>
        </motion.div>

        {/* Card 2 */}
        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.2 }} className="bg-white rounded-[20px] p-6 shadow-[0_2px_12px_rgba(0,0,0,0.03)] border border-[#F1F5F9] relative overflow-hidden flex flex-col justify-between h-[140px]">
          <div className="flex justify-between items-start">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-[#EFF6FF] flex items-center justify-center">
                <Users className="w-5 h-5 text-[#3B82F6]" />
              </div>
              <p className="text-[12px] font-bold text-[#64748B]">Active Mentorships</p>
            </div>
          </div>
          <div className="flex items-end justify-between mt-auto">
            <div>
              <h3 className="text-[32px] font-black text-[#1E293B] leading-none mb-2">38</h3>
              <p className="text-[11px] font-bold text-[#10B981]">↑ 8 this semester</p>
            </div>
            <div className="w-24 h-8">
              <svg viewBox="0 0 100 30" className="w-full h-full stroke-[#3B82F6] fill-none" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round">
                <path d="M0,20 C20,25 40,5 60,15 C80,25 90,10 100,5" />
              </svg>
            </div>
          </div>
        </motion.div>

        {/* Card 3 */}
        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.3 }} className="bg-white rounded-[20px] p-6 shadow-[0_2px_12px_rgba(0,0,0,0.03)] border border-[#F1F5F9] relative overflow-hidden flex flex-col justify-between h-[140px]">
          <div className="flex justify-between items-start">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-[#ECFDF5] flex items-center justify-center">
                <Users className="w-5 h-5 text-[#10B981]" />
              </div>
              <p className="text-[12px] font-bold text-[#64748B]">At Risk Students</p>
            </div>
          </div>
          <div className="flex items-end justify-between mt-auto">
            <div>
              <h3 className="text-[32px] font-black text-[#1E293B] leading-none mb-2">6</h3>
              <p className="text-[11px] font-bold text-[#10B981]">↓ 2 this month</p>
            </div>
            <div className="w-24 h-8">
              <svg viewBox="0 0 100 30" className="w-full h-full stroke-[#10B981] fill-none" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round">
                <path d="M0,5 C10,5 30,20 50,10 C70,0 80,25 100,25" />
              </svg>
            </div>
          </div>
        </motion.div>

        {/* Card 4 */}
        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.4 }} className="bg-white rounded-[20px] p-6 shadow-[0_2px_12px_rgba(0,0,0,0.03)] border border-[#F1F5F9] relative overflow-hidden flex flex-col justify-between h-[140px]">
          <div className="flex justify-between items-start">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-[#FFFBEB] flex items-center justify-center">
                <Users className="w-5 h-5 text-[#F59E0B]" />
              </div>
              <p className="text-[12px] font-bold text-[#64748B]">Top Performers</p>
            </div>
          </div>
          <div className="flex items-end justify-between mt-auto">
            <div>
              <h3 className="text-[32px] font-black text-[#1E293B] leading-none mb-2">15</h3>
              <p className="text-[11px] font-bold text-[#10B981]">↑ 5 this semester</p>
            </div>
            <div className="w-24 h-8">
              <svg viewBox="0 0 100 30" className="w-full h-full stroke-[#F59E0B] fill-none" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round">
                <path d="M0,20 C20,10 40,25 60,15 C80,5 90,20 100,10" />
              </svg>
            </div>
          </div>
        </motion.div>
      </div>

      {/* Main Layout Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        
        {/* Left Column (Table) */}
        <div className="lg:col-span-2 space-y-6">
          <div className="bg-white rounded-[20px] shadow-[0_2px_12px_rgba(0,0,0,0.02)] border border-[#F1F5F9] overflow-hidden flex flex-col">
            
            {/* Table Header / Tabs / Search */}
            <div className="px-6 pt-6 border-b border-[#E2E8F0] flex flex-col md:flex-row md:items-end justify-between gap-4">
              <div className="flex items-center gap-6 overflow-x-auto custom-scrollbar pb-[-1px]">
                {['All Students', 'My Mentees', 'At Risk', 'Top Performers'].map(tab => (
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
                  <button onClick={() => setShowFilter(!showFilter)} className="flex items-center gap-2 px-4 py-2 border border-[#E2E8F0] rounded-xl text-[13px] font-bold text-[#1E293B] hover:bg-[#F8F9FC] transition-colors shadow-sm">
                    <Filter className="w-4 h-4" /> Filters
                  </button>
                  <AnimatePresence>
                    {showFilter && (
                      <motion.div initial={{ opacity: 0, y: 5 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: 5 }} className="absolute right-0 top-[110%] w-[200px] bg-white border border-[#F1F5F9] shadow-lg rounded-xl p-3 z-20">
                        <p className="text-[11px] font-bold text-[#94A3B8] uppercase mb-2">Filter by Status</p>
                        <div className="space-y-1">
                          <label className="flex items-center gap-2 text-[13px] font-semibold text-[#1E293B] cursor-pointer"><input type="checkbox" className="rounded" /> Active</label>
                          <label className="flex items-center gap-2 text-[13px] font-semibold text-[#1E293B] cursor-pointer"><input type="checkbox" className="rounded" /> At Risk</label>
                        </div>
                      </motion.div>
                    )}
                  </AnimatePresence>
                </div>
                <div className="relative">
                  <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-[#94A3B8]" />
                  <input type="text" value={searchQuery} onChange={(e) => { setSearchQuery(e.target.value); setCurrentPage(1); }} placeholder="Search in students..." className="pl-9 pr-4 py-2 border border-[#E2E8F0] rounded-xl text-[13px] w-[200px] outline-none focus:border-[#6C3DFF] transition-colors" />
                </div>
              </div>
            </div>

            {/* Table Body */}
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse min-w-[800px]">
                <thead>
                  <tr className="border-b border-[#F1F5F9]">
                    <th className="py-4 px-6 text-[11px] font-bold text-[#94A3B8] uppercase w-10"><input type="checkbox" className="rounded-[4px] border-[#CBD5E1]" /></th>
                    <th className="py-4 px-6 text-[11px] font-bold text-[#94A3B8] uppercase">Student</th>
                    <th className="py-4 px-6 text-[11px] font-bold text-[#94A3B8] uppercase">Roll Number</th>
                    <th className="py-4 px-6 text-[11px] font-bold text-[#94A3B8] uppercase">Batch</th>
                    <th className="py-4 px-6 text-[11px] font-bold text-[#94A3B8] uppercase">Progress</th>
                    <th className="py-4 px-6 text-[11px] font-bold text-[#94A3B8] uppercase">Mentorship Status</th>
                    <th className="py-4 px-6 text-[11px] font-bold text-[#94A3B8] uppercase">Last Activity</th>
                    <th className="py-4 px-6"></th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#F1F5F9]">
                  <AnimatePresence mode="popLayout">
                    {paginatedStudents.length === 0 ? (
                      <motion.tr initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}>
                        <td colSpan={8} className="py-8 text-center text-[#94A3B8] text-[13px] font-semibold">No students found matching your criteria.</td>
                      </motion.tr>
                    ) : (
                      paginatedStudents.map((student) => (
                        <motion.tr layout initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0 }} key={student.id} className="hover:bg-[#F8F9FC]/50 transition-colors group">
                          <td className="py-4 px-6"><input type="checkbox" className="rounded-[4px] border-[#CBD5E1]" /></td>
                          <td className="py-4 px-6">
                            <div className="flex items-center gap-3">
                              <img src={`https://ui-avatars.com/api/?name=${encodeURIComponent(student.name)}&background=random`} alt="" className="w-8 h-8 rounded-full border border-white shadow-sm" />
                              <div>
                                <p className="text-[13px] font-bold text-[#1E293B] group-hover:text-[#6C3DFF] transition-colors cursor-pointer">{student.name}</p>
                                <p className="text-[11px] text-[#94A3B8]">{student.email}</p>
                              </div>
                            </div>
                          </td>
                          <td className="py-4 px-6 text-[13px] font-bold text-[#475569]">{student.roll}</td>
                          <td className="py-4 px-6 text-[13px] font-semibold text-[#64748B]">{student.batch}</td>
                          <td className="py-4 px-6">
                            <div className="flex items-center gap-2">
                              <span className="text-[12px] font-bold text-[#1E293B] w-8">{student.progress}%</span>
                              <div className="w-16 h-1.5 rounded-full bg-[#F1F5F9] overflow-hidden">
                                <motion.div initial={{ width: 0 }} animate={{ width: `${student.progress}%` }} className={`h-full rounded-full ${student.progress > 80 ? 'bg-[#6C3DFF]' : student.progress > 50 ? 'bg-[#3B82F6]' : 'bg-[#F59E0B]'}`}></motion.div>
                              </div>
                            </div>
                          </td>
                          <td className="py-4 px-6">
                            {student.status === 'Active' ? (
                              <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-[#ECFDF5] text-[#059669] text-[11px] font-bold border border-[#A7F3D0]"><span className="w-1.5 h-1.5 rounded-full bg-[#059669]"></span> Active</span>
                            ) : (
                              <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-[#FFFBEB] text-[#D97706] text-[11px] font-bold border border-[#FDE68A]"><span className="w-1.5 h-1.5 rounded-full bg-[#D97706]"></span> At Risk</span>
                            )}
                          </td>
                          <td className="py-4 px-6 text-[12px] font-semibold text-[#64748B]">{student.activity}</td>
                          <td className="py-4 px-6 text-right">
                            <button className="p-1 text-[#94A3B8] hover:text-[#1E293B] hover:bg-[#F1F5F9] rounded-md transition-colors">
                              <MoreVertical className="w-4 h-4" />
                            </button>
                          </td>
                        </motion.tr>
                      )))}
                  </AnimatePresence>
                </tbody>
              </table>
            </div>

            {/* Pagination Footer */}
            <div className="p-4 border-t border-[#F1F5F9] flex flex-col sm:flex-row items-center justify-between gap-4">
              <span className="text-[12px] font-semibold text-[#64748B]">Showing {(currentPage - 1) * itemsPerPage + 1} to {Math.min(currentPage * itemsPerPage, filteredStudents.length)} of {filteredStudents.length} students</span>
              <div className="flex items-center gap-2">
                <button disabled={currentPage === 1} onClick={() => setCurrentPage(p => Math.max(1, p - 1))} className="w-8 h-8 rounded-lg flex items-center justify-center text-[#94A3B8] hover:bg-[#F1F5F9] disabled:opacity-50"><ChevronLeft className="w-4 h-4" /></button>
                {Array.from({ length: totalPages }, (_, i) => i + 1).map(p => (
                  <button key={p} onClick={() => setCurrentPage(p)} className={`w-8 h-8 rounded-lg flex items-center justify-center font-bold text-[13px] ${currentPage === p ? 'bg-[#6C3DFF] text-white shadow-sm' : 'text-[#64748B] hover:bg-[#F1F5F9]'}`}>{p}</button>
                ))}
                <button disabled={currentPage === totalPages} onClick={() => setCurrentPage(p => Math.min(totalPages, p + 1))} className="w-8 h-8 rounded-lg flex items-center justify-center text-[#94A3B8] hover:bg-[#F1F5F9] disabled:opacity-50"><ChevronRight className="w-4 h-4" /></button>
              </div>
              <div className="flex items-center gap-2 text-[12px] font-semibold text-[#64748B]">
                Rows per page: 
                <select value={itemsPerPage} onChange={(e) => { setItemsPerPage(Number(e.target.value)); setCurrentPage(1); }} className="border border-[#E2E8F0] rounded-lg px-2 py-1 cursor-pointer hover:bg-[#F8F9FC] outline-none">
                  <option value={5}>5</option>
                  <option value={10}>10</option>
                  <option value={20}>20</option>
                </select>
              </div>
            </div>
            
          </div>
        </div>

        {/* Right Column */}
        <div className="space-y-6">
          
          {/* Quick Actions */}
          <div className="bg-white rounded-[20px] shadow-[0_2px_12px_rgba(0,0,0,0.02)] border border-[#F1F5F9] p-6">
            <h3 className="text-[16px] font-bold text-[#1E293B] mb-5">Quick Actions</h3>
            <div className="grid grid-cols-2 gap-4">
              <button onClick={() => showToast('Student Added Successfully')} className="p-4 rounded-[16px] bg-[#F8F6FF] border border-[#E5D4FF]/50 flex flex-col items-center justify-center gap-2 hover:bg-[#E5D4FF]/40 transition-colors group">
                <div className="w-8 h-8 rounded-full bg-white flex items-center justify-center shadow-sm">
                  <Plus className="w-4 h-4 text-[#6C3DFF]" />
                </div>
                <span className="text-[13px] font-bold text-[#6C3DFF]">Add<br/>Student</span>
              </button>
              <button onClick={() => showToast('Importing Students from CSV...')} className="p-4 rounded-[16px] bg-[#EFF6FF] border border-[#BFDBFE]/50 flex flex-col items-center justify-center gap-2 hover:bg-[#DBEAFE]/50 transition-colors">
                <div className="w-8 h-8 rounded-full bg-white flex items-center justify-center shadow-sm">
                  <UploadCloud className="w-4 h-4 text-[#3B82F6]" />
                </div>
                <span className="text-[13px] font-bold text-[#3B82F6]">Import<br/>Students</span>
              </button>
              <button onClick={() => showToast('Opening Messenger...')} className="p-4 rounded-[16px] bg-[#ECFDF5] border border-[#A7F3D0]/50 flex flex-col items-center justify-center gap-2 hover:bg-[#D1FAE5]/50 transition-colors">
                <div className="w-8 h-8 rounded-full bg-white flex items-center justify-center shadow-sm">
                  <Send className="w-4 h-4 text-[#10B981]" />
                </div>
                <span className="text-[13px] font-bold text-[#10B981]">Send<br/>Message</span>
              </button>
              <button onClick={() => showToast('Generating Report...')} className="p-4 rounded-[16px] bg-[#FFFBEB] border border-[#FDE68A]/50 flex flex-col items-center justify-center gap-2 hover:bg-[#FEF3C7]/50 transition-colors">
                <div className="w-8 h-8 rounded-full bg-white flex items-center justify-center shadow-sm">
                  <FileText className="w-4 h-4 text-[#F59E0B]" />
                </div>
                <span className="text-[13px] font-bold text-[#F59E0B]">View<br/>Reports</span>
              </button>
            </div>
          </div>

          {/* Students by Progress Chart */}
          <div className="bg-white rounded-[20px] shadow-[0_2px_12px_rgba(0,0,0,0.02)] border border-[#F1F5F9] p-6">
            <h3 className="text-[16px] font-bold text-[#1E293B] mb-5">Students by Progress</h3>
            <div className="flex items-center gap-6 mb-4">
              {/* Fake Donut SVG */}
              <div className="relative w-28 h-28 shrink-0">
                <svg viewBox="0 0 36 36" className="w-full h-full -rotate-90">
                  <circle cx="18" cy="18" r="16" fill="none" className="stroke-[#6C3DFF]" strokeWidth="6" strokeDasharray="28 100" strokeDashoffset="0"></circle>
                  <circle cx="18" cy="18" r="16" fill="none" className="stroke-[#3B82F6]" strokeWidth="6" strokeDasharray="42 100" strokeDashoffset="-28"></circle>
                  <circle cx="18" cy="18" r="16" fill="none" className="stroke-[#F59E0B]" strokeWidth="6" strokeDasharray="18 100" strokeDashoffset="-70"></circle>
                  <circle cx="18" cy="18" r="16" fill="none" className="stroke-[#F43F5E]" strokeWidth="6" strokeDasharray="12 100" strokeDashoffset="-88"></circle>
                </svg>
              </div>
              <div className="flex-1 space-y-2">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2"><div className="w-2.5 h-2.5 rounded-full bg-[#6C3DFF]"></div><span className="text-[11px] font-bold text-[#1E293B]">Excellent (80-100%)</span></div>
                  <span className="text-[11px] text-[#64748B] font-bold">28%</span>
                </div>
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2"><div className="w-2.5 h-2.5 rounded-full bg-[#3B82F6]"></div><span className="text-[11px] font-bold text-[#1E293B]">Good (60-79%)</span></div>
                  <span className="text-[11px] text-[#64748B] font-bold">42%</span>
                </div>
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2"><div className="w-2.5 h-2.5 rounded-full bg-[#F59E0B]"></div><span className="text-[11px] font-bold text-[#1E293B]">Average (40-59%)</span></div>
                  <span className="text-[11px] text-[#64748B] font-bold">18%</span>
                </div>
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2"><div className="w-2.5 h-2.5 rounded-full bg-[#F43F5E]"></div><span className="text-[11px] font-bold text-[#1E293B]">Poor (&lt;40%)</span></div>
                  <span className="text-[11px] text-[#64748B] font-bold">12%</span>
                </div>
              </div>
            </div>
            <p className="text-[11px] text-[#94A3B8] font-semibold italic text-center">Based on overall activity & submissions</p>
          </div>

          {/* Recent At Risk Students */}
          <div className="bg-white rounded-[20px] shadow-[0_2px_12px_rgba(0,0,0,0.02)] border border-[#F1F5F9] p-6">
            <div className="flex justify-between items-center mb-6">
              <h3 className="text-[16px] font-bold text-[#1E293B]">Recent At Risk Students</h3>
              <Link href="#" className="text-[12px] font-bold text-[#6C3DFF]">View All</Link>
            </div>
            
            <div className="space-y-4 mb-6">
              {[
                { name: 'Rohan Verma', progress: '40%' },
                { name: 'Ali Raza', progress: '35%' },
                { name: 'Zoya Fatima', progress: '38%' },
              ].map((s, i) => (
                <div key={i} className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <img src={`https://ui-avatars.com/api/?name=${encodeURIComponent(s.name)}&background=random`} alt="" className="w-8 h-8 rounded-full" />
                    <div>
                      <p className="text-[13px] font-bold text-[#1E293B]">{s.name}</p>
                      <p className="text-[11px] text-[#64748B]">Progress: {s.progress}</p>
                    </div>
                  </div>
                  <span className="text-[10px] font-bold text-[#EF4444] bg-[#FEF2F2] px-2 py-0.5 rounded-full flex items-center gap-1 border border-[#FECACA]"><span className="w-1.5 h-1.5 rounded-full bg-[#EF4444]"></span> At Risk</span>
                </div>
              ))}
            </div>

            <button className="w-full py-3.5 bg-[#F8F6FF] text-[#6C3DFF] rounded-[12px] text-[13px] font-bold hover:bg-[#E5D4FF]/30 transition-colors text-center shadow-sm">
              View At Risk Students
            </button>
          </div>

        </div>

      </div>
    </div>
  );
}
