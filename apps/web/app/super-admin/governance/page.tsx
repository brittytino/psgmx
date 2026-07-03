import React from 'react';
import { ShieldCheck, AlertTriangle, Archive, GraduationCap } from 'lucide-react';
import connectDB from '@/lib/mongodb';
import UserAccount from '@/models/UserAccount';
import KnowledgeBrainArticle from '@/models/KnowledgeBrainArticle';
import FYPRepository from '@/models/FYPRepository';

export const dynamic = 'force-dynamic';

export default async function SuperAdminGovernance() {
  await connectDB();
  const currentYear = new Date().getFullYear();

  const [
    graduatingStudents,
    staleArticles,
    archivedProjects
  ] = await Promise.all([
    UserAccount.countDocuments({ role: 'student', batchEndYear: currentYear, accountType: 'student' }),
    KnowledgeBrainArticle.countDocuments({ status: 'needs_review', archived: false }),
    FYPRepository.countDocuments({ status: 'Archived' })
  ]);

  const averageFreshnessResult = await KnowledgeBrainArticle.aggregate([
    { $match: { archived: false } },
    { $group: { _id: null, avgScore: { $avg: '$freshnessScore' } } }
  ]);
  
  const averageFreshness = averageFreshnessResult[0]?.avgScore || 0;

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-3xl font-bold text-white tracking-tight">Data Governance</h1>
        <p className="text-text-muted mt-2">Monitor data decay and academic lifecycle transitions.</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <div className="bg-black/20 border border-border rounded-2xl p-6">
          <p className="text-sm font-medium text-text-muted uppercase tracking-wider">Avg Freshness</p>
          <div className="flex items-center gap-4 mt-4">
            <p className="text-4xl font-bold text-white">{Math.round(averageFreshness)}%</p>
            <ShieldCheck className={`w-8 h-8 ${averageFreshness > 70 ? 'text-green-400' : 'text-yellow-400'}`} />
          </div>
        </div>

        <div className="bg-black/20 border border-border rounded-2xl p-6">
          <p className="text-sm font-medium text-text-muted uppercase tracking-wider">Stale Articles</p>
          <div className="flex items-center gap-4 mt-4">
            <p className="text-4xl font-bold text-white">{staleArticles}</p>
            <AlertTriangle className={`w-8 h-8 ${staleArticles > 0 ? 'text-red-400' : 'text-green-400'}`} />
          </div>
        </div>

        <div className="bg-black/20 border border-border rounded-2xl p-6">
          <p className="text-sm font-medium text-text-muted uppercase tracking-wider">Archived FYPs</p>
          <div className="flex items-center gap-4 mt-4">
            <p className="text-4xl font-bold text-white">{archivedProjects}</p>
            <Archive className="w-8 h-8 text-electric-blue" />
          </div>
        </div>

        <div className="bg-black/20 border border-border rounded-2xl p-6">
          <p className="text-sm font-medium text-text-muted uppercase tracking-wider">Graduating Cohort</p>
          <div className="flex items-center gap-4 mt-4">
            <p className="text-4xl font-bold text-white">{graduatingStudents}</p>
            <GraduationCap className="w-8 h-8 text-purple-400" />
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-black/20 border border-border rounded-2xl p-6">
          <h2 className="text-lg font-bold text-white mb-4">Transition Readiness</h2>
          <p className="text-text-muted mb-4">
            The automated Yearly Transition cron job will promote {graduatingStudents} students to Alumni status. 
            Ensure all final grades and FYPs are finalized before June 1st.
          </p>
          <button className="px-4 py-2 bg-electric-blue/20 text-electric-blue rounded-lg font-bold text-sm">
            Simulate Transition Run
          </button>
        </div>

        <div className="bg-black/20 border border-border rounded-2xl p-6">
          <h2 className="text-lg font-bold text-white mb-4">Knowledge Decay Monitor</h2>
          <p className="text-text-muted mb-4">
            {staleArticles} articles have a freshness score below 30%. Faculty must revalidate these articles or they will be automatically archived next month to protect the AI Senior context window.
          </p>
          <button className="px-4 py-2 bg-purple-500/20 text-purple-400 rounded-lg font-bold text-sm">
            Ping Faculty
          </button>
        </div>
      </div>
    </div>
  );
}
