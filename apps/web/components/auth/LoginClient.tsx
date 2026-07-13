'use client';

import React, { useState, Suspense } from 'react';
import { User, Lock, Eye, EyeOff, ArrowRight, ShieldCheck, Heart, Loader2, ShieldAlert } from 'lucide-react';
import { useRouter, useSearchParams } from 'next/navigation';
import Link from 'next/link';

function LoginForm() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const redirectTo = searchParams.get('redirect');

  const [identifier, setIdentifier] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  async function handleLogin(e: React.FormEvent) {
    e.preventDefault();
    if (!identifier.trim() || !password.trim()) return;
    
    setError('');
    setLoading(true);
    
    try {
      const res = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ identifier: identifier.trim(), password }),
      });
      
      const data = await res.json();
      
      if (!res.ok) {
        setError(data.error ?? 'Invalid identifier or password');
        return;
      }
      // If the URL tried to bounce us through /app, bypass it completely to avoid Next.js routing bugs
      // Use hard navigation to bypass Next.js router bug and ensure cookies are picked up by the server
      const finalRedirect = (redirectTo && redirectTo !== '/app') ? redirectTo : (data.redirect || '/student');
      window.location.href = finalRedirect;
    } catch {
      setError('Network error. Please check your connection and try again.');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="min-h-screen w-full bg-[#FDF7F3] flex items-center justify-center p-4 sm:p-6 lg:p-8 font-sans">
      
      {/* Main Container - The White Card */}
      <div className="w-full max-w-[1200px] bg-white rounded-[32px] shadow-[0_20px_60px_-15px_rgba(0,0,0,0.05)] flex flex-col lg:flex-row p-3">
        
        {/* Left Side - Image/Text Container */}
        <div className="hidden lg:flex lg:w-[50%] bg-[#FDF8F3] rounded-[24px] overflow-hidden flex-col relative pt-12 px-12 pb-0">
          
          {/* Logo */}
          <div className="mb-10 flex items-center gap-2">
             <img src="/logo.webp" alt="PSGMX" className="w-8 h-8" />
             <span className="font-bold text-[22px] tracking-tight text-[#1E293B]">PSGMX</span>
          </div>
          
          {/* Text Content */}
          <div className="relative z-10 mb-4">
            <h1 className="text-[44px] font-bold tracking-tight text-[#101828] mb-1 leading-[1.1]">
              Your journey.<br/>
              <span className="text-[#FF5A1F]">Our mission.</span>
            </h1>
            <p className="text-[#475467] text-[15px] max-w-[380px] leading-[1.6] mt-4">
              PSGMX is the placement operating system for PSG Tech MCA. Track, prepare, collaborate and succeed—together.
            </p>
          </div>

          {/* Mascot Image */}
          <div className="flex-grow w-full relative mt-[-20px] flex items-end justify-center">
            <img 
              src="/auth/login.png" 
              alt="PSGMX Mascot" 
              className="w-[110%] max-w-none object-contain object-bottom origin-bottom"
              style={{ objectPosition: 'center bottom' }}
            />
          </div>
        </div>

        {/* Right Side - Form */}
        <div className="w-full lg:w-[50%] flex flex-col justify-center px-6 sm:px-16 py-10 lg:py-16 bg-white">
          <div className="w-full max-w-[420px] mx-auto">
            
            {/* Tag */}
            <div className="flex mb-5">
              <div className="flex items-center gap-1.5 px-3 py-1 rounded-full bg-[#FFF0E6] text-[#FF5A1F] text-[12px] font-bold">
                <Heart className="w-3.5 h-3.5 fill-current" />
                Welcome Back
              </div>
            </div>

            {/* Headers */}
            <h1 className="text-[36px] sm:text-[40px] font-bold tracking-tight text-[#101828] mb-1.5 leading-tight">
              Sign in to <span className="text-[#FF5A1F]">PSGMX</span>
            </h1>
            <p className="text-[#475467] text-[15px] mb-8 font-medium">
              Access your department ecosystem
            </p>

            {/* Error Message */}
            {error && (
              <div className="mb-6 bg-red-50 border border-red-100 text-red-600 text-[13px] px-4 py-3 rounded-[12px] flex items-center gap-2">
                <ShieldAlert className="w-4 h-4 shrink-0" />
                <p className="font-semibold">{error}</p>
              </div>
            )}

            {/* Form */}
            <form onSubmit={handleLogin} className="space-y-4">
              
              <div className="space-y-1.5">
                <label className="block text-[13px] font-bold text-[#101828]">
                  Identifier
                </label>
                <div className="relative">
                  <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                    <User className="h-[18px] w-[18px] text-[#98A2B3]" />
                  </div>
                  <input
                    type="text"
                    required
                    value={identifier}
                    onChange={e => setIdentifier(e.target.value)}
                    className="block w-full pl-11 pr-4 py-3.5 bg-white border border-[#D0D5DD] rounded-[12px] text-[15px] text-[#101828] placeholder-[#98A2B3] focus:border-[#FF5A1F] focus:ring-1 focus:ring-[#FF5A1F] focus:outline-none transition-colors"
                    placeholder="Email or Token (e.g. 25MX301)"
                    autoComplete="username"
                  />
                </div>
              </div>

              <div className="space-y-1.5">
                <label className="block text-[13px] font-bold text-[#101828]">
                  Access Key
                </label>
                <div className="relative">
                  <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                    <Lock className="h-[18px] w-[18px] text-[#98A2B3]" />
                  </div>
                  <input
                    type={showPassword ? 'text' : 'password'}
                    required
                    value={password}
                    onChange={e => setPassword(e.target.value)}
                    className="block w-full pl-11 pr-11 py-3.5 bg-white border border-[#D0D5DD] rounded-[12px] text-[15px] text-[#101828] placeholder-[#98A2B3] focus:border-[#FF5A1F] focus:ring-1 focus:ring-[#FF5A1F] focus:outline-none transition-colors"
                    placeholder="Enter your password"
                    autoComplete="current-password"
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute inset-y-0 right-0 pr-4 flex items-center text-[#98A2B3] hover:text-[#101828] transition-colors"
                  >
                    {showPassword ? <EyeOff className="h-[18px] w-[18px]" /> : <Eye className="h-[18px] w-[18px]" />}
                  </button>
                </div>
              </div>

              <div className="flex items-center justify-between pt-1 pb-1">
                <label className="flex items-center gap-2 cursor-pointer group">
                  <div className="w-[18px] h-[18px] rounded-[5px] bg-[#FF5A1F] flex items-center justify-center shadow-sm">
                    <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round"><polyline points="20 6 9 17 4 12"></polyline></svg>
                  </div>
                  <span className="text-[14px] font-medium text-[#475467] group-hover:text-[#101828] transition-colors">Remember me</span>
                </label>
                <Link href="/forgot-password" className="text-[14px] font-medium text-[#FF5A1F] hover:text-[#E04812] transition-colors">
                  Forgot password?
                </Link>
              </div>

              <button
                type="submit"
                disabled={loading}
                className="w-full bg-[#FF5A1F] hover:bg-[#E04812] text-white font-semibold py-3.5 rounded-[12px] transition-all disabled:opacity-50 flex items-center justify-center gap-2 mt-2 text-[16px] shadow-[0_4px_14px_rgba(255,90,31,0.25)]"
              >
                {loading ? (
                  <><Loader2 className="w-5 h-5 animate-spin" /> Authenticating...</>
                ) : (
                  <>Enter System <ArrowRight className="w-4 h-4" /></>
                )}
              </button>
            </form>

            {/* Divider */}
            <div className="relative my-8">
              <div className="absolute inset-0 flex items-center">
                <div className="w-full border-t border-[#F2F4F7]" />
              </div>
              <div className="relative flex justify-center text-xs">
                <span className="px-3 bg-white text-[#98A2B3] font-medium tracking-wide text-[12px]">OR</span>
              </div>
            </div>

            {/* Alumni join */}
            <button
              onClick={() => router.push('/join-alumni')}
              className="w-full group bg-[#FFF9F5] hover:bg-[#FFF0E6] rounded-[16px] p-4 transition-colors flex items-center justify-between text-left border border-transparent"
            >
              <div className="flex items-center gap-4">
                <div className="w-[42px] h-[42px] rounded-full bg-white flex items-center justify-center shrink-0 text-[#FF5A1F] shadow-sm">
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><path d="M22 10v6M2 10l10-5 10 5-10 5z"/><path d="M6 12v5c3 3 9 3 12 0v-5"/></svg>
                </div>
                <div>
                  <h4 className="font-bold text-[#101828] text-[14px]">Join Alumni Network</h4>
                  <p className="text-[13px] text-[#475467]">
                    Are you an alumnus?
                  </p>
                </div>
              </div>
              <div className="px-3.5 py-1.5 rounded-full border border-[#FF5A1F] text-[#FF5A1F] text-[12px] font-bold flex items-center gap-1.5 group-hover:bg-[#FF5A1F] group-hover:text-white transition-colors bg-transparent">
                Join now <ArrowRight className="w-3.5 h-3.5" />
              </div>
            </button>

            {/* Footer */}
            <div className="mt-10 flex justify-center items-center gap-1.5 text-[#98A2B3]">
              <ShieldCheck className="w-4 h-4" />
              <p className="text-[12px] font-medium">
                Secure. Private. Built for PSG Tech MCA.
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
      <div className="min-h-screen w-full bg-[#FDF7F3] flex items-center justify-center">
        <Loader2 className="w-8 h-8 animate-spin text-[#FF5A1F]" />
      </div>
    }>
      <LoginForm />
    </Suspense>
  );
}
