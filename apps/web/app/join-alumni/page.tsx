"use client";

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { User, Calendar, Mail, Link as LinkIcon, Lock, EyeOff, Eye, ArrowRight, ShieldCheck, Check, GraduationCap } from 'lucide-react';
import Image from 'next/image';

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
        router.push('/login');
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
      <div className="min-h-screen w-full bg-[#FDF7F3] flex items-center justify-center p-4">
        <div className="w-full max-w-md rounded-[32px] bg-white p-10 text-center shadow-[0_20px_60px_-15px_rgba(0,0,0,0.05)]">
          <div className="mx-auto mb-6 flex h-16 w-16 items-center justify-center rounded-full bg-[#FFF0E6] text-[#FF5A1F]">
            <Check className="h-8 w-8" />
          </div>
          <h2 className="mb-2 text-[26px] font-bold text-[#101828]">Application Submitted</h2>
          <p className="text-[#475467] text-[15px] mb-8 font-medium">
            Your request to join the MCA Alumni Network has been sent to the HOD for verification. You will receive login access once approved.
          </p>
          <div className="flex justify-center items-center gap-2 text-[14px] font-bold text-[#FF5A1F]">
            <div className="w-4 h-4 border-2 border-current border-t-transparent rounded-full animate-spin"></div>
            Redirecting to login...
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen w-full bg-[#FDF7F3] flex items-center justify-center p-4 sm:p-6 lg:p-8 font-sans text-[#101828]">

      {/* Main Container - The White Card */}
      <div className="w-full max-w-[1200px] bg-white rounded-[32px] shadow-[0_20px_60px_-15px_rgba(0,0,0,0.05)] flex flex-col lg:flex-row p-3 relative h-auto lg:h-[840px]">

        {/* Left Side - Image Container */}
        <div className="hidden lg:flex lg:w-[50%] bg-[#fef6eb] rounded-[24px] overflow-hidden relative">

          {/* Logo overlay on top left */}
          <div className="absolute top-10 left-10 flex items-center gap-2 z-10">
            <img src="/logo.webp" alt="PSGMX" className="w-8 h-8" />
            <span className="font-bold text-[22px] tracking-tight text-[#1E293B]">PSGMX</span>
          </div>

          <div className="w-full h-full flex items-center justify-center pt-20 px-6">
            <img
              src="/auth/alumni.png"
              alt="PSGMX Alumni"
              className="w-full max-w-[900px] object-contain"
            />
          </div>
        </div>

        {/* Right Side - Form */}
        <div className="w-full lg:w-[50%] flex flex-col justify-center px-6 sm:px-16 py-8 lg:py-6 bg-white overflow-y-auto custom-scrollbar">

          <div className="w-full max-w-[420px] mx-auto py-6">
            {/* Tag */}
            <div className="flex mb-5">
              <div className="flex items-center gap-1.5 px-3 py-1 rounded-full bg-[#FFF0E6] text-[#FF5A1F] text-[12px] font-bold">
                <GraduationCap className="w-3.5 h-3.5" />
                Alumni Network
              </div>
            </div>

            {/* Headers */}
            <h1 className="text-[36px] sm:text-[40px] font-bold tracking-tight text-[#101828] mb-1.5 leading-[1.1]">
              Join the <span className="text-[#FF5A1F]">PSGMX</span><br />Alumni Network
            </h1>
            <p className="text-[#475467] text-[15px] mb-8 font-medium leading-[1.6]">
              Connect with your department. Mentor and inspire the next generation.
            </p>

            {/* Error Message */}
            {error && (
              <div className="mb-6 bg-red-50 border border-red-100 text-red-600 text-[13px] px-4 py-3 rounded-[12px] flex items-center gap-2">
                <ShieldCheck className="w-4 h-4 shrink-0" />
                <p className="font-semibold">{error}</p>
              </div>
            )}

            {/* Form */}
            <form onSubmit={handleSubmit} className="space-y-4">

              <div className="space-y-1.5">
                <label className="block text-[13px] font-bold text-[#101828]">
                  Roll Number (Token)
                </label>
                <div className="relative">
                  <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                    <User className="h-[18px] w-[18px] text-[#98A2B3]" />
                  </div>
                  <input
                    type="text"
                    required
                    placeholder="e.g., 21MX114"
                    className="block w-full pl-11 pr-4 py-3.5 bg-white border border-[#D0D5DD] rounded-[12px] text-[15px] text-[#101828] placeholder-[#98A2B3] focus:border-[#FF5A1F] focus:ring-1 focus:ring-[#FF5A1F] focus:outline-none transition-colors uppercase"
                    value={formData.token}
                    onChange={(e) => setFormData({ ...formData, token: e.target.value })}
                  />
                </div>
              </div>

              <div className="space-y-1.5">
                <label className="block text-[13px] font-bold text-[#101828]">
                  Graduation Year
                </label>
                <div className="relative">
                  <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                    <Calendar className="h-[18px] w-[18px] text-[#98A2B3]" />
                  </div>
                  <input
                    type="number"
                    required
                    placeholder="e.g., 2023"
                    className="block w-full pl-11 pr-4 py-3.5 bg-white border border-[#D0D5DD] rounded-[12px] text-[15px] text-[#101828] placeholder-[#98A2B3] focus:border-[#FF5A1F] focus:ring-1 focus:ring-[#FF5A1F] focus:outline-none transition-colors"
                    value={formData.graduationYear}
                    onChange={(e) => setFormData({ ...formData, graduationYear: e.target.value })}
                  />
                </div>
              </div>

              <div className="space-y-1.5">
                <label className="block text-[13px] font-bold text-[#101828]">
                  Email Address
                </label>
                <div className="relative">
                  <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                    <Mail className="h-[18px] w-[18px] text-[#98A2B3]" />
                  </div>
                  <input
                    type="email"
                    required
                    placeholder="you@example.com"
                    className="block w-full pl-11 pr-4 py-3.5 bg-white border border-[#D0D5DD] rounded-[12px] text-[15px] text-[#101828] placeholder-[#98A2B3] focus:border-[#FF5A1F] focus:ring-1 focus:ring-[#FF5A1F] focus:outline-none transition-colors"
                    value={formData.email}
                    onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                  />
                </div>
              </div>

              <div className="space-y-1.5">
                <label className="block text-[13px] font-bold text-[#101828]">
                  LinkedIn Profile (Optional)
                </label>
                <div className="relative">
                  <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                    <LinkIcon className="h-[18px] w-[18px] text-[#98A2B3]" />
                  </div>
                  <input
                    type="url"
                    placeholder="https://linkedin.com/in/username"
                    className="block w-full pl-11 pr-4 py-3.5 bg-white border border-[#D0D5DD] rounded-[12px] text-[15px] text-[#101828] placeholder-[#98A2B3] focus:border-[#FF5A1F] focus:ring-1 focus:ring-[#FF5A1F] focus:outline-none transition-colors"
                    value={formData.linkedin}
                    onChange={(e) => setFormData({ ...formData, linkedin: e.target.value })}
                  />
                </div>
              </div>

              <div className="space-y-1.5 pb-1">
                <label className="block text-[13px] font-bold text-[#101828]">
                  Create Password
                </label>
                <div className="relative">
                  <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                    <Lock className="h-[18px] w-[18px] text-[#98A2B3]" />
                  </div>
                  <input
                    type={showPassword ? 'text' : 'password'}
                    required
                    placeholder="••••••••"
                    className="block w-full pl-11 pr-11 py-3.5 bg-white border border-[#D0D5DD] rounded-[12px] text-[15px] text-[#101828] placeholder-[#98A2B3] focus:border-[#FF5A1F] focus:ring-1 focus:ring-[#FF5A1F] focus:outline-none transition-colors"
                    value={formData.password}
                    onChange={(e) => setFormData({ ...formData, password: e.target.value })}
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute inset-y-0 right-0 pr-4 flex items-center text-[#98A2B3] hover:text-[#101828] transition-colors"
                  >
                    {showPassword ? <EyeOff className="h-[18px] w-[18px]" /> : <Eye className="h-[18px] w-[18px]" />}
                  </button>
                </div>

                <div className="flex items-center justify-between pt-3">
                  <div className={`flex items-center gap-1 text-[11px] font-semibold ${hasMinChars ? 'text-[#101828]' : 'text-[#98A2B3]'}`}>
                    <Check className="w-3.5 h-3.5" /> Min. 8 characters
                  </div>
                  <div className={`flex items-center gap-1 text-[11px] font-semibold ${hasNumber ? 'text-[#101828]' : 'text-[#98A2B3]'}`}>
                    <Check className="w-3.5 h-3.5" /> One number
                  </div>
                  <div className={`flex items-center gap-1 text-[11px] font-semibold ${hasSpecial ? 'text-[#101828]' : 'text-[#98A2B3]'}`}>
                    <Check className="w-3.5 h-3.5" /> One special character
                  </div>
                </div>
              </div>

              <button
                type="submit"
                disabled={loading}
                className="w-full bg-[#FF5A1F] hover:bg-[#E04812] text-white font-semibold py-3.5 rounded-[12px] transition-all disabled:opacity-50 flex items-center justify-center gap-2 mt-2 text-[16px] shadow-[0_4px_14px_rgba(255,90,31,0.25)]"
              >
                {loading ? 'Submitting...' : 'Submit Application'}
                {!loading && <ArrowRight className="w-4 h-4" />}
              </button>
            </form>

            <div className="mt-5 text-center text-[14px] font-medium text-[#475467]">
              Already verified?{' '}
              <Link href="/login" className="text-[#FF5A1F] hover:text-[#E04812] font-bold transition-colors">
                Log in here
              </Link>
            </div>

            <div className="mt-8 flex items-start justify-center gap-2 pt-5 border-t border-[#F2F4F7]">
              <ShieldCheck className="w-4 h-4 text-[#98A2B3] shrink-0 mt-0.5" />
              <p className="text-[12px] font-medium text-[#98A2B3] leading-[1.6]">
                All applications are reviewed by the department.<br />You will receive login access once verified.
              </p>
            </div>

          </div>
        </div>
      </div>

      {/* Global styles for custom scrollbar hidden internally */}
      <style dangerouslySetInnerHTML={{
        __html: `
        .custom-scrollbar::-webkit-scrollbar {
          width: 4px;
        }
        .custom-scrollbar::-webkit-scrollbar-track {
          background: transparent;
        }
        .custom-scrollbar::-webkit-scrollbar-thumb {
          background-color: #D0D5DD;
          border-radius: 20px;
        }
      `}} />
    </div>
  );
}
