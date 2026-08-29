'use client';

import React from 'react';
import { motion } from 'framer-motion';
import { Award, PenLine, Users, Briefcase, BookOpen, ArrowRight, ToggleLeft, ToggleRight, Calendar, FileText } from 'lucide-react';
import Link from 'next/link';
import { createClient } from '@/lib/supabase/client';
import { InitialsAvatar } from '@/components/basic/InitialsAvatar';
import { getCurrentProfile } from '@/lib/current-profile';

interface ArticleRow { id: string; title: string; approval_status: string; view_count: number; created_at: string }
interface ActivityItem { id: string; text: string; time: string; kind: 'pattern' | 'article' | 'announcement' }
interface JuniorInfo { id: string; name: string; batchCode: string }

export default function AlumniDashboard() {
  const supabase = createClient();
  const [loading, setLoading] = React.useState(true);
  const [name, setName] = React.useState('');
  const [batchCode, setBatchCode] = React.useState('');
  const [score, setScore] = React.useState<number | null>(null);
  const [articles, setArticles] = React.useState<ArticleRow[]>([]);
  const [mentorshipActive, setMentorshipActive] = React.useState(false);
  const [junior, setJunior] = React.useState<JuniorInfo | null>(null);
  const [lineageCount, setLineageCount] = React.useState(0);
  const [activityFeed, setActivityFeed] = React.useState<ActivityItem[]>([]);
  const [batchStats, setBatchStats] = React.useState({ bestStreak: 0, leetcodeTotal: 0, examsTaken: 0, gradYear: null as number | null });

  const load = React.useCallback(async () => {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) { setLoading(false); return; }

    const me = await getCurrentProfile(supabase);
    if (!me) { setLoading(false); return; }

    setName(me.name);
    setMentorshipActive(me.mentorship_open);

    const [
      { data: batch },
      { data: scoreRow },
      { data: articleRows },
      { data: lineageRows },
      { data: announcements },
      { data: patterns },
      { data: batchStreaks },
      { data: batchLeetcode },
      { data: batchExamResults },
    ] = await Promise.all([
      me.batch_id ? supabase.from('batches').select('batch_code, end_year').eq('id', me.batch_id).single() : Promise.resolve({ data: null }),
      supabase.from('current_readiness_scores').select('score').eq('user_id', me.id).maybeSingle(),
      supabase.from('knowledge_brain_articles').select('id, title, approval_status, view_count, created_at').eq('author_id', me.id).order('created_at', { ascending: false }),
      supabase.from('lineage_map').select('id, student_id, users!lineage_map_student_id_fkey(name, batch_id)').eq('senior_user_id', me.id),
      supabase.from('announcements').select('id, title, created_at').order('created_at', { ascending: false }).limit(3),
      supabase.from('interview_patterns').select('id,title,created_at').eq('approval_status', 'approved').order('created_at', { ascending: false }).limit(2),
      me.batch_id ? supabase.from('daily_five_streaks').select('longest_streak, user_id, users!inner(batch_id)').eq('users.batch_id', me.batch_id).order('longest_streak', { ascending: false }).limit(1) : Promise.resolve({ data: [] }),
      me.batch_id ? supabase.from('leetcode_stats').select('total_solved, user_id, users!inner(batch_id)').eq('users.batch_id', me.batch_id) : Promise.resolve({ data: [] }),
      me.batch_id ? supabase.from('mock_exam_results').select('id, mock_exams!inner(batch_id)').eq('mock_exams.batch_id', me.batch_id).eq('status', 'submitted') : Promise.resolve({ data: [] }),
    ]);

    setBatchCode((batch as any)?.batch_code || '');
    setScore(scoreRow?.score ?? null);
    setArticles(articleRows || []);
    setLineageCount((lineageRows || []).length);

    const firstJunior = (lineageRows || [])[0] as any;
    setJunior(firstJunior?.users ? { id: firstJunior.student_id, name: firstJunior.users.name, batchCode: '' } : null);

    const feed: ActivityItem[] = [
      ...(patterns || []).map((pattern) => ({ id: `p-${pattern.id}`, text: `Interview pattern published: ${pattern.title}`, time: pattern.created_at, kind: 'pattern' as const })),
      ...(announcements || []).map((a: any) => ({ id: `a-${a.id}`, text: a.title, time: a.created_at, kind: 'announcement' as const })),
    ].sort((a, b) => new Date(b.time).getTime() - new Date(a.time).getTime()).slice(0, 5);
    setActivityFeed(feed);

    setBatchStats({
      bestStreak: (batchStreaks || [])[0]?.longest_streak ?? 0,
      leetcodeTotal: (batchLeetcode || []).reduce((acc: number, r: any) => acc + (r.total_solved || 0), 0),
      examsTaken: (batchExamResults || []).length,
      gradYear: (batch as any)?.end_year ?? null,
    });

    setLoading(false);
  }, [supabase]);

  React.useEffect(() => { load(); }, [load]);

  const toggleMentorship = async () => {
    const me = await getCurrentProfile(supabase);
    if (!me) return;
    const next = !mentorshipActive;
    setMentorshipActive(next);
    await supabase.from('users').update({ mentorship_open: next }).eq('id', me.id);
  };

  if (loading) {
    return (
      <div className="max-w-[1400px] mx-auto space-y-8 pb-8 animate-pulse">
        <div className="h-10 w-96 bg-border-light rounded-lg" />
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          {[0, 1, 2, 3].map((i) => <div key={i} className="h-[140px] bg-white border border-border-light rounded-[20px]" />)}
        </div>
      </div>
    );
  }

  const scoreBand = score === null ? '' : score >= 80 ? 'STRONG' : score >= 60 ? 'BUILDING' : score >= 40 ? 'NEEDS ATTENTION' : 'AT RISK';
  const approvedCount = articles.filter((a) => a.approval_status === 'approved').length;
  const totalViews = articles.reduce((acc, a) => acc + (a.view_count || 0), 0);

  return (
    <div className="max-w-[1400px] mx-auto space-y-8 pb-8">

      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <motion.h1 initial={{ opacity: 0, y: -10 }} animate={{ opacity: 1, y: 0 }} className="text-[26px] font-bold text-text-main tracking-tight mb-1">
            Welcome back, {name.split(' ')[0]} 👋
          </motion.h1>
          <motion.p initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: 0.1 }} className="text-[14px] text-text-muted">
            {batchCode && `Class of ${batchCode} · `}Alumni Dashboard
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

      {/* 4 Stat Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {[
          { title: 'Final Readiness Score', value: score !== null ? Math.round(score).toString() : '—', sub: batchCode ? `Batch ${batchCode} · Graduated` : 'Graduated', icon: Award, color: 'bg-primary-purple' },
          { title: 'Articles Contributed', value: approvedCount.toString(), sub: totalViews > 0 ? `${totalViews} total views` : 'No views yet', icon: PenLine, color: 'bg-electric-blue' },
          { title: 'Mentorship Status', value: mentorshipActive ? 'Active' : 'Off', sub: junior ? `Your junior: ${junior.name}` : 'No junior assigned', icon: Users, color: mentorshipActive ? 'bg-electric-blue' : 'bg-border-light' },
          { title: 'Students in Lineage', value: lineageCount.toString(), sub: lineageCount > 0 ? `${lineageCount} active junior${lineageCount === 1 ? '' : 's'}` : 'None yet', icon: Users, color: 'bg-illus-gold' },
        ].map((c, i) => (
          <motion.div key={i} initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.1 }} className="bg-white rounded-[20px] p-6 shadow-[0_2px_12px_rgba(0,0,0,0.03)] border border-border-light flex flex-col justify-between h-[140px]">
            <div className="flex items-center gap-3">
              <div className={`w-10 h-10 rounded-full ${c.color} flex items-center justify-center shadow-sm`}>
                <c.icon className="w-5 h-5 text-white" />
              </div>
              <p className="text-[12px] font-bold text-text-muted">{c.title}</p>
            </div>
            <div>
              <h3 className="text-[28px] font-black text-text-main leading-none">{c.value}</h3>
              <p className="text-[11px] text-text-muted mt-1">{c.sub}</p>
            </div>
          </motion.div>
        ))}
      </div>

      {/* Main Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">

        {/* Left: 2/3 */}
        <div className="lg:col-span-2 space-y-6">

          {/* Knowledge Contributions */}
          <div className="bg-white rounded-[20px] border border-border-light shadow-[0_2px_12px_rgba(0,0,0,0.02)]">
            <div className="p-6 border-b border-page-bg flex justify-between items-center">
              <div className="flex items-center gap-2">
                <BookOpen className="w-5 h-5 text-primary-purple" />
                <h3 className="text-[16px] font-bold text-text-main">Your Knowledge Contributions</h3>
              </div>
              <Link href="/alumni/contribute" className="flex items-center gap-2 px-4 py-2 bg-primary-purple text-white rounded-xl text-[12px] font-bold hover:bg-deep-violet transition-colors">
                <PenLine className="w-3.5 h-3.5" /> Write Article
              </Link>
            </div>
            <div className="p-6 space-y-3">
              {articles.length === 0 && (
                <p className="text-[13px] text-text-muted text-center py-4">You haven't written any articles yet.</p>
              )}
              {articles.slice(0, 5).map((a) => (
                <div key={a.id} className="flex items-center justify-between p-4 rounded-[16px] border border-border-light hover:border-primary-purple/30 transition-colors">
                  <div className="flex items-center gap-4">
                    <div className="w-10 h-10 rounded-[10px] bg-page-bg flex items-center justify-center shrink-0">
                      <FileText className="w-4 h-4 text-primary-purple" />
                    </div>
                    <div>
                      <h4 className="text-[14px] font-bold text-text-main">{a.title}</h4>
                      <p className="text-[11px] text-text-muted">{new Date(a.created_at).toLocaleDateString('en-IN', { month: 'short', year: 'numeric' })} {a.view_count > 0 && `· ${a.view_count} views`}</p>
                    </div>
                  </div>
                  <span className={`text-[10px] font-bold px-2.5 py-1 rounded-full shrink-0 uppercase ${
                    a.approval_status === 'approved' ? 'bg-electric-blue/10 text-electric-blue' : a.approval_status === 'rejected' ? 'bg-deep-violet/10 text-deep-violet' : 'bg-illus-gold/10 text-illus-gold'
                  }`}>{a.approval_status}</span>
                </div>
              ))}
              <Link href="/alumni/contribute" className="w-full py-3.5 bg-white/40 backdrop-blur-md border border-white/20 text-primary-purple rounded-[12px] text-[13px] font-bold flex items-center justify-center gap-2 hover:bg-page-bg transition-colors">
                View All Contributions <ArrowRight className="w-4 h-4" />
              </Link>
            </div>
          </div>

          {/* Impact Banner — hidden until real citation tracking exists, per plan
              Section 7.3: "a missing feature is honest; a fake number is a
              trust problem." Not building AI-citation tracking in this pass. */}

          {/* Department Activity Feed */}
          <div className="bg-white rounded-[20px] border border-border-light shadow-[0_2px_12px_rgba(0,0,0,0.02)] p-6">
            <h3 className="text-[16px] font-bold text-text-main mb-5">Department Activity</h3>
            {activityFeed.length === 0 ? (
              <p className="text-[13px] text-text-muted">No recent department activity.</p>
            ) : (
              <div className="space-y-4">
                {activityFeed.map((a) => {
                  const Icon = a.kind === 'pattern' ? Briefcase : a.kind === 'article' ? BookOpen : Award;
                  return (
                    <div key={a.id} className="flex items-start gap-3">
                      <div className="w-8 h-8 rounded-full bg-page-bg flex items-center justify-center shrink-0">
                        <Icon className="w-4 h-4 text-primary-purple" />
                      </div>
                      <div>
                        <p className="text-[13px] font-semibold text-text-main">{a.text}</p>
                        <p className="text-[11px] text-text-muted mt-0.5">{new Date(a.time).toLocaleDateString('en-IN', { month: 'short', day: 'numeric' })}</p>
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </div>
        </div>

        {/* Right: 1/3 */}
        <div className="space-y-6">

          {/* Mentorship Toggle Card */}
          <div className="bg-white rounded-[20px] border border-border-light shadow-[0_2px_12px_rgba(0,0,0,0.02)] p-6">
            <div className="flex items-center gap-2 mb-5">
              <Users className="w-5 h-5 text-primary-purple" />
              <h3 className="text-[14px] font-bold text-text-main">Mentorship</h3>
            </div>
            <div className="flex items-center justify-between p-4 bg-page-bg rounded-xl mb-4">
              <span className="text-[13px] font-bold text-text-main">Available for Mentorship</span>
              <button onClick={toggleMentorship} className="transition-transform active:scale-95">
                {mentorshipActive
                  ? <ToggleRight className="w-9 h-9 text-electric-blue" />
                  : <ToggleLeft className="w-9 h-9 text-border-light" />}
              </button>
            </div>
            {mentorshipActive && junior && (
              <motion.div initial={{ opacity: 0, y: -5 }} animate={{ opacity: 1, y: 0 }} className="p-4 bg-electric-blue/5 border border-electric-blue/20 rounded-xl">
                <p className="text-[12px] font-bold text-electric-blue mb-2">Your junior can now see you!</p>
                <div className="flex items-center gap-3">
                  <InitialsAvatar name={junior.name} size={40} />
                  <div>
                    <p className="text-[13px] font-bold text-text-main">{junior.name}</p>
                    <p className="text-[11px] text-text-muted">Active Student</p>
                  </div>
                </div>
                <Link href="/alumni/lineage" className="mt-3 flex items-center gap-1.5 text-[12px] font-bold text-primary-purple hover:underline">
                  View Lineage <ArrowRight className="w-3.5 h-3.5" />
                </Link>
              </motion.div>
            )}
            {mentorshipActive && !junior && (
              <p className="text-[12px] text-text-muted">No junior assigned to you yet — faculty manage lineage assignments.</p>
            )}
          </div>

          {/* Batch Summary */}
          <div className="bg-white rounded-[20px] border border-border-light shadow-[0_2px_12px_rgba(0,0,0,0.02)] p-6">
            <div className="flex items-center gap-2 mb-4">
              <Award className="w-5 h-5 text-primary-purple" />
              <h3 className="text-[14px] font-bold text-text-main">Your Batch Summary</h3>
            </div>
            <div className="text-center mb-4">
              <div className="relative w-20 h-20 mx-auto">
                <svg viewBox="0 0 100 100" className="w-full h-full -rotate-90">
                  <circle cx="50" cy="50" r="44" fill="none" stroke="#EFE9E0" strokeWidth="10" />
                  <circle cx="50" cy="50" r="44" fill="none" stroke="var(--primary-purple)" strokeWidth="10" strokeLinecap="round" strokeDasharray={`${score !== null ? (score / 100) * 276.46 : 0} 276.46`} />
                </svg>
                <div className="absolute inset-0 flex items-center justify-center">
                  <span className="text-[18px] font-black text-text-main">{score !== null ? Math.round(score) : '—'}</span>
                </div>
              </div>
              {scoreBand && <p className="text-[11px] font-bold text-text-muted mt-2 uppercase">Final Readiness · {scoreBand}</p>}
            </div>
            <div className="space-y-2">
              {[
                { label: 'Best Streak (batch)', value: `${batchStats.bestStreak} days` },
                { label: 'LeetCode (batch)', value: `${batchStats.leetcodeTotal} problems` },
                { label: 'Exams taken (batch)', value: `${batchStats.examsTaken} exams` },
                { label: 'Graduated', value: batchStats.gradYear ? String(batchStats.gradYear) : '—' },
              ].map((s, i) => (
                <div key={i} className="flex justify-between text-[12px]">
                  <span className="text-text-muted">{s.label}</span>
                  <span className="font-bold text-text-main">{s.value}</span>
                </div>
              ))}
            </div>
            <Link href="/alumni/journey" className="mt-4 w-full py-2.5 bg-page-bg text-primary-purple rounded-xl text-[13px] font-bold flex items-center justify-center gap-2 hover:bg-border-light transition-colors">
              View Full Journey <ArrowRight className="w-4 h-4" />
            </Link>
          </div>

          {/* Community board quick action */}
          <div className="bg-white rounded-[20px] border border-border-light shadow-[0_2px_12px_rgba(0,0,0,0.02)] p-6">
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-2">
                <Briefcase className="w-5 h-5 text-primary-purple" />
                <h3 className="text-[14px] font-bold text-text-main">Community Board</h3>
              </div>
              <Link href="/alumni/community-board" className="text-[12px] font-bold text-primary-purple hover:underline">View All</Link>
            </div>
            <Link href="/alumni/community-board" className="block w-full py-3 bg-primary-purple text-white rounded-xl text-[13px] font-bold text-center hover:bg-deep-violet transition-colors">
              + Share with the Community
            </Link>
            <p className="text-[11px] text-text-muted mt-3 text-center">Projects · Mentorship · Learning events · Unofficial career information</p>
            <p className="mt-2 text-center text-[10px] font-semibold text-amber-700">Official placement operations remain in NEO PAT.</p>
          </div>
        </div>
      </div>
    </div>
  );
}
