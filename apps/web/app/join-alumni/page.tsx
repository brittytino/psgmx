"use client";

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { Users, MessageSquare, Star, User, Calendar, Mail, Link as LinkIcon, Lock, EyeOff, Eye, ArrowRight, ShieldCheck, Check } from 'lucide-react';

export default function JoinAlumniPage() {
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState(false);
  const [showPassword, setShowPassword] = useState(false);

  const [formData, setFormData] = useState({
    token: '',
    graduationYear: '',
    linkedin: '',
    email: '',
    password: '',
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      const res = await fetch('/api/auth/join-alumni', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData),
      });

      const data = await res.json();

      if (!res.ok) {
        throw new Error(data.error || 'Failed to register');
      }

      setSuccess(true);
      setTimeout(() => {
        router.push('/');
      }, 3000);
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const hasMinChars = formData.password.length >= 8;
  const hasNumber = /\d/.test(formData.password);
  const hasSpecial = /[!@#$%^&*(),.?":{}|<>]/.test(formData.password);

  if (success) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-[#F4F7FE] p-4 font-sans">
        <div className="w-full max-w-md rounded-[2rem] border border-[#E2E8F0] bg-white p-10 text-center shadow-xl">
          <div className="mx-auto mb-6 flex h-16 w-16 items-center justify-center rounded-full bg-[#F0FDF4] text-[#16A34A]">
            <Check className="h-8 w-8" />
          </div>
          <h2 className="mb-2 text-2xl font-bold text-[#1E293B]">Application Submitted</h2>
          <p className="text-[#64748B] mb-6">
            Your request to join the MCA Alumni Network has been sent to the HOD for verification. You will be able to log in once approved.
          </p>
          <div className="flex justify-center items-center gap-2 text-sm font-bold text-[#6C3DFF]">
            <div className="w-4 h-4 border-2 border-current border-t-transparent rounded-full animate-spin"></div>
            Redirecting to login...
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="h-screen w-screen bg-[#F8F9FC] flex items-center justify-center overflow-hidden relative font-sans text-[#1E293B]">
      
      {/* Abstract Background Waves (Bottom Left) */}
      <div className="absolute bottom-0 left-0 w-[80%] h-[50%] pointer-events-none opacity-60 z-0">
        <svg viewBox="0 0 1440 320" className="absolute bottom-0 w-full h-full" preserveAspectRatio="none">
          <path fill="url(#wave-gradient)" fillOpacity="1" d="M0,288L48,272C96,256,192,224,288,197.3C384,171,480,149,576,165.3C672,181,768,235,864,250.7C960,267,1056,245,1152,213.3C1248,181,1344,139,1392,117.3L1440,96L1440,320L1392,320C1344,320,1248,320,1152,320C1056,320,960,320,864,320C768,320,672,320,576,320C480,320,384,320,288,320C192,320,96,320,48,320L0,320Z"></path>
          <defs>
            <linearGradient id="wave-gradient" x1="0%" y1="0%" x2="100%" y2="0%">
              <stop offset="0%" stopColor="#C4B5FD" stopOpacity="0.4" />
              <stop offset="50%" stopColor="#FBCFE8" stopOpacity="0.3" />
              <stop offset="100%" stopColor="#BAE6FD" stopOpacity="0.1" />
            </linearGradient>
          </defs>
        </svg>
      </div>

      {/* Main Container - Full Screen with consistent padding */}
      <div className="w-full h-full flex items-center justify-between relative z-10 px-8 lg:px-20 xl:px-32">
        
        {/* Left Section (Text + Image) */}
        <div className="w-[55%] xl:w-[60%] h-full relative flex items-center">
          
          {/* Text Content */}
          <div className="w-[55%] flex flex-col justify-center z-20">
            {/* Logo */}
            <div className="mb-10">
              <img src="/logo.webp" alt="PSGMX Logo" className="w-24 h-24 object-contain drop-shadow-md" />
            </div>

            {/* Title */}
            <h1 className="text-5xl xl:text-[3.8rem] font-bold tracking-tight leading-[1.15] text-[#1E293B] mb-5">
              Stay Connected.<br />
              Give Back.<br />
              <span className="text-transparent bg-clip-text bg-gradient-to-r from-[#6C3DFF] to-[#3B82F6]">Inspire the Next.</span>
            </h1>

            {/* Paragraph */}
            <p className="text-[#64748B] text-[15px] xl:text-[17px] leading-relaxed max-w-[380px] mb-12">
              Join the PSGMX Alumni Network and continue shaping the future of the MCA Department.
            </p>

            {/* Features */}
            <div className="space-y-7">
              {/* Feature 1 */}
              <div className="flex gap-4 items-start">
                <div className="w-[46px] h-[46px] rounded-full border border-[#E2E8F0] bg-white flex items-center justify-center shrink-0 shadow-sm">
                  <Users className="w-5 h-5 text-[#6C3DFF]" />
                </div>
                <div className="pt-0.5">
                  <h3 className="font-bold text-[#1E293B] text-[14px]">Reconnect</h3>
                  <p className="text-xs text-[#94A3B8] mt-0.5">Find classmates, seniors, and juniors.</p>
                </div>
              </div>

              {/* Feature 2 */}
              <div className="flex gap-4 items-start">
                <div className="w-[46px] h-[46px] rounded-full border border-[#E2E8F0] bg-white flex items-center justify-center shrink-0 shadow-sm">
                  <MessageSquare className="w-5 h-5 text-[#3B82F6]" />
                </div>
                <div className="pt-0.5">
                  <h3 className="font-bold text-[#1E293B] text-[14px]">Mentor</h3>
                  <p className="text-xs text-[#94A3B8] mt-0.5">Guide and support the next generation.</p>
                </div>
              </div>

              {/* Feature 3 */}
              <div className="flex gap-4 items-start">
                <div className="w-[46px] h-[46px] rounded-full border border-[#E2E8F0] bg-white flex items-center justify-center shrink-0 shadow-sm">
                  <Star className="w-5 h-5 text-[#10B981]" />
                </div>
                <div className="pt-0.5">
                  <h3 className="font-bold text-[#1E293B] text-[14px]">Make Impact</h3>
                  <p className="text-xs text-[#94A3B8] mt-0.5">Your knowledge. Your experience. Their future.</p>
                </div>
              </div>
            </div>
          </div>

          {/* 3D Image & Orb */}
          <div className="absolute right-[-15%] top-1/2 -translate-y-1/2 w-[65%] h-[85%] flex items-center justify-center z-10 pointer-events-none">
            {/* Orb */}
            <div className="absolute w-[500px] h-[500px] bg-gradient-to-tr from-[#E5D4FF]/60 to-[#E0F2FE]/60 rounded-full blur-[70px]"></div>
            {/* Image */}
            <img src="/alumni-illustration.png" alt="Graduates" className="relative z-10 max-h-full object-contain mix-blend-multiply" />
          </div>
        </div>

        {/* Right Section (Form Card) */}
        <div className="w-[45%] xl:w-[40%] h-full flex items-center justify-end z-20">
          <div className="w-full max-w-[480px] bg-white rounded-3xl shadow-[0_20px_60px_-15px_rgba(0,0,0,0.06)] border border-[#F1F5F9] flex flex-col p-8 sm:p-10">
            
            {/* Header */}
            <div className="flex justify-center mb-5">
              <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-[#F5F3FF] text-[#6C3DFF] text-[11px] font-bold">
                <Users className="w-3.5 h-3.5" /> Alumni Network
              </div>
            </div>
            <h2 className="text-[26px] font-bold tracking-tight text-[#1E293B] text-center mb-1.5">Join Alumni Network</h2>
            <p className="text-[12px] text-[#64748B] text-center mb-8">Connect with the MCA Department and mentor the next generation.</p>

            {/* Error Message */}
            {error && (
              <div className="mb-6 bg-red-50 border border-red-100 text-red-600 text-[13px] px-4 py-3 rounded-xl flex items-center gap-2">
                <ShieldCheck className="w-4 h-4 shrink-0" />
                <p className="font-semibold">{error}</p>
              </div>
            )}

            {/* Form */}
            <form onSubmit={handleSubmit} className="space-y-4">
              
              {/* Roll Number */}
              <div className="space-y-1.5">
                <label className="block text-[10px] font-bold text-[#94A3B8] tracking-widest pl-1 uppercase">
                  Roll Number (Token)
                </label>
                <div className="relative">
                  <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                    <User className="h-[18px] w-[18px] text-[#CBD5E1]" />
                  </div>
                  <input
                    type="text"
                    required
                    placeholder="E.g., 21MX114"
                    className="block w-full pl-11 pr-4 py-3.5 bg-white border border-[#E2E8F0] rounded-[10px] text-[14px] text-[#1E293B] placeholder-[#94A3B8] focus:border-[#6C3DFF] focus:ring-1 focus:ring-[#6C3DFF] focus:outline-none transition-colors uppercase"
                    value={formData.token}
                    onChange={(e) => setFormData({ ...formData, token: e.target.value })}
                  />
                </div>
              </div>

              {/* Graduation Year */}
              <div className="space-y-1.5">
                <label className="block text-[10px] font-bold text-[#94A3B8] tracking-widest pl-1 uppercase">
                  Graduation Year
                </label>
                <div className="relative">
                  <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                    <Calendar className="h-[18px] w-[18px] text-[#CBD5E1]" />
                  </div>
                  <input
                    type="number"
                    required
                    placeholder="e.g., 2023"
                    className="block w-full pl-11 pr-4 py-3.5 bg-white border border-[#E2E8F0] rounded-[10px] text-[14px] text-[#1E293B] placeholder-[#94A3B8] focus:border-[#6C3DFF] focus:ring-1 focus:ring-[#6C3DFF] focus:outline-none transition-colors"
                    value={formData.graduationYear}
                    onChange={(e) => setFormData({ ...formData, graduationYear: e.target.value })}
                  />
                </div>
              </div>

              {/* Email */}
              <div className="space-y-1.5">
                <label className="block text-[10px] font-bold text-[#94A3B8] tracking-widest pl-1 uppercase">
                  Email Address
                </label>
                <div className="relative">
                  <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                    <Mail className="h-[18px] w-[18px] text-[#CBD5E1]" />
                  </div>
                  <input
                    type="email"
                    required
                    placeholder="you@example.com"
                    className="block w-full pl-11 pr-4 py-3.5 bg-white border border-[#E2E8F0] rounded-[10px] text-[14px] text-[#1E293B] placeholder-[#94A3B8] focus:border-[#6C3DFF] focus:ring-1 focus:ring-[#6C3DFF] focus:outline-none transition-colors"
                    value={formData.email}
                    onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                  />
                </div>
              </div>

              {/* LinkedIn */}
              <div className="space-y-1.5">
                <label className="block text-[10px] font-bold text-[#94A3B8] tracking-widest pl-1 uppercase">
                  LinkedIn URL (Optional)
                </label>
                <div className="relative">
                  <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                    <LinkIcon className="h-[18px] w-[18px] text-[#CBD5E1]" />
                  </div>
                  <input
                    type="url"
                    placeholder="https://linkedin.com/in/username"
                    className="block w-full pl-11 pr-4 py-3.5 bg-white border border-[#E2E8F0] rounded-[10px] text-[14px] text-[#1E293B] placeholder-[#94A3B8] focus:border-[#6C3DFF] focus:ring-1 focus:ring-[#6C3DFF] focus:outline-none transition-colors"
                    value={formData.linkedin}
                    onChange={(e) => setFormData({ ...formData, linkedin: e.target.value })}
                  />
                </div>
              </div>

              {/* Password */}
              <div className="space-y-1.5 pb-2">
                <label className="block text-[10px] font-bold text-[#94A3B8] tracking-widest pl-1 uppercase">
                  Create Password
                </label>
                <div className="relative">
                  <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                    <Lock className="h-[18px] w-[18px] text-[#CBD5E1]" />
                  </div>
                  <input
                    type={showPassword ? 'text' : 'password'}
                    required
                    placeholder="••••••••"
                    className="block w-full pl-11 pr-12 py-3.5 bg-white border border-[#E2E8F0] rounded-[10px] text-[14px] text-[#1E293B] placeholder-[#94A3B8] focus:border-[#6C3DFF] focus:ring-1 focus:ring-[#6C3DFF] focus:outline-none transition-colors"
                    value={formData.password}
                    onChange={(e) => setFormData({ ...formData, password: e.target.value })}
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute inset-y-0 right-0 pr-4 flex items-center text-[#CBD5E1] hover:text-[#94A3B8] transition-colors"
                  >
                    {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                  </button>
                </div>

                {/* Validation Rules */}
                <div className="flex items-center justify-between pt-3 px-1">
                  <div className={`flex items-center gap-1.5 text-[10px] font-semibold ${hasMinChars ? 'text-[#2563EB]' : 'text-[#94A3B8]'}`}>
                    <Check className="w-3 h-3" /> Min. 8 characters
                  </div>
                  <div className={`flex items-center gap-1.5 text-[10px] font-semibold ${hasNumber ? 'text-[#2563EB]' : 'text-[#94A3B8]'}`}>
                    <Check className="w-3 h-3" /> One number
                  </div>
                  <div className={`flex items-center gap-1.5 text-[10px] font-semibold ${hasSpecial ? 'text-[#2563EB]' : 'text-[#94A3B8]'}`}>
                    <Check className="w-3 h-3" /> One special character
                  </div>
                </div>
              </div>

              {/* Submit Button */}
              <button
                type="submit"
                disabled={loading}
                className="w-full bg-gradient-to-r from-[#7E22CE] to-[#2563EB] hover:opacity-95 text-white font-semibold py-3.5 rounded-xl transition-opacity disabled:opacity-50 flex items-center justify-center gap-2 mt-2 text-[14px]"
              >
                {loading ? 'Submitting...' : 'Submit Application'}
                {!loading && <ArrowRight className="w-4 h-4" />}
              </button>
            </form>

            {/* Login Link */}
            <div className="mt-5 text-center text-[12px] font-medium text-[#64748B]">
              Already verified?{' '}
              <Link href="/" className="text-[#6C3DFF] hover:text-[#5B21B6] font-bold">
                Log in here
              </Link>
            </div>
            
            {/* Footer */}
            <div className="mt-7 pt-5 border-t border-[#F1F5F9] flex items-start gap-2.5">
              <ShieldCheck className="w-[16px] h-[16px] text-[#6C3DFF] shrink-0" />
              <p className="text-[10px] font-medium text-[#64748B] leading-[1.6]">
                All applications are reviewed by the department.<br/>You will receive login access once verified.
              </p>
            </div>

          </div>
        </div>
      </div>
    </div>
  );
}
