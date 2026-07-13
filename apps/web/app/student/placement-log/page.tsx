'use client';

import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { Building2, Search, Filter, ChevronDown, ArrowRight, Tag, User, Calendar, Trophy } from 'lucide-react';

const experiences = [
  { id: 1, company: 'Zoho Corporation', role: 'Software Engineer', batch: '23MX', date: 'Dec 2024', outcome: 'Selected', rounds: ['Online Test (Reasoning + Prog)', 'Technical Round 1', 'Technical Round 2', 'HR'], tags: ['DSA', 'C Programming', 'Logic', 'HR'], preview: 'The Zoho test is pure programming + reasoning. No aptitude. They test you with questions that require clean logical thinking. I was asked to implement a specific algorithm from scratch without any library functions...' },
  { id: 2, company: 'TCS Digital', role: 'Systems Engineer', batch: '22MX', date: 'Nov 2024', outcome: 'Selected', rounds: ['Online Test (NQT)', 'Technical', 'HR'], tags: ['DSA', 'Aptitude', 'SQL', 'Python'], preview: 'TCS Digital NQT is harder than the regular NQT. Expect 60 minutes for 26 questions. The coding section tests medium-level DSA. I got a graph problem and a string manipulation problem...' },
  { id: 3, company: 'Infosys', role: 'Systems Engineer', batch: '22MX', date: 'Oct 2024', outcome: 'Selected', rounds: ['Online Test', 'Technical + HR (Combined)'], tags: ['Pseudocode', 'Reasoning', 'Verbal'], preview: 'Infosys uses a pseudo-code section in their test that many students overlook. It tests your ability to trace through code without running it. Study their specific pseudo-code syntax before the test...' },
  { id: 4, company: 'Capgemini', role: 'Analyst', batch: '23MX', date: 'Sep 2024', outcome: 'Selected', rounds: ['Game-based Assessment', 'Technical', 'HR'], tags: ['Reasoning', 'Attention to Detail', 'HR'], preview: 'Capgemini uses a gamified assessment called "GameChallenge" that tests attention to detail, reasoning speed, and pattern recognition. It\'s not like any regular aptitude test...' },
  { id: 5, company: 'Wipro', role: 'Project Engineer', batch: '21MX', date: 'Aug 2024', outcome: 'Rejected', rounds: ['Online Test', 'Technical'], tags: ['Aptitude', 'SQL', 'Python'], preview: 'I was rejected at the technical round. The interviewer asked very specific SQL optimization questions that I hadn\'t prepared for. I recommend studying query execution plans and indexing concepts...' },
  { id: 6, company: 'Zoho Corporation', role: 'Junior Developer', batch: '21MX', date: 'Dec 2023', outcome: 'Selected', rounds: ['Programming Test', 'Technical 1', 'Technical 2', 'HR', 'Management'], tags: ['C++', 'Data Structures', 'OOP', 'HR'], preview: 'The 2023 Zoho process had 5 rounds total. The programming test gave 4 hours for 7 problems of increasing difficulty. If you can solve 4-5 cleanly, you will likely clear it...' },
];

const companies = ['All', 'Zoho', 'TCS', 'Infosys', 'Capgemini', 'Wipro', 'Others'];
const outcomeColors: Record<string, string> = {
  'Selected': 'bg-electric-blue/10 text-electric-blue border-electric-blue/20',
  'Rejected': 'bg-deep-violet/10 text-deep-violet border-deep-violet/20',
  'On Hold': 'bg-illus-gold/10 text-illus-gold border-illus-gold/20',
};

export default function PlacementLogPage() {
  const [search, setSearch] = useState('');
  const [company, setCompany] = useState('All');
  const [expandedId, setExpandedId] = useState<number | null>(null);

  const filtered = experiences.filter(e =>
    (company === 'All' || e.company.includes(company)) &&
    (search === '' || e.company.toLowerCase().includes(search.toLowerCase()) || e.tags.some(t => t.toLowerCase().includes(search.toLowerCase())))
  );

  const companyStats = [
    { name: 'Zoho', drives: 4, selected: 18, avgRounds: 4 },
    { name: 'TCS Digital', drives: 3, selected: 12, avgRounds: 3 },
    { name: 'Infosys', drives: 2, selected: 22, avgRounds: 2 },
    { name: 'Capgemini', drives: 2, selected: 15, avgRounds: 3 },
  ];

  return (
    <div className="max-w-[1200px] mx-auto space-y-8 pb-8">

      {/* Header */}
      <div>
        <h1 className="text-[24px] font-black text-text-main tracking-tight flex items-center gap-2">
          <Building2 className="w-6 h-6 text-primary-purple" /> Placement Log
        </h1>
        <p className="text-[13px] text-text-muted mt-0.5">Real experiences from real seniors — every company, every round, written by those who sat the drives.</p>
        <div className="flex items-center gap-2 mt-2">
          <span className="text-[11px] font-bold bg-page-bg border border-border-light text-text-muted px-3 py-1 rounded-full">📖 Read-only on web</span>
          <span className="text-[11px] font-bold bg-page-bg border border-border-light text-text-muted px-3 py-1 rounded-full">✍️ Write via Flutter App (2nd year students)</span>
        </div>
      </div>

      {/* Company Stats */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        {companyStats.map((c, i) => (
          <motion.div key={i} initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.05 }} className="bg-white rounded-[16px] border border-border-light p-5 hover:border-primary-purple/30 transition-colors cursor-pointer" onClick={() => setCompany(c.name)}>
            <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-primary-purple to-deep-violet flex items-center justify-center text-white font-black text-[14px] mb-3">{c.name[0]}</div>
            <p className="text-[14px] font-bold text-text-main">{c.name}</p>
            <p className="text-[12px] text-text-muted mt-1">{c.drives} drives · {c.selected} selected</p>
          </motion.div>
        ))}
      </div>

      {/* Search & Filter */}
      <div className="flex gap-4">
        <div className="flex-1 flex items-center bg-white border border-border-light rounded-xl px-4 py-3 shadow-sm focus-within:border-primary-purple transition-colors">
          <Search className="w-4 h-4 text-text-muted mr-3 shrink-0" />
          <input type="text" value={search} onChange={(e) => setSearch(e.target.value)} placeholder="Search by company, skill, round type..." className="bg-transparent border-none outline-none text-[14px] text-text-main placeholder-text-muted w-full" />
        </div>
        <div className="flex gap-2">
          {companies.map((c) => (
            <button key={c} onClick={() => setCompany(c)} className={`px-4 py-2 rounded-xl text-[12px] font-bold transition-colors shrink-0 ${company === c ? 'bg-primary-purple text-white' : 'bg-white border border-border-light text-text-muted hover:bg-page-bg'}`}>
              {c}
            </button>
          ))}
        </div>
      </div>

      {/* Experience Cards */}
      <div className="space-y-4">
        {filtered.map((exp, i) => (
          <motion.div key={exp.id} initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.05 }} className="bg-white rounded-[20px] border border-border-light shadow-[0_2px_12px_rgba(0,0,0,0.02)] overflow-hidden">
            <div className="p-6 cursor-pointer hover:bg-page-bg transition-colors" onClick={() => setExpandedId(expandedId === exp.id ? null : exp.id)}>
              <div className="flex items-start justify-between gap-4">
                <div className="flex items-start gap-4">
                  <div className="w-12 h-12 rounded-[12px] bg-gradient-to-br from-primary-purple/20 to-deep-violet/20 flex items-center justify-center text-primary-purple font-black text-[18px] shrink-0">
                    {exp.company[0]}
                  </div>
                  <div>
                    <h4 className="text-[16px] font-bold text-text-main">{exp.company}</h4>
                    <p className="text-[13px] text-text-muted">{exp.role} · Batch {exp.batch} · {exp.date}</p>
                    <div className="flex flex-wrap gap-2 mt-2">
                      {exp.rounds.map((r, ri) => (
                        <span key={ri} className="text-[10px] font-bold bg-page-bg text-text-muted border border-border-light px-2 py-1 rounded-full">{r}</span>
                      ))}
                    </div>
                  </div>
                </div>
                <div className="flex items-center gap-3 shrink-0">
                  <span className={`text-[11px] font-bold px-3 py-1 rounded-full border ${outcomeColors[exp.outcome]}`}>{exp.outcome}</span>
                  <ChevronDown className={`w-4 h-4 text-text-muted transition-transform ${expandedId === exp.id ? 'rotate-180' : ''}`} />
                </div>
              </div>

              {/* Tags */}
              <div className="flex gap-2 mt-4">
                {exp.tags.map((t) => (
                  <span key={t} className="text-[10px] font-bold bg-primary-purple/10 text-primary-purple px-2 py-0.5 rounded-full">#{t}</span>
                ))}
              </div>
            </div>

            {expandedId === exp.id && (
              <motion.div initial={{ opacity: 0, height: 0 }} animate={{ opacity: 1, height: 'auto' }} exit={{ opacity: 0, height: 0 }} className="border-t border-border-light px-6 py-5 bg-page-bg">
                <p className="text-[14px] text-text-main leading-relaxed">{exp.preview}</p>
                <p className="text-[12px] text-text-muted mt-3 italic">— Batch {exp.batch} student · This experience is permanently archived and searchable by the AI Senior.</p>
              </motion.div>
            )}
          </motion.div>
        ))}
      </div>
    </div>
  );
}
