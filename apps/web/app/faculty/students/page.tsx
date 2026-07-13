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
          <motion.div initial={{ opacity: 0, y: 50 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: 50 }} className="fixed bottom-8 left-1/2 -translate-x-1/2 z-50 bg-rich-black text-white px-6 py-3 rounded-xl shadow-xl flex items-center gap-3">
            <div className="w-2 h-2 rounded-full bg-electric-blue"></div>
            <span className="text-[13px] font-bold">{toastMessage}</span>
          </motion.div>
        )}
      </AnimatePresence>
      
      {/* Header */}
      <div className="flex items-center gap-4">
        <div className="w-12 h-12 rounded-2xl bg-primary-purple flex items-center justify-center shadow-lg shadow-md shadow-primary-purple/10 shrink-0">
          <Users className="w-6 h-6 text-white" />
        </div>
        <div>
          <motion.h1 
            initial={{ opacity: 0, y: -10 }}
            animate={{ opacity: 1, y: 0 }}
            className="text-[26px] font-bold text-text-main tracking-tight mb-0.5"
          >
            Students
          </motion.h1>
          <motion.p 
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.1 }}
            className="text-[14px] text-text-muted"
          >
            Manage and mentor students effectively. Track progress and provide guidance.
          </motion.p>
        </div>
      </div>

      {/* 4 Stat Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {/* Card 1 */}
        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.1 }} className="bg-white rounded-[20px] p-6 shadow-[0_2px_12px_rgba(0,0,0,0.03)] border border-border-light relative overflow-hidden flex flex-col justify-between h-[140px]">
          <div className="flex justify-between items-start">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-page-bg flex items-center justify-center">
                <Users className="w-5 h-5 text-primary-purple" />
              </div>
              <p className="text-[12px] font-bold text-text-muted">Total Students</p>
            </div>
          </div>
          <div className="flex items-end justify-between mt-auto">
            <div>
              <h3 className="text-[32px] font-black text-text-main leading-none mb-2">142</h3>
              <p className="text-[11px] font-bold text-electric-blue">↑ 12 this semester</p>
            </div>
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
              <div className="w-10 h-10 rounded-full bg-white flex items-center justify-center">
                <Users className="w-5 h-5 text-electric-blue" />
              </div>
              <p className="text-[12px] font-bold text-text-muted">Active Mentorships</p>
            </div>
          </div>
          <div className="flex items-end justify-between mt-auto">
            <div>
              <h3 className="text-[32px] font-black text-text-main leading-none mb-2">38</h3>
              <p className="text-[11px] font-bold text-electric-blue">↑ 8 this semester</p>
            </div>
            <div className="w-24 h-8">
              <svg viewBox="0 0 100 30" className="w-full h-full stroke-electric-blue fill-none" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round">
                <path d="M0,20 C20,25 40,5 60,15 C80,25 90,10 100,5" />
              </svg>
            </div>
          </div>
        </motion.div>

        {/* Card 3 */}
        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.3 }} className="bg-white rounded-[20px] p-6 shadow-[0_2px_12px_rgba(0,0,0,0.03)] border border-border-light relative overflow-hidden flex flex-col justify-between h-[140px]">
          <div className="flex justify-between items-start">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-white flex items-center justify-center">
                <Users className="w-5 h-5 text-electric-blue" />
              </div>
              <p className="text-[12px] font-bold text-text-muted">At Risk Students</p>
            </div>
          </div>
          <div className="flex items-end justify-between mt-auto">
            <div>
              <h3 className="text-[32px] font-black text-text-main leading-none mb-2">6</h3>
              <p className="text-[11px] font-bold text-electric-blue">↓ 2 this month</p>
            </div>
            <div className="w-24 h-8">
              <svg viewBox="0 0 100 30" className="w-full h-full stroke-electric-blue fill-none" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round">
                <path d="M0,5 C10,5 30,20 50,10 C70,0 80,25 100,25" />
              </svg>
            </div>
          </div>
        </motion.div>

        {/* Card 4 */}
        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.4 }} className="bg-white rounded-[20px] p-6 shadow-[0_2px_12px_rgba(0,0,0,0.03)] border border-border-light relative overflow-hidden flex flex-col justify-between h-[140px]">
          <div className="flex justify-between items-start">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-white flex items-center justify-center">
                <Users className="w-5 h-5 text-illus-gold" />
              </div>
              <p className="text-[12px] font-bold text-text-muted">Top Performers</p>
            </div>
          </div>
          <div className="flex items-end justify-between mt-auto">
            <div>
              <h3 className="text-[32px] font-black text-text-main leading-none mb-2">15</h3>
              <p className="text-[11px] font-bold text-electric-blue">↑ 5 this semester</p>
            </div>
            <div className="w-24 h-8">
              <svg viewBox="0 0 100 30" className="w-full h-full stroke-illus-gold fill-none" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round">
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
          <div className="bg-white rounded-[20px] shadow-[0_2px_12px_rgba(0,0,0,0.02)] border border-border-light overflow-hidden flex flex-col">
            
            {/* Table Header / Tabs / Search */}
            <div className="px-6 pt-6 border-b border-border-light flex flex-col md:flex-row md:items-end justify-between gap-4">
              <div className="flex items-center gap-6 overflow-x-auto custom-scrollbar pb-[-1px]">
                {['All Students', 'My Mentees', 'At Risk', 'Top Performers'].map(tab => (
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
                  <button onClick={() => setShowFilter(!showFilter)} className="flex items-center gap-2 px-4 py-2 border border-border-light rounded-xl text-[13px] font-bold text-text-main hover:bg-page-bg transition-colors shadow-sm">
                    <Filter className="w-4 h-4" /> Filters
                  </button>
                  <AnimatePresence>
                    {showFilter && (
                      <motion.div initial={{ opacity: 0, y: 5 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: 5 }} className="absolute right-0 top-[110%] w-[200px] bg-white border border-border-light shadow-lg rounded-xl p-3 z-20">
                        <p className="text-[11px] font-bold text-text-muted uppercase mb-2">Filter by Status</p>
                        <div className="space-y-1">
                          <label className="flex items-center gap-2 text-[13px] font-semibold text-text-main cursor-pointer"><input type="checkbox" className="rounded" /> Active</label>
                          <label className="flex items-center gap-2 text-[13px] font-semibold text-text-main cursor-pointer"><input type="checkbox" className="rounded" /> At Risk</label>
                        </div>
                      </motion.div>
                    )}
                  </AnimatePresence>
                </div>
                <div className="relative">
                  <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-text-muted" />
                  <input type="text" value={searchQuery} onChange={(e) => { setSearchQuery(e.target.value); setCurrentPage(1); }} placeholder="Search in students..." className="pl-9 pr-4 py-2 border border-border-light rounded-xl text-[13px] w-[200px] outline-none focus:border-primary-purple transition-colors" />
                </div>
              </div>
            </div>

            {/* Table Body */}
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse min-w-[800px]">
                <thead>
                  <tr className="border-b border-border-light">
                    <th className="py-4 px-6 text-[11px] font-bold text-text-muted uppercase w-10"><input type="checkbox" className="rounded-[4px] border-border-light" /></th>
                    <th className="py-4 px-6 text-[11px] font-bold text-text-muted uppercase">Student</th>
                    <th className="py-4 px-6 text-[11px] font-bold text-text-muted uppercase">Roll Number</th>
                    <th className="py-4 px-6 text-[11px] font-bold text-text-muted uppercase">Batch</th>
                    <th className="py-4 px-6 text-[11px] font-bold text-text-muted uppercase">Progress</th>
                    <th className="py-4 px-6 text-[11px] font-bold text-text-muted uppercase">Mentorship Status</th>
                    <th className="py-4 px-6 text-[11px] font-bold text-text-muted uppercase">Last Activity</th>
                    <th className="py-4 px-6"></th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#F1F5F9]">
                  <AnimatePresence mode="popLayout">
                    {paginatedStudents.length === 0 ? (
                      <motion.tr initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}>
                        <td colSpan={8} className="py-8 text-center text-text-muted text-[13px] font-semibold">No students found matching your criteria.</td>
                      </motion.tr>
                    ) : (
                      paginatedStudents.map((student) => (
                        <motion.tr layout initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0 }} key={student.id} className="hover:bg-page-bg/50 transition-colors group">
                          <td className="py-4 px-6"><input type="checkbox" className="rounded-[4px] border-border-light" /></td>
                          <td className="py-4 px-6">
                            <div className="flex items-center gap-3">
                              <img src={`https://ui-avatars.com/api/?name=${encodeURIComponent(student.name)}&background=random`} alt="" className="w-8 h-8 rounded-full border border-white shadow-sm" />
                              <div>
                                <p className="text-[13px] font-bold text-text-main group-hover:text-primary-purple transition-colors cursor-pointer">{student.name}</p>
                                <p className="text-[11px] text-text-muted">{student.email}</p>
                              </div>
                            </div>
                          </td>
                          <td className="py-4 px-6 text-[13px] font-bold text-text-muted">{student.roll}</td>
                          <td className="py-4 px-6 text-[13px] font-semibold text-text-muted">{student.batch}</td>
                          <td className="py-4 px-6">
                            <div className="flex items-center gap-2">
                              <span className="text-[12px] font-bold text-text-main w-8">{student.progress}%</span>
                              <div className="w-16 h-1.5 rounded-full bg-page-bg overflow-hidden">
                                <motion.div initial={{ width: 0 }} animate={{ width: `${student.progress}%` }} className={`h-full rounded-full ${student.progress > 80 ? 'bg-primary-purple' : student.progress > 50 ? 'bg-electric-blue' : 'bg-illus-gold'}`}></motion.div>
                              </div>
                            </div>
                          </td>
                          <td className="py-4 px-6">
                            {student.status === 'Active' ? (
                              <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-white text-electric-blue text-[11px] font-bold border border-electric-blue/30"><span className="w-1.5 h-1.5 rounded-full bg-electric-blue"></span> Active</span>
                            ) : (
                              <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-white text-illus-gold text-[11px] font-bold border border-illus-gold/30"><span className="w-1.5 h-1.5 rounded-full bg-illus-gold"></span> At Risk</span>
                            )}
                          </td>
                          <td className="py-4 px-6 text-[12px] font-semibold text-text-muted">{student.activity}</td>
                          <td className="py-4 px-6 text-right">
                            <button className="p-1 text-text-muted hover:text-text-main hover:bg-page-bg rounded-md transition-colors">
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
            <div className="p-4 border-t border-border-light flex flex-col sm:flex-row items-center justify-between gap-4">
              <span className="text-[12px] font-semibold text-text-muted">Showing {(currentPage - 1) * itemsPerPage + 1} to {Math.min(currentPage * itemsPerPage, filteredStudents.length)} of {filteredStudents.length} students</span>
              <div className="flex items-center gap-2">
                <button disabled={currentPage === 1} onClick={() => setCurrentPage(p => Math.max(1, p - 1))} className="w-8 h-8 rounded-lg flex items-center justify-center text-text-muted hover:bg-page-bg disabled:opacity-50"><ChevronLeft className="w-4 h-4" /></button>
                {Array.from({ length: totalPages }, (_, i) => i + 1).map(p => (
                  <button key={p} onClick={() => setCurrentPage(p)} className={`w-8 h-8 rounded-lg flex items-center justify-center font-bold text-[13px] ${currentPage === p ? 'bg-primary-purple text-white shadow-sm' : 'text-text-muted hover:bg-page-bg'}`}>{p}</button>
                ))}
                <button disabled={currentPage === totalPages} onClick={() => setCurrentPage(p => Math.min(totalPages, p + 1))} className="w-8 h-8 rounded-lg flex items-center justify-center text-text-muted hover:bg-page-bg disabled:opacity-50"><ChevronRight className="w-4 h-4" /></button>
              </div>
              <div className="flex items-center gap-2 text-[12px] font-semibold text-text-muted">
                Rows per page: 
                <select value={itemsPerPage} onChange={(e) => { setItemsPerPage(Number(e.target.value)); setCurrentPage(1); }} className="border border-border-light rounded-lg px-2 py-1 cursor-pointer hover:bg-page-bg outline-none">
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
          <div className="bg-white rounded-[20px] shadow-[0_2px_12px_rgba(0,0,0,0.02)] border border-border-light p-6">
            <h3 className="text-[16px] font-bold text-text-main mb-5">Quick Actions</h3>
            <div className="grid grid-cols-2 gap-4">
              <button onClick={() => showToast('Student Added Successfully')} className="p-4 rounded-[16px] bg-white/40 backdrop-blur-md border border-white/20 border border-primary-purple/20 flex flex-col items-center justify-center gap-2 hover:bg-page-bg transition-colors group">
                <div className="w-8 h-8 rounded-full bg-white flex items-center justify-center shadow-sm">
                  <Plus className="w-4 h-4 text-primary-purple" />
                </div>
                <span className="text-[13px] font-bold text-primary-purple">Add<br/>Student</span>
              </button>
              <button onClick={() => showToast('Importing Students from CSV...')} className="p-4 rounded-[16px] bg-white border border-primary-purple/30/50 flex flex-col items-center justify-center gap-2 hover:bg-[#DBEAFE]/50 transition-colors">
                <div className="w-8 h-8 rounded-full bg-white flex items-center justify-center shadow-sm">
                  <UploadCloud className="w-4 h-4 text-electric-blue" />
                </div>
                <span className="text-[13px] font-bold text-electric-blue">Import<br/>Students</span>
              </button>
              <button onClick={() => showToast('Opening Messenger...')} className="p-4 rounded-[16px] bg-white border border-electric-blue/30/50 flex flex-col items-center justify-center gap-2 hover:bg-[#D1FAE5]/50 transition-colors">
                <div className="w-8 h-8 rounded-full bg-white flex items-center justify-center shadow-sm">
                  <Send className="w-4 h-4 text-electric-blue" />
                </div>
                <span className="text-[13px] font-bold text-electric-blue">Send<br/>Message</span>
              </button>
              <button onClick={() => showToast('Generating Report...')} className="p-4 rounded-[16px] bg-white border border-illus-gold/30/50 flex flex-col items-center justify-center gap-2 hover:bg-[#FEF3C7]/50 transition-colors">
                <div className="w-8 h-8 rounded-full bg-white flex items-center justify-center shadow-sm">
                  <FileText className="w-4 h-4 text-illus-gold" />
                </div>
                <span className="text-[13px] font-bold text-illus-gold">View<br/>Reports</span>
              </button>
            </div>
          </div>

          {/* Students by Progress Chart */}
          <div className="bg-white rounded-[20px] shadow-[0_2px_12px_rgba(0,0,0,0.02)] border border-border-light p-6">
            <h3 className="text-[16px] font-bold text-text-main mb-5">Students by Progress</h3>
            <div className="flex items-center gap-6 mb-4">
              {/* Fake Donut SVG */}
              <div className="relative w-28 h-28 shrink-0">
                <svg viewBox="0 0 36 36" className="w-full h-full -rotate-90">
                  <circle cx="18" cy="18" r="16" fill="none" className="stroke-primary-purple" strokeWidth="6" strokeDasharray="28 100" strokeDashoffset="0"></circle>
                  <circle cx="18" cy="18" r="16" fill="none" className="stroke-electric-blue" strokeWidth="6" strokeDasharray="42 100" strokeDashoffset="-28"></circle>
                  <circle cx="18" cy="18" r="16" fill="none" className="stroke-illus-gold" strokeWidth="6" strokeDasharray="18 100" strokeDashoffset="-70"></circle>
                  <circle cx="18" cy="18" r="16" fill="none" className="stroke-deep-violet" strokeWidth="6" strokeDasharray="12 100" strokeDashoffset="-88"></circle>
                </svg>
              </div>
              <div className="flex-1 space-y-2">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2"><div className="w-2.5 h-2.5 rounded-full bg-primary-purple"></div><span className="text-[11px] font-bold text-text-main">Excellent (80-100%)</span></div>
                  <span className="text-[11px] text-text-muted font-bold">28%</span>
                </div>
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2"><div className="w-2.5 h-2.5 rounded-full bg-electric-blue"></div><span className="text-[11px] font-bold text-text-main">Good (60-79%)</span></div>
                  <span className="text-[11px] text-text-muted font-bold">42%</span>
                </div>
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2"><div className="w-2.5 h-2.5 rounded-full bg-illus-gold"></div><span className="text-[11px] font-bold text-text-main">Average (40-59%)</span></div>
                  <span className="text-[11px] text-text-muted font-bold">18%</span>
                </div>
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2"><div className="w-2.5 h-2.5 rounded-full bg-deep-violet"></div><span className="text-[11px] font-bold text-text-main">Poor (&lt;40%)</span></div>
                  <span className="text-[11px] text-text-muted font-bold">12%</span>
                </div>
              </div>
            </div>
            <p className="text-[11px] text-text-muted font-semibold italic text-center">Based on overall activity & submissions</p>
          </div>

          {/* Recent At Risk Students */}
          <div className="bg-white rounded-[20px] shadow-[0_2px_12px_rgba(0,0,0,0.02)] border border-border-light p-6">
            <div className="flex justify-between items-center mb-6">
              <h3 className="text-[16px] font-bold text-text-main">Recent At Risk Students</h3>
              <Link href="#" className="text-[12px] font-bold text-primary-purple">View All</Link>
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
                      <p className="text-[13px] font-bold text-text-main">{s.name}</p>
                      <p className="text-[11px] text-text-muted">Progress: {s.progress}</p>
                    </div>
                  </div>
                  <span className="text-[10px] font-bold text-deep-violet bg-page-bg px-2 py-0.5 rounded-full flex items-center gap-1 border border-deep-violet/30"><span className="w-1.5 h-1.5 rounded-full bg-deep-violet"></span> At Risk</span>
                </div>
              ))}
            </div>

            <button className="w-full py-3.5 bg-white/40 backdrop-blur-md border border-white/20 text-primary-purple rounded-[12px] text-[13px] font-bold hover:bg-page-bg transition-colors text-center shadow-sm">
              View At Risk Students
            </button>
          </div>

        </div>

      </div>
    </div>
  );
}
