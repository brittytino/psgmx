'use client';

import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { Settings, User, Users, Shield, Save, Linkedin, Globe, ToggleRight, ToggleLeft } from 'lucide-react';

export default function AlumniSettingsPage() {
  const [activeTab, setActiveTab] = useState<'profile' | 'mentorship' | 'account'>('profile');
  const [saved, setSaved] = useState(false);
  const [mentorshipActive, setMentorshipActive] = useState(true);

  const handleSave = () => {
    setSaved(true);
    setTimeout(() => setSaved(false), 2500);
  };

  return (
    <div className="max-w-[900px] mx-auto space-y-8 pb-8">
      <div>
        <h1 className="text-[24px] font-black text-text-main tracking-tight flex items-center gap-2">
          <Settings className="w-6 h-6 text-primary-purple" /> Settings
        </h1>
        <p className="text-[13px] text-text-muted mt-0.5">Manage your alumni profile and mentorship preferences.</p>
      </div>

      {/* Tabs */}
      <div className="flex gap-6 border-b border-border-light">
        {(['profile', 'mentorship', 'account'] as const).map((tab) => (
          <button key={tab} onClick={() => setActiveTab(tab)} className={`pb-4 px-1 text-[14px] font-bold capitalize transition-colors border-b-2 ${activeTab === tab ? 'text-primary-purple border-primary-purple' : 'text-text-muted border-transparent hover:text-text-main'}`}>
            {tab}
          </button>
        ))}
      </div>

      {activeTab === 'profile' && (
        <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} className="space-y-6">
          {/* Avatar */}
          <div className="bg-white rounded-[20px] border border-border-light shadow-[0_2px_12px_rgba(0,0,0,0.02)] p-6">
            <h3 className="text-[15px] font-bold text-text-main mb-5">Profile Picture</h3>
            <div className="flex items-center gap-6">
              <div className="w-20 h-20 rounded-2xl bg-gradient-to-br from-primary-purple to-deep-violet flex items-center justify-center text-white text-3xl font-black shadow-lg">R</div>
              <div>
                <button className="px-5 py-2 bg-primary-purple text-white rounded-xl text-[13px] font-bold hover:bg-deep-violet transition-colors">Upload Photo</button>
                <p className="text-[12px] text-text-muted mt-2">This photo is shown to your junior in the lineage view.</p>
              </div>
            </div>
          </div>

          {/* Read-only Info */}
          <div className="bg-white rounded-[20px] border border-border-light shadow-[0_2px_12px_rgba(0,0,0,0.02)] p-6">
            <h3 className="text-[15px] font-bold text-text-main mb-5">Alumni Identity (Read-only)</h3>
            <div className="grid grid-cols-2 gap-4">
              {[
                { label: 'Roll Number', value: '23MX301' },
                { label: 'Graduation Batch', value: '23MX · Class of 2025' },
                { label: 'Alumni Since', value: 'June 2025' },
                { label: 'Department', value: 'MCA — Computer Applications' },
              ].map((f, i) => (
                <div key={i} className="p-4 bg-page-bg rounded-xl">
                  <p className="text-[11px] font-bold text-text-muted uppercase tracking-wider">{f.label}</p>
                  <p className="text-[14px] font-bold text-text-main mt-1">{f.value}</p>
                </div>
              ))}
            </div>
          </div>

          {/* Editable Profile */}
          <div className="bg-white rounded-[20px] border border-border-light shadow-[0_2px_12px_rgba(0,0,0,0.02)] p-6">
            <h3 className="text-[15px] font-bold text-text-main mb-5">Professional Details</h3>
            <div className="space-y-4">
              <div>
                <label className="text-[12px] font-bold text-text-muted uppercase tracking-wider block mb-2">Display Name</label>
                <input type="text" defaultValue="Riya Menon" className="w-full bg-page-bg border border-border-light rounded-xl px-4 py-3 text-[14px] text-text-main outline-none focus:border-primary-purple transition-colors" />
              </div>
              <div>
                <label className="text-[12px] font-bold text-text-muted uppercase tracking-wider block mb-2">Current Company</label>
                <input type="text" defaultValue="Zoho Corporation" className="w-full bg-page-bg border border-border-light rounded-xl px-4 py-3 text-[14px] text-text-main outline-none focus:border-primary-purple transition-colors" />
              </div>
              <div>
                <label className="text-[12px] font-bold text-text-muted uppercase tracking-wider block mb-2">Current Role / Title</label>
                <input type="text" defaultValue="Software Engineer" className="w-full bg-page-bg border border-border-light rounded-xl px-4 py-3 text-[14px] text-text-main outline-none focus:border-primary-purple transition-colors" />
              </div>
              <div>
                <label className="text-[12px] font-bold text-text-muted uppercase tracking-wider block mb-2 flex items-center gap-2"><Linkedin className="w-3.5 h-3.5 text-primary-purple" /> LinkedIn URL</label>
                <input type="url" placeholder="https://linkedin.com/in/your-profile" className="w-full bg-page-bg border border-border-light rounded-xl px-4 py-3 text-[14px] text-text-main outline-none focus:border-primary-purple transition-colors" />
              </div>
              <div>
                <label className="text-[12px] font-bold text-text-muted uppercase tracking-wider block mb-2 flex items-center gap-2"><Globe className="w-3.5 h-3.5 text-text-muted" /> Personal Website</label>
                <input type="url" placeholder="https://yourwebsite.com" className="w-full bg-page-bg border border-border-light rounded-xl px-4 py-3 text-[14px] text-text-main outline-none focus:border-primary-purple transition-colors" />
              </div>
              <div>
                <label className="text-[12px] font-bold text-text-muted uppercase tracking-wider block mb-2">Short Bio (shown in lineage card)</label>
                <textarea rows={3} defaultValue="Stay consistent. The score takes care of itself." className="w-full bg-page-bg border border-border-light rounded-xl px-4 py-3 text-[14px] text-text-main outline-none focus:border-primary-purple transition-colors resize-none" />
              </div>
            </div>
            <div className="flex items-center gap-3 mt-6">
              <button onClick={handleSave} className="flex items-center gap-2 px-6 py-3 bg-primary-purple text-white rounded-xl text-[14px] font-bold hover:bg-deep-violet transition-colors">
                <Save className="w-4 h-4" /> Save Changes
              </button>
              {saved && <motion.span initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="text-[13px] font-bold text-electric-blue">✓ Saved!</motion.span>}
            </div>
          </div>
        </motion.div>
      )}

      {activeTab === 'mentorship' && (
        <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} className="space-y-6">
          <div className="bg-white rounded-[20px] border border-border-light shadow-[0_2px_12px_rgba(0,0,0,0.02)] p-6">
            <h3 className="text-[15px] font-bold text-text-main mb-5">Mentorship Preferences</h3>
            <div className="flex items-center justify-between p-4 bg-page-bg rounded-xl mb-5">
              <div>
                <p className="text-[14px] font-bold text-text-main">Available for Mentorship</p>
                <p className="text-[12px] text-text-muted mt-0.5">Your junior (25MX301) can see your contact information</p>
              </div>
              <button onClick={() => setMentorshipActive(!mentorshipActive)} className="transition-transform active:scale-95">
                {mentorshipActive ? <ToggleRight className="w-10 h-10 text-electric-blue" /> : <ToggleLeft className="w-10 h-10 text-border-light" />}
              </button>
            </div>
            <div className="space-y-4">
              <div>
                <label className="text-[12px] font-bold text-text-muted uppercase tracking-wider block mb-2">Preferred Contact Method</label>
                <select className="w-full bg-page-bg border border-border-light rounded-xl px-4 py-3 text-[14px] text-text-main outline-none focus:border-primary-purple transition-colors">
                  <option>LinkedIn</option>
                  <option>Email</option>
                  <option>Platform Message</option>
                </select>
              </div>
              <div>
                <label className="text-[12px] font-bold text-text-muted uppercase tracking-wider block mb-2">Availability Note</label>
                <input type="text" defaultValue="Best reached evenings on weekdays." className="w-full bg-page-bg border border-border-light rounded-xl px-4 py-3 text-[14px] text-text-main outline-none focus:border-primary-purple transition-colors" />
              </div>
              <button onClick={handleSave} className="flex items-center gap-2 px-6 py-3 bg-primary-purple text-white rounded-xl text-[14px] font-bold hover:bg-deep-violet transition-colors">
                <Save className="w-4 h-4" /> Save Mentorship Settings
              </button>
            </div>
          </div>
        </motion.div>
      )}

      {activeTab === 'account' && (
        <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} className="space-y-6">
          <div className="bg-white rounded-[20px] border border-border-light shadow-[0_2px_12px_rgba(0,0,0,0.02)] p-6">
            <h3 className="text-[15px] font-bold text-text-main mb-5">Change Password</h3>
            <div className="space-y-4">
              <input type="password" placeholder="Current password" className="w-full bg-page-bg border border-border-light rounded-xl px-4 py-3 text-[14px] outline-none focus:border-primary-purple transition-colors" />
              <input type="password" placeholder="New password" className="w-full bg-page-bg border border-border-light rounded-xl px-4 py-3 text-[14px] outline-none focus:border-primary-purple transition-colors" />
              <input type="password" placeholder="Confirm new password" className="w-full bg-page-bg border border-border-light rounded-xl px-4 py-3 text-[14px] outline-none focus:border-primary-purple transition-colors" />
            </div>
            <button className="mt-4 px-6 py-3 bg-primary-purple text-white rounded-xl text-[14px] font-bold hover:bg-deep-violet transition-colors">Update Password</button>
          </div>

          <div className="bg-white rounded-[20px] border border-deep-violet/30 p-6">
            <h3 className="text-[15px] font-bold text-deep-violet mb-2">Sign Out</h3>
            <p className="text-[13px] text-text-muted mb-4">You'll need your alumni credentials to sign back in.</p>
            <button onClick={async () => { try { await fetch('/api/auth/logout', { method: 'POST' }); } catch {} window.location.href = '/login'; }} className="px-6 py-3 bg-deep-violet text-white rounded-xl text-[14px] font-bold hover:opacity-90 transition-opacity">
              Sign Out
            </button>
          </div>
        </motion.div>
      )}
    </div>
  );
}
