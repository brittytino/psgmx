"use client";

import { useState } from 'react';
import { useRouter } from 'next/navigation';

export default function FirstLoginPage() {
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const [formData, setFormData] = useState({
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
    setLoading(true);

    try {
      const res = await fetch('/api/auth/first-login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          linkedin_url: formData.linkedin || null,
          github_url: formData.github || null,
          skills: formData.skills,
          interests: formData.interests,
          career_goal: formData.careerGoal,
          arrears: formData.hasArrears === 'yes' ? formData.arrearSubjects : [],
        }),
      });

      const data = await res.json();

      if (!res.ok) {
        throw new Error(data.error || 'Failed to update profile');
      }

      router.push(data.redirect || '/student');
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex min-h-screen items-center justify-center bg-[#FDF7F3] p-4 font-sans">
      <div className="w-full max-w-2xl rounded-[32px] border border-[#F3E9E1] bg-white p-8 shadow-[0_30px_90px_-35px_rgba(16,24,40,.28)]">
        <div className="mb-8 text-center">
          <h1 className="text-3xl font-black tracking-tight text-[#101828]">Welcome to PSGMX</h1>
          <p className="mt-2 text-sm text-[#667085]">
            Confirm your preparation profile. Your first real calibration happens in Daily Five using server-selected questions.
          </p>
        </div>

        {error && (
          <div className="mb-6 rounded-xl border border-red-100 bg-red-50 p-4 text-sm font-semibold text-red-700" role="alert">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-8">

          <div className="space-y-5">
            <h3 className="border-b border-[#F3E9E1] pb-2 text-lg font-black text-[#101828]">1. Professional Links</h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
              <div>
                <label className="mb-1 block text-xs font-bold uppercase tracking-wider text-[#98A2B3]">GitHub URL</label>
                <input
                  type="url"
                  placeholder="https://github.com/username"
                  className="w-full rounded-xl border border-[#D0D5DD] bg-white px-4 py-3 text-[#101828] placeholder-[#98A2B3] outline-none transition focus:border-[#FF5A1F] focus:ring-4 focus:ring-[#FF5A1F]/10"
                  value={formData.github}
                  onChange={(e) => setFormData({ ...formData, github: e.target.value })}
                />
              </div>
              <div>
                <label className="mb-1 block text-xs font-bold uppercase tracking-wider text-[#98A2B3]">LinkedIn URL</label>
                <input
                  type="url"
                  placeholder="https://linkedin.com/in/username"
                  className="w-full rounded-xl border border-[#D0D5DD] bg-white px-4 py-3 text-[#101828] placeholder-[#98A2B3] outline-none transition focus:border-[#FF5A1F] focus:ring-4 focus:ring-[#FF5A1F]/10"
                  value={formData.linkedin}
                  onChange={(e) => setFormData({ ...formData, linkedin: e.target.value })}
                />
              </div>
            </div>
          </div>

          <div className="space-y-5">
            <h3 className="border-b border-[#F3E9E1] pb-2 text-lg font-black text-[#101828]">2. Technical Profile</h3>
            <div>
              <label className="mb-1 block text-xs font-bold uppercase tracking-wider text-[#98A2B3]">Skills (Comma separated)</label>
              <input
                type="text"
                placeholder="React, Node.js, Python, MongoDB"
                className="w-full rounded-xl border border-[#D0D5DD] bg-white px-4 py-3 text-[#101828] placeholder-[#98A2B3] outline-none transition focus:border-[#FF5A1F] focus:ring-4 focus:ring-[#FF5A1F]/10"
                value={formData.skills}
                onChange={(e) => setFormData({ ...formData, skills: e.target.value })}
              />
            </div>
            <div>
              <label className="mb-1 block text-xs font-bold uppercase tracking-wider text-[#98A2B3]">Primary Interest</label>
              <input
                type="text"
                placeholder="e.g., Full Stack Development"
                className="w-full rounded-xl border border-[#D0D5DD] bg-white px-4 py-3 text-[#101828] placeholder-[#98A2B3] outline-none transition focus:border-[#FF5A1F] focus:ring-4 focus:ring-[#FF5A1F]/10"
                value={formData.interests}
                onChange={(e) => setFormData({ ...formData, interests: e.target.value })}
              />
            </div>
          </div>

          <div className="space-y-5">
            <h3 className="border-b border-[#F3E9E1] pb-2 text-lg font-black text-[#101828]">3. Academic Profile</h3>
            <div>
              <label className="mb-2 block text-sm font-bold text-[#344054]">Do you currently have arrears?</label>
              <div className="flex gap-4">
                <label className="flex items-center gap-2 cursor-pointer">
                  <input
                    type="radio"
                    name="hasArrears"
                    value="no"
                    checked={formData.hasArrears === 'no'}
                    onChange={(e) => setFormData({ ...formData, hasArrears: e.target.value })}
                    className="accent-[#FF5A1F]"
                  />
                  <span className="text-[#101828]">No</span>
                </label>
                <label className="flex items-center gap-2 cursor-pointer">
                  <input
                    type="radio"
                    name="hasArrears"
                    value="yes"
                    checked={formData.hasArrears === 'yes'}
                    onChange={(e) => setFormData({ ...formData, hasArrears: e.target.value, arrearSubjects: [] })}
                    className="accent-[#FF5A1F]"
                  />
                  <span className="text-[#101828]">Yes</span>
                </label>
              </div>
            </div>

            {formData.hasArrears === 'yes' && (
              <div className="mt-4 p-4 rounded-xl border border-[#FFD9C2] bg-[#FFF8F3]">
                <p className="text-sm text-[#667085] mb-3">Select your arrear subjects to unlock the Recovery Hub:</p>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                  {mcaSubjects.map((subject) => (
                    <label key={subject} className="flex items-center gap-3 cursor-pointer p-2 rounded-lg hover:bg-white transition-colors">
                      <input
                        type="checkbox"
                        checked={formData.arrearSubjects.includes(subject)}
                        onChange={() => handleSubjectToggle(subject)}
                        className="w-4 h-4 rounded border-[#D0D5DD] accent-[#FF5A1F]"
                      />
                      <span className="text-sm text-[#344054]">{subject}</span>
                    </label>
                  ))}
                </div>
              </div>
            )}
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full rounded-xl bg-[#FF5A1F] px-4 py-4 font-black text-white shadow-[0_8px_24px_rgba(255,90,31,.25)] transition hover:-translate-y-0.5 hover:bg-[#E04812] focus:outline-none focus:ring-4 focus:ring-[#FF5A1F]/20 disabled:translate-y-0 disabled:opacity-50"
          >
            {loading ? 'Saving Profile...' : 'Complete Setup & Access Dashboard'}
          </button>
        </form>
      </div>
    </div>
  );
}
