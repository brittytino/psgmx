import React from 'react';
import { ShieldCheck, AlertTriangle, Archive, GraduationCap } from 'lucide-react';
import { createClient } from '@/lib/supabase/server';

export const dynamic = 'force-dynamic';

export default async function SuperAdminGovernance() {
  const supabase = await createClient();

  const [
    { count: graduatingStudents },
    { count: pendingArticles },
  ] = await Promise.all([
    // Active seniors are graduating soon
    supabase.from('users').select('id, batches!inner(status)', { count: 'exact', head: true })
      .eq('batches.status', 'active_senior')
      .eq('role', 'student'),
    // Pending articles
    supabase.from('knowledge_brain_articles').select('id', { count: 'exact', head: true })
      .eq('approval_status', 'pending')
  ]);

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-3xl font-bold text-white tracking-tight">Data Governance</h1>
        <p className="text-text-muted mt-2">Monitor system health and pending reviews.</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <div className="bg-black/20 border border-border rounded-2xl p-6">
          <p className="text-sm font-medium text-text-muted uppercase tracking-wider">Health</p>
          <div className="flex items-center gap-4 mt-4">
            <p className="text-4xl font-bold text-white">Good</p>
            <ShieldCheck className="w-8 h-8 text-green-400" />
          </div>
        </div>

        <div className="bg-black/20 border border-border rounded-2xl p-6">
          <p className="text-sm font-medium text-text-muted uppercase tracking-wider">Pending Articles</p>
          <div className="flex items-center gap-4 mt-4">
            <p className="text-4xl font-bold text-white">{pendingArticles ?? 0}</p>
            <AlertTriangle className={`w-8 h-8 ${(pendingArticles ?? 0) > 0 ? 'text-red-400' : 'text-green-400'}`} />
          </div>
        </div>

        <div className="bg-black/20 border border-border rounded-2xl p-6">
          <p className="text-sm font-medium text-text-muted uppercase tracking-wider">Active Teams</p>
          <div className="flex items-center gap-4 mt-4">
            <p className="text-4xl font-bold text-white">Live</p>
            <Archive className="w-8 h-8 text-electric-blue" />
          </div>
        </div>

        <div className="bg-black/20 border border-border rounded-2xl p-6">
          <p className="text-sm font-medium text-text-muted uppercase tracking-wider">Graduating Cohort</p>
          <div className="flex items-center gap-4 mt-4">
            <p className="text-4xl font-bold text-white">{graduatingStudents ?? 0}</p>
            <GraduationCap className="w-8 h-8 text-purple-400" />
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-black/20 border border-border rounded-2xl p-6">
          <h2 className="text-lg font-bold text-white mb-4">Transition Readiness</h2>
          <p className="text-text-muted mb-4">
            The automated Yearly Transition cron job will promote {graduatingStudents ?? 0} students to Alumni status. 
            Ensure all requirements are finalized before June 1st.
          </p>
          <button className="px-4 py-2 bg-electric-blue/20 text-electric-blue rounded-lg font-bold text-sm">
            Simulate Transition Run
          </button>
        </div>

        <div className="bg-black/20 border border-border rounded-2xl p-6">
          <h2 className="text-lg font-bold text-white mb-4">Pending Content Reviews</h2>
          <p className="text-text-muted mb-4">
            There are {pendingArticles ?? 0} knowledge articles waiting for faculty approval. They must be approved before they are embedded into the AI Senior RAG context.
          </p>
        </div>
      </div>
    </div>
  );
}
