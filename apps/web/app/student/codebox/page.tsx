'use client'

import React from 'react'
import Link from 'next/link'
import { CheckCircle2, Clock, Code2, Loader2, Trophy } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { getCurrentProfile } from '@/lib/current-profile'

type Quest = {
  id: string
  slug: string | null
  title: string
  type: string
  difficulty: number
  topic_tags: string[]
  xp_reward: number
  due_at: string | null
}

const DIFFICULTY_LABEL = ['', 'Very Easy', 'Easy', 'Medium', 'Hard', 'Very Hard']

export default function CodeBoxIndexPage() {
  const supabase = React.useMemo(() => createClient(), [])
  const [quests, setQuests] = React.useState<Quest[]>([])
  const [solved, setSolved] = React.useState<Set<string>>(new Set())
  const [loading, setLoading] = React.useState(true)
  const [error, setError] = React.useState('')

  React.useEffect(() => {
    (async () => {
      setLoading(true); setError('')
      try {
        const me = await getCurrentProfile(supabase)
        if (!me?.id) throw new Error('Sign in again to view CodeBox quests.')
        const db = supabase as any
        const [{ data: questRows, error: questError }, { data: submissionRows }] = await Promise.all([
          db.from('quests').select('id,slug,title,type,difficulty,topic_tags,xp_reward,due_at').order('created_at', { ascending: false }).limit(200),
          db.from('code_submissions').select('quest_id').eq('student_id', me.id).eq('is_verified_complete', true),
        ])
        if (questError) throw questError
        setQuests((questRows ?? []) as Quest[])
        setSolved(new Set((submissionRows ?? []).map((row: { quest_id: string }) => row.quest_id)))
      } catch (cause) {
        setError(cause instanceof Error ? cause.message : 'CodeBox quests could not be loaded.')
      } finally {
        setLoading(false)
      }
    })()
  }, [supabase])

  if (loading) return <div className="grid min-h-64 place-items-center"><Loader2 className="h-6 w-6 animate-spin text-primary-purple" /></div>

  return (
    <div className="mx-auto max-w-4xl space-y-6 pb-12">
      <header>
        <h1 className="flex items-center gap-2 text-2xl font-black"><Code2 className="h-6 w-6 text-primary-purple" />CodeBox</h1>
        <p className="mt-1 text-sm text-text-muted">{quests.length} quest{quests.length === 1 ? '' : 's'} open for your batch right now.</p>
      </header>

      {error && <div className="rounded-xl bg-red-50 p-4 text-sm font-bold text-red-700">{error}</div>}

      <div className="grid gap-4 sm:grid-cols-2">
        {quests.map((quest) => {
          const isSolved = solved.has(quest.id)
          return (
            <Link key={quest.id} href={`/student/codebox/${quest.slug || quest.id}`} className="rounded-3xl border border-border-light bg-white p-6 shadow-sm transition hover:border-primary-purple/40">
              <div className="flex flex-wrap items-center gap-2">
                <span className="rounded-full bg-violet-50 px-2 py-1 text-[10px] font-black text-primary-purple">{DIFFICULTY_LABEL[quest.difficulty] || `Level ${quest.difficulty}`}</span>
                <span className="rounded-full bg-page-bg px-2 py-1 text-[10px] font-black capitalize">{quest.type.replace('_', ' ')}</span>
                {isSolved && <span className="inline-flex items-center gap-1 rounded-full bg-emerald-50 px-2 py-1 text-[10px] font-black text-emerald-700"><CheckCircle2 className="h-3 w-3" />Solved</span>}
              </div>
              <h2 className="mt-3 text-base font-black leading-6">{quest.title}</h2>
              <div className="mt-3 flex items-center gap-4 text-[11px] font-bold text-text-muted">
                <span className="inline-flex items-center gap-1"><Trophy className="h-3.5 w-3.5" />{quest.xp_reward} XP</span>
                {quest.due_at && <span className="inline-flex items-center gap-1"><Clock className="h-3.5 w-3.5" />Due {new Intl.DateTimeFormat('en-IN', { dateStyle: 'medium' }).format(new Date(quest.due_at))}</span>}
              </div>
            </Link>
          )
        })}
        {!quests.length && !error && <div className="col-span-full rounded-3xl border border-dashed border-border-light bg-white p-10 text-center text-sm text-text-muted">No quests are open for your batch yet — check back soon.</div>}
      </div>
    </div>
  )
}
