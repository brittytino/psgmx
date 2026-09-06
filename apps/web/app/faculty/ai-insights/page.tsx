'use client';

import React from 'react';
import { BrainCircuit, MessageSquare, Users, TrendingUp, Loader2, BookOpen, Clock } from 'lucide-react';
import { createClient } from '@/lib/supabase/client';
import { getCurrentProfile } from '@/lib/current-profile';

interface AIStats {
  totalConversations: number;
  uniqueStudents: number;
  knowledgeArticles: number;
  pendingReviews: number;
}

interface RecentArticle {
  id: string;
  title: string;
  author_name: string;
  approval_status: string;
  view_count: number;
  created_at: string;
}

interface TopQuestion {
  id: string;
  query_text: string;
  asked_count: number;
  topic_tag: string | null;
}

export default function FacultyAIInsightsDashboard() {
  const supabase = React.useMemo(() => createClient(), []);
  const [loading, setLoading] = React.useState(true);
  const [stats, setStats] = React.useState<AIStats | null>(null);
  const [recentArticles, setRecentArticles] = React.useState<RecentArticle[]>([]);
  const [topQuestions, setTopQuestions] = React.useState<TopQuestion[]>([]);
  const [batchCode, setBatchCode] = React.useState('');
  const [error, setError] = React.useState('');

  const load = React.useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const me = await getCurrentProfile(supabase);
      if (!me) throw new Error('Faculty profile could not be loaded.');

      const [
        { data: batchRow },
        { count: conversationCount },
        { data: articleRows, count: articleCount },
        { count: pendingCount },
        { data: questionRows },
      ] = await Promise.all([
        me.batch_id ? supabase.from('batches').select('batch_code').eq('id', me.batch_id).single() : Promise.resolve({ data: null }),
        (supabase as any).from('ai_conversations').select('*', { count: 'exact', head: true }).gte('created_at', new Date(Date.now() - 30 * 86400000).toISOString()),
        supabase.from('knowledge_brain_articles').select('id, title, approval_status, view_count, created_at, users!inner(name)', { count: 'exact' }).order('created_at', { ascending: false }).limit(5),
        supabase.from('knowledge_brain_articles').select('*', { count: 'exact', head: true }).eq('approval_status', 'pending'),
        (supabase as any).from('ai_senior_common_queries').select('id, query_text, asked_count, topic_tag').order('asked_count', { ascending: false }).limit(5),
      ]);

      setBatchCode((batchRow as any)?.batch_code ?? '');

      // Count unique students from conversations
      const { count: uniqueStudentCount } = await (supabase as any)
        .from('ai_conversations')
        .select('student_id', { count: 'exact', head: true })
        .gte('created_at', new Date(Date.now() - 30 * 86400000).toISOString());

      setStats({
        totalConversations: conversationCount ?? 0,
        uniqueStudents: uniqueStudentCount ?? 0,
        knowledgeArticles: articleCount ?? 0,
        pendingReviews: pendingCount ?? 0,
      });

      setRecentArticles(
        (articleRows ?? []).map((row) => ({
          id: row.id,
          title: row.title,
          author_name: (row as any).users?.name ?? 'Unknown',
          approval_status: row.approval_status,
          view_count: row.view_count ?? 0,
          created_at: row.created_at,
        }))
      );

      setTopQuestions((questionRows ?? []) as TopQuestion[]);
    } catch {
      // If ai_conversations or ai_senior_common_queries tables don't exist yet,
      // fall back to knowledge brain stats only
      try {
        const me = await getCurrentProfile(supabase);
        const [
          { data: batchRow },
          { data: articleRows, count: articleCount },
          { count: pendingCount },
        ] = await Promise.all([
          me?.batch_id ? supabase.from('batches').select('batch_code').eq('id', me.batch_id).single() : Promise.resolve({ data: null }),
          supabase.from('knowledge_brain_articles').select('id, title, approval_status, view_count, created_at, users!inner(name)', { count: 'exact' }).order('created_at', { ascending: false }).limit(5),
          supabase.from('knowledge_brain_articles').select('*', { count: 'exact', head: true }).eq('approval_status', 'pending'),
        ]);

        setBatchCode((batchRow as any)?.batch_code ?? '');
        setStats({ totalConversations: 0, uniqueStudents: 0, knowledgeArticles: articleCount ?? 0, pendingReviews: pendingCount ?? 0 });
        setRecentArticles(
          (articleRows ?? []).map((row) => ({
            id: row.id, title: row.title, author_name: (row as any).users?.name ?? 'Unknown',
            approval_status: row.approval_status, view_count: row.view_count ?? 0, created_at: row.created_at,
          }))
        );
      } catch (fallbackCause) {
        setError(fallbackCause instanceof Error ? fallbackCause.message : 'AI insights could not be loaded.');
      }
    } finally {
      setLoading(false);
    }
  }, [supabase]);

  React.useEffect(() => { void load(); }, [load]);

  if (loading) {
    return <div className="flex min-h-64 items-center justify-center"><Loader2 className="h-6 w-6 animate-spin text-primary-purple" /></div>;
  }

  if (error) {
    return <div className="rounded-2xl border border-red-200 bg-red-50 p-6 text-sm font-bold text-red-700">{error} <button onClick={() => void load()} className="underline ml-2">Retry</button></div>;
  }

  const statCards = [
    { title: 'AI Conversations (30d)', value: stats?.totalConversations ?? 0, icon: MessageSquare, note: 'Last 30 days' },
    { title: 'Unique Students (30d)', value: stats?.uniqueStudents ?? 0, icon: Users, note: 'Engaged with AI Senior' },
    { title: 'Knowledge Articles', value: stats?.knowledgeArticles ?? 0, icon: BookOpen, note: 'Total in Knowledge Brain' },
    { title: 'Pending Faculty Review', value: stats?.pendingReviews ?? 0, icon: Clock, note: 'Alumni contributions waiting' },
  ];

  return (
    <div className="max-w-[1400px] mx-auto space-y-8 pb-8">
      <div className="flex items-start gap-4">
        <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl bg-primary-purple shadow-sm">
          <BrainCircuit className="h-6 w-6 text-white" />
        </div>
        <div>
          <h1 className="text-[26px] font-bold text-text-main tracking-tight">AI Senior Insights</h1>
          <p className="text-[14px] text-text-muted">
            Live usage statistics from the AI Senior and Knowledge Brain{batchCode ? ` — ${batchCode}` : ''}.
          </p>
        </div>
      </div>

      {/* Stat Cards */}
      <div className="grid grid-cols-2 gap-4 lg:grid-cols-4">
        {statCards.map((card, i) => (
          <div key={i} className="rounded-2xl border border-border-light bg-white p-5 shadow-sm">
            <card.icon className="h-5 w-5 text-primary-purple" />
            <p className="mt-3 text-3xl font-black text-text-main">{card.value}</p>
            <p className="mt-1 text-xs font-bold text-text-muted">{card.title}</p>
            <p className="text-[10px] text-text-muted">{card.note}</p>
          </div>
        ))}
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        {/* Recent Knowledge Articles */}
        <div className="rounded-2xl border border-border-light bg-white shadow-sm">
          <div className="border-b border-border-light px-6 py-4">
            <h2 className="flex items-center gap-2 font-black text-text-main">
              <BookOpen className="h-4 w-4 text-primary-purple" /> Recent Knowledge Contributions
            </h2>
            <p className="mt-1 text-xs text-text-muted">Latest alumni submissions to the Knowledge Brain.</p>
          </div>
          <div className="divide-y divide-border-light">
            {recentArticles.length === 0 && (
              <p className="px-6 py-8 text-center text-sm text-text-muted">No articles submitted yet.</p>
            )}
            {recentArticles.map((article) => (
              <div key={article.id} className="flex items-start justify-between gap-3 px-6 py-4">
                <div>
                  <p className="text-sm font-bold text-text-main">{article.title}</p>
                  <p className="mt-0.5 text-xs text-text-muted">by {article.author_name} · {new Date(article.created_at).toLocaleDateString('en-IN', { dateStyle: 'medium' })}</p>
                </div>
                <span className={`shrink-0 rounded-full px-2 py-0.5 text-[10px] font-black uppercase ${
                  article.approval_status === 'approved' ? 'bg-emerald-50 text-emerald-700 border border-emerald-200' :
                  article.approval_status === 'rejected' ? 'bg-red-50 text-red-700 border border-red-200' :
                  'bg-amber-50 text-amber-700 border border-amber-200'
                }`}>
                  {article.approval_status}
                </span>
              </div>
            ))}
          </div>
        </div>

        {/* Top AI Questions */}
        <div className="rounded-2xl border border-border-light bg-white shadow-sm">
          <div className="border-b border-border-light px-6 py-4">
            <h2 className="flex items-center gap-2 font-black text-text-main">
              <TrendingUp className="h-4 w-4 text-primary-purple" /> Top Student AI Queries
            </h2>
            <p className="mt-1 text-xs text-text-muted">
              {topQuestions.length > 0 ? 'Most frequently asked questions to AI Senior.' : 'Query analytics will appear once the ai_senior_common_queries view is populated.'}
            </p>
          </div>
          <div className="divide-y divide-border-light">
            {topQuestions.length === 0 && (
              <p className="px-6 py-8 text-center text-sm text-text-muted">No query analytics yet. Students need to use the AI Senior first.</p>
            )}
            {topQuestions.map((q, i) => (
              <div key={q.id} className="flex items-start gap-4 px-6 py-4">
                <span className="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-violet-50 text-xs font-black text-primary-purple">{i + 1}</span>
                <div>
                  <p className="text-sm font-bold text-text-main">{q.query_text}</p>
                  <p className="mt-0.5 text-xs text-text-muted">{q.asked_count} queries{q.topic_tag ? ` · ${q.topic_tag}` : ''}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Guidance note */}
      <div className="rounded-2xl border border-amber-200 bg-amber-50 px-6 py-4 text-sm font-semibold text-amber-900">
        <strong>Note:</strong> AI conversation tracking requires the <code>ai_conversations</code> and <code>ai_senior_common_queries</code> database views. Knowledge Brain statistics are always live. Satisfaction scores are not tracked to protect student privacy.
      </div>
    </div>
  );
}
