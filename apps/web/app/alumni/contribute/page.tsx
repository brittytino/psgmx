'use client';

import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { PenLine, FileText, CheckCircle, AlertTriangle, Clock, Eye, TrendingUp, Send } from 'lucide-react';

const mySubmissions = [
  { id: 1, title: 'How I cracked Zoho\'s 5-round process', status: 'APPROVED', date: 'Mar 2025', views: 243, facultyNote: null },
  { id: 2, title: 'My 2-Year MCA Preparation Strategy', status: 'APPROVED', date: 'Feb 2025', views: 421, facultyNote: null },
  { id: 3, title: 'SQL Queries That Actually Appear in Interviews', status: 'PENDING', date: 'Jan 2025', views: 0, facultyNote: null },
  { id: 4, title: 'What my first year at Zoho looked like', status: 'REVISION', date: 'Dec 2024', views: 0, facultyNote: 'Please add more specifics about the technologies used in your role. The industry perspective section is excellent — expand it.' },
];

const categories = ['Placement Experience', 'Technical Guide', 'Career Advice', 'Industry Insight', 'Company Review'];
const statusColors: Record<string, string> = {
  'APPROVED': 'bg-electric-blue/10 text-electric-blue',
  'PENDING': 'bg-illus-gold/10 text-illus-gold',
  'REVISION': 'bg-deep-violet/10 text-deep-violet',
};
const statusIcons: Record<string, any> = {
  'APPROVED': CheckCircle,
  'PENDING': Clock,
  'REVISION': AlertTriangle,
};

export default function ContributePage() {
  const [title, setTitle] = useState('');
  const [category, setCategory] = useState('Placement Experience');
  const [company, setCompany] = useState('');
  const [body, setBody] = useState('');
  const [tags, setTags] = useState('');
  const [submitted, setSubmitted] = useState(false);
  const [selectedRevision, setSelectedRevision] = useState<any>(null);

  const handleSubmit = () => {
    if (!title.trim() || !body.trim()) return;
    setSubmitted(true);
    setTimeout(() => { setSubmitted(false); setTitle(''); setBody(''); setTags(''); setCompany(''); }, 3000);
  };

  return (
    <div className="max-w-[1300px] mx-auto space-y-8 pb-8">

      {/* Header */}
      <div>
        <h1 className="text-[24px] font-black text-text-main tracking-tight flex items-center gap-2">
          <PenLine className="w-6 h-6 text-primary-purple" /> Contribute to Knowledge Brain
        </h1>
        <p className="text-[13px] text-text-muted mt-0.5">Your real experience is the most valuable thing you can give back to your department.</p>
      </div>

      {/* Impact Banner */}
      <div className="bg-gradient-to-r from-primary-purple to-deep-violet rounded-[20px] p-6 flex items-center justify-between">
        <div>
          <h3 className="text-[16px] font-bold text-white">Your articles were surfaced by AI Senior <span className="font-black">87 times</span> this month</h3>
          <p className="text-[13px] text-white/80 mt-1">3 articles · 664 total reads · Actively helping 200+ students</p>
        </div>
        <TrendingUp className="w-12 h-12 text-white/30 shrink-0" />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">

        {/* Article Editor */}
        <div className="bg-white rounded-[24px] border border-border-light shadow-[0_4px_20px_rgba(0,0,0,0.04)] p-8">
          <h2 className="text-[18px] font-bold text-text-main mb-6">Write a New Article</h2>

          <div className="space-y-5">
            <div>
              <label className="text-[12px] font-bold text-text-muted uppercase tracking-wider block mb-2">Article Title *</label>
              <input type="text" value={title} onChange={(e) => setTitle(e.target.value)} placeholder="E.g. How I prepared for Zoho's programming test" className="w-full bg-page-bg border border-border-light rounded-xl px-4 py-3 text-[14px] text-text-main outline-none focus:border-primary-purple transition-colors" />
            </div>

            <div>
              <label className="text-[12px] font-bold text-text-muted uppercase tracking-wider block mb-2">Category *</label>
              <select value={category} onChange={(e) => setCategory(e.target.value)} className="w-full bg-page-bg border border-border-light rounded-xl px-4 py-3 text-[14px] text-text-main outline-none focus:border-primary-purple transition-colors">
                {categories.map(c => <option key={c} value={c}>{c}</option>)}
              </select>
            </div>

            {(category === 'Placement Experience' || category === 'Company Review') && (
              <div>
                <label className="text-[12px] font-bold text-text-muted uppercase tracking-wider block mb-2">Company Name</label>
                <input type="text" value={company} onChange={(e) => setCompany(e.target.value)} placeholder="E.g. Zoho Corporation, TCS, Infosys" className="w-full bg-page-bg border border-border-light rounded-xl px-4 py-3 text-[14px] text-text-main outline-none focus:border-primary-purple transition-colors" />
              </div>
            )}

            <div>
              <label className="text-[12px] font-bold text-text-muted uppercase tracking-wider block mb-2">Article Content *</label>
              <textarea
                value={body}
                onChange={(e) => setBody(e.target.value)}
                placeholder="Write your article here. Share your real experience — the more specific, the more helpful it is for juniors. Describe the rounds, the types of questions, what worked, what didn't..."
                rows={10}
                className="w-full bg-page-bg border border-border-light rounded-xl px-4 py-3 text-[14px] text-text-main outline-none focus:border-primary-purple transition-colors resize-none"
              />
              <p className="text-[11px] text-text-muted mt-1">{body.length} characters · Minimum 200 recommended</p>
            </div>

            <div>
              <label className="text-[12px] font-bold text-text-muted uppercase tracking-wider block mb-2">Tags (comma separated)</label>
              <input type="text" value={tags} onChange={(e) => setTags(e.target.value)} placeholder="E.g. DSA, SQL, HR Interview, Python" className="w-full bg-page-bg border border-border-light rounded-xl px-4 py-3 text-[14px] text-text-main outline-none focus:border-primary-purple transition-colors" />
            </div>

            <div className="p-4 bg-page-bg rounded-xl border border-border-light">
              <p className="text-[12px] font-bold text-text-muted">📋 Review Process</p>
              <p className="text-[12px] text-text-muted mt-1">Faculty will review your article within 48 hours. Once approved, it's indexed in the Knowledge Brain and the AI Senior can use it to answer student questions.</p>
            </div>

            <button
              onClick={handleSubmit}
              disabled={!title.trim() || !body.trim()}
              className="w-full py-4 bg-primary-purple text-white rounded-xl text-[15px] font-bold hover:bg-deep-violet transition-colors disabled:opacity-40 disabled:cursor-not-allowed flex items-center justify-center gap-2"
            >
              {submitted ? '✓ Submitted for Review!' : <><Send className="w-5 h-5" /> Submit for Faculty Review</>}
            </button>
          </div>
        </div>

        {/* Submission History */}
        <div className="bg-white rounded-[24px] border border-border-light shadow-[0_4px_20px_rgba(0,0,0,0.04)] p-8">
          <h2 className="text-[18px] font-bold text-text-main mb-6">Your Submissions</h2>

          <div className="space-y-4">
            {mySubmissions.map((sub, i) => {
              const StatusIcon = statusIcons[sub.status];
              return (
                <motion.div key={sub.id} initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.08 }} className="p-5 rounded-[16px] border border-border-light hover:border-primary-purple/30 transition-colors">
                  <div className="flex items-start justify-between gap-3">
                    <div className="flex-1">
                      <h4 className="text-[14px] font-bold text-text-main mb-1">{sub.title}</h4>
                      <p className="text-[12px] text-text-muted">{sub.date} {sub.views > 0 && `· ${sub.views} reads`}</p>
                    </div>
                    <span className={`text-[10px] font-bold px-2.5 py-1 rounded-full flex items-center gap-1 shrink-0 ${statusColors[sub.status]}`}>
                      <StatusIcon className="w-3 h-3" /> {sub.status}
                    </span>
                  </div>

                  {sub.status === 'REVISION' && sub.facultyNote && (
                    <div className="mt-3 p-3 bg-deep-violet/5 border border-deep-violet/20 rounded-xl">
                      <p className="text-[11px] font-bold text-deep-violet mb-1">Faculty Feedback:</p>
                      <p className="text-[12px] text-text-muted">{sub.facultyNote}</p>
                      <button className="mt-2 text-[12px] font-bold text-primary-purple hover:underline">Edit & Resubmit →</button>
                    </div>
                  )}

                  {sub.status === 'APPROVED' && (
                    <div className="mt-3 flex items-center gap-3">
                      <span className="text-[11px] font-bold text-electric-blue flex items-center gap-1"><CheckCircle className="w-3 h-3" /> Indexed in Knowledge Brain</span>
                      <span className="text-[11px] text-text-muted flex items-center gap-1"><Eye className="w-3 h-3" /> {sub.views} reads</span>
                    </div>
                  )}
                </motion.div>
              );
            })}
          </div>
        </div>
      </div>
    </div>
  );
}
