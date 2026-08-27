'use client';

import React from 'react';
import { motion } from 'framer-motion';
import { Users, TrendingUp, AlertTriangle, Download, CalendarClock } from 'lucide-react';
import { createClient } from '@/lib/supabase/client';
import { getCurrentProfile } from '@/lib/current-profile';

interface CommandCenterData {
  batchCode: string;
  totalStudents: number;
  bandCounts: { strong: number; building: number; needs_attention: number; at_risk: number };
  avgAttendance: number | null;
  flaggedAttempts: number;
  upcomingSessions: number;
}

function bandFor(score: number) {
  if (score >= 80) return 'strong';
  if (score >= 60) return 'building';
  if (score >= 40) return 'needs_attention';
  return 'at_risk';
}

export default function CommandCenterPage() {
  const [data, setData] = React.useState<CommandCenterData | null>(null);
  const [loading, setLoading] = React.useState(true);
  const [exporting, setExporting] = React.useState(false);

  React.useEffect(() => {
    let cancelled = false;
    const supabase = createClient();

    async function load() {
      const me = await getCurrentProfile(supabase);
      const batchId = me?.batch_id;
      if (!batchId) { setLoading(false); return; }

      const [{ data: batch }, { data: batchUsers }, { data: attendanceRows }, { data: flagged }, { data: sessions }] = await Promise.all([
        supabase.from('batches').select('batch_code').eq('id', batchId).single(),
        supabase.from('users').select('id').eq('batch_id', batchId).eq('role_label', 'Student'),
        supabase.from('placement_attendance_summary').select('attendance_pct').eq('batch_id', batchId),
        supabase.from('mock_exam_results').select('id, mock_exams!inner(batch_id)').eq('mock_exams.batch_id', batchId).neq('proctoring_flags', '[]'),
        supabase.from('placement_sessions').select('id').eq('batch_id', batchId).gte('session_datetime', new Date().toISOString()),
      ]);

      const studentIds = (batchUsers || []).map((u) => u.id);
      const { data: scoreRows } = studentIds.length > 0
        ? await supabase.from('current_readiness_scores').select('user_id, score').in('user_id', studentIds)
        : { data: [] as { user_id: string; score: number }[] };

      const bandCounts = { strong: 0, building: 0, needs_attention: 0, at_risk: 0 };
      (scoreRows || []).forEach((s) => {
        bandCounts[bandFor(s.score) as keyof typeof bandCounts]++;
      });

      const avgAttendance = (attendanceRows && attendanceRows.length > 0)
        ? attendanceRows.reduce((acc: number, r: any) => acc + (r.attendance_pct || 0), 0) / attendanceRows.length
        : null;

      if (cancelled) return;
      setData({
        batchCode: (batch as any)?.batch_code || '',
        totalStudents: (batchUsers || []).length,
        bandCounts,
        avgAttendance,
        flaggedAttempts: (flagged || []).length,
        upcomingSessions: (sessions || []).length,
      });
      setLoading(false);
    }

    load();
    return () => { cancelled = true; };
  }, []);

  const handleExportCsv = async () => {
    setExporting(true);
    try {
      const supabase = createClient();
      const me = await getCurrentProfile(supabase);
      if (!me?.batch_id) return;
      const { data: rows } = await supabase
        .from('users')
        .select('id, reg_no, name, email')
        .eq('batch_id', me.batch_id)
        .eq('role_label', 'Student');

      const ids = (rows || []).map((r) => r.id);
      const { data: scores } = ids.length > 0
        ? await supabase.from('current_readiness_scores').select('user_id, score').in('user_id', ids)
        : { data: [] as { user_id: string; score: number }[] };
      const scoreMap = new Map((scores || []).map((s) => [s.user_id, s.score]));

      const csvRows = (rows || []).map((r) => [r.reg_no, r.name, r.email, scoreMap.get(r.id) ?? ''].join(','));
      const csv = ['reg_no,name,email,readiness_score', ...csvRows].join('\n');
      const blob = new Blob([csv], { type: 'text/csv' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `batch-readiness-${new Date().toISOString().slice(0, 10)}.csv`;
      a.click();
      URL.revokeObjectURL(url);
    } finally {
      setExporting(false);
    }
  };

  if (loading) {
    return <div className="space-y-6 animate-pulse">{[0, 1, 2].map((i) => <div key={i} className="h-32 bg-white border border-border-light rounded-2xl" />)}</div>;
  }

  if (!data) {
    return <p className="text-text-muted">No batch assignment found for this account.</p>;
  }

  const bandTotal = data.bandCounts.strong + data.bandCounts.building + data.bandCounts.needs_attention + data.bandCounts.at_risk;

  return (
    <div className="space-y-8 max-w-6xl">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-[24px] font-black text-text-main">Command Center</h1>
          <p className="text-[13px] text-text-muted mt-1">Batch {data.batchCode} · {data.totalStudents} students</p>
        </div>
        <button
          onClick={handleExportCsv}
          disabled={exporting}
          className="flex items-center gap-2 px-5 py-2.5 bg-primary-purple text-white rounded-xl text-[13px] font-bold hover:bg-deep-violet transition-colors disabled:opacity-50"
        >
          <Download className="w-4 h-4" /> {exporting ? 'Exporting…' : 'Export CSV'}
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} className="bg-white rounded-2xl border border-border-light p-6">
          <div className="flex items-center gap-2 mb-4"><Users className="w-5 h-5 text-primary-purple" /><h3 className="text-[14px] font-bold">Batch Size</h3></div>
          <p className="text-[32px] font-black text-text-main">{data.totalStudents}</p>
        </motion.div>
        <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.05 }} className="bg-white rounded-2xl border border-border-light p-6">
          <div className="flex items-center gap-2 mb-4"><TrendingUp className="w-5 h-5 text-electric-blue" /><h3 className="text-[14px] font-bold">Avg. Attendance</h3></div>
          <p className="text-[32px] font-black text-text-main">{data.avgAttendance !== null ? `${Math.round(data.avgAttendance)}%` : '—'}</p>
        </motion.div>
        <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.1 }} className="bg-white rounded-2xl border border-border-light p-6">
          <div className="flex items-center gap-2 mb-4"><AlertTriangle className="w-5 h-5 text-illus-gold" /><h3 className="text-[14px] font-bold">Flagged Exam Attempts</h3></div>
          <p className="text-[32px] font-black text-text-main">{data.flaggedAttempts}</p>
        </motion.div>
      </div>

      <div className="bg-white rounded-2xl border border-border-light p-6">
        <h3 className="text-[16px] font-bold text-text-main mb-5">Readiness Distribution</h3>
        {bandTotal === 0 ? (
          <p className="text-[13px] text-text-muted">No readiness scores computed yet for this batch.</p>
        ) : (
          <div className="space-y-4">
            {([
              ['strong', 'Strong', 'bg-electric-blue'],
              ['building', 'Building', 'bg-illus-gold'],
              ['needs_attention', 'Needs Attention', 'bg-primary-purple'],
              ['at_risk', 'At Risk', 'bg-deep-violet'],
            ] as const).map(([key, label, color]) => {
              const count = data.bandCounts[key];
              const pct = bandTotal > 0 ? (count / bandTotal) * 100 : 0;
              return (
                <div key={key}>
                  <div className="flex justify-between text-[13px] font-semibold mb-1.5">
                    <span className="text-text-muted">{label}</span>
                    <span className="text-text-main font-black">{count}</span>
                  </div>
                  <div className="h-2 bg-border-light rounded-full overflow-hidden">
                    <div className={`h-full rounded-full ${color}`} style={{ width: `${pct}%` }} />
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>

      <div className="bg-white rounded-2xl border border-border-light p-6 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <CalendarClock className="w-5 h-5 text-primary-purple" />
          <div>
            <h3 className="text-[14px] font-bold text-text-main">Upcoming Sessions</h3>
            <p className="text-[12px] text-text-muted">Scheduled for this batch</p>
          </div>
        </div>
        <span className="text-[24px] font-black text-text-main">{data.upcomingSessions}</span>
      </div>
    </div>
  );
}
