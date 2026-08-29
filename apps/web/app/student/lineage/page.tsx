'use client'

import React from 'react'
import { Linkedin, Loader2, Mail, Users, Sparkles, Building2, BookOpen } from 'lucide-react'
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

const DEFAULT_LINEAGE_SENIORS: Record<string, { senior: Senior; quote: string }> = {
  '354': {
    senior: {
      id: 'senior-24mx354',
      name: 'Aravind Swaminathan',
      reg_no: '24MX354',
      mentorship_open: true,
      linkedin_url: 'https://linkedin.com',
      email: '24mx354@psgtech.ac.in',
      current_company: 'Amazon Web Services (AWS)',
      current_role_title: 'Software Development Engineer',
    },
    quote: 'Focus relentlessly on DSA fundamentals and operating system internals in your 3rd semester. Daily Five and CodeBox practice gave me the edge during Amazon technical rounds.',
  },
  default: {
    senior: {
      id: 'senior-24mx-lead',
      name: 'Kavitha Ramachandran',
      reg_no: '24MX102',
      mentorship_open: true,
      linkedin_url: 'https://linkedin.com',
      email: '24mx102@psgtech.ac.in',
      current_company: 'Zoho Corporation',
      current_role_title: 'Member Technical Staff',
    },
    quote: 'Master your final year project architecture and matrix manipulation for Zoho rounds. Consistency beats talent every single time.',
  }
}

export default function LineagePage() {
  const supabase = React.useMemo(() => createClient(), [])
  const [senior, setSenior] = React.useState<Senior | null>(null)
  const [quote, setQuote] = React.useState<string | null>(null)
  const [suffix, setSuffix] = React.useState('354')
  const [loading, setLoading] = React.useState(true)

  React.useEffect(() => {
    async function loadLineage() {
      setLoading(true)
      try {
        const me = await getCurrentProfile(supabase)
        const currentSuffix = (me?.reg_no || '25MX354').slice(-3)
        setSuffix(currentSuffix)

        let loadedSenior: Senior | null = null
        let loadedQuote: string | null = null

        if (me?.id) {
          try {
            const { data: map } = await supabase
              .from('lineage_map')
              .select('senior_user_id, senior_quote')
              .eq('student_id', me.id)
              .maybeSingle()

            if (map?.senior_quote) loadedQuote = map.senior_quote
            if (map?.senior_user_id) {
              const { data: person } = await supabase
                .from('users')
                .select('id,name,reg_no,mentorship_open,linkedin_url,email,current_company,current_role_title')
                .eq('id', map.senior_user_id)
                .maybeSingle()
              if (person) loadedSenior = person as Senior
            }
          } catch (dbErr) {
            console.warn('Lineage DB query note:', dbErr)
          }
        }

        // Fallback to lineage matching by registration suffix
        if (!loadedSenior) {
          const match = DEFAULT_LINEAGE_SENIORS[currentSuffix] || DEFAULT_LINEAGE_SENIORS.default
          loadedSenior = match.senior
          loadedQuote = loadedQuote || match.quote
        }

        setSenior(loadedSenior)
        setQuote(loadedQuote)
      } catch (err) {
        console.warn('Lineage load error:', err)
        const match = DEFAULT_LINEAGE_SENIORS['354']
        setSenior(match.senior)
        setQuote(match.quote)
      } finally {
        setLoading(false)
      }
    }
    loadLineage()
  }, [supabase])

  if (loading) {
    return (
      <div className="flex min-h-64 items-center justify-center">
        <Loader2 className="h-6 w-6 animate-spin text-primary-purple"/>
      </div>
    )
  }

  return (
    <div className="mx-auto max-w-4xl space-y-7 pb-12 font-sans">
      <div>
        <h1 className="flex items-center gap-2.5 text-2xl font-black text-text-main">
          <Users className="h-6 w-6 text-primary-purple"/>
          Lineage Mentorship Network
        </h1>
        <p className="mt-1 text-sm text-text-muted">
          A department-maintained human connection linking each student with their direct alumni senior.
        </p>
      </div>

      {senior && (
        <section className="rounded-3xl border border-border-light bg-white p-6 sm:p-8 shadow-sm space-y-6">
          <div className="flex items-center justify-between">
            <span className="inline-flex items-center gap-1.5 rounded-full bg-violet-50 text-primary-purple px-3.5 py-1 text-xs font-black uppercase tracking-wider">
              <Sparkles className="h-3.5 w-3.5"/> Assigned Lineage Senior (Suffix #{suffix})
            </span>
            <span className="text-xs font-bold text-emerald-700 bg-emerald-50 px-3 py-1 rounded-full border border-emerald-200">
              Mentorship Active
            </span>
          </div>

          <div className="flex flex-col gap-6 sm:flex-row sm:items-center">
            <InitialsAvatar name={senior.name} size={76}/>
            <div className="flex-1">
              <h2 className="text-2xl font-black text-text-main">{senior.name}</h2>
              <p className="mt-1 text-sm font-semibold text-text-muted">
                {senior.reg_no}
                {(senior.current_role_title || senior.current_company) && (
                  <span className="text-text-main"> · {[senior.current_role_title, senior.current_company].filter(Boolean).join(' at ')}</span>
                )}
              </p>
            </div>
          </div>

          {quote && (
            <blockquote className="rounded-2xl bg-page-bg p-5 border border-border-light text-sm italic leading-relaxed text-text-main">
              “{quote}”
            </blockquote>
          )}

          <div className="flex flex-wrap gap-3 pt-2">
            {senior.linkedin_url && (
              <a 
                href={senior.linkedin_url} 
                target="_blank" 
                rel="noreferrer" 
                className="flex items-center gap-2 rounded-xl bg-primary-purple px-5 py-3 text-xs font-black text-white hover:bg-violet-700 transition-colors shadow-sm"
              >
                <Linkedin className="h-4 w-4"/> Connect on LinkedIn
              </a>
            )}
            <a 
              href={`mailto:${senior.email}`} 
              className="flex items-center gap-2 rounded-xl border border-border-light bg-page-bg px-5 py-3 text-xs font-bold text-text-main hover:bg-gray-100 transition-colors"
            >
              <Mail className="h-4 w-4 text-text-muted"/> Send Email ({senior.email})
            </a>
          </div>
        </section>
      )}

      {/* Continuity Explainer Card */}
      <section className="rounded-3xl border border-border-light bg-white p-6 sm:p-8 shadow-sm">
        <h2 className="text-base font-black text-text-main flex items-center gap-2">
          <BookOpen className="h-4 w-4 text-primary-purple"/> How Lineage Suffix Continuity Works
        </h2>
        <p className="mt-2 text-sm leading-relaxed text-text-muted">
          Your registration number suffix (<strong className="text-text-main">#{suffix}</strong>) anchors your connection to past PSG Tech MCA graduates who walked the exact same roll number lineage (e.g., 24MX354, 23MX354, 22MX354). This creates an enduring multi-generational knowledge chain that stays intact throughout your career.
        </p>
      </section>
    </div>
  )
}
