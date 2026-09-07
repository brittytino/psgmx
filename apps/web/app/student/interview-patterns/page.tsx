'use client'

import React from 'react'
import { Building2, Calendar, Lightbulb, Loader2, ShieldCheck, Sparkles, X } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'

type Pattern = {
  id: string
  title: string
  pattern_type: string
  historical_context: string | null
  preparation_helped: string
  mistakes: string | null
  example_themes: string[]
  advice: string
  company_name: string | null
  batch_year: string | null
  created_at: string
}

const TYPE_LABELS: Record<string, string> = {
  aptitude_screening: 'Aptitude Screening',
  coding_round: 'Coding Round',
  technical_deep_dive: 'Technical Deep Dive',
  fyp_discussion: 'FYP Discussion',
  behavioural: 'Behavioural',
  group_discussion: 'Group Discussion',
  general: 'General',
}

export default function InterviewPatternsPage() {
  const supabase = React.useMemo(() => createClient(), [])
  const [patterns, setPatterns] = React.useState<Pattern[]>([])
  const [query, setQuery] = React.useState('')
  const [type, setType] = React.useState<string | null>(null)
  const [active, setActive] = React.useState<Pattern | null>(null)
  const [loading, setLoading] = React.useState(true)
  const [error, setError] = React.useState('')

  const load = React.useCallback(async () => {
    setLoading(true); setError('')
    try {
      const { data, error: patternError } = await supabase
        .from('interview_patterns')
        .select('id,title,pattern_type,historical_context,preparation_helped,mistakes,example_themes,advice,company_name,batch_year,created_at')
        .eq('approval_status', 'approved')
        .order('created_at', { ascending: false })
        .limit(200)
      if (patternError) throw patternError
      setPatterns((data ?? []) as Pattern[])
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : 'Interview patterns could not be loaded.')
      setPatterns([])
    } finally {
      setLoading(false)
    }
  }, [supabase])
  React.useEffect(() => { void load() }, [load])

  const types = React.useMemo(() => [...new Set(patterns.map((p) => p.pattern_type))], [patterns])
  const visible = React.useMemo(() => patterns.filter((p) => {
    const text = `${p.title} ${p.company_name ?? ''} ${(p.example_themes ?? []).join(' ')}`.toLowerCase()
    return text.includes(query.toLowerCase()) && (!type || p.pattern_type === type)
  }), [patterns, query, type])

  if (loading) return <div className="grid min-h-64 place-items-center"><Loader2 className="h-6 w-6 animate-spin text-primary-purple" /></div>

  return (
    <div className="mx-auto max-w-5xl space-y-7 pb-12">
      <header>
        <h1 className="flex items-center gap-2 text-2xl font-black"><Building2 className="h-6 w-6 text-primary-purple" />Interview Pattern Library</h1>
        <p className="mt-1 text-sm text-text-muted">{patterns.length} faculty-reviewed patterns contributed by alumni and seniors.</p>
        <div className="mt-3 flex gap-3 rounded-2xl border border-amber-200 bg-amber-50 p-4 text-xs font-semibold leading-5 text-amber-900">
          <ShieldCheck className="mt-0.5 h-5 w-5 shrink-0" />
          <span>These are historical, faculty-reviewed accounts of past interviews — not official drive information. Official drives, eligibility, applications and shortlists stay in NEO PAT.</span>
        </div>
      </header>

      {error && <div className="rounded-xl bg-red-50 p-4 text-sm font-bold text-red-700">{error} <button onClick={() => void load()} className="underline">Retry</button></div>}

      <input
        value={query}
        onChange={(event) => setQuery(event.target.value)}
        className="w-full rounded-2xl border border-border-light bg-white py-3 px-4 text-sm outline-none focus:border-primary-purple"
        placeholder="Search by title, company or theme…"
      />

      <div className="flex flex-wrap gap-2">
        <button onClick={() => setType(null)} className={`rounded-xl px-3 py-1.5 text-xs font-bold ${!type ? 'bg-primary-purple text-white' : 'border border-border-light bg-white'}`}>All</button>
        {types.map((value) => (
          <button key={value} onClick={() => setType(value)} className={`rounded-xl px-3 py-1.5 text-xs font-bold ${type === value ? 'bg-primary-purple text-white' : 'border border-border-light bg-white'}`}>
            {TYPE_LABELS[value] || value}
          </button>
        ))}
      </div>

      <div className="grid gap-4 sm:grid-cols-2">
        {visible.map((pattern) => (
          <button key={pattern.id} onClick={() => setActive(pattern)} className="rounded-3xl border border-border-light bg-white p-6 text-left shadow-sm transition hover:border-primary-purple/40">
            <div className="flex flex-wrap gap-2">
              <span className="inline-flex items-center gap-1 rounded-full bg-violet-50 px-2 py-1 text-[10px] font-black text-primary-purple">{TYPE_LABELS[pattern.pattern_type] || pattern.pattern_type}</span>
              {pattern.company_name && <span className="inline-flex items-center gap-1 rounded-full bg-page-bg px-2 py-1 text-[10px] font-black"><Building2 className="h-3 w-3" />{pattern.company_name}</span>}
              {pattern.batch_year && <span className="rounded-full bg-page-bg px-2 py-1 text-[10px] font-black">{pattern.batch_year}</span>}
            </div>
            <h2 className="mt-3 text-base font-black leading-6">{pattern.title}</h2>
            <p className="mt-2 line-clamp-3 text-xs leading-5 text-text-muted">{pattern.preparation_helped}</p>
          </button>
        ))}
        {!visible.length && <div className="col-span-full rounded-3xl border border-dashed border-border-light bg-white p-10 text-center text-sm text-text-muted">No approved pattern matches this view yet.</div>}
      </div>

      {active && (
        <div className="fixed inset-0 z-50 overflow-y-auto bg-slate-950/50 p-4 sm:p-8">
          <article className="mx-auto max-w-3xl rounded-3xl bg-white p-6 shadow-2xl sm:p-9">
            <div className="flex justify-between gap-4">
              <div>
                <h2 className="text-2xl font-black">{active.title}</h2>
                <p className="mt-2 flex items-center gap-1 text-xs text-text-muted"><Calendar className="h-3.5 w-3.5" />{new Intl.DateTimeFormat('en-IN', { dateStyle: 'medium' }).format(new Date(active.created_at))}</p>
              </div>
              <button onClick={() => setActive(null)} aria-label="Close"><X className="h-5 w-5" /></button>
            </div>
            {active.historical_context && <p className="mt-6 whitespace-pre-wrap text-sm leading-7 text-text-main">{active.historical_context}</p>}
            <div className="mt-6 rounded-2xl bg-emerald-50 p-4">
              <p className="flex items-center gap-1.5 text-xs font-black text-emerald-800"><Sparkles className="h-4 w-4" />What preparation helped</p>
              <p className="mt-2 whitespace-pre-wrap text-sm leading-6 text-emerald-900">{active.preparation_helped}</p>
            </div>
            {active.mistakes && (
              <div className="mt-4 rounded-2xl bg-red-50 p-4">
                <p className="text-xs font-black text-red-800">Mistakes to avoid</p>
                <p className="mt-2 whitespace-pre-wrap text-sm leading-6 text-red-900">{active.mistakes}</p>
              </div>
            )}
            <div className="mt-4 rounded-2xl bg-violet-50 p-4">
              <p className="flex items-center gap-1.5 text-xs font-black text-primary-purple"><Lightbulb className="h-4 w-4" />Advice</p>
              <p className="mt-2 whitespace-pre-wrap text-sm leading-6 text-text-main">{active.advice}</p>
            </div>
            {!!active.example_themes?.length && (
              <div className="mt-4 flex flex-wrap gap-2">
                {active.example_themes.map((theme) => <span key={theme} className="rounded-full bg-page-bg px-3 py-1 text-[11px] font-bold text-text-muted">{theme}</span>)}
              </div>
            )}
          </article>
        </div>
      )}
    </div>
  )
}
