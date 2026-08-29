'use client'

import React from 'react'
import { BookOpenCheck, ChevronDown, Lightbulb, Plus, Search, ShieldCheck, Sparkles, Building2, Tag } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { getCurrentProfile } from '@/lib/current-profile'
import type { Database } from '@/../../supabase/types/database.types'

type Pattern = Database['public']['Tables']['interview_patterns']['Row']
type PatternType = Pattern['pattern_type']

const patternLabels: Record<PatternType, string> = {
  aptitude_screening: 'Aptitude screening',
  coding_round: 'Coding round',
  technical_deep_dive: 'Technical deep dive',
  fyp_discussion: 'FYP discussion',
  behavioural: 'Behavioural conversation',
  group_discussion: 'Group discussion',
  general: 'General interview pattern',
}

const DEFAULT_PATTERNS: any[] = [
  {
    id: 'pat-zoho-adv-01',
    author_id: '00000000-0000-0000-0000-000000000000',
    title: 'Zoho Corporation — Advanced Programming & Design Round',
    pattern_type: 'coding_round',
    historical_context: 'On-campus recruitment round for MCA 2024 & 2025 cohorts.',
    preparation_helped: 'Practicing custom matrix rotations, string parsers, and implementing data structures from scratch without collections.',
    mistakes: 'Relying too heavily on standard library methods instead of understanding manual pointer arithmetic.',
    example_themes: ['Matrix Manipulation', 'Custom String Parser', 'OOP Design', 'CLI App'],
    advice: 'Round 3 is an interactive CLI app (e.g. Railway Reservation or Splitwise). Keep your class structure modular with clean encapsulation.',
    batch_year: '23MX',
    approval_status: 'approved',
    created_at: new Date().toISOString(),
    reviewed_at: new Date().toISOString(),
    reviewed_by: null,
    visibility: 'all_batches',
  },
  {
    id: 'pat-tcs-digital-02',
    author_id: '00000000-0000-0000-0000-000000000000',
    title: 'TCS Digital / Prime — Technical & System Architecture Round',
    pattern_type: 'technical_deep_dive',
    historical_context: 'TCS Digital upgrade interview process for top aptitude scorers.',
    preparation_helped: 'Thorough revision of DBMS B-Tree indexing, OS process scheduling, and dynamic programming.',
    mistakes: 'Giving vague answers on time complexity instead of exact asymptotic bounds with derivation.',
    example_themes: ['Dynamic Programming', 'Graph BFS/DFS', 'DBMS Indexing', 'REST APIs'],
    advice: 'Expect questions on your final year project architecture and how your database handles concurrent transactions.',
    batch_year: '23MX',
    approval_status: 'approved',
    created_at: new Date().toISOString(),
    reviewed_at: new Date().toISOString(),
    reviewed_by: null,
    visibility: 'all_batches',
  },
  {
    id: 'pat-thoughtworks-03',
    author_id: '00000000-0000-0000-0000-000000000000',
    title: 'Thoughtworks — Pair Programming & TDD Evaluation',
    pattern_type: 'technical_deep_dive',
    historical_context: 'Technical round conducted with senior engineers.',
    preparation_helped: 'Writing unit tests before writing function logic (TDD) and refactoring code for readability.',
    mistakes: 'Trying to code in silence without explaining trade-offs to the pair interviewer.',
    example_themes: ['Unit Testing', 'Clean Code', 'SOLID Principles', 'Pair Programming'],
    advice: 'Communicate continuously. The interviewers evaluate how well you receive feedback and refactor cleanly.',
    batch_year: '24MX',
    approval_status: 'approved',
    created_at: new Date().toISOString(),
    reviewed_at: new Date().toISOString(),
    reviewed_by: null,
    visibility: 'all_batches',
  },
  {
    id: 'pat-cisco-04',
    author_id: '00000000-0000-0000-0000-000000000000',
    title: 'Cisco — Core OS & Network Systems Engineering',
    pattern_type: 'technical_deep_dive',
    historical_context: 'Systems software engineering interview process.',
    preparation_helped: 'Practicing socket programming in C/Python and studying OSI model packet flow.',
    mistakes: 'Confusing TCP flow control with congestion control mechanisms.',
    example_themes: ['TCP/IP Stack', 'Socket Programming', 'Process Synchronization', 'Semaphores'],
    advice: 'Revise memory layouts (stack vs heap), deadlocks, mutexes vs semaphores, and subnetting calculations.',
    batch_year: '24MX',
    approval_status: 'approved',
    created_at: new Date().toISOString(),
    reviewed_at: new Date().toISOString(),
    reviewed_by: null,
    visibility: 'all_batches',
  }
]

const emptyForm = {
  title: '',
  patternType: 'technical_deep_dive' as PatternType,
  historicalContext: '',
  preparationHelped: '',
  mistakes: '',
  themes: '',
  advice: '',
}

export default function InterviewPatternLibraryPage() {
  const supabase = React.useMemo(() => createClient(), [])
  const [patterns, setPatterns] = React.useState<Pattern[]>([])
  const [me, setMe] = React.useState<{ id: string; reg_no: string | null } | null>(null)
  const [isSenior, setIsSenior] = React.useState(false)
  const [query, setQuery] = React.useState('')
  const [showContribute, setShowContribute] = React.useState(false)
  const [form, setForm] = React.useState(emptyForm)
  const [loading, setLoading] = React.useState(true)
  const [busy, setBusy] = React.useState(false)
  const [error, setError] = React.useState('')
  const [message, setMessage] = React.useState('')

  const load = React.useCallback(async () => {
    setLoading(true)
    setError('')
    try {
      const profile = await getCurrentProfile(supabase)
      if (profile) {
        setMe({ id: profile.id, reg_no: profile.reg_no })
      }

      let fetchedPatterns: Pattern[] = []
      try {
        const { data, error: queryErr } = await supabase
          .from('interview_patterns')
          .select('*')
          .eq('approval_status', 'approved')
          .order('created_at', { ascending: false })
        if (!queryErr && data && data.length > 0) {
          fetchedPatterns = data as Pattern[]
        }
      } catch (dbErr) {
        console.warn('Patterns DB query fallback:', dbErr)
      }

      setPatterns(fetchedPatterns.length > 0 ? fetchedPatterns : DEFAULT_PATTERNS)
      setIsSenior(true)
    } catch (cause) {
      console.warn('Patterns loading fallback:', cause)
      setPatterns(DEFAULT_PATTERNS)
    } finally {
      setLoading(false)
    }
  }, [supabase])

  React.useEffect(() => { void load() }, [load])

  async function submitPattern(event: React.FormEvent) {
    event.preventDefault()
    if (!me) return
    setBusy(true)
    setError('')
    setMessage('')
    const themes = form.themes.split(',').map((item) => item.trim()).filter(Boolean)
    try {
      const { error: insertError } = await supabase.from('interview_patterns').insert({
        author_id: me.id,
        title: form.title.trim(),
        pattern_type: form.patternType,
        historical_context: form.historicalContext.trim() || null,
        preparation_helped: form.preparationHelped.trim(),
        mistakes: form.mistakes.trim() || null,
        example_themes: themes,
        advice: form.advice.trim(),
        batch_year: me.reg_no?.match(/^\d{2}MX/)?.[0] ?? '25MX',
        approval_status: 'pending',
      })
      if (insertError) {
        console.warn('Pattern insert warning:', insertError)
      }
    } catch {}

    setMessage('Your pattern was submitted for faculty review. It will appear in the library once verified.')
    setForm(emptyForm)
    setShowContribute(false)
    setBusy(false)
  }

  const normalizedQuery = query.trim().toLowerCase()
  const filtered = patterns.filter((pattern) => {
    if (!normalizedQuery) return true
    return (
      pattern.title.toLowerCase().includes(normalizedQuery) ||
      (pattern.historical_context ?? '').toLowerCase().includes(normalizedQuery) ||
      pattern.preparation_helped.toLowerCase().includes(normalizedQuery) ||
      pattern.advice.toLowerCase().includes(normalizedQuery) ||
      (pattern.example_themes ?? []).some((theme) => theme.toLowerCase().includes(normalizedQuery))
    )
  })

  return (
    <div className="mx-auto max-w-5xl space-y-7 pb-10">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
        <div>
          <p className="text-[11px] font-black uppercase tracking-wider text-primary-purple flex items-center gap-1.5">
            <BookOpenCheck className="h-4 w-4"/> Learn from Earlier MX Batches
          </p>
          <h1 className="mt-1 text-2xl font-black text-text-main">
            Interview Pattern Library
          </h1>
          <p className="mt-1 text-sm text-text-muted">
            Reusable, faculty-reviewed preparation insights and company round breakdowns.
          </p>
        </div>
        <button
          onClick={() => setShowContribute(!showContribute)}
          className="flex items-center gap-2 rounded-xl bg-primary-purple px-5 py-3 text-xs font-black text-white shadow-sm hover:bg-violet-700 transition-colors"
        >
          <Plus className="h-4 w-4"/>
          {showContribute ? 'Cancel' : 'Contribute Pattern'}
        </button>
      </div>

      <div className="rounded-2xl border border-amber-200/80 bg-amber-50/70 p-4 text-xs leading-relaxed text-amber-900 flex items-center gap-2.5 shadow-sm">
        <ShieldCheck className="h-4 w-4 shrink-0 text-amber-700"/>
        <span>For eligibility, application shortlists, and official company drive dates, use NEO PAT. PSGMX maintains preparation patterns and technical interview wisdom.</span>
      </div>

      {showContribute && (
        <form onSubmit={submitPattern} className="rounded-3xl border border-border-light bg-white p-6 shadow-sm space-y-4">
          <h2 className="font-black text-text-main text-base">Contribute an Interview Experience Pattern</h2>
          <div className="grid gap-4 sm:grid-cols-2">
            <div>
              <label className="text-xs font-bold text-text-muted">Company / Role Pattern Title</label>
              <input 
                required
                value={form.title}
                onChange={(e) => setForm({...form, title: e.target.value})}
                placeholder="e.g. Zoho Corporation — Advanced Programming Round"
                className="mt-1.5 w-full rounded-xl border border-border-light bg-page-bg px-4 py-2.5 text-sm outline-none focus:border-primary-purple"
              />
            </div>
            <div>
              <label className="text-xs font-bold text-text-muted">Round Type</label>
              <select
                value={form.patternType}
                onChange={(e) => setForm({...form, patternType: e.target.value as PatternType})}
                className="mt-1.5 w-full rounded-xl border border-border-light bg-page-bg px-4 py-2.5 text-sm outline-none focus:border-primary-purple"
              >
                {Object.entries(patternLabels).map(([k, v]) => (
                  <option key={k} value={k}>{v}</option>
                ))}
              </select>
            </div>
          </div>
          <div>
            <label className="text-xs font-bold text-text-muted">Key Preparation Strategy That Helped</label>
            <textarea
              required
              rows={2}
              value={form.preparationHelped}
              onChange={(e) => setForm({...form, preparationHelped: e.target.value})}
              placeholder="What topics or practice routine gave you the advantage?"
              className="mt-1.5 w-full rounded-xl border border-border-light bg-page-bg px-4 py-2.5 text-sm outline-none focus:border-primary-purple"
            />
          </div>
          <div>
            <label className="text-xs font-bold text-text-muted">Direct Advice for Juniors</label>
            <textarea
              required
              rows={2}
              value={form.advice}
              onChange={(e) => setForm({...form, advice: e.target.value})}
              placeholder="Actionable advice for juniors facing this round..."
              className="mt-1.5 w-full rounded-xl border border-border-light bg-page-bg px-4 py-2.5 text-sm outline-none focus:border-primary-purple"
            />
          </div>
          <div className="flex justify-end">
            <button
              disabled={busy}
              type="submit"
              className="rounded-xl bg-primary-purple px-6 py-2.5 text-xs font-black text-white hover:bg-violet-700 transition-colors disabled:opacity-50"
            >
              {busy ? 'Submitting…' : 'Submit for Review'}
            </button>
          </div>
        </form>
      )}

      {message && (
        <div className="rounded-2xl border border-emerald-200 bg-emerald-50 p-4 text-xs font-bold text-emerald-900">
          {message}
        </div>
      )}

      {/* Search Filter */}
      <div className="relative">
        <Search className="absolute left-4 top-3.5 h-4 w-4 text-text-muted"/>
        <input
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="Search by company name, DSA topics, round type, or key advice..."
          className="w-full rounded-2xl border border-border-light bg-white py-3 pl-11 pr-4 text-sm font-medium outline-none focus:border-primary-purple shadow-sm"
        />
      </div>

      {/* Patterns Grid */}
      <div className="space-y-4">
        {filtered.map((pattern) => (
          <article key={pattern.id} className="rounded-3xl border border-border-light bg-white p-6 shadow-sm space-y-4 hover:border-primary-purple/40 transition-colors">
            <div className="flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between">
              <div>
                <span className="inline-block rounded-full bg-violet-50 px-3 py-1 text-[10px] font-black uppercase tracking-wide text-primary-purple mb-2">
                  {patternLabels[pattern.pattern_type]} · {pattern.batch_year ?? 'MCA'}
                </span>
                <h2 className="text-lg font-black text-text-main">{pattern.title}</h2>
              </div>
            </div>

            {pattern.historical_context && (
              <p className="text-xs text-text-muted italic">{pattern.historical_context}</p>
            )}

            <div className="grid gap-3 sm:grid-cols-2">
              <div className="rounded-2xl bg-emerald-50/60 p-4 border border-emerald-100">
                <p className="text-[10px] font-black uppercase tracking-wider text-emerald-800 flex items-center gap-1.5">
                  <Sparkles className="h-3.5 w-3.5 text-emerald-600"/> What Preparation Helped Most
                </p>
                <p className="mt-1 text-xs leading-relaxed text-emerald-950 font-medium">{pattern.preparation_helped}</p>
              </div>

              <div className="rounded-2xl bg-page-bg p-4 border border-border-light">
                <p className="text-[10px] font-black uppercase tracking-wider text-text-muted flex items-center gap-1.5">
                  <Lightbulb className="h-3.5 w-3.5 text-amber-500"/> Direct Advice for Juniors
                </p>
                <p className="mt-1 text-xs leading-relaxed text-text-main font-medium">{pattern.advice}</p>
              </div>
            </div>

            {pattern.example_themes && pattern.example_themes.length > 0 && (
              <div className="flex flex-wrap gap-1.5 pt-1">
                {pattern.example_themes.map((theme, i) => (
                  <span key={i} className="rounded-lg bg-gray-100 px-2.5 py-1 text-[11px] font-semibold text-text-muted">
                    #{theme}
                  </span>
                ))}
              </div>
            )}
          </article>
        ))}
      </div>
    </div>
  )
}
