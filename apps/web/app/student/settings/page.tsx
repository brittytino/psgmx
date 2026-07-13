'use client';

import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { Settings, User, Bell, Shield, Save, Linkedin, Github, ExternalLink } from 'lucide-react';

export default function StudentSettingsPage() {
  const [activeTab, setActiveTab] = useState<'profile' | 'notifications' | 'account'>('profile');
  const [saved, setSaved] = useState(false);

  const handleSave = () => {
    setSaved(true);
    setTimeout(() => setSaved(false), 2500);
  };

  return (
    <div className="max-w-[900px] mx-auto space-y-8 pb-8">

      {/* Header */}
      <div>
        <h1 className="text-[24px] font-black text-text-main tracking-tight flex items-center gap-2">
          <Settings className="w-6 h-6 text-primary-purple" /> Settings
        </h1>
        <p className="text-[13px] text-text-muted mt-0.5">Manage your profile, preferences, and account.</p>
      </div>

      {/* Tabs */}
      <div className="flex gap-6 border-b border-border-light">
        {(['profile', 'notifications', 'account'] as const).map((tab) => (
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
              <div className="w-20 h-20 rounded-2xl bg-gradient-to-br from-primary-purple to-deep-violet flex items-center justify-center text-white text-3xl font-black shadow-lg">S</div>
              <div>
                <button className="px-5 py-2 bg-primary-purple text-white rounded-xl text-[13px] font-bold hover:bg-deep-violet transition-colors">Upload Photo</button>
                <p className="text-[12px] text-text-muted mt-2">JPG, PNG up to 2MB</p>
              </div>
            </div>
          </div>

          {/* Read-only Info */}
          <div className="bg-white rounded-[20px] border border-border-light shadow-[0_2px_12px_rgba(0,0,0,0.02)] p-6">
            <h3 className="text-[15px] font-bold text-text-main mb-5">Identity (Read-only)</h3>
            <div className="grid grid-cols-2 gap-4">
              {[
                { label: 'Roll Number', value: '25MX301' },
                { label: 'Batch', value: '25MX · Class of 2027' },
                { label: 'Department', value: 'MCA — Computer Applications' },
                { label: 'Status', value: 'Active Student' },
              ].map((f, i) => (
                <div key={i} className="p-4 bg-page-bg rounded-xl">
                  <p className="text-[11px] font-bold text-text-muted uppercase tracking-wider">{f.label}</p>
                  <p className="text-[14px] font-bold text-text-main mt-1">{f.value}</p>
                </div>
              ))}
            </div>
            <p className="text-[12px] text-text-muted mt-4 flex items-center gap-1.5"><Shield className="w-3.5 h-3.5" /> To change batch or roll information, contact your placement coordinator.</p>
          </div>

          {/* Editable Profile */}
          <div className="bg-white rounded-[20px] border border-border-light shadow-[0_2px_12px_rgba(0,0,0,0.02)] p-6">
            <h3 className="text-[15px] font-bold text-text-main mb-5">Profile Details</h3>
            <div className="space-y-4">
              <div>
                <label className="text-[12px] font-bold text-text-muted uppercase tracking-wider block mb-2">Display Name</label>
                <input type="text" defaultValue="Student" className="w-full bg-page-bg border border-border-light rounded-xl px-4 py-3 text-[14px] text-text-main outline-none focus:border-primary-purple transition-colors" />
              </div>
              <div>
                <label className="text-[12px] font-bold text-text-muted uppercase tracking-wider block mb-2 flex items-center gap-2"><Linkedin className="w-3.5 h-3.5 text-primary-purple" /> LinkedIn Profile URL</label>
                <input type="url" placeholder="https://linkedin.com/in/your-profile" className="w-full bg-page-bg border border-border-light rounded-xl px-4 py-3 text-[14px] text-text-main outline-none focus:border-primary-purple transition-colors" />
              </div>
              <div>
                <label className="text-[12px] font-bold text-text-muted uppercase tracking-wider block mb-2 flex items-center gap-2"><Github className="w-3.5 h-3.5 text-text-muted" /> GitHub Profile URL</label>
                <input type="url" placeholder="https://github.com/username" className="w-full bg-page-bg border border-border-light rounded-xl px-4 py-3 text-[14px] text-text-main outline-none focus:border-primary-purple transition-colors" />
              </div>
            </div>
            <div className="flex items-center gap-3 mt-6">
              <button onClick={handleSave} className="flex items-center gap-2 px-6 py-3 bg-primary-purple text-white rounded-xl text-[14px] font-bold hover:bg-deep-violet transition-colors">
                <Save className="w-4 h-4" /> Save Changes
              </button>
              {saved && <motion.span initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="text-[13px] font-bold text-electric-blue flex items-center gap-1.5"><span>✓</span> Saved!</motion.span>}
            </div>
          </div>
        </motion.div>
      )}

      {activeTab === 'notifications' && (
        <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} className="bg-white rounded-[20px] border border-border-light shadow-[0_2px_12px_rgba(0,0,0,0.02)] p-6 space-y-5">
          <h3 className="text-[15px] font-bold text-text-main">Notification Preferences</h3>
          {[
            { label: 'Exam reminders', sub: 'Get notified 24h and 1h before scheduled exams', defaultOn: true },
            { label: 'Knowledge Brain approvals', sub: 'When an article you submitted gets approved', defaultOn: true },
            { label: 'Lineage senior activity', sub: 'When your senior updates their profile or posts an article', defaultOn: false },
            { label: 'Department announcements', sub: 'Important notices from faculty and placement team', defaultOn: true },
            { label: 'Readiness score milestones', sub: 'When your score crosses a new band', defaultOn: true },
          ].map((n, i) => (
            <div key={i} className="flex items-center justify-between p-4 bg-page-bg rounded-xl">
              <div>
                <p className="text-[14px] font-bold text-text-main">{n.label}</p>
                <p className="text-[12px] text-text-muted mt-0.5">{n.sub}</p>
              </div>
              <label className="relative inline-flex items-center cursor-pointer">
                <input type="checkbox" defaultChecked={n.defaultOn} className="sr-only peer" />
                <div className="w-10 h-6 bg-border-light peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full after:content-[''] after:absolute after:top-0.5 after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary-purple" />
              </label>
            </div>
          ))}
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

          <div className="bg-white rounded-[20px] border border-deep-violet/30 shadow-[0_2px_12px_rgba(0,0,0,0.02)] p-6">
            <h3 className="text-[15px] font-bold text-deep-violet mb-2">Sign Out</h3>
            <p className="text-[13px] text-text-muted mb-4">You'll need to log in again to access your account.</p>
            <button onClick={async () => { try { await fetch('/api/auth/logout', { method: 'POST' }); } catch {} window.location.href = '/login'; }} className="px-6 py-3 bg-deep-violet text-white rounded-xl text-[14px] font-bold hover:opacity-90 transition-opacity">
              Sign Out
            </button>
          </div>
        </motion.div>
      )}
    </div>
  );
}
