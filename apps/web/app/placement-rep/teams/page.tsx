'use client';

import React from 'react';
import { motion } from 'framer-motion';
import { Plus, Users, X, UserCheck } from 'lucide-react';
import { createClient } from '@/lib/supabase/client';

interface StudentRow { id: string; name: string; reg_no: string; team_id: string | null }
interface TeamRow { id: string; team_name: string; target_size: number; team_leader_id: string | null }

export default function TeamManagementPage() {
  const [batchId, setBatchId] = React.useState<string | null>(null);
  const [teams, setTeams] = React.useState<TeamRow[]>([]);
  const [students, setStudents] = React.useState<StudentRow[]>([]);
  const [loading, setLoading] = React.useState(true);
  const [showCreate, setShowCreate] = React.useState(false);
  const [newTeamName, setNewTeamName] = React.useState('');
  const [newTeamSize, setNewTeamSize] = React.useState(5);
  const [saving, setSaving] = React.useState(false);

  const supabase = createClient();

  const load = React.useCallback(async () => {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return;
    const { data: me } = await supabase.from('users').select('batch_id').eq('id', user.id).single();
    if (!me?.batch_id) { setLoading(false); return; }
    setBatchId(me.batch_id);

    const [{ data: teamRows }, { data: studentRows }] = await Promise.all([
      supabase.from('teams').select('id, team_name, target_size, team_leader_id').eq('batch_id', me.batch_id).order('team_name'),
      supabase.from('users').select('id, name, reg_no, team_id').eq('batch_id', me.batch_id).eq('role_label', 'Student').order('reg_no'),
    ]);

    setTeams(teamRows || []);
    setStudents(studentRows || []);
    setLoading(false);
  }, [supabase]);

  React.useEffect(() => { load(); }, [load]);

  const handleCreateTeam = async () => {
    if (!newTeamName.trim() || !batchId) return;
    setSaving(true);
    try {
      await supabase.from('teams').insert({ batch_id: batchId, team_name: newTeamName.trim(), target_size: newTeamSize });
      setNewTeamName('');
      setNewTeamSize(5);
      setShowCreate(false);
      await load();
    } finally {
      setSaving(false);
    }
  };

  const handleAssign = async (studentId: string, teamId: string | null) => {
    await supabase.from('users').update({ team_id: teamId }).eq('id', studentId);
    setStudents((prev) => prev.map((s) => (s.id === studentId ? { ...s, team_id: teamId } : s)));
  };

  const handleSetLeader = async (teamId: string, studentId: string) => {
    await supabase.from('teams').update({ team_leader_id: studentId }).eq('id', teamId);
    setTeams((prev) => prev.map((t) => (t.id === teamId ? { ...t, team_leader_id: studentId } : t)));
  };

  if (loading) {
    return <div className="space-y-4 animate-pulse">{[0, 1].map((i) => <div key={i} className="h-40 bg-white border border-border-light rounded-2xl" />)}</div>;
  }

  return (
    <div className="space-y-8 max-w-6xl">
      <div className="flex items-center justify-between">
        <h1 className="text-[24px] font-black text-text-main">Team Management</h1>
        <button
          onClick={() => setShowCreate(true)}
          className="flex items-center gap-2 px-5 py-2.5 bg-primary-purple text-white rounded-xl text-[13px] font-bold hover:bg-deep-violet transition-colors"
        >
          <Plus className="w-4 h-4" /> New Team
        </button>
      </div>

      {showCreate && (
        <motion.div initial={{ opacity: 0, y: -10 }} animate={{ opacity: 1, y: 0 }} className="bg-white rounded-2xl border border-border-light p-6 flex flex-col sm:flex-row gap-4 items-end">
          <div className="flex-1">
            <label className="text-[12px] font-bold text-text-muted block mb-1.5">Team Name</label>
            <input value={newTeamName} onChange={(e) => setNewTeamName(e.target.value)} placeholder="e.g. Team Alpha" className="w-full border border-border-light rounded-lg px-3 py-2 text-[14px] outline-none focus:border-primary-purple" />
          </div>
          <div>
            <label className="text-[12px] font-bold text-text-muted block mb-1.5">Target Size</label>
            <input type="number" min={1} value={newTeamSize} onChange={(e) => setNewTeamSize(Number(e.target.value))} className="w-24 border border-border-light rounded-lg px-3 py-2 text-[14px] outline-none focus:border-primary-purple" />
          </div>
          <button onClick={handleCreateTeam} disabled={saving} className="px-5 py-2 bg-primary-purple text-white rounded-lg text-[13px] font-bold disabled:opacity-50">
            {saving ? 'Creating…' : 'Create'}
          </button>
          <button onClick={() => setShowCreate(false)} className="w-9 h-9 flex items-center justify-center rounded-lg bg-page-bg text-text-muted"><X className="w-4 h-4" /></button>
        </motion.div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {teams.length === 0 && (
          <p className="text-[13px] text-text-muted col-span-2">No teams created for this batch yet.</p>
        )}
        {teams.map((team) => {
          const members = students.filter((s) => s.team_id === team.id);
          return (
            <div key={team.id} className="bg-white rounded-2xl border border-border-light p-6">
              <div className="flex items-center justify-between mb-4">
                <div className="flex items-center gap-2">
                  <Users className="w-5 h-5 text-primary-purple" />
                  <h3 className="text-[15px] font-bold text-text-main">{team.team_name}</h3>
                </div>
                <span className="text-[12px] font-semibold text-text-muted">{members.length}/{team.target_size}</span>
              </div>
              <div className="space-y-2">
                {members.length === 0 && <p className="text-[12px] text-text-muted">No members assigned yet.</p>}
                {members.map((m) => (
                  <div key={m.id} className="flex items-center justify-between p-2.5 rounded-lg hover:bg-page-bg">
                    <span className="text-[13px] font-semibold text-text-main">{m.name} <span className="text-text-muted font-normal">· {m.reg_no}</span></span>
                    <div className="flex items-center gap-2">
                      {team.team_leader_id === m.id ? (
                        <span className="text-[10px] font-bold text-primary-purple bg-primary-purple/10 px-2 py-1 rounded-full">Leader</span>
                      ) : (
                        <button onClick={() => handleSetLeader(team.id, m.id)} className="text-[10px] font-bold text-text-muted hover:text-primary-purple flex items-center gap-1">
                          <UserCheck className="w-3 h-3" /> Make Leader
                        </button>
                      )}
                      <button onClick={() => handleAssign(m.id, null)} className="text-text-muted hover:text-deep-violet"><X className="w-3.5 h-3.5" /></button>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          );
        })}
      </div>

      <div className="bg-white rounded-2xl border border-border-light p-6">
        <h3 className="text-[15px] font-bold text-text-main mb-4">Unassigned Students</h3>
        <div className="space-y-2">
          {students.filter((s) => !s.team_id).length === 0 && <p className="text-[13px] text-text-muted">Every student is assigned to a team.</p>}
          {students.filter((s) => !s.team_id).map((s) => (
            <div key={s.id} className="flex items-center justify-between p-2.5 rounded-lg hover:bg-page-bg">
              <span className="text-[13px] font-semibold text-text-main">{s.name} <span className="text-text-muted font-normal">· {s.reg_no}</span></span>
              <select
                onChange={(e) => e.target.value && handleAssign(s.id, e.target.value)}
                defaultValue=""
                className="text-[12px] border border-border-light rounded-lg px-2 py-1.5 outline-none"
              >
                <option value="" disabled>Assign to team…</option>
                {teams.map((t) => <option key={t.id} value={t.id}>{t.team_name}</option>)}
              </select>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
