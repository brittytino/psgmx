'use client';

import React from 'react';
import { motion } from 'framer-motion';
import { Award, BrainCircuit, BookOpen, ClipboardList, Users, ArrowRight, Calendar, Flame, FileText, Building2, Star, ChevronRight } from 'lucide-react';
import Link from 'next/link';
import { createClient } from '@/lib/supabase/client';
import { InitialsAvatar } from '@/components/basic/InitialsAvatar';

const StatCard = ({ title, value, trend, icon: Icon, color, delay }: any) => (
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
        <p className="text-[11px] font-bold text-text-muted">{trend}</p>
      </div>
    </div>
  </motion.div>
);

const COMPONENT_LABELS: Record<string, string> = {
  daily_five_accuracy_pct: 'Daily Five Accuracy',
  daily_five_adherence_pct: 'Daily Five Adherence',
  placement_attendance_pct: 'Session Attendance',
  task_completion_rate_pct: 'Task Completion',
  leetcode_momentum_percentile: 'LeetCode Momentum',
};

interface DashboardData {
  userName: string;
  batchId: string | null;
  batchCode: string;
  score: number | null;
  components: Record<string, number | null>;
  streak: number;
  articlesCount: number;
  examsTakenCount: number;
  recentArticles: { id: string; title: string; tag: string; authorName: string; authorRole: string }[];
  upcomingExams: { id: string; title: string; examDate: string; durationMinutes: number }[];
  senior: { name: string; quote: string | null } | null;
  leaderboard: { userId: string; name: string; score: number; isYou: boolean }[];
  recentCompanies: { id: string; name: string; role: string; visitDate: string }[];
}

export default function StudentDashboard() {
  const [data, setData] = React.useState<DashboardData | null>(null);
  const [loading, setLoading] = React.useState(true);

  const [aiQuery, setAiQuery] = React.useState('');
  const [aiResponse, setAiResponse] = React.useState('');
  const [isAiLoading, setIsAiLoading] = React.useState(false);

  React.useEffect(() => {
    let cancelled = false;
    const supabase = createClient();

    async function load() {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) { setLoading(false); return; }

      const { data: me } = await supabase
        .from('users')
        .select('name, batch_id')
        .eq('id', user.id)
        .single();

      const batchId = me?.batch_id ?? null;

      const [
        { data: batch },
        { data: scoreRow },
        { data: streakRow },
        { data: articles },
        { data: exams },
        { data: lineage },
        { data: leaderboardRows },
        { data: companies },
      ] = await Promise.all([
        batchId ? supabase.from('batches').select('batch_code').eq('id', batchId).single() : Promise.resolve({ data: null }),
        supabase.from('current_readiness_scores').select('score, components_json').eq('user_id', user.id).maybeSingle(),
        supabase.from('daily_five_streaks').select('current_streak').eq('user_id', user.id).maybeSingle(),
        supabase
          .from('knowledge_brain_articles')
          .select('id, title, tags, created_at, author_id, users!knowledge_brain_articles_author_id_fkey(name, role_label)')
          .eq('approval_status', 'approved')
          .order('created_at', { ascending: false })
          .limit(3),
        supabase
          .from('mock_exam_results')
          .select('id, status, mock_exams(id, title, exam_date, duration_minutes)')
          .eq('student_id', user.id),
        supabase
          .from('lineage_map')
          .select('senior_quote, users!lineage_map_senior_user_id_fkey(name)')
          .eq('student_id', user.id)
          .maybeSingle(),
        batchId
          ? supabase
              .from('current_readiness_scores')
              .select('user_id, score, users!inner(name, batch_id)')
              .eq('users.batch_id', batchId)
              .order('score', { ascending: false })
              .limit(5)
          : Promise.resolve({ data: [] }),
        supabase.from('companies').select('id, name, roles_offered, visit_date').order('visit_date', { ascending: false }).limit(2),
      ]);

      const { count: articlesCount } = await supabase
        .from('knowledge_brain_articles')
        .select('id', { count: 'exact', head: true })
        .eq('approval_status', 'approved');

      const examResultsList = (exams || []) as any[];
      const examsTakenCount = examResultsList.filter((e) => e.status === 'submitted').length;
      const upcomingExams = examResultsList
        .filter((e) => e.status === 'in_progress' && e.mock_exams?.exam_date && new Date(e.mock_exams.exam_date) > new Date())
        .map((e) => ({
          id: e.mock_exams.id,
          title: e.mock_exams.title,
          examDate: e.mock_exams.exam_date,
          durationMinutes: e.mock_exams.duration_minutes,
        }));

      if (cancelled) return;

      setData({
        userName: me?.name || 'Scholar',
        batchId,
        batchCode: (batch as any)?.batch_code || '',
        score: scoreRow?.score ?? null,
        components: (scoreRow?.components_json as Record<string, number | null>) ?? {},
        streak: streakRow?.current_streak ?? 0,
        articlesCount: articlesCount ?? 0,
        examsTakenCount,
        recentArticles: (articles || []).map((a: any) => ({
          id: a.id,
          title: a.title,
          tag: (a.tags && a.tags[0]) || 'GENERAL',
          authorName: a.users?.name || 'Unknown',
          authorRole: a.users?.role_label || '',
        })),
        upcomingExams,
        senior: lineage?.users
          ? { name: (lineage.users as any).name, quote: lineage.senior_quote }
          : null,
        leaderboard: (leaderboardRows || []).map((r: any) => ({
          userId: r.user_id,
          name: r.users?.name || 'Student',
          score: r.score,
          isYou: r.user_id === user.id,
        })),
        recentCompanies: (companies || []).map((c: any) => ({
          id: c.id,
          name: c.name,
          role: Array.isArray(c.roles_offered) ? c.roles_offered[0] || '' : (c.roles_offered || ''),
          visitDate: c.visit_date,
        })),
      });
      setLoading(false);
    }

    load();
    return () => { cancelled = true; };
  }, []);

  const handleAiAsk = async () => {
    if (!aiQuery.trim()) return;
    setIsAiLoading(true);
    try {
      const res = await fetch('/api/ai-senior', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ query: aiQuery }) });
      const resData = await res.json();
      setAiResponse(resData.success ? resData.answer : 'Sorry, I encountered an error. Please try again.');
    } catch {
      setAiResponse('Connection failed. Please try again.');
    } finally {
      setIsAiLoading(false);
    }
  };

  const getBand = (score: number) => {
    if (score >= 80) return { label: 'STRONG', color: 'bg-electric-blue text-white' };
    if (score >= 60) return { label: 'BUILDING', color: 'bg-illus-gold text-white' };
    if (score >= 40) return { label: 'NEEDS ATTENTION', color: 'bg-primary-purple text-white' };
    return { label: 'AT RISK', color: 'bg-deep-violet text-white' };
  };

  if (loading) {
    return (
      <div className="max-w-[1400px] mx-auto space-y-8 pb-8 animate-pulse">
        <div className="h-10 w-72 bg-border-light rounded-lg" />
        <div className="h-64 bg-white border border-border-light rounded-[24px]" />
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          {[0, 1, 2, 3].map((i) => <div key={i} className="h-[140px] bg-white border border-border-light rounded-[20px]" />)}
        </div>
      </div>
    );
  }

  const readinessScore = data?.score ?? 0;
  const band = getBand(readinessScore);
  const componentEntries = Object.entries(data?.components || {}).filter(([, v]) => v !== null) as [string, number][];

  return (
    <div className="max-w-[1400px] mx-auto space-y-8 pb-8">

      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <motion.h1 initial={{ opacity: 0, y: -10 }} animate={{ opacity: 1, y: 0 }} className="text-[26px] font-bold text-text-main tracking-tight mb-1">
            Welcome back, {data?.userName?.split(' ')[0] || 'Scholar'} 👋
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
              <span className="text-[44px] font-black text-text-main leading-none">{Math.round(readinessScore)}</span>
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
            {componentEntries.length === 0 && (
              <p className="text-[13px] text-text-muted">No score components yet — this fills in once your Daily Five, LeetCode, attendance, and task activity starts syncing.</p>
            )}
            {componentEntries.map(([key, value], i) => (
              <motion.div key={key} initial={{ opacity: 0, x: -20 }} animate={{ opacity: 1, x: 0 }} transition={{ delay: 0.1 + i * 0.1 }}>
                <div className="flex justify-between items-center mb-1.5">
                  <span className="text-[13px] font-semibold text-text-muted">{COMPONENT_LABELS[key] || key}</span>
                  <span className="text-[13px] font-black text-text-main">{Math.round(value)}%</span>
                </div>
                <div className="h-2 bg-border-light rounded-full overflow-hidden">
                  <motion.div
                    initial={{ width: 0 }}
                    animate={{ width: `${Math.min(value, 100)}%` }}
                    transition={{ delay: 0.3 + i * 0.1, duration: 0.8, ease: 'easeOut' }}
                    className="h-full rounded-full bg-primary-purple"
                  />
                </div>
              </motion.div>
            ))}
          </div>
        </div>
      </motion.div>

      {/* 4 Stat Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <StatCard title="Readiness Score" value={Math.round(readinessScore)} trend={band.label} icon={Award} color="bg-primary-purple" delay={0.1} />
        <StatCard title="Current Streak" value={data?.streak ?? 0} trend="Days via Flutter App" icon={Flame} color="bg-deep-violet" delay={0.2} />
        <StatCard title="Exams Taken" value={data?.examsTakenCount ?? 0} trend="Lifetime" icon={ClipboardList} color="bg-illus-gold" delay={0.3} />
        <StatCard title="Articles Approved" value={data?.articlesCount ?? 0} trend="Across the Knowledge Brain" icon={BookOpen} color="bg-electric-blue" delay={0.4} />
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
              <span className="text-[13px] font-bold text-primary-purple">{data?.upcomingExams.length ?? 0} Scheduled</span>
            </div>
            <div className="p-6 space-y-4">
              {(data?.upcomingExams.length ?? 0) === 0 && (
                <p className="text-[13px] text-text-muted text-center py-4">No exams scheduled right now — check back soon.</p>
              )}
              {data?.upcomingExams.map((exam) => {
                const daysLeft = Math.max(0, Math.ceil((new Date(exam.examDate).getTime() - Date.now()) / 86400000));
                return (
                  <div key={exam.id} className="flex items-center justify-between p-4 rounded-[16px] border border-border-light hover:border-primary-purple/30 transition-colors group">
                    <div className="flex items-center gap-4">
                      <div className="w-12 h-12 rounded-[12px] bg-page-bg flex flex-col items-center justify-center shrink-0">
                        <span className="text-[16px] font-black text-primary-purple leading-none">{daysLeft}</span>
                        <span className="text-[8px] font-bold text-text-muted uppercase">days</span>
                      </div>
                      <div>
                        <h4 className="text-[14px] font-bold text-text-main mb-0.5">{exam.title}</h4>
                        <p className="text-[11px] font-semibold text-text-muted">{new Date(exam.examDate).toLocaleDateString('en-IN', { month: 'short', day: 'numeric', year: 'numeric' })} · {exam.durationMinutes} min</p>
                      </div>
                    </div>
                    <Link href="/student/exams" className="px-4 py-2 bg-primary-purple text-white rounded-[10px] text-[12px] font-bold opacity-0 group-hover:opacity-100 transition-opacity shrink-0">
                      Details →
                    </Link>
                  </div>
                );
              })}
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
              {(data?.recentArticles.length ?? 0) === 0 && (
                <p className="text-[13px] text-text-muted text-center py-4">No approved articles yet — be the first to contribute.</p>
              )}
              {data?.recentArticles.map((article) => (
                <div key={article.id} className="flex items-start gap-4 p-4 rounded-[16px] border border-border-light hover:border-primary-purple/30 transition-colors cursor-pointer group">
                  <div className="w-10 h-10 rounded-[10px] bg-page-bg flex items-center justify-center shrink-0">
                    <FileText className="w-4 h-4 text-primary-purple" />
                  </div>
                  <div className="flex-1">
                    <span className="text-[9px] font-bold text-primary-purple uppercase tracking-wider">{article.tag}</span>
                    <h4 className="text-[14px] font-bold text-text-main mt-0.5 mb-1 group-hover:text-primary-purple transition-colors">{article.title}</h4>
                    <p className="text-[11px] font-semibold text-text-muted">{article.authorRole} · {article.authorName} · Approved ✓</p>
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
            {data?.senior ? (
              <div className="flex flex-col items-center text-center gap-3">
                <InitialsAvatar name={data.senior.name} size={64} className="text-xl shadow-lg" />
                <div>
                  <h4 className="text-[15px] font-black text-text-main">{data.senior.name}</h4>
                </div>
                {data.senior.quote && <p className="text-[12px] text-text-muted text-center">"{data.senior.quote}"</p>}
                <Link href="/student/lineage" className="w-full py-2 bg-page-bg text-primary-purple rounded-[10px] text-[12px] font-bold text-center hover:bg-border-light transition-colors">View Lineage</Link>
              </div>
            ) : (
              <div className="text-center py-4">
                <p className="text-[13px] text-text-muted mb-3">No senior assigned yet.</p>
                <Link href="/student/lineage" className="text-[12px] font-bold text-primary-purple hover:underline">View Lineage Program</Link>
              </div>
            )}
          </div>

          {/* Batch Leaderboard Mini */}
          <div className="bg-white rounded-[20px] border border-border-light shadow-[0_2px_12px_rgba(0,0,0,0.02)] p-6">
            <div className="flex items-center justify-between mb-5">
              <div className="flex items-center gap-2">
                <Star className="w-5 h-5 text-illus-gold" />
                <h3 className="text-[14px] font-bold text-text-main">Batch Leaderboard</h3>
              </div>
              {data?.batchCode && <span className="text-[10px] font-bold text-text-muted bg-page-bg px-2 py-1 rounded-lg">{data.batchCode}</span>}
            </div>
            {(data?.leaderboard.length ?? 0) === 0 ? (
              <p className="text-[13px] text-text-muted text-center py-4">No scores yet in your batch.</p>
            ) : (
              <div className="space-y-3">
                {data?.leaderboard.map((s, i) => (
                  <div key={s.userId} className={`flex items-center gap-3 p-2.5 rounded-[10px] transition-colors ${s.isYou ? 'bg-primary-purple/10 border border-primary-purple/20' : 'hover:bg-page-bg'}`}>
                    <span className={`text-[13px] font-black w-5 text-center ${i < 3 ? 'text-illus-gold' : 'text-text-muted'}`}>{i + 1}</span>
                    <span className={`text-[13px] font-bold flex-1 ${s.isYou ? 'text-primary-purple' : 'text-text-main'}`}>{s.name} {s.isYou && '(You)'}</span>
                    <span className="text-[13px] font-black text-text-main">{Math.round(s.score)}</span>
                  </div>
                ))}
              </div>
            )}
            <p className="text-[10px] text-text-muted mt-3 text-center">Full leaderboard available in Flutter app</p>
          </div>

          {/* Placement Log Teaser */}
          <div className="bg-white rounded-[20px] border border-border-light shadow-[0_2px_12px_rgba(0,0,0,0.02)] p-6">
            <div className="flex items-center gap-2 mb-4">
              <Building2 className="w-5 h-5 text-primary-purple" />
              <h3 className="text-[14px] font-bold text-text-main">Recent Drives</h3>
            </div>
            {(data?.recentCompanies.length ?? 0) === 0 && (
              <p className="text-[13px] text-text-muted">No drives recorded yet.</p>
            )}
            {data?.recentCompanies.map((d) => (
              <div key={d.id} className="flex items-center gap-3 mb-3 last:mb-0">
                <div className="w-8 h-8 rounded-lg bg-page-bg flex items-center justify-center text-[13px] font-black text-primary-purple shrink-0">
                  {d.name[0]}
                </div>
                <div>
                  <p className="text-[13px] font-bold text-text-main">{d.name}</p>
                  <p className="text-[11px] text-text-muted">{d.role} · {new Date(d.visitDate).toLocaleDateString('en-IN', { month: 'short', day: 'numeric', year: 'numeric' })}</p>
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
