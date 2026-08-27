'use client'

import React, { Suspense } from 'react'
import { ArrowRight, Heart, Loader2, Mail, ShieldAlert, ShieldCheck } from 'lucide-react'
import { useSearchParams } from 'next/navigation'

function LoginForm() {
  const searchParams = useSearchParams()
  const redirectTo = searchParams.get('redirect')
  const [mode, setMode] = React.useState<'student' | 'staff'>('student')
  const [email, setEmail] = React.useState('')
  const [otp, setOtp] = React.useState('')
  const [otpSent, setOtpSent] = React.useState(false)
  const [loading, setLoading] = React.useState(false)
  const [error, setError] = React.useState('')
  const [message, setMessage] = React.useState('')

  async function submitOtp(event: React.FormEvent) {
    event.preventDefault(); setLoading(true); setError(''); setMessage('')
    try {
      const response = await fetch(otpSent ? '/api/auth/verify' : '/api/auth/request-otp', {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(otpSent ? { email, token: otp } : { email }),
      })
      const result = await response.json()
      if (!response.ok) return setError(result.error ?? 'Sign in failed.')
      if (!otpSent) { setOtpSent(true); setMessage(result.message) }
      else window.location.href = (redirectTo && redirectTo !== '/app') ? redirectTo : (result.redirect || (mode === 'staff' ? '/faculty' : '/student'))
    } catch { setError('Network error. Check your connection and try again.') }
    finally { setLoading(false) }
  }

  return <main className="min-h-screen bg-[#FDF7F3] p-4 sm:p-8 lg:flex lg:items-center lg:justify-center">
    <div className="mx-auto flex min-h-[680px] w-full max-w-[1160px] overflow-hidden rounded-[32px] bg-white p-3 shadow-[0_24px_80px_-24px_rgba(16,24,40,.18)]">
      <section className="relative hidden w-1/2 flex-col overflow-hidden rounded-[24px] bg-[#FFF4EC] p-12 lg:flex">
        <div className="flex items-center gap-2"><img src="/logo.webp" alt="PSGMX" className="h-9 w-9" /><span className="text-xl font-black">PSGMX</span></div>
        <div className="relative z-10 mt-20"><h1 className="text-5xl font-black leading-[1.08] tracking-tight text-[#101828]">Five focused minutes.<br/><span className="text-[#FF5A1F]">A stronger placement day.</span></h1><p className="mt-5 max-w-md text-base leading-7 text-[#475467]">Attendance, Daily Five, today’s quest and batch updates—one calm routine for 25MX and 26MX.</p></div>
        <img src="/auth/login.png" alt="PSGMX student experience" className="absolute bottom-0 right-0 w-[92%] object-contain" />
      </section>
      <section className="flex w-full items-center px-6 py-12 sm:px-14 lg:w-1/2">
        <div className="mx-auto w-full max-w-[420px]">
          <div className="inline-flex items-center gap-2 rounded-full bg-[#FFF0E6] px-3 py-1.5 text-xs font-black text-[#FF5A1F]"><Heart className="h-3.5 w-3.5 fill-current" />Welcome back</div>
          <h2 className="mt-5 text-4xl font-black tracking-tight text-[#101828]">Sign in to <span className="text-[#FF5A1F]">PSGMX</span></h2>
          <p className="mt-2 text-sm text-[#667085]">{mode === 'staff' ? 'Use your department @psgtech.ac.in email. A six-digit code will be sent.' : 'Use the personal or college email approved on your roster.'}</p>

          <div className="mt-7 grid grid-cols-2 rounded-xl bg-[#F2F4F7] p-1 text-sm font-bold">
            <button type="button" onClick={() => { setMode('student'); setError(''); setMessage(''); setOtpSent(false); setOtp('') }} className={`rounded-lg px-3 py-2.5 ${mode === 'student' ? 'bg-white text-[#FF5A1F] shadow-sm' : 'text-[#667085]'}`}>Student OTP</button>
            <button type="button" onClick={() => { setMode('staff'); setError(''); setMessage(''); setOtpSent(false); setOtp('') }} className={`rounded-lg px-3 py-2.5 ${mode === 'staff' ? 'bg-white text-[#FF5A1F] shadow-sm' : 'text-[#667085]'}`}>Faculty / HOD</button>
          </div>

          {error && <div className="mt-5 flex gap-2 rounded-xl border border-red-100 bg-red-50 p-3 text-sm font-semibold text-red-700"><ShieldAlert className="h-4 w-4 shrink-0" />{error}</div>}
          {message && <div className="mt-5 rounded-xl border border-green-100 bg-green-50 p-3 text-sm font-semibold text-green-700">{message}</div>}

          <form onSubmit={submitOtp} className="mt-6 space-y-4">
            <label className="block"><span className="mb-1.5 block text-sm font-bold text-[#101828]">Email address</span><div className="relative"><Mail className="absolute left-4 top-4 h-4 w-4 text-[#98A2B3]" /><input type="email" required value={email} disabled={otpSent} onChange={(e) => setEmail(e.target.value.toLowerCase())} placeholder={mode === 'staff' ? 'name.mca@psgtech.ac.in' : 'you@example.com'} autoComplete="email" className="w-full rounded-xl border border-[#D0D5DD] py-3.5 pl-11 pr-4 text-sm outline-none focus:border-[#FF5A1F] disabled:bg-[#F9FAFB]" /></div></label>
            {otpSent && <label className="block"><span className="mb-1.5 block text-sm font-bold">Six-digit code</span><input autoFocus inputMode="numeric" pattern="[0-9]{6}" maxLength={6} required value={otp} onChange={(e) => setOtp(e.target.value.replace(/\D/g, ''))} placeholder="000000" className="w-full rounded-xl border border-[#D0D5DD] px-4 py-3.5 text-center text-xl font-black tracking-[.45em] outline-none focus:border-[#FF5A1F]" /></label>}
            <button disabled={loading} className="flex w-full items-center justify-center gap-2 rounded-xl bg-[#FF5A1F] py-3.5 text-base font-bold text-white shadow-[0_8px_24px_rgba(255,90,31,.25)] transition hover:bg-[#E04812] disabled:opacity-50">{loading ? <Loader2 className="h-5 w-5 animate-spin" /> : <>{otpSent ? 'Verify and continue' : 'Send secure code'}<ArrowRight className="h-4 w-4" /></>}</button>
            {otpSent && <button type="button" onClick={() => { setOtpSent(false); setOtp(''); setMessage('') }} className="w-full text-sm font-bold text-[#667085]">Use a different email</button>}
          </form>
          <div className="mt-8 flex items-center justify-center gap-2 text-xs font-semibold text-[#98A2B3]"><ShieldCheck className="h-4 w-4" />One student profile, whichever approved email you use.</div>
        </div>
      </section>
    </div>
  </main>
}

export default function LoginClient() {
  return <Suspense fallback={<div className="grid min-h-screen place-items-center bg-[#FDF7F3]"><Loader2 className="h-8 w-8 animate-spin text-[#FF5A1F]" /></div>}><LoginForm /></Suspense>
}
