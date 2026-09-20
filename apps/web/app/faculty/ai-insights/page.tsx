'use client';

import React from 'react';
import { BrainCircuit, MessageSquare, Users, Loader2, BookOpen, Clock } from 'lucide-react';

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

export default function FacultyAIInsightsDashboard() {
  const [loading, setLoading] = React.useState(true);
  const [stats, setStats] = React.useState<AIStats | null>(null);
  const [recentArticles, setRecentArticles] = React.useState<RecentArticle[]>([]);
  const [error, setError] = React.useState('');

  const load = React.useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const response = await fetch('/api/insights', { cache: 'no-store' });
      const payload = await response.json();
      if (!response.ok || !payload.ai) throw new Error(payload.error || 'AI insights could not be loaded.');

      setStats({
        totalConversations: payload.ai.conversations30d ?? 0,
        uniqueStudents: payload.ai.uniqueStudents30d ?? 0,
        knowledgeArticles: payload.ai.knowledgeArticles ?? 0,
        pendingReviews: payload.ai.pendingReviews ?? 0,
      });
      setRecentArticles(payload.ai.recentArticles ?? []);
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : 'AI insights could not be loaded.');
    } finally {
      setLoading(false);
    }
  }, []);

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
            Aggregate usage statistics from the AI Senior and Knowledge Brain. Conversation content remains private.
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

      <div className="grid gap-6">
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

      </div>

      {/* Guidance note */}
      <div className="rounded-2xl border border-amber-200 bg-amber-50 px-6 py-4 text-sm font-semibold text-amber-900">
        <strong>Privacy:</strong> This page reports counts only. Student prompts, responses and conversation titles are never shown to staff.
      </div>
    </div>
  );
}
