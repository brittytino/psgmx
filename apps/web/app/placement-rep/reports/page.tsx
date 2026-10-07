'use client'

import React, { useState, useEffect, useMemo, useCallback } from 'react'
import { Download, TrendingUp, Users, Activity, BookOpen, CheckCircle2, Clock } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { getCurrentProfile } from '@/lib/current-profile'

type ReportRow = {
  id: string
  reg_no: string
  name: string
  email: string
  dailyFive: number
  leetcodeTotal: number
}

type AuditRow = {
  id: string
  action: string
  entity_type: string
  created_at: string
  metadata: unknown
}

type BatchOption = {
  id: string
  batch_code: string
}

function escapeCsv(value: unknown) {
  return `"${String(value ?? '').replaceAll('"', '""')}"`
}

function MetricCard({
  icon,
  label,
  value,
  sub,
  color = 'text-violet-600',
}: {
  icon: React.ReactNode
  label: string
  value: string | number
  sub?: string
  color?: string
}) {
  return (
    <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
      <div className={color}>{icon}</div>
      <p className="mt-4 text-3xl font-black text-slate-900">{value}</p>
      <p className="text-sm text-slate-500 mt-1">{label}</p>
      {sub && <p className="text-xs text-slate-400 mt-0.5">{sub}</p>}
    </div>
  )
}

export default function ReportsPage() {
  const supabase = useMemo(() => createClient(), [])
  const [batches, setBatches] = useState<BatchOption[]>([])
  const [selectedBatchId, setSelectedBatchId] = useState<string>('')
  const [myBatchId, setMyBatchId] = useState<string>('')

  const [rows, setRows] = useState<ReportRow[]>([])
  const [audits, setAudits] = useState<AuditRow[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  // 1. Initial Load: Profile & Batches
  useEffect(() => {
    void (async () => {
      try {
        const me = await getCurrentProfile(supabase)
        if (me?.batch_id) setMyBatchId(me.batch_id)

        const { data: batchList } = await supabase
          .from('batches')
          .select('id, batch_code')
          .order('start_year', { ascending: false })

        const loadedBatches = (batchList ?? []) as BatchOption[]
        setBatches(loadedBatches)

        const defaultBatchId = me?.batch_id || loadedBatches[0]?.id || ''
        setSelectedBatchId(defaultBatchId)
      } catch (err) {
        console.warn('Reports profile error:', err)
      }
    })()
  }, [supabase])

  // 2. Load Reports Data for Selected Batch
  const loadBatchReports = useCallback(
    async (batchId: string) => {
      if (!batchId) return
      setLoading(true)
      setError('')

      try {
        // Fetch students in batch
        const { data: users, error: usersErr } = await supabase
          .from('users')
          .select('id,reg_no,name,email,leetcode_username')
          .eq('batch_id', batchId)
          .eq('role_label', 'Student')
          .order('reg_no')

        if (usersErr) throw new Error(usersErr.message)

        const userList = users ?? []
        const userIds = userList.map((u) => u.id)
        const leetcodeUsernames = userList
          .map((u) => u.leetcode_username)
          .filter(Boolean) as string[]

        // Fetch daily five attempts (last 30 days)
        const thirtyDaysAgo = new Date(Date.now() - 30 * 86400000).toISOString().slice(0, 10)
        const attemptCountMap = new Map<string, number>()
        if (userIds.length > 0) {
          const { data: attempts } = await supabase
            .from('daily_five_attempts')
            .select('user_id,attempt_date')
            .in('user_id', userIds)
            .gte('attempt_date', thirtyDaysAgo)
          ;(attempts ?? []).forEach((v) =>
            attemptCountMap.set(v.user_id, (attemptCountMap.get(v.user_id) ?? 0) + 1)
          )
        }

        // Fetch LeetCode stats
        const leetcodeMap = new Map<string, number>()
        if (leetcodeUsernames.length > 0) {
          const { data: lcStats } = await supabase
            .from('leetcode_stats')
            .select('username,total_solved')
            .in('username', leetcodeUsernames)
          ;(lcStats ?? []).forEach((v) =>
            leetcodeMap.set(v.username, Number(v.total_solved ?? 0))
          )
        }

        // Build report rows
        setRows(
          userList.map((u) => ({
            id: u.id,
            reg_no: u.reg_no,
            name: u.name,
            email: u.email,
            dailyFive: attemptCountMap.get(u.id) ?? 0,
            leetcodeTotal: u.leetcode_username ? leetcodeMap.get(u.leetcode_username) ?? 0 : 0,
          }))
        )

        // Fetch audit logs
        try {
          const { data } = await supabase
            .from('audit_logs')
            .select('id,action,entity_type,created_at,metadata')
            .order('created_at', { ascending: false })
            .limit(50)
          setAudits((data ?? []) as AuditRow[])
        } catch {
          setAudits([])
        }
      } catch (e) {
        setError(e instanceof Error ? e.message : 'Failed to load report data.')
      } finally {
        setLoading(false)
      }
    },
    [supabase]
  )

  useEffect(() => {
    if (selectedBatchId) {
      void loadBatchReports(selectedBatchId)
    }
  }, [selectedBatchId, loadBatchReports])

  const exportStudentsCsv = () => {
    const selectedCode = batches.find((b) => b.id === selectedBatchId)?.batch_code || 'Batch'
    const headers = ['Register Number', 'Name', 'Email', 'Daily Five Completed (30d)', 'LeetCode Total Solved']
    const csvContent = [
      headers.map(escapeCsv).join(','),
      ...rows.map((row) =>
        [row.reg_no, row.name, row.email, row.dailyFive, row.leetcodeTotal].map(escapeCsv).join(',')
      ),
    ].join('\n')

    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' })
    const url = URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = url
    link.download = `PSGMX_${selectedCode}_placement_readiness_report.csv`
    link.click()
    URL.revokeObjectURL(url)
  }

  const exportAuditCsv = () => {
    const headers = ['Action', 'Entity Type', 'Timestamp', 'Details']
    const csvContent = [
      headers.map(escapeCsv).join(','),
      ...audits.map((a) =>
        [
          a.action,
          a.entity_type,
          new Date(a.created_at).toLocaleString('en-IN'),
          JSON.stringify(a.metadata || {}),
        ]
          .map(escapeCsv)
          .join(',')
      ),
    ].join('\n')

    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' })
    const url = URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = url
    link.download = `PSGMX_audit_logs_${new Date().toISOString().slice(0, 10)}.csv`
    link.click()
    URL.revokeObjectURL(url)
  }

  // Aggregate stats
  const totalStudents = rows.length
  const activeDailyFive = rows.filter((r) => r.dailyFive > 0).length
  const avgDailyFive = totalStudents > 0
    ? (rows.reduce((sum, r) => sum + r.dailyFive, 0) / totalStudents).toFixed(1)
    : '0'
  const totalLeetCode = rows.reduce((sum, r) => sum + r.leetcodeTotal, 0)
  const activeLeetCodeUsers = rows.filter((r) => r.leetcodeTotal > 0).length

  const selectedBatchCode = batches.find((b) => b.id === selectedBatchId)?.batch_code || ''

  return (
    <div className="max-w-6xl mx-auto space-y-6 pb-12">
      {/* Header with Batch Tab Switcher */}
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
        <div>
          <h1 className="text-2xl sm:text-3xl font-black text-slate-900 tracking-tight">Placement Reports</h1>
          <p className="mt-1 text-sm text-slate-500">
            Export official readiness reports, habit engagement metrics, and audit history.
          </p>
        </div>

        {/* Batch Tab Switcher (25MX / 26MX) */}
        <div className="inline-flex p-1 rounded-2xl bg-slate-100 border border-slate-200">
          {batches.map((b) => {
            const isSelected = b.id === selectedBatchId
            const isMine = b.id === myBatchId
            return (
              <button
                key={b.id}
                onClick={() => setSelectedBatchId(b.id)}
                className={`relative px-4 py-2 rounded-xl text-xs font-black transition-all ${
                  isSelected
                    ? 'bg-white text-violet-700 shadow-sm'
                    : 'text-slate-600 hover:text-slate-900'
                }`}
              >
                {b.batch_code}
                {isMine && (
                  <span className="ml-1.5 text-[10px] font-bold text-violet-500 bg-violet-50 px-1.5 py-0.5 rounded-full">
                    mine
                  </span>
                )}
              </button>
            )
          })}
        </div>
      </div>

      {error && (
        <div className="rounded-2xl border border-red-200 bg-red-50 p-4 text-sm font-semibold text-red-700">
          {error}
        </div>
      )}

      {/* Aggregate KPI Cards */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <MetricCard
          icon={<Users className="h-6 w-6" />}
          label="Total Students"
          value={totalStudents}
          sub={`${selectedBatchCode} roster`}
          color="text-blue-600"
        />
        <MetricCard
          icon={<Activity className="h-6 w-6" />}
          label="Active in Daily Five"
          value={activeDailyFive}
          sub={`${totalStudents > 0 ? Math.round((activeDailyFive / totalStudents) * 100) : 0}% habit adoption`}
          color="text-emerald-600"
        />
        <MetricCard
          icon={<CheckCircle2 className="h-6 w-6" />}
          label="Avg Daily Five Pace"
          value={avgDailyFive}
          sub="days completed (30d avg)"
          color="text-violet-600"
        />
        <MetricCard
          icon={<TrendingUp className="h-6 w-6" />}
          label="Total LeetCode Solved"
          value={totalLeetCode}
          sub={`${activeLeetCodeUsers} active solvers`}
          color="text-orange-600"
        />
      </div>

      {/* Student Readiness Table */}
      <div className="rounded-2xl border border-slate-200 bg-white shadow-sm overflow-hidden">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 p-5 border-b border-slate-100 bg-slate-50/50">
          <div>
            <h2 className="text-sm font-black text-slate-900 uppercase tracking-wider">
              Student Activity & Readiness ({selectedBatchCode})
            </h2>
            <p className="text-xs text-slate-400 mt-0.5">
              Live snapshot of Daily Five completions and LeetCode problem velocity.
            </p>
          </div>
          <button
            onClick={exportStudentsCsv}
            disabled={rows.length === 0}
            className="flex items-center gap-2 rounded-xl bg-violet-600 hover:bg-violet-700 disabled:opacity-50 px-4 py-2.5 text-xs font-bold text-white transition-colors self-start sm:self-auto shadow-sm"
          >
            <Download className="h-3.5 w-3.5" />
            Export CSV ({rows.length})
          </button>
        </div>

        {loading ? (
          <div className="p-8 text-center text-sm text-slate-400">Loading student records…</div>
        ) : rows.length === 0 ? (
          <div className="p-8 text-center text-sm text-slate-400">No students registered in this batch yet.</div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead className="bg-slate-50 text-[11px] font-black uppercase tracking-wider text-slate-500 border-b border-slate-100">
                <tr>
                  <th className="px-5 py-3.5">Reg. No</th>
                  <th className="px-5 py-3.5">Name</th>
                  <th className="px-5 py-3.5 text-center">Daily Five (30d)</th>
                  <th className="px-5 py-3.5 text-center">LeetCode Solved</th>
                  <th className="px-5 py-3.5 text-right">Activity Level</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {rows.map((row) => {
                  const activityPct = Math.min(100, Math.round((row.dailyFive / 30) * 100))
                  return (
                    <tr key={row.id} className="hover:bg-slate-50/60 transition-colors">
                      <td className="px-5 py-3.5 font-mono text-xs font-bold text-slate-700">
                        {row.reg_no}
                      </td>
                      <td className="px-5 py-3.5">
                        <p className="font-bold text-slate-900">{row.name}</p>
                        <p className="text-xs text-slate-400">{row.email}</p>
                      </td>
                      <td className="px-5 py-3.5 text-center">
                        <span className="inline-flex items-center gap-1 font-bold text-slate-800">
                          {row.dailyFive}
                          <span className="text-xs font-normal text-slate-400">/ 30</span>
                        </span>
                      </td>
                      <td className="px-5 py-3.5 text-center font-bold text-orange-600">
                        {row.leetcodeTotal > 0 ? row.leetcodeTotal : <span className="text-slate-300 font-normal">—</span>}
                      </td>
                      <td className="px-5 py-3.5 text-right">
                        <span
                          className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-bold ${
                            activityPct >= 70
                              ? 'bg-emerald-100 text-emerald-700'
                              : activityPct >= 30
                              ? 'bg-amber-100 text-amber-700'
                              : 'bg-slate-100 text-slate-500'
                          }`}
                        >
                          {activityPct >= 70 ? 'High' : activityPct >= 30 ? 'Moderate' : 'Low'}
                        </span>
                      </td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Audit Log Table */}
      <div className="rounded-2xl border border-slate-200 bg-white shadow-sm overflow-hidden">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 p-5 border-b border-slate-100 bg-slate-50/50">
          <div>
            <h2 className="text-sm font-black text-slate-900 uppercase tracking-wider">Audit Trail</h2>
            <p className="text-xs text-slate-400 mt-0.5">Immutable event history for compliance and verification.</p>
          </div>
          <button
            onClick={exportAuditCsv}
            disabled={audits.length === 0}
            className="flex items-center gap-2 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 px-4 py-2.5 text-xs font-bold transition-colors self-start sm:self-auto"
          >
            <Download className="h-3.5 w-3.5" />
            Export Audit CSV ({audits.length})
          </button>
        </div>

        {audits.length === 0 ? (
          <div className="p-8 text-center text-sm text-slate-400">No audit events recorded yet.</div>
        ) : (
          <div className="overflow-x-auto max-h-80">
            <table className="w-full text-left text-sm">
              <thead className="bg-slate-50 text-[11px] font-black uppercase tracking-wider text-slate-500 border-b border-slate-100 sticky top-0">
                <tr>
                  <th className="px-5 py-3">Timestamp</th>
                  <th className="px-5 py-3">Action</th>
                  <th className="px-5 py-3">Entity</th>
                  <th className="px-5 py-3 text-right">Details</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {audits.map((a) => (
                  <tr key={a.id} className="hover:bg-slate-50/60 transition-colors">
                    <td className="px-5 py-3 text-xs text-slate-400 whitespace-nowrap">
                      {new Date(a.created_at).toLocaleString('en-IN', {
                        month: 'short',
                        day: 'numeric',
                        hour: '2-digit',
                        minute: '2-digit',
                      })}
                    </td>
                    <td className="px-5 py-3 font-mono text-xs font-bold text-slate-800">
                      {a.action}
                    </td>
                    <td className="px-5 py-3 text-xs text-slate-500">{a.entity_type}</td>
                    <td className="px-5 py-3 text-right font-mono text-xs text-slate-400 truncate max-w-xs">
                      {typeof a.metadata === 'object' ? JSON.stringify(a.metadata) : String(a.metadata ?? '')}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  )
}
