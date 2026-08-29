'use client';

import React, { useState, useEffect } from 'react';
import { Users, Shield, Award, CheckCircle2, MessageSquare, ArrowRight, Target, Flame } from 'lucide-react';
import { createClient } from '@/lib/supabase/client';
import { InitialsAvatar } from '@/components/basic/InitialsAvatar';

export default function StudentSquadsPage() {
  const supabase = createClient();
  const [squad, setSquad] = useState({
    name: 'Squad Beta (Algorithms & Systems)',
    leader: 'Kavya S (25MX114)',
    objective: 'Complete 15 combined CodeBox verified quests and maintain 80%+ Daily Five adherence.',
    completion_rate: 78,
    members: [
      { name: 'Kavya S', reg_no: '25MX114', role: 'Team Leader', quests: 4, streak: 8 },
      { name: 'Vikram R', reg_no: '25MX128', role: 'Member', quests: 3, streak: 6 },
      { name: 'Britty Tino', reg_no: '25MX102', role: 'Member', quests: 5, streak: 12 },
      { name: 'Sneha M', reg_no: '25MX142', role: 'Member', quests: 2, streak: 4 },
      { name: 'Dinesh K', reg_no: '25MX109', role: 'Member', quests: 3, streak: 5 },
      { name: 'Ananya P', reg_no: '25MX103', role: 'Member', quests: 4, streak: 7 },
    ],
    feed: [
      { text: 'Britty Tino verified Two Sum with O(n) hash map approach', time: '2 hours ago' },
      { text: 'Kavya S completed the DBMS ACID property clinic sprint', time: '4 hours ago' },
      { text: 'Squad reached 75% weekly milestone!', time: 'Yesterday' },
    ]
  });

  return (
    <div className="max-w-5xl mx-auto space-y-6 pb-12">
      <div>
        <span className="text-xs font-bold text-electric-blue uppercase tracking-wider block">
          Heterogeneous Peer Cohort · PRD Chapter 14.1
        </span>
        <h1 className="text-2xl font-black text-white mt-1 flex items-center gap-2">
          <Users className="w-6 h-6 text-electric-blue" />
          {squad.name}
        </h1>
        <p className="text-sm text-slate-400">
          6-8 member balanced squad. Peer competition is evaluated on completion momentum, not raw readiness scores.
        </p>
      </div>

      {/* Squad Objective Banner */}
      <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6 relative overflow-hidden shadow-sm">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div className="space-y-1">
            <div className="flex items-center gap-2 text-xs font-bold text-amber-400 uppercase tracking-wider">
              <Target className="w-4 h-4" /> Weekly Squad Objective
            </div>
            <p className="text-base font-bold text-white max-w-2xl">{squad.objective}</p>
          </div>
          <div className="text-right">
            <div className="text-3xl font-black text-electric-blue">{squad.completion_rate}%</div>
            <span className="text-xs text-slate-400 font-bold uppercase">Weekly Progress</span>
          </div>
        </div>
      </div>

      {/* Grid: Members & Activity Feed */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        {/* Left: Squad Members */}
        <div className="lg:col-span-2 bg-slate-900 border border-slate-800 rounded-2xl p-6 space-y-4">
          <div className="flex items-center justify-between border-b border-slate-800 pb-3">
            <h3 className="text-sm font-bold text-white uppercase tracking-wider">Squad Members ({squad.members.length})</h3>
            <span className="text-xs text-slate-500 font-mono">TL: {squad.leader}</span>
          </div>

          <div className="space-y-3">
            {squad.members.map((m) => (
              <div key={m.reg_no} className="p-3.5 bg-slate-950 rounded-xl border border-slate-800 flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <InitialsAvatar name={m.name} size={36} />
                  <div>
                    <div className="font-bold text-sm text-white flex items-center gap-2">
                      {m.name}
                      {m.role === 'Team Leader' && (
                        <span className="px-2 py-0.5 bg-electric-blue/10 border border-electric-blue/20 text-electric-blue text-[10px] rounded-full">
                          Team Leader
                        </span>
                      )}
                    </div>
                    <div className="text-xs text-slate-500 font-mono">{m.reg_no}</div>
                  </div>
                </div>

                <div className="flex items-center gap-4 text-xs">
                  <span className="text-slate-400">
                    <strong className="text-white">{m.quests}</strong> quests
                  </span>
                  <span className="flex items-center gap-1 text-amber-400 font-bold">
                    <Flame className="w-3.5 h-3.5" /> {m.streak}d
                  </span>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Right: Squad Completion Feed */}
        <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6 space-y-4">
          <h3 className="text-sm font-bold text-white uppercase tracking-wider border-b border-slate-800 pb-3">
            Activity Signals
          </h3>
          <div className="space-y-3">
            {squad.feed.map((f, idx) => (
              <div key={idx} className="p-3 bg-slate-950 rounded-xl border border-slate-800/80 text-xs space-y-1">
                <p className="text-slate-300 font-medium">{f.text}</p>
                <span className="text-[10px] text-slate-500 block">{f.time}</span>
              </div>
            ))}
          </div>
        </div>

      </div>
    </div>
  );
}
