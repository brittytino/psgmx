'use client';

import React from 'react';
import { motion } from 'framer-motion';
import {
  GraduationCap,
  PenLine,
  Users,
  Briefcase,
  BookOpen,
  ArrowRight,
  ToggleLeft,
  ToggleRight,
  Calendar,
  FileText,
  HandHeart,
  Plus,
} from 'lucide-react';
import Link from 'next/link';
import { createClient } from '@/lib/supabase/client';
import { InitialsAvatar } from '@/components/basic/InitialsAvatar';
import { getCurrentProfile } from '@/lib/current-profile';
import { parseBatchFromRegisterNumber } from '@/lib/auth-input';
import { useUI } from '@/components/providers/ui-provider';
import type { Database } from '@/../../supabase/types/database.types';

type CollaborationPost = Database['public']['Tables']['collaboration_posts']['Row'];
interface ArticleRow { id: string; title: string; approval_status: string; view_count: number; created_at: string }
interface ActivityItem { id: string; text: string; time: string; kind: 'pattern' | 'article' | 'announcement' }
interface JuniorInfo { id: string; name: string; regNo: string; batchCode: string }

export default function AlumniDashboard() {
  const supabase = React.useMemo(() => createClient(), []);
  const { showToast } = useUI();
  const [loading, setLoading] = React.useState(true);
  const [name, setName] = React.useState('');
  const [regNo, setRegNo] = React.useState('');
  const [batchCode, setBatchCode] = React.useState('');
  const [startYear, setStartYear] = React.useState<number | null>(null);
  const [endYear, setEndYear] = React.useState<number | null>(null);
  const [company, setCompany] = React.useState<string | null>(null);
  const [role, setRole] = React.useState<string | null>(null);
  const [articles, setArticles] = React.useState<ArticleRow[]>([]);
  const [communityPosts, setCommunityPosts] = React.useState<CollaborationPost[]>([]);
  const [mentorshipActive, setMentorshipActive] = React.useState(false);
  const [junior, setJunior] = React.useState<JuniorInfo | null>(null);
  const [lineageCount, setLineageCount] = React.useState(0);
  const [postsCount, setPostsCount] = React.useState(0);
  const [activityFeed, setActivityFeed] = React.useState<ActivityItem[]>([]);

  const load = React.useCallback(async () => {
    try {
      const me = await getCurrentProfile(supabase);
      if (!me) { setLoading(false); return; }

      setName(me.name || 'Alumnus');
      setRegNo(me.reg_no || '');
      setMentorshipActive(Boolean(me.mentorship_open));
      setCompany(me.current_company ?? null);
      setRole(me.current_role_title ?? null);

      // Dynamic batch parsing from reg_no fallback if batch_id is not set
      const parsed = me.reg_no ? parseBatchFromRegisterNumber(me.reg_no) : null;

      const [
        { data: batch },
        { data: articleRows },
        { data: lineageRows },
        { data: announcements },
        { data: patterns },
        { data: recentCommunityPosts },
        { count: myPostsCount },
      ] = await Promise.all([
        me.batch_id
          ? supabase.from('batches').select('batch_code, start_year, end_year').eq('id', me.batch_id).maybeSingle()
          : Promise.resolve({ data: null }),
        supabase
          .from('knowledge_brain_articles')
          .select('id, title, approval_status, view_count, created_at')
          .eq('author_id', me.id)
          .order('created_at', { ascending: false }),
        supabase
          .from('lineage_map')
          .select('student_id')
          .eq('senior_user_id', me.id),
        supabase
          .from('announcements')
          .select('id, title, created_at')
          .order('created_at', { ascending: false })
          .limit(3),
        supabase
          .from('interview_patterns')
          .select('id, title, created_at')
          .eq('approval_status', 'approved')
          .order('created_at', { ascending: false })
          .limit(3),
        supabase
          .from('collaboration_posts')
          .select('*')
          .eq('is_active', true)
          .order('created_at', { ascending: false })
          .limit(3),
        supabase
          .from('collaboration_posts')
          .select('id', { count: 'exact', head: true })
          .eq('posted_by', me.id),
      ]);

      const typedBatch = batch as { batch_code?: string; start_year?: number; end_year?: number } | null;
      const code = typedBatch?.batch_code || parsed?.code || (me.reg_no ? me.reg_no.slice(0, 4) : 'MCA');
      const sYear = typedBatch?.start_year ?? parsed?.startYear ?? null;
      const eYear = typedBatch?.end_year ?? parsed?.endYear ?? null;

      setBatchCode(code);
      setStartYear(sYear);
      setEndYear(eYear);
      setArticles(articleRows || []);
      setCommunityPosts(recentCommunityPosts || []);
      setPostsCount(myPostsCount ?? 0);

      const juniorIds = (lineageRows ?? []).map((row) => row.student_id);
      setLineageCount(juniorIds.length);

      if (juniorIds.length > 0) {
        const { data: juniorUsers } = await supabase
          .from('users')
          .select('id, name, reg_no')
          .in('id', juniorIds)
          .limit(1);

        const first = juniorUsers?.[0];
        if (first) {
          setJunior({
            id: first.id,
            name: first.name,
            regNo: first.reg_no || '',
            batchCode: first.reg_no ? first.reg_no.slice(0, 4) : '',
          });
        } else {
          setJunior(null);
        }
      } else {
        setJunior(null);
      }

      const feed: ActivityItem[] = [
        ...(patterns || []).map((pattern) => ({
          id: `p-${pattern.id}`,
          text: `Interview Pattern: ${pattern.title}`,
          time: pattern.created_at,
          kind: 'pattern' as const,
        })),
        ...(announcements || []).map((a) => ({
          id: `a-${a.id}`,
          text: `Announcement: ${a.title}`,
          time: a.created_at,
          kind: 'announcement' as const,
        })),
      ].sort((a, b) => new Date(b.time).getTime() - new Date(a.time).getTime()).slice(0, 5);

      setActivityFeed(feed);
    } catch {
      // Graceful error state handling
    } finally {
      setLoading(false);
    }
  }, [supabase]);

  React.useEffect(() => { load(); }, [load]);

  const toggleMentorship = async () => {
    const me = await getCurrentProfile(supabase);
    if (!me) return;
    const next = !mentorshipActive;
    setMentorshipActive(next);
    try {
      const { error } = await supabase.from('users').update({ mentorship_open: next }).eq('id', me.id);
      if (error) throw error;
      showToast(next ? 'Mentorship availability enabled' : 'Mentorship availability paused', 'success');
    } catch {
      showToast('Failed to update mentorship status', 'error');
    }
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

  const duration = startYear ? (startYear <= 2019 ? 3 : 2) : 2;
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
            {batchCode ? `Class of ${batchCode}` : 'MCA Alumni'} · Alumni Network Dashboard
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
          {
            title: 'Alumni Cohort',
            value: batchCode ? `${batchCode}` : 'MCA',
            sub: startYear && endYear ? `${startYear}–${endYear} (${duration}-Yr MCA)` : 'Verified Alumni',
            icon: GraduationCap,
            color: 'bg-primary-purple',
          },
          {
            title: 'Knowledge Articles',
            value: approvedCount.toString(),
            sub: totalViews > 0 ? `${totalViews} total reader views` : 'Guides for students',
            icon: PenLine,
            color: 'bg-electric-blue',
          },
          {
            title: 'Mentorship Status',
            value: mentorshipActive ? 'Available' : 'Paused',
            sub: junior ? `Junior: ${junior.name}` : 'Open to lineage juniors',
            icon: HandHeart,
            color: mentorshipActive ? 'bg-emerald-600' : 'bg-slate-400',
          },
          {
            title: 'Lineage Juniors',
            value: lineageCount.toString(),
            sub: lineageCount > 0 ? `${lineageCount} connected junior${lineageCount === 1 ? '' : 's'}` : 'Department lineage active',
            icon: Users,
            color: 'bg-illus-gold',
          },
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
                <div className="py-8 text-center bg-page-bg/50 rounded-2xl border border-dashed border-border-light p-6">
                  <p className="text-[14px] font-bold text-text-main">Share your industry experience with students</p>
                  <p className="text-[12px] text-text-muted mt-1 max-w-md mx-auto">
                    Help juniors prepare for tech interviews, final year projects, and career roadmaps.
                  </p>
                  <div className="mt-4 flex flex-wrap justify-center gap-2">
                    <Link href="/alumni/contribute" className="px-3 py-1.5 rounded-lg bg-primary-purple/10 text-primary-purple text-xs font-bold hover:bg-primary-purple/20 transition">
                      + Interview Experience
                    </Link>
                    <Link href="/alumni/contribute" className="px-3 py-1.5 rounded-lg bg-electric-blue/10 text-electric-blue text-xs font-bold hover:bg-electric-blue/20 transition">
                      + Tech Roadmap
                    </Link>
                    <Link href="/alumni/knowledge-brain" className="px-3 py-1.5 rounded-lg bg-slate-100 text-slate-700 text-xs font-bold hover:bg-slate-200 transition">
                      Browse Knowledge Brain
                    </Link>
                  </div>
                </div>
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
                    a.approval_status === 'approved' ? 'bg-emerald-50 text-emerald-700' : a.approval_status === 'rejected' ? 'bg-red-50 text-red-700' : 'bg-amber-50 text-amber-700'
                  }`}>{a.approval_status}</span>
                </div>
              ))}
              {articles.length > 0 && (
                <Link href="/alumni/contribute" className="w-full py-3.5 bg-white/40 backdrop-blur-md border border-white/20 text-primary-purple rounded-[12px] text-[13px] font-bold flex items-center justify-center gap-2 hover:bg-page-bg transition-colors">
                  View All Contributions <ArrowRight className="w-4 h-4" />
                </Link>
              )}
            </div>
          </div>

          {/* Community Board Highlights */}
          <div className="bg-white rounded-[20px] border border-border-light shadow-[0_2px_12px_rgba(0,0,0,0.02)] p-6">
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-2">
                <Briefcase className="w-5 h-5 text-primary-purple" />
                <h3 className="text-[16px] font-bold text-text-main">Community Opportunities</h3>
              </div>
              <Link href="/alumni/community-board" className="text-[12px] font-bold text-primary-purple hover:underline">
                View All Posts
              </Link>
            </div>
            {communityPosts.length === 0 ? (
              <div className="rounded-2xl border border-dashed border-border-light p-6 text-center">
                <p className="text-sm font-semibold text-text-muted">No active community posts right now.</p>
                <Link href="/alumni/community-board" className="mt-2 inline-flex items-center gap-1.5 text-xs font-bold text-primary-purple hover:underline">
                  <Plus className="h-3.5 w-3.5" /> Start a project, mentorship circle or share career info
                </Link>
              </div>
            ) : (
              <div className="space-y-3">
                {communityPosts.map((post) => (
                  <div key={post.id} className="p-4 rounded-2xl border border-border-light bg-page-bg/40 flex items-start justify-between gap-4">
                    <div>
                      <span className="inline-block rounded-md bg-violet-100 px-2 py-0.5 text-[10px] font-black uppercase text-primary-purple">
                        {post.post_type.replaceAll('_', ' ')}
                      </span>
                      <h4 className="mt-1.5 text-sm font-bold text-text-main">{post.title}</h4>
                      <p className="mt-1 text-xs text-text-muted line-clamp-2">{post.description}</p>
                    </div>
                    <span className="text-[10px] font-semibold text-text-muted shrink-0">
                      {new Date(post.created_at).toLocaleDateString('en-IN', { month: 'short', day: 'numeric' })}
                    </span>
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* Department Activity Feed */}
          <div className="bg-white rounded-[20px] border border-border-light shadow-[0_2px_12px_rgba(0,0,0,0.02)] p-6">
            <h3 className="text-[16px] font-bold text-text-main mb-5">Department Activity</h3>
            {activityFeed.length === 0 ? (
              <p className="text-[13px] text-text-muted">No recent department activity.</p>
            ) : (
              <div className="space-y-4">
                {activityFeed.map((a) => {
                  const Icon = a.kind === 'pattern' ? Briefcase : a.kind === 'article' ? BookOpen : GraduationCap;
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
              <HandHeart className="w-5 h-5 text-primary-purple" />
              <h3 className="text-[14px] font-bold text-text-main">Lineage Mentorship</h3>
            </div>
            <div className="flex items-center justify-between p-4 bg-page-bg rounded-xl mb-4">
              <span className="text-[13px] font-bold text-text-main">Available for Mentorship</span>
              <button onClick={toggleMentorship} aria-label="Toggle mentorship availability" className="transition-transform active:scale-95 cursor-pointer">
                {mentorshipActive
                  ? <ToggleRight className="w-9 h-9 text-emerald-600" />
                  : <ToggleLeft className="w-9 h-9 text-border-light" />}
              </button>
            </div>
            {mentorshipActive && junior && (
              <motion.div initial={{ opacity: 0, y: -5 }} animate={{ opacity: 1, y: 0 }} className="p-4 bg-emerald-50/60 border border-emerald-200/60 rounded-xl">
                <p className="text-[12px] font-bold text-emerald-800 mb-2">Connected Lineage Junior</p>
                <div className="flex items-center gap-3">
                  <InitialsAvatar name={junior.name} size={40} />
                  <div>
                    <p className="text-[13px] font-bold text-text-main">{junior.name}</p>
                    <p className="text-[11px] text-text-muted">{junior.regNo} · Active Student</p>
                  </div>
                </div>
                <Link href="/alumni/lineage" className="mt-3 flex items-center gap-1.5 text-[12px] font-bold text-primary-purple hover:underline">
                  View Full Lineage Tree <ArrowRight className="w-3.5 h-3.5" />
                </Link>
              </motion.div>
            )}
            {mentorshipActive && !junior && (
              <p className="text-[12px] text-text-muted">Mentorship is enabled. Juniors matching your register suffix are linked when cohorts onboard.</p>
            )}
            {!mentorshipActive && (
              <p className="text-[12px] text-text-muted">Turn on mentorship to guide students from the same department lineage.</p>
            )}
          </div>

          {/* Alumni Legacy & Cohort Summary */}
          <div className="bg-white rounded-[20px] border border-border-light shadow-[0_2px_12px_rgba(0,0,0,0.02)] p-6">
            <div className="flex items-center gap-2 mb-4">
              <GraduationCap className="w-5 h-5 text-primary-purple" />
              <h3 className="text-[14px] font-bold text-text-main">Department Legacy</h3>
            </div>
            <div className="p-4 rounded-2xl bg-page-bg space-y-2.5 mb-4">
              <div className="flex justify-between text-[12px]">
                <span className="text-text-muted">Register Number</span>
                <span className="font-bold text-text-main">{regNo || '—'}</span>
              </div>
              <div className="flex justify-between text-[12px]">
                <span className="text-text-muted">Admission Batch</span>
                <span className="font-bold text-text-main">{batchCode || 'MCA'}</span>
              </div>
              <div className="flex justify-between text-[12px]">
                <span className="text-text-muted">Curriculum</span>
                <span className="font-bold text-text-main">{startYear && endYear ? `${startYear}–${endYear} (${duration}-Yr)` : 'Graduated'}</span>
              </div>
              {(company || role) && (
                <div className="flex justify-between text-[12px] pt-1 border-t border-border-light/60">
                  <span className="text-text-muted">Current Role</span>
                  <span className="font-bold text-text-main text-right truncate max-w-[160px]">{[role, company].filter(Boolean).join(' · ')}</span>
                </div>
              )}
            </div>
            <div className="space-y-2">
              <Link href="/alumni/journey" className="w-full py-2.5 bg-primary-purple/10 text-primary-purple rounded-xl text-[13px] font-bold flex items-center justify-center gap-2 hover:bg-primary-purple/20 transition-colors">
                View Alumni Journey <ArrowRight className="w-4 h-4" />
              </Link>
              <Link href="/alumni/settings" className="w-full py-2.5 bg-page-bg text-text-muted rounded-xl text-[12px] font-bold flex items-center justify-center gap-2 hover:bg-border-light hover:text-text-main transition-colors">
                Edit Professional Profile
              </Link>
            </div>
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
            <p className="text-[11px] text-text-muted mt-3 text-center">Projects · Mentorship · Learning events · Unofficial career advice</p>
            <p className="mt-2 text-center text-[10px] font-semibold text-amber-700">Official placement drives remain in NEO PAT.</p>
          </div>
        </div>
      </div>
    </div>
  );
}
