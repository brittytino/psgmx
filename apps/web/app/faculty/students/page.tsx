'use client'

import React from 'react'
import { AlertTriangle, Award, Loader2, Search, Users } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { InitialsAvatar } from '@/components/basic/InitialsAvatar'

type Student = {
  id: string
  name: string
  email: string
  regNo: string
  batchCode: string
  section: string
  score: number | null
  status: string
  lastActive: string
}

function readinessBand(score: number | null) {
  if (score === null) return 'Not measured'
  if (score >= 80) return 'Strong'
  if (score >= 60) return 'Building'
  if (score >= 40) return 'Needs attention'
  return 'At risk'
}

export default function FacultyStudentsDashboard() {
  const supabase = React.useMemo(() => createClient(), [])
  const [students, setStudents] = React.useState<Student[]>([])
  const [query, setQuery] = React.useState('')
  const [batchFilter, setBatchFilter] = React.useState('all')
  const [riskOnly, setRiskOnly] = React.useState(false)
  const [loading, setLoading] = React.useState(true)
  const [error, setError] = React.useState('')

  const load = React.useCallback(async () => {
    setLoading(true)
    setError('')
    const { data: userRows, error: userError } = await supabase
      .from('users')
      .select('id,name,email,reg_no,batch,batch_id,updated_at,batches(batch_code,status)')
      .eq('role_label', 'Student')
      .order('reg_no')
    if (userError) {
      setError(userError.message)
      setLoading(false)
      return
    }
    const ids = (userRows ?? []).map((row) => row.id)
    const { data: scores, error: scoreError } = ids.length
      ? await supabase.from('current_readiness_scores').select('user_id,score').in('user_id', ids)
      : { data: [], error: null }
    if (scoreError) setError('Student identities loaded, but readiness scores are temporarily unavailable.')
    const scoreMap = new Map((scores ?? []).map((row) => [row.user_id, Number(row.score)]))
    setStudents((userRows ?? []).map((row) => {
      const batch = Array.isArray(row.batches) ? row.batches[0] : row.batches
      const score = scoreMap.get(row.id) ?? null
      return {
        id: row.id,
        name: row.name,
        email: row.email,
        regNo: row.reg_no,
        batchCode: batch?.batch_code ?? 'Unassigned',
        section: row.batch,
        score,
        status: batch?.status ?? 'unassigned',
        lastActive: row.updated_at,
      }
    }))
    setLoading(false)
  }, [supabase])

  React.useEffect(() => { void load() }, [load])

  const batchCodes = [...new Set(students.map((student) => student.batchCode))].sort()
  const filtered = students.filter((student) => {
    const searchMatch = `${student.name} ${student.regNo} ${student.email}`.toLowerCase().includes(query.toLowerCase())
    const batchMatch = batchFilter === 'all' || student.batchCode === batchFilter
    const riskMatch = !riskOnly || (student.score !== null && student.score < 40)
    return searchMatch && batchMatch && riskMatch
  })
  const measured = students.filter((student) => student.score !== null)
  const atRisk = measured.filter((student) => (student.score ?? 100) < 40).length
  const strong = measured.filter((student) => (student.score ?? 0) >= 80).length
  const stats = [
    { label: 'Active students', value: students.length, icon: Users },
    { label: 'Readiness measured', value: measured.length, icon: Award },
    { label: 'Needs intervention', value: atRisk, icon: AlertTriangle },
  ]

  if (loading) return <div className="flex min-h-64 items-center justify-center"><Loader2 className="h-6 w-6 animate-spin text-primary-purple"/></div>

  return <div className="mx-auto max-w-7xl space-y-7 pb-10">
    <div><h1 className="flex items-center gap-2 text-2xl font-black"><Users className="h-6 w-6 text-primary-purple"/>Student pulse</h1><p className="mt-1 text-sm text-text-muted">Live identity and readiness data across every current batch.</p></div>

    <div className="grid gap-3 sm:grid-cols-3">{stats.map(({ label, value, icon: Icon }) => <div key={label} className="rounded-2xl border border-border-light bg-white p-5"><Icon className="h-5 w-5 text-primary-purple"/><p className="mt-4 text-3xl font-black">{value}</p><p className="mt-1 text-xs font-bold text-text-muted">{label}</p></div>)}</div>

    {error && <div className="rounded-2xl border border-amber-200 bg-amber-50 p-4 text-sm font-semibold">{error}<button onClick={load} className="ml-2 font-black text-primary-purple">Retry</button></div>}

    <div className="flex flex-col gap-3 rounded-2xl border border-border-light bg-white p-4 md:flex-row md:items-center">
      <label className="relative flex-1"><Search className="absolute left-3 top-3 h-4 w-4 text-text-muted"/><input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Search name, register number or email" className="w-full rounded-xl border border-border-light bg-page-bg py-2.5 pl-10 pr-4 text-sm outline-none focus:border-primary-purple"/></label>
      <select value={batchFilter} onChange={(event) => setBatchFilter(event.target.value)} className="rounded-xl border border-border-light bg-page-bg px-4 py-2.5 text-sm font-bold"><option value="all">All batches</option>{batchCodes.map((code) => <option key={code} value={code}>{code}</option>)}</select>
      <label className="flex items-center gap-2 rounded-xl bg-page-bg px-4 py-2.5 text-sm font-bold"><input type="checkbox" checked={riskOnly} onChange={(event) => setRiskOnly(event.target.checked)} className="accent-[#5B3FD1]"/>At risk only</label>
    </div>

    <div className="overflow-hidden rounded-2xl border border-border-light bg-white">
      <div className="overflow-x-auto"><table className="w-full min-w-[760px] text-left text-sm"><thead className="bg-page-bg text-xs uppercase text-text-muted"><tr><th className="p-4">Student</th><th>Batch</th><th>Readiness</th><th>Band</th><th>Record updated</th></tr></thead><tbody className="divide-y divide-border-light">{filtered.map((student) => <tr key={student.id} className="hover:bg-page-bg/60"><td className="p-4"><div className="flex items-center gap-3"><InitialsAvatar name={student.name} size={36}/><div><p className="font-black">{student.name}</p><p className="text-xs text-text-muted">{student.regNo} · {student.email}</p></div></div></td><td><p className="font-bold">{student.batchCode}</p><p className="text-xs text-text-muted">{student.section} · {student.status.replaceAll('_', ' ')}</p></td><td><p className="font-black">{student.score === null ? '—' : `${Math.round(student.score)}/100`}</p></td><td><span className={`rounded-full px-3 py-1 text-xs font-bold ${student.score === null ? 'bg-slate-100 text-slate-600' : student.score < 40 ? 'bg-red-50 text-red-700' : student.score >= 80 ? 'bg-emerald-50 text-emerald-700' : 'bg-amber-50 text-amber-700'}`}>{readinessBand(student.score)}</span></td><td className="text-xs text-text-muted">{new Intl.DateTimeFormat('en-IN', { dateStyle: 'medium' }).format(new Date(student.lastActive))}</td></tr>)}{filtered.length === 0 && <tr><td colSpan={5} className="p-12 text-center text-sm text-text-muted">No real student records match this view.</td></tr>}</tbody></table></div>
    </div>
    <p className="text-xs text-text-muted">{strong} students are currently in the Strong band. Readiness is shown only after the scoring engine has real activity to measure.</p>
  </div>
}
