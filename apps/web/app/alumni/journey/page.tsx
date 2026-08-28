'use client'

import React from 'react'
import { Award, BookOpen, Code2, Flame, GraduationCap, Loader2, Target } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { getCurrentProfile } from '@/lib/current-profile'

type Journey = {
  name: string
  batchCode: string
  startYear: number | null
  endYear: number | null
  finalScore: number | null
  bestStreak: number
  leetcodeSolved: number
  examsTaken: number
  articles: number
  joinedAt: string
  lastSnapshot: string | null
}

export default function JourneyPage() {
  const supabase = React.useMemo(() => createClient(), [])
  const [data, setData] = React.useState<Journey | null>(null)
  const [loading, setLoading] = React.useState(true)
  const [error, setError] = React.useState('')

  React.useEffect(() => { void (async () => {
    try {
      const me = await getCurrentProfile(supabase)
      if (!me) throw new Error('Your alumni profile could not be found.')
      const [{ data: batch }, { data: score }, { data: streak }, { data: leetcode }, { count: exams }, { count: articles }] = await Promise.all([
        me.batch_id ? supabase.from('batches').select('batch_code,start_year,end_year').eq('id', me.batch_id).single() : Promise.resolve({ data: null }),
        supabase.from('readiness_scores').select('score,computed_at').eq('user_id', me.id).order('computed_at', { ascending: false }).limit(1).maybeSingle(),
        supabase.from('daily_five_streaks').select('longest_streak').eq('user_id', me.id).maybeSingle(),
        me.leetcode_username ? supabase.from('leetcode_stats').select('total_solved').eq('username', me.leetcode_username).maybeSingle() : Promise.resolve({ data: null }),
        supabase.from('mock_exam_results').select('id', { count: 'exact', head: true }).eq('student_id', me.id).eq('status', 'submitted'),
        supabase.from('knowledge_brain_articles').select('id', { count: 'exact', head: true }).eq('author_id', me.id).eq('approval_status', 'approved'),
      ])
      setData({
        name: me.name,
        batchCode: batch?.batch_code ?? 'MCA',
        startYear: batch?.start_year ?? null,
        endYear: batch?.end_year ?? null,
        finalScore: score?.score ?? null,
        bestStreak: streak?.longest_streak ?? 0,
        leetcodeSolved: leetcode?.total_solved ?? 0,
        examsTaken: exams ?? 0,
        articles: articles ?? 0,
        joinedAt: me.created_at,
        lastSnapshot: score?.computed_at ?? null,
      })
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : 'Your journey could not be loaded.')
    } finally {
      setLoading(false)
    }
  })() }, [supabase])

  if (loading) return <div className="flex min-h-64 items-center justify-center"><Loader2 className="h-6 w-6 animate-spin text-primary-purple"/></div>
  if (!data) return <div className="rounded-2xl border border-amber-200 bg-amber-50 p-6 font-bold">{error}</div>

  const band = data.finalScore === null ? 'Not archived' : data.finalScore >= 80 ? 'Strong' : data.finalScore >= 60 ? 'Building' : data.finalScore >= 40 ? 'Needs attention' : 'At risk'
  const facts = [
    { label: 'Best Daily Five streak', value: `${data.bestStreak} days`, icon: Flame },
    { label: 'LeetCode solved', value: data.leetcodeSolved, icon: Code2 },
    { label: 'Mock exams completed', value: data.examsTaken, icon: Target },
    { label: 'Approved contributions', value: data.articles, icon: BookOpen },
  ]

  return <div className="mx-auto max-w-5xl space-y-7 pb-10">
    <div><h1 className="flex items-center gap-2 text-2xl font-black"><Award className="h-6 w-6 text-primary-purple"/>Your MCA journey</h1><p className="mt-1 text-sm text-text-muted">A read-only record built from the activity PSGMX actually captured.</p></div>
    <section className="grid gap-6 rounded-3xl border border-border-light bg-white p-6 md:grid-cols-[190px_1fr] md:p-8"><div className="flex h-44 w-44 flex-col items-center justify-center justify-self-center rounded-full border-[12px] border-violet-100 bg-page-bg"><p className="text-4xl font-black">{data.finalScore === null ? '—' : Math.round(data.finalScore)}</p><p className="text-xs font-black text-primary-purple">{band}</p></div><div className="flex flex-col justify-center"><p className="text-xs font-black uppercase tracking-[0.18em] text-primary-purple">Archived cohort record</p><h2 className="mt-2 text-3xl font-black">{data.name} · {data.batchCode}</h2><p className="mt-2 text-sm text-text-muted">{data.startYear && data.endYear ? `MCA ${data.startYear}–${data.endYear}` : 'MCA alumni'} · Account active since {new Intl.DateTimeFormat('en-IN', { dateStyle: 'medium' }).format(new Date(data.joinedAt))}</p><p className="mt-4 max-w-xl text-sm leading-6 text-text-muted">{data.lastSnapshot ? `The final available readiness snapshot was recorded on ${new Intl.DateTimeFormat('en-IN', { dateStyle: 'long' }).format(new Date(data.lastSnapshot))}.` : 'No readiness snapshot was captured before graduation. The rest of your real contributions remain available below.'}</p></div></section>
    <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">{facts.map(({ label, value, icon: Icon }) => <div key={label} className="rounded-2xl border border-border-light bg-white p-5"><Icon className="h-5 w-5 text-primary-purple"/><p className="mt-4 text-2xl font-black">{value}</p><p className="mt-1 text-xs font-bold text-text-muted">{label}</p></div>)}</div>
    <section className="rounded-3xl border border-border-light bg-white p-6"><div className="flex items-start gap-3"><GraduationCap className="mt-0.5 h-6 w-6 text-primary-purple"/><div><h2 className="font-black">Your story continues through contribution</h2><p className="mt-2 text-sm leading-6 text-text-muted">Keep your LinkedIn, role and company current, mentor your assigned lineage junior, and document interviews while the details are still fresh. Those actions are more valuable to future batches than a decorative trophy count.</p></div></div></section>
  </div>
}
