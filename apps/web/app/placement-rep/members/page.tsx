'use client'

import React from 'react'
import { Upload, Search, ShieldCheck, MailPlus } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { getCurrentProfile } from '@/lib/current-profile'
import { parseCsv } from '@/lib/csv'

const permissionOptions = [
  ['configure_teams', 'Teams'],
  ['schedule_preparation_sessions', 'Programme'],
  ['mark_preparation_participation', 'Participation'],
  ['publish_quests', 'Quests'],
  ['publish_announcements', 'Communication'],
  ['manage_preparation_tracks', 'Tracks'],
  ['moderate_interview_patterns', 'Patterns'],
  ['view_batch_analytics', 'Analytics'],
  ['view_ai_mentor', 'AI Senior'],
] as const

type Member = {
  id: string | null
  name: string
  reg_no: string
  email: string
  personal_email: string | null
  college_email: string | null
  section: string | null
  team_uuid: string | null
  activated: boolean
  user_permissions: { permission_key: string }[]
}

export default function MembersPage() {
  const supabase = React.useMemo(() => createClient(), [])
  const [members, setMembers] = React.useState<Member[]>([])
  const [batchId, setBatchId] = React.useState('')
  const [query, setQuery] = React.useState('')
  const [message, setMessage] = React.useState('')
  const [busy, setBusy] = React.useState(false)

  const load = React.useCallback(async () => {
    const me = await getCurrentProfile(supabase)
    if (!me?.batch_id) return
    setBatchId(me.batch_id)

    const [{ data: roster }, { data: users }, { data: permissions }] = await Promise.all([
      supabase.from('whitelist').select('email,name,reg_no,personal_email,college_email,batch,team_id').eq('batch_id', me.batch_id).order('reg_no'),
      supabase.from('users').select('id,reg_no,team_uuid').eq('batch_id', me.batch_id).eq('role_label', 'Student'),
      supabase.from('user_permissions').select('user_id,permission_key'),
    ])

    const usersByRegisterNumber = new Map((users ?? []).map((user) => [user.reg_no, user]))
    const permissionMap = new Map<string, { permission_key: string }[]>()
    for (const permission of permissions ?? []) {
      permissionMap.set(permission.user_id, [
        ...(permissionMap.get(permission.user_id) ?? []),
        { permission_key: permission.permission_key },
      ])
    }

    setMembers((roster ?? []).map((entry) => {
      const registerNumber = entry.reg_no ?? 'Unassigned'
      const user = usersByRegisterNumber.get(registerNumber)
      return {
        id: user?.id ?? null,
        name: entry.name ?? registerNumber,
        reg_no: registerNumber,
        email: entry.email,
        personal_email: entry.personal_email,
        college_email: entry.college_email,
        section: entry.batch,
        team_uuid: user?.team_uuid ?? null,
        activated: Boolean(user),
        user_permissions: user ? permissionMap.get(user.id) ?? [] : [],
      }
    }))
  }, [supabase])

  React.useEffect(() => { void load() }, [load])

  async function importRoster(event: React.ChangeEvent<HTMLInputElement>) {
    const file = event.target.files?.[0]
    if (!file || !batchId) return
    setBusy(true)
    setMessage('')
    const students = parseCsv(await file.text())
    const response = await fetch('/api/faculty/batch-import', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ students, batch_id: batchId }),
    })
    const result = await response.json()
    setMessage(response.ok
      ? `${result.created} rostered: ${result.readyForOtp} OTP-ready, ${result.pendingEmail} waiting for email; ${result.failed} failed.`
      : result.error ?? 'Import failed.')
    if (response.ok) await load()
    setBusy(false)
    event.target.value = ''
  }

  async function togglePermission(member: Member, key: string) {
    if (!member.id) {
      setMessage('This student must complete their first login before permissions can be assigned.')
      return
    }
    const current = member.user_permissions.map((permission) => permission.permission_key)
    const next = current.includes(key) ? current.filter((permission) => permission !== key) : [...current, key]
    const { error } = await supabase.rpc('set_member_permissions', { p_user_id: member.id, p_permissions: next })
    if (error) return setMessage(error.message)
    setMembers((rows) => rows.map((row) => row.id === member.id
      ? { ...row, user_permissions: next.map((permission_key) => ({ permission_key })) }
      : row))
  }

  const filtered = members.filter((member) =>
    `${member.name} ${member.reg_no} ${member.email}`.toLowerCase().includes(query.toLowerCase()))
  const otpReady = members.filter((member) => member.personal_email || member.college_email).length
  const activated = members.filter((member) => member.activated).length

  return <div className="max-w-6xl space-y-6">
    <div className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
      <div>
        <h1 className="text-2xl font-black">Members & Access</h1>
        <p className="mt-1 text-sm text-text-muted">Manage the complete batch roster, including students waiting for email or their first login.</p>
      </div>
      <label className="inline-flex cursor-pointer items-center gap-2 rounded-xl bg-primary-purple px-5 py-3 text-sm font-bold text-white">
        <Upload className="h-4 w-4" /> {busy ? 'Importing…' : 'Import roster CSV'}
        <input type="file" accept=".csv,text/csv" className="hidden" disabled={busy} onChange={importRoster} />
      </label>
    </div>

    <div className="rounded-2xl border border-border-light bg-white p-5">
      <div className="flex items-start gap-3">
        <MailPlus className="mt-0.5 h-5 w-5 text-primary-purple" />
        <div className="text-sm"><p className="font-bold">CSV columns</p><p className="text-text-muted">section, name, reg_no, personal_email, alternate_personal_email, college_email, team_code, gender. Name and register number are required; email can be added later.</p></div>
      </div>
      {message && <p className="mt-3 rounded-lg bg-page-bg px-3 py-2 text-sm font-semibold">{message}</p>}
    </div>

    <div className="grid gap-3 sm:grid-cols-3">
      {[
        ['Rostered', members.length],
        ['OTP-ready', otpReady],
        ['Activated', activated],
      ].map(([label, value]) => <div key={label} className="rounded-2xl border border-border-light bg-white p-4"><p className="text-xs font-bold uppercase tracking-wide text-text-muted">{label}</p><p className="mt-1 text-2xl font-black">{value}</p></div>)}
    </div>

    <div className="relative max-w-md">
      <Search className="absolute left-3 top-3 h-4 w-4 text-text-muted" />
      <input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Search name, register number or email" className="w-full rounded-xl border border-border-light bg-white py-2.5 pl-10 pr-4 text-sm outline-none focus:border-primary-purple" />
    </div>

    <div className="overflow-hidden rounded-2xl border border-border-light bg-white">
      <div className="overflow-x-auto">
        <table className="w-full min-w-[1040px] text-left text-sm">
          <thead className="bg-page-bg text-xs uppercase text-text-muted"><tr><th className="p-4">Student</th><th>Email identities</th><th>Status</th><th>Delegated access</th></tr></thead>
          <tbody className="divide-y divide-border-light">
            {filtered.map((member) => <tr key={member.reg_no}>
              <td className="p-4"><p className="font-bold">{member.name}</p><p className="text-xs text-text-muted">{member.reg_no} • {member.section ?? 'Section pending'}</p></td>
              <td className="py-4"><p>{member.personal_email ?? 'Personal email required'}</p><p className="text-xs text-text-muted">{member.college_email ?? 'College email not issued'}</p></td>
              <td className="py-4"><span className={`rounded-full px-3 py-1 text-xs font-bold ${member.activated ? 'bg-emerald-50 text-emerald-700' : member.personal_email || member.college_email ? 'bg-violet-50 text-violet-700' : 'bg-amber-50 text-amber-700'}`}>{member.activated ? 'Activated' : member.personal_email || member.college_email ? 'Awaiting first login' : 'Email required'}</span></td>
              <td className="py-4 pr-4"><div className="flex flex-wrap gap-2">{permissionOptions.map(([key, label]) => {
                const active = member.user_permissions.some((permission) => permission.permission_key === key)
                return <button key={key} disabled={!member.id} onClick={() => togglePermission(member, key)} className={`rounded-full px-3 py-1 text-xs font-bold disabled:cursor-not-allowed disabled:opacity-40 ${active ? 'bg-primary-purple text-white' : 'bg-page-bg text-text-muted'}`}><ShieldCheck className="mr-1 inline h-3 w-3" />{label}</button>
              })}</div></td>
            </tr>)}
          </tbody>
        </table>
      </div>
    </div>
  </div>
}
