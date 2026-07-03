'use client';

import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { useRouter } from 'next/navigation';
import { Github, Linkedin, Code2, ArrowRight } from 'lucide-react';

export default function OnboardingPage() {
  const router = useRouter();
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  
  const [form, setForm] = useState({
    fullName: '',
    linkedin: '',
    github: '',
    skills: ''
  });

  useEffect(() => {
    fetch('/api/user/profile')
      .then(res => res.json())
      .then(data => {
        if (data.success && data.profile) {
          // If already completed, redirect to home (which will route properly)
          if (data.profile.linkedin && data.profile.skills && data.profile.skills.length > 0) {
            router.push('/');
          }
          setForm({
            fullName: data.profile.fullName || '',
            linkedin: data.profile.linkedin || '',
            github: data.profile.github || '',
            skills: data.profile.skills ? data.profile.skills.join(', ') : ''
          });
        }
        setLoading(false);
      });
  }, [router]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);
    
    try {
      const skillsArray = form.skills.split(',').map(s => s.trim()).filter(s => s);
      await fetch('/api/user/profile', {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ ...form, skills: skillsArray })
      });
      router.push('/');
    } catch (e) {
      console.error(e);
    } finally {
      setSaving(false);
    }
  };

  if (loading) return null;

  return (
    <div className="min-h-screen bg-page-bg text-text-main flex items-center justify-center p-4 relative overflow-hidden">
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[80%] h-[80%] bg-electric-blue/5 rounded-full blur-[150px] pointer-events-none" />

      <motion.div 
        initial={{ opacity: 0, scale: 0.95 }} animate={{ opacity: 1, scale: 1 }}
        className="w-full max-w-xl psgmx-glass p-8 relative z-10"
      >
        <h1 className="text-3xl font-black text-white mb-2">Complete Your Profile</h1>
        <p className="text-text-muted mb-8">Before you enter the Token Lineage Network, set up your professional profile.</p>

        <form onSubmit={handleSubmit} className="space-y-6">
          <div>
            <label className="block text-xs font-bold text-text-muted uppercase tracking-wider mb-2">Full Name</label>
            <input 
              required
              type="text" 
              value={form.fullName}
              onChange={(e) => setForm({...form, fullName: e.target.value})}
              className="w-full bg-black/40 border border-border rounded-xl px-4 py-3 text-white focus:border-electric-blue transition-colors outline-none"
              placeholder="e.g. Britty Tino"
            />
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <label className="flex items-center gap-2 text-xs font-bold text-text-muted uppercase tracking-wider mb-2">
                <Linkedin className="w-4 h-4" /> LinkedIn
              </label>
              <input 
                required
                type="url" 
                value={form.linkedin}
                onChange={(e) => setForm({...form, linkedin: e.target.value})}
                className="w-full bg-black/40 border border-border rounded-xl px-4 py-3 text-white focus:border-electric-blue transition-colors outline-none"
                placeholder="https://linkedin.com/in/..."
              />
            </div>
            <div>
              <label className="flex items-center gap-2 text-xs font-bold text-text-muted uppercase tracking-wider mb-2">
                <Github className="w-4 h-4" /> GitHub
              </label>
              <input 
                type="url" 
                value={form.github}
                onChange={(e) => setForm({...form, github: e.target.value})}
                className="w-full bg-black/40 border border-border rounded-xl px-4 py-3 text-white focus:border-electric-blue transition-colors outline-none"
                placeholder="https://github.com/..."
              />
            </div>
          </div>

          <div>
            <label className="flex items-center gap-2 text-xs font-bold text-text-muted uppercase tracking-wider mb-2">
              <Code2 className="w-4 h-4" /> Core Skills (Comma Separated)
            </label>
            <input 
              required
              type="text" 
              value={form.skills}
              onChange={(e) => setForm({...form, skills: e.target.value})}
              className="w-full bg-black/40 border border-border rounded-xl px-4 py-3 text-white focus:border-electric-blue transition-colors outline-none"
              placeholder="React, Node.js, Python, System Design"
            />
          </div>

          <button 
            type="submit" 
            disabled={saving}
            className="w-full py-4 rounded-xl bg-electric-blue text-white font-black hover:bg-electric-blue/80 transition-colors flex items-center justify-center gap-2 disabled:opacity-50"
          >
            {saving ? 'Saving Profile...' : 'Enter Lineage Network'} <ArrowRight className="w-5 h-5" />
          </button>
        </form>
      </motion.div>
    </div>
  );
}
