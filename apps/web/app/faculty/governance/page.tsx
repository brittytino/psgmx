import React from 'react';
import connectDB from '@/lib/mongodb';
import KnowledgeBrainArticle from '@/models/KnowledgeBrainArticle';
import { AlertCircle } from 'lucide-react';
import FacultyGovernanceClient from './FacultyGovernanceClient';

export const dynamic = 'force-dynamic';

export default async function FacultyGovernance() {
  await connectDB();

  // Fetch articles that are stale or need review
  const staleDocs = await KnowledgeBrainArticle.find({ 
    archived: false,
    status: 'needs_review'
  }).sort({ freshnessScore: 1 }).lean();

  const articles = staleDocs.map((doc: any) => ({
    _id: doc._id.toString(),
    title: doc.title,
    authorToken: doc.authorToken,
    freshnessScore: doc.freshnessScore,
    lastReviewedAt: doc.lastReviewedAt ? doc.lastReviewedAt.toISOString() : null,
  }));

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-white tracking-tight">Knowledge Revalidation</h1>
        <p className="text-text-muted mt-2">Review stale department knowledge to maintain AI accuracy.</p>
      </div>

      <div className="bg-orange-500/10 border border-orange-500/20 rounded-xl p-4 flex gap-4 items-start">
        <AlertCircle className="w-6 h-6 text-orange-400 shrink-0 mt-1" />
        <div>
          <h3 className="font-bold text-orange-400">Action Required</h3>
          <p className="text-orange-200/80 text-sm mt-1">
            Articles listed below have degraded in freshness. If not revalidated, they will be archived and hidden from the AI Context Window.
          </p>
        </div>
      </div>

      <FacultyGovernanceClient initialArticles={articles} />
    </div>
  );
}
