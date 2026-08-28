'use client'

import Link from 'next/link'
import { useRouter } from 'next/navigation'
import { FormEvent, useMemo, useState } from 'react'
import {
  ArrowLeft,
  ArrowRight,
  CheckCircle2,
  GraduationCap,
  Link2,
  Loader2,
  LockKeyhole,
  Mail,
  ShieldCheck,
  UserRound,
} from 'lucide-react'

type Step = 'profile' | 'otp' | 'success'

function batchSummary(regNo: string) {
  const match = regNo.trim().toUpperCase().match(/^(\d{2}MX)\d{3}$/)
  if (!match) return null
  const start = 2000 + Number(match[1].slice(0, 2))
  return { code: match[1], start, end: start + 2 }
}

export default function JoinAlumniPage() {
  const router = useRouter()
  const [step, setStep] = useState<Step>('profile')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')
  const [otp, setOtp] = useState('')
  const [form, setForm] = useState({ name: '', regNo: '', email: '', linkedin: '' })
  const batch = useMemo(() => batchSummary(form.regNo), [form.regNo])

  async function sendCode() {
    const response = await fetch('/api/auth/request-otp', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: form.email }),
    })
    const result = await response.json()
    if (!response.ok) throw new Error(result.error || 'The sign-in code could not be sent.')
    setMessage(result.message || 'A six-digit code has been sent.')
  }

  async function submitProfile(event: FormEvent) {
    event.preventDefault()
    setLoading(true)
    setError('')
    try {
      const response = await fetch('/api/auth/join-alumni', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(form),
      })
      const result = await response.json()
      if (!response.ok) throw new Error(result.error || 'Enrollment could not be completed.')
      await sendCode()
      setStep('otp')
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : 'Enrollment could not be completed.')
    } finally {
      setLoading(false)
    }
  }

  async function verifyCode(event: FormEvent) {
    event.preventDefault()
    setLoading(true)
    setError('')
    try {
      const response = await fetch('/api/auth/verify', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: form.email, token: otp }),
      })
      const result = await response.json()
      if (!response.ok) throw new Error(result.error || 'The code is invalid or expired.')
      setStep('success')
      window.setTimeout(() => router.replace(result.redirect || '/alumni'), 600)
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : 'The code could not be verified.')
    } finally {
      setLoading(false)
    }
  }

  async function resendCode() {
    setLoading(true)
    setError('')
    try {
      await sendCode()
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : 'The code could not be sent.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <main className="min-h-screen bg-[#FDF7F3] p-4 sm:p-8 lg:grid lg:place-items-center">
      <div className="mx-auto flex min-h-[720px] w-full max-w-[1160px] overflow-hidden rounded-[32px] border border-[#F3E9E1] bg-white p-3 shadow-[0_30px_90px_-35px_rgba(16,24,40,.28)]">
        <section className="relative hidden w-1/2 overflow-hidden rounded-[24px] bg-[#FFF4EC] lg:block">
          <img
            src="/auth/alumni.png"
            alt="Stay connected, give back and inspire the next generation through the PSGMX alumni community"
            className="h-full w-full object-contain"
          />
        </section>

        <section className="flex w-full items-center px-6 py-10 sm:px-14 lg:w-1/2">
          <div className="mx-auto w-full max-w-[430px]">
            <Link href="/login" className="mb-8 inline-flex items-center gap-2 text-sm font-bold text-[#667085] transition hover:text-[#FF5A1F]">
              <ArrowLeft className="h-4 w-4" /> Back to sign in
            </Link>

            {step === 'success' ? (
              <div className="py-16 text-center" aria-live="polite">
                <div className="mx-auto grid h-16 w-16 place-items-center rounded-2xl bg-[#ECFDF3] text-[#039855]">
                  <CheckCircle2 className="h-8 w-8" />
                </div>
                <h2 className="mt-6 text-3xl font-black text-[#101828]">Welcome back to PSGMX</h2>
                <p className="mt-3 text-sm leading-6 text-[#667085]">Your verified alumni workspace is opening now.</p>
                <Loader2 className="mx-auto mt-7 h-6 w-6 animate-spin text-[#FF5A1F]" />
              </div>
            ) : (
              <>
                <div className="flex items-center gap-3 text-xs font-black uppercase tracking-[.18em] text-[#98A2B3]">
                  <span className={`grid h-7 w-7 place-items-center rounded-full ${step === 'profile' ? 'bg-[#FF5A1F] text-white' : 'bg-[#ECFDF3] text-[#039855]'}`}>{step === 'profile' ? '1' : '✓'}</span>
                  Profile
                  <span className="h-px flex-1 bg-[#EAECF0]" />
                  <span className={`grid h-7 w-7 place-items-center rounded-full ${step === 'otp' ? 'bg-[#FF5A1F] text-white' : 'bg-[#F2F4F7] text-[#98A2B3]'}`}>2</span>
                  Verify
                </div>

                <h2 className="mt-7 text-4xl font-black tracking-tight text-[#101828]">
                  {step === 'profile' ? <>Join the <span className="text-[#FF5A1F]">alumni network</span></> : 'Check your email'}
                </h2>
                <p className="mt-2 text-sm leading-6 text-[#667085]">
                  {step === 'profile'
                    ? 'Your admission batch is derived from your MCA register number and securely linked to your profile.'
                    : <>Enter the six-digit code sent to <strong className="text-[#344054]">{form.email}</strong>.</>}
                </p>

                {error && <div className="mt-5 rounded-xl border border-red-100 bg-red-50 p-3 text-sm font-semibold text-red-700" role="alert">{error}</div>}
                {message && step === 'otp' && <div className="mt-5 rounded-xl border border-green-100 bg-green-50 p-3 text-sm font-semibold text-green-700">{message}</div>}

                {step === 'profile' ? (
                  <form onSubmit={submitProfile} className="mt-7 space-y-4">
                    <Field icon={<UserRound />} label="Full name">
                      <input required autoComplete="name" value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} placeholder="Your name as in department records" className="auth-input" />
                    </Field>
                    <Field icon={<GraduationCap />} label="MCA register number">
                      <input required value={form.regNo} onChange={(e) => setForm({ ...form, regNo: e.target.value.toUpperCase() })} placeholder="e.g. 21MX114" maxLength={7} className="auth-input uppercase" />
                    </Field>
                    <div className={`rounded-xl border px-4 py-3 text-sm ${batch ? 'border-[#FFD9C2] bg-[#FFF8F3]' : 'border-[#EAECF0] bg-[#F9FAFB]'}`}>
                      <div className="text-xs font-bold uppercase tracking-wider text-[#98A2B3]">Detected batch</div>
                      <div className="mt-1 font-black text-[#344054]">{batch ? `${batch.code} · ${batch.start}–${batch.end}` : 'Enter a valid register number'}</div>
                    </div>
                    <Field icon={<Mail />} label="Email for OTP">
                      <input required type="email" autoComplete="email" value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value.toLowerCase() })} placeholder="you@example.com" className="auth-input" />
                    </Field>
                    <Field icon={<Link2 />} label="LinkedIn profile (optional)">
                      <input type="url" value={form.linkedin} onChange={(e) => setForm({ ...form, linkedin: e.target.value })} placeholder="https://linkedin.com/in/username" className="auth-input" />
                    </Field>
                    <PrimaryButton loading={loading} label="Continue with secure OTP" />
                  </form>
                ) : (
                  <form onSubmit={verifyCode} className="mt-7 space-y-5">
                    <label className="block">
                      <span className="mb-2 block text-sm font-bold text-[#344054]">Six-digit verification code</span>
                      <input autoFocus required inputMode="numeric" pattern="[0-9]{6}" maxLength={6} value={otp} onChange={(e) => setOtp(e.target.value.replace(/\D/g, ''))} placeholder="000000" className="w-full rounded-xl border border-[#D0D5DD] px-4 py-4 text-center text-2xl font-black tracking-[.42em] text-[#101828] outline-none transition focus:border-[#FF5A1F] focus:ring-4 focus:ring-[#FF5A1F]/10" />
                    </label>
                    <PrimaryButton loading={loading} label="Verify and open alumni workspace" />
                    <button type="button" disabled={loading} onClick={resendCode} className="w-full text-sm font-bold text-[#667085] hover:text-[#FF5A1F] disabled:opacity-50">Send a new code</button>
                  </form>
                )}

                <div className="mt-7 flex items-center justify-center gap-2 text-xs font-semibold text-[#98A2B3]">
                  <ShieldCheck className="h-4 w-4" /> Passwordless. Batch-aware. One verified identity.
                </div>
              </>
            )}
          </div>
        </section>
      </div>
      <style jsx>{`
        .auth-input { width: 100%; border: 1px solid #d0d5dd; border-radius: 12px; padding: 14px 16px 14px 44px; color: #101828; font-size: 14px; outline: none; transition: border-color .2s, box-shadow .2s; }
        .auth-input:focus { border-color: #ff5a1f; box-shadow: 0 0 0 4px rgba(255,90,31,.1); }
      `}</style>
    </main>
  )
}

function Field({ icon, label, children }: { icon: React.ReactElement; label: string; children: React.ReactNode }) {
  return (
    <label className="block">
      <span className="mb-2 block text-sm font-bold text-[#344054]">{label}</span>
      <span className="relative block">
        <span className="pointer-events-none absolute left-4 top-3.5 z-10 text-[#98A2B3] [&>svg]:h-4 [&>svg]:w-4">{icon}</span>
        {children}
      </span>
    </label>
  )
}

function PrimaryButton({ loading, label }: { loading: boolean; label: string }) {
  return (
    <button disabled={loading} className="flex w-full items-center justify-center gap-2 rounded-xl bg-[#FF5A1F] py-3.5 text-sm font-black text-white shadow-[0_8px_24px_rgba(255,90,31,.25)] transition hover:-translate-y-0.5 hover:bg-[#E04812] disabled:translate-y-0 disabled:opacity-50">
      {loading ? <Loader2 className="h-5 w-5 animate-spin" /> : <><LockKeyhole className="h-4 w-4" />{label}<ArrowRight className="h-4 w-4" /></>}
    </button>
  )
}
