'use client';

import React, { useState, useEffect } from 'react';
import { Users, Target, Flame, CheckCircle2, ShieldCheck, Loader2 } from 'lucide-react';
import { createClient } from '@/lib/supabase/client';
import { getCurrentProfile } from '@/lib/current-profile';
import { InitialsAvatar } from '@/components/basic/InitialsAvatar';

interface Member {
  id: string;
  name: string;
  reg_no: string;
  role: string;
  quests: number;
  streak: number;
}

interface SquadData {
  name: string;
  team_code: string;
  leader: string;
  objective: string;
  completion_rate: number;
  members: Member[];
  feed: { text: string; time: string }[];
}

export default function StudentSquadsPage() {
  const [squad, setSquad] = useState<SquadData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    async function loadSquad() {
      try {
        const supabase = createClient();
        const me = await getCurrentProfile(supabase);
        if (!me) {
          setLoading(false);
          return;
        }

        // The member roster (name, reg no, Team Leader flag, streak, verified
        // quest count) is served by get_my_squad() rather than reading
        // `users`/`daily_five_streaks`/`code_submissions` directly — those
        // tables' RLS only ever granted read access to the row's own owner
        // or an admin role, never to a squadmate, so the old direct-query
        // version of this page always rendered an empty member list for
        // anyone without an admin capability.
        const { data: squadData, error: rpcError } = await supabase.rpc('get_my_squad' as never);
        if (rpcError) throw rpcError;

        const teamData = squadData as {
          team_id: string;
          team_name: string;
          team_code: string;
          objective: string;
          members: { id: string; name: string; reg_no: string; is_team_leader: boolean; current_streak: number; verified_quest_count: number }[];
          feed: { member_name: string; quest_title: string; completed_at: string }[];
        } | null;

        const members: Member[] = (teamData?.members || []).map(m => ({
          id: m.id,
          name: m.name || 'Student',
          reg_no: m.reg_no || '—',
          role: m.is_team_leader ? 'Team Leader' : 'Member',
          quests: m.verified_quest_count,
          streak: m.current_streak,
        }));

        if (!teamData || members.length === 0) {
          setSquad(null);
        } else {
          const leaderMember = members.find(m => m.role === 'Team Leader') || members[0];
          const totalQuests = members.reduce((acc, m) => acc + m.quests, 0);
          const completionRate = Math.min(100, Math.round((totalQuests / Math.max(1, members.length * 3)) * 100));

          setSquad({
            name: teamData.team_name || `Squad ${teamData.team_code}`,
            team_code: teamData.team_code,
            leader: `${leaderMember.name} (${leaderMember.reg_no})`,
            // Real, PR-settable objective (get_my_squad() falls back to a
            // computed default when the PR hasn't set one for this squad yet).
            objective: teamData.objective,
            completion_rate: completionRate,
            members,
            // Real verified-quest-completion events from the last 7 days —
            // this used to always be an empty array.
            feed: (teamData.feed || []).map(f => ({
              text: `${f.member_name} verified "${f.quest_title}"`,
              time: new Date(f.completed_at).toLocaleString(undefined, {
                month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit',
              }),
            })),
          });
        }
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Squad could not be loaded.');
      } finally {
        setLoading(false);
      }
    }

    loadSquad();
  }, []);

  if (loading) {
    return (
      <div className="flex min-h-64 items-center justify-center">
        <Loader2 className="h-6 w-6 animate-spin text-primary-purple" />
      </div>
    );
  }

  if (!squad) return <div className="mx-auto max-w-3xl rounded-3xl border border-dashed border-border-light bg-white p-10 text-center"><Users className="mx-auto h-10 w-10 text-text-muted"/><h1 className="mt-4 text-xl font-black">Squad assignment pending</h1><p className="mt-2 text-sm text-text-muted">The PR panel can auto-build balanced squads for your batch. No temporary squad is shown.</p>{error && <p className="mt-3 text-sm font-bold text-red-600">{error}</p>}</div>;

  return (
    <div className="max-w-5xl mx-auto space-y-6 pb-12">
      <div>
        <span className="text-xs font-bold text-primary-purple uppercase tracking-wider block">
          Heterogeneous Peer Cohort · PRD Chapter 14.1
        </span>
        <h1 className="text-2xl font-black text-text-main mt-1 flex items-center gap-2">
          <Users className="w-6 h-6 text-primary-purple" />
          {squad.name}
        </h1>
        <p className="text-sm text-text-muted">
          6-8 member balanced squad. Peer competition is evaluated on completion momentum, not raw readiness scores.
        </p>
      </div>

      {/* Squad Objective Banner */}
      <div className="bg-white border border-border-light rounded-2xl p-6 relative overflow-hidden shadow-sm">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div className="space-y-1">
            <div className="flex items-center gap-2 text-xs font-bold text-amber-600 uppercase tracking-wider">
              <Target className="w-4 h-4" /> Weekly Squad Objective
            </div>
            <p className="text-base font-bold text-text-main max-w-2xl">{squad.objective}</p>
          </div>
          <div className="text-right">
            <div className="text-3xl font-black text-primary-purple">{squad.completion_rate}%</div>
            <span className="text-xs text-text-muted font-bold uppercase">Weekly Progress</span>
          </div>
        </div>
      </div>

      {/* Grid: Members & Activity Feed */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        {/* Left: Squad Members */}
        <div className="lg:col-span-2 bg-white border border-border-light rounded-2xl p-6 space-y-4 shadow-sm">
          <div className="flex items-center justify-between border-b border-border-light pb-3">
            <h3 className="text-sm font-bold text-text-main uppercase tracking-wider">Squad Members ({squad.members.length})</h3>
            <span className="text-xs text-text-muted font-mono">TL: {squad.leader}</span>
          </div>

          <div className="space-y-3">
            {squad.members.map((m) => (
              <div key={m.reg_no} className="p-3.5 bg-page-bg rounded-xl border border-border-light flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <InitialsAvatar name={m.name} size={36} />
                  <div>
                    <div className="font-bold text-sm text-text-main flex items-center gap-2">
                      {m.name}
                      {m.role === 'Team Leader' && (
                        <span className="px-2 py-0.5 bg-primary-purple/10 border border-primary-purple/20 text-primary-purple text-[10px] font-bold rounded-full">
                          Team Leader
                        </span>
                      )}
                    </div>
                    <div className="text-xs text-text-muted font-mono">{m.reg_no}</div>
                  </div>
                </div>

                <div className="flex items-center gap-4 text-xs">
                  <span className="text-text-muted">
                    <strong className="text-text-main font-bold">{m.quests}</strong> quests
                  </span>
                  <span className="flex items-center gap-1 text-amber-600 font-bold">
                    <Flame className="w-3.5 h-3.5" /> {m.streak}d
                  </span>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Right: Squad Completion Feed */}
        <div className="bg-white border border-border-light rounded-2xl p-6 space-y-4 shadow-sm">
          <h3 className="text-sm font-bold text-text-main uppercase tracking-wider border-b border-border-light pb-3">
            Activity Signals
          </h3>
          <div className="space-y-3">
            {squad.feed.map((f, idx) => (
              <div key={idx} className="p-3 bg-page-bg rounded-xl border border-border-light text-xs space-y-1">
                <p className="text-text-main font-medium">{f.text}</p>
                <span className="text-[10px] text-text-muted block">{f.time}</span>
              </div>
            ))}
            {squad.feed.length === 0 && <p className="rounded-xl border border-dashed border-border-light p-4 text-center text-xs text-text-muted">Verified squad activity will appear after member submissions.</p>}
          </div>
        </div>

      </div>
    </div>
  );
}
