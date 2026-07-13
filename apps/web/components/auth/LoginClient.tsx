'use client';

import React, { useState, useEffect, Suspense } from 'react';
import {
  Mail, ArrowRight, ShieldCheck, GraduationCap, Users,
  BrainCircuit, BookOpen, LineChart, Target, Loader2,
  KeyRound, ChevronLeft, ShieldAlert
} from 'lucide-react';
import { useRouter, useSearchParams } from 'next/navigation';

type Step = 'email' | 'otp';

function LoginForm() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const redirectTo = searchParams.get('redirect') || '/student';

  const [step, setStep] = useState<Step>('email');
  const [email, setEmail] = useState('');
  const [otp, setOtp] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [countdown, setCountdown] = useState(0);

  // Resend OTP countdown
  useEffect(() => {
    if (countdown <= 0) return;
    const t = setTimeout(() => setCountdown(c => c - 1), 1000);
    return () => clearTimeout(t);
  }, [countdown]);

  async function handleSendOtp(e: React.FormEvent) {
    e.preventDefault();
    if (!email.trim()) return;
    setError('');
    setLoading(true);
    try {
      const res = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: email.trim().toLowerCase() }),
      });
      const data = await res.json();
      if (!res.ok) {
        setError(data.error ?? 'Failed to send OTP. Please try again.');
        return;
      }
      setStep('otp');
      setCountdown(60);
    } catch {
      setError('Network error. Please check your connection and try again.');
    } finally {
      setLoading(false);
    }
  }

  async function handleVerifyOtp(e: React.FormEvent) {
    e.preventDefault();
    if (!otp.trim()) return;
    setError('');
    setLoading(true);
    try {
      const res = await fetch('/api/auth/verify', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: email.trim().toLowerCase(), token: otp.trim() }),
      });
      const data = await res.json();
      if (!res.ok) {
        setError(data.error ?? 'Invalid OTP. Please check and try again.');
        return;
      }
      // Redirect to role-based path or the originally requested path
      const finalRedirect = redirectTo !== '/student' ? redirectTo : (data.redirect || '/student');
      router.push(finalRedirect);
    } catch {
      setError('Network error. Please check your connection and try again.');
    } finally {
      setLoading(false);
    }
  }

  async function handleResendOtp() {
    if (countdown > 0) return;
    setError('');
    setCountdown(60);
    try {
      await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: email.trim().toLowerCase() }),
      });
    } catch {
      setError('Failed to resend OTP.');
    }
  }

  return (
    <div className="h-screen w-screen bg-[#F8F9FC] flex items-center justify-center overflow-hidden relative font-sans text-[#1E293B]">

      {/* Background wave */}
      <div className="absolute bottom-0 left-0 w-[80%] h-[50%] pointer-events-none opacity-60 z-0">
        <svg viewBox="0 0 1440 320" className="absolute bottom-0 w-full h-full" preserveAspectRatio="none">
          <path fill="url(#wave-grad)" fillOpacity="1" d="M0,288L48,272C96,256,192,224,288,197.3C384,171,480,149,576,165.3C672,181,768,235,864,250.7C960,267,1056,245,1152,213.3C1248,181,1344,139,1392,117.3L1440,96L1440,320L1392,320C1344,320,1248,320,1152,320C1056,320,960,320,864,320C768,320,672,320,576,320C480,320,384,320,288,320C192,320,96,320,48,320L0,320Z" />
          <defs>
            <linearGradient id="wave-grad" x1="0%" y1="0%" x2="100%" y2="0%">
              <stop offset="0%" stopColor="#C4B5FD" stopOpacity="0.4" />
              <stop offset="50%" stopColor="#FBCFE8" stopOpacity="0.3" />
              <stop offset="100%" stopColor="#BAE6FD" stopOpacity="0.1" />
            </linearGradient>
          </defs>
        </svg>
      </div>

      <div className="w-full h-full flex items-center justify-between relative z-10 px-8 lg:px-20 xl:px-32">

        {/* Left section — info */}
        <div className="hidden lg:flex w-[55%] xl:w-[60%] h-full flex-col justify-center">
          <div className="max-w-[560px]">
            <div className="mb-10">
              <img src="/logo.webp" alt="PSGMX Logo" className="w-24 h-24 object-contain drop-shadow-md" />
            </div>
            <h1 className="text-5xl xl:text-[3.8rem] font-bold tracking-tight leading-[1.15] text-[#1E293B] mb-5">
              Your Department.<br />
              Your Legacy.<br />
              <span className="text-transparent bg-clip-text bg-gradient-to-r from-[#6C3DFF] to-[#3B82F6]">
                Powered by Intelligence.
              </span>
            </h1>
            <p className="text-[#64748B] text-[15px] xl:text-[17px] leading-relaxed max-w-[420px] mb-12">
              PSGMX is the unified digital ecosystem for the MCA Department — built for collaboration, knowledge sharing, and placement excellence.
            </p>
            <div className="grid grid-cols-2 gap-6">
              {[
                { icon: BrainCircuit, color: '#6C3DFF', bg: '#F5F3FF', title: 'AI Senior', desc: 'Get instant, context-aware answers from your department\'s AI mentor.' },
                { icon: BookOpen, color: '#3B82F6', bg: '#EFF6FF', title: 'Knowledge Brain', desc: 'Access curated guides, survival notes, and alumni experiences.' },
                { icon: LineChart, color: '#10B981', bg: '#F0FDF4', title: 'Readiness Score', desc: 'Track your placement readiness score in real time across all four inputs.' },
                { icon: Target, color: '#F97316', bg: '#FFF7ED', title: 'Mock Exams', desc: 'Sit proctored mock exams that update your readiness score instantly.' },
              ].map(({ icon: Icon, color, bg, title, desc }) => (
                <div key={title} className="bg-white rounded-[1.25rem] p-5 shadow-[0_8px_30px_rgb(0,0,0,0.04)] border border-[#F1F5F9]">
                  <div className="w-10 h-10 rounded-full flex items-center justify-center mb-3" style={{ background: bg }}>
                    <Icon className="w-5 h-5" style={{ color }} />
                  </div>
                  <h3 className="font-bold text-[#1E293B] text-[14px] mb-1">{title}</h3>
                  <p className="text-xs text-[#64748B] leading-relaxed">{desc}</p>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Right section — form */}
        <div className="w-full lg:w-[45%] xl:w-[40%] h-full flex items-center justify-end z-20">
          <div className="w-full max-w-[480px] bg-white rounded-3xl shadow-[0_20px_60px_-15px_rgba(0,0,0,0.08)] border border-[#F1F5F9] flex flex-col p-8 sm:p-10">

            {/* Header */}
            <div className="flex justify-center mb-5">
              <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-[#EFF6FF] text-[#2563EB] text-[11px] font-bold">
                <GraduationCap className="w-3.5 h-3.5" />
                {step === 'email' ? 'Welcome Back' : 'Check Your Email'}
              </div>
            </div>
            <h2 className="text-[26px] font-bold tracking-tight text-[#1E293B] text-center mb-1.5">
              {step === 'email' ? 'Sign in to PSGMX' : 'Enter your OTP'}
            </h2>
            <p className="text-[12px] text-[#64748B] text-center mb-8">
              {step === 'email'
                ? 'Enter your @psgtech.ac.in email to receive a one-time passcode'
                : `We sent a 6-digit code to ${email}`}
            </p>

            {/* Error */}
            {error && (
              <div className="mb-6 bg-red-50 border border-red-100 text-red-600 text-[13px] px-4 py-3 rounded-xl flex items-center gap-2">
                <ShieldAlert className="w-4 h-4 shrink-0" />
                <p className="font-semibold">{error}</p>
              </div>
            )}

            {/* Email step */}
            {step === 'email' && (
              <form onSubmit={handleSendOtp} className="space-y-5">
                <div className="space-y-1.5">
                  <label className="block text-[10px] font-bold text-[#94A3B8] tracking-widest pl-1 uppercase">
                    PSG Tech Email
                  </label>
                  <div className="relative">
                    <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                      <Mail className="h-[18px] w-[18px] text-[#CBD5E1]" />
                    </div>
                    <input
                      type="email"
                      required
                      value={email}
                      onChange={e => setEmail(e.target.value)}
                      className="block w-full pl-11 pr-4 py-3.5 bg-white border border-[#E2E8F0] rounded-[10px] text-[14px] text-[#1E293B] placeholder-[#94A3B8] focus:border-[#6C3DFF] focus:ring-1 focus:ring-[#6C3DFF] focus:outline-none transition-colors"
                      placeholder="yourname@psgtech.ac.in"
                      autoComplete="email"
                      autoFocus
                    />
                  </div>
                </div>

                <button
                  type="submit"
                  disabled={loading}
                  className="w-full bg-gradient-to-r from-[#7E22CE] to-[#2563EB] hover:opacity-95 text-white font-semibold py-3.5 rounded-xl transition-opacity disabled:opacity-50 flex items-center justify-center gap-2 text-[14px]"
                >
                  {loading ? (
                    <><Loader2 className="w-4 h-4 animate-spin" /> Sending OTP...</>
                  ) : (
                    <>Send One-Time Passcode <ArrowRight className="w-4 h-4" /></>
                  )}
                </button>
              </form>
            )}

            {/* OTP step */}
            {step === 'otp' && (
              <form onSubmit={handleVerifyOtp} className="space-y-5">
                <div className="space-y-1.5">
                  <label className="block text-[10px] font-bold text-[#94A3B8] tracking-widest pl-1 uppercase">
                    One-Time Passcode
                  </label>
                  <div className="relative">
                    <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                      <KeyRound className="h-[18px] w-[18px] text-[#CBD5E1]" />
                    </div>
                    <input
                      type="text"
                      required
                      value={otp}
                      onChange={e => setOtp(e.target.value.replace(/\D/g, '').slice(0, 6))}
                      className="block w-full pl-11 pr-4 py-3.5 bg-white border border-[#E2E8F0] rounded-[10px] text-[14px] text-[#1E293B] placeholder-[#94A3B8] focus:border-[#6C3DFF] focus:ring-1 focus:ring-[#6C3DFF] focus:outline-none transition-colors tracking-[0.3em] font-bold text-center"
                      placeholder="••••••"
                      inputMode="numeric"
                      autoComplete="one-time-code"
                      autoFocus
                      maxLength={6}
                    />
                  </div>
                </div>

                <button
                  type="submit"
                  disabled={loading || otp.length < 6}
                  className="w-full bg-gradient-to-r from-[#7E22CE] to-[#2563EB] hover:opacity-95 text-white font-semibold py-3.5 rounded-xl transition-opacity disabled:opacity-50 flex items-center justify-center gap-2 text-[14px]"
                >
                  {loading ? (
                    <><Loader2 className="w-4 h-4 animate-spin" /> Verifying...</>
                  ) : (
                    <>Verify & Enter System <ArrowRight className="w-4 h-4" /></>
                  )}
                </button>

                <div className="flex items-center justify-between pt-1">
                  <button
                    type="button"
                    onClick={() => { setStep('email'); setOtp(''); setError(''); }}
                    className="text-[12px] font-bold text-[#64748B] hover:text-[#1E293B] transition-colors flex items-center gap-1"
                  >
                    <ChevronLeft className="w-3.5 h-3.5" /> Change email
                  </button>
                  <button
                    type="button"
                    onClick={handleResendOtp}
                    disabled={countdown > 0}
                    className="text-[12px] font-bold text-[#2563EB] hover:text-[#6C3DFF] transition-colors disabled:text-[#94A3B8] disabled:cursor-not-allowed"
                  >
                    {countdown > 0 ? `Resend in ${countdown}s` : 'Resend OTP'}
                  </button>
                </div>
              </form>
            )}

            {/* Divider */}
            <div className="relative my-7">
              <div className="absolute inset-0 flex items-center">
                <div className="w-full border-t border-[#F1F5F9]" />
              </div>
              <div className="relative flex justify-center text-xs">
                <span className="px-3 bg-white text-[#94A3B8] font-bold uppercase tracking-widest text-[10px]">OR</span>
              </div>
            </div>

            {/* Alumni join */}
            <button
              onClick={() => router.push('/join-alumni')}
              className="w-full group bg-[#F8F9FC] hover:bg-[#F1F5F9] border border-[#E2E8F0] rounded-[1rem] p-4 transition-colors flex items-center gap-4 text-left"
            >
              <div className="w-[38px] h-[38px] rounded-full bg-white border border-[#E2E8F0] flex items-center justify-center shrink-0 text-[#6C3DFF] shadow-sm">
                <Users className="w-[18px] h-[18px]" />
              </div>
              <div className="flex-1">
                <h4 className="font-bold text-[#1E293B] text-[13px]">Join Alumni Network</h4>
                <p className="text-[11px] text-[#64748B] mt-0.5 flex items-center gap-1">
                  Are you an alumnus?{' '}
                  <span className="text-[#2563EB] font-bold flex items-center">
                    Join now <ArrowRight className="w-3 h-3 ml-0.5" />
                  </span>
                </p>
              </div>
            </button>

            {/* Footer */}
            <div className="mt-7 pt-5 flex justify-center items-center gap-2">
              <ShieldCheck className="w-[16px] h-[16px] text-[#10B981]" />
              <p className="text-[11px] font-bold text-[#64748B]">
                Secure &bull; Private &bull; Department Verified
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

export default function LoginClient() {
  return (
    <Suspense fallback={
      <div className="h-screen w-screen bg-[#F8F9FC] flex items-center justify-center">
        <Loader2 className="w-8 h-8 animate-spin text-[#6C3DFF]" />
      </div>
    }>
      <LoginForm />
    </Suspense>
  );
}
