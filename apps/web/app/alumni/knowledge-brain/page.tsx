'use client';

import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { BookOpen, Search, FileText, CheckCircle, ArrowRight, PenLine, Star } from 'lucide-react';
import Link from 'next/link';

const articles = [
  { id: 1, title: 'How I cracked Zoho\'s 5-round process', isYours: true, author: 'You (Riya Menon)', tag: 'PLACEMENT EXPERIENCE', date: 'Mar 2025', reads: 243, preview: 'Zoho\'s process starts with a reasoning and programming test...' },
  { id: 2, title: 'My 2-Year MCA Preparation Strategy', isYours: true, author: 'You (Riya Menon)', tag: 'CAREER ADVICE', date: 'Feb 2025', reads: 421, preview: 'Month 1: Don\'t panic. Month 3: Start LeetCode easy...' },
  { id: 3, title: 'Dynamic Programming — A Pattern-First Guide', isYours: false, author: 'Dr. Arunkumar · Faculty', tag: 'TECHNICAL GUIDE', date: 'Feb 2025', reads: 189, preview: 'Most students memorize DP solutions. The better approach is recognizing the four patterns...' },
  { id: 4, title: 'TCS Digital: Aptitude Test Deep Dive', isYours: false, author: 'Arjun Pillai · 22MX', tag: 'COMPANY SPECIFIC', date: 'Jan 2025', reads: 312, preview: 'TCS Digital NQT is harder than the regular NQT...' },
  { id: 5, title: 'SQL Queries That Actually Appear in Interviews', isYours: false, author: 'Dr. Priya · Faculty', tag: 'TECHNICAL GUIDE', date: 'Dec 2024', reads: 156, preview: 'Based on experience writeups from 3 batches, these SQL patterns appear most...' },
  { id: 6, title: 'Infosys Systems Engineer: The Full Process', isYours: false, author: 'Deepika Raj · 22MX', tag: 'PLACEMENT EXPERIENCE', date: 'Oct 2024', reads: 278, preview: 'Infosys SE selection has 3 rounds: Online test, technical, and HR...' },
];

const tagColors: Record<string, string> = {
  'PLACEMENT EXPERIENCE': 'bg-primary-purple/10 text-primary-purple',
  'TECHNICAL GUIDE': 'bg-electric-blue/10 text-electric-blue',
  'COMPANY SPECIFIC': 'bg-illus-gold/10 text-illus-gold',
  'CAREER ADVICE': 'bg-deep-violet/10 text-deep-violet',
};

export default function AlumniKnowledgeBrainPage() {
  const [search, setSearch] = useState('');
  const [showYoursOnly, setShowYoursOnly] = useState(false);

  const filtered = articles.filter(a =>
    (search === '' || a.title.toLowerCase().includes(search.toLowerCase())) &&
    (!showYoursOnly || a.isYours)
  );

  return (
    <div className="max-w-[1200px] mx-auto space-y-8 pb-8">

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-[24px] font-black text-text-main tracking-tight flex items-center gap-2">
            <BookOpen className="w-6 h-6 text-primary-purple" /> Knowledge Brain
          </h1>
          <p className="text-[13px] text-text-muted mt-0.5">147 articles indexed · You contributed 2 of them.</p>
        </div>
        <Link href="/alumni/contribute" className="flex items-center gap-2 px-5 py-2.5 bg-primary-purple text-white rounded-xl text-[13px] font-bold hover:bg-deep-violet transition-colors shadow-sm">
          <PenLine className="w-4 h-4" /> Write Article
        </Link>
      </div>

      {/* Your Impact */}
      <div className="grid grid-cols-3 gap-4">
        {[
          { label: 'Your Articles', value: '2 approved', icon: FileText },
          { label: 'Total Reads', value: '664', icon: BookOpen },
          { label: 'AI Senior Surfaces', value: '87/month', icon: Star },
        ].map((s, i) => (
          <div key={i} className="bg-white rounded-[16px] border border-border-light p-5 flex items-center gap-4">
            <div className="w-10 h-10 rounded-full bg-primary-purple flex items-center justify-center shrink-0">
              <s.icon className="w-5 h-5 text-white" />
            </div>
            <div>
              <p className="text-[11px] font-bold text-text-muted uppercase">{s.label}</p>
              <p className="text-[18px] font-black text-text-main">{s.value}</p>
            </div>
          </div>
        ))}
      </div>

      {/* Search & Filter */}
      <div className="bg-white rounded-[20px] border border-border-light shadow-[0_2px_12px_rgba(0,0,0,0.02)] p-5">
        <div className="flex gap-4 items-center">
          <div className="flex-1 flex items-center bg-page-bg border border-border-light rounded-xl px-4 py-3 focus-within:border-primary-purple transition-colors">
            <Search className="w-4 h-4 text-text-muted mr-3 shrink-0" />
            <input type="text" value={search} onChange={(e) => setSearch(e.target.value)} placeholder="Search articles..." className="bg-transparent border-none outline-none text-[14px] text-text-main placeholder-text-muted w-full" />
          </div>
          <button onClick={() => setShowYoursOnly(!showYoursOnly)} className={`px-5 py-3 rounded-xl text-[13px] font-bold transition-colors shrink-0 ${showYoursOnly ? 'bg-primary-purple text-white' : 'bg-page-bg border border-border-light text-text-muted hover:bg-border-light'}`}>
            <Star className="w-4 h-4 inline mr-1.5" />My Articles Only
          </button>
        </div>
      </div>

      {/* Articles Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
        {filtered.map((article, i) => (
          <motion.div key={article.id} initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.05 }} className={`bg-white rounded-[20px] border shadow-[0_2px_12px_rgba(0,0,0,0.02)] p-6 hover:border-primary-purple/30 transition-all ${article.isYours ? 'border-primary-purple/30 ring-1 ring-primary-purple/10' : 'border-border-light'}`}>
            <div className="flex items-start justify-between mb-3">
              <span className={`text-[10px] font-bold px-2.5 py-1 rounded-full ${tagColors[article.tag] || 'bg-page-bg text-text-muted'}`}>{article.tag}</span>
              <div className="flex items-center gap-2">
                {article.isYours && <span className="text-[10px] font-bold bg-primary-purple text-white px-2 py-0.5 rounded-full">BY YOU</span>}
                <div className="flex items-center gap-1 text-[11px] text-text-muted"><CheckCircle className="w-3 h-3 text-electric-blue" /> Approved</div>
              </div>
            </div>
            <h4 className="text-[15px] font-bold text-text-main mb-2">{article.title}</h4>
            <p className="text-[12px] text-text-muted mb-2">{article.author} · {article.date}</p>
            <p className="text-[13px] text-text-muted line-clamp-2 mb-4">{article.preview}</p>
            <div className="flex items-center justify-between pt-4 border-t border-border-light">
              <span className="text-[11px] text-text-muted">{article.reads} reads</span>
              {article.isYours && (
                <Link href="/alumni/contribute" className="text-[12px] font-bold text-primary-purple hover:underline flex items-center gap-1">Edit Article <ArrowRight className="w-3 h-3" /></Link>
              )}
            </div>
          </motion.div>
        ))}
      </div>
    </div>
  );
}
