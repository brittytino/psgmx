'use client';

import React from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Award, BrainCircuit, BookOpen, ClipboardList, Users, ArrowRight, Calendar, TrendingUp, Flame, FileText, Building2, Star, ChevronRight } from 'lucide-react';
import Link from 'next/link';

const StatCard = ({ title, value, trend, trendUp, icon: Icon, color, delay, sparkPath }: any) => (
  <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay }} className="bg-white rounded-[20px] p-6 shadow-[0_2px_12px_rgba(0,0,0,0.03)] border border-border-light relative overflow-hidden flex flex-col justify-between h-[140px]">
    <div className="flex items-center gap-3">
      <div className={`w-10 h-10 rounded-full ${color} flex items-center justify-center shadow-sm`}>
        <Icon className="w-5 h-5 text-white" />
      </div>
      <p className="text-[12px] font-bold text-text-muted">{title}</p>
    </div>
    <div className="flex items-end justify-between mt-auto">
      <div>
        <h3 className="text-[32px] font-black text-text-main leading-none mb-1">{value}</h3>
        <p className={`text-[11px] font-bold ${trendUp ? 'text-electric-blue' : 'text-deep-violet'}`}>{trend}</p>
      </div>
      <div className="w-24 h-8">
        <svg viewBox="0 0 100 30" className={`w-full h-full fill-none ${trendUp ? 'stroke-primary-purple' : 'stroke-deep-violet'}`} strokeWidth="3" strokeLinecap="round" strokeLinejoin="round">
          <path d={sparkPath} />
        </svg>
      </div>
    </div>
  </motion.div>
);

export default function StudentDashboard() {
  const readinessScore = 72;
  const readinessComponents = [
    { label: 'Daily Five Engagement', value: 21, max: 30, color: 'bg-primary-purple' },
    { label: 'LeetCode Progress', value: 16, max: 25, color: 'bg-electric-blue' },
    { label: 'Mock Exam Performance', value: 28, max: 35, color: 'bg-illus-gold' },
    { label: 'Session Attendance', value: 7, max: 10, color: 'bg-deep-violet' },
  ];

  const upcomingExams = [
    { name: 'Data Structures — Full Mock', date: 'Jan 20, 2025', duration: '90 min', type: 'MCQ + Coding', daysLeft: 4 },
    { name: 'Aptitude Assessment — Q3', date: 'Jan 28, 2025', duration: '60 min', type: 'MCQ', daysLeft: 12 },
  ];

  const recentArticles = [
    { title: "How I cracked Zoho's 5-round process", author: 'Alumni 23MX201', tag: 'PLACEMENT EXPERIENCE' },
    { title: 'Dynamic Programming - A Pattern-First Guide', author: 'Faculty · Dr. Arunkumar', tag: 'TECHNICAL GUIDE' },
    { title: "What TCS Digital's aptitude test actually tests", author: 'Alumni 22MX115', tag: 'COMPANY SPECIFIC' },
  ];

  const today = new Date().toLocaleDateString('en-IN', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' });

  const getBand = (score: number) => {
    if (score >= 80) return { label: 'STRONG', color: 'bg-electric-blue text-white' };
    if (score >= 60) return { label: 'BUILDING', color: 'bg-illus-gold text-white' };
    if (score >= 40) return { label: 'NEEDS ATTENTION', color: 'bg-primary-purple text-white' };
    return { label: 'AT RISK', color: 'bg-deep-violet text-white' };
  };

  const band = getBand(readinessScore);

  const [aiQuery, setAiQuery] = React.useState('');
  const [aiResponse, setAiResponse] = React.useState('');
  const [isAiLoading, setIsAiLoading] = React.useState(false);

  const handleAiAsk = async () => {
    if (!aiQuery.trim()) return;
    setIsAiLoading(true);
    try {
      const res = await fetch('/api/ai-senior', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ query: aiQuery }) });
      const data = await res.json();
      setAiResponse(data.success ? data.answer : 'Sorry, I encountered an error. Please try again.');
    } catch {
      setAiResponse('Connection failed. Please try again.');
    } finally {
      setIsAiLoading(false);
    }
  };

  return (
    <div className="max-w-[1400px] mx-auto space-y-8 pb-8">

      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <motion.h1 initial={{ opacity: 0, y: -10 }} animate={{ opacity: 1, y: 0 }} className="text-[26px] font-bold text-text-main tracking-tight mb-1">
            Welcome back, Scholar 👋
          </motion.h1>
          <motion.p initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: 0.1 }} className="text-[14px] text-text-muted">
            Here's your placement readiness snapshot for today.
          </motion.p>
        </div>
        <div className="flex items-center gap-3 bg-white border border-border-light rounded-2xl px-5 py-3 shadow-sm shrink-0">
          <Calendar className="w-5 h-5 text-text-muted" />
          <div>
            <p className="text-[13px] font-bold text-text-main">{new Date().toLocaleDateString('en-IN', { month: 'long', day: 'numeric', year: 'numeric' })}</p>
            <p className="text-[11px] font-semibold text-text-muted">{new Date().toLocaleDateString('en-IN', { weekday: 'long' })}</p>
          </div>
        </div>
      </div>

      {/* Readiness Score Hero Card */}
      <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.05 }} className="bg-white rounded-[24px] border border-border-light shadow-[0_4px_20px_rgba(0,0,0,0.04)] p-8">
        <div className="flex flex-col lg:flex-row gap-8 items-center lg:items-start">

          {/* Score Circle */}
          <div className="relative w-48 h-48 shrink-0">
            <svg viewBox="0 0 100 100" className="w-full h-full -rotate-90">
              <circle cx="50" cy="50" r="44" fill="none" stroke="#EFE9E0" strokeWidth="8" />
              <circle
                cx="50" cy="50" r="44" fill="none" stroke="var(--primary-purple)" strokeWidth="8"
                strokeLinecap="round"
                strokeDasharray={`${(readinessScore / 100) * 276.46} 276.46`}
                strokeDashoffset="0"
                style={{ transition: 'stroke-dasharray 1s ease-in-out' }}
              />
            </svg>
            <div className="absolute inset-0 flex flex-col items-center justify-center">
              <span className="text-[44px] font-black text-text-main leading-none">{readinessScore}</span>
              <span className="text-[10px] font-bold text-text-muted uppercase tracking-wider">/ 100</span>
              <span className={`mt-2 text-[9px] font-bold px-2 py-0.5 rounded-full ${band.color}`}>{band.label}</span>
            </div>
          </div>

          {/* Components Breakdown */}
          <div className="flex-1 w-full space-y-5">
            <div className="flex items-center justify-between">
              <h2 className="text-[18px] font-black text-text-main">Readiness Score Breakdown</h2>
              <Link href="/student/readiness" className="text-[13px] font-bold text-primary-purple flex items-center gap-1 hover:underline">
                Full Analysis <ArrowRight className="w-3.5 h-3.5" />
              </Link>
            </div>
            {readinessComponents.map((comp, i) => (
              <motion.div key={comp.label} initial={{ opacity: 0, x: -20 }} animate={{ opacity: 1, x: 0 }} transition={{ delay: 0.1 + i * 0.1 }}>
                <div className="flex justify-between items-center mb-1.5">
                  <span className="text-[13px] font-semibold text-text-muted">{comp.label}</span>
                  <span className="text-[13px] font-black text-text-main">{comp.value}<span className="text-text-muted font-semibold">/{comp.max}</span></span>
                </div>
                <div className="h-2 bg-border-light rounded-full overflow-hidden">
                  <motion.div
                    initial={{ width: 0 }}
                    animate={{ width: `${(comp.value / comp.max) * 100}%` }}
                    transition={{ delay: 0.3 + i * 0.1, duration: 0.8, ease: 'easeOut' }}
                    className={`h-full rounded-full ${comp.color}`}
                  />
                </div>
              </motion.div>
            ))}
          </div>

          {/* Right: 90-day trend */}
          <div className="hidden xl:flex flex-col items-center gap-2 shrink-0">
            <span className="text-[11px] font-bold text-text-muted uppercase tracking-wider">90-Day Trend</span>
            <svg viewBox="0 0 120 60" className="w-32 h-16 fill-none stroke-primary-purple" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
              <path d="M0,55 C15,50 20,45 30,40 C40,35 45,42 55,35 C65,28 70,20 80,18 C90,16 100,12 120,8" />
            </svg>
            <TrendingUp className="w-4 h-4 text-electric-blue" />
            <span className="text-[11px] font-bold text-electric-blue">↑ 8 pts this month</span>
          </div>
        </div>
      </motion.div>

      {/* 4 Stat Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <StatCard title="Readiness Score" value={readinessScore} trend="↑ 8 pts this month" trendUp icon={Award} color="bg-primary-purple" delay={0.1} sparkPath="M0,25 C20,25 30,15 50,15 C70,15 80,5 100,5" />
        <StatCard title="Current Streak" value="14" trend="Days via Flutter App" trendUp icon={Flame} color="bg-deep-violet" delay={0.2} sparkPath="M0,20 C20,18 30,10 50,8 C70,6 80,4 100,2" />
        <StatCard title="Exams Taken" value="5" trend="↑ 2 this semester" trendUp icon={ClipboardList} color="bg-illus-gold" delay={0.3} sparkPath="M0,25 C20,20 40,15 60,18 C80,22 90,8 100,5" />
        <StatCard title="Articles Read" value="23" trend="Keep exploring" trendUp icon={BookOpen} color="bg-electric-blue" delay={0.4} sparkPath="M0,22 C15,20 30,18 50,14 C70,10 85,8 100,5" />
      </div>

      {/* Main Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">

        {/* Left: 2/3 */}
        <div className="lg:col-span-2 space-y-6">

          {/* Upcoming Mock Exams */}
          <div className="bg-white rounded-[20px] border border-border-light shadow-[0_2px_12px_rgba(0,0,0,0.02)] flex flex-col">
            <div className="p-6 border-b border-page-bg flex justify-between items-center">
              <div className="flex items-center gap-2">
                <ClipboardList className="w-5 h-5 text-primary-purple" />
                <h3 className="text-[16px] font-bold text-text-main">Upcoming Mock Exams</h3>
              </div>
              <span className="text-[13px] font-bold text-primary-purple">{upcomingExams.length} Scheduled</span>
            </div>
            <div className="p-6 space-y-4">
              {upcomingExams.map((exam, i) => (
                <div key={i} className="flex items-center justify-between p-4 rounded-[16px] border border-border-light hover:border-primary-purple/30 transition-colors group">
                  <div className="flex items-center gap-4">
                    <div className="w-12 h-12 rounded-[12px] bg-page-bg flex flex-col items-center justify-center shrink-0">
                      <span className="text-[16px] font-black text-primary-purple leading-none">{exam.daysLeft}</span>
                      <span className="text-[8px] font-bold text-text-muted uppercase">days</span>
                    </div>
                    <div>
                      <h4 className="text-[14px] font-bold text-text-main mb-0.5">{exam.name}</h4>
                      <p className="text-[11px] font-semibold text-text-muted">{exam.date} · {exam.duration} · {exam.type}</p>
                    </div>
                  </div>
                  <Link href="/student/exams" className="px-4 py-2 bg-primary-purple text-white rounded-[10px] text-[12px] font-bold opacity-0 group-hover:opacity-100 transition-opacity shrink-0">
                    Details →
                  </Link>
                </div>
              ))}
              <Link href="/student/exams" className="w-full py-3.5 bg-white/40 backdrop-blur-md border border-white/20 text-primary-purple rounded-[12px] text-[13px] font-bold flex items-center justify-center gap-2 hover:bg-page-bg transition-colors">
                View All Exams <ArrowRight className="w-4 h-4" />
              </Link>
            </div>
          </div>

          {/* AI Senior Quick Ask */}
          <div className="bg-white rounded-[20px] border border-border-light shadow-[0_2px_12px_rgba(0,0,0,0.02)] p-6">
            <div className="flex items-center gap-2 mb-6">
              <BrainCircuit className="w-5 h-5 text-primary-purple" />
              <h3 className="text-[16px] font-bold text-text-main">Ask the AI Senior</h3>
              <span className="text-[10px] font-bold bg-primary-purple text-white px-2 py-0.5 rounded-full ml-auto">RAG-Powered</span>
            </div>
            <div className="relative mb-4">
              <input
                type="text" value={aiQuery} onChange={(e) => setAiQuery(e.target.value)}
                onKeyDown={(e) => e.key === 'Enter' && handleAiAsk()}
                placeholder="E.g. Which companies visit MCA for placements? or How do I improve my LeetCode score?"
                className="w-full bg-page-bg border border-border-light rounded-xl px-4 py-3 pr-12 text-[14px] text-text-main placeholder-text-muted outline-none focus:border-primary-purple transition-colors"
              />
              <button onClick={handleAiAsk} disabled={isAiLoading} className="absolute right-2 top-2 p-1.5 bg-primary-purple hover:bg-deep-violet rounded-lg text-white transition-colors disabled:opacity-50">
                <ArrowRight className="w-4 h-4" />
              </button>
            </div>
            {isAiLoading && <p className="text-[13px] text-primary-purple animate-pulse">Searching the Knowledge Brain...</p>}
            {aiResponse && (
              <div className="p-4 bg-page-bg border border-border-light rounded-xl">
                <p className="text-[13px] text-text-main leading-relaxed whitespace-pre-wrap">{aiResponse}</p>
              </div>
            )}
            <Link href="/student/ai-senior" className="mt-4 flex items-center gap-1.5 text-[13px] font-bold text-primary-purple hover:underline">
              Open Full AI Senior Chat <ChevronRight className="w-4 h-4" />
            </Link>
          </div>

          {/* Recent Knowledge Brain Activity */}
          <div className="bg-white rounded-[20px] border border-border-light shadow-[0_2px_12px_rgba(0,0,0,0.02)] flex flex-col">
            <div className="p-6 border-b border-page-bg flex justify-between items-center">
              <div className="flex items-center gap-2">
                <BookOpen className="w-5 h-5 text-primary-purple" />
                <h3 className="text-[16px] font-bold text-text-main">Knowledge Brain — Recent Articles</h3>
              </div>
            </div>
            <div className="p-6 space-y-4">
              {recentArticles.map((article, i) => (
                <div key={i} className="flex items-start gap-4 p-4 rounded-[16px] border border-border-light hover:border-primary-purple/30 transition-colors cursor-pointer group">
                  <div className="w-10 h-10 rounded-[10px] bg-page-bg flex items-center justify-center shrink-0">
                    <FileText className="w-4 h-4 text-primary-purple" />
                  </div>
                  <div className="flex-1">
                    <span className="text-[9px] font-bold text-primary-purple uppercase tracking-wider">{article.tag}</span>
                    <h4 className="text-[14px] font-bold text-text-main mt-0.5 mb-1 group-hover:text-primary-purple transition-colors">{article.title}</h4>
                    <p className="text-[11px] font-semibold text-text-muted">{article.author} · Approved by Faculty ✓</p>
                  </div>
                  <ArrowRight className="w-4 h-4 text-text-muted opacity-0 group-hover:opacity-100 transition-opacity shrink-0 mt-1" />
                </div>
              ))}
              <Link href="/student/knowledge-brain" className="w-full py-3.5 bg-white/40 backdrop-blur-md border border-white/20 text-primary-purple rounded-[12px] text-[13px] font-bold flex items-center justify-center gap-2 hover:bg-page-bg transition-colors">
                Browse Knowledge Brain <ArrowRight className="w-4 h-4" />
              </Link>
            </div>
          </div>
        </div>

        {/* Right: 1/3 */}
        <div className="space-y-6">

          {/* Your Senior Lineage Card */}
          <div className="bg-white rounded-[20px] border border-border-light shadow-[0_2px_12px_rgba(0,0,0,0.02)] p-6">
            <div className="flex items-center gap-2 mb-5">
              <Users className="w-5 h-5 text-primary-purple" />
              <h3 className="text-[16px] font-bold text-text-main">Your Senior</h3>
            </div>
            <div className="flex flex-col items-center text-center gap-3">
              <div className="w-16 h-16 rounded-full bg-gradient-to-br from-primary-purple to-deep-violet flex items-center justify-center text-white text-xl font-black shadow-lg">
                R
              </div>
              <div>
                <h4 className="text-[15px] font-black text-text-main">Riya Menon</h4>
                <p className="text-[12px] text-text-muted">Batch 23MX · Class of 2025</p>
                <p className="text-[12px] font-semibold text-primary-purple mt-1">Software Engineer @ Zoho</p>
              </div>
              <p className="text-[12px] text-text-muted text-center">"Stay consistent. The score takes care of itself."</p>
              <div className="flex gap-2 w-full">
                <a href="#" className="flex-1 py-2 bg-primary-purple text-white rounded-[10px] text-[12px] font-bold text-center hover:bg-deep-violet transition-colors">LinkedIn</a>
                <Link href="/student/lineage" className="flex-1 py-2 bg-page-bg text-primary-purple rounded-[10px] text-[12px] font-bold text-center hover:bg-border-light transition-colors">View Lineage</Link>
              </div>
            </div>
          </div>

          {/* Next Exam Countdown */}
          <div className="bg-white rounded-[20px] border border-border-light shadow-[0_2px_12px_rgba(0,0,0,0.02)] p-6">
            <div className="flex items-center gap-2 mb-4">
              <ClipboardList className="w-5 h-5 text-illus-gold" />
              <h3 className="text-[14px] font-bold text-text-main">Next Exam</h3>
            </div>
            <div className="text-center">
              <div className="flex items-center justify-center gap-3 mb-3">
                <div className="text-center">
                  <span className="text-[36px] font-black text-primary-purple leading-none">4</span>
                  <p className="text-[9px] font-bold text-text-muted uppercase">Days</p>
                </div>
                <span className="text-[24px] font-black text-border-light">:</span>
                <div className="text-center">
                  <span className="text-[36px] font-black text-primary-purple leading-none">08</span>
                  <p className="text-[9px] font-bold text-text-muted uppercase">Hours</p>
                </div>
              </div>
              <p className="text-[13px] font-bold text-text-main mb-4">Data Structures — Full Mock</p>
              <Link href="/student/exams" className="block w-full py-2.5 bg-primary-purple text-white rounded-[10px] text-[13px] font-bold hover:bg-deep-violet transition-colors">
                Prepare Now →
              </Link>
            </div>
          </div>

          {/* Batch Leaderboard Mini */}
          <div className="bg-white rounded-[20px] border border-border-light shadow-[0_2px_12px_rgba(0,0,0,0.02)] p-6">
            <div className="flex items-center justify-between mb-5">
              <div className="flex items-center gap-2">
                <Star className="w-5 h-5 text-illus-gold" />
                <h3 className="text-[14px] font-bold text-text-main">Batch Leaderboard</h3>
              </div>
              <span className="text-[10px] font-bold text-text-muted bg-page-bg px-2 py-1 rounded-lg">25MX</span>
            </div>
            <div className="space-y-3">
              {[
                { rank: 1, token: '25MX089', score: 91, isYou: false },
                { rank: 2, token: '25MX156', score: 87, isYou: false },
                { rank: 3, token: '25MX301', score: 72, isYou: true },
                { rank: 4, token: '25MX044', score: 68, isYou: false },
                { rank: 5, token: '25MX212', score: 65, isYou: false },
              ].map((s) => (
                <div key={s.rank} className={`flex items-center gap-3 p-2.5 rounded-[10px] transition-colors ${s.isYou ? 'bg-primary-purple/10 border border-primary-purple/20' : 'hover:bg-page-bg'}`}>
                  <span className={`text-[13px] font-black w-5 text-center ${s.rank <= 3 ? 'text-illus-gold' : 'text-text-muted'}`}>{s.rank}</span>
                  <span className={`text-[13px] font-bold flex-1 ${s.isYou ? 'text-primary-purple' : 'text-text-main'}`}>{s.token} {s.isYou && '(You)'}</span>
                  <span className="text-[13px] font-black text-text-main">{s.score}</span>
                </div>
              ))}
            </div>
            <p className="text-[10px] text-text-muted mt-3 text-center">Full leaderboard available in Flutter app</p>
          </div>

          {/* Placement Log Teaser */}
          <div className="bg-white rounded-[20px] border border-border-light shadow-[0_2px_12px_rgba(0,0,0,0.02)] p-6">
            <div className="flex items-center gap-2 mb-4">
              <Building2 className="w-5 h-5 text-primary-purple" />
              <h3 className="text-[14px] font-bold text-text-main">Recent Drives</h3>
            </div>
            {[
              { company: 'Zoho Corporation', role: 'Software Engineer', date: 'Jan 8, 2025' },
              { company: 'TCS Digital', role: 'Systems Engineer', date: 'Dec 20, 2024' },
            ].map((d, i) => (
              <div key={i} className="flex items-center gap-3 mb-3 last:mb-0">
                <div className="w-8 h-8 rounded-lg bg-page-bg flex items-center justify-center text-[13px] font-black text-primary-purple shrink-0">
                  {d.company[0]}
                </div>
                <div>
                  <p className="text-[13px] font-bold text-text-main">{d.company}</p>
                  <p className="text-[11px] text-text-muted">{d.role} · {d.date}</p>
                </div>
              </div>
            ))}
            <Link href="/student/placement-log" className="mt-3 flex items-center gap-1.5 text-[13px] font-bold text-primary-purple hover:underline">
              Read All Experiences <ArrowRight className="w-4 h-4" />
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
}
