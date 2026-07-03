'use client';

import React, { useEffect, useState } from 'react';

import { Activity, BrainCircuit, Users, BookOpen, AlertCircle } from 'lucide-react';

export default function PilotAnalytics() {
  const [data, setData] = useState<any>(null);

  useEffect(() => {
    fetch('/api/insights')
      .then(res => res.json())
      .then(res => {
        if (res.success) setData(res.data);
      })
      .catch(console.error);
  }, []);

  if (!data) {
    return <div className="h-40 flex items-center justify-center text-text-muted">Loading Pilot Telemetry...</div>;
  }

  return (
    <div className="psgmx-glass p-8 mt-8">
      <div className="flex items-center justify-between mb-8">
        <div>
          <h3 className="text-xl font-bold text-white flex items-center gap-2">
            <Activity className="w-5 h-5 text-neon-pink" /> 
            Pilot Observability Telemetry
          </h3>
          <p className="text-sm text-text-muted mt-1">Real-time usage metrics across the Phase 13 deployment cohort.</p>
        </div>
        <div className="px-3 py-1 bg-white/5 border border-white/10 rounded-full text-xs font-bold text-text-muted tracking-wider">
          LIVE
        </div>
      </div>

      <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
        <div className="psgmx-glass-panel p-4 rounded-xl">
          <p className="text-xs font-bold text-text-muted uppercase mb-1">Daily / Weekly Active</p>
          <div className="flex items-end gap-2">
            <span className="text-2xl font-black text-white">{data.dau}</span>
            <span className="text-sm text-text-muted mb-1">/ {data.wau}</span>
          </div>
        </div>

        <div className="psgmx-glass-panel p-4 rounded-xl">
          <p className="text-xs font-bold text-text-muted uppercase mb-1">AI Queries (Total)</p>
          <div className="flex items-end gap-2">
            <BrainCircuit className="w-5 h-5 text-electric-blue mb-1" />
            <span className="text-2xl font-black text-white">{data.totalQueries}</span>
          </div>
        </div>

        <div className="psgmx-glass-panel p-4 rounded-xl">
          <p className="text-xs font-bold text-text-muted uppercase mb-1">Profile Completion</p>
          <div className="flex items-end gap-2">
            <Users className="w-5 h-5 text-primary-purple mb-1" />
            <span className="text-2xl font-black text-white">{data.profileCompletionRate}%</span>
          </div>
        </div>

        <div className="psgmx-glass-panel p-4 rounded-xl">
          <p className="text-xs font-bold text-text-muted uppercase mb-1">Alumni Engaged</p>
          <div className="flex items-end gap-2">
            <BookOpen className="w-5 h-5 text-neon-pink mb-1" />
            <span className="text-2xl font-black text-white">{data.alumniParticipationRate}%</span>
          </div>
        </div>
      </div>
      
      <div className="mt-6 flex items-center gap-2 text-xs text-text-muted bg-yellow-500/10 p-3 rounded-lg border border-yellow-500/20">
        <AlertCircle className="w-4 h-4 text-yellow-500" />
        <span>Dormancy sweeps are active. Stale accounts (&gt;30 days) and abandoned projects will be automatically tombstoned.</span>
      </div>
    </div>
  );
}
