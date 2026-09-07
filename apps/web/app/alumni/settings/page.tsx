'use client'

import React, { useState, useEffect, useMemo } from 'react'
import { Linkedin, Github, Save, Settings, ShieldCheck, ToggleLeft, ToggleRight, Loader2, User, Building, Briefcase } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { getCurrentProfile } from '@/lib/current-profile'
import { useUI } from '@/components/providers/ui-provider'
import { parseBatchFromRegisterNumber } from '@/lib/auth-input'

type ProfileForm = {
  id: string
  name: string
  regNo: string
  batch: string
  email: string
  company: string
  role: string
  linkedin: string
  github: string
  skills: string
  mentorshipOpen: boolean
}

export default function AlumniSettingsPage() {
  const supabase = useMemo(() => createClient(), [])
  const { showToast } = useUI()
  const [form, setForm] = useState<ProfileForm | null>(null)
  const [loading, setLoading] = useState(true)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')

  useEffect(() => {
    void (async () => {
      try {
        const me = await getCurrentProfile(supabase)
        if (!me) throw new Error('Your alumni profile could not be loaded.')

        const parsed = me.reg_no ? parseBatchFromRegisterNumber(me.reg_no) : null
        const batchDisplay = me.batch || parsed?.code || (me.reg_no ? me.reg_no.slice(0, 4) : 'MCA')

        setForm({
          id: me.id,
          name: me.name,
          regNo: me.reg_no || '',
          batch: batchDisplay,
          email: me.email,
          company: me.current_company ?? '',
          role: me.current_role_title ?? '',
          linkedin: me.linkedin_url ?? '',
          github: me.github_url ?? '',
          skills: (me.skills ?? []).join(', '),
          mentorshipOpen: Boolean(me.mentorship_open),
        })
      } catch (cause) {
        setError(cause instanceof Error ? cause.message : 'Your profile could not be loaded.')
      } finally {
        setLoading(false)
      }
    })()
  }, [supabase])

  async function save() {
    if (!form) return
    setBusy(true)
    setError('')
    try {
      const { error: updateError } = await supabase
        .from('users')
        .update({
          name: form.name.trim(),
          current_company: form.company.trim() || null,
          current_role_title: form.role.trim() || null,
          linkedin_url: form.linkedin.trim() || null,
          github_url: form.github.trim() || null,
          skills: form.skills
            .split(',')
            .map((skill) => skill.trim())
            .filter(Boolean),
          mentorship_open: form.mentorshipOpen,
        })
        .eq('id', form.id)

      if (updateError) throw updateError
      showToast('Your alumni profile and mentorship settings are updated.', 'success')
    } catch (cause) {
      const msg = cause instanceof Error ? cause.message : 'Failed to save changes.'
      setError(msg)
      showToast(msg, 'error')
    } finally {
      setBusy(false)
    }
  }

  if (loading) {
    return (
      <div className="mx-auto h-96 max-w-4xl animate-pulse rounded-3xl bg-white border border-border-light" />
    )
  }

  if (!form) {
    return (
      <div role="alert" className="mx-auto max-w-4xl rounded-2xl border border-red-200 bg-red-50 p-5 text-sm font-bold text-red-700">
        {error}
      </div>
    )
  }

  return (
    <div className="mx-auto max-w-4xl space-y-6 pb-12">
      <header>
        <div className="mb-2 flex items-center gap-2 text-xs font-black uppercase tracking-[.16em] text-primary-purple">
          <Settings className="h-4 w-4" /> Alumni Profile
        </div>
        <h1 className="text-3xl font-black tracking-tight text-text-main">Account & Mentorship Settings</h1>
        <p className="mt-2 text-sm text-text-muted">
          Keep your professional details and mentorship availability updated for students and lineage juniors.
        </p>
      </header>

      {error && (
        <div role="alert" className="rounded-2xl border border-red-200 bg-red-50 p-4 text-sm font-bold text-red-700">
          {error}
        </div>
      )}

      {/* Verified Academic Identity */}
      <section className="rounded-3xl border border-border-light bg-white p-6 md:p-8 shadow-sm">
        <h2 className="text-lg font-black text-text-main">Verified Identity</h2>
        <div className="mt-4 grid gap-3 sm:grid-cols-3">
          {[
            ['Register Number', form.regNo || '—'],
            ['Cohort Batch', form.batch],
            ['Verified Email', form.email],
          ].map(([label, value]) => (
            <div key={label} className="rounded-2xl bg-page-bg p-4 border border-border-light/60">
              <p className="text-[10px] font-black uppercase tracking-wider text-text-muted">{label}</p>
              <p className="mt-1 break-all text-sm font-bold text-text-main">{value}</p>
            </div>
          ))}
        </div>
      </section>

      {/* Professional Career Info */}
      <section className="rounded-3xl border border-border-light bg-white p-6 md:p-8 shadow-sm">
        <h2 className="text-lg font-black text-text-main">Professional & Industry Context</h2>
        <div className="mt-5 grid gap-4 sm:grid-cols-2">
          <Field
            label="Full Name"
            value={form.name}
            onChange={(name) => setForm({ ...form, name })}
            icon={<User className="h-3.5 w-3.5" />}
          />
          <Field
            label="Current Organisation"
            value={form.company}
            onChange={(company) => setForm({ ...form, company })}
            placeholder="e.g. Google, Microsoft, Amazon"
            icon={<Building className="h-3.5 w-3.5" />}
          />
          <Field
            label="Current Role / Title"
            value={form.role}
            onChange={(role) => setForm({ ...form, role })}
            placeholder="e.g. Senior Software Engineer"
            icon={<Briefcase className="h-3.5 w-3.5" />}
          />
          <Field
            label="Key Skills (comma separated)"
            value={form.skills}
            onChange={(skills) => setForm({ ...form, skills })}
            placeholder="Distributed Systems, Java, React, Cloud Architecture"
          />
          <Field
            label="LinkedIn Profile URL"
            value={form.linkedin}
            onChange={(linkedin) => setForm({ ...form, linkedin })}
            placeholder="https://linkedin.com/in/..."
            icon={<Linkedin className="h-3.5 w-3.5" />}
          />
          <Field
            label="GitHub Profile URL"
            value={form.github}
            onChange={(github) => setForm({ ...form, github })}
            placeholder="https://github.com/..."
            icon={<Github className="h-3.5 w-3.5" />}
          />
        </div>
      </section>

      {/* Mentorship Availability */}
      <section className="rounded-3xl border border-border-light bg-white p-6 md:p-8 shadow-sm">
        <div className="flex items-center justify-between gap-5">
          <div>
            <h2 className="text-lg font-black text-text-main">Mentorship Availability</h2>
            <p className="mt-1 text-xs leading-6 text-text-muted max-w-xl">
              When enabled, your lineage juniors and MCA students can see your guidance availability and reach out through your verified contacts.
            </p>
          </div>
          <button
            type="button"
            aria-pressed={form.mentorshipOpen}
            onClick={() => setForm({ ...form, mentorshipOpen: !form.mentorshipOpen })}
            className="cursor-pointer transition-transform active:scale-95"
          >
            {form.mentorshipOpen ? (
              <ToggleRight className="h-12 w-12 text-emerald-600" />
            ) : (
              <ToggleLeft className="h-12 w-12 text-border-light hover:text-text-muted" />
            )}
          </button>
        </div>
      </section>

      {/* Bottom Save Action */}
      <div className="flex flex-col gap-3 rounded-2xl border border-violet-100 bg-violet-50/50 p-4 text-sm text-text-main sm:flex-row sm:items-center sm:justify-between">
        <div className="flex items-center gap-3">
          <ShieldCheck className="h-5 w-5 shrink-0 text-primary-purple" />
          <p className="text-xs text-text-muted">
            All alumni profile changes are saved instantly to your verified department identity.
          </p>
        </div>
        <button
          disabled={busy}
          onClick={() => void save()}
          className="inline-flex shrink-0 items-center justify-center gap-2 rounded-xl bg-primary-purple px-6 py-3 text-sm font-black text-white shadow-sm hover:bg-deep-violet disabled:opacity-50 transition-colors"
        >
          {busy ? <Loader2 className="h-4 w-4 animate-spin" /> : <Save className="h-4 w-4" />}
          {busy ? 'Saving…' : 'Save Changes'}
        </button>
      </div>
    </div>
  )
}

function Field({
  label,
  value,
  onChange,
  placeholder,
  icon,
}: {
  label: string
  value: string
  onChange: (value: string) => void
  placeholder?: string
  icon?: React.ReactNode
}) {
  return (
    <label className="block">
      <span className="mb-2 flex items-center gap-2 text-[11px] font-black uppercase tracking-wider text-text-muted">
        {icon}
        {label}
      </span>
      <input
        value={value}
        onChange={(event) => onChange(event.target.value)}
        placeholder={placeholder}
        className="w-full rounded-xl border border-border-light bg-page-bg px-4 py-3 text-sm outline-none focus:border-primary-purple focus:bg-white transition-colors"
      />
    </label>
  )
}
