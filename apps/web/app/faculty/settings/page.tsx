'use client';

import React from 'react';
import { motion } from 'framer-motion';
import { Settings, User, Bell, Lock, Sliders, LogOut, Check } from 'lucide-react';
import Link from 'next/link';

import { AnimatePresence } from 'framer-motion';

export default function FacultySettingsDashboard() {
  const [activeTab, setActiveTab] = React.useState('Profile');
  const [isSaving, setIsSaving] = React.useState(false);
  const [showSaved, setShowSaved] = React.useState(false);

  const handleSave = () => {
    setIsSaving(true);
    setTimeout(() => {
      setIsSaving(false);
      setShowSaved(true);
      setTimeout(() => setShowSaved(false), 3000);
    }, 800);
  };

  return (
    <div className="max-w-[1400px] mx-auto space-y-8 pb-8">
      
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div className="flex items-center gap-4">
          <div className="w-12 h-12 rounded-2xl bg-[#6C3DFF] flex items-center justify-center shadow-lg shadow-[#6C3DFF]/20 shrink-0">
            <Settings className="w-6 h-6 text-white" />
          </div>
          <div>
            <motion.h1 
              initial={{ opacity: 0, y: -10 }}
              animate={{ opacity: 1, y: 0 }}
              className="text-[26px] font-bold text-[#1E293B] tracking-tight mb-0.5"
            >
              Settings
            </motion.h1>
            <motion.p 
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 0.1 }}
              className="text-[14px] text-[#64748B]"
            >
              Manage your personal preferences, security, and account settings.
            </motion.p>
          </div>
        </div>
      </div>

      <div className="flex flex-col lg:flex-row gap-8">
        
        {/* Left Sidebar Menu */}
        <div className="w-full lg:w-[280px] shrink-0">
          <div className="bg-white rounded-[20px] shadow-[0_2px_12px_rgba(0,0,0,0.02)] border border-[#F1F5F9] p-4 flex flex-col gap-1">
            <div onClick={() => setActiveTab('Profile')} className={`px-4 py-3 rounded-xl flex items-center gap-3 cursor-pointer transition-colors ${activeTab === 'Profile' ? 'bg-[#F8F6FF] text-[#6C3DFF] font-bold' : 'text-[#64748B] hover:bg-[#F8F9FC] hover:text-[#1E293B] font-semibold'}`}>
              <User className="w-5 h-5" />
              <span className="text-[14px]">Profile Information</span>
            </div>
            <div onClick={() => setActiveTab('Notifications')} className={`px-4 py-3 rounded-xl flex items-center gap-3 cursor-pointer transition-colors ${activeTab === 'Notifications' ? 'bg-[#F8F6FF] text-[#6C3DFF] font-bold' : 'text-[#64748B] hover:bg-[#F8F9FC] hover:text-[#1E293B] font-semibold'}`}>
              <Bell className="w-5 h-5" />
              <span className="text-[14px]">Notifications</span>
            </div>
            <div onClick={() => setActiveTab('Security')} className={`px-4 py-3 rounded-xl flex items-center gap-3 cursor-pointer transition-colors ${activeTab === 'Security' ? 'bg-[#F8F6FF] text-[#6C3DFF] font-bold' : 'text-[#64748B] hover:bg-[#F8F9FC] hover:text-[#1E293B] font-semibold'}`}>
              <Lock className="w-5 h-5" />
              <span className="text-[14px]">Security</span>
            </div>
            <div onClick={() => setActiveTab('Preferences')} className={`px-4 py-3 rounded-xl flex items-center gap-3 cursor-pointer transition-colors ${activeTab === 'Preferences' ? 'bg-[#F8F6FF] text-[#6C3DFF] font-bold' : 'text-[#64748B] hover:bg-[#F8F9FC] hover:text-[#1E293B] font-semibold'}`}>
              <Sliders className="w-5 h-5" />
              <span className="text-[14px]">Preferences</span>
            </div>
            
            <div className="my-2 border-t border-[#F1F5F9]"></div>
            
            <div className="px-4 py-3 text-[#EF4444] hover:bg-[#FEF2F2] rounded-xl flex items-center gap-3 cursor-pointer transition-colors">
              <LogOut className="w-5 h-5" />
              <span className="text-[14px] font-bold">Log out</span>
            </div>
          </div>
        </div>

        {/* Right Main Content */}
        <div className="flex-1 space-y-6">
          
          <div className="bg-white rounded-[20px] shadow-[0_2px_12px_rgba(0,0,0,0.02)] border border-[#F1F5F9] p-8">
            {activeTab === 'Profile' && (
              <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -10 }}>
                <h3 className="text-[18px] font-bold text-[#1E293B] mb-6">Profile Information</h3>
                
                <div className="flex items-center gap-6 mb-8">
                  <div className="w-24 h-24 rounded-full bg-[#E2E8F0] overflow-hidden border-4 border-white shadow-sm relative">
                     <div className="absolute inset-0 flex items-center justify-center bg-gradient-to-br from-[#6C3DFF] to-[#3B82F6] text-white font-bold text-3xl">
                      A
                     </div>
                  </div>
                  <div>
                    <button className="px-4 py-2 bg-[#F8F9FC] border border-[#E2E8F0] text-[#1E293B] rounded-lg text-[13px] font-bold hover:bg-[#F1F5F9] transition-colors mb-2">Change Avatar</button>
                    <p className="text-[11px] text-[#94A3B8]">JPG, GIF or PNG. Max size of 800K</p>
                  </div>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
                  <div className="space-y-2">
                    <label className="text-[12px] font-bold text-[#475569]">Full Name</label>
                    <input type="text" defaultValue="Dr. Arunkumar" className="w-full px-4 py-3 rounded-xl border border-[#E2E8F0] bg-[#F8F9FC] text-[14px] text-[#1E293B] font-semibold focus:outline-none focus:border-[#6C3DFF] focus:bg-white transition-colors" />
                  </div>
                  <div className="space-y-2">
                    <label className="text-[12px] font-bold text-[#475569]">Employee ID</label>
                    <input type="text" defaultValue="PSGMX001" disabled className="w-full px-4 py-3 rounded-xl border border-[#E2E8F0] bg-[#F1F5F9] text-[14px] text-[#64748B] font-semibold focus:outline-none cursor-not-allowed" />
                  </div>
                  <div className="space-y-2">
                    <label className="text-[12px] font-bold text-[#475569]">Department</label>
                    <input type="text" defaultValue="Master of Computer Applications" className="w-full px-4 py-3 rounded-xl border border-[#E2E8F0] bg-[#F8F9FC] text-[14px] text-[#1E293B] font-semibold focus:outline-none focus:border-[#6C3DFF] focus:bg-white transition-colors" />
                  </div>
                  <div className="space-y-2">
                    <label className="text-[12px] font-bold text-[#475569]">Designation</label>
                    <input type="text" defaultValue="Associate Professor" className="w-full px-4 py-3 rounded-xl border border-[#E2E8F0] bg-[#F8F9FC] text-[14px] text-[#1E293B] font-semibold focus:outline-none focus:border-[#6C3DFF] focus:bg-white transition-colors" />
                  </div>
                  <div className="space-y-2 md:col-span-2">
                    <label className="text-[12px] font-bold text-[#475569]">Email Address</label>
                    <input type="email" defaultValue="arunkumar@psgtech.ac.in" className="w-full px-4 py-3 rounded-xl border border-[#E2E8F0] bg-[#F8F9FC] text-[14px] text-[#1E293B] font-semibold focus:outline-none focus:border-[#6C3DFF] focus:bg-white transition-colors" />
                  </div>
                </div>
              </motion.div>
            )}

            {activeTab === 'Notifications' && (
              <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -10 }}>
                <h3 className="text-[18px] font-bold text-[#1E293B] mb-6">Notification Settings</h3>
                <div className="space-y-4 mb-8">
                  {[
                    { title: 'Email Notifications', desc: 'Receive daily summary of student queries.' },
                    { title: 'Push Notifications', desc: 'Get instant alerts for important announcements.' },
                    { title: 'Mentorship Alerts', desc: 'Receive alerts when a mentee falls behind.' },
                  ].map((item, i) => (
                    <div key={i} className="flex items-center justify-between p-4 border border-[#F1F5F9] rounded-xl">
                      <div>
                        <h4 className="text-[14px] font-bold text-[#1E293B]">{item.title}</h4>
                        <p className="text-[12px] text-[#64748B]">{item.desc}</p>
                      </div>
                      <div className="w-10 h-6 bg-[#6C3DFF] rounded-full relative cursor-pointer">
                        <div className="absolute right-1 top-1 w-4 h-4 bg-white rounded-full"></div>
                      </div>
                    </div>
                  ))}
                </div>
              </motion.div>
            )}

            {activeTab === 'Security' && (
              <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -10 }}>
                <h3 className="text-[18px] font-bold text-[#1E293B] mb-6">Security Settings</h3>
                <div className="space-y-6 mb-8">
                  <div className="space-y-2">
                    <label className="text-[12px] font-bold text-[#475569]">Current Password</label>
                    <input type="password" placeholder="••••••••" className="w-full px-4 py-3 rounded-xl border border-[#E2E8F0] bg-[#F8F9FC] text-[14px] text-[#1E293B] focus:outline-none focus:border-[#6C3DFF] focus:bg-white transition-colors" />
                  </div>
                  <div className="space-y-2">
                    <label className="text-[12px] font-bold text-[#475569]">New Password</label>
                    <input type="password" placeholder="••••••••" className="w-full px-4 py-3 rounded-xl border border-[#E2E8F0] bg-[#F8F9FC] text-[14px] text-[#1E293B] focus:outline-none focus:border-[#6C3DFF] focus:bg-white transition-colors" />
                  </div>
                </div>
              </motion.div>
            )}

            {activeTab === 'Preferences' && (
              <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -10 }}>
                <h3 className="text-[18px] font-bold text-[#1E293B] mb-6">System Preferences</h3>
                <div className="space-y-6 mb-8">
                  <div className="space-y-2">
                    <label className="text-[12px] font-bold text-[#475569]">Default Dashboard View</label>
                    <select className="w-full px-4 py-3 rounded-xl border border-[#E2E8F0] bg-[#F8F9FC] text-[14px] text-[#1E293B] font-semibold focus:outline-none focus:border-[#6C3DFF] focus:bg-white transition-colors">
                      <option>Main Dashboard</option>
                      <option>Students Hub</option>
                      <option>Analytics</option>
                    </select>
                  </div>
                </div>
              </motion.div>
            )}

            <div className="flex justify-end items-center gap-4 pt-4 border-t border-[#F1F5F9]">
              <AnimatePresence>
                {showSaved && (
                  <motion.span initial={{ opacity: 0, x: -10 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0 }} className="text-[#10B981] text-[13px] font-bold flex items-center gap-1">
                    <Check className="w-4 h-4" /> Saved Successfully!
                  </motion.span>
                )}
              </AnimatePresence>
              <button onClick={handleSave} disabled={isSaving} className="px-8 py-3 bg-[#6C3DFF] text-white rounded-xl text-[14px] font-bold shadow-md shadow-[#6C3DFF]/20 hover:bg-[#5B21B6] transition-colors flex items-center gap-2 disabled:opacity-50">
                {isSaving ? 'Saving...' : <><Check className="w-4 h-4" /> Save Changes</>}
              </button>
            </div>
          </div>

        </div>

      </div>
    </div>
  );
}
