'use client';

import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { TokenGraph } from '@/components/lineage/TokenGraph';
import { TokenBadge } from '@/components/lineage/TokenBadge';
import { SubmitArticleModal } from '@/components/brain/SubmitArticleModal';
import { PostProjectModal } from '@/components/projects/PostProjectModal';
import { LogOut, GraduationCap, BrainCircuit, Activity, Send } from 'lucide-react';
import { useRouter } from 'next/navigation';

export default function StudentDashboard() {
  const router = useRouter();
  
  const [userToken, setUserToken] = useState("LOADING");
  const [userSuffix, setUserSuffix] = useState("...");
  const [userProfile, setUserProfile] = useState<any>(null);

  useEffect(() => {
    const t = sessionStorage.getItem('psgmx_token') || 'UNKNOWN';
    const s = sessionStorage.getItem('psgmx_lineage_suffix') || 'UNK';
    setUserToken(t);
    setUserSuffix(s);

    // Profile check
    fetch('/api/user/profile')
      .then(res => res.json())
      .then(data => {
        if (data.success && data.profile) {
          setUserProfile(data.profile);
          if (!data.profile.linkedin || !data.profile.skills || data.profile.skills.length === 0) {
            router.push('/onboarding/first-login');
          }
        }
      });
  }, [router]);

  const [aiQuery, setAiQuery] = useState('');
  const [aiResponse, setAiResponse] = useState('');
  const [isAiLoading, setIsAiLoading] = useState(false);

  const [isBrainModalOpen, setBrainModalOpen] = useState(false);
  const [isProjectModalOpen, setProjectModalOpen] = useState(false);

  const handleAiAsk = async () => {
    if (!aiQuery) return;
    setIsAiLoading(true);
    try {
      const res = await fetch('/api/ai-senior', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ query: aiQuery })
      });
      const data = await res.json();
      if (data.success) {
        setAiResponse(data.answer);
      } else {
        setAiResponse("Sorry, I encountered an error connecting to the Knowledge Brain.");
      }
    } catch (e) {
      setAiResponse("Connection failed.");
    } finally {
      setIsAiLoading(false);
    }
  };

  const handleLogout = () => {
    document.cookie = "token=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;";
    router.push('/login');
  };

  return (
    <div className="min-h-screen bg-page-bg text-text-main p-4 md:p-8 relative overflow-hidden">
      {/* Abstract Background Orbs */}
      <div className="absolute top-[-10%] left-[-10%] w-[40%] h-[40%] bg-primary-purple/10 rounded-full blur-[120px] pointer-events-none" />
      <div className="absolute bottom-[-10%] right-[-10%] w-[40%] h-[40%] bg-electric-blue/10 rounded-full blur-[120px] pointer-events-none" />

      <div className="max-w-7xl mx-auto relative z-10">
        {/* Header */}
        <header className="flex items-center justify-between mb-12">
          <motion.div initial={{ opacity: 0, x: -20 }} animate={{ opacity: 1, x: 0 }} className="flex items-center gap-4">
            <div className="w-12 h-12 rounded-2xl bg-gradient-to-br from-primary-purple to-deep-violet flex items-center justify-center shadow-[0_0_20px_rgba(108,61,255,0.4)]">
              <GraduationCap className="w-6 h-6 text-white" />
            </div>
            <div>
              <h1 className="text-2xl font-black tracking-tight text-white">Student Portal</h1>
              <p className="psgmx-subtitle mt-0.5">MCA Department</p>
            </div>
          </motion.div>

          <motion.div initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} className="flex items-center gap-4">
            <TokenBadge token={userToken} />
            <button onClick={handleLogout} className="p-2.5 rounded-xl psgmx-glass-panel hover:bg-white/5 transition-colors text-text-muted hover:text-white">
              <LogOut className="w-5 h-5" />
            </button>
          </motion.div>
        </header>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Main Content Column */}
          <div className="lg:col-span-2 space-y-8">
            {/* Welcome Banner */}
            <motion.div 
              initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.1 }}
              className="psgmx-glass p-8 relative overflow-hidden group"
            >
              <div className="absolute inset-0 bg-gradient-to-br from-primary-purple/10 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-500" />
              <h2 className="text-3xl font-black text-white mb-2">Welcome back, {userToken}.</h2>
              <p className="text-text-muted max-w-lg mb-6">Your token lineage has 2 new announcements from the network. Keep your FYP progress updated.</p>
              <div className="flex gap-4">
                <button onClick={() => setBrainModalOpen(true)} className="psgmx-btn-primary">Add to Knowledge Brain</button>
                <button onClick={() => setProjectModalOpen(true)} className="px-6 py-3 rounded-xl border border-border text-white hover:bg-white/5 transition-colors font-semibold shadow-sm text-sm flex items-center gap-2">Log FYP Progress</button>
              </div>
            </motion.div>

            {/* Recovery Engine Widget - Only shown if student has arrears */}
            {userProfile?.arrears && userProfile.arrears.length > 0 && (
              <motion.div 
                initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.2 }}
                className="psgmx-glass p-8 border-rose-500/30"
              >
                <div className="flex items-center justify-between mb-6">
                  <div className="flex items-center gap-3">
                    <BrainCircuit className="w-6 h-6 text-rose-500" />
                    <h3 className="text-xl font-bold text-white">Academic Recovery Hub</h3>
                  </div>
                  <button onClick={() => router.push('/student/recovery-hub')} className="text-sm font-bold text-rose-400 hover:text-rose-300 transition-colors">
                    Enter Hub &rarr;
                  </button>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  {userProfile.arrears.map((arrear: any, idx: number) => (
                    <div key={idx} className="psgmx-glass-panel p-5 border-rose-500/20 hover:border-rose-500/50 transition-colors cursor-pointer group">
                      <div className="flex justify-between items-start mb-4">
                        <div className="p-2 rounded-lg bg-rose-500/10 text-rose-500 group-hover:bg-rose-500 group-hover:text-white transition-colors">
                          <Activity className="w-5 h-5" />
                        </div>
                        <span className="text-xs font-bold px-2 py-1 rounded bg-rose-500/20 text-rose-400 uppercase">{arrear.status}</span>
                      </div>
                      <h4 className="font-bold text-white mb-1">{arrear.subject}</h4>
                      <p className="text-xs text-text-muted">AI Mock Exams Available</p>
                    </div>
                  ))}
                </div>
              </motion.div>
            )}

            {/* AI Senior Interactive Box */}
            <motion.div 
              initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.3 }}
              className="psgmx-glass p-8"
            >
              <div className="flex items-center gap-3 mb-6">
                <div className="p-2 bg-gradient-to-br from-primary-purple to-neon-pink rounded-xl shadow-[0_0_15px_rgba(108,61,255,0.4)]">
                  <BrainCircuit className="w-6 h-6 text-white" />
                </div>
                <h3 className="text-xl font-bold text-white">Ask the AI Senior</h3>
              </div>
              
              <div className="flex flex-col gap-4">
                <div className="relative">
                  <input 
                    type="text" 
                    value={aiQuery}
                    onChange={(e) => setAiQuery(e.target.value)}
                    placeholder="E.g. How do I prepare for Zoho placements? or What's the best tech stack?"
                    className="w-full bg-black/40 border border-border rounded-xl px-4 py-3 text-white placeholder-text-muted focus:outline-none focus:border-primary-purple transition-colors"
                  />
                  <button 
                    onClick={handleAiAsk}
                    disabled={isAiLoading}
                    className="absolute right-2 top-2 p-1.5 bg-primary-purple hover:bg-deep-violet rounded-lg transition-colors text-white disabled:opacity-50"
                  >
                    <Send className="w-4 h-4" />
                  </button>
                </div>

                {isAiLoading && <p className="text-sm text-primary-purple animate-pulse">The AI Senior is searching the Department Knowledge Brain...</p>}
                
                {aiResponse && (
                  <div className="mt-2 p-5 bg-white/5 border border-white/10 rounded-xl">
                    <p className="text-sm text-text-secondary leading-relaxed whitespace-pre-wrap">{aiResponse}</p>
                  </div>
                )}
              </div>
            </motion.div>
          </div>

          {/* Sidebar Column */}
          <div className="space-y-8">
            <motion.div initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} transition={{ delay: 0.3 }}>
              <TokenGraph currentToken={userToken} lineageSuffix={userSuffix} />
            </motion.div>
          </div>
        </div>
      </div>
      
      <SubmitArticleModal 
        isOpen={isBrainModalOpen} 
        onClose={() => setBrainModalOpen(false)} 
        onSuccess={() => {
          setBrainModalOpen(false);
          setAiResponse("Knowledge injected successfully. The Brain is expanding.");
        }} 
      />

      <PostProjectModal 
        isOpen={isProjectModalOpen} 
        onClose={() => setProjectModalOpen(false)} 
        onSuccess={() => setProjectModalOpen(false)} 
      />
    </div>
  );
}
