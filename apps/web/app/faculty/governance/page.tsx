import React from 'react';
import { createClient } from '@/lib/supabase/server';
import { AlertCircle } from 'lucide-react';
import FacultyGovernanceClient from './FacultyGovernanceClient';

export const dynamic = 'force-dynamic';

export default async function FacultyGovernance() {
  const supabase = await createClient();

  // Fetch pending articles
  const { data: pendingDocs } = await supabase
    .from('knowledge_brain_articles')
    .select('id, title, author_id, created_at')
    .eq('approval_status', 'pending')
    .order('created_at', { ascending: true });

  const articles = (pendingDocs || []).map((doc: any) => ({
    _id: doc.id,
    title: doc.title,
    authorToken: doc.author_id,
    freshnessScore: 0, // Placeholder
    lastReviewedAt: doc.created_at,
  }));

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-white tracking-tight">Knowledge Moderation</h1>
        <p className="text-text-muted mt-2">Review pending knowledge base articles submitted by students.</p>
      </div>

      <div className="bg-orange-500/10 border border-orange-500/20 rounded-xl p-4 flex gap-4 items-start">
        <AlertCircle className="w-6 h-6 text-orange-400 shrink-0 mt-1" />
        <div>
          <h3 className="font-bold text-orange-400">Action Required</h3>
          <p className="text-orange-200/80 text-sm mt-1">
            Articles listed below require your approval. Only approved articles are embedded into the AI Senior context.
          </p>
        </div>
      </div>

      <FacultyGovernanceClient initialArticles={articles} />
    </div>
  );
}
