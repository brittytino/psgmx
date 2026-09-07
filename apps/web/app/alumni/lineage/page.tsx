'use client'

import React, { useState, useEffect, useCallback, useMemo } from 'react'
import { Linkedin, Loader2, Mail, Save, Users, ShieldCheck, HeartHandshake } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { getCurrentProfile } from '@/lib/current-profile'
import { InitialsAvatar } from '@/components/basic/InitialsAvatar'
import { useUI } from '@/components/providers/ui-provider'

type Person = {
  id: string
  name: string
  reg_no: string
  email: string
  linkedin_url: string | null
  current_company: string | null
  current_role_title: string | null
}

export default function AlumniLineagePage() {
  const supabase = useMemo(() => createClient(), [])
  const { showToast } = useUI()
  const [me, setMe] = useState<Person | null>(null)
  const [senior, setSenior] = useState<Person | null>(null)
  const [juniors, setJuniors] = useState<Person[]>([])
  const [mentorshipOpen, setMentorshipOpen] = useState(false)
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)

  const load = useCallback(async () => {
    setLoading(true)
    try {
      const profile = await getCurrentProfile(supabase)
      if (!profile) throw new Error('Your alumni profile could not be found.')
      setMe(profile)
      setMentorshipOpen(Boolean(profile.mentorship_open))

      const [{ data: seniorMap }, { data: juniorMaps }] = await Promise.all([
        supabase.from('lineage_map').select('senior_user_id').eq('student_id', profile.id).maybeSingle(),
        supabase.from('lineage_map').select('student_id').eq('senior_user_id', profile.id),
      ])

      const juniorIds = (juniorMaps ?? []).map((row) => row.student_id)
      const [{ data: seniorRow }, { data: juniorRows }] = await Promise.all([
        seniorMap?.senior_user_id
          ? supabase
              .from('users')
              .select('id,name,reg_no,email,linkedin_url,current_company,current_role_title')
              .eq('id', seniorMap.senior_user_id)
              .maybeSingle()
          : Promise.resolve({ data: null }),
        juniorIds.length
          ? supabase
              .from('users')
              .select('id,name,reg_no,email,linkedin_url,current_company,current_role_title')
              .in('id', juniorIds)
          : Promise.resolve({ data: [] }),
      ])

      setSenior(seniorRow)
      setJuniors(juniorRows ?? [])
    } catch (cause) {
      const msg = cause instanceof Error ? cause.message : 'Lineage could not be loaded.'
      showToast(msg, 'error')
    } finally {
      setLoading(false)
    }
  }, [supabase, showToast])

  useEffect(() => {
    void load()
  }, [load])

  async function saveAvailability(nextState?: boolean) {
    if (!me) return
    const newState = nextState !== undefined ? nextState : mentorshipOpen
    setSaving(true)
    try {
      const { error } = await supabase.from('users').update({ mentorship_open: newState }).eq('id', me.id)
      if (error) throw error
      setMentorshipOpen(newState)
      showToast(
        newState
          ? 'Mentorship enabled. Your juniors can reach you through your verified contacts.'
          : 'Mentorship availability paused.',
        'success'
      )
    } catch (cause) {
      const msg = cause instanceof Error ? cause.message : 'Failed to update mentorship availability.'
      showToast(msg, 'error')
    } finally {
      setSaving(false)
    }
  }

  if (loading) {
    return (
      <div className="flex min-h-64 items-center justify-center">
        <Loader2 className="h-6 w-6 animate-spin text-primary-purple" />
      </div>
    )
  }

  return (
    <div className="mx-auto max-w-5xl space-y-7 pb-12">
      <header>
        <div className="mb-2 flex items-center gap-2 text-xs font-black uppercase tracking-[.16em] text-primary-purple">
          <Users className="h-4 w-4" /> Department Lineage
        </div>
        <h1 className="text-3xl font-black tracking-tight text-text-main">Your Lineage Tree</h1>
        <p className="mt-1 text-sm text-text-muted">
          Real people connected across batches by matching register number suffixes maintained by the MCA department.
        </p>
      </header>

      {/* Mentorship Availability Control */}
      <section className="rounded-3xl border border-border-light bg-white p-6 md:p-8 shadow-sm">
        <div className="flex flex-col gap-5 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <span className="text-xs font-black uppercase tracking-wide text-text-muted">Mentorship Availability</span>
            <h2 className="mt-1 text-xl font-black text-text-main">
              {mentorshipOpen ? 'Open to your Lineage Juniors' : 'Currently Paused'}
            </h2>
            <p className="mt-1.5 max-w-xl text-xs leading-relaxed text-text-muted">
              When enabled, assigned juniors can contact you via LinkedIn or college email for project reviews and career roadmaps.
            </p>
          </div>
          <label className="flex items-center gap-3 rounded-2xl bg-page-bg p-4 text-sm font-black cursor-pointer select-none">
            <input
              type="checkbox"
              checked={mentorshipOpen}
              onChange={(e) => {
                const checked = e.target.checked
                setMentorshipOpen(checked)
                void saveAvailability(checked)
              }}
              className="h-5 w-5 accent-[#5B3FD1] cursor-pointer"
            />
            <span>{mentorshipOpen ? 'Available' : 'Paused'}</span>
          </label>
        </div>

        <div className="mt-5 flex items-center gap-3">
          <button
            onClick={() => void saveAvailability()}
            disabled={!me || saving}
            className="flex items-center gap-2 rounded-xl bg-primary-purple px-5 py-3 text-xs font-bold text-white shadow-sm hover:bg-deep-violet disabled:opacity-50 transition-colors"
          >
            {saving ? <Loader2 className="h-4 w-4 animate-spin" /> : <Save className="h-4 w-4" />}
            Save Availability
          </button>
        </div>
      </section>

      {/* Juniors & Senior Grid */}
      <div className="grid gap-6 lg:grid-cols-3">
        <section className="lg:col-span-2 space-y-3">
          <div className="flex items-center justify-between">
            <h2 className="font-black text-text-main text-base">Juniors Assigned to You ({juniors.length})</h2>
            <span className="text-xs font-bold text-text-muted">Same Register Suffix</span>
          </div>
          <div className="space-y-3">
            {juniors.map((person) => (
              <PersonCard key={person.id} person={person} contacts={mentorshipOpen} />
            ))}
          </div>
          {juniors.length === 0 && (
            <Empty text="No junior has been assigned to you yet. Assignments automatically happen when the new matching MCA cohort is onboarded." />
          )}
        </section>

        <section className="space-y-3">
          <h2 className="font-black text-text-main text-base">Your Senior</h2>
          <div>
            {senior ? (
              <PersonCard person={senior} contacts={true} />
            ) : (
              <Empty text="No senior record is linked to this account register suffix." />
            )}
          </div>
        </section>
      </div>

      {/* Explanatory Info Card */}
      <section className="rounded-3xl border border-violet-100 bg-violet-50/40 p-6">
        <div className="flex items-start gap-3">
          <HeartHandshake className="h-5 w-5 text-primary-purple shrink-0 mt-0.5" />
          <div>
            <h3 className="text-sm font-black text-text-main">Scalable Lineage Architecture</h3>
            <p className="mt-1 text-xs leading-relaxed text-text-muted">
              Lineage assignments are dynamically stored by UUID relations and register suffix patterns. Every incoming batch seamlessly inherits their senior lineage connections without hardcoding.
            </p>
          </div>
        </div>
      </section>
    </div>
  )
}

function PersonCard({ person, contacts }: { person: Person; contacts: boolean }) {
  return (
    <article className="rounded-3xl border border-border-light bg-white p-6 shadow-sm hover:shadow-md transition-shadow">
      <div className="flex items-start gap-4">
        <InitialsAvatar name={person.name} size={44} />
        <div className="min-w-0 flex-1">
          <div className="flex items-center justify-between gap-2">
            <h3 className="font-black text-text-main text-sm truncate">{person.name}</h3>
            <span className="rounded-full bg-page-bg px-2.5 py-0.5 text-[10px] font-bold text-text-muted">
              {person.reg_no}
            </span>
          </div>

          {(person.current_role_title || person.current_company) && (
            <p className="mt-1 text-xs font-semibold text-text-main truncate">
              {[person.current_role_title, person.current_company].filter(Boolean).join(' · ')}
            </p>
          )}

          {contacts && (
            <div className="mt-4 flex flex-wrap gap-2">
              {person.linkedin_url && (
                <a
                  href={person.linkedin_url}
                  target="_blank"
                  rel="noreferrer"
                  className="flex items-center gap-1.5 rounded-xl bg-violet-50 px-3 py-1.5 text-xs font-bold text-primary-purple hover:bg-violet-100 transition-colors"
                >
                  <Linkedin className="h-3.5 w-3.5" /> LinkedIn
                </a>
              )}
              {person.email && (
                <a
                  href={`mailto:${person.email}`}
                  className="flex items-center gap-1.5 rounded-xl bg-page-bg px-3 py-1.5 text-xs font-bold text-text-main hover:bg-border-light transition-colors"
                >
                  <Mail className="h-3.5 w-3.5" /> Email
                </a>
              )}
            </div>
          )}
        </div>
      </div>
    </article>
  )
}

function Empty({ text }: { text: string }) {
  return (
    <div className="rounded-3xl border border-dashed border-border-light bg-white p-8 text-center text-xs leading-6 text-text-muted">
      {text}
    </div>
  )
}
