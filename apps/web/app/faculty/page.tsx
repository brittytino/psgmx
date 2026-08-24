'use client';

import React from 'react';
import { motion } from 'framer-motion';
import { Users, BookOpen, Target, ClipboardList, FileText, Calendar, ChevronRight, ArrowRight } from 'lucide-react';
import Link from 'next/link';
import { InitialsAvatar } from '@/components/basic/InitialsAvatar';
import { createClient } from '@/lib/supabase/client';

import { AnimatePresence } from 'framer-motion';

interface ReviewItem { id: string; title: string; author: string; time: string }
interface FypCounts { proposal: number; in_progress: number; completed: number; archived: number }
interface TopQuery { title: string; count: number }
interface MentorshipActivity { id: string; action: string; time: string }

export default function FacultyDashboardHome() {
  const [myName, setMyName] = React.useState('');
  const [loading, setLoading] = React.useState(true);
  const [reviewQueue, setReviewQueue] = React.useState<ReviewItem[]>([]);
  const [mentoredCount, setMentoredCount] = React.useState(0);
  const [pendingArticlesCount, setPendingArticlesCount] = React.useState(0);
  const [aiQueriesThisWeek, setAiQueriesThisWeek] = React.useState(0);
  const [pendingFypReviews, setPendingFypReviews] = React.useState(0);
  const [fypCounts, setFypCounts] = React.useState<FypCounts>({ proposal: 0, in_progress: 0, completed: 0, archived: 0 });
  const [topQueries, setTopQueries] = React.useState<TopQuery[]>([]);
  const [mentorshipActivity, setMentorshipActivity] = React.useState<MentorshipActivity[]>([]);
  const [toastMessage, setToastMessage] = React.useState('');

  const supabase = createClient();

  const load = React.useCallback(async () => {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) { setLoading(false); return; }

    const { data: me } = await supabase.from('users').select('name').eq('id', user.id).single();

    const weekAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString();

    const [
      { data: pendingArticles, count: pendingArticlesTotal },
      { count: mentored },
      { data: aiLogsThisWeek },
      { data: fypRows },
      { data: recentFeedback },
    ] = await Promise.all([
      supabase
        .from('knowledge_brain_articles')
        .select('id, title, author_id, created_at, users!knowledge_brain_articles_author_id_fkey(name)', { count: 'exact' })
        .eq('approval_status', 'pending')
        .order('created_at', { ascending: false })
        .limit(10),
      supabase.from('fyp_feedback').select('project_id', { count: 'exact', head: true }).eq('faculty_id', user.id),
      supabase.from('ai_query_logs').select('query_text').gte('created_at', weekAgo).limit(500),
      supabase.from('fyp_projects').select('status'),
      supabase
        .from('fyp_feedback')
        .select('id, comment, created_at, fyp_projects(title, users(name))')
        .eq('faculty_id', user.id)
        .order('created_at', { ascending: false })
        .limit(3),
    ]);

    setMyName(me?.name || 'Faculty');
    setPendingArticlesCount(pendingArticlesTotal ?? 0);
    setMentoredCount(mentored ?? 0);

    setReviewQueue((pendingArticles || []).map((a: any) => ({
      id: a.id,
      title: a.title,
      author: a.users?.name || 'Unknown',
      time: new Date(a.created_at).toLocaleDateString('en-IN', { month: 'short', day: 'numeric' }),
    })));

    const counts: FypCounts = { proposal: 0, in_progress: 0, completed: 0, archived: 0 };
    (fypRows || []).forEach((p: any) => { if (p.status in counts) counts[p.status as keyof FypCounts]++; });
    setFypCounts(counts);
    setPendingFypReviews(counts.proposal + counts.in_progress);

    setAiQueriesThisWeek((aiLogsThisWeek || []).length);
    const freq = new Map<string, number>();
    (aiLogsThisWeek || []).forEach((r: any) => {
      const key = (r.query_text || '').trim().toLowerCase();
      if (!key) return;
      freq.set(key, (freq.get(key) || 0) + 1);
    });
    const top = [...freq.entries()].sort((a, b) => b[1] - a[1]).slice(0, 3);
    setTopQueries(top.map(([title, count]) => ({ title, count })));

    setMentorshipActivity((recentFeedback || []).map((f: any) => ({
      id: f.id,
      action: `Reviewed "${f.fyp_projects?.title || 'a project'}" for ${f.fyp_projects?.users?.name || 'a student'}`,
      time: new Date(f.created_at).toLocaleDateString('en-IN', { month: 'short', day: 'numeric' }),
    })));

    setLoading(false);
  }, [supabase]);

  React.useEffect(() => { load(); }, [load]);

  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(''), 3000);
  };

  const handleReviewAction = async (id: string, action: 'Approve' | 'Reject') => {
    setReviewQueue((prev) => prev.filter((item) => item.id !== id));
    setPendingArticlesCount((c) => Math.max(0, c - 1));
    const { data: { user } } = await supabase.auth.getUser();
    await supabase
      .from('knowledge_brain_articles')
      .update({
        approval_status: action === 'Approve' ? 'approved' : 'rejected',
        reviewed_by: user?.id,
        reviewed_at: new Date().toISOString(),
      })
      .eq('id', id);
    showToast(`Article ${action}d successfully`);
  };

  const today = new Date();
  const fypTotal = fypCounts.proposal + fypCounts.in_progress + fypCounts.completed + fypCounts.archived;
  const pct = (n: number) => (fypTotal > 0 ? Math.round((n / fypTotal) * 100) : 0);

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

  return (
    <div className="max-w-[1400px] mx-auto space-y-8 pb-8 relative">
      <AnimatePresence>
        {toastMessage && (
          <motion.div initial={{ opacity: 0, y: 50 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: 50 }} className="fixed bottom-8 left-1/2 -translate-x-1/2 z-50 bg-rich-black text-white px-6 py-3 rounded-xl shadow-xl flex items-center gap-3">
            <div className="w-2 h-2 rounded-full bg-electric-blue"></div>
            <span className="text-[13px] font-bold">{toastMessage}</span>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Header & Date */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <motion.h1
            initial={{ opacity: 0, y: -10 }}
            animate={{ opacity: 1, y: 0 }}
            className="text-[26px] font-bold text-text-main tracking-tight mb-1"
          >
            Welcome back, {myName} <span className="inline-block animate-wave">👋</span>
          </motion.h1>
          <motion.p
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.1 }}
            className="text-[14px] text-text-muted"
          >
            Here's what's happening in the MCA Department today.
          </motion.p>
        </div>
        <div className="flex items-center gap-3 bg-white border border-border-light rounded-2xl px-5 py-3 shadow-sm shrink-0">
          <Calendar className="w-5 h-5 text-text-muted" />
          <div>
            <p className="text-[13px] font-bold text-text-main">{today.toLocaleDateString('en-IN', { month: 'long', day: 'numeric', year: 'numeric' })}</p>
            <p className="text-[11px] font-semibold text-text-muted">{today.toLocaleDateString('en-IN', { weekday: 'long' })}</p>
          </div>
        </div>
      </div>

      {/* 4 Stat Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.1 }} className="bg-white rounded-[20px] p-6 shadow-[0_2px_12px_rgba(0,0,0,0.03)] border border-border-light flex flex-col justify-between h-[140px]">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-primary-purple flex items-center justify-center shadow-md shadow-primary-purple/10">
              <Users className="w-5 h-5 text-white" />
            </div>
            <p className="text-[12px] font-bold text-text-muted">Mentored Students</p>
          </div>
          <h3 className="text-[32px] font-black text-text-main leading-none mt-auto">{mentoredCount}</h3>
        </motion.div>

        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.2 }} className="bg-white rounded-[20px] p-6 shadow-[0_2px_12px_rgba(0,0,0,0.03)] border border-border-light flex flex-col justify-between h-[140px]">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-primary-purple flex items-center justify-center shadow-md shadow-[#06B6D4]/20">
              <BookOpen className="w-5 h-5 text-white" />
            </div>
            <p className="text-[12px] font-bold text-text-muted">Knowledge Approvals</p>
          </div>
          <h3 className="text-[32px] font-black text-text-main leading-none mt-auto">{pendingArticlesCount}</h3>
        </motion.div>

        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.3 }} className="bg-white rounded-[20px] p-6 shadow-[0_2px_12px_rgba(0,0,0,0.03)] border border-border-light flex flex-col justify-between h-[140px]">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-deep-violet flex items-center justify-center shadow-md shadow-[#F43F5E]/20">
              <Target className="w-5 h-5 text-white" />
            </div>
            <p className="text-[12px] font-bold text-text-muted">AI Queries This Week</p>
          </div>
          <h3 className="text-[32px] font-black text-text-main leading-none mt-auto">{aiQueriesThisWeek}</h3>
        </motion.div>

        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.4 }} className="bg-white rounded-[20px] p-6 shadow-[0_2px_12px_rgba(0,0,0,0.03)] border border-border-light flex flex-col justify-between h-[140px]">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-illus-gold flex items-center justify-center shadow-md shadow-[#F59E0B]/20">
              <ClipboardList className="w-5 h-5 text-white" />
            </div>
            <p className="text-[12px] font-bold text-text-muted">Pending FYP Reviews</p>
          </div>
          <div className="mt-auto">
            <h3 className="text-[32px] font-black text-text-main leading-none mb-1">{pendingFypReviews}</h3>
            <Link href="/faculty/fyp-repository" className="text-[11px] font-bold text-primary-purple hover:underline">View all</Link>
          </div>
        </motion.div>
      </div>

      {/* Row 2: Knowledge Brain Review Queue */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-3 bg-white rounded-[20px] border border-border-light shadow-[0_2px_12px_rgba(0,0,0,0.02)] flex flex-col">
          <div className="p-6 border-b border-[#F8F9FC] flex justify-between items-center">
            <div className="flex items-center gap-2">
              <BookOpen className="w-5 h-5 text-primary-purple" />
              <h3 className="text-[16px] font-bold text-text-main">Knowledge Brain – Review Queue</h3>
            </div>
            <span className="text-[13px] font-bold text-primary-purple">{reviewQueue.length} Pending</span>
          </div>
          <div className="p-6 flex-1 flex flex-col gap-4">
            <AnimatePresence>
              {reviewQueue.length === 0 ? (
                <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="flex-1 flex items-center justify-center text-[13px] font-semibold text-text-muted py-8">
                  All caught up! No pending reviews.
                </motion.div>
              ) : (
                reviewQueue.map((item) => (
                  <motion.div
                    key={item.id}
                    initial={{ opacity: 0, height: 0, scale: 0.95 }}
                    animate={{ opacity: 1, height: 'auto', scale: 1 }}
                    exit={{ opacity: 0, height: 0, scale: 0.95, overflow: 'hidden', padding: 0, margin: 0 }}
                    transition={{ duration: 0.2 }}
                    className="flex items-center justify-between p-4 rounded-[16px] border border-border-light hover:border-border-light transition-colors"
                  >
                    <div className="flex items-center gap-4">
                      <div className="w-12 h-12 rounded-[12px] bg-white/40 backdrop-blur-md border border-white/20 flex items-center justify-center shrink-0">
                        <FileText className="w-5 h-5 text-primary-purple" />
                      </div>
                      <div>
                        <h4 className="text-[14px] font-bold text-text-main mb-0.5">{item.title}</h4>
                        <p className="text-[11px] font-semibold text-text-muted">
                          By {item.author} • {item.time}
                        </p>
                      </div>
                    </div>
                    <div className="flex items-center gap-2 shrink-0">
                      <button onClick={() => handleReviewAction(item.id, 'Approve')} className="px-5 py-2.5 bg-primary-purple text-white rounded-[10px] text-[13px] font-bold hover:bg-[#5B21B6] transition-colors shadow-sm">Approve</button>
                      <button onClick={() => handleReviewAction(item.id, 'Reject')} className="px-5 py-2.5 bg-white border border-border-light text-text-muted rounded-[10px] text-[13px] font-bold hover:bg-page-bg hover:text-text-main transition-colors shadow-sm">Reject</button>
                    </div>
                  </motion.div>
                ))
              )}
            </AnimatePresence>
            <Link href="/faculty/knowledge-brain" className="mt-2 w-full py-3.5 bg-white/40 backdrop-blur-md border border-white/20 text-primary-purple rounded-[12px] text-[13px] font-bold flex items-center justify-center gap-2 hover:bg-page-bg transition-colors">
              View All Pending Articles <ArrowRight className="w-4 h-4" />
            </Link>
          </div>
        </div>
      </div>

      {/* Row 3: FYP Overview, Mentorship Activities, AI Senior Queries */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">

        {/* FYP Overview */}
        <div className="bg-white rounded-[20px] border border-border-light shadow-[0_2px_12px_rgba(0,0,0,0.02)] p-6">
          <div className="flex justify-between items-center mb-8">
            <div className="flex items-center gap-2">
              <ClipboardList className="w-5 h-5 text-primary-purple" />
              <h3 className="text-[16px] font-bold text-text-main">FYP Overview</h3>
            </div>
            <Link href="/faculty/fyp-repository" className="text-[12px] font-bold text-primary-purple flex items-center gap-1">View All <ArrowRight className="w-3.5 h-3.5" /></Link>
          </div>

          {fypTotal === 0 ? (
            <p className="text-[13px] text-text-muted text-center py-8">No FYP projects submitted yet.</p>
          ) : (
            <div className="flex items-center gap-8">
              <div className="relative w-32 h-32 shrink-0">
                <svg viewBox="0 0 36 36" className="w-full h-full -rotate-90">
                  <circle cx="18" cy="18" r="16" fill="none" className="stroke-[#F1F5F9]" strokeWidth="4"></circle>
                  <circle cx="18" cy="18" r="16" fill="none" className="stroke-primary-purple" strokeWidth="4" strokeDasharray={`${pct(fypCounts.in_progress)} 100`} strokeDashoffset="0"></circle>
                  <circle cx="18" cy="18" r="16" fill="none" className="stroke-illus-gold" strokeWidth="4" strokeDasharray={`${pct(fypCounts.proposal)} 100`} strokeDashoffset={`-${pct(fypCounts.in_progress)}`}></circle>
                  <circle cx="18" cy="18" r="16" fill="none" className="stroke-electric-blue" strokeWidth="4" strokeDasharray={`${pct(fypCounts.completed)} 100`} strokeDashoffset={`-${pct(fypCounts.in_progress) + pct(fypCounts.proposal)}`}></circle>
                </svg>
                <div className="absolute inset-0 flex flex-col items-center justify-center">
                  <span className="text-[22px] font-black text-text-main leading-none">{fypTotal}</span>
                  <span className="text-[9px] font-bold text-text-muted uppercase">Total Projects</span>
                </div>
              </div>

              <div className="flex-1 space-y-4">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2"><div className="w-2.5 h-2.5 rounded-full bg-primary-purple"></div><span className="text-[13px] font-bold text-text-main">In Progress</span></div>
                  <div className="text-[13px] text-text-muted font-semibold">{fypCounts.in_progress} ({pct(fypCounts.in_progress)}%)</div>
                </div>
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2"><div className="w-2.5 h-2.5 rounded-full bg-illus-gold"></div><span className="text-[13px] font-bold text-text-main">Proposal</span></div>
                  <div className="text-[13px] text-text-muted font-semibold">{fypCounts.proposal} ({pct(fypCounts.proposal)}%)</div>
                </div>
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2"><div className="w-2.5 h-2.5 rounded-full bg-electric-blue"></div><span className="text-[13px] font-bold text-text-main">Completed</span></div>
                  <div className="text-[13px] text-text-muted font-semibold">{fypCounts.completed} ({pct(fypCounts.completed)}%)</div>
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Recent Mentorship Activities */}
        <div className="bg-white rounded-[20px] border border-border-light shadow-[0_2px_12px_rgba(0,0,0,0.02)] p-6 flex flex-col">
          <div className="flex items-center gap-2 mb-6">
            <Users className="w-5 h-5 text-primary-purple" />
            <h3 className="text-[16px] font-bold text-text-main">Recent Mentorship Activities</h3>
          </div>

          <div className="flex-1 space-y-5">
            {mentorshipActivity.length === 0 && (
              <p className="text-[13px] text-text-muted">No FYP feedback given yet — activity shows up here once you review a project.</p>
            )}
            {mentorshipActivity.map((item) => (
              <div key={item.id} className="flex items-start gap-3">
                <InitialsAvatar name={item.action} size={32} className="border-2 border-white shadow-sm" />
                <div>
                  <p className="text-[13px] font-bold text-text-main leading-snug">{item.action}</p>
                  <p className="text-[11px] font-semibold text-text-muted mt-0.5">{item.time}</p>
                </div>
              </div>
            ))}
          </div>

          <Link href="/faculty/mentorship" className="mt-4 w-full py-3.5 bg-page-bg text-primary-purple rounded-[12px] text-[13px] font-bold flex items-center justify-center gap-2 hover:bg-page-bg transition-colors">
            View All Activities <ArrowRight className="w-4 h-4" />
          </Link>
        </div>

        {/* AI Senior - Top Queries */}
        <div className="bg-white rounded-[20px] border border-border-light shadow-[0_2px_12px_rgba(0,0,0,0.02)] p-6 flex flex-col">
          <div className="flex justify-between items-center mb-6">
            <div className="flex items-center gap-2">
              <Users className="w-5 h-5 text-deep-violet" />
              <h3 className="text-[16px] font-bold text-text-main">AI Senior – Top Queries</h3>
            </div>
            <span className="text-[11px] font-bold text-text-muted border border-border-light px-2 py-1 rounded-lg">This Week</span>
          </div>

          <div className="flex-1 space-y-5">
            {topQueries.length === 0 && <p className="text-[13px] text-text-muted">No AI Senior queries logged this week.</p>}
            {topQueries.map((item, i) => (
              <div key={item.title} className="flex items-start gap-3">
                <div className="w-7 h-7 rounded-full bg-page-bg text-primary-purple text-[12px] font-black flex items-center justify-center shrink-0">
                  {i + 1}
                </div>
                <div>
                  <p className="text-[13px] font-bold text-text-main leading-snug capitalize">{item.title}</p>
                  <p className="text-[11px] font-semibold text-text-muted mt-0.5">{item.count} {item.count === 1 ? 'query' : 'queries'}</p>
                </div>
              </div>
            ))}
          </div>

          <div className="mt-auto pt-4 flex justify-center">
            <Link href="/faculty/ai-insights" className="text-[13px] font-bold text-primary-purple hover:underline flex items-center gap-1.5">
              View All Insights <ChevronRight className="w-4 h-4" />
            </Link>
          </div>
        </div>

      </div>
    </div>
  );
}
