'use client'

import React from 'react'
import {
  GraduationCap,
  BookOpen,
  HandHeart,
  Briefcase,
  Users,
  Loader2,
  Building2,
  Linkedin,
  ArrowRight,
  Sparkles,
} from 'lucide-react'
import Link from 'next/link'
import { createClient } from '@/lib/supabase/client'
import { getCurrentProfile } from '@/lib/current-profile'
import { InitialsAvatar } from '@/components/basic/InitialsAvatar'

type AlumniJourney = {
  name: string
  regNo: string
  batchCode: string
  startYear: number | null
  endYear: number | null
  company: string | null
  role: string | null
  linkedin: string | null
  articlesCount: number
  totalViews: number
  lineageCount: number
  postsCount: number
  joinedAt: string
}

export default function JourneyPage() {
  const supabase = React.useMemo(() => createClient(), [])
  const [data, setData] = React.useState<AlumniJourney | null>(null)
  const [loading, setLoading] = React.useState(true)
  const [error, setError] = React.useState('')

  React.useEffect(() => {
    void (async () => {
      try {
        const me = await getCurrentProfile(supabase)
        if (!me) throw new Error('Your alumni profile could not be found.')

        const [
          { data: batch },
          { data: articles },
          { data: lineageRows },
          { count: postsCount },
        ] = await Promise.all([
          me.batch_id
            ? supabase.from('batches').select('batch_code, start_year, end_year').eq('id', me.batch_id).single()
            : Promise.resolve({ data: null }),
          supabase
            .from('knowledge_brain_articles')
            .select('id, view_count')
            .eq('author_id', me.id)
            .eq('approval_status', 'approved'),
          supabase
            .from('lineage_map')
            .select('id')
            .eq('senior_user_id', me.id),
          supabase
            .from('collaboration_posts')
            .select('id', { count: 'exact', head: true })
            .eq('posted_by', me.id),
        ])

        const totalViews = (articles || []).reduce((acc, a) => acc + (a.view_count || 0), 0)

        setData({
          name: me.name,
          regNo: me.reg_no || '',
          batchCode: batch?.batch_code ?? 'MCA',
          startYear: batch?.start_year ?? null,
          endYear: batch?.end_year ?? null,
          company: me.current_company ?? null,
          role: me.current_role_title ?? null,
          linkedin: me.linkedin_url ?? null,
          articlesCount: (articles || []).length,
          totalViews,
          lineageCount: (lineageRows || []).length,
          postsCount: postsCount ?? 0,
          joinedAt: me.created_at,
        })
      } catch (cause) {
        setError(cause instanceof Error ? cause.message : 'Your alumni journey could not be loaded.')
      } finally {
        setLoading(false)
      }
    })()
  }, [supabase])

  if (loading) {
    return (
      <div className="flex min-h-64 items-center justify-center">
        <Loader2 className="h-6 w-6 animate-spin text-primary-purple" />
      </div>
    )
  }
  if (!data) {
    return <div className="rounded-2xl border border-amber-200 bg-amber-50 p-6 font-bold">{error}</div>
  }

  const duration = data.startYear ? (data.startYear <= 2019 ? 3 : 2) : 2
  const durationLabel = `${duration}-Year Master of Computer Applications`

  const milestones = [
    {
      label: 'Approved Knowledge Guides',
      value: data.articlesCount.toString(),
      sub: 'Published in Knowledge Brain',
      icon: BookOpen,
      color: 'bg-primary-purple',
    },
    {
      label: 'Student Reader Views',
      value: data.totalViews.toString(),
      sub: 'Total student engagement',
      icon: Sparkles,
      color: 'bg-electric-blue',
    },
    {
      label: 'Lineage Juniors Guided',
      value: data.lineageCount.toString(),
      sub: 'Connected department juniors',
      icon: Users,
      color: 'bg-emerald-600',
    },
    {
      label: 'Community Posts',
      value: data.postsCount.toString(),
      sub: 'Opportunities & mentorship',
      icon: Briefcase,
      color: 'bg-illus-gold',
    },
  ]

  return (
    <div className="mx-auto max-w-5xl space-y-7 pb-10">
      <div>
        <h1 className="flex items-center gap-2 text-2xl font-black text-text-main">
          <GraduationCap className="h-7 w-7 text-primary-purple" />
          Your MCA Journey & Department Legacy
        </h1>
        <p className="mt-1 text-sm text-text-muted">
          Your verified academic record and ongoing contributions shaping future PSG Tech MCA cohorts.
        </p>
      </div>

      {/* Cohort & Degree Profile Card */}
      <section className="grid gap-6 rounded-3xl border border-border-light bg-white p-6 md:grid-cols-[160px_1fr] md:p-8 shadow-sm">
        <div className="flex h-36 w-36 flex-col items-center justify-center justify-self-center rounded-3xl bg-primary-purple/10 border border-primary-purple/20 text-primary-purple">
          <GraduationCap className="h-14 w-14" />
          <span className="mt-1 text-xs font-black uppercase tracking-wider">{data.batchCode}</span>
        </div>
        <div className="flex flex-col justify-center">
          <div className="flex items-center gap-2">
            <span className="rounded-full bg-emerald-50 px-3 py-1 text-[11px] font-black uppercase text-emerald-700">
              Verified Alumni
            </span>
            {data.startYear && data.endYear && (
              <span className="text-xs font-bold text-text-muted">
                Batch {data.startYear}–{data.endYear}
              </span>
            )}
          </div>
          <h2 className="mt-2 text-3xl font-black text-text-main">
            {data.name} {data.regNo && <span className="text-xl font-bold text-text-muted">({data.regNo})</span>}
          </h2>
          <p className="mt-1 text-sm font-semibold text-text-main">
            {durationLabel}
          </p>
          <p className="mt-2 text-sm text-text-muted">
            {(data.role || data.company)
              ? [data.role, data.company].filter(Boolean).join(' at ')
              : 'PSG Tech Department of Computer Applications'}
            {' · '}
            Alumni member since {new Intl.DateTimeFormat('en-IN', { dateStyle: 'medium' }).format(new Date(data.joinedAt))}
          </p>
        </div>
      </section>

      {/* 4 Impact & Contribution Milestone Cards */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {milestones.map(({ label, value, sub, icon: Icon, color }) => (
          <div key={label} className="rounded-3xl border border-border-light bg-white p-6 shadow-sm flex flex-col justify-between h-[150px]">
            <div className="flex items-center justify-between">
              <span className="text-xs font-bold text-text-muted">{label}</span>
              <div className={`grid h-8 w-8 place-items-center rounded-xl ${color} text-white shadow-sm`}>
                <Icon className="h-4 w-4" />
              </div>
            </div>
            <div>
              <p className="text-3xl font-black text-text-main">{value}</p>
              <p className="mt-0.5 text-[11px] text-text-muted">{sub}</p>
            </div>
          </div>
        ))}
      </div>

      {/* Legacy & Impact Statement */}
      <section className="rounded-3xl border border-border-light bg-white p-6 md:p-8 shadow-sm">
        <div className="flex items-start gap-4">
          <div className="grid h-12 w-12 shrink-0 place-items-center rounded-2xl bg-violet-50 text-primary-purple">
            <HandHeart className="h-6 w-6" />
          </div>
          <div>
            <h2 className="text-lg font-black text-text-main">Giving back through lineage and knowledge</h2>
            <p className="mt-2 text-sm leading-6 text-text-muted">
              As an alumnus of PSG Tech MCA, your guidance bridges the gap between campus and industry.
              By sharing interview patterns, mentoring juniors assigned from your lineage register suffix, and posting opportunities on the Community Board, you directly impact placement readiness across every batch.
            </p>
            <div className="mt-5 flex flex-wrap gap-3">
              <Link
                href="/alumni/contribute"
                className="inline-flex items-center gap-2 rounded-xl bg-primary-purple px-4 py-2.5 text-xs font-bold text-white shadow-sm hover:bg-deep-violet transition"
              >
                <BookOpen className="h-4 w-4" /> Contribute an Article
              </Link>
              <Link
                href="/alumni/lineage"
                className="inline-flex items-center gap-2 rounded-xl bg-page-bg px-4 py-2.5 text-xs font-bold text-text-main hover:bg-border-light transition"
              >
                <Users className="h-4 w-4" /> Check Lineage Tree
              </Link>
            </div>
          </div>
        </div>
      </section>
    </div>
  )
}
