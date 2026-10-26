'use client'

import React from 'react'
import {
  AlertCircle,
  Building2,
  Calendar,
  CheckCircle2,
  Code2,
  Cpu,
  Layers,
  Lightbulb,
  Loader2,
  MessageSquare,
  Search,
  ShieldCheck,
  Sparkles,
  Users,
  X,
  ArrowRight,
} from 'lucide-react'
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

const TYPE_CONFIG: Record<
  string,
  { label: string; badgeClass: string; icon: React.ComponentType<{ className?: string }> }
> = {
  coding_round: {
    label: 'Coding Round',
    badgeClass: 'bg-emerald-50 text-emerald-700 border-emerald-200',
    icon: Code2,
  },
  technical_deep_dive: {
    label: 'Technical Deep Dive',
    badgeClass: 'bg-indigo-50 text-indigo-700 border-indigo-200',
    icon: Cpu,
  },
  aptitude_screening: {
    label: 'Aptitude Screening',
    badgeClass: 'bg-amber-50 text-amber-800 border-amber-200',
    icon: Layers,
  },
  behavioural: {
    label: 'Behavioural / HR',
    badgeClass: 'bg-rose-50 text-rose-700 border-rose-200',
    icon: Users,
  },
  group_discussion: {
    label: 'Group Discussion',
    badgeClass: 'bg-cyan-50 text-cyan-700 border-cyan-200',
    icon: MessageSquare,
  },
  fyp_discussion: {
    label: 'FYP Discussion',
    badgeClass: 'bg-purple-50 text-purple-700 border-purple-200',
    icon: Sparkles,
  },
  general: {
    label: 'General Drive',
    badgeClass: 'bg-slate-100 text-slate-700 border-slate-200',
    icon: Building2,
  },
}

type ParsedRound = {
  step: number
  title: string
  details: string
}

function parseSelectionRounds(text: string | null): { rounds: ParsedRound[]; narrative: string } {
  if (!text) return { rounds: [], narrative: '' }

  let clean = text
  // Extract JSON structure if legacy record
  const jsonMatch = clean.match(/Recorded selection structure:\s*(\[.*?\])\./)
  if (jsonMatch) {
    try {
      const parsed = JSON.parse(jsonMatch[1])
      if (parsed[0]?.description && parsed[0].description !== '-') {
        clean = parsed[0].description
      }
    } catch {}
  }

  // Strip JSON brackets if any remain
  clean = clean.replace(/\[\s*\{\s*"name".*?"description":\s*"(.*?)"\s*\}\s*\]/g, '$1')
  clean = clean.replace(/Archived department (record|placement record).*?\n+/i, '')
  clean = clean.replace(/\*Note: This represents historical interview intelligence.*?\*/i, '')
  clean = clean.trim()

  const rounds: ParsedRound[] = []

  // Check for markdown bullet list with "Round X:" or "- **Round X"
  const bulletMatches = [...clean.matchAll(/[-*]\s+\*\*Round\s*(\d+)[:\s]*(.*?)\*\*\s*[—–-]?\s*([^\n]+)/gi)]
  if (bulletMatches.length > 0) {
    for (const m of bulletMatches) {
      rounds.push({
        step: parseInt(m[1], 10),
        title: m[2].trim() || `Round ${m[1]}`,
        details: m[3].trim(),
      })
    }
  }

  // If no markdown bullets, look for textual round delimiters: "First Round:", "1st round", "Round 1:", etc.
  if (rounds.length === 0) {
    const delimiters = /(?:(?:First|Second|Third|Fourth|Fifth|Final|\b1st|\b2nd|\b3rd|\b4th|\b5th|Round\s*\d+)\s*(?:Round|Interview)?\s*[:\-\—]?)/gi
    const parts = clean.split(delimiters).map((s) => s.trim()).filter(Boolean)
    const matches = clean.match(delimiters)

    if (matches && matches.length > 0 && parts.length >= matches.length) {
      matches.forEach((label, idx) => {
        const rawTitle = label.replace(/[:\-\—]/g, '').trim()
        rounds.push({
          step: idx + 1,
          title: rawTitle,
          details: parts[idx] || '',
        })
      })
    }
  }

  // If still empty and clean text exists, check comma-separated parenthesized list like "3 (OA, Technical Interview, HR interview)"
  if (rounds.length === 0) {
    const parenMatch = clean.match(/\d+\s*[-–]?\s*\((.*?)\)/)
    if (parenMatch) {
      const subItems = parenMatch[1].split(/[,;]/).map((s) => s.trim()).filter(Boolean)
      subItems.forEach((item, idx) => {
        rounds.push({
          step: idx + 1,
          title: `Round ${idx + 1}`,
          details: item,
        })
      })
    }
  }

  return { rounds, narrative: clean }
}

export default function InterviewPatternsPage() {
  const supabase = React.useMemo(() => createClient(), [])
  const [patterns, setPatterns] = React.useState<Pattern[]>([])
  const [query, setQuery] = React.useState('')
  const [selectedType, setSelectedType] = React.useState<string | null>(null)
  const [selectedBatch, setSelectedBatch] = React.useState<string | null>(null)
  const [active, setActive] = React.useState<Pattern | null>(null)
  const [loading, setLoading] = React.useState(true)
  const [error, setError] = React.useState('')

  const load = React.useCallback(async () => {
    setLoading(true)
    setError('')
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

  React.useEffect(() => {
    void load()
  }, [load])

  // Extract distinct types & batches
  const availableTypes = React.useMemo(() => [...new Set(patterns.map((p) => p.pattern_type))].filter(Boolean), [patterns])
  const availableBatches = React.useMemo(() => [...new Set(patterns.map((p) => p.batch_year))].filter(Boolean).sort(), [patterns])
  const uniqueCompaniesCount = React.useMemo(() => new Set(patterns.map((p) => p.company_name).filter(Boolean)).size, [patterns])

  const visible = React.useMemo(() => {
    const q = query.toLowerCase().trim()
    return patterns.filter((p) => {
      const matchQuery =
        !q ||
        p.title.toLowerCase().includes(q) ||
        (p.company_name ?? '').toLowerCase().includes(q) ||
        (p.preparation_helped ?? '').toLowerCase().includes(q) ||
        (p.example_themes ?? []).some((t) => t.toLowerCase().includes(q))

      const matchType = !selectedType || p.pattern_type === selectedType
      const matchBatch = !selectedBatch || p.batch_year === selectedBatch

      return matchQuery && matchType && matchBatch
    })
  }, [patterns, query, selectedType, selectedBatch])

  const parsedActiveRounds = React.useMemo(() => {
    if (!active?.historical_context) return { rounds: [], narrative: '' }
    return parseSelectionRounds(active.historical_context)
  }, [active])

  if (loading) {
    return (
      <div className="grid min-h-72 place-items-center">
        <div className="flex flex-col items-center gap-3">
          <Loader2 className="h-8 w-8 animate-spin text-primary-purple" />
          <p className="text-sm font-semibold text-text-muted">Loading authentic interview patterns...</p>
        </div>
      </div>
    )
  }

  return (
    <div className="mx-auto max-w-7xl space-y-8 pb-16 px-2 sm:px-4">
      {/* Header Banner */}
      <header className="rounded-3xl border border-border-light bg-gradient-to-br from-white via-white to-violet-50/40 p-6 sm:p-8 shadow-xs">
        <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-6">
          <div className="space-y-2">
            <div className="inline-flex items-center gap-2 rounded-full bg-primary-purple/10 px-3 py-1 text-xs font-black text-primary-purple">
              <Building2 className="h-3.5 w-3.5" />
              Department Placement Intelligence Archive
            </div>
            <h1 className="text-2xl sm:text-3xl font-black text-slate-900 tracking-tight">
              Interview Pattern Library
            </h1>
            <p className="text-sm text-text-muted max-w-2xl leading-relaxed">
              Explore authentic, faculty-verified selection structures, coding round expectations, and senior takeaways
              contributed across {uniqueCompaniesCount} placement drives.
            </p>
          </div>

          {/* Quick Metrics */}
          <div className="grid grid-cols-3 gap-3 shrink-0">
            <div className="rounded-2xl border border-border-light bg-white/90 p-3.5 text-center shadow-xs">
              <p className="text-2xl font-black text-primary-purple">{patterns.length}</p>
              <p className="text-[11px] font-bold text-text-muted mt-0.5">Patterns</p>
            </div>
            <div className="rounded-2xl border border-border-light bg-white/90 p-3.5 text-center shadow-xs">
              <p className="text-2xl font-black text-emerald-600">{uniqueCompaniesCount}</p>
              <p className="text-[11px] font-bold text-text-muted mt-0.5">Companies</p>
            </div>
            <div className="rounded-2xl border border-border-light bg-white/90 p-3.5 text-center shadow-xs">
              <p className="text-2xl font-black text-indigo-600">{availableBatches.length}</p>
              <p className="text-[11px] font-bold text-text-muted mt-0.5">Batches</p>
            </div>
          </div>
        </div>

        {/* NEO PAT Disclaimer */}
        <div className="mt-6 flex items-start gap-3 rounded-2xl border border-amber-200/80 bg-amber-50/80 p-4 text-xs font-medium leading-relaxed text-amber-900">
          <ShieldCheck className="h-5 w-5 text-amber-700 shrink-0 mt-0.5" />
          <span>
            <strong>Official Placement Notice:</strong> These entries are historical accounts from alumni and seniors to aid skill preparation.
            Official campus drives, eligibility criteria, applications, and student shortlists stay exclusively in NEO PAT.
          </span>
        </div>
      </header>

      {error && (
        <div className="flex items-center justify-between rounded-2xl border border-red-200 bg-red-50 p-4 text-sm font-semibold text-red-700">
          <span>{error}</span>
          <button onClick={() => void load()} className="underline hover:text-red-900 font-bold">
            Retry
          </button>
        </div>
      )}

      {/* Search & Filter Bar */}
      <div className="space-y-4">
        <div className="flex flex-col sm:flex-row gap-3">
          <div className="relative flex-1">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400" />
            <input
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              className="w-full rounded-2xl border border-border-light bg-white py-3 pl-11 pr-4 text-sm outline-none transition shadow-xs focus:border-primary-purple focus:ring-2 focus:ring-primary-purple/10"
              placeholder="Search companies, coding rounds, topics, or technologies (e.g. Amazon, DBMS, Machine Test)..."
            />
            {query && (
              <button
                onClick={() => setQuery('')}
                className="absolute right-3.5 top-1/2 -translate-y-1/2 p-1 rounded-full text-slate-400 hover:text-slate-600"
              >
                <X className="h-3.5 w-3.5" />
              </button>
            )}
          </div>

          {/* Batch Selector */}
          <div className="flex gap-1.5 p-1 rounded-2xl border border-border-light bg-white shadow-xs shrink-0">
            <button
              onClick={() => setSelectedBatch(null)}
              className={`rounded-xl px-3 py-1.5 text-xs font-bold transition ${
                !selectedBatch ? 'bg-primary-purple text-white shadow-xs' : 'text-slate-600 hover:bg-slate-50'
              }`}
            >
              All Batches
            </button>
            {availableBatches.map((b) => (
              <button
                key={b}
                onClick={() => setSelectedBatch(selectedBatch === b ? null : b)}
                className={`rounded-xl px-3 py-1.5 text-xs font-bold transition ${
                  selectedBatch === b ? 'bg-primary-purple text-white shadow-xs' : 'text-slate-600 hover:bg-slate-50'
                }`}
              >
                {b}
              </button>
            ))}
          </div>
        </div>

        {/* Pattern Category Filter Chips */}
        <div className="flex flex-wrap items-center gap-2 pt-1">
          <button
            onClick={() => setSelectedType(null)}
            className={`rounded-xl px-3.5 py-1.5 text-xs font-bold transition border ${
              !selectedType
                ? 'bg-slate-900 text-white border-slate-900 shadow-xs'
                : 'bg-white text-slate-600 border-border-light hover:bg-slate-50'
            }`}
          >
            All Categories ({patterns.length})
          </button>
          {availableTypes.map((typeKey) => {
            const conf = TYPE_CONFIG[typeKey] || { label: typeKey, badgeClass: '', icon: Building2 }
            const Icon = conf.icon
            const isSelected = selectedType === typeKey
            const count = patterns.filter((p) => p.pattern_type === typeKey).length
            return (
              <button
                key={typeKey}
                onClick={() => setSelectedType(isSelected ? null : typeKey)}
                className={`inline-flex items-center gap-1.5 rounded-xl px-3 py-1.5 text-xs font-bold transition border ${
                  isSelected
                    ? 'bg-primary-purple text-white border-primary-purple shadow-xs'
                    : 'bg-white text-slate-700 border-border-light hover:border-slate-300'
                }`}
              >
                <Icon className="h-3.5 w-3.5" />
                {conf.label} ({count})
              </button>
            )
          })}
        </div>
      </div>

      {/* Grid of Pattern Cards */}
      <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
        {visible.map((pattern) => {
          const conf = TYPE_CONFIG[pattern.pattern_type] || {
            label: pattern.pattern_type,
            badgeClass: 'bg-slate-100 text-slate-700 border-slate-200',
            icon: Building2,
          }
          const Icon = conf.icon
          const companyName = pattern.company_name || pattern.title.split('·')[0].trim()

          return (
            <button
              key={pattern.id}
              onClick={() => setActive(pattern)}
              className="group flex flex-col justify-between rounded-3xl border border-border-light bg-white p-6 text-left shadow-xs transition-all duration-200 hover:-translate-y-1 hover:border-primary-purple/40 hover:shadow-md"
            >
              <div className="space-y-3.5 w-full">
                {/* Card Top Badges */}
                <div className="flex flex-wrap items-center justify-between gap-2">
                  <span
                    className={`inline-flex items-center gap-1.5 rounded-full border px-2.5 py-0.5 text-[11px] font-bold ${conf.badgeClass}`}
                  >
                    <Icon className="h-3 w-3" />
                    {conf.label}
                  </span>
                  {pattern.batch_year && (
                    <span className="rounded-full bg-slate-100 px-2 py-0.5 text-[10px] font-black text-slate-600">
                      {pattern.batch_year}
                    </span>
                  )}
                </div>

                {/* Company Name & Title */}
                <div>
                  <h2 className="text-base font-black text-slate-900 group-hover:text-primary-purple transition-colors leading-snug line-clamp-1">
                    {companyName}
                  </h2>
                  <p className="mt-0.5 text-[11px] font-bold text-slate-400">
                    Archived Selection Pattern
                  </p>
                </div>

                {/* Unique Preparation Takeaway */}
                <p className="text-xs leading-5 text-slate-600 line-clamp-3">
                  {pattern.preparation_helped}
                </p>

                {/* Key Theme Tags */}
                {!!pattern.example_themes?.length && (
                  <div className="flex flex-wrap gap-1.5 pt-1">
                    {pattern.example_themes.slice(0, 3).map((theme) => (
                      <span
                        key={theme}
                        className="rounded-md bg-slate-50 border border-slate-150 px-2 py-0.5 text-[10px] font-semibold text-slate-600"
                      >
                        #{theme}
                      </span>
                    ))}
                    {pattern.example_themes.length > 3 && (
                      <span className="rounded-md bg-slate-50 px-1.5 py-0.5 text-[10px] font-bold text-slate-400">
                        +{pattern.example_themes.length - 3}
                      </span>
                    )}
                  </div>
                )}
              </div>

              {/* Card Footer Hint */}
              <div className="mt-5 flex items-center justify-between border-t border-slate-100 pt-3.5 text-xs font-bold text-slate-400 group-hover:text-primary-purple transition-colors">
                <span>View Full Rounds & Tips</span>
                <ArrowRight className="h-3.5 w-3.5 transform group-hover:translate-x-1 transition-transform" />
              </div>
            </button>
          )
        })}

        {!visible.length && (
          <div className="col-span-full rounded-3xl border border-dashed border-border-light bg-white p-12 text-center">
            <AlertCircle className="mx-auto h-8 w-8 text-slate-400 mb-2" />
            <p className="text-sm font-bold text-slate-700">No interview patterns match your filter</p>
            <p className="text-xs text-text-muted mt-1">Try clearing your search query or switching categories.</p>
            <button
              onClick={() => {
                setQuery('')
                setSelectedType(null)
                setSelectedBatch(null)
              }}
              className="mt-4 rounded-xl bg-slate-100 px-4 py-2 text-xs font-bold text-slate-700 hover:bg-slate-200 transition"
            >
              Reset Filters
            </button>
          </div>
        )}
      </div>

      {/* Modal: View Full Pattern */}
      {active && (
        <div className="fixed inset-0 z-50 overflow-y-auto bg-slate-950/60 backdrop-blur-xs p-3 sm:p-6 md:p-8 flex items-center justify-center animate-in fade-in duration-150">
          <article className="w-[94vw] sm:max-w-4xl md:max-w-5xl max-h-[92vh] flex flex-col rounded-3xl bg-white shadow-2xl border border-slate-200 overflow-hidden">
            {/* Modal Header */}
            <div className="flex items-start justify-between gap-4 p-6 sm:p-8 border-b border-border-light shrink-0 bg-gradient-to-r from-white via-slate-50/50 to-white">
              <div className="space-y-2 max-w-3xl">
                <div className="flex flex-wrap items-center gap-2">
                  {active.company_name && (
                    <span className="inline-flex items-center gap-1.5 rounded-full bg-primary-purple/10 px-3 py-1 text-xs font-black text-primary-purple">
                      <Building2 className="h-3.5 w-3.5" />
                      {active.company_name}
                    </span>
                  )}
                  {active.batch_year && (
                    <span className="rounded-full bg-slate-100 px-2.5 py-0.5 text-xs font-bold text-slate-700">
                      Batch {active.batch_year}
                    </span>
                  )}
                  {active.pattern_type && (
                    <span
                      className={`inline-flex items-center gap-1 rounded-full border px-2.5 py-0.5 text-xs font-bold ${
                        TYPE_CONFIG[active.pattern_type]?.badgeClass || 'bg-slate-100 text-slate-700'
                      }`}
                    >
                      {TYPE_CONFIG[active.pattern_type]?.label || active.pattern_type}
                    </span>
                  )}
                </div>

                <h2 className="text-xl sm:text-2xl font-black text-slate-900 leading-tight">
                  {active.company_name || active.title}
                </h2>
                <p className="flex items-center gap-2 text-xs text-text-muted">
                  <Calendar className="h-3.5 w-3.5" />
                  Archived record •{' '}
                  {new Intl.DateTimeFormat('en-IN', { dateStyle: 'medium' }).format(new Date(active.created_at))}
                </p>
              </div>

              <button
                onClick={() => setActive(null)}
                className="p-2 rounded-2xl hover:bg-slate-100 text-slate-400 hover:text-slate-700 transition"
                aria-label="Close"
              >
                <X className="h-5 w-5" />
              </button>
            </div>

            {/* Modal Body */}
            <div className="flex-1 overflow-y-auto p-6 sm:p-8 space-y-6 custom-scrollbar">
              {/* Structured Selection Process */}
              <div>
                <h3 className="flex items-center gap-2 text-base font-black text-slate-900 mb-3">
                  <Layers className="h-4 w-4 text-primary-purple" />
                  Recorded Selection Structure & Rounds
                </h3>

                {parsedActiveRounds.rounds.length > 0 ? (
                  <div className="grid gap-3 sm:grid-cols-2">
                    {parsedActiveRounds.rounds.map((round) => (
                      <div
                        key={round.step}
                        className="rounded-2xl border border-border-light bg-slate-50/70 p-4 transition hover:bg-white hover:shadow-xs"
                      >
                        <div className="flex items-center gap-2 mb-1.5">
                          <span className="flex h-6 w-6 items-center justify-center rounded-lg bg-primary-purple text-[11px] font-black text-white shrink-0">
                            {round.step}
                          </span>
                          <span className="text-sm font-black text-slate-900 truncate">{round.title}</span>
                        </div>
                        <p className="text-xs text-slate-600 leading-relaxed pl-8">
                          {round.details || 'Technical discussion & assessment round.'}
                        </p>
                      </div>
                    ))}
                  </div>
                ) : (
                  <div className="rounded-2xl border border-border-light bg-slate-50/70 p-4 text-sm leading-relaxed text-slate-700 whitespace-pre-wrap">
                    {parsedActiveRounds.narrative || active.historical_context}
                  </div>
                )}
              </div>

              {/* What preparation helped */}
              <div className="rounded-2xl border border-emerald-200 bg-emerald-50/70 p-5">
                <p className="flex items-center gap-2 text-xs font-black text-emerald-900 uppercase tracking-wider">
                  <CheckCircle2 className="h-4 w-4 text-emerald-600" />
                  What Preparation Strategy Helped
                </p>
                <p className="mt-2 text-sm leading-relaxed text-emerald-950 font-medium">
                  {active.preparation_helped}
                </p>
              </div>

              {/* Mistakes to avoid */}
              {active.mistakes && (
                <div className="rounded-2xl border border-rose-200 bg-rose-50/70 p-5">
                  <p className="flex items-center gap-2 text-xs font-black text-rose-900 uppercase tracking-wider">
                    <AlertCircle className="h-4 w-4 text-rose-600" />
                    Common Pitfalls & Mistakes to Avoid
                  </p>
                  <p className="mt-2 text-sm leading-relaxed text-rose-950 font-medium">
                    {active.mistakes}
                  </p>
                </div>
              )}

              {/* Advice */}
              <div className="rounded-2xl border border-violet-200 bg-violet-50/70 p-5">
                <p className="flex items-center gap-2 text-xs font-black text-primary-purple uppercase tracking-wider">
                  <Lightbulb className="h-4 w-4 text-primary-purple" />
                  Senior & Faculty Advice
                </p>
                <p className="mt-2 text-sm leading-relaxed text-slate-900 font-medium">
                  {active.advice}
                </p>
              </div>

              {/* Themes / Tags */}
              {!!active.example_themes?.length && (
                <div>
                  <p className="text-xs font-bold text-slate-400 mb-2">Relevant Themes & Topics</p>
                  <div className="flex flex-wrap gap-2">
                    {active.example_themes.map((theme) => (
                      <span
                        key={theme}
                        className="rounded-xl border border-slate-200 bg-white px-3 py-1 text-xs font-semibold text-slate-700 shadow-2xs"
                      >
                        #{theme}
                      </span>
                    ))}
                  </div>
                </div>
              )}
            </div>

            {/* Modal Footer */}
            <div className="flex items-center justify-between p-4 px-6 border-t border-border-light bg-slate-50 shrink-0 text-xs text-text-muted">
              <span>Historical intelligence • Department of Computer Applications</span>
              <button
                onClick={() => setActive(null)}
                className="rounded-xl bg-white border border-border-light px-4 py-1.5 font-bold text-slate-700 hover:bg-slate-100 transition shadow-2xs"
              >
                Close
              </button>
            </div>
          </article>
        </div>
      )}
    </div>
  )
}
