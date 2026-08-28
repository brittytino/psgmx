'use client'

import React from 'react'
import { Linkedin, Loader2, Mail, Users } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { getCurrentProfile } from '@/lib/current-profile'
import { InitialsAvatar } from '@/components/basic/InitialsAvatar'

type Senior = { id: string; name: string; reg_no: string; mentorship_open: boolean; linkedin_url: string | null; email: string; current_company: string | null; current_role_title: string | null }

export default function LineagePage() {
  const supabase = React.useMemo(() => createClient(), [])
  const [senior, setSenior] = React.useState<Senior | null>(null)
  const [quote, setQuote] = React.useState<string | null>(null)
  const [suffix, setSuffix] = React.useState('')
  const [loading, setLoading] = React.useState(true)
  const [error, setError] = React.useState('')

  React.useEffect(() => { void (async () => {
    try {
      const me = await getCurrentProfile(supabase)
      if (!me) throw new Error('Your student profile could not be found.')
      setSuffix(me.reg_no.slice(-3))
      const { data: map, error: mapError } = await supabase.from('lineage_map').select('senior_user_id,senior_quote').eq('student_id', me.id).maybeSingle()
      if (mapError) throw mapError
      setQuote(map?.senior_quote ?? null)
      if (map?.senior_user_id) {
        const { data: person, error: personError } = await supabase.from('users').select('id,name,reg_no,mentorship_open,linkedin_url,email,current_company,current_role_title').eq('id', map.senior_user_id).maybeSingle()
        if (personError) throw personError
        setSenior(person)
      }
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : 'Lineage could not be loaded.')
    } finally {
      setLoading(false)
    }
  })() }, [supabase])

  if (loading) return <div className="flex min-h-64 items-center justify-center"><Loader2 className="h-6 w-6 animate-spin text-primary-purple"/></div>

  return <div className="mx-auto max-w-4xl space-y-7 pb-10">
    <div><h1 className="flex items-center gap-2 text-2xl font-black"><Users className="h-6 w-6 text-primary-purple"/>Your lineage</h1><p className="mt-1 text-sm text-text-muted">A department-maintained human connection across MCA cohorts.</p></div>
    {error && <div className="rounded-2xl border border-amber-200 bg-amber-50 p-5 text-sm font-bold">{error}</div>}
    {!error && !senior && <div className="rounded-3xl border border-dashed border-border-light bg-white p-12 text-center"><Users className="mx-auto h-10 w-10 text-text-muted"/><h2 className="mt-4 font-black">Your senior is not assigned yet</h2><p className="mx-auto mt-2 max-w-lg text-sm leading-6 text-text-muted">Your Placement Rep or faculty coordinator can create the connection. This page will update automatically—no app release is needed.</p></div>}
    {senior && <section className="rounded-3xl border border-border-light bg-white p-6 sm:p-8"><p className="text-xs font-black uppercase tracking-[0.18em] text-primary-purple">Assigned lineage senior</p><div className="mt-5 flex flex-col gap-5 sm:flex-row"><InitialsAvatar name={senior.name} size={72}/><div className="flex-1"><h2 className="text-2xl font-black">{senior.name}</h2><p className="mt-1 text-sm text-text-muted">{senior.reg_no}{(senior.current_role_title || senior.current_company) ? ` · ${[senior.current_role_title, senior.current_company].filter(Boolean).join(' at ')}` : ''}</p>{quote && <blockquote className="mt-5 rounded-2xl bg-page-bg p-4 text-sm italic leading-6">“{quote}”</blockquote>}{senior.mentorship_open ? <div className="mt-5 flex flex-wrap gap-2">{senior.linkedin_url && <a href={senior.linkedin_url} target="_blank" rel="noreferrer" className="flex items-center gap-2 rounded-xl bg-primary-purple px-4 py-3 text-sm font-bold text-white"><Linkedin className="h-4 w-4"/>LinkedIn</a>}<a href={`mailto:${senior.email}`} className="flex items-center gap-2 rounded-xl border border-border-light px-4 py-3 text-sm font-bold"><Mail className="h-4 w-4"/>Email</a></div> : <p className="mt-5 rounded-xl bg-page-bg p-4 text-sm text-text-muted">Your senior is currently unavailable for direct mentorship. Their approved Knowledge Brain contributions remain available.</p>}</div></div></section>}
    <section className="rounded-2xl bg-page-bg p-5"><h2 className="text-sm font-black">Lineage suffix {suffix || '—'}</h2><p className="mt-2 text-sm leading-6 text-text-muted">The final three digits help the department build continuity across cohorts, while the actual assignment is stored by stable user ID so email or batch changes cannot break it.</p></section>
  </div>
}
