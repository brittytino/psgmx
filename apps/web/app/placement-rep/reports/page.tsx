'use client'

import React from 'react'
import { Download, ShieldCheck, TrendingUp, Users } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { getCurrentProfile } from '@/lib/current-profile'

type ReportRow = { id: string; reg_no: string; name: string; email: string; attendance: number; readiness: number; dailyFive: number }
type Audit = { id: string; action: string; entity_type: string; created_at: string; metadata: unknown }

function escapeCsv(value: unknown) { return `"${String(value ?? '').replaceAll('"', '""')}"` }

export default function ReportsPage() {
  const supabase = React.useMemo(() => createClient(), [])
  const [rows, setRows] = React.useState<ReportRow[]>([])
  const [audits, setAudits] = React.useState<Audit[]>([])
  const [loading, setLoading] = React.useState(true)
  React.useEffect(() => { void (async () => {
    const me = await getCurrentProfile(supabase); if (!me?.batch_id) return setLoading(false)
    const [{ data: users }, { data: attendance }, { data: scores }, { data: attempts }, { data: logs }] = await Promise.all([
      supabase.from('users').select('id,reg_no,name,email').eq('batch_id', me.batch_id).eq('role_label', 'Student').order('reg_no'),
      supabase.from('placement_attendance_summary').select('user_id,attendance_pct').eq('batch_id', me.batch_id),
      supabase.from('current_readiness_scores').select('user_id,score'),
      supabase.from('daily_five_attempts').select('user_id,attempt_date').gte('attempt_date', new Date(Date.now() - 30 * 86400000).toISOString().slice(0, 10)),
      supabase.from('audit_logs').select('id,action,entity_type,created_at,metadata').eq('batch_id', me.batch_id).order('created_at', { ascending: false }).limit(50),
    ])
    const attendanceMap = new Map((attendance ?? []).map((v) => [v.user_id, Number(v.attendance_pct ?? 0)]))
    const scoreMap = new Map((scores ?? []).map((v) => [v.user_id, Number(v.score ?? 0)]))
    const attemptCount = new Map<string, number>(); (attempts ?? []).forEach((v) => attemptCount.set(v.user_id, (attemptCount.get(v.user_id) ?? 0) + 1))
    setRows((users ?? []).map((u) => ({ ...u, attendance: attendanceMap.get(u.id) ?? 0, readiness: scoreMap.get(u.id) ?? 0, dailyFive: attemptCount.get(u.id) ?? 0 })))
    setAudits((logs ?? []) as Audit[]); setLoading(false)
  })() }, [supabase])

  function exportCsv() {
    const csv = [['reg_no','name','email','placement_attendance_pct','readiness_score','daily_five_days_30d'], ...rows.map((r) => [r.reg_no,r.name,r.email,r.attendance,r.readiness,r.dailyFive])].map((r) => r.map(escapeCsv).join(',')).join('\n')
    const url = URL.createObjectURL(new Blob([csv], { type: 'text/csv' })); const a = document.createElement('a'); a.href = url; a.download = `psgmx-batch-report-${new Date().toISOString().slice(0,10)}.csv`; a.click(); URL.revokeObjectURL(url)
  }
  const avg = (key: 'attendance'|'readiness') => rows.length ? Math.round(rows.reduce((sum, row) => sum + row[key], 0) / rows.length) : 0
  if (loading) return <p className="text-sm text-text-muted">Building batch report…</p>
  return <div className="max-w-6xl space-y-6">
    <div className="flex items-end justify-between"><div><h1 className="text-2xl font-black">Reports & Audit</h1><p className="mt-1 text-sm text-text-muted">Own-batch outcomes and an accountable history of administrative changes.</p></div><button onClick={exportCsv} className="flex items-center gap-2 rounded-xl bg-primary-purple px-5 py-3 text-sm font-bold text-white"><Download className="h-4 w-4" />Export CSV</button></div>
    <div className="grid gap-4 sm:grid-cols-3">
      <Metric icon={<Users className="h-5 w-5" />} label="Students" value={rows.length} />
      <Metric icon={<TrendingUp className="h-5 w-5" />} label="Avg attendance" value={`${avg('attendance')}%`} />
      <Metric icon={<ShieldCheck className="h-5 w-5" />} label="Avg readiness" value={`${avg('readiness')}%`} />
    </div>
    <div className="overflow-x-auto rounded-2xl border border-border-light bg-white"><table className="w-full min-w-[760px] text-left text-sm"><thead className="bg-page-bg text-xs uppercase text-text-muted"><tr><th className="p-4">Student</th><th>Attendance</th><th>Readiness</th><th>Daily Five / 30d</th></tr></thead><tbody className="divide-y divide-border-light">{rows.map((row) => <tr key={row.id}><td className="p-4"><p className="font-bold">{row.name}</p><p className="text-xs text-text-muted">{row.reg_no}</p></td><td>{row.attendance.toFixed(0)}%</td><td>{row.readiness.toFixed(0)}%</td><td>{row.dailyFive} days</td></tr>)}</tbody></table></div>
    <div className="rounded-2xl border border-border-light bg-white p-5"><h2 className="mb-4 font-black">Recent audit trail</h2><div className="space-y-3">{audits.map((audit) => <div key={audit.id} className="flex items-center justify-between border-b border-border-light pb-3 text-sm last:border-0"><div><p className="font-bold">{audit.action.replaceAll('_',' ')}</p><p className="text-xs text-text-muted">{audit.entity_type}</p></div><time className="text-xs text-text-muted">{new Date(audit.created_at).toLocaleString()}</time></div>)}{audits.length === 0 && <p className="text-sm text-text-muted">No batch administration events recorded yet.</p>}</div></div>
  </div>
}

function Metric({ icon, label, value }: { icon: React.ReactNode; label: string; value: string | number }) {
  return <div className="rounded-2xl border border-border-light bg-white p-5"><div className="text-primary-purple">{icon}</div><p className="mt-4 text-3xl font-black">{value}</p><p className="text-sm text-text-muted">{label}</p></div>
}
