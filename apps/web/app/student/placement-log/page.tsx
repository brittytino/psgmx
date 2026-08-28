'use client'

import React from 'react'
import { Building2, Loader2, Search } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'

type Entry = { id: string; company_id: string; user_id: string; round_name: string; experience_text: string; created_at: string }
type Company = { id: string; name: string; roles_offered: string[]; visit_date: string; rounds: unknown }
type Author = { id: string; name: string; reg_no: string }

export default function PlacementLogPage() {
  const supabase = React.useMemo(() => createClient(), [])
  const [entries, setEntries] = React.useState<Entry[]>([])
  const [companies, setCompanies] = React.useState<Map<string, Company>>(new Map())
  const [authors, setAuthors] = React.useState<Map<string, Author>>(new Map())
  const [query, setQuery] = React.useState('')
  const [loading, setLoading] = React.useState(true)
  const [error, setError] = React.useState('')

  const load = React.useCallback(async () => {
    setLoading(true)
    const { data, error: entryError } = await supabase.from('placement_log_entries').select('id,company_id,user_id,round_name,experience_text,created_at').eq('approval_status', 'approved').eq('is_moderated', true).order('created_at', { ascending: false }).limit(150)
    if (entryError) { setError(entryError.message); setLoading(false); return }
    const rows = data ?? []
    setEntries(rows)
    const companyIds = [...new Set(rows.map((row) => row.company_id))]
    const userIds = [...new Set(rows.map((row) => row.user_id))]
    const [{ data: companyRows }, { data: userRows }] = await Promise.all([
      companyIds.length ? supabase.from('companies').select('id,name,roles_offered,visit_date,rounds').in('id', companyIds) : Promise.resolve({ data: [] }),
      userIds.length ? supabase.from('users').select('id,name,reg_no').in('id', userIds) : Promise.resolve({ data: [] }),
    ])
    setCompanies(new Map((companyRows ?? []).map((row) => [row.id, row])))
    setAuthors(new Map((userRows ?? []).map((row) => [row.id, row])))
    setLoading(false)
  }, [supabase])
  React.useEffect(() => { void load() }, [load])

  const filtered = entries.filter((entry) => {
    const company = companies.get(entry.company_id)
    const author = authors.get(entry.user_id)
    return `${company?.name ?? ''} ${company?.roles_offered.join(' ') ?? ''} ${entry.round_name} ${entry.experience_text} ${author?.name ?? ''}`.toLowerCase().includes(query.toLowerCase())
  })
  if (loading) return <div className="flex min-h-64 items-center justify-center"><Loader2 className="h-6 w-6 animate-spin text-primary-purple"/></div>

  return <div className="mx-auto max-w-5xl space-y-7 pb-10">
    <div><h1 className="flex items-center gap-2 text-2xl font-black"><Building2 className="h-6 w-6 text-primary-purple"/>Placement experiences</h1><p className="mt-1 text-sm text-text-muted">Moderated, approved accounts from students who attended real drives.</p></div>
    <label className="relative block"><Search className="absolute left-4 top-3.5 h-4 w-4 text-text-muted"/><input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Search company, role, round or skill" className="w-full rounded-2xl border border-border-light bg-white py-3 pl-11 pr-4 text-sm outline-none focus:border-primary-purple"/></label>
    {error && <div className="rounded-2xl border border-amber-200 bg-amber-50 p-5 text-sm font-bold">{error}<button onClick={load} className="ml-2 text-primary-purple">Retry</button></div>}
    {!error && filtered.length === 0 && <div className="rounded-3xl border border-dashed border-border-light bg-white p-14 text-center"><Building2 className="mx-auto h-10 w-10 text-text-muted"/><h2 className="mt-4 font-black">{entries.length ? 'No experience matches that search' : 'No approved experiences yet'}</h2><p className="mt-2 text-sm text-text-muted">Senior submissions appear after Placement Rep moderation.</p></div>}
    <div className="space-y-4">{filtered.map((entry) => { const company = companies.get(entry.company_id); const author = authors.get(entry.user_id); return <article key={entry.id} className="rounded-2xl border border-border-light bg-white p-5 sm:p-6"><div className="flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between"><div><h2 className="text-lg font-black">{company?.name ?? 'Placement drive'}</h2><p className="text-sm font-bold text-primary-purple">{entry.round_name}</p></div><p className="text-xs text-text-muted">{new Intl.DateTimeFormat('en-IN', { dateStyle: 'medium' }).format(new Date(entry.created_at))}</p></div><p className="mt-4 whitespace-pre-wrap text-sm leading-6 text-text-main">{entry.experience_text}</p><div className="mt-4 flex flex-wrap gap-2">{company?.roles_offered.map((role) => <span key={role} className="rounded-full bg-page-bg px-3 py-1 text-[10px] font-bold text-text-muted">{role}</span>)}</div><p className="mt-4 text-xs font-bold text-text-muted">{author ? `${author.name} · ${author.reg_no.slice(0, 4)}` : 'Verified PSGMX contributor'}</p></article> })}</div>
  </div>
}
