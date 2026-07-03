'use client';

import React, { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import { BrainCircuit, BookOpen, Activity, ArrowLeft } from 'lucide-react';
import { useRouter } from 'next/navigation';

export default function RecoveryHub() {
  const router = useRouter();
  const [profile, setProfile] = useState<any>(null);
  
  useEffect(() => {
    fetch('/api/user/profile')
      .then(res => res.json())
      .then(data => {
        if (data.success && data.profile) {
          setProfile(data.profile);
          if (!data.profile.arrears || data.profile.arrears.length === 0) {
            router.push('/student');
          }
        }
      });
  }, [router]);

  if (!profile) {
    return <div className="min-h-screen bg-page-bg text-white flex items-center justify-center">Loading...</div>;
  }

  return (
    <div className="min-h-screen bg-page-bg text-text-main p-4 md:p-8 relative overflow-hidden">
      <div className="absolute top-[-10%] left-[-10%] w-[40%] h-[40%] bg-rose-500/10 rounded-full blur-[120px] pointer-events-none" />
      
      <div className="max-w-7xl mx-auto relative z-10">
        <header className="flex items-center justify-between mb-12">
          <motion.div initial={{ opacity: 0, x: -20 }} animate={{ opacity: 1, x: 0 }} className="flex items-center gap-4">
            <button onClick={() => router.push('/student')} className="p-2.5 rounded-xl psgmx-glass-panel hover:bg-white/5 transition-colors text-text-muted hover:text-white">
              <ArrowLeft className="w-5 h-5" />
            </button>
            <div className="w-12 h-12 rounded-2xl bg-gradient-to-br from-rose-500 to-orange-500 flex items-center justify-center shadow-[0_0_20px_rgba(244,63,94,0.4)]">
              <Activity className="w-6 h-6 text-white" />
            </div>
            <div>
              <h1 className="text-2xl font-black tracking-tight text-white">Recovery Hub</h1>
              <p className="psgmx-subtitle mt-0.5">Academic Intervention & Mock Testing</p>
            </div>
          </motion.div>
        </header>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          <div className="lg:col-span-2 space-y-8">
            <motion.div 
              initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.1 }}
              className="psgmx-glass p-8 border-rose-500/30"
            >
              <h2 className="text-2xl font-black text-white mb-6">Active Arrears</h2>
              
              <div className="space-y-4">
                {profile.arrears?.map((arrear: any, idx: number) => (
                  <div key={idx} className="psgmx-glass-panel p-6 border-rose-500/20">
                    <div className="flex justify-between items-start mb-4">
                      <h3 className="text-xl font-bold text-white">{arrear.subject}</h3>
                      <span className="px-3 py-1 bg-rose-500/20 text-rose-400 rounded-full text-xs font-bold uppercase">{arrear.status}</span>
                    </div>
                    
                    <div className="grid grid-cols-2 gap-4 mt-6">
                      <button className="flex items-center justify-center gap-2 py-3 rounded-xl bg-white/5 hover:bg-white/10 transition-colors border border-white/10 text-white font-semibold text-sm">
                        <BookOpen className="w-4 h-4" /> Previous Year Questions
                      </button>
                      <button className="flex items-center justify-center gap-2 py-3 rounded-xl bg-rose-500 hover:bg-rose-600 transition-colors text-white font-semibold text-sm shadow-[0_0_15px_rgba(244,63,94,0.4)]">
                        <BrainCircuit className="w-4 h-4" /> Start AI Mock Exam
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            </motion.div>
          </div>
          
          <div className="space-y-8">
            <motion.div 
              initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} transition={{ delay: 0.2 }}
              className="psgmx-glass p-8"
            >
              <h3 className="text-xl font-bold text-white mb-6">AI Coach Feedback</h3>
              <div className="h-40 flex flex-col items-center justify-center border border-dashed border-border rounded-2xl p-6 text-center">
                <BrainCircuit className="w-8 h-8 text-text-muted mb-3 opacity-50" />
                <p className="text-sm text-text-muted">Take your first mock exam to receive personalized feedback from the AI Senior.</p>
              </div>
            </motion.div>
          </div>
        </div>
      </div>
    </div>
  );
}
