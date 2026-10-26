'use client';

import React from 'react';
import {
  BarChart2,
  Users,
  FolderOpen,
  CheckCircle2,
  TrendingUp,
  Loader2,
  Download,
  ShieldCheck,
  Search,
} from 'lucide-react';
import { createClient } from '@/lib/supabase/client';
import { getCurrentProfile } from '@/lib/current-profile';

interface BatchOption {
  id: string;
  batch_code: string;
  status: string;
}

interface Stats {
  activeStudents: number;
  activeProjects: number;
  completedProjects: number;
  avgProgress: number;
  avgReadiness: number | null;
  avgAttendance: number | null;
  leetcodeTotal: number;
  dailyFiveActive: number;
}

interface StudentRow {
  id: string;
  name: string;
  reg_no: string;
  readiness: number | null;
  attendance: number | null;
  dailyFive: number;
}

function escapeCsv(v: unknown) {
  return `"${String(v ?? '').replaceAll('"', '""')}"`;
}

export default function FacultyAnalyticsDashboard() {
  const supabase = React.useMemo(() => createClient(), []);
  const [loading, setLoading] = React.useState(true);
  const [batches, setBatches] = React.useState<BatchOption[]>([]);
  const [selectedBatchId, setSelectedBatchId] = React.useState<string>('');
  const [stats, setStats] = React.useState<Stats | null>(null);
  const [students, setStudents] = React.useState<StudentRow[]>([]);
  const [batchCode, setBatchCode] = React.useState('');
  const [searchFilter, setSearchFilter] = React.useState('');
  const [error, setError] = React.useState('');

  const load = React.useCallback(
    async (targetBatchId?: string) => {
      setLoading(true);
      setError('');
      try {
        const me = await getCurrentProfile(supabase);

        // Fetch all available batches
        const { data: batchList, error: batchErr } = await supabase
          .from('batches')
          .select('id, batch_code, status')
          .order('start_year', { ascending: false });

        if (batchErr) throw batchErr;
        const availableBatches: BatchOption[] = batchList ?? [];
        setBatches(availableBatches);

        if (availableBatches.length === 0) {
          setBatchCode('No active batches');
          setStats({
            activeStudents: 0,
            activeProjects: 0,
            completedProjects: 0,
            avgProgress: 0,
            avgReadiness: null,
            avgAttendance: null,
            leetcodeTotal: 0,
            dailyFiveActive: 0,
          });
          setStudents([]);
          return;
        }

        // Determine which batch to display:
        // 1. Explicit targetBatchId
        // 2. Previously selected batch if still valid
        // 3. User profile batch_id if set and valid
        // 4. Batch marked 'active_senior'
        // 5. Batch marked 'active_junior'
        // 6. First available batch
        let resolvedBatchId =
          targetBatchId ||
          (selectedBatchId && availableBatches.some((b) => b.id === selectedBatchId)
            ? selectedBatchId
            : null);

        if (!resolvedBatchId && me?.batch_id && availableBatches.some((b) => b.id === me.batch_id)) {
          resolvedBatchId = me.batch_id;
        }

        if (!resolvedBatchId) {
          const activeSenior = availableBatches.find((b) => b.status === 'active_senior');
          const activeJunior = availableBatches.find((b) => b.status === 'active_junior');
          resolvedBatchId = (activeSenior || activeJunior || availableBatches[0]).id;
        }

        setSelectedBatchId(resolvedBatchId);

        const currentBatch = availableBatches.find((b) => b.id === resolvedBatchId);
        setBatchCode(currentBatch?.batch_code ?? '');

        const [
          { data: userRows, error: userErr },
          { data: fypRows },
          { data: scoreRows },
          { data: attendanceRows },
          { data: leetRows },
          { data: dailyRows },
        ] = await Promise.all([
          supabase
            .from('users')
            .select('id, name, reg_no, leetcode_username')
            .eq('batch_id', resolvedBatchId)
            .eq('role_label', 'Student')
            .order('reg_no'),
          supabase
            .from('fyp_projects')
            .select('id, status')
            .eq('batch_id', resolvedBatchId),
          supabase.from('current_readiness_scores').select('user_id, score'),
          supabase
            .from('placement_attendance_summary')
            .select('user_id, attendance_pct')
            .eq('batch_id', resolvedBatchId),
          supabase.from('leetcode_stats').select('username, total_solved'),
          supabase
            .from('daily_five_attempts')
            .select('user_id')
            .gte('attempt_date', new Date(Date.now() - 7 * 86400000).toISOString().slice(0, 10)),
        ]);

        if (userErr) throw userErr;

        const scoreMap = new Map((scoreRows ?? []).map((r) => [r.user_id, Number(r.score ?? 0)]));
        const attendanceMap = new Map((attendanceRows ?? []).map((r) => [r.user_id, Number(r.attendance_pct ?? 0)]));
        const leetMap = new Map((leetRows ?? []).map((r) => [r.username.toLowerCase(), Number(r.total_solved ?? 0)]));
        const dailySet = new Set((dailyRows ?? []).map((r) => r.user_id));

        const activeStudents = userRows ?? [];
        const allScores = activeStudents
          .map((u) => scoreMap.get(u.id))
          .filter((value): value is number => value !== undefined && value > 0);
        const allAttendance = activeStudents
          .map((u) => attendanceMap.get(u.id))
          .filter((value): value is number => value !== undefined);

        const avgReadiness = allScores.length
          ? Math.round(allScores.reduce((a, b) => a + b, 0) / allScores.length)
          : null;
        const avgAttendance = allAttendance.length
          ? Math.round(allAttendance.reduce((a, b) => a + b, 0) / allAttendance.length)
          : null;

        const leetcodeTotal = activeStudents.reduce((total, student) => {
          const username = student.leetcode_username?.trim().toLowerCase();
          return total + (username ? leetMap.get(username) ?? 0 : 0);
        }, 0);

        const activeProjects = (fypRows ?? []).filter((f) =>
          ['active', 'registered', 'in_progress', 'proposal'].includes(f.status ?? '')
        ).length;
        const completedProjects = (fypRows ?? []).filter((f) => f.status === 'completed').length;
        const totalProjects = (fypRows ?? []).length;
        const avgProgress = totalProjects > 0 ? Math.round((completedProjects / totalProjects) * 100) : 0;
        const dailyFiveActive = activeStudents.filter((u) => dailySet.has(u.id)).length;

        setStats({
          activeStudents: activeStudents.length,
          activeProjects,
          completedProjects,
          avgProgress,
          avgReadiness,
          avgAttendance,
          leetcodeTotal,
          dailyFiveActive,
        });

        setStudents(
          activeStudents.map((u) => ({
            id: u.id,
            name: u.name || '—',
            reg_no: u.reg_no || '—',
            readiness: scoreMap.get(u.id) ?? null,
            attendance: attendanceMap.get(u.id) ?? null,
            dailyFive: dailySet.has(u.id) ? 1 : 0,
          }))
        );
      } catch (cause) {
        setError(cause instanceof Error ? cause.message : 'Analytics could not be loaded.');
      } finally {
        setLoading(false);
      }
    },
    [supabase, selectedBatchId]
  );

  React.useEffect(() => {
    void load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  function handleBatchChange(newBatchId: string) {
    setSelectedBatchId(newBatchId);
    void load(newBatchId);
  }

  function exportCsv() {
    const csv = [
      ['reg_no', 'name', 'readiness_score', 'attendance_pct', 'daily_five_this_week'],
      ...students.map((s) => [
        s.reg_no,
        s.name,
        s.readiness?.toFixed(0) ?? '',
        s.attendance?.toFixed(0) ?? '',
        s.dailyFive,
      ]),
    ]
      .map((r) => r.map(escapeCsv).join(','))
      .join('\n');
    const url = URL.createObjectURL(new Blob([csv], { type: 'text/csv' }));
    const a = document.createElement('a');
    a.href = url;
    a.download = `psgmx-analytics-${batchCode || 'batch'}-${new Date().toISOString().slice(0, 10)}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  }

  const filteredStudents = React.useMemo(() => {
    if (!searchFilter.trim()) return students;
    const query = searchFilter.toLowerCase();
    return students.filter(
      (s) => s.name.toLowerCase().includes(query) || s.reg_no.toLowerCase().includes(query)
    );
  }, [students, searchFilter]);

  if (loading && !stats) {
    return (
      <div className="flex min-h-64 items-center justify-center">
        <Loader2 className="h-6 w-6 animate-spin text-primary-purple" />
      </div>
    );
  }

  if (error && !stats) {
    return (
      <div className="rounded-2xl border border-red-200 bg-red-50 p-6 text-sm font-bold text-red-700">
        {error}{' '}
        <button onClick={() => void load()} className="ml-2 underline cursor-pointer">
          Retry
        </button>
      </div>
    );
  }

  const statCards = [
    {
      title: 'Active Students',
      value: stats?.activeStudents ?? 0,
      sub: batchCode ? `Batch ${batchCode}` : 'All students',
      icon: Users,
      color: 'text-primary-purple',
    },
    {
      title: 'FYP Projects Active',
      value: stats?.activeProjects ?? 0,
      sub: `${stats?.completedProjects ?? 0} completed`,
      icon: FolderOpen,
      color: 'text-electric-blue',
    },
    {
      title: 'Avg Readiness Score',
      value: stats?.avgReadiness === null || stats?.avgReadiness === undefined ? '—' : `${stats.avgReadiness}%`,
      sub: 'Students with evidence',
      icon: TrendingUp,
      color: 'text-illus-gold',
    },
    {
      title: 'Avg Attendance',
      value: stats?.avgAttendance === null || stats?.avgAttendance === undefined ? '—' : `${stats.avgAttendance}%`,
      sub: 'Recorded sessions',
      icon: CheckCircle2,
      color: 'text-success',
    },
    {
      title: 'LeetCode Solved',
      value: stats?.leetcodeTotal ?? 0,
      sub: 'Across batch (total)',
      icon: BarChart2,
      color: 'text-primary-purple',
    },
    {
      title: 'Daily Five Active',
      value: stats?.dailyFiveActive ?? 0,
      sub: 'Active this week',
      icon: ShieldCheck,
      color: 'text-success',
    },
  ];

  return (
    <div className="max-w-[1400px] mx-auto space-y-8 pb-8">
      {/* Header with Title and Controls */}
      <div className="flex flex-col items-start gap-4 sm:flex-row sm:items-end sm:justify-between">
        <div>
          <h1 className="text-[26px] font-bold text-text-main tracking-tight mb-0.5">Analytics</h1>
          <p className="text-[14px] text-text-muted">
            Live cohort performance metrics{batchCode ? ` — Batch ${batchCode}` : ''}.
          </p>
        </div>

        <div className="flex flex-wrap items-center gap-3">
          {batches.length > 0 && (
            <div className="flex items-center gap-2">
              <span className="text-xs font-bold text-text-muted hidden sm:inline">Cohort:</span>
              <select
                value={selectedBatchId}
                onChange={(e) => handleBatchChange(e.target.value)}
                className="rounded-xl border border-border-light bg-white px-3.5 py-2.5 text-sm font-bold text-text-main shadow-2xs outline-none transition focus:border-primary-purple cursor-pointer"
              >
                {batches.map((b) => (
                  <option key={b.id} value={b.id}>
                    {b.batch_code} {b.status ? `(${b.status.replace('_', ' ')})` : ''}
                  </option>
                ))}
              </select>
            </div>
          )}

          <button
            onClick={exportCsv}
            disabled={students.length === 0}
            className="flex items-center gap-2 rounded-xl bg-primary-purple px-5 py-2.5 text-sm font-bold text-white hover:bg-deep-violet transition-colors disabled:opacity-50 cursor-pointer shadow-sm"
          >
            <Download className="h-4 w-4" /> Export CSV
          </button>
        </div>
      </div>

      {loading && (
        <div className="flex items-center gap-2 text-xs font-semibold text-text-muted">
          <Loader2 className="h-4 w-4 animate-spin text-primary-purple" /> Updating batch analytics...
        </div>
      )}

      {/* Stat Grid */}
      <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-6">
        {statCards.map((card, i) => (
          <div key={i} className="rounded-2xl border border-border-light bg-white p-5 shadow-xs transition hover:shadow-sm">
            <card.icon className={`h-5 w-5 ${card.color}`} />
            <p className="mt-3 text-2xl font-black text-text-main">{card.value}</p>
            <p className="mt-1 text-xs font-bold text-text-muted">{card.title}</p>
            <p className="text-[10px] text-text-muted capitalize">{card.sub}</p>
          </div>
        ))}
      </div>

      {/* Student Table */}
      <div className="rounded-2xl border border-border-light bg-white shadow-xs overflow-hidden">
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between border-b border-border-light px-6 py-4 gap-3">
          <div>
            <h2 className="font-black text-text-main">
              Student breakdown {batchCode ? `— Batch ${batchCode}` : ''}
            </h2>
            <p className="mt-1 text-xs text-text-muted">
              Readiness score, attendance, and weekly engagement for {students.length} students.
            </p>
          </div>

          <div className="relative w-full sm:w-64">
            <Search className="absolute left-3 top-3 h-4 w-4 text-text-muted" />
            <input
              type="text"
              value={searchFilter}
              onChange={(e) => setSearchFilter(e.target.value)}
              placeholder="Filter by name or reg no..."
              className="w-full rounded-xl border border-border-light bg-page-bg py-2 pl-9 pr-3 text-xs font-medium text-text-main outline-none focus:border-primary-purple"
            />
          </div>
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
              {filteredStudents.map((s) => (
                <tr key={s.id} className="hover:bg-page-bg/50 transition-colors">
                  <td className="px-6 py-3">
                    <p className="font-bold text-text-main">{s.name}</p>
                    <p className="text-xs text-text-muted font-mono">{s.reg_no}</p>
                  </td>
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-2">
                      <div className="h-1.5 w-20 overflow-hidden rounded-full bg-page-bg border border-border-light">
                        <div
                          className="h-full rounded-full bg-primary-purple"
                          style={{ width: `${Math.min(100, Math.max(0, s.readiness ?? 0))}%` }}
                        />
                      </div>
                      <span className="text-xs font-bold">
                        {s.readiness === null ? '—' : `${s.readiness.toFixed(0)}%`}
                      </span>
                    </div>
                  </td>
                  <td className="px-4 py-3 text-xs font-bold text-text-main">
                    {s.attendance === null ? '—' : `${s.attendance.toFixed(0)}%`}
                  </td>
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
              {filteredStudents.length === 0 && (
                <tr>
                  <td colSpan={4} className="px-6 py-10 text-center text-sm text-text-muted">
                    {students.length === 0
                      ? `No students found enrolled in Batch ${batchCode || ''}.`
                      : 'No students match your filter query.'}
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

