"use client";

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { motion } from 'framer-motion';

export default function FirstLoginPage() {
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const [formData, setFormData] = useState({
    password: '',
    confirmPassword: '',
    github: '',
    linkedin: '',
    skills: '',
    interests: '',
    careerGoal: '',
    hasArrears: 'no',
    arrearSubjects: [] as string[],
  });

  const mcaSubjects = [
    'Data Structures',
    'Operating Systems',
    'Computer Networks',
    'DBMS',
    'Software Engineering',
    'Java Programming',
    'Mathematics'
  ];

  const handleSubjectToggle = (subject: string) => {
    setFormData(prev => {
      if (prev.arrearSubjects.includes(subject)) {
        return { ...prev, arrearSubjects: prev.arrearSubjects.filter(s => s !== subject) };
      }
      return { ...prev, arrearSubjects: [...prev.arrearSubjects, subject] };
    });
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    if (formData.password !== formData.confirmPassword) {
      setError('Passwords do not match');
      return;
    }

    setLoading(true);

    try {
      const res = await fetch('/api/auth/first-login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData),
      });

      const data = await res.json();

      if (!res.ok) {
        throw new Error(data.error || 'Failed to update profile');
      }

      // Update token in cookies
      document.cookie = `token=${data.token}; path=/; max-age=28800; SameSite=Lax`;
      
      router.push(data.redirect);
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex min-h-screen items-center justify-center bg-slate-950 p-4 font-sans text-slate-200">
      <div className="w-full max-w-2xl rounded-2xl border border-slate-800 bg-slate-900/80 p-8 shadow-2xl backdrop-blur-xl">
        <div className="mb-8 text-center">
          <h1 className="text-3xl font-bold text-white tracking-tight">Welcome to PSGMX</h1>
          <p className="mt-2 text-sm text-slate-400">
            For security, you must change your temporary password. Please complete your professional profile to activate your account.
          </p>
        </div>

        {error && (
          <div className="mb-6 rounded-lg bg-rose-500/10 p-4 text-sm text-rose-400 border border-rose-500/20">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-8">
          
          <div className="space-y-5">
            <h3 className="text-lg font-bold text-white border-b border-slate-800 pb-2">1. Security</h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
              <div>
                <label className="mb-1 block text-xs font-medium text-slate-400 uppercase tracking-wider">New Password</label>
                <input
                  type="password"
                  required
                  className="w-full rounded-lg border border-slate-700 bg-slate-800/50 px-4 py-3 text-white placeholder-slate-500 focus:border-[#6C3DFF] focus:outline-none focus:ring-1 focus:ring-[#6C3DFF]"
                  value={formData.password}
                  onChange={(e) => setFormData({ ...formData, password: e.target.value })}
                />
              </div>
              <div>
                <label className="mb-1 block text-xs font-medium text-slate-400 uppercase tracking-wider">Confirm Password</label>
                <input
                  type="password"
                  required
                  className="w-full rounded-lg border border-slate-700 bg-slate-800/50 px-4 py-3 text-white placeholder-slate-500 focus:border-[#6C3DFF] focus:outline-none focus:ring-1 focus:ring-[#6C3DFF]"
                  value={formData.confirmPassword}
                  onChange={(e) => setFormData({ ...formData, confirmPassword: e.target.value })}
                />
              </div>
            </div>
          </div>

          <div className="space-y-5">
            <h3 className="text-lg font-bold text-white border-b border-slate-800 pb-2">2. Professional Links</h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
              <div>
                <label className="mb-1 block text-xs font-medium text-slate-400 uppercase tracking-wider">GitHub URL</label>
                <input
                  type="url"
                  placeholder="https://github.com/username"
                  className="w-full rounded-lg border border-slate-700 bg-slate-800/50 px-4 py-3 text-white placeholder-slate-500 focus:border-[#6C3DFF] focus:outline-none focus:ring-1 focus:ring-[#6C3DFF]"
                  value={formData.github}
                  onChange={(e) => setFormData({ ...formData, github: e.target.value })}
                />
              </div>
              <div>
                <label className="mb-1 block text-xs font-medium text-slate-400 uppercase tracking-wider">LinkedIn URL</label>
                <input
                  type="url"
                  placeholder="https://linkedin.com/in/username"
                  className="w-full rounded-lg border border-slate-700 bg-slate-800/50 px-4 py-3 text-white placeholder-slate-500 focus:border-[#6C3DFF] focus:outline-none focus:ring-1 focus:ring-[#6C3DFF]"
                  value={formData.linkedin}
                  onChange={(e) => setFormData({ ...formData, linkedin: e.target.value })}
                />
              </div>
            </div>
          </div>

          <div className="space-y-5">
            <h3 className="text-lg font-bold text-white border-b border-slate-800 pb-2">3. Technical Profile</h3>
            <div>
              <label className="mb-1 block text-xs font-medium text-slate-400 uppercase tracking-wider">Skills (Comma separated)</label>
              <input
                type="text"
                placeholder="React, Node.js, Python, MongoDB"
                className="w-full rounded-lg border border-slate-700 bg-slate-800/50 px-4 py-3 text-white placeholder-slate-500 focus:border-[#6C3DFF] focus:outline-none focus:ring-1 focus:ring-[#6C3DFF]"
                value={formData.skills}
                onChange={(e) => setFormData({ ...formData, skills: e.target.value })}
              />
            </div>
            <div>
              <label className="mb-1 block text-xs font-medium text-slate-400 uppercase tracking-wider">Primary Interest</label>
              <input
                type="text"
                placeholder="e.g., Full Stack Development"
                className="w-full rounded-lg border border-slate-700 bg-slate-800/50 px-4 py-3 text-white placeholder-slate-500 focus:border-[#6C3DFF] focus:outline-none focus:ring-1 focus:ring-[#6C3DFF]"
                value={formData.interests}
                onChange={(e) => setFormData({ ...formData, interests: e.target.value })}
              />
            </div>
          </div>

          <div className="space-y-5">
            <h3 className="text-lg font-bold text-white border-b border-slate-800 pb-2">4. Academic Profile</h3>
            <div>
              <label className="mb-2 block text-sm font-medium text-slate-300">Do you currently have arrears?</label>
              <div className="flex gap-4">
                <label className="flex items-center gap-2 cursor-pointer">
                  <input
                    type="radio"
                    name="hasArrears"
                    value="no"
                    checked={formData.hasArrears === 'no'}
                    onChange={(e) => setFormData({ ...formData, hasArrears: e.target.value })}
                    className="accent-[#6C3DFF]"
                  />
                  <span className="text-white">No</span>
                </label>
                <label className="flex items-center gap-2 cursor-pointer">
                  <input
                    type="radio"
                    name="hasArrears"
                    value="yes"
                    checked={formData.hasArrears === 'yes'}
                    onChange={(e) => setFormData({ ...formData, hasArrears: e.target.value, arrearSubjects: [] })}
                    className="accent-[#6C3DFF]"
                  />
                  <span className="text-white">Yes</span>
                </label>
              </div>
            </div>

            {formData.hasArrears === 'yes' && (
              <div className="mt-4 p-4 rounded-xl border border-rose-500/20 bg-rose-500/5">
                <p className="text-sm text-slate-300 mb-3">Select your arrear subjects to unlock the Recovery Hub:</p>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                  {mcaSubjects.map((subject) => (
                    <label key={subject} className="flex items-center gap-3 cursor-pointer p-2 rounded-lg hover:bg-slate-800/50 transition-colors">
                      <input
                        type="checkbox"
                        checked={formData.arrearSubjects.includes(subject)}
                        onChange={() => handleSubjectToggle(subject)}
                        className="w-4 h-4 rounded border-slate-700 text-[#6C3DFF] focus:ring-[#6C3DFF] bg-slate-800/50 accent-[#6C3DFF]"
                      />
                      <span className="text-sm text-slate-200">{subject}</span>
                    </label>
                  ))}
                </div>
              </div>
            )}
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full rounded-lg bg-[#6C3DFF] px-4 py-4 font-bold text-white transition-colors hover:bg-[#5b30e5] focus:outline-none focus:ring-2 focus:ring-[#6C3DFF] focus:ring-offset-2 focus:ring-offset-slate-900 disabled:opacity-50"
          >
            {loading ? 'Saving Profile...' : 'Complete Setup & Access Dashboard'}
          </button>
        </form>
      </div>
    </div>
  );
}
