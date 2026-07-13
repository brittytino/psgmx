'use client';

import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { ClipboardList, Clock, ChevronDown, Shield, CheckCircle, AlertTriangle, ArrowRight, Play, Download, Eye } from 'lucide-react';
import Link from 'next/link';

const upcomingExams = [
  { id: 1, name: 'Data Structures — Full Mock', subject: 'DSA', faculty: 'Dr. Arunkumar', date: 'Jan 20, 2025', time: '10:00 AM', duration: 90, qCount: 40, type: 'MCQ + Coding', status: 'scheduled', daysLeft: 4 },
  { id: 2, name: 'Aptitude Assessment — Q3', subject: 'Aptitude', faculty: 'Dr. Priya', date: 'Jan 28, 2025', time: '2:00 PM', duration: 60, qCount: 30, type: 'MCQ', status: 'scheduled', daysLeft: 12 },
  { id: 3, name: 'DBMS Concepts & SQL', subject: 'DBMS', faculty: 'Dr. Arunkumar', date: 'Feb 5, 2025', time: '11:00 AM', duration: 75, qCount: 35, type: 'MCQ', status: 'scheduled', daysLeft: 20 },
];

const completedExams = [
  { id: 4, name: 'Operating Systems — Mock 1', date: 'Dec 15, 2024', score: 82, total: 100, band: 'GOOD', proctorFlags: 0, contribution: '+3.8 pts' },
  { id: 5, name: 'Python Programming — Full Mock', date: 'Nov 20, 2024', score: 67, total: 100, band: 'AVERAGE', proctorFlags: 1, contribution: '+2.9 pts' },
  { id: 6, name: 'Data Structures — Mid Mock', date: 'Oct 10, 2024', score: 91, total: 100, band: 'EXCELLENT', proctorFlags: 0, contribution: '+4.5 pts' },
  { id: 7, name: 'Aptitude Assessment — Q1', date: 'Sep 5, 2024', score: 54, total: 100, band: 'AVERAGE', proctorFlags: 2, contribution: '+2.1 pts' },
  { id: 8, name: 'Aptitude Assessment — Q2', date: 'Sep 25, 2024', score: 72, total: 100, band: 'GOOD', proctorFlags: 0, contribution: '+3.2 pts' },
];

const getBandColor = (band: string) => {
  if (band === 'EXCELLENT') return 'bg-electric-blue text-white';
  if (band === 'GOOD') return 'bg-primary-purple text-white';
  if (band === 'AVERAGE') return 'bg-illus-gold text-white';
  return 'bg-deep-violet text-white';
};

export default function ExamsPage() {
  const [activeTab, setActiveTab] = useState<'upcoming' | 'completed'>('upcoming');
  const [selectedResult, setSelectedResult] = useState<any>(null);

  return (
    <div className="max-w-[1200px] mx-auto space-y-8 pb-8">

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-[24px] font-black text-text-main tracking-tight flex items-center gap-2">
            <ClipboardList className="w-6 h-6 text-primary-purple" /> Mock Exams
          </h1>
          <p className="text-[13px] text-text-muted mt-0.5">Proctored mock exams that simulate real placement tests.</p>
        </div>
        <div className="flex items-center gap-2 bg-white border border-border-light rounded-xl px-4 py-2.5 shadow-sm">
          <Shield className="w-4 h-4 text-electric-blue" />
          <span className="text-[12px] font-bold text-text-main">Proctoring Active</span>
        </div>
      </div>

      {/* Stat Cards */}
      <div className="grid grid-cols-3 gap-6">
        {[
          { label: 'Exams Taken', value: '5', sub: 'This semester', color: 'bg-primary-purple', spark: 'M0,25 C20,20 40,10 60,12 C80,15 90,5 100,3' },
          { label: 'Best Score', value: '91%', sub: 'DS Mid Mock', color: 'bg-electric-blue', spark: 'M0,28 C20,20 40,5 60,10 C80,15 90,8 100,5' },
          { label: 'Exam Contribution', value: '28/35', sub: 'Readiness points', color: 'bg-illus-gold', spark: 'M0,22 C15,20 30,15 50,12 C70,10 85,8 100,5' },
        ].map((c, i) => (
          <motion.div key={i} initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.1 }} className="bg-white rounded-[20px] p-6 border border-border-light shadow-[0_2px_12px_rgba(0,0,0,0.03)] h-[130px] flex flex-col justify-between">
            <div className="flex items-center gap-3">
              <div className={`w-9 h-9 rounded-full ${c.color} flex items-center justify-center shadow-sm`}>
                <ClipboardList className="w-4 h-4 text-white" />
              </div>
              <p className="text-[12px] font-bold text-text-muted">{c.label}</p>
            </div>
            <div className="flex items-end justify-between">
              <div>
                <h3 className="text-[28px] font-black text-text-main leading-none">{c.value}</h3>
                <p className="text-[11px] text-text-muted mt-1">{c.sub}</p>
              </div>
              <svg viewBox="0 0 100 30" className="w-20 h-7 fill-none stroke-primary-purple" strokeWidth="3" strokeLinecap="round">
                <path d={c.spark} />
              </svg>
            </div>
          </motion.div>
        ))}
      </div>

      {/* Tab Navigation */}
      <div className="bg-white rounded-[20px] border border-border-light shadow-[0_2px_12px_rgba(0,0,0,0.02)] overflow-hidden">
        <div className="border-b border-border-light px-6 pt-6 flex gap-6">
          {(['upcoming', 'completed'] as const).map((tab) => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              className={`pb-4 px-1 text-[14px] font-bold capitalize transition-colors border-b-2 ${
                activeTab === tab ? 'text-primary-purple border-primary-purple' : 'text-text-muted border-transparent hover:text-text-main'
              }`}
            >
              {tab} {tab === 'upcoming' ? `(${upcomingExams.length})` : `(${completedExams.length})`}
            </button>
          ))}
        </div>

        <div className="p-6 space-y-4">
          <AnimatePresence mode="wait">
            {activeTab === 'upcoming' ? (
              <motion.div key="upcoming" initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0 }} className="space-y-4">
                {upcomingExams.map((exam) => (
                  <div key={exam.id} className="flex items-center justify-between p-5 rounded-[16px] border border-border-light hover:border-primary-purple/30 transition-all group bg-white">
                    <div className="flex items-center gap-5">
                      <div className="w-14 h-14 rounded-[14px] bg-page-bg flex flex-col items-center justify-center shrink-0 border border-border-light">
                        <span className="text-[20px] font-black text-primary-purple leading-none">{exam.daysLeft}</span>
                        <span className="text-[8px] font-bold text-text-muted uppercase">days left</span>
                      </div>
                      <div>
                        <h4 className="text-[15px] font-bold text-text-main mb-1">{exam.name}</h4>
                        <div className="flex flex-wrap gap-x-4 gap-y-1">
                          <p className="text-[12px] text-text-muted flex items-center gap-1"><Clock className="w-3.5 h-3.5" /> {exam.date} at {exam.time}</p>
                          <p className="text-[12px] text-text-muted">{exam.duration} min · {exam.qCount} questions · {exam.type}</p>
                          <p className="text-[12px] text-text-muted">By {exam.faculty}</p>
                        </div>
                      </div>
                    </div>
                    <div className="flex items-center gap-3">
                      <span className="text-[10px] font-bold px-3 py-1 rounded-full bg-page-bg text-text-muted border border-border-light">SCHEDULED</span>
                      <button disabled className="flex items-center gap-2 px-5 py-2.5 bg-primary-purple text-white rounded-xl text-[13px] font-bold opacity-40 cursor-not-allowed shrink-0">
                        <Play className="w-4 h-4" /> Enter Exam
                      </button>
                    </div>
                  </div>
                ))}
                <div className="p-5 rounded-[16px] border border-dashed border-border-light bg-page-bg flex items-center gap-4 text-center justify-center">
                  <AlertTriangle className="w-5 h-5 text-illus-gold" />
                  <p className="text-[13px] font-semibold text-text-muted">The <strong className="text-text-main">Enter Exam</strong> button activates on the day of the exam. You'll need to allow camera access to begin proctoring.</p>
                </div>
              </motion.div>
            ) : (
              <motion.div key="completed" initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0 }}>
                <table className="w-full">
                  <thead>
                    <tr className="border-b border-border-light">
                      {['Exam', 'Date', 'Score', 'Readiness', 'Proctoring', 'Action'].map(h => (
                        <th key={h} className="pb-4 text-[11px] font-bold text-text-muted uppercase text-left px-2 first:pl-0">{h}</th>
                      ))}
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-border-light">
                    {completedExams.map((exam) => (
                      <tr key={exam.id} className="hover:bg-page-bg transition-colors">
                        <td className="py-4 pl-0 pr-2">
                          <p className="text-[14px] font-bold text-text-main">{exam.name}</p>
                        </td>
                        <td className="py-4 px-2 text-[13px] text-text-muted whitespace-nowrap">{exam.date}</td>
                        <td className="py-4 px-2">
                          <div className="flex items-center gap-2">
                            <span className="text-[14px] font-black text-text-main">{exam.score}/100</span>
                            <span className={`text-[9px] font-bold px-2 py-0.5 rounded-full ${getBandColor(exam.band)}`}>{exam.band}</span>
                          </div>
                        </td>
                        <td className="py-4 px-2">
                          <span className="text-[13px] font-bold text-electric-blue">{exam.contribution}</span>
                        </td>
                        <td className="py-4 px-2">
                          {exam.proctorFlags === 0 ? (
                            <span className="flex items-center gap-1 text-[12px] font-bold text-electric-blue"><CheckCircle className="w-3.5 h-3.5" /> Clean</span>
                          ) : (
                            <span className="flex items-center gap-1 text-[12px] font-bold text-illus-gold"><AlertTriangle className="w-3.5 h-3.5" /> {exam.proctorFlags} flag{exam.proctorFlags > 1 ? 's' : ''}</span>
                          )}
                        </td>
                        <td className="py-4 px-2">
                          <button onClick={() => setSelectedResult(exam)} className="flex items-center gap-1.5 text-[12px] font-bold text-primary-purple hover:underline">
                            <Eye className="w-3.5 h-3.5" /> View
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </motion.div>
            )}
          </AnimatePresence>
        </div>
      </div>

      {/* Result Modal */}
      <AnimatePresence>
        {selectedResult && (
          <>
            <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} onClick={() => setSelectedResult(null)} className="fixed inset-0 bg-rich-black/40 backdrop-blur-sm z-50" />
            <motion.div initial={{ opacity: 0, scale: 0.95, y: 20 }} animate={{ opacity: 1, scale: 1, y: 0 }} exit={{ opacity: 0, scale: 0.95, y: 20 }} className="fixed inset-0 flex items-center justify-center z-50 p-6">
              <div className="bg-white rounded-[24px] shadow-2xl border border-border-light w-full max-w-lg p-8">
                <div className="flex items-start justify-between mb-6">
                  <div>
                    <h3 className="text-[18px] font-black text-text-main">{selectedResult.name}</h3>
                    <p className="text-[13px] text-text-muted mt-1">{selectedResult.date}</p>
                  </div>
                  <button onClick={() => setSelectedResult(null)} className="w-8 h-8 flex items-center justify-center rounded-full bg-page-bg text-text-muted hover:bg-border-light transition-colors">
                    ✕
                  </button>
                </div>
                <div className="flex items-center justify-center mb-6">
                  <div className="relative w-32 h-32">
                    <svg viewBox="0 0 100 100" className="w-full h-full -rotate-90">
                      <circle cx="50" cy="50" r="44" fill="none" stroke="#EFE9E0" strokeWidth="8" />
                      <circle cx="50" cy="50" r="44" fill="none" stroke="var(--primary-purple)" strokeWidth="8" strokeLinecap="round"
                        strokeDasharray={`${(selectedResult.score / 100) * 276.46} 276.46`} />
                    </svg>
                    <div className="absolute inset-0 flex flex-col items-center justify-center">
                      <span className="text-[28px] font-black text-text-main">{selectedResult.score}</span>
                      <span className="text-[10px] text-text-muted">/ 100</span>
                    </div>
                  </div>
                </div>
                <div className="space-y-3">
                  <div className="flex justify-between p-3 bg-page-bg rounded-xl">
                    <span className="text-[13px] font-semibold text-text-muted">Band</span>
                    <span className={`text-[12px] font-bold px-2 py-0.5 rounded-full ${getBandColor(selectedResult.band)}`}>{selectedResult.band}</span>
                  </div>
                  <div className="flex justify-between p-3 bg-page-bg rounded-xl">
                    <span className="text-[13px] font-semibold text-text-muted">Readiness Contribution</span>
                    <span className="text-[13px] font-black text-electric-blue">{selectedResult.contribution}</span>
                  </div>
                  <div className="flex justify-between p-3 bg-page-bg rounded-xl">
                    <span className="text-[13px] font-semibold text-text-muted">Proctoring Events</span>
                    <span className="text-[13px] font-bold text-text-main">{selectedResult.proctorFlags === 0 ? 'None detected ✓' : `${selectedResult.proctorFlags} tab switch(es) flagged`}</span>
                  </div>
                </div>
              </div>
            </motion.div>
          </>
        )}
      </AnimatePresence>
    </div>
  );
}
