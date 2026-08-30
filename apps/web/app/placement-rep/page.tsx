'use client';

import React from 'react';
import { motion } from 'framer-motion';
import { Users, TrendingUp, AlertTriangle, Download, CalendarClock, Activity } from 'lucide-react';

interface CommandCenterData {
  batchCode: string;
  totalStudents: number;
  activeThisWeekPct: number;
  avgReadinessScore: number | null;
  bandCounts: { strong: number; building: number; needs_attention: number; at_risk: number };
  avgAttendance: number | null;
  flaggedAttempts: number;
  upcomingSessions: number;
  declineSignalCount: number;
  generatedAt: string;
}

export default function CommandCenterPage() {
  const [data, setData] = React.useState<CommandCenterData | null>(null);
  const [loading, setLoading] = React.useState(true);
  const [error, setError] = React.useState('');

  const load = React.useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const response = await fetch('/api/placement-rep/pulse', { cache: 'no-store' });
      const payload = await response.json();
      if (!response.ok) throw new Error(payload.error || 'Could not load the batch pulse.');
      setData(payload);
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : 'Could not load the batch pulse.');
    } finally {
      setLoading(false);
    }
  }, []);

  React.useEffect(() => { void load(); }, [load]);

  const handleExportCsv = () => {
    if (!data) return;
    const rows = [
      ['metric', 'value'],
      ['batch', data.batchCode],
      ['students', data.totalStudents],
      ['active_this_week_pct', data.activeThisWeekPct],
      ['average_readiness', data.avgReadinessScore ?? 'not_measured'],
      ['average_attendance_pct', data.avgAttendance ?? 'not_measured'],
      ['strong_band_count', data.bandCounts.strong],
      ['building_band_count', data.bandCounts.building],
      ['needs_attention_band_count', data.bandCounts.needs_attention],
      ['at_risk_band_count', data.bandCounts.at_risk],
      ['flagged_exam_attempts', data.flaggedAttempts],
      ['upcoming_sessions', data.upcomingSessions],
      ['decline_signals_routed_to_faculty', data.declineSignalCount],
      ['generated_at', data.generatedAt],
    ];
    const csv = rows.map((row) => row.map((value) => `"${String(value).replaceAll('"', '""')}"`).join(',')).join('\n');
    const url = URL.createObjectURL(new Blob([csv], { type: 'text/csv;charset=utf-8' }));
    const anchor = document.createElement('a');
    anchor.href = url;
    anchor.download = `batch-readiness-${data.batchCode}-${new Date().toISOString().slice(0, 10)}.csv`;
    anchor.click();
    URL.revokeObjectURL(url);
  };

  if (loading) return <div className="space-y-6 animate-pulse">{[0, 1, 2].map((i) => <div key={i} className="h-32 bg-white border border-border-light rounded-2xl" />)}</div>;

  if (error || !data) {
    return <div className="rounded-2xl border border-red-200 bg-red-50 p-6 text-sm font-semibold text-red-800">{error || 'No batch assignment was found.'}<button onClick={() => void load()} className="ml-3 underline">Retry</button></div>;
  }

  const bandTotal = Object.values(data.bandCounts).reduce((sum, value) => sum + value, 0);
  const summaries = [
    { label: 'Batch size', value: data.totalStudents, note: `${data.activeThisWeekPct}% active this week`, icon: Users, colour: 'text-primary-purple' },
    { label: 'Average readiness', value: data.avgReadinessScore == null ? '—' : `${data.avgReadinessScore}/100`, note: 'Verified evidence only', icon: Activity, colour: 'text-electric-blue' },
    { label: 'Average attendance', value: data.avgAttendance == null ? '—' : `${Math.round(data.avgAttendance)}%`, note: 'Preparation sessions', icon: TrendingUp, colour: 'text-electric-blue' },
    { label: 'Flagged attempts', value: data.flaggedAttempts, note: 'Review handled by faculty', icon: AlertTriangle, colour: 'text-illus-gold' },
  ];

  return (
    <div className="space-y-8 max-w-6xl">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div><h1 className="text-[24px] font-black text-text-main">Command Center</h1><p className="text-[13px] text-text-muted mt-1">Batch {data.batchCode} · privacy-safe aggregate view</p></div>
        <button onClick={handleExportCsv} className="flex items-center justify-center gap-2 px-5 py-2.5 bg-primary-purple text-white rounded-xl text-[13px] font-bold hover:bg-deep-violet transition-colors"><Download className="w-4 h-4" /> Export aggregate CSV</button>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-5">
        {summaries.map((summary, index) => (
          <motion.div key={summary.label} initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: index * .04 }} className="bg-white rounded-2xl border border-border-light p-6">
            <div className="flex items-center gap-2 mb-4"><summary.icon className={`w-5 h-5 ${summary.colour}`} /><h3 className="text-[13px] font-bold">{summary.label}</h3></div>
            <p className="text-[30px] font-black text-text-main">{summary.value}</p><p className="mt-1 text-[11px] font-semibold text-text-muted">{summary.note}</p>
          </motion.div>
        ))}
      </div>

      <div className="bg-white rounded-2xl border border-border-light p-6">
        <h3 className="text-[16px] font-bold text-text-main mb-2">Readiness distribution</h3>
        <p className="mb-5 text-[12px] text-text-muted">Counts only—individual readiness is visible to the student and authorised faculty, never to a peer representative.</p>
        {bandTotal === 0 ? <p className="text-[13px] text-text-muted">No readiness evidence has been computed for this batch yet.</p> : (
          <div className="space-y-4">
            {([['strong', 'Strong', 'bg-electric-blue'], ['building', 'Building', 'bg-illus-gold'], ['needs_attention', 'Needs attention', 'bg-primary-purple'], ['at_risk', 'At risk', 'bg-deep-violet']] as const).map(([key, label, colour]) => {
              const count = data.bandCounts[key];
              return <div key={key}><div className="flex justify-between text-[13px] font-semibold mb-1.5"><span className="text-text-muted">{label}</span><span className="text-text-main font-black">{count}</span></div><div className="h-2 bg-border-light rounded-full overflow-hidden"><div className={`h-full rounded-full ${colour}`} style={{ width: `${(count / bandTotal) * 100}%` }} /></div></div>;
            })}
          </div>
        )}
      </div>

      <div className="grid gap-5 sm:grid-cols-2">
        <div className="bg-white rounded-2xl border border-border-light p-6 flex items-center justify-between"><div className="flex items-center gap-3"><CalendarClock className="w-5 h-5 text-primary-purple" /><div><h3 className="text-[14px] font-bold text-text-main">Upcoming sessions</h3><p className="text-[12px] text-text-muted">Scheduled for this batch</p></div></div><span className="text-[24px] font-black text-text-main">{data.upcomingSessions}</span></div>
        <div className="bg-white rounded-2xl border border-border-light p-6 flex items-center justify-between"><div className="flex items-center gap-3"><AlertTriangle className="w-5 h-5 text-illus-gold" /><div><h3 className="text-[14px] font-bold text-text-main">Recovery signals</h3><p className="text-[12px] text-text-muted">Automatically routed to faculty</p></div></div><span className="text-[24px] font-black text-text-main">{data.declineSignalCount}</span></div>
      </div>
    </div>
  );
}
