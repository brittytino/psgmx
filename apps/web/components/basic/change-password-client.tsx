'use client';

import React, { useEffect, useState } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { Eye, EyeOff, Lock, ShieldCheck, AlertCircle, CheckCircle2, Shield, LockKeyhole, UserCheck, ArrowRight } from 'lucide-react';

const RULES = [
  { label: 'Minimum 8 characters', test: (p: string) => p.length >= 8 },
  { label: 'One uppercase letter', test: (p: string) => /[A-Z]/.test(p) },
  { label: 'One number', test: (p: string) => /\d/.test(p) },
  { label: 'One special character', test: (p: string) => /[!@#$%^&*(),.?":{}|<>]/.test(p) },
];

export default function ChangePasswordClient() {
  const router = useRouter();
  const searchParams = useSearchParams();

  const [token, setToken]               = useState('');
  const [redirect, setRedirect]         = useState('/');
  const [currentPw, setCurrentPw]       = useState('');
  const [newPw, setNewPw]               = useState('');
  const [confirmPw, setConfirmPw]       = useState('');
  const [showCurrent, setShowCurrent]   = useState(false);
  const [showNew, setShowNew]           = useState(false);
  const [showConfirm, setShowConfirm]   = useState(false);
  const [loading, setLoading]           = useState(false);
  const [error, setError]               = useState('');
  const [success, setSuccess]           = useState(false);

  useEffect(() => {
    const stored = sessionStorage.getItem('auth_token');
    const dest   = sessionStorage.getItem('post_change_redirect') || searchParams.get('redirect') || '/';

    if (!stored) {
      router.replace('/');
      return;
    }
    setToken(stored);
    setRedirect(dest);
  }, [router, searchParams]);

  const rules = RULES.map(r => ({ ...r, passed: r.test(newPw) }));
  const passedRulesCount = rules.filter(r => r.passed).length;
  const allRulesPassed = passedRulesCount === RULES.length;
  const passwordsMatch = newPw === confirmPw && confirmPw.length > 0;

  let passwordStrength = 'Weak';
  let strengthColor = 'text-red-500';
  let barColor = 'bg-red-500 w-1/4';
  if (passedRulesCount === 2) { passwordStrength = 'Fair'; strengthColor = 'text-orange-500'; barColor = 'bg-orange-500 w-2/4'; }
  if (passedRulesCount === 3) { passwordStrength = 'Good'; strengthColor = 'text-electric-blue'; barColor = 'bg-electric-blue w-3/4'; }
  if (passedRulesCount === 4) { passwordStrength = 'Strong'; strengthColor = 'text-[#10B981]'; barColor = 'bg-[#10B981] w-full'; }
  if (newPw.length === 0) { barColor = 'bg-border-light w-0'; }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError('');

    if (!allRulesPassed) { setError('Password does not meet the requirements.'); return; }
    if (!passwordsMatch) { setError('Passwords do not match.'); return; }

    setLoading(true);
    try {
      const res = await fetch('/api/auth/change-password', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
        body: JSON.stringify({ currentPassword: currentPw, newPassword: newPw }),
      });
      const data = await res.json();
      if (!res.ok) { setError(data.error ?? 'Failed to change password'); return; }

      setSuccess(true);
      sessionStorage.removeItem('post_change_redirect');
      window.setTimeout(() => { window.location.href = redirect; }, 1500);
    } catch {
      setError('Network error. Please try again.');
    } finally {
      setLoading(false);
    }
  }

  if (success) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-[#F4F7FE] p-4 font-sans">
        <div className="w-full max-w-md rounded-[2rem] border border-border-light bg-white p-10 text-center shadow-xl">
          <div className="mx-auto mb-6 flex h-16 w-16 items-center justify-center rounded-full bg-[#F0FDF4] text-[#16A34A]">
            <CheckCircle2 className="h-8 w-8" />
          </div>
          <h2 className="mb-2 text-2xl font-bold text-text-main">Password Set Successfully</h2>
          <p className="text-text-muted mb-6">
            Your account is now secure. Redirecting you to your dashboard...
          </p>
          <div className="flex justify-center items-center gap-2 text-sm font-bold text-primary-purple">
            <div className="w-4 h-4 border-2 border-current border-t-transparent rounded-full animate-spin"></div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="h-screen w-screen bg-page-bg flex items-center justify-center overflow-hidden relative font-sans text-text-main">
      
      {/* Abstract Background Waves (Bottom Left) */}
      <div className="absolute bottom-0 left-0 w-[80%] h-[50%] pointer-events-none opacity-60 z-0">
        <svg viewBox="0 0 1440 320" className="absolute bottom-0 w-full h-full" preserveAspectRatio="none">
          <path fill="url(#wave-gradient-pwd)" fillOpacity="1" d="M0,288L48,272C96,256,192,224,288,197.3C384,171,480,149,576,165.3C672,181,768,235,864,250.7C960,267,1056,245,1152,213.3C1248,181,1344,139,1392,117.3L1440,96L1440,320L1392,320C1344,320,1248,320,1152,320C1056,320,960,320,864,320C768,320,672,320,576,320C480,320,384,320,288,320C192,320,96,320,48,320L0,320Z"></path>
          <defs>
            <linearGradient id="wave-gradient-pwd" x1="0%" y1="0%" x2="100%" y2="0%">
              <stop offset="0%" stopColor="#C4B5FD" stopOpacity="0.4" />
              <stop offset="50%" stopColor="#FBCFE8" stopOpacity="0.3" />
              <stop offset="100%" stopColor="#BAE6FD" stopOpacity="0.1" />
            </linearGradient>
          </defs>
        </svg>
      </div>

      {/* Main Container - Full Screen with consistent padding */}
      <div className="w-full h-full flex items-center justify-between relative z-10 px-8 lg:px-20 xl:px-32">
        
        {/* Left Section (Text + Illustration + Footer Features) */}
        <div className="w-[55%] xl:w-[60%] h-full flex flex-col justify-between py-[10vh]">
          
          <div className="max-w-[560px]">
            {/* Logo */}
            <div className="mb-10">
              <img src="/logo.webp" alt="PSGMX Logo" className="w-24 h-24 object-contain drop-shadow-md" />
            </div>

            {/* Badge */}
            <div className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-page-bg text-primary-purple text-[11px] font-bold tracking-widest uppercase mb-6 border border-[#E5D4FF]">
              <ShieldCheck className="w-3.5 h-3.5" /> Security Upgrade
            </div>

            {/* Title */}
            <h1 className="text-5xl xl:text-[3.5rem] font-bold tracking-tight leading-[1.15] text-text-main mb-5">
              Secure Your<br />
              Account
            </h1>

            {/* Paragraph */}
            <p className="text-text-muted text-[15px] xl:text-[17px] leading-relaxed max-w-[400px]">
              Create a strong password to protect your profile and continue your journey with PSGMX.
            </p>
            
            {/* 3D Shield CSS Placeholder */}
            <div className="w-full max-w-sm flex justify-center py-6 mt-4 relative">
              <div className="relative w-56 h-56 flex items-center justify-center">
                {/* Glowing Base */}
                <div className="absolute bottom-4 w-40 h-8 bg-primary-purple/20 rounded-full blur-md"></div>
                {/* Orb */}
                <div className="absolute inset-0 bg-gradient-to-tr from-[#6C3DFF]/20 to-[#3B82F6]/20 rounded-full blur-[40px]"></div>
                {/* Shield Body */}
                <div className="relative z-10 w-32 h-36 bg-gradient-to-b from-[#A78BFA] to-[#6C3DFF] rounded-2xl flex items-center justify-center shadow-2xl border border-white/20" style={{ clipPath: 'polygon(50% 0%, 100% 15%, 100% 65%, 50% 100%, 0 65%, 0 15%)' }}>
                  <LockKeyhole className="w-12 h-12 text-white" />
                </div>
              </div>
            </div>
          </div>

          {/* Bottom Features Row */}
          <div className="flex gap-10 mt-auto bg-white/50 backdrop-blur-sm py-4 px-6 rounded-2xl border border-border-light w-max">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-page-bg flex items-center justify-center shrink-0">
                <ShieldCheck className="w-5 h-5 text-primary-purple" />
              </div>
              <div>
                <h4 className="font-bold text-text-main text-[13px]">Secure</h4>
                <p className="text-[11px] text-text-muted max-w-[120px] leading-snug">Your data is encrypted and protected</p>
              </div>
            </div>
            
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-page-bg flex items-center justify-center shrink-0">
                <Lock className="w-5 h-5 text-primary-purple" />
              </div>
              <div>
                <h4 className="font-bold text-text-main text-[13px]">Private</h4>
                <p className="text-[11px] text-text-muted max-w-[120px] leading-snug">We never share your information</p>
              </div>
            </div>

            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-page-bg flex items-center justify-center shrink-0">
                <UserCheck className="w-5 h-5 text-primary-purple" />
              </div>
              <div>
                <h4 className="font-bold text-text-main text-[13px]">Verified</h4>
                <p className="text-[11px] text-text-muted max-w-[120px] leading-snug">Department verified platform</p>
              </div>
            </div>
          </div>

        </div>

        {/* Right Section (Form Card) */}
        <div className="w-[45%] xl:w-[40%] h-full flex items-center justify-end z-20">
          <div className="w-full max-w-[500px] bg-white rounded-[2rem] shadow-[0_20px_60px_-15px_rgba(0,0,0,0.06)] border border-border-light flex flex-col relative overflow-hidden">
            
            <div className="p-8 sm:p-10 flex-1">
              
              <div className="mb-8 relative z-10">
                <h2 className="text-[28px] font-bold tracking-tight text-text-main mb-1.5">Set a New Password</h2>
                <p className="text-[12px] text-text-muted">Your account requires a new password to ensure security.</p>
              </div>

              {error && (
                <div className="mb-6 bg-red-50 border border-red-100 text-red-600 text-[13px] px-4 py-3 rounded-xl flex items-center gap-2">
                  <AlertCircle className="w-4 h-4 shrink-0" />
                  <p className="font-semibold">{error}</p>
                </div>
              )}

              <form onSubmit={handleSubmit} className="space-y-5 relative z-10">
                
                {/* Temporary Password */}
                <div className="space-y-1.5">
                  <label className="text-[10px] font-bold text-primary-purple uppercase tracking-widest flex items-center gap-1.5">
                    <Lock className="w-[14px] h-[14px]" /> Temporary Password
                  </label>
                  <div className="relative group">
                    <input
                      type={showCurrent ? 'text' : 'password'}
                      required
                      placeholder="Enter your temporary password"
                      className="block w-full pl-11 pr-12 py-3.5 bg-white border border-border-light rounded-[10px] text-[14px] text-text-main placeholder-[#94A3B8] focus:border-primary-purple focus:ring-1 focus:ring-[#6C3DFF] focus:outline-none transition-colors"
                      value={currentPw}
                      onChange={(e) => setCurrentPw(e.target.value)}
                    />
                    <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                      <LockKeyhole className="w-[18px] h-[18px] text-[#CBD5E1]" />
                    </div>
                    <button
                      type="button"
                      onClick={() => setShowCurrent(!showCurrent)}
                      className="absolute inset-y-0 right-0 pr-4 flex items-center text-[#CBD5E1] hover:text-text-muted transition-colors"
                    >
                      {showCurrent ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                    </button>
                  </div>
                </div>

                {/* New Password */}
                <div className="space-y-1.5 pt-1">
                  <label className="text-[10px] font-bold text-primary-purple uppercase tracking-widest flex items-center gap-1.5">
                    <Lock className="w-[14px] h-[14px]" /> New Password
                  </label>
                  <div className="relative group">
                    <input
                      type={showNew ? 'text' : 'password'}
                      required
                      placeholder="Create a new password"
                      className="block w-full pl-11 pr-12 py-3.5 bg-white border border-border-light rounded-[10px] text-[14px] text-text-main placeholder-[#94A3B8] focus:border-primary-purple focus:ring-1 focus:ring-[#6C3DFF] focus:outline-none transition-colors"
                      value={newPw}
                      onChange={(e) => setNewPw(e.target.value)}
                    />
                    <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                      <LockKeyhole className="w-[18px] h-[18px] text-[#CBD5E1]" />
                    </div>
                    <button
                      type="button"
                      onClick={() => setShowNew(!showNew)}
                      className="absolute inset-y-0 right-0 pr-4 flex items-center text-[#CBD5E1] hover:text-text-muted transition-colors"
                    >
                      {showNew ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                    </button>
                  </div>
                  
                  {/* Strength Bar */}
                  <div className="pt-2">
                    <div className="h-1.5 w-full bg-page-bg rounded-full overflow-hidden">
                      <div className={`h-full transition-all duration-300 ${barColor}`}></div>
                    </div>
                    <p className="text-[11px] font-bold text-text-muted mt-2 flex gap-1">
                      Password strength: <span className={strengthColor}>{newPw.length > 0 ? passwordStrength : 'None'}</span>
                    </p>
                  </div>

                  {/* Rules Radio style */}
                  <div className="flex flex-wrap gap-x-5 gap-y-2.5 mt-4 text-[10px] font-bold text-text-muted">
                    {rules.map(r => (
                      <div key={r.label} className="flex items-center gap-1.5">
                        <div className={`w-3.5 h-3.5 rounded-full border-[1.5px] flex items-center justify-center transition-colors ${r.passed ? 'border-primary-purple bg-white' : 'border-border-light bg-transparent'}`}>
                          {r.passed && <div className="w-1.5 h-1.5 rounded-full bg-primary-purple"></div>}
                        </div>
                        <span className={r.passed ? 'text-text-main' : ''}>{r.label}</span>
                      </div>
                    ))}
                  </div>
                </div>

                {/* Confirm Password */}
                <div className="space-y-1.5 pt-3">
                  <label className="text-[10px] font-bold text-primary-purple uppercase tracking-widest flex items-center gap-1.5">
                    <Lock className="w-[14px] h-[14px]" /> Confirm New Password
                  </label>
                  <div className="relative group">
                    <input
                      type={showConfirm ? 'text' : 'password'}
                      required
                      placeholder="Confirm your new password"
                      className={`block w-full pl-11 pr-12 py-3.5 bg-white border rounded-[10px] text-[14px] text-text-main placeholder-[#94A3B8] focus:outline-none transition-colors ${
                        confirmPw.length > 0
                          ? passwordsMatch
                            ? 'border-[#10B981] focus:ring-1 focus:ring-[#10B981]'
                            : 'border-red-300 focus:border-red-500 focus:ring-1 focus:ring-red-500'
                          : 'border-border-light focus:border-primary-purple focus:ring-1 focus:ring-[#6C3DFF]'
                      }`}
                      value={confirmPw}
                      onChange={(e) => setConfirmPw(e.target.value)}
                    />
                    <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                      <LockKeyhole className="w-[18px] h-[18px] text-[#CBD5E1]" />
                    </div>
                    <button
                      type="button"
                      onClick={() => setShowConfirm(!showConfirm)}
                      className="absolute inset-y-0 right-0 pr-4 flex items-center text-[#CBD5E1] hover:text-text-muted transition-colors"
                    >
                      {showConfirm ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                    </button>
                  </div>
                  {confirmPw.length > 0 && !passwordsMatch && (
                    <p className="text-[11px] font-bold text-red-500 pt-1">Passwords do not match</p>
                  )}
                </div>

                <button
                  type="submit"
                  disabled={loading || !allRulesPassed || !passwordsMatch}
                  className="w-full bg-gradient-to-r from-[#7E22CE] to-[#2563EB] hover:opacity-95 text-white font-semibold py-3.5 rounded-xl transition-all duration-300 disabled:opacity-50 flex items-center justify-center gap-2 mt-2 text-[14px]"
                >
                  <ShieldCheck className="w-[18px] h-[18px]" />
                  {loading ? 'Updating...' : 'Update Password & Continue'}
                  {!loading && <ArrowRight className="w-4 h-4" />}
                </button>
              </form>
            </div>
            
            {/* Footer attached seamlessly with a light background */}
            <div className="bg-page-bg border-t border-border-light p-6 text-center">
              <div className="flex justify-center items-center gap-1.5 text-electric-blue font-bold text-[12px] mb-1">
                <ShieldCheck className="w-4 h-4" /> Your security is our priority
              </div>
              <p className="text-[10px] font-bold text-text-muted">
                PSGMX • Secure Platform for MCA Department
              </p>
            </div>

          </div>
        </div>

      </div>
    </div>
  );
}
