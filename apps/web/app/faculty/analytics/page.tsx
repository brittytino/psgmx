'use client';

import React from 'react';
import { BarChart2, Users, FolderOpen, CheckCircle2, TrendingUp, Loader2, Download, ShieldCheck } from 'lucide-react';
import { createClient } from '@/lib/supabase/client';
import { getCurrentProfile } from '@/lib/current-profile';

interface Stats {
  activeStudents: number;
  activeProjects: number;
  completedProjects: number;
  avgProgress: number;
  avgReadiness: number;
  avgAttendance: number;
  leetcodeTotal: number;
  dailyFiveActive: number;
}

interface StudentRow {
  id: string;
  name: string;
  reg_no: string;
  readiness: number;
  attendance: number;
  dailyFive: number;
}

function escapeCsv(v: unknown) {
  return `"${String(v ?? '').replaceAll('"', '""')}"`
}

export default function FacultyAnalyticsDashboard() {
  const supabase = React.useMemo(() => createClient(), []);
  const [loading, setLoading] = React.useState(true);
  const [stats, setStats] = React.useState<Stats | null>(null);
  const [students, setStudents] = React.useState<StudentRow[]>([]);
  const [batchCode, setBatchCode] = React.useState('');
  const [error, setError] = React.useState('');

  const load = React.useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const me = await getCurrentProfile(supabase);
      if (!me?.batch_id) throw new Error('Faculty profile or batch could not be found.');

      const batchId = me.batch_id;

      const [
        { data: batchRow },
        { data: userRows },
        { data: fypRows },
        { data: scoreRows },
        { data: attendanceRows },
        { data: leetRows },
        { data: dailyRows },
      ] = await Promise.all([
        supabase.from('batches').select('batch_code').eq('id', batchId).single(),
        supabase.from('users').select('id, name, reg_no').eq('batch_id', batchId).eq('role_label', 'Student').order('reg_no'),
        (supabase as any).from('fyp_registrations').select('id, status').eq('batch_id', batchId),
        supabase.from('current_readiness_scores').select('user_id, score'),
        supabase.from('placement_attendance_summary').select('user_id, attendance_pct').eq('batch_id', batchId),
        (supabase as any).from('leetcode_stats').select('user_id, total_solved'),
        supabase.from('daily_five_attempts').select('user_id').gte('attempt_date', new Date(Date.now() - 7 * 86400000).toISOString().slice(0, 10)),
      ]);

      setBatchCode((batchRow as any)?.batch_code ?? '');

      const scoreMap = new Map((scoreRows ?? []).map((r) => [r.user_id, Number(r.score ?? 0)]));
      const attendanceMap = new Map((attendanceRows ?? []).map((r) => [r.user_id, Number(r.attendance_pct ?? 0)]));
      const leetMap = new Map((leetRows ?? []).map((r: any) => [r.user_id, Number(r.total_solved ?? 0)]));
      const dailySet = new Set((dailyRows ?? []).map((r) => r.user_id));

      const activeStudents = userRows ?? [];
      const allScores = activeStudents.map((u) => scoreMap.get(u.id) ?? 0);
      const allAttendance = activeStudents.map((u) => attendanceMap.get(u.id) ?? 0);
      const avgReadiness = allScores.length ? Math.round(allScores.reduce((a, b) => a + b, 0) / allScores.length) : 0;
      const avgAttendance = allAttendance.length ? Math.round(allAttendance.reduce((a, b) => a + b, 0) / allAttendance.length) : 0;
      const leetcodeTotal = (leetRows ?? []).reduce((acc: number, r: any) => acc + Number(r.total_solved ?? 0), 0);
      const activeProjects = (fypRows ?? []).filter((f: any) => ['active', 'registered'].includes(f.status ?? '')).length;
      const completedProjects = (fypRows ?? []).filter((f: any) => f.status === 'completed').length;
      const avgProgress = (fypRows ?? []).length > 0 ? Math.round(((completedProjects / (fypRows ?? []).length) * 100)) : 0;
      const dailyFiveActive = activeStudents.filter((u) => dailySet.has(u.id)).length;

      setStats({ activeStudents: activeStudents.length, activeProjects, completedProjects, avgProgress, avgReadiness, avgAttendance, leetcodeTotal, dailyFiveActive });

      setStudents(activeStudents.map((u) => ({
        id: u.id, name: u.name || '—', reg_no: u.reg_no || '—',
        readiness: scoreMap.get(u.id) ?? 0,
        attendance: attendanceMap.get(u.id) ?? 0,
        dailyFive: dailySet.has(u.id) ? 1 : 0,
      })));
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : 'Analytics could not be loaded.');
    } finally {
      setLoading(false);
    }
  }, [supabase]);

  React.useEffect(() => { void load(); }, [load]);

  function exportCsv() {
    const csv = [
      ['reg_no', 'name', 'readiness_score', 'attendance_pct', 'daily_five_this_week'],
      ...students.map((s) => [s.reg_no, s.name, s.readiness.toFixed(0), s.attendance.toFixed(0), s.dailyFive]),
    ].map((r) => r.map(escapeCsv).join(',')).join('\n');
    const url = URL.createObjectURL(new Blob([csv], { type: 'text/csv' }));
    const a = document.createElement('a'); a.href = url;
    a.download = `psgmx-analytics-${batchCode}-${new Date().toISOString().slice(0, 10)}.csv`;
    a.click(); URL.revokeObjectURL(url);
  }

  if (loading) {
    return (
      <div className="flex min-h-64 items-center justify-center">
        <Loader2 className="h-6 w-6 animate-spin text-primary-purple" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="rounded-2xl border border-red-200 bg-red-50 p-6 text-sm font-bold text-red-700">
        {error} <button onClick={() => void load()} className="ml-2 underline">Retry</button>
      </div>
    );
  }

  if (!stats) return null;

  const statCards = [
    { title: 'Active Students', value: stats.activeStudents, sub: batchCode, icon: Users, color: 'text-primary-purple' },
    { title: 'FYP Projects Active', value: stats.activeProjects, sub: `${stats.completedProjects} completed`, icon: FolderOpen, color: 'text-electric-blue' },
    { title: 'Avg Readiness Score', value: `${stats.avgReadiness}%`, sub: 'Current batch average', icon: TrendingUp, color: 'text-illus-gold' },
    { title: 'Avg Attendance', value: `${stats.avgAttendance}%`, sub: 'Preparation sessions', icon: CheckCircle2, color: 'text-success' },
    { title: 'LeetCode Solved', value: stats.leetcodeTotal, sub: 'Across batch (total)', icon: BarChart2, color: 'text-primary-purple' },
    { title: 'Daily Five Active', value: stats.dailyFiveActive, sub: 'Students active this week', icon: ShieldCheck, color: 'text-success' },
  ];

  return (
    <div className="max-w-[1400px] mx-auto space-y-8 pb-8">
      <div className="flex items-end justify-between">
        <div>
          <h1 className="text-[26px] font-bold text-text-main tracking-tight mb-0.5">Analytics</h1>
          <p className="text-[14px] text-text-muted">
            Live data from your batch{batchCode ? ` — ${batchCode}` : ''}. All figures are real-time from the database.
          </p>
        </div>
        <button
          onClick={exportCsv}
          className="flex items-center gap-2 rounded-xl bg-primary-purple px-5 py-3 text-sm font-bold text-white hover:bg-deep-violet transition-colors"
        >
          <Download className="h-4 w-4" /> Export CSV
        </button>
      </div>

      {/* Stat Grid */}
      <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-6">
        {statCards.map((card, i) => (
          <div key={i} className="rounded-2xl border border-border-light bg-white p-5 shadow-sm">
            <card.icon className={`h-5 w-5 ${card.color}`} />
            <p className="mt-3 text-2xl font-black text-text-main">{card.value}</p>
            <p className="mt-1 text-xs font-bold text-text-muted">{card.title}</p>
            <p className="text-[10px] text-text-muted">{card.sub}</p>
          </div>
        ))}
      </div>

      {/* Student Table */}
      <div className="rounded-2xl border border-border-light bg-white shadow-sm">
        <div className="border-b border-border-light px-6 py-4">
          <h2 className="font-black text-text-main">Student breakdown — {batchCode}</h2>
          <p className="mt-1 text-xs text-text-muted">Readiness score and attendance for each rostered student.</p>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full min-w-[600px] text-sm text-left">
            <thead className="bg-page-bg text-xs font-black uppercase tracking-wider text-text-muted">
              <tr>
                <th className="px-6 py-3">Student</th>
                <th className="px-4 py-3">Readiness</th>
                <th className="px-4 py-3">Attendance</th>
                <th className="px-4 py-3">Daily 5 (week)</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border-light">
              {students.map((s) => (
                <tr key={s.id} className="hover:bg-page-bg/50 transition-colors">
                  <td className="px-6 py-3">
                    <p className="font-bold text-text-main">{s.name}</p>
                    <p className="text-xs text-text-muted font-mono">{s.reg_no}</p>
                  </td>
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-2">
                      <div className="h-1.5 w-20 overflow-hidden rounded-full bg-page-bg">
                        <div className="h-full rounded-full bg-primary-purple" style={{ width: `${s.readiness}%` }} />
                      </div>
                      <span className="text-xs font-bold">{s.readiness.toFixed(0)}%</span>
                    </div>
                  </td>
                  <td className="px-4 py-3 text-xs font-bold text-text-main">{s.attendance.toFixed(0)}%</td>
                  <td className="px-4 py-3">
                    {s.dailyFive ? (
                      <span className="inline-flex items-center gap-1 rounded-full bg-emerald-50 px-2 py-0.5 text-[10px] font-black text-emerald-700 border border-emerald-200">
                        ✓ Active
                      </span>
                    ) : (
                      <span className="text-xs text-text-muted">—</span>
                    )}
                  </td>
                </tr>
              ))}
              {students.length === 0 && (
                <tr>
                  <td colSpan={4} className="px-6 py-10 text-center text-sm text-text-muted">
                    No students found for this batch.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
