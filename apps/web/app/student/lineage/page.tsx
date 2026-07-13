'use client';

import React from 'react';
import { motion } from 'framer-motion';
import { Users, ArrowRight, Linkedin, Mail, ExternalLink, BookOpen, Award, ChevronRight } from 'lucide-react';
import Link from 'next/link';

const lineageArticles = [
  { title: 'How I cracked Zoho in 3 rounds', tag: 'PLACEMENT EXPERIENCE', date: 'Mar 2025' },
  { title: 'My preparation strategy — 2 years in MCA', tag: 'CAREER ADVICE', date: 'Feb 2025' },
  { title: 'SQL & DBMS topics that actually appeared', tag: 'TECHNICAL GUIDE', date: 'Jan 2025' },
];

export default function LineagePage() {
  return (
    <div className="max-w-[1100px] mx-auto space-y-8 pb-8">

      {/* Header */}
      <div>
        <h1 className="text-[24px] font-black text-text-main tracking-tight flex items-center gap-2">
          <Users className="w-6 h-6 text-primary-purple" /> Your Lineage
        </h1>
        <p className="text-[13px] text-text-muted mt-0.5">The human network of PSGMX. Your seniors, your path, your future juniors.</p>
      </div>

      {/* Main Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">

        {/* Your Senior Hero Card */}
        <div className="lg:col-span-2">
          <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} className="bg-white rounded-[24px] border border-border-light shadow-[0_4px_20px_rgba(0,0,0,0.04)] p-8">
            <p className="text-[11px] font-bold text-text-muted uppercase tracking-wider mb-6">Your Lineage Senior</p>
            <div className="flex items-start gap-6">
              <div className="relative">
                <div className="w-24 h-24 rounded-2xl bg-gradient-to-br from-primary-purple to-deep-violet flex items-center justify-center text-white text-3xl font-black shadow-lg shadow-primary-purple/20">
                  R
                </div>
                <div className="absolute -bottom-2 -right-2 w-7 h-7 bg-electric-blue rounded-full flex items-center justify-center border-2 border-white">
                  <Award className="w-3.5 h-3.5 text-white" />
                </div>
              </div>
              <div className="flex-1">
                <h2 className="text-[22px] font-black text-text-main">Riya Menon</h2>
                <p className="text-[13px] text-text-muted">Batch 23MX · Roll No. 23MX301</p>
                <p className="text-[14px] font-bold text-primary-purple mt-1">Software Engineer @ Zoho Corporation</p>
                <p className="text-[13px] text-text-muted mt-3 leading-relaxed italic">
                  "Stay consistent. Every day you complete the Daily Five is a brick. The score takes care of itself."
                </p>
                <div className="flex gap-3 mt-5">
                  <a href="#" className="flex items-center gap-2 px-5 py-2.5 bg-primary-purple text-white rounded-xl text-[13px] font-bold hover:bg-deep-violet transition-colors shadow-sm">
                    <Linkedin className="w-4 h-4" /> LinkedIn
                  </a>
                  <a href="#" className="flex items-center gap-2 px-5 py-2.5 bg-page-bg text-text-main rounded-xl text-[13px] font-bold hover:bg-border-light transition-colors border border-border-light">
                    <Mail className="w-4 h-4" /> Email
                  </a>
                </div>
              </div>
            </div>

            {/* Stats from their journey */}
            <div className="grid grid-cols-3 gap-4 mt-8 pt-6 border-t border-border-light">
              {[
                { label: 'Final Readiness', value: '88' },
                { label: 'LeetCode (batch)', value: '147' },
                { label: 'Exams Taken', value: '9' },
              ].map((s, i) => (
                <div key={i} className="text-center p-4 bg-page-bg rounded-xl">
                  <p className="text-[24px] font-black text-text-main">{s.value}</p>
                  <p className="text-[11px] font-bold text-text-muted mt-0.5">{s.label}</p>
                </div>
              ))}
            </div>
          </motion.div>
        </div>

        {/* Right: Lineage Tree + Info */}
        <div className="space-y-6">

          {/* How Lineage Works */}
          <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.1 }} className="bg-white rounded-[20px] border border-border-light shadow-[0_2px_12px_rgba(0,0,0,0.02)] p-6">
            <h3 className="text-[14px] font-bold text-text-main mb-3">How Lineage Works</h3>
            <p className="text-[13px] text-text-muted leading-relaxed">
              Your roll number ends in <span className="font-black text-text-main bg-page-bg px-1.5 py-0.5 rounded">301</span>. Every student across all batches who shares this suffix is in your lineage.
            </p>
            <div className="mt-4 p-3 bg-page-bg rounded-xl">
              <p className="text-[12px] font-bold text-primary-purple">Your lineage includes:</p>
              <p className="text-[13px] font-bold text-text-main mt-1">3 alumni + 1 current junior</p>
            </div>
          </motion.div>

          {/* Lineage Tree */}
          <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.15 }} className="bg-white rounded-[20px] border border-border-light shadow-[0_2px_12px_rgba(0,0,0,0.02)] p-6">
            <h3 className="text-[14px] font-bold text-text-main mb-5">Lineage Tree</h3>
            <div className="space-y-0">
              {[
                { token: '21MX301', batch: 'Batch 2021', role: 'Senior SDE @ Infosys', isYou: false, isAlumni: true, degree: 'Great-Senior' },
                { token: '23MX301', batch: 'Batch 2023', role: 'SWE @ Zoho', isYou: false, isAlumni: true, degree: 'Senior (Active Mentor)' },
                { token: '25MX301', batch: 'Batch 2025', role: 'Current Student — You', isYou: true, isAlumni: false, degree: 'You' },
                { token: '26MX301', batch: 'Batch 2026', role: 'Your Junior', isYou: false, isAlumni: false, degree: 'Junior' },
              ].map((node, i, arr) => (
                <div key={i} className="flex flex-col items-start">
                  <div className={`flex items-center gap-3 w-full p-3 rounded-xl transition-colors ${node.isYou ? 'bg-primary-purple/10 border border-primary-purple/20' : 'hover:bg-page-bg'}`}>
                    <div className={`w-10 h-10 rounded-full flex items-center justify-center text-[13px] font-black shrink-0 ${
                      node.isYou ? 'bg-primary-purple text-white' : node.isAlumni ? 'bg-gradient-to-br from-primary-purple/60 to-deep-violet/60 text-white' : 'bg-page-bg text-text-muted'
                    }`}>
                      {node.token.slice(-3)}
                    </div>
                    <div className="flex-1">
                      <p className={`text-[13px] font-bold ${node.isYou ? 'text-primary-purple' : 'text-text-main'}`}>
                        {node.token} {node.isYou && '← You'}
                      </p>
                      <p className="text-[11px] text-text-muted">{node.degree} · {node.batch}</p>
                    </div>
                  </div>
                  {i < arr.length - 1 && (
                    <div className="w-px h-4 bg-border-light ml-8" />
                  )}
                </div>
              ))}
            </div>
          </motion.div>
        </div>
      </div>

      {/* Articles by Your Senior */}
      <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.2 }} className="bg-white rounded-[20px] border border-border-light shadow-[0_2px_12px_rgba(0,0,0,0.02)]">
        <div className="p-6 border-b border-page-bg flex justify-between items-center">
          <div className="flex items-center gap-2">
            <BookOpen className="w-5 h-5 text-primary-purple" />
            <h3 className="text-[16px] font-bold text-text-main">Articles by Riya Menon</h3>
          </div>
          <Link href="/student/knowledge-brain" className="text-[13px] font-bold text-primary-purple flex items-center gap-1 hover:underline">
            Browse All <ArrowRight className="w-4 h-4" />
          </Link>
        </div>
        <div className="p-6 grid grid-cols-1 md:grid-cols-3 gap-4">
          {lineageArticles.map((article, i) => (
            <div key={i} className="p-5 bg-page-bg rounded-[16px] hover:border hover:border-primary-purple/30 transition-all cursor-pointer group">
              <span className="text-[9px] font-bold text-primary-purple uppercase tracking-wider">{article.tag}</span>
              <h4 className="text-[14px] font-bold text-text-main mt-2 mb-1 group-hover:text-primary-purple transition-colors">{article.title}</h4>
              <p className="text-[11px] text-text-muted">{article.date} · Approved ✓</p>
            </div>
          ))}
        </div>
      </motion.div>
    </div>
  );
}
