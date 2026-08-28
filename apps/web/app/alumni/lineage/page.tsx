'use client'

import React from 'react'
import { Linkedin, Loader2, Mail, Save, Users } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { getCurrentProfile } from '@/lib/current-profile'
import { InitialsAvatar } from '@/components/basic/InitialsAvatar'

type Person = { id: string; name: string; reg_no: string; email: string; linkedin_url: string | null; current_company: string | null; current_role_title: string | null }

export default function AlumniLineagePage() {
  const supabase = React.useMemo(() => createClient(), [])
  const [me, setMe] = React.useState<Person | null>(null)
  const [senior, setSenior] = React.useState<Person | null>(null)
  const [juniors, setJuniors] = React.useState<Person[]>([])
  const [mentorshipOpen, setMentorshipOpen] = React.useState(false)
  const [loading, setLoading] = React.useState(true)
  const [saving, setSaving] = React.useState(false)
  const [message, setMessage] = React.useState('')

  const load = React.useCallback(async () => {
    setLoading(true)
    try {
      const profile = await getCurrentProfile(supabase)
      if (!profile) throw new Error('Your alumni profile could not be found.')
      setMe(profile)
      setMentorshipOpen(profile.mentorship_open)
      const [{ data: seniorMap }, { data: juniorMaps }] = await Promise.all([
        supabase.from('lineage_map').select('senior_user_id').eq('student_id', profile.id).maybeSingle(),
        supabase.from('lineage_map').select('student_id').eq('senior_user_id', profile.id),
      ])
      const juniorIds = (juniorMaps ?? []).map((row) => row.student_id)
      const [{ data: seniorRow }, { data: juniorRows }] = await Promise.all([
        seniorMap?.senior_user_id ? supabase.from('users').select('id,name,reg_no,email,linkedin_url,current_company,current_role_title').eq('id', seniorMap.senior_user_id).maybeSingle() : Promise.resolve({ data: null }),
        juniorIds.length ? supabase.from('users').select('id,name,reg_no,email,linkedin_url,current_company,current_role_title').in('id', juniorIds) : Promise.resolve({ data: [] }),
      ])
      setSenior(seniorRow)
      setJuniors(juniorRows ?? [])
    } catch (cause) {
      setMessage(cause instanceof Error ? cause.message : 'Lineage could not be loaded.')
    } finally {
      setLoading(false)
    }
  }, [supabase])

  React.useEffect(() => { void load() }, [load])

  async function saveAvailability() {
    if (!me) return
    setSaving(true)
    const { error } = await supabase.from('users').update({ mentorship_open: mentorshipOpen }).eq('id', me.id)
    setMessage(error ? error.message : mentorshipOpen ? 'Your juniors can now reach you through your saved profile links.' : 'Mentorship availability is now paused.')
    setSaving(false)
  }

  if (loading) return <div className="flex min-h-64 items-center justify-center"><Loader2 className="h-6 w-6 animate-spin text-primary-purple"/></div>

  return <div className="mx-auto max-w-5xl space-y-7 pb-10">
    <div><h1 className="flex items-center gap-2 text-2xl font-black"><Users className="h-6 w-6 text-primary-purple"/>Your lineage</h1><p className="mt-1 text-sm text-text-muted">Real people connected by the register-number lineage map maintained by the department.</p></div>

    <section className="rounded-3xl border border-border-light bg-white p-6"><div className="flex flex-col gap-5 sm:flex-row sm:items-center sm:justify-between"><div><p className="text-xs font-black uppercase tracking-wide text-text-muted">Mentorship availability</p><h2 className="mt-1 text-xl font-black">{mentorshipOpen ? 'Open to your juniors' : 'Currently paused'}</h2><p className="mt-2 max-w-xl text-sm text-text-muted">When enabled, assigned juniors can use the LinkedIn and email details already on your profile.</p></div><label className="flex items-center gap-3 rounded-2xl bg-page-bg p-4 text-sm font-black"><input type="checkbox" checked={mentorshipOpen} onChange={(event) => setMentorshipOpen(event.target.checked)} className="h-5 w-5 accent-[#5B3FD1]"/>Available</label></div><div className="mt-5 flex items-center gap-3"><button onClick={saveAvailability} disabled={!me || saving} className="flex items-center gap-2 rounded-xl bg-primary-purple px-5 py-3 text-sm font-bold text-white disabled:opacity-50">{saving ? <Loader2 className="h-4 w-4 animate-spin"/> : <Save className="h-4 w-4"/>}Save availability</button>{message && <p className="text-sm font-semibold" role="status">{message}</p>}</div></section>

    <div className="grid gap-6 lg:grid-cols-3"><section className="lg:col-span-2"><h2 className="font-black">Juniors assigned to you</h2><div className="mt-3 space-y-3">{juniors.map((person) => <PersonCard key={person.id} person={person} contacts={mentorshipOpen}/>)}</div>{juniors.length === 0 && <Empty text="No junior has been assigned to you yet. Assignment happens when the next matching cohort is onboarded." />}</section><section><h2 className="font-black">Your senior</h2><div className="mt-3">{senior ? <PersonCard person={senior} contacts/> : <Empty text="No senior record is linked to this account yet." />}</div></section></div>

    <section className="rounded-2xl bg-page-bg p-5"><h2 className="text-sm font-black">How this stays useful for five more batches</h2><p className="mt-2 text-sm leading-6 text-text-muted">Lineage assignments are stored by user ID, not hardcoded names or one batch code. New cohorts can therefore inherit mentoring connections without changing this screen.</p></section>
  </div>
}

function PersonCard({ person, contacts }: { person: Person; contacts: boolean }) {
  return <article className="rounded-2xl border border-border-light bg-white p-5"><div className="flex items-start gap-3"><InitialsAvatar name={person.name} size={42}/><div className="min-w-0 flex-1"><h3 className="font-black">{person.name}</h3><p className="text-xs text-text-muted">{person.reg_no}</p>{(person.current_role_title || person.current_company) && <p className="mt-2 text-sm font-semibold">{[person.current_role_title, person.current_company].filter(Boolean).join(' · ')}</p>}{contacts && <div className="mt-4 flex flex-wrap gap-2">{person.linkedin_url && <a href={person.linkedin_url} target="_blank" rel="noreferrer" className="flex items-center gap-1 rounded-lg bg-violet-50 px-3 py-2 text-xs font-bold text-primary-purple"><Linkedin className="h-3.5 w-3.5"/>LinkedIn</a>}<a href={`mailto:${person.email}`} className="flex items-center gap-1 rounded-lg bg-page-bg px-3 py-2 text-xs font-bold"><Mail className="h-3.5 w-3.5"/>Email</a></div>}</div></div></article>
}

function Empty({ text }: { text: string }) {
  return <div className="rounded-2xl border border-dashed border-border-light bg-white p-6 text-sm leading-6 text-text-muted">{text}</div>
}
