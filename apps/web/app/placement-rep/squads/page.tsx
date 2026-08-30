'use client';

import React from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  Users, UserCheck, GraduationCap, WandSparkles, Plus, X,
  ChevronDown, Search, Check, AlertTriangle, Loader2,
  Crown, BookOpen
} from 'lucide-react';
import { createClient } from '@/lib/supabase/client';
import { getCurrentProfile } from '@/lib/current-profile';

interface Student {
  id: string;
  name: string;
  reg_no: string;
  team_uuid: string | null;
  mentor_id: string | null;
  mentor_name: string | null;
}

interface Team {
  id: string;
  team_name: string;
  team_code: string;
  target_size: number;
  team_leader_id: string | null;
  team_leader_name: string | null;
}

interface Faculty {
  id: string;
  name: string;
  email: string;
}

export default function SquadsManagementPage() {
  const supabase = React.useMemo(() => createClient(), []);
  const [batchId, setBatchId] = React.useState<string | null>(null);
  const [teams, setTeams] = React.useState<Team[]>([]);
  const [students, setStudents] = React.useState<Student[]>([]);
  const [faculty, setFaculty] = React.useState<Faculty[]>([]);
  const [loading, setLoading] = React.useState(true);
  const [busy, setBusy] = React.useState(false);
  const [message, setMessage] = React.useState('');
  const [error, setError] = React.useState('');

  // Create team form
  const [showCreate, setShowCreate] = React.useState(false);
  const [newTeamName, setNewTeamName] = React.useState('');
  const [newTeamSize, setNewTeamSize] = React.useState(8);

  // Search
  const [query, setQuery] = React.useState('');
  const [expandedTeam, setExpandedTeam] = React.useState<string | null>(null);

  const load = React.useCallback(async () => {
    const me = await getCurrentProfile(supabase);
    if (!me?.batch_id) { setLoading(false); return; }
    setBatchId(me.batch_id);

    const [{ data: teamRows }, { data: studentRows }, { data: facultyRows }, { data: mentorRows }] = await Promise.all([
      supabase.from('teams').select('id, team_name, team_code, target_size, team_leader_id').eq('batch_id', me.batch_id).order('team_name'),
      supabase.from('users').select('id, name, reg_no, team_uuid').eq('batch_id', me.batch_id).eq('role_label', 'Student').order('name'),
      supabase.from('users').select('id, name, email').in('role_label', ['Faculty', 'HOD']).order('name'),
      (supabase as any).from('mentor_assignments').select('student_id, mentor_id, users!mentor_assignments_mentor_id_fkey(name)').eq('batch_id', me.batch_id).eq('active', true),
    ]);

    // Build mentor map
    const mentorMap = new Map<string, { id: string; name: string }>();
    (mentorRows || []).forEach((m: any) => {
      mentorMap.set(m.student_id, { id: m.mentor_id, name: m.users?.name || 'Unknown' });
    });

    // Build team leader names
    const leaderMap = new Map<string, string>();
    (studentRows || []).forEach((s: any) => {
      leaderMap.set(s.id, s.name);
    });

    setTeams((teamRows || []).map((t: any) => ({
      ...t,
      team_leader_name: t.team_leader_id ? (leaderMap.get(t.team_leader_id) || 'Unknown') : null,
    })));
    setStudents((studentRows || []).map((s: any) => ({
      ...s,
      mentor_id: mentorMap.get(s.id)?.id || null,
      mentor_name: mentorMap.get(s.id)?.name || null,
    })));
    setFaculty(facultyRows || []);
    setLoading(false);
  }, [supabase]);

  React.useEffect(() => { void load(); }, [load]);

  const flash = (msg: string, isError = false) => {
    if (isError) setError(msg); else setMessage(msg);
    setTimeout(() => { setError(''); setMessage(''); }, 5000);
  };

  const handleCreateTeam = async () => {
    if (!newTeamName.trim() || !batchId) return;
    setBusy(true);
    const usedCodes = new Set(teams.map(t => t.team_code));
    let seq = 1;
    while (usedCodes.has(`T${String(seq).padStart(2, '0')}`)) seq++;
    const nextCode = `T${String(seq).padStart(2, '0')}`;
    const { error: e } = await supabase.from('teams').insert({ batch_id: batchId, team_name: newTeamName.trim(), team_code: nextCode, target_size: newTeamSize });
    if (e) flash(e.message, true); else { flash('Squad created.'); setNewTeamName(''); setShowCreate(false); await load(); }
    setBusy(false);
  };

  const handleAssignToTeam = async (studentId: string, teamId: string) => {
    const { error: e } = await supabase.rpc('assign_team_member', { p_user_id: studentId, p_team_id: teamId });
    if (e) flash(e.message, true); else { await load(); }
  };

  const handleSetLeader = async (teamId: string, studentId: string | null) => {
    const { error: e } = await supabase.from('teams').update({ team_leader_id: studentId }).eq('id', teamId);
    if (e) flash(e.message, true); else { flash('Team leader updated.'); await load(); }
  };

  const handleAssignMentor = async (studentId: string, mentorId: string) => {
    setBusy(true);
    const { error: e } = await (supabase as any).rpc('assign_student_mentor', {
      p_student_id: studentId,
      p_mentor_id: mentorId,
      p_focus_areas: [],
    });
    if (e) flash(e.message, true); else { flash('Mentor assigned.'); await load(); }
    setBusy(false);
  };

  const handleAutoBalance = async () => {
    setBusy(true);
    const { data, error: e } = await (supabase as any).rpc('auto_assign_unassigned_squads', { p_target_size: newTeamSize });
    if (e) flash(e.message, true);
    else flash(`${data?.assigned ?? 0} students auto-assigned across balanced squads.`);
    await load();
    setBusy(false);
  };

  const handleBulkMentor = async () => {
    setBusy(true);
    const { data, error: e } = await (supabase as any).rpc('pr_bulk_assign_mentors', { p_batch_id: batchId });
    if (e) flash(e.message, true);
    else flash(`${data?.assigned ?? 0} mentor assignments created across ${data?.faculty_count ?? 0} faculty members.`);
    await load();
    setBusy(false);
  };

  const term = query.trim().toLowerCase();
  const filteredStudents = students.filter(s => !term || s.name.toLowerCase().includes(term) || s.reg_no.toLowerCase().includes(term));
  const unassigned = filteredStudents.filter(s => !s.team_uuid);
  const studentsInTeam = (teamId: string) => filteredStudents.filter(s => s.team_uuid === teamId);

  if (loading) return (
    <div className="space-y-4 animate-pulse">
      {[0,1,2].map(i => <div key={i} className="h-24 bg-white border border-border-light rounded-2xl" />)}
    </div>
  );

  return (
    <div className="max-w-6xl space-y-8">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-[24px] font-black text-text-main flex items-center gap-2">
            <Users className="w-6 h-6 text-primary-purple" />
            Squads &amp; Mentors
          </h1>
          <p className="text-[13px] text-text-muted mt-1">
            {teams.length} squads · {students.length} students · {faculty.length} faculty mentors
          </p>
        </div>
        <div className="flex flex-wrap gap-2">
          <button onClick={handleBulkMentor} disabled={busy}
            className="flex items-center gap-2 px-4 py-2 bg-white border border-border-light rounded-xl text-[13px] font-bold hover:border-primary-purple transition-colors disabled:opacity-50">
            <GraduationCap className="w-4 h-4 text-primary-purple" />
            Auto-assign Mentors
          </button>
          <button onClick={handleAutoBalance} disabled={busy}
            className="flex items-center gap-2 px-4 py-2 bg-white border border-border-light rounded-xl text-[13px] font-bold hover:border-primary-purple transition-colors disabled:opacity-50">
            <WandSparkles className="w-4 h-4 text-primary-purple" />
            Auto-balance Squads
          </button>
          <button onClick={() => setShowCreate(!showCreate)}
            className="flex items-center gap-2 px-4 py-2 bg-primary-purple text-white rounded-xl text-[13px] font-bold">
            <Plus className="w-4 h-4" /> New Squad
          </button>
        </div>
      </div>

      <AnimatePresence>
        {(message || error) && (
          <motion.div initial={{ opacity: 0, y: -8 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0 }}
            className={`p-4 rounded-2xl text-sm font-bold ${error ? 'bg-red-50 border border-red-200 text-red-700' : 'bg-emerald-50 border border-emerald-200 text-emerald-800'}`}>
            {error || message}
          </motion.div>
        )}
      </AnimatePresence>

      {/* Create Squad Form */}
      <AnimatePresence>
        {showCreate && (
          <motion.div initial={{ opacity: 0, height: 0 }} animate={{ opacity: 1, height: 'auto' }} exit={{ opacity: 0, height: 0 }}
            className="bg-white border border-border-light rounded-2xl p-6 overflow-hidden">
            <h3 className="text-[15px] font-bold mb-4">Create New Squad</h3>
            <div className="flex flex-col sm:flex-row gap-3">
              <input
                value={newTeamName} onChange={e => setNewTeamName(e.target.value)}
                placeholder="Squad name (e.g., Alpha Squad)"
                className="flex-1 px-4 py-2.5 border border-border-light rounded-xl text-[14px] outline-none focus:border-primary-purple"
              />
              <select value={newTeamSize} onChange={e => setNewTeamSize(Number(e.target.value))}
                className="px-4 py-2.5 border border-border-light rounded-xl text-[14px] outline-none">
                {[4,5,6,7,8,10].map(n => <option key={n} value={n}>{n} members</option>)}
              </select>
              <button onClick={handleCreateTeam} disabled={!newTeamName.trim() || busy}
                className="px-5 py-2.5 bg-primary-purple text-white rounded-xl text-[13px] font-bold disabled:opacity-50">
                {busy ? <Loader2 className="w-4 h-4 animate-spin" /> : 'Create'}
              </button>
              <button onClick={() => setShowCreate(false)}
                className="px-4 py-2.5 border border-border-light rounded-xl text-[13px] font-bold text-text-muted">
                Cancel
              </button>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Search */}
      <div className="relative">
        <Search className="absolute left-4 top-3.5 w-4 h-4 text-text-muted" />
        <input value={query} onChange={e => setQuery(e.target.value)}
          placeholder="Search students by name or register number"
          className="w-full pl-11 pr-4 py-3 bg-white border border-border-light rounded-2xl text-[14px] outline-none focus:border-primary-purple" />
      </div>

      {/* Squad Cards */}
      <div className="space-y-4">
        {teams.map(team => {
          const members = studentsInTeam(team.id);
          const isOpen = expandedTeam === team.id;
          return (
            <div key={team.id} className="bg-white border border-border-light rounded-2xl overflow-hidden shadow-sm">
              <button
                onClick={() => setExpandedTeam(isOpen ? null : team.id)}
                className="w-full flex items-center justify-between p-5 text-left hover:bg-page-bg transition-colors">
                <div className="flex items-center gap-4">
                  <div className="w-10 h-10 bg-violet-50 rounded-xl flex items-center justify-center">
                    <span className="text-[11px] font-black text-primary-purple">{team.team_code}</span>
                  </div>
                  <div>
                    <h3 className="text-[15px] font-bold text-text-main">{team.team_name}</h3>
                    <p className="text-[12px] text-text-muted">
                      {members.length}/{team.target_size} members
                      {team.team_leader_name && <span> · Leader: {team.team_leader_name}</span>}
                    </p>
                  </div>
                </div>
                <div className="flex items-center gap-3">
                  <span className={`text-[11px] font-bold px-2.5 py-1 rounded-full ${members.length >= team.target_size ? 'bg-emerald-100 text-emerald-700' : 'bg-amber-50 text-amber-700'}`}>
                    {members.length >= team.target_size ? 'Full' : `${team.target_size - members.length} open`}
                  </span>
                  <ChevronDown className={`w-4 h-4 text-text-muted transition-transform ${isOpen ? 'rotate-180' : ''}`} />
                </div>
              </button>

              <AnimatePresence>
                {isOpen && (
                  <motion.div initial={{ height: 0 }} animate={{ height: 'auto' }} exit={{ height: 0 }} className="overflow-hidden">
                    <div className="border-t border-border-light">
                      {members.length === 0 ? (
                        <p className="p-5 text-[13px] text-text-muted italic">No students assigned to this squad yet.</p>
                      ) : (
                        <table className="w-full text-[13px]">
                          <thead>
                            <tr className="border-b border-border-light bg-page-bg">
                              <th className="text-left px-5 py-3 text-[11px] font-black text-text-muted uppercase tracking-wider">Student</th>
                              <th className="text-left px-5 py-3 text-[11px] font-black text-text-muted uppercase tracking-wider">Mentor (Faculty)</th>
                              <th className="text-left px-5 py-3 text-[11px] font-black text-text-muted uppercase tracking-wider">Team Leader</th>
                            </tr>
                          </thead>
                          <tbody>
                            {members.map(student => (
                              <tr key={student.id} className="border-b border-border-light last:border-0 hover:bg-page-bg transition-colors">
                                <td className="px-5 py-3">
                                  <div className="flex items-center gap-2">
                                    <div className="w-7 h-7 rounded-full bg-gradient-to-br from-primary-purple to-deep-violet flex items-center justify-center text-white text-[10px] font-black shrink-0">
                                      {student.name.charAt(0)}
                                    </div>
                                    <div>
                                      <p className="font-bold text-text-main">{student.name}</p>
                                      <p className="text-[11px] text-text-muted">{student.reg_no}</p>
                                    </div>
                                  </div>
                                </td>
                                <td className="px-5 py-3">
                                  <select
                                    value={student.mentor_id || ''}
                                    onChange={e => e.target.value && handleAssignMentor(student.id, e.target.value)}
                                    className="text-[12px] border border-border-light rounded-lg px-2 py-1.5 outline-none focus:border-primary-purple bg-white">
                                    <option value="">{student.mentor_name || 'Assign mentor'}</option>
                                    {faculty.map(f => (
                                      <option key={f.id} value={f.id}>{f.name}</option>
                                    ))}
                                  </select>
                                  {student.mentor_name && (
                                    <span className="ml-2 text-[11px] text-emerald-600 font-bold">✓ {student.mentor_name}</span>
                                  )}
                                </td>
                                <td className="px-5 py-3">
                                  <button
                                    onClick={() => handleSetLeader(team.id, team.team_leader_id === student.id ? null : student.id)}
                                    className={`flex items-center gap-1.5 text-[11px] font-bold px-3 py-1.5 rounded-full border transition-colors ${
                                      team.team_leader_id === student.id
                                        ? 'bg-amber-50 border-amber-200 text-amber-700'
                                        : 'border-border-light text-text-muted hover:border-amber-300'
                                    }`}>
                                    <Crown className="w-3 h-3" />
                                    {team.team_leader_id === student.id ? 'Leader' : 'Set Leader'}
                                  </button>
                                </td>
                              </tr>
                            ))}
                          </tbody>
                        </table>
                      )}
                    </div>
                  </motion.div>
                )}
              </AnimatePresence>
            </div>
          );
        })}
      </div>

      {/* Unassigned Students */}
      {unassigned.length > 0 && (
        <div className="bg-white border border-amber-200 rounded-2xl overflow-hidden">
          <div className="flex items-center gap-3 p-5 border-b border-amber-100 bg-amber-50">
            <AlertTriangle className="w-5 h-5 text-amber-600" />
            <div>
              <h3 className="text-[15px] font-bold text-text-main">Unassigned Students ({unassigned.length})</h3>
              <p className="text-[12px] text-amber-700">These students are not in any squad yet.</p>
            </div>
          </div>
          <div className="divide-y divide-border-light">
            {unassigned.map(student => (
              <div key={student.id} className="flex items-center justify-between px-5 py-3 gap-4">
                <div className="flex items-center gap-3">
                  <div className="w-7 h-7 rounded-full bg-gradient-to-br from-primary-purple to-deep-violet flex items-center justify-center text-white text-[10px] font-black">
                    {student.name.charAt(0)}
                  </div>
                  <div>
                    <p className="text-[13px] font-bold">{student.name}</p>
                    <p className="text-[11px] text-text-muted">{student.reg_no}</p>
                  </div>
                </div>
                <div className="flex items-center gap-3">
                  <select
                    defaultValue=""
                    onChange={e => e.target.value && handleAssignToTeam(student.id, e.target.value)}
                    className="text-[12px] border border-border-light rounded-lg px-2 py-1.5 outline-none focus:border-primary-purple bg-white">
                    <option value="">Assign to squad…</option>
                    {teams.map(t => (
                      <option key={t.id} value={t.id}>{t.team_name} ({studentsInTeam(t.id).length}/{t.target_size})</option>
                    ))}
                  </select>
                  <select
                    defaultValue=""
                    onChange={e => e.target.value && handleAssignMentor(student.id, e.target.value)}
                    className="text-[12px] border border-border-light rounded-lg px-2 py-1.5 outline-none focus:border-primary-purple bg-white">
                    <option value="">{student.mentor_name || 'Assign mentor…'}</option>
                    {faculty.map(f => <option key={f.id} value={f.id}>{f.name}</option>)}
                  </select>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Faculty Mentor Overview */}
      <div className="bg-white border border-border-light rounded-2xl p-6">
        <h3 className="text-[16px] font-bold mb-4 flex items-center gap-2">
          <BookOpen className="w-5 h-5 text-primary-purple" />
          Faculty Mentor Workload
        </h3>
        <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-3">
          {faculty.map(f => {
            const count = students.filter(s => s.mentor_id === f.id).length;
            return (
              <div key={f.id} className="bg-page-bg rounded-xl p-4">
                <div className="w-8 h-8 rounded-full bg-gradient-to-br from-primary-purple to-deep-violet flex items-center justify-center text-white text-[11px] font-black mb-2">
                  {f.name.charAt(0)}
                </div>
                <p className="text-[13px] font-bold text-text-main truncate">{f.name}</p>
                <p className="text-[11px] text-text-muted">{count} student{count !== 1 ? 's' : ''}</p>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}
