'use client';

import React from 'react';
import { motion } from 'framer-motion';
import { LogOut, Activity, Users, ShieldAlert, BarChart3, Crown } from 'lucide-react';
import { useRouter } from 'next/navigation';
import PilotAnalytics from '@/components/PilotAnalytics';

export default function HodDashboard() {
  const router = useRouter();
  const [metrics, setMetrics] = React.useState({ students: '...', alumni: '...', networks: '...' });
  const [pendingAlumni, setPendingAlumni] = React.useState<any[]>([]);

  const fetchPendingAlumni = async () => {
    try {
      const res = await fetch('/api/hod/pending-alumni');
      const data = await res.json();
      if (data.success) {
        setPendingAlumni(data.pendingAlumni || data.data || []);
      }
    } catch (e) {
      console.error(e);
    }
  };

  React.useEffect(() => {
    fetch('/api/metrics')
      .then(res => res.json())
      .then(data => {
        if (data.success) {
          setMetrics({
            students: data.data.studentsCount.toString(),
            alumni: data.data.alumniCount.toString(),
            networks: data.data.networksCount.toString()
          });
        }
      })
      .catch(console.error);

    fetchPendingAlumni();
  }, []);

  const handleApprove = async (userId: string, action: 'approve' | 'reject') => {
    try {
      const res = await fetch('/api/hod/pending-alumni', {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ userId, action })
      });
      if (res.ok) fetchPendingAlumni();
    } catch (e) {
      console.error(e);
    }
  };

  const handleLogout = () => {
    document.cookie = "token=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;";
    router.push('/login');
  };

  return (
    <div className="min-h-screen bg-page-bg text-text-main p-4 md:p-8 relative overflow-hidden">
      {/* Abstract Background */}
      <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[80%] h-[50%] bg-electric-blue/5 rounded-full blur-[150px] pointer-events-none" />

      <div className="max-w-7xl mx-auto relative z-10">
        <header className="flex items-center justify-between mb-12">
          <motion.div initial={{ opacity: 0, x: -20 }} animate={{ opacity: 1, x: 0 }} className="flex items-center gap-4">
            <div className="w-12 h-12 rounded-2xl bg-gradient-to-br from-electric-blue to-deep-violet flex items-center justify-center shadow-[0_0_20px_rgba(0,240,255,0.3)]">
              <Crown className="w-6 h-6 text-white" />
            </div>
            <div>
              <h1 className="text-2xl font-black tracking-tight text-white">Department Head</h1>
              <p className="psgmx-subtitle mt-0.5">MCA Overview</p>
            </div>
          </motion.div>

          <motion.div initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} className="flex items-center gap-4">
            <div className="px-3 py-1 rounded-full bg-electric-blue/20 text-electric-blue border border-electric-blue/30 text-xs font-bold tracking-wider">
              ADMIN
            </div>
            <button onClick={handleLogout} className="p-2.5 rounded-xl psgmx-glass-panel hover:bg-white/5 transition-colors text-text-muted hover:text-white">
              <LogOut className="w-5 h-5" />
            </button>
          </motion.div>
        </header>

        {/* Metrics Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          {[
            { label: 'Active Students', value: metrics.students, icon: Users, color: 'text-primary-purple' },
            { label: 'Lineage Networks', value: metrics.networks, icon: Activity, color: 'text-electric-blue' },
            { label: 'Engaged Alumni', value: metrics.alumni, icon: BarChart3, color: 'text-neon-pink' },
            { label: 'System Alerts', value: '0', icon: ShieldAlert, color: 'text-white' },
          ].map((stat, i) => (
            <motion.div 
              key={i}
              initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.1 }}
              className="psgmx-glass p-6"
            >
              <div className="flex items-center justify-between mb-4">
                <stat.icon className={`w-6 h-6 ${stat.color}`} />
                <span className="text-2xl font-black text-white">{stat.value}</span>
              </div>
              <p className="text-xs font-bold text-text-muted uppercase tracking-wider">{stat.label}</p>
            </motion.div>
          ))}
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          <div className="lg:col-span-2 space-y-8">
            <motion.div 
              initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.4 }}
              className="psgmx-glass p-8"
            >
              <div className="flex items-center justify-between mb-6">
                <h3 className="text-xl font-bold text-white">Alumni Approval Queue</h3>
                <span className="px-3 py-1 bg-neon-pink/20 text-neon-pink rounded-full text-xs font-bold">
                  {pendingAlumni.length} Pending
                </span>
              </div>
              
              <div className="space-y-4">
                {pendingAlumni.length === 0 ? (
                  <div className="h-40 flex flex-col items-center justify-center border border-dashed border-border rounded-2xl">
                    <p className="text-text-muted font-medium">No pending alumni verifications</p>
                  </div>
                ) : (
                  pendingAlumni.map((alumni) => (
                    <div key={alumni._id} className="psgmx-glass-panel p-4 flex items-center justify-between">
                      <div>
                        <p className="font-bold text-white text-lg">{alumni.token}</p>
                        <p className="text-sm text-text-muted">{alumni.email}</p>
                      </div>
                      <div className="flex items-center gap-2">
                        <button 
                          onClick={() => handleApprove(alumni._id, 'reject')}
                          className="px-4 py-2 rounded-lg bg-red-500/10 text-red-400 hover:bg-red-500/20 text-xs font-bold transition-colors"
                        >
                          Reject
                        </button>
                        <button 
                          onClick={() => handleApprove(alumni._id, 'approve')}
                          className="px-4 py-2 rounded-lg bg-electric-blue text-white hover:bg-electric-blue/80 text-xs font-bold transition-colors"
                        >
                          Verify & Activate
                        </button>
                      </div>
                    </div>
                  ))
                )}
              </div>
            </motion.div>
          </div>
          
          <div className="space-y-8">
            <motion.div 
              initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} transition={{ delay: 0.5 }}
              className="psgmx-glass p-8"
            >
              <h3 className="text-xl font-bold text-white mb-6">Top Lineage Clusters</h3>
              <div className="h-40 flex flex-col items-center justify-center border border-dashed border-border rounded-2xl">
                <p className="text-text-muted font-medium">Insufficient lineage data</p>
              </div>
            </motion.div>
          </div>
        </div>

        <PilotAnalytics />
      </div>
    </div>
  );
}
