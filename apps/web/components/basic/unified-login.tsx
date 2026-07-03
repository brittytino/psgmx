'use client';

import React, { useState } from 'react';
import { ShieldAlert, Eye, EyeOff, User, Lock, ArrowRight, BrainCircuit, BookOpen, LineChart, Target, GraduationCap, Users, ShieldCheck } from 'lucide-react';
import { useRouter } from 'next/navigation';

export default function UnifiedLogin() {
  const router = useRouter();
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [showPassword, setShowPassword] = useState(false);

  async function handleLogin(e: React.FormEvent) {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      const res = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username, password }),
      });

      const data = await res.json();
      if (!res.ok) {
        setError(data.error ?? 'Login failed');
        return;
      }

      sessionStorage.setItem('auth_token', data.token);
      sessionStorage.setItem('auth_role', data.role);
      sessionStorage.setItem('auth_username', username);
      
      if (data.user?.token) {
        sessionStorage.setItem('psgmx_token', data.user.token);
      }
      if (data.user?.lineageSuffix) {
        sessionStorage.setItem('psgmx_lineage_suffix', data.user.lineageSuffix);
      }

      if (data.mustChangePassword) {
        sessionStorage.setItem('post_change_redirect', data.redirect || '/');
        router.push('/change-password');
        return;
      }

      router.push(data.redirect || '/');
    } catch {
      setError('Network error. Please try again.');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="h-screen w-screen bg-[#F8F9FC] flex items-center justify-center overflow-hidden relative font-sans text-[#1E293B]">
      
      {/* Abstract Background Waves (Bottom Left) */}
      <div className="absolute bottom-0 left-0 w-[80%] h-[50%] pointer-events-none opacity-60 z-0">
        <svg viewBox="0 0 1440 320" className="absolute bottom-0 w-full h-full" preserveAspectRatio="none">
          <path fill="url(#wave-gradient-login)" fillOpacity="1" d="M0,288L48,272C96,256,192,224,288,197.3C384,171,480,149,576,165.3C672,181,768,235,864,250.7C960,267,1056,245,1152,213.3C1248,181,1344,139,1392,117.3L1440,96L1440,320L1392,320C1344,320,1248,320,1152,320C1056,320,960,320,864,320C768,320,672,320,576,320C480,320,384,320,288,320C192,320,96,320,48,320L0,320Z"></path>
          <defs>
            <linearGradient id="wave-gradient-login" x1="0%" y1="0%" x2="100%" y2="0%">
              <stop offset="0%" stopColor="#C4B5FD" stopOpacity="0.4" />
              <stop offset="50%" stopColor="#FBCFE8" stopOpacity="0.3" />
              <stop offset="100%" stopColor="#BAE6FD" stopOpacity="0.1" />
            </linearGradient>
          </defs>
        </svg>
      </div>

      {/* Main Container - Full Screen with consistent padding */}
      <div className="w-full h-full flex items-center justify-between relative z-10 px-8 lg:px-20 xl:px-32">
        
        {/* Left Section */}
        <div className="w-[55%] xl:w-[60%] h-full flex flex-col justify-center">
          
          <div className="max-w-[560px]">
            {/* Logo */}
            <div className="mb-10">
              <img src="/logo.webp" alt="PSGMX Logo" className="w-24 h-24 object-contain drop-shadow-md" />
            </div>

            {/* Title */}
            <h1 className="text-5xl xl:text-[3.8rem] font-bold tracking-tight leading-[1.15] text-[#1E293B] mb-5">
              Your Department.<br />
              Your Legacy.<br />
              <span className="text-transparent bg-clip-text bg-gradient-to-r from-[#6C3DFF] to-[#3B82F6]">Powered by Intelligence.</span>
            </h1>

            {/* Paragraph */}
            <p className="text-[#64748B] text-[15px] xl:text-[17px] leading-relaxed max-w-[420px] mb-12">
              PSGMX is the unified digital ecosystem for the MCA Department — built for collaboration, knowledge sharing, and academic excellence.
            </p>

            {/* Features 2x2 Grid */}
            <div className="grid grid-cols-2 gap-6">
              
              {/* Feature 1 */}
              <div className="bg-white rounded-[1.25rem] p-5 shadow-[0_8px_30px_rgb(0,0,0,0.04)] border border-[#F1F5F9]">
                <div className="w-10 h-10 rounded-full bg-[#F5F3FF] flex items-center justify-center mb-3">
                  <BrainCircuit className="w-5 h-5 text-[#6C3DFF]" />
                </div>
                <h3 className="font-bold text-[#1E293B] text-[14px] mb-1">AI Senior</h3>
                <p className="text-xs text-[#64748B] leading-relaxed">Get instant, context-aware answers from your department's AI mentor.</p>
              </div>
              
              {/* Feature 2 */}
              <div className="bg-white rounded-[1.25rem] p-5 shadow-[0_8px_30px_rgb(0,0,0,0.04)] border border-[#F1F5F9]">
                <div className="w-10 h-10 rounded-full bg-[#EFF6FF] flex items-center justify-center mb-3">
                  <BookOpen className="w-5 h-5 text-[#3B82F6]" />
                </div>
                <h3 className="font-bold text-[#1E293B] text-[14px] mb-1">Knowledge Brain</h3>
                <p className="text-xs text-[#64748B] leading-relaxed">Access curated guides, survival notes, and alumni experiences.</p>
              </div>

              {/* Feature 3 */}
              <div className="bg-white rounded-[1.25rem] p-5 shadow-[0_8px_30px_rgb(0,0,0,0.04)] border border-[#F1F5F9]">
                <div className="w-10 h-10 rounded-full bg-[#F0FDF4] flex items-center justify-center mb-3">
                  <LineChart className="w-5 h-5 text-[#10B981]" />
                </div>
                <h3 className="font-bold text-[#1E293B] text-[14px] mb-1">FYP Repository</h3>
                <p className="text-xs text-[#64748B] leading-relaxed">Track, document, and learn from past year projects effortlessly.</p>
              </div>

              {/* Feature 4 */}
              <div className="bg-white rounded-[1.25rem] p-5 shadow-[0_8px_30px_rgb(0,0,0,0.04)] border border-[#F1F5F9]">
                <div className="w-10 h-10 rounded-full bg-[#FFF7ED] flex items-center justify-center mb-3">
                  <Target className="w-5 h-5 text-[#F97316]" />
                </div>
                <h3 className="font-bold text-[#1E293B] text-[14px] mb-1">Recovery Hub</h3>
                <p className="text-xs text-[#64748B] leading-relaxed">Special resources and mock exams to help you clear arrears.</p>
              </div>

            </div>
          </div>
        </div>

        {/* Right Section (Form Card) */}
        <div className="w-[45%] xl:w-[40%] h-full flex items-center justify-end z-20">
          <div className="w-full max-w-[480px] bg-white rounded-3xl shadow-[0_20px_60px_-15px_rgba(0,0,0,0.06)] border border-[#F1F5F9] flex flex-col p-8 sm:p-10">
            
            {/* Header */}
            <div className="flex justify-center mb-5">
              <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-[#EFF6FF] text-[#2563EB] text-[11px] font-bold">
                <GraduationCap className="w-3.5 h-3.5" /> Welcome Back
              </div>
            </div>
            <h2 className="text-[26px] font-bold tracking-tight text-[#1E293B] text-center mb-1.5">Sign in to PSGMX</h2>
            <p className="text-[12px] text-[#64748B] text-center mb-8">Access your department ecosystem</p>

            {/* Error */}
            {error && (
              <div className="mb-6 bg-red-50 border border-red-100 text-red-600 text-[13px] px-4 py-3 rounded-xl flex items-center gap-2">
                <ShieldAlert className="w-4 h-4 shrink-0" />
                <p className="font-semibold">{error}</p>
              </div>
            )}

            {/* Form */}
            <form onSubmit={handleLogin} className="space-y-5">
              
              {/* Identifier */}
              <div className="space-y-1.5">
                <label className="block text-[10px] font-bold text-[#94A3B8] tracking-widest pl-1 uppercase">
                  Identifier
                </label>
                <div className="relative">
                  <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                    <User className="h-[18px] w-[18px] text-[#CBD5E1]" />
                  </div>
                  <input
                    type="text"
                    required
                    value={username}
                    onChange={(e) => setUsername(e.target.value)}
                    className="block w-full pl-11 pr-4 py-3.5 bg-white border border-[#E2E8F0] rounded-[10px] text-[14px] text-[#1E293B] placeholder-[#94A3B8] focus:border-[#6C3DFF] focus:ring-1 focus:ring-[#6C3DFF] focus:outline-none transition-colors"
                    placeholder="Email or Token (e.g. 25MX301)"
                    autoComplete="username"
                  />
                </div>
              </div>

              {/* Password */}
              <div className="space-y-1.5">
                <label className="block text-[10px] font-bold text-[#94A3B8] tracking-widest pl-1 uppercase">
                  Access Key
                </label>
                <div className="relative">
                  <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                    <Lock className="h-[18px] w-[18px] text-[#CBD5E1]" />
                  </div>
                  <input
                    type={showPassword ? 'text' : 'password'}
                    required
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    className="block w-full pl-11 pr-12 py-3.5 bg-white border border-[#E2E8F0] rounded-[10px] text-[14px] text-[#1E293B] placeholder-[#94A3B8] focus:border-[#6C3DFF] focus:ring-1 focus:ring-[#6C3DFF] focus:outline-none transition-colors"
                    placeholder="Enter your password"
                    autoComplete="current-password"
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute inset-y-0 right-0 pr-4 flex items-center text-[#CBD5E1] hover:text-[#94A3B8] transition-colors"
                  >
                    {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                  </button>
                </div>
              </div>

              {/* Options */}
              <div className="flex items-center justify-between pt-1 pb-1">
                <label className="flex items-center gap-2 cursor-pointer group">
                  <div className="w-4 h-4 rounded border border-[#E2E8F0] bg-white group-hover:border-[#6C3DFF] flex items-center justify-center transition-colors"></div>
                  <span className="text-[12px] text-[#64748B] font-medium">Remember me</span>
                </label>
                <button type="button" className="text-[12px] font-bold text-[#2563EB] hover:text-[#6C3DFF] transition-colors">
                  Forgot password?
                </button>
              </div>

              {/* Submit Button */}
              <button
                type="submit"
                disabled={loading}
                className="w-full bg-gradient-to-r from-[#7E22CE] to-[#2563EB] hover:opacity-95 text-white font-semibold py-3.5 rounded-xl transition-opacity disabled:opacity-50 flex items-center justify-center gap-2 text-[14px]"
              >
                {loading ? 'Authenticating...' : 'Enter System'}
                {!loading && <ArrowRight className="w-4 h-4" />}
              </button>
            </form>

            {/* Divider */}
            <div className="relative my-7">
              <div className="absolute inset-0 flex items-center">
                <div className="w-full border-t border-[#F1F5F9]"></div>
              </div>
              <div className="relative flex justify-center text-xs">
                <span className="px-3 bg-white text-[#94A3B8] font-bold uppercase tracking-widest text-[10px]">OR</span>
              </div>
            </div>

            {/* Alumni Network Section */}
            <button onClick={() => router.push('/join-alumni')} className="w-full group bg-[#F8F9FC] hover:bg-[#F1F5F9] border border-[#E2E8F0] rounded-[1rem] p-4 transition-colors flex items-center gap-4 text-left">
              <div className="w-[38px] h-[38px] rounded-full bg-white border border-[#E2E8F0] flex items-center justify-center shrink-0 text-[#6C3DFF] shadow-sm">
                <Users className="w-[18px] h-[18px]" />
              </div>
              <div className="flex-1">
                <h4 className="font-bold text-[#1E293B] text-[13px]">Join Alumni Network</h4>
                <p className="text-[11px] text-[#64748B] mt-0.5 flex items-center gap-1">
                  Are you an alumnus? <span className="text-[#2563EB] font-bold flex items-center">Join now <ArrowRight className="w-3 h-3 ml-0.5" /></span>
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
