'use client'

import React from 'react'
import {
  BookOpen,
  CheckCircle2,
  CornerUpRight,
  Inbox,
  Linkedin,
  Loader2,
  Mail,
  MessageCircle,
  Send,
  Users,
  X,
} from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { getCurrentProfile } from '@/lib/current-profile'
import { InitialsAvatar } from '@/components/basic/InitialsAvatar'
import { useUI } from '@/components/providers/ui-provider'

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

type Person = {
  id: string
  name: string
  reg_no: string
  email: string
  linkedin_url: string | null
  current_company: string | null
  current_role_title: string | null
}

type LineageRequestStatus = 'pending' | 'accepted' | 'declined' | 'redirected'

type LineageRequestRow = {
  id: string
  topic: string
  question: string
  status: LineageRequestStatus
  created_at: string
  responded_at: string | null
  redirected_to: string | null
  student_id?: string
}

function formatDate(iso: string) {
  try {
    return new Intl.DateTimeFormat('en-IN', { dateStyle: 'medium' }).format(new Date(iso))
  } catch {
    return iso
  }
}

export default function LineagePage() {
  const supabase = React.useMemo(() => createClient(), [])
  // `lineage_requests` (migration 45) isn't in the generated Database types
  // yet — same reason the RPC calls below are cast `as never`. Matches the
  // `db = supabase as any` pattern already used in app/student/announcements.
  const db = supabase as any
  const { showToast } = useUI()

  const [me, setMe] = React.useState<{ id: string } | null>(null)
  const [senior, setSenior] = React.useState<Senior | null>(null)
  const [quote, setQuote] = React.useState<string | null>(null)
  const [juniors, setJuniors] = React.useState<Person[]>([])
  const [sentRequests, setSentRequests] = React.useState<LineageRequestRow[]>([])
  const [incomingRequests, setIncomingRequests] = React.useState<LineageRequestRow[]>([])
  const [loading, setLoading] = React.useState(true)
  const [error, setError] = React.useState('')

  const [askOpen, setAskOpen] = React.useState(false)
  const [askTopic, setAskTopic] = React.useState('')
  const [askQuestion, setAskQuestion] = React.useState('')
  const [sending, setSending] = React.useState(false)

  const [respondingId, setRespondingId] = React.useState<string | null>(null)
  const [redirectOpenId, setRedirectOpenId] = React.useState<string | null>(null)
  const [redirectTargetId, setRedirectTargetId] = React.useState('')

  const load = React.useCallback(async () => {
    setLoading(true)
    setError('')
    try {
      const profile = await getCurrentProfile(supabase)
      if (!profile?.id) throw new Error('Sign in again to load your lineage.')
      setMe({ id: profile.id })

      // get_my_lineage() / get_my_juniors() are SECURITY DEFINER RPCs, not
      // raw table reads — RLS on `users` has no policy letting a student
      // read an arbitrary senior's or junior's row (only "own row",
      // PR/coordinator/faculty, or same legacy team_id), so a direct query
      // here always returned nothing for a real student. Both are scoped to
      // the caller only. `lineage_requests` itself is a normal RLS-gated
      // table (migrations 45/51): student_id/alumni_id = current_user_id().
      const [
        { data: lineageData, error: lineageErr },
        { data: juniorData, error: juniorErr },
        { data: sentData, error: sentErr },
        { data: incomingData, error: incomingErr },
      ] = await Promise.all([
        supabase.rpc('get_my_lineage' as never),
        supabase.rpc('get_my_juniors' as never),
        db
          .from('lineage_requests')
          .select('id, topic, question, status, created_at, responded_at, redirected_to')
          .eq('student_id', profile.id)
          .order('created_at', { ascending: false })
          .limit(30),
        db
          .from('lineage_requests')
          .select('id, topic, question, status, created_at, responded_at, redirected_to, student_id')
          .eq('alumni_id', profile.id)
          .order('created_at', { ascending: false })
          .limit(30),
      ])
      if (lineageErr) throw lineageErr
      if (juniorErr) throw juniorErr
      if (sentErr) throw sentErr
      if (incomingErr) throw incomingErr

      const rows = (lineageData ?? []) as {
        senior_user_id: string
        senior_name: string
        senior_reg_no: string | null
        senior_current_company: string | null
        senior_current_role_title: string | null
        senior_linkedin_url: string | null
        senior_email: string | null
        senior_mentorship_open: boolean | null
        senior_quote: string | null
      }[]
      const row = rows[0]

      if (row) {
        setSenior({
          id: row.senior_user_id,
          name: row.senior_name,
          reg_no: row.senior_reg_no ?? '',
          mentorship_open: row.senior_mentorship_open ?? false,
          linkedin_url: row.senior_linkedin_url,
          email: row.senior_email ?? '',
          current_company: row.senior_current_company,
          current_role_title: row.senior_current_role_title,
        })
        setQuote(row.senior_quote)
      } else {
        setSenior(null)
        setQuote(null)
      }

      const juniorRows = ((juniorData ?? []) as {
        junior_user_id: string
        junior_name: string
        junior_reg_no: string | null
        junior_email: string | null
        junior_linkedin_url: string | null
        junior_current_company: string | null
        junior_current_role_title: string | null
      }[]).map((r) => ({
        id: r.junior_user_id,
        name: r.junior_name,
        reg_no: r.junior_reg_no ?? '',
        email: r.junior_email ?? '',
        linkedin_url: r.junior_linkedin_url,
        current_company: r.junior_current_company,
        current_role_title: r.junior_current_role_title,
      }))
      setJuniors(juniorRows)

      setSentRequests((sentData ?? []) as LineageRequestRow[])
      setIncomingRequests((incomingData ?? []) as LineageRequestRow[])
    } catch (cause) {
      console.warn('Lineage load notice:', cause)
      setError(cause instanceof Error ? cause.message : 'Lineage details could not be loaded.')
      setSenior(null)
      setJuniors([])
      setSentRequests([])
      setIncomingRequests([])
    } finally {
      setLoading(false)
    }
  }, [supabase, db])

  React.useEffect(() => {
    void load()
  }, [load])

  async function sendRequest() {
    if (!me || !senior) return
    const topic = askTopic.trim()
    const question = askQuestion.trim()
    if (topic.length < 2 || topic.length > 120) {
      showToast('Add a topic between 2 and 120 characters.', 'error')
      return
    }
    if (question.length < 5 || question.length > 1000) {
      showToast('Add a fuller question (at least 5 characters).', 'error')
      return
    }
    setSending(true)
    try {
      const { error } = await db.from('lineage_requests').insert({
        student_id: me.id,
        alumni_id: senior.id,
        topic,
        question,
      })
      if (error) throw error
      setAskTopic('')
      setAskQuestion('')
      setAskOpen(false)
      showToast('Question sent to your senior.', 'success')
      void load()
    } catch (cause) {
      showToast(cause instanceof Error ? cause.message : 'Could not send the question. Try again shortly.', 'error')
    } finally {
      setSending(false)
    }
  }

  async function respond(id: string, status: 'accepted' | 'declined' | 'redirected', redirectTo?: string) {
    if (status === 'redirected' && !redirectTo?.trim()) {
      showToast('Choose who to redirect this request to.', 'error')
      return
    }
    setRespondingId(id)
    try {
      const payload: Record<string, unknown> = { status, responded_at: new Date().toISOString() }
      if (status === 'redirected') payload.redirected_to = redirectTo!.trim()
      const { error } = await db.from('lineage_requests').update(payload).eq('id', id)
      if (error) throw error
      setIncomingRequests((prev) =>
        prev.map((r) =>
          r.id === id
            ? { ...r, status, redirected_to: (payload.redirected_to as string) ?? r.redirected_to, responded_at: payload.responded_at as string }
            : r
        )
      )
      setRedirectOpenId(null)
      setRedirectTargetId('')
      showToast(
        status === 'accepted' ? 'Request accepted.' : status === 'declined' ? 'Request declined.' : 'Request redirected.',
        'success'
      )
    } catch (cause) {
      showToast(cause instanceof Error ? cause.message : 'Could not update the request. Try again.', 'error')
    } finally {
      setRespondingId(null)
    }
  }

  const juniorMap = React.useMemo(() => new Map(juniors.map((j) => [j.id, j])), [juniors])
  const pendingIncoming = incomingRequests.filter((r) => r.status === 'pending')
  const resolvedIncoming = incomingRequests.filter((r) => r.status !== 'pending')

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
                Assigned senior
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

          {/* PRD Ch. 14.2: send a topic + question request to the assigned senior */}
          <div className="border-t border-border-light pt-5">
            {!askOpen ? (
              <button
                onClick={() => setAskOpen(true)}
                disabled={!senior.mentorship_open}
                className="inline-flex items-center gap-2 rounded-xl bg-primary-purple px-5 py-3 text-xs font-black text-white hover:bg-deep-violet disabled:cursor-not-allowed disabled:opacity-40 transition-colors"
              >
                <MessageCircle className="h-4 w-4" /> Ask a specific question
              </button>
            ) : (
              <div className="space-y-3 rounded-2xl border border-border-light bg-page-bg p-5">
                <p className="text-xs font-bold text-text-muted">
                  A focused question is easier to answer well than a general chat request.
                </p>
                <div>
                  <label className="mb-1 block text-[11px] font-black uppercase tracking-wide text-text-muted">Topic</label>
                  <input
                    value={askTopic}
                    onChange={(e) => setAskTopic(e.target.value)}
                    maxLength={120}
                    placeholder="System design interviews"
                    className="w-full rounded-xl border border-border-light bg-white px-4 py-2.5 text-sm outline-none focus:border-primary-purple"
                  />
                </div>
                <div>
                  <label className="mb-1 block text-[11px] font-black uppercase tracking-wide text-text-muted">
                    Your specific question
                  </label>
                  <textarea
                    value={askQuestion}
                    onChange={(e) => setAskQuestion(e.target.value)}
                    maxLength={1000}
                    rows={4}
                    placeholder="What's actually on your mind about this topic?"
                    className="w-full rounded-xl border border-border-light bg-white px-4 py-2.5 text-sm outline-none focus:border-primary-purple"
                  />
                </div>
                <div className="flex items-center gap-3">
                  <button
                    onClick={() => void sendRequest()}
                    disabled={sending}
                    className="inline-flex items-center gap-2 rounded-xl bg-primary-purple px-5 py-2.5 text-xs font-black text-white hover:bg-deep-violet disabled:opacity-50 transition-colors"
                  >
                    {sending ? <Loader2 className="h-4 w-4 animate-spin" /> : <Send className="h-4 w-4" />}
                    Review and send
                  </button>
                  <button
                    onClick={() => {
                      setAskOpen(false)
                      setAskTopic('')
                      setAskQuestion('')
                    }}
                    disabled={sending}
                    className="text-xs font-bold text-text-muted hover:text-text-main"
                  >
                    Cancel
                  </button>
                </div>
              </div>
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

      {/* Your sent requests */}
      <section className="rounded-3xl border border-border-light bg-white p-6">
        <h2 className="flex items-center gap-2 font-black text-text-main">
          <MessageCircle className="h-4 w-4 text-primary-purple" />
          Your questions
        </h2>
        <p className="mt-1 text-xs text-text-muted">Requests you've sent to your assigned senior.</p>
        <div className="mt-4 space-y-3">
          {sentRequests.length === 0 ? (
            <p className="rounded-2xl border border-dashed border-border-light bg-page-bg p-6 text-center text-xs text-text-muted">
              No questions sent yet.
            </p>
          ) : (
            sentRequests.map((r) => <RequestCard key={r.id} request={r} />)
          )}
        </div>
      </section>

      {/* Juniors Assigned to You — any signed-in caller can hold juniors,
          not only alumni: a mid-programme senior (e.g. 25MX) can already
          have juniors assigned without needing a senior of their own. */}
      <section className="space-y-3">
        <div className="flex items-center justify-between">
          <h2 className="font-black text-text-main text-base">Juniors Assigned to You ({juniors.length})</h2>
          <span className="text-xs font-bold text-text-muted">Same Register Suffix</span>
        </div>
        <div className="space-y-3">
          {juniors.map((person) => (
            <PersonCard key={person.id} person={person} contacts />
          ))}
        </div>
        {juniors.length === 0 && (
          <Empty text="No junior has been assigned to you yet. Assignments automatically happen when the new matching MCA cohort is onboarded." />
        )}
      </section>

      {/* Incoming requests from juniors */}
      <section className="rounded-3xl border border-border-light bg-white p-6">
        <h2 className="flex items-center gap-2 font-black text-text-main">
          <Inbox className="h-4 w-4 text-primary-purple" />
          Requests from your juniors
        </h2>
        <p className="mt-1 text-xs text-text-muted">Accept, decline, or redirect a junior's question.</p>
        <div className="mt-4 space-y-3">
          {pendingIncoming.length === 0 && resolvedIncoming.length === 0 && (
            <p className="rounded-2xl border border-dashed border-border-light bg-page-bg p-6 text-center text-xs text-text-muted">
              No requests yet. When a junior asks you a specific question, it will show up here.
            </p>
          )}
          {pendingIncoming.map((r) => (
            <IncomingRequestCard
              key={r.id}
              request={r}
              sender={juniorMap.get(r.student_id || '')}
              responding={respondingId === r.id}
              onAccept={() => void respond(r.id, 'accepted')}
              onDecline={() => void respond(r.id, 'declined')}
              redirectOpen={redirectOpenId === r.id}
              onToggleRedirect={() => setRedirectOpenId(redirectOpenId === r.id ? null : r.id)}
              redirectTargetId={redirectTargetId}
              onRedirectTargetChange={setRedirectTargetId}
              onRedirectToSenior={senior ? () => void respond(r.id, 'redirected', senior.id) : undefined}
              seniorName={senior?.name}
              onRedirectSubmit={() => void respond(r.id, 'redirected', redirectTargetId)}
            />
          ))}
          {resolvedIncoming.map((r) => (
            <IncomingRequestCard key={r.id} request={r} sender={juniorMap.get(r.student_id || '')} responding={false} />
          ))}
        </div>
      </section>

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

function StatusChip({ status }: { status: LineageRequestStatus }) {
  const styles: Record<LineageRequestStatus, string> = {
    pending: 'bg-amber-50 text-amber-700',
    accepted: 'bg-emerald-50 text-emerald-700',
    declined: 'bg-slate-100 text-slate-600',
    redirected: 'bg-blue-50 text-blue-700',
  }
  return (
    <span className={`shrink-0 rounded-full px-2.5 py-1 text-[10px] font-black uppercase tracking-wide ${styles[status]}`}>
      {status}
    </span>
  )
}

function RequestCard({ request }: { request: LineageRequestRow }) {
  return (
    <div className="rounded-2xl border border-border-light bg-page-bg p-4">
      <div className="flex items-start justify-between gap-3">
        <p className="text-sm font-black text-text-main">{request.topic}</p>
        <StatusChip status={request.status} />
      </div>
      <p className="mt-2 text-xs leading-relaxed text-text-muted">{request.question}</p>
      <p className="mt-2 text-[10px] font-bold text-text-muted">{formatDate(request.created_at)}</p>
    </div>
  )
}

function IncomingRequestCard({
  request,
  sender,
  responding,
  onAccept,
  onDecline,
  redirectOpen,
  onToggleRedirect,
  redirectTargetId,
  onRedirectTargetChange,
  onRedirectToSenior,
  seniorName,
  onRedirectSubmit,
}: {
  request: LineageRequestRow
  sender?: Person
  responding: boolean
  onAccept?: () => void
  onDecline?: () => void
  redirectOpen?: boolean
  onToggleRedirect?: () => void
  redirectTargetId?: string
  onRedirectTargetChange?: (value: string) => void
  onRedirectToSenior?: () => void
  seniorName?: string
  onRedirectSubmit?: () => void
}) {
  const isPending = request.status === 'pending'
  return (
    <div className="rounded-2xl border border-border-light bg-page-bg p-4">
      <div className="flex items-start justify-between gap-3">
        <div className="min-w-0">
          <p className="truncate text-sm font-black text-text-main">
            {sender?.name ?? 'A student'} <span className="font-bold text-text-muted">· {request.topic}</span>
          </p>
          {sender?.reg_no && <p className="text-[10px] font-bold text-text-muted">{sender.reg_no}</p>}
        </div>
        {!isPending && <StatusChip status={request.status} />}
      </div>
      <p className="mt-2 text-xs leading-relaxed text-text-muted">{request.question}</p>
      <p className="mt-2 text-[10px] font-bold text-text-muted">{formatDate(request.created_at)}</p>

      {isPending &&
        (responding ? (
          <div className="mt-3 flex items-center gap-2 text-xs font-bold text-text-muted">
            <Loader2 className="h-4 w-4 animate-spin" /> Updating…
          </div>
        ) : (
          <div className="mt-3 space-y-2">
            <div className="flex flex-wrap items-center gap-2">
              <button
                onClick={onAccept}
                className="inline-flex items-center gap-1.5 rounded-xl bg-primary-purple px-4 py-2 text-xs font-black text-white hover:bg-deep-violet transition-colors"
              >
                <CheckCircle2 className="h-3.5 w-3.5" /> Accept
              </button>
              <button
                onClick={onDecline}
                className="inline-flex items-center gap-1.5 rounded-xl border border-border-light bg-white px-4 py-2 text-xs font-black text-text-main hover:bg-page-bg transition-colors"
              >
                <X className="h-3.5 w-3.5" /> Decline
              </button>
              <button
                onClick={onToggleRedirect}
                className="inline-flex items-center gap-1.5 rounded-xl border border-border-light bg-white px-4 py-2 text-xs font-black text-text-main hover:bg-page-bg transition-colors"
              >
                <CornerUpRight className="h-3.5 w-3.5" /> Redirect
              </button>
            </div>
            {redirectOpen && (
              <div className="space-y-2 rounded-xl border border-dashed border-border-light bg-white p-3">
                {onRedirectToSenior && (
                  <button onClick={onRedirectToSenior} className="text-xs font-bold text-primary-purple hover:underline">
                    Forward to {seniorName ?? 'your senior'}
                  </button>
                )}
                <div className="flex items-center gap-2">
                  <input
                    value={redirectTargetId ?? ''}
                    onChange={(e) => onRedirectTargetChange?.(e.target.value)}
                    placeholder="Or paste another PSGMX account ID"
                    className="flex-1 rounded-lg border border-border-light px-3 py-1.5 text-xs outline-none focus:border-primary-purple"
                  />
                  <button
                    onClick={onRedirectSubmit}
                    disabled={!redirectTargetId?.trim()}
                    className="rounded-lg bg-primary-purple px-3 py-1.5 text-[11px] font-black text-white disabled:opacity-40"
                  >
                    Send
                  </button>
                </div>
              </div>
            )}
          </div>
        ))}
    </div>
  )
}
