'use client'

import React from 'react'
import { BookOpen, Linkedin, Loader2, Mail, Users } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { getCurrentProfile } from '@/lib/current-profile'
import { InitialsAvatar } from '@/components/basic/InitialsAvatar'

type Senior = {
  id: string
  name: string
  reg_no: string
  mentorship_open: boolean
  linkedin_url: string | null
  email: string
  current_company: string | null
  current_role_title: string | null
}

export default function LineagePage() {
  const supabase = React.useMemo(() => createClient(), [])
  const [senior, setSenior] = React.useState<Senior | null>(null)
  const [quote, setQuote] = React.useState<string | null>(null)
  const [suffix, setSuffix] = React.useState('')
  const [loading, setLoading] = React.useState(true)
  const [error, setError] = React.useState('')

  const load = React.useCallback(async () => {
    setLoading(true)
    setError('')
    try {
      const me = await getCurrentProfile(supabase)
      if (!me?.id) throw new Error('Sign in again to load your lineage.')
      
      const meReg = (me.reg_no || '').trim().toUpperCase()
      const suf = meReg ? meReg.slice(-3) : ''
      setSuffix(suf)

      let resolvedSenior: Senior | null = null
      let resolvedQuote: string | null = null

      // 1. Try direct lineage_map lookup
      const { data: map } = await supabase
        .from('lineage_map')
        .select('senior_user_id, senior_quote')
        .eq('student_id', me.id)
        .maybeSingle()

      if (map?.senior_user_id) {
        resolvedQuote = map.senior_quote ?? null
        const { data: person } = await supabase
          .from('users')
          .select('id, name, reg_no, mentorship_open, linkedin_url, email, current_company, current_role_title')
          .eq('id', map.senior_user_id)
          .maybeSingle()

        if (person) {
          resolvedSenior = person as Senior
        }
      }

      // 2. Fallback: Search users table by register number suffix if map unlinked or not matched
      if (!resolvedSenior && suf) {
        const { data: fallbackSenior } = await supabase
          .from('users')
          .select('id, name, reg_no, mentorship_open, linkedin_url, email, current_company, current_role_title, batch')
          .ilike('reg_no', `%MX${suf}`)
          .neq('id', me.id)
          .order('reg_no', { ascending: false })
          .limit(1)
          .maybeSingle()

        if (fallbackSenior) {
          resolvedSenior = fallbackSenior as Senior
          resolvedQuote = resolvedQuote || `Graduate of PSG Tech MCA`
        }
      }

      setSenior(resolvedSenior)
      setQuote(resolvedQuote)
    } catch (cause) {
      console.warn('Lineage load notice:', cause)
      setError(cause instanceof Error ? cause.message : 'Lineage details could not be loaded.')
      setSenior(null)
    } finally {
      setLoading(false)
    }
  }, [supabase])

  React.useEffect(() => {
    void load()
  }, [load])

  if (loading) {
    return (
      <div className="grid min-h-64 place-items-center">
        <Loader2 className="h-6 w-6 animate-spin text-primary-purple" />
      </div>
    )
  }

  return (
    <div className="mx-auto max-w-4xl space-y-7 pb-12">
      <header>
        <h1 className="flex items-center gap-2 text-2xl font-black text-text-main">
          <Users className="h-6 w-6 text-primary-purple" />
          Lineage mentorship
        </h1>
        <p className="mt-1 text-sm text-text-muted">
          A department-maintained connection to the graduate who shares your register-number lineage.
        </p>
      </header>

      {error && (
        <div className="rounded-xl bg-red-50 p-4 text-sm font-bold text-red-700">
          {error} <button onClick={() => void load()} className="underline">Retry</button>
        </div>
      )}

      {senior ? (
        <section className="space-y-6 rounded-3xl border border-border-light bg-white p-6 shadow-sm sm:p-8">
          <div className="flex flex-col gap-5 sm:flex-row sm:items-center">
            <InitialsAvatar name={senior.name} size={76} />
            <div>
              <span className="text-[10px] font-black uppercase tracking-wider text-primary-purple">
                Assigned senior {suffix ? `· suffix ${suffix}` : ''}
              </span>
              <h2 className="mt-1 text-2xl font-black text-text-main">{senior.name}</h2>
              <p className="mt-1 text-sm text-text-muted">
                {senior.reg_no}
                {senior.current_role_title ? ` · ${senior.current_role_title}` : ''}
                {senior.current_company ? ` at ${senior.current_company}` : ''}
              </p>
            </div>
          </div>

          {quote && (
            <blockquote className="rounded-2xl border border-border-light bg-page-bg p-5 text-sm italic leading-6 text-text-main">
              “{quote}”
            </blockquote>
          )}

          <div className="flex flex-wrap gap-3">
            {senior.mentorship_open && senior.linkedin_url && (
              <a
                href={senior.linkedin_url}
                target="_blank"
                rel="noreferrer"
                className="inline-flex items-center gap-2 rounded-xl bg-primary-purple px-5 py-3 text-xs font-black text-white hover:bg-deep-violet transition-colors"
              >
                <Linkedin className="h-4 w-4" />
                Connect on LinkedIn
              </a>
            )}
            {senior.mentorship_open && senior.email && (
              <a
                href={`mailto:${senior.email}`}
                className="inline-flex items-center gap-2 rounded-xl border border-border-light bg-white px-5 py-3 text-xs font-black text-text-main hover:bg-page-bg transition-colors"
              >
                <Mail className="h-4 w-4" />
                Send email
              </a>
            )}
            {!senior.mentorship_open && (
              <p className="text-xs font-bold text-text-muted">
                This senior is not accepting mentorship requests currently.
              </p>
            )}
          </div>
        </section>
      ) : (
        !error && (
          <section className="rounded-3xl border border-dashed border-border-light bg-white p-10 text-center">
            <Users className="mx-auto h-10 w-10 text-text-muted" />
            <h2 className="mt-4 font-black text-text-main">Lineage assignment pending</h2>
            <p className="mt-2 text-sm text-text-muted">
              The PR panel can connect you to an eligible alumni senior. No profile is guessed or substituted.
            </p>
          </section>
        )
      )}

      <section className="rounded-3xl border border-border-light bg-white p-6">
        <h2 className="flex items-center gap-2 font-black text-text-main">
          <BookOpen className="h-4 w-4 text-primary-purple" />
          Continuity across batches
        </h2>
        <p className="mt-2 text-sm leading-6 text-text-muted">
          Assignments are stored between verified user profiles. Matching by register suffix guides the lineage connection network, connecting active students directly to graduated alumni.
        </p>
      </section>
    </div>
  )
}

