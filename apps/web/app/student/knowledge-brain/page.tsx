'use client';

import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { BookOpen, Search, Filter, ArrowRight, FileText, CheckCircle, PenLine } from 'lucide-react';

const articles = [
  { id: 1, title: "How I cracked Zoho's 5-round technical process", author: 'Riya Menon', authorBatch: '23MX', role: 'Alumni', tag: 'PLACEMENT EXPERIENCE', company: 'Zoho', preview: "Zoho's process starts with a reasoning and programming test. They test you on pure logic and C programming - not data structures...", date: 'Mar 2025', reads: 243 },
  { id: 2, title: 'Dynamic Programming — A Pattern-First Guide', author: 'Dr. Arunkumar', authorBatch: 'Faculty', role: 'Faculty', tag: 'TECHNICAL GUIDE', company: null, preview: 'Most students memorize DP solutions. The better approach is recognizing the four patterns: 1D DP, 2D DP, interval DP, and tree DP...', date: 'Feb 2025', reads: 189 },
  { id: 3, title: 'TCS Digital: Aptitude Test Deep Dive', author: 'Arjun Pillai', authorBatch: '22MX', role: 'Alumni', tag: 'COMPANY SPECIFIC', company: 'TCS', preview: "TCS Digital's aptitude section is harder than NQT. Expect 20 questions in 20 minutes covering reasoning, quant, and English...", date: 'Jan 2025', reads: 312 },
  { id: 4, title: 'SQL Queries That Actually Appear in Interviews', author: 'Dr. Priya', authorBatch: 'Faculty', role: 'Faculty', tag: 'TECHNICAL GUIDE', company: null, preview: 'Based on experience writeups from 3 batches, these are the SQL patterns that appear most: GROUP BY with HAVING, subqueries vs JOINs...', date: 'Dec 2024', reads: 156 },
  { id: 5, title: 'My 2-Year MCA Placement Preparation Strategy', author: 'Karthik Sundaram', authorBatch: '23MX', role: 'Alumni', tag: 'CAREER ADVICE', company: null, preview: 'Month 1: Don\'t panic. Month 3: Start LeetCode easy. Month 8: Begin mocks. Here\'s the full breakdown of what worked for me...', date: 'Nov 2024', reads: 421 },
  { id: 6, title: 'Infosys Systems Engineer: The Full Process', author: 'Deepika Raj', authorBatch: '22MX', role: 'Alumni', tag: 'PLACEMENT EXPERIENCE', company: 'Infosys', preview: 'Infosys SE selection has 3 rounds: Online test (reasoning + verbal + pseudo code), technical, and HR. Here\'s what each looked like...', date: 'Oct 2024', reads: 278 },
];

const tabs = ['All', 'Placement Experiences', 'Technical Guides', 'Interview Prep', 'Alumni Advice', 'Company Reviews'];
const tagColors: Record<string, string> = {
  'PLACEMENT EXPERIENCE': 'bg-primary-purple/10 text-primary-purple',
  'TECHNICAL GUIDE': 'bg-electric-blue/10 text-electric-blue',
  'COMPANY SPECIFIC': 'bg-illus-gold/10 text-illus-gold',
  'CAREER ADVICE': 'bg-deep-violet/10 text-deep-violet',
};

export default function KnowledgeBrainPage() {
  const [search, setSearch] = useState('');
  const [activeTab, setActiveTab] = useState('All');
  const [expandedId, setExpandedId] = useState<number | null>(null);

  const filtered = articles.filter(a =>
    (search === '' || a.title.toLowerCase().includes(search.toLowerCase()) || a.author.toLowerCase().includes(search.toLowerCase())) &&
    (activeTab === 'All' ||
      (activeTab === 'Placement Experiences' && a.tag === 'PLACEMENT EXPERIENCE') ||
      (activeTab === 'Technical Guides' && a.tag === 'TECHNICAL GUIDE') ||
      (activeTab === 'Alumni Advice' && a.tag === 'CAREER ADVICE') ||
      (activeTab === 'Company Reviews' && a.company !== null)
    )
  );

  return (
    <div className="max-w-[1200px] mx-auto space-y-8 pb-8">

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-[24px] font-black text-text-main tracking-tight flex items-center gap-2">
            <BookOpen className="w-6 h-6 text-primary-purple" /> Knowledge Brain
          </h1>
          <p className="text-[13px] text-text-muted mt-0.5">147 articles indexed · All reviewed and approved by faculty.</p>
        </div>
        <button className="flex items-center gap-2 px-5 py-2.5 bg-primary-purple text-white rounded-xl text-[13px] font-bold hover:bg-deep-violet transition-colors shadow-sm">
          <PenLine className="w-4 h-4" /> Submit Article
        </button>
      </div>

      {/* Submit CTA Banner */}
      <div className="bg-gradient-to-r from-primary-purple to-deep-violet rounded-[20px] p-6 flex items-center justify-between">
        <div>
          <h3 className="text-[16px] font-bold text-white mb-1">Share your experience. Help 200+ students prepare better.</h3>
          <p className="text-[13px] text-white/80">Submit articles and guides. Faculty will review and approve within 48 hours.</p>
        </div>
        <button className="shrink-0 px-6 py-3 bg-white text-primary-purple rounded-xl text-[13px] font-bold hover:bg-page-bg transition-colors">
          Submit an Article →
        </button>
      </div>

      {/* Search & Filter */}
      <div className="bg-white rounded-[20px] border border-border-light shadow-[0_2px_12px_rgba(0,0,0,0.02)] p-6">
        <div className="flex gap-4 mb-6">
          <div className="flex-1 flex items-center bg-page-bg border border-border-light rounded-xl px-4 py-3 focus-within:border-primary-purple transition-colors">
            <Search className="w-4 h-4 text-text-muted mr-3 shrink-0" />
            <input
              type="text" value={search} onChange={(e) => setSearch(e.target.value)}
              placeholder="Search articles, authors, companies..."
              className="bg-transparent border-none outline-none text-[14px] text-text-main placeholder-text-muted w-full"
            />
          </div>
          <button className="flex items-center gap-2 px-4 py-3 bg-page-bg border border-border-light rounded-xl text-[13px] font-bold text-text-muted hover:bg-border-light transition-colors">
            <Filter className="w-4 h-4" /> Sort
          </button>
        </div>

        {/* Tabs */}
        <div className="flex gap-2 overflow-x-auto pb-2 custom-scrollbar">
          {tabs.map((tab) => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              className={`shrink-0 px-4 py-2 rounded-full text-[12px] font-bold transition-colors ${
                activeTab === tab ? 'bg-primary-purple text-white' : 'bg-page-bg text-text-muted hover:bg-border-light'
              }`}
            >
              {tab}
            </button>
          ))}
        </div>
      </div>

      {/* Articles Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
        {filtered.map((article, i) => (
          <motion.div
            key={article.id}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: i * 0.05 }}
            className="bg-white rounded-[20px] border border-border-light shadow-[0_2px_12px_rgba(0,0,0,0.02)] p-6 hover:border-primary-purple/30 transition-all cursor-pointer group"
            onClick={() => setExpandedId(expandedId === article.id ? null : article.id)}
          >
            <div className="flex items-start justify-between mb-3">
              <span className={`text-[10px] font-bold px-2.5 py-1 rounded-full ${tagColors[article.tag] || 'bg-page-bg text-text-muted'}`}>
                {article.tag}
              </span>
              <div className="flex items-center gap-1 text-[11px] text-text-muted">
                <CheckCircle className="w-3 h-3 text-electric-blue" /> Approved
              </div>
            </div>

            <h4 className="text-[15px] font-bold text-text-main mb-2 group-hover:text-primary-purple transition-colors">{article.title}</h4>

            <div className="flex items-center gap-2 mb-3">
              <div className="w-6 h-6 rounded-full bg-gradient-to-br from-primary-purple to-deep-violet flex items-center justify-center text-white text-[9px] font-bold">
                {article.author[0]}
              </div>
              <span className="text-[12px] font-semibold text-text-muted">{article.author} · {article.authorBatch} · {article.date}</span>
            </div>

            {expandedId === article.id ? (
              <motion.p initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="text-[13px] text-text-main leading-relaxed">
                {article.preview} <span className="text-primary-purple font-bold">Read more →</span>
              </motion.p>
            ) : (
              <p className="text-[13px] text-text-muted line-clamp-2">{article.preview}</p>
            )}

            <div className="flex items-center justify-between mt-4 pt-4 border-t border-border-light">
              <span className="text-[11px] text-text-muted">{article.reads} reads</span>
              <span className="text-[12px] font-bold text-primary-purple flex items-center gap-1 group-hover:gap-2 transition-all">
                {expandedId === article.id ? 'Collapse' : 'Read Article'} <ArrowRight className="w-3.5 h-3.5" />
              </span>
            </div>
          </motion.div>
        ))}
      </div>

      {filtered.length === 0 && (
        <div className="text-center py-20">
          <FileText className="w-12 h-12 text-border-light mx-auto mb-4" />
          <p className="text-[16px] font-bold text-text-muted">No articles found</p>
          <p className="text-[13px] text-text-muted mt-1">Try a different search or filter.</p>
        </div>
      )}
    </div>
  );
}
