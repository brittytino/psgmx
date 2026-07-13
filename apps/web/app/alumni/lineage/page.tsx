'use client';

import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { Users, ToggleRight, ToggleLeft, Linkedin, Mail, ArrowRight, BookOpen, Award, ChevronDown } from 'lucide-react';
import Link from 'next/link';

export default function AlumniLineagePage() {
  const [mentorshipActive, setMentorshipActive] = useState(true);

  return (
    <div className="max-w-[1100px] mx-auto space-y-8 pb-8">

      {/* Header */}
      <div>
        <h1 className="text-[24px] font-black text-text-main tracking-tight flex items-center gap-2">
          <Users className="w-6 h-6 text-primary-purple" /> My Lineage
        </h1>
        <p className="text-[13px] text-text-muted mt-0.5">Your position in the MCA department's human network — past, present, and future.</p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">

        {/* Your Junior — Main Card */}
        <div className="lg:col-span-2 space-y-6">

          {/* Junior Card */}
          <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} className="bg-white rounded-[24px] border border-border-light shadow-[0_4px_20px_rgba(0,0,0,0.04)] p-8">
            <p className="text-[11px] font-bold text-text-muted uppercase tracking-wider mb-6">Your Lineage Junior (Active Student)</p>

            <div className="flex items-start gap-6">
              <div className="relative">
                <div className="w-24 h-24 rounded-2xl bg-gradient-to-br from-electric-blue/30 to-primary-purple/30 flex items-center justify-center text-primary-purple text-3xl font-black shadow-sm border-2 border-primary-purple/20">
                  S
                </div>
              </div>
              <div className="flex-1">
                <h2 className="text-[20px] font-black text-text-main">25MX301</h2>
                <p className="text-[13px] text-text-muted">Batch 25MX · Roll Suffix 301 · Active Student</p>
                <div className="grid grid-cols-2 gap-3 mt-4">
                  <div className="p-3 bg-page-bg rounded-xl">
                    <p className="text-[10px] font-bold text-text-muted uppercase">Readiness Band</p>
                    <p className="text-[15px] font-black text-primary-purple">BUILDING</p>
                  </div>
                  <div className="p-3 bg-page-bg rounded-xl">
                    <p className="text-[10px] font-bold text-text-muted uppercase">Exams Taken</p>
                    <p className="text-[15px] font-black text-text-main">5</p>
                  </div>
                </div>
                <p className="text-[12px] text-text-muted mt-4 italic">
                  Exact readiness score is kept private — you see their progress band and engagement level.
                </p>
              </div>
            </div>
          </motion.div>

          {/* Mentorship Toggle */}
          <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.1 }} className="bg-white rounded-[20px] border border-border-light shadow-[0_2px_12px_rgba(0,0,0,0.02)] p-6">
            <h3 className="text-[16px] font-bold text-text-main mb-4">Mentorship Availability</h3>

            <div className="flex items-center justify-between p-4 bg-page-bg rounded-xl mb-4">
              <div>
                <p className="text-[14px] font-bold text-text-main">I'm available for mentorship</p>
                <p className="text-[12px] text-text-muted mt-0.5">When ON, 25MX301 sees your contact info in their portal</p>
              </div>
              <button onClick={() => setMentorshipActive(!mentorshipActive)} className="transition-transform active:scale-95">
                {mentorshipActive
                  ? <ToggleRight className="w-10 h-10 text-electric-blue" />
                  : <ToggleLeft className="w-10 h-10 text-border-light" />}
              </button>
            </div>

            {mentorshipActive ? (
              <div className="p-4 bg-electric-blue/5 border border-electric-blue/20 rounded-xl">
                <p className="text-[13px] font-bold text-electric-blue mb-2">✓ Mentorship active</p>
                <p className="text-[13px] text-text-muted">25MX301 can see your LinkedIn and contact you. They see this message: <em>"Your lineage senior Riya Menon (23MX) is active and can be reached via LinkedIn."</em></p>
              </div>
            ) : (
              <div className="p-4 bg-page-bg border border-border-light rounded-xl">
                <p className="text-[13px] text-text-muted">Your junior won't see your contact information until you toggle this on.</p>
              </div>
            )}

            <div className="mt-5 space-y-3">
              <div>
                <label className="text-[12px] font-bold text-text-muted uppercase mb-2 block">Preferred Contact Method</label>
                <select className="w-full bg-page-bg border border-border-light rounded-xl px-4 py-3 text-[14px] text-text-main outline-none focus:border-primary-purple transition-colors">
                  <option>LinkedIn</option>
                  <option>Email</option>
                </select>
              </div>
              <div>
                <label className="text-[12px] font-bold text-text-muted uppercase mb-2 block">Availability Note (optional)</label>
                <input type="text" defaultValue="Best reached evenings on weekdays." className="w-full bg-page-bg border border-border-light rounded-xl px-4 py-3 text-[14px] text-text-main outline-none focus:border-primary-purple transition-colors" />
              </div>
              <button className="px-6 py-3 bg-primary-purple text-white rounded-xl text-[14px] font-bold hover:bg-deep-violet transition-colors">Save Preferences</button>
            </div>
          </motion.div>
        </div>

        {/* Right: Lineage Tree + Your Senior */}
        <div className="space-y-6">

          {/* Your Senior */}
          <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.15 }} className="bg-white rounded-[20px] border border-border-light shadow-[0_2px_12px_rgba(0,0,0,0.02)] p-6">
            <p className="text-[11px] font-bold text-text-muted uppercase tracking-wider mb-4">Your Lineage Senior</p>
            <div className="flex items-center gap-3 mb-4">
              <div className="w-14 h-14 rounded-xl bg-gradient-to-br from-primary-purple to-deep-violet flex items-center justify-center text-white font-black text-lg shadow-md">P</div>
              <div>
                <h4 className="text-[15px] font-bold text-text-main">Priya Shankar</h4>
                <p className="text-[12px] text-text-muted">Batch 21MX · Class of 2023</p>
                <p className="text-[12px] font-bold text-primary-purple">Senior SDE @ Infosys</p>
              </div>
            </div>
            <a href="#" className="flex items-center gap-2 px-4 py-2.5 bg-primary-purple text-white rounded-xl text-[12px] font-bold hover:bg-deep-violet transition-colors">
              <Linkedin className="w-3.5 h-3.5" /> View LinkedIn
            </a>
          </motion.div>

          {/* Lineage Tree */}
          <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.2 }} className="bg-white rounded-[20px] border border-border-light shadow-[0_2px_12px_rgba(0,0,0,0.02)] p-6">
            <h3 className="text-[14px] font-bold text-text-main mb-5">Suffix-301 Lineage</h3>
            <div className="space-y-0">
              {[
                { token: '21MX301', batch: '2021', role: 'Sr SDE @ Infosys', isYou: false },
                { token: '23MX301', batch: '2023', role: 'SWE @ Zoho — You', isYou: true },
                { token: '25MX301', batch: '2025', role: 'Active Student', isYou: false },
              ].map((n, i, arr) => (
                <div key={i} className="flex flex-col items-start">
                  <div className={`flex items-center gap-3 w-full p-3 rounded-xl ${n.isYou ? 'bg-primary-purple/10 border border-primary-purple/20' : 'hover:bg-page-bg'}`}>
                    <div className={`w-10 h-10 rounded-full flex items-center justify-center text-[12px] font-black shrink-0 ${n.isYou ? 'bg-primary-purple text-white' : 'bg-page-bg text-text-muted'}`}>
                      {n.token.slice(-3)}
                    </div>
                    <div>
                      <p className={`text-[13px] font-bold ${n.isYou ? 'text-primary-purple' : 'text-text-main'}`}>{n.token}</p>
                      <p className="text-[11px] text-text-muted">{n.role}</p>
                    </div>
                  </div>
                  {i < arr.length - 1 && <div className="w-px h-4 bg-border-light ml-8" />}
                </div>
              ))}
            </div>
          </motion.div>

          {/* How it works */}
          <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.25 }} className="bg-page-bg rounded-[16px] border border-border-light p-5">
            <h4 className="text-[12px] font-bold text-text-main mb-2">How Lineage Works</h4>
            <p className="text-[12px] text-text-muted leading-relaxed">Roll number suffix 301 connects you across all batches. Your senior mentored someone who mentored you. Now you mentor the next 301.</p>
          </motion.div>
        </div>
      </div>
    </div>
  );
}
