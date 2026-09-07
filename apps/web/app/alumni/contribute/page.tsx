'use client'

import React, { useState, useEffect, useCallback, useMemo } from 'react'
import {
  CheckCircle2,
  Clock3,
  FilePenLine,
  PenLine,
  Send,
  ShieldCheck,
  Sparkles,
  Loader2,
} from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { getCurrentProfile } from '@/lib/current-profile'
import { useUI } from '@/components/providers/ui-provider'

type Submission = { id: string; title: string; kind: string; status: string; updatedAt: string }
type Mode = 'interview_pattern' | 'technical_guide' | 'career_transition' | 'fyp_lesson' | 'communication_advice'

const modeLabels: Record<Mode, string> = {
  interview_pattern: 'Interview Pattern',
  technical_guide: 'Technical Guide',
  career_transition: 'Career Transition',
  fyp_lesson: 'FYP Lesson',
  communication_advice: 'Communication Advice',
}

export default function AlumniContributePage() {
  const supabase = useMemo(() => createClient(), [])
  const { showToast } = useUI()
  const [submissions, setSubmissions] = useState<Submission[]>([])
  const [mode, setMode] = useState<Mode>('interview_pattern')
  const [title, setTitle] = useState('')
  const [context, setContext] = useState('')
  const [helped, setHelped] = useState('')
  const [mistakes, setMistakes] = useState('')
  const [advice, setAdvice] = useState('')
  const [themes, setThemes] = useState('')
  const [loading, setLoading] = useState(true)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')

  const load = useCallback(async () => {
    setLoading(true)
    setError('')
    try {
      const me = await getCurrentProfile(supabase)
      if (!me) throw new Error('Your alumni profile could not be loaded.')
      const [patternResult, articleResult] = await Promise.all([
        supabase
          .from('interview_patterns')
          .select('id,title,approval_status,updated_at')
          .eq('author_id', me.id)
          .order('updated_at', { ascending: false }),
        supabase
          .from('knowledge_brain_articles')
          .select('id,title,approval_status,updated_at,source')
          .eq('author_id', me.id)
          .order('updated_at', { ascending: false }),
      ])
      if (patternResult.error) throw patternResult.error
      if (articleResult.error) throw articleResult.error

      setSubmissions([
        ...(patternResult.data ?? []).map((item) => ({
          id: item.id,
          title: item.title,
          kind: 'Interview Pattern',
          status: item.approval_status,
          updatedAt: item.updated_at,
        })),
        ...(articleResult.data ?? [])
          .filter((item) => !item.source?.startsWith('interview_pattern:'))
          .map((item) => ({
            id: item.id,
            title: item.title,
            kind: 'Knowledge Guide',
            status: item.approval_status,
            updatedAt: item.updated_at,
          })),
      ].sort((a, b) => new Date(b.updatedAt).getTime() - new Date(a.updatedAt).getTime()))
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : 'Your contributions could not be loaded.')
    } finally {
      setLoading(false)
    }
  }, [supabase])

  useEffect(() => {
    void load()
  }, [load])

  async function submit(event: React.FormEvent) {
    event.preventDefault()
    setBusy(true)
    setError('')
    try {
      const me = await getCurrentProfile(supabase)
      if (!me) throw new Error('Your alumni profile could not be loaded.')
      const batchYear = me.reg_no?.match(/^\d{2}MX/)?.[0] ?? null

      if (mode === 'interview_pattern') {
        const { error: submitError } = await supabase.from('interview_patterns').insert({
          author_id: me.id,
          title: title.trim(),
          pattern_type: 'general',
          historical_context: context.trim() || null,
          preparation_helped: helped.trim(),
          mistakes: mistakes.trim() || null,
          example_themes: themes.split(',').map((item) => item.trim()).filter(Boolean),
          advice: advice.trim(),
          batch_year: batchYear,
          approval_status: 'pending',
        })
        if (submitError) throw submitError
      } else {
        const content = [
          context,
          helped && `What helped:\n${helped}`,
          mistakes && `Mistakes and lessons:\n${mistakes}`,
          advice && `Advice:\n${advice}`,
        ]
          .filter(Boolean)
          .join('\n\n')

        const { error: submitError } = await supabase.from('knowledge_brain_articles').insert({
          author_id: me.id,
          title: title.trim(),
          summary: advice.trim().slice(0, 300) || context.trim().slice(0, 300),
          content,
          tags: [mode, ...themes.split(',').map((item) => item.trim()).filter(Boolean)],
          source: 'alumni_contribution',
          batch_year: batchYear,
          approval_status: 'pending',
        })
        if (submitError) throw submitError
      }

      setTitle('')
      setContext('')
      setHelped('')
      setMistakes('')
      setAdvice('')
      setThemes('')
      showToast('Contribution submitted for faculty review!', 'success')
      await load()
    } catch (cause) {
      const msg = cause instanceof Error ? cause.message : 'Your contribution could not be submitted.'
      setError(msg)
      showToast(msg, 'error')
    } finally {
      setBusy(false)
    }
  }

  return (
    <div className="mx-auto max-w-6xl space-y-7 pb-12">
      <header>
        <div className="mb-2 flex items-center gap-2 text-xs font-black uppercase tracking-[.16em] text-primary-purple">
          <PenLine className="h-4 w-4" /> Give Back to MX
        </div>
        <h1 className="text-3xl font-black tracking-tight text-text-main">Contribute Knowledge</h1>
        <p className="mt-2 max-w-3xl text-sm leading-6 text-text-muted">
          Turn your lived interview experiences and industry lessons into reviewed guides for juniors.
        </p>
      </header>

      <div className="flex gap-3 rounded-2xl border border-amber-200 bg-amber-50/70 p-4 text-xs font-semibold leading-5 text-amber-900">
        <ShieldCheck className="mt-0.5 h-5 w-5 shrink-0 text-amber-700" />
        <span>
          Do not include proprietary codebase snippets, confidential NDA questions, or claims about current active placement drives. NEO PAT remains the official placement drive portal.
        </span>
      </div>

      {error && (
        <div role="alert" className="rounded-2xl border border-red-200 bg-red-50 p-4 text-sm font-bold text-red-700">
          {error}
        </div>
      )}

      <div className="grid gap-6 xl:grid-cols-[1.3fr_.7fr]">
        <form onSubmit={submit} className="space-y-5 rounded-3xl border border-border-light bg-white p-6 md:p-8 shadow-sm">
          <div>
            <h2 className="text-lg font-black text-text-main">Guided Contribution Form</h2>
            <p className="mt-1 text-xs text-text-muted">Structured insights remain valuable across years and batches.</p>
          </div>

          <div>
            <span className="block text-xs font-bold text-text-muted mb-2">Contribution Mode</span>
            <div className="flex flex-wrap gap-2">
              {(Object.keys(modeLabels) as Mode[]).map((value) => (
                <button
                  key={value}
                  type="button"
                  onClick={() => setMode(value)}
                  className={`rounded-xl px-3.5 py-2 text-xs font-bold transition-all ${
                    mode === value
                      ? 'bg-primary-purple text-white shadow-sm'
                      : 'bg-page-bg text-text-muted hover:text-text-main'
                  }`}
                >
                  {modeLabels[value]}
                </button>
              ))}
            </div>
          </div>

          <label className="block text-xs font-bold text-text-muted">
            Title
            <input
              required
              minLength={5}
              maxLength={160}
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="e.g. Preparing for Distributed Systems & Core Java Rounds"
              className="mt-2 w-full rounded-xl border border-border-light px-4 py-3 text-sm outline-none focus:border-primary-purple"
            />
          </label>

          <label className="block text-xs font-bold text-text-muted">
            Historical Context / Background
            <textarea
              value={context}
              onChange={(e) => setContext(e.target.value)}
              placeholder="When, for which roles, and why was this knowledge significant?"
              className="mt-2 min-h-24 w-full rounded-xl border border-border-light px-4 py-3 text-sm outline-none focus:border-primary-purple"
            />
          </label>

          <div className="grid gap-4 md:grid-cols-2">
            <label className="text-xs font-bold text-text-muted">
              What Preparation Helped Most
              <textarea
                required
                minLength={20}
                value={helped}
                onChange={(e) => setHelped(e.target.value)}
                placeholder="Books, concepts, mock patterns, key topics..."
                className="mt-2 min-h-32 w-full rounded-xl border border-border-light px-4 py-3 text-sm outline-none focus:border-primary-purple"
              />
            </label>
            <label className="text-xs font-bold text-text-muted">
              Mistakes & Pitfalls to Avoid
              <textarea
                value={mistakes}
                onChange={(e) => setMistakes(e.target.value)}
                placeholder="Common traps, communication gaps, time management..."
                className="mt-2 min-h-32 w-full rounded-xl border border-border-light px-4 py-3 text-sm outline-none focus:border-primary-purple"
              />
            </label>
          </div>

          <label className="block text-xs font-bold text-text-muted">
            Actionable Advice for a Junior
            <textarea
              required
              minLength={20}
              value={advice}
              onChange={(e) => setAdvice(e.target.value)}
              placeholder="Concrete advice you would give yourself if starting again."
              className="mt-2 min-h-28 w-full rounded-xl border border-border-light px-4 py-3 text-sm outline-none focus:border-primary-purple"
            />
          </label>

          <label className="block text-xs font-bold text-text-muted">
            Search Themes & Tags (comma separated)
            <input
              value={themes}
              onChange={(e) => setThemes(e.target.value)}
              placeholder="DBMS, System Design, Java, Final Year Project, Communication"
              className="mt-2 w-full rounded-xl border border-border-light px-4 py-3 text-sm outline-none focus:border-primary-purple"
            />
          </label>

          <button
            disabled={busy}
            type="submit"
            className="flex w-full items-center justify-center gap-2 rounded-xl bg-primary-purple px-5 py-3.5 text-sm font-black text-white shadow-sm hover:bg-deep-violet disabled:opacity-50 transition-colors"
          >
            {busy ? <Loader2 className="h-4 w-4 animate-spin" /> : <Send className="h-4 w-4" />}
            {busy ? 'Submitting…' : 'Submit for Faculty Review'}
          </button>
        </form>

        {/* Review Queue */}
        <section className="space-y-4">
          <div>
            <h2 className="text-lg font-black text-text-main">Your Review Queue</h2>
            <p className="mt-1 text-xs text-text-muted">
              Track pending, approved, and updated submissions in real-time.
            </p>
          </div>

          {loading && <div className="h-40 animate-pulse rounded-3xl bg-white border border-border-light" />}

          {!loading && submissions.length === 0 && (
            <div className="rounded-3xl border border-dashed border-border-light bg-white p-10 text-center">
              <FilePenLine className="mx-auto h-9 w-9 text-primary-purple" />
              <h3 className="mt-4 font-black text-text-main">No contributions submitted yet</h3>
              <p className="mt-2 text-xs leading-5 text-text-muted">
                Your first verified guide can help upcoming batches prepare with confidence.
              </p>
            </div>
          )}

          <div className="space-y-3">
            {submissions.map((item) => (
              <article key={`${item.kind}-${item.id}`} className="rounded-2xl border border-border-light bg-white p-5 shadow-sm">
                <div className="flex items-start gap-3">
                  {item.status === 'approved' ? (
                    <CheckCircle2 className="mt-0.5 h-5 w-5 text-emerald-600 shrink-0" />
                  ) : (
                    <Clock3 className="mt-0.5 h-5 w-5 text-amber-600 shrink-0" />
                  )}
                  <div className="min-w-0 flex-1">
                    <span
                      className={`text-[10px] font-black uppercase tracking-wider px-2 py-0.5 rounded-full ${
                        item.status === 'approved'
                          ? 'bg-emerald-50 text-emerald-700'
                          : 'bg-amber-50 text-amber-700'
                      }`}
                    >
                      {item.kind} · {item.status.replace('_', ' ')}
                    </span>
                    <h3 className="mt-1.5 text-sm font-black text-text-main leading-snug">{item.title}</h3>
                    <p className="mt-2 text-[10px] text-text-muted font-medium">
                      Updated {new Date(item.updatedAt).toLocaleDateString('en-IN', { dateStyle: 'medium' })}
                    </p>
                  </div>
                </div>
              </article>
            ))}
          </div>
        </section>
      </div>
    </div>
  )
}
