import { ShieldCheck, AlertTriangle, GraduationCap, Users } from 'lucide-react';
import { createClient } from '@/lib/supabase/server';

export const dynamic = 'force-dynamic';

export default async function FacultyGovernancePage() {
  const supabase = await createClient();

  const [
    { count: graduatingStudents },
    { count: pendingArticles },
    { count: totalStudents },
  ] = await Promise.all([
    supabase.from('users').select('id, batches!inner(status)', { count: 'exact', head: true })
      .eq('batches.status', 'active_senior')
      .eq('role_label', 'Student'),
    supabase.from('knowledge_brain_articles').select('id', { count: 'exact', head: true })
      .eq('approval_status', 'pending'),
    supabase.from('users').select('id', { count: 'exact', head: true }).eq('role_label', 'Student'),
  ]);

  return (
    <div className="max-w-[1400px] mx-auto space-y-8 pb-8">
      <div>
        <h1 className="text-[26px] font-bold text-text-main tracking-tight mb-1">Governance</h1>
        <p className="text-[14px] text-text-muted">Department-wide health and pending reviews. HOD-only.</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <div className="bg-white rounded-[20px] border border-border-light p-6">
          <p className="text-[12px] font-bold text-text-muted uppercase tracking-wider">Total Students</p>
          <div className="flex items-center gap-4 mt-4">
            <p className="text-[32px] font-black text-text-main">{totalStudents ?? 0}</p>
            <Users className="w-7 h-7 text-primary-purple" />
          </div>
        </div>

        <div className="bg-white rounded-[20px] border border-border-light p-6">
          <p className="text-[12px] font-bold text-text-muted uppercase tracking-wider">Pending Articles</p>
          <div className="flex items-center gap-4 mt-4">
            <p className="text-[32px] font-black text-text-main">{pendingArticles ?? 0}</p>
            <AlertTriangle className={`w-7 h-7 ${(pendingArticles ?? 0) > 0 ? 'text-illus-gold' : 'text-electric-blue'}`} />
          </div>
        </div>

        <div className="bg-white rounded-[20px] border border-border-light p-6">
          <p className="text-[12px] font-bold text-text-muted uppercase tracking-wider">System Health</p>
          <div className="flex items-center gap-4 mt-4">
            <p className="text-[32px] font-black text-text-main">Good</p>
            <ShieldCheck className="w-7 h-7 text-electric-blue" />
          </div>
        </div>

        <div className="bg-white rounded-[20px] border border-border-light p-6">
          <p className="text-[12px] font-bold text-text-muted uppercase tracking-wider">Graduating Cohort</p>
          <div className="flex items-center gap-4 mt-4">
            <p className="text-[32px] font-black text-text-main">{graduatingStudents ?? 0}</p>
            <GraduationCap className="w-7 h-7 text-deep-violet" />
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white rounded-[20px] border border-border-light p-6">
          <h2 className="text-[16px] font-bold text-text-main mb-4">Batch Graduation</h2>
          <p className="text-[13px] text-text-muted leading-relaxed">
            {graduatingStudents ?? 0} students are in the active-senior batch. Run the <code className="bg-page-bg px-1.5 py-0.5 rounded text-[12px]">batch-graduation</code> Edge Function
            in staging to dry-run promoting them to alumni before doing this against production (plan Section 13/14).
          </p>
        </div>

        <div className="bg-white rounded-[20px] border border-border-light p-6">
          <h2 className="text-[16px] font-bold text-text-main mb-4">Pending Content Reviews</h2>
          <p className="text-[13px] text-text-muted leading-relaxed">
            {pendingArticles ?? 0} knowledge articles are waiting for approval. They only enter the AI Senior RAG context
            once approved from the Knowledge Brain review queue.
          </p>
        </div>
      </div>
    </div>
  );
}
