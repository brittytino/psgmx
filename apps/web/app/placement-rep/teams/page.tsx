'use client';

import React from 'react';
import { motion } from 'framer-motion';
import { Plus, Users, X, UserCheck, WandSparkles, GraduationCap } from 'lucide-react';
import { createClient } from '@/lib/supabase/client';
import { getCurrentProfile } from '@/lib/current-profile';

interface StudentRow { id: string; name: string; reg_no: string; team_uuid: string | null }
interface TeamRow { id: string; team_name: string; team_code: string; target_size: number; team_leader_id: string | null }
interface FacultyRow { id: string; name: string; email: string }
interface MentorAssignment { student_id: string; mentor_id: string }

export default function TeamManagementPage() {
  const [batchId, setBatchId] = React.useState<string | null>(null);
  const [teams, setTeams] = React.useState<TeamRow[]>([]);
  const [students, setStudents] = React.useState<StudentRow[]>([]);
  const [loading, setLoading] = React.useState(true);
  const [showCreate, setShowCreate] = React.useState(false);
  const [newTeamName, setNewTeamName] = React.useState('');
  const [newTeamSize, setNewTeamSize] = React.useState(5);
  const [saving, setSaving] = React.useState(false);
  const [faculty, setFaculty] = React.useState<FacultyRow[]>([]);
  const [mentorAssignments, setMentorAssignments] = React.useState<MentorAssignment[]>([]);
  const [message, setMessage] = React.useState('');
  const [error, setError] = React.useState('');

  const supabase = React.useMemo(() => createClient(), []);

  const load = React.useCallback(async () => {
    const me = await getCurrentProfile(supabase);
    if (!me?.batch_id) { setLoading(false); return; }
    setBatchId(me.batch_id);

    const [{ data: teamRows }, { data: studentRows }, { data: facultyRows }, { data: mentorRows }] = await Promise.all([
      supabase.from('teams').select('id, team_name, team_code, target_size, team_leader_id').eq('batch_id', me.batch_id).order('team_name'),
      supabase.from('users').select('id, name, reg_no, team_uuid').eq('batch_id', me.batch_id).eq('role_label', 'Student').order('reg_no'),
      supabase.from('users').select('id,name,email').in('role_label', ['Faculty', 'HOD']).order('name'),
      (supabase as any).from('mentor_assignments').select('student_id,mentor_id').eq('batch_id', me.batch_id).eq('active', true),
    ]);

    setTeams(teamRows || []);
    setStudents(studentRows || []);
    setFaculty(facultyRows || []);
    setMentorAssignments(mentorRows || []);
    setLoading(false);
  }, [supabase]);

  React.useEffect(() => { load(); }, [load]);

  const handleCreateTeam = async () => {
    if (!newTeamName.trim() || !batchId) return;
    setSaving(true);
    try {
      const usedCodes = new Set(teams.map((team) => team.team_code));
      let sequence = 1;
      while (usedCodes.has(`T${String(sequence).padStart(2, '0')}`)) sequence += 1;
      const nextCode = `T${String(sequence).padStart(2, '0')}`;
      await supabase.from('teams').insert({ batch_id: batchId, team_name: newTeamName.trim(), team_code: nextCode, target_size: newTeamSize });
      setNewTeamName('');
      setNewTeamSize(5);
      setShowCreate(false);
      await load();
    } finally {
      setSaving(false);
    }
  };

  const handleAssign = async (studentId: string, teamId: string | null) => {
    if (!teamId) return;
    const { error } = await supabase.rpc('assign_team_member', { p_user_id: studentId, p_team_id: teamId });
    if (!error) setStudents((prev) => prev.map((s) => (s.id === studentId ? { ...s, team_uuid: teamId } : s)));
  };

  const autoAssign = async () => {
    setSaving(true); setError(''); setMessage('');
    const { data, error: assignError } = await (supabase as any).rpc('auto_assign_unassigned_squads', { p_target_size: newTeamSize });
    if (assignError) setError(assignError.message);
    else setMessage(`${data?.assigned ?? 0} students assigned across balanced squads. Individual readiness values were not exposed.`);
    await load(); setSaving(false);
  };

  const assignMentor = async (studentId: string, mentorId: string) => {
    if (!mentorId) return;
    setError(''); setMessage('');
    const { error: mentorError } = await (supabase as any).rpc('assign_student_mentor', {
      p_student_id: studentId,
      p_mentor_id: mentorId,
      p_focus_areas: [],
    });
    if (mentorError) setError(mentorError.message);
    else {
      setMessage('Faculty mentor assigned and audit logged.');
      await load();
    }
  };

  const handleSetLeader = async (teamId: string, studentId: string) => {
    const { error } = await supabase.rpc('set_team_leader', { p_team_id: teamId, p_user_id: studentId });
    if (!error) setTeams((prev) => prev.map((t) => (t.id === teamId ? { ...t, team_leader_id: studentId } : t)));
  };

  if (loading) {
    return <div className="space-y-4 animate-pulse">{[0, 1].map((i) => <div key={i} className="h-40 bg-white border border-border-light rounded-2xl" />)}</div>;
  }

  return (
    <div className="space-y-8 max-w-6xl">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <h1 className="text-[24px] font-black text-text-main">Team Management</h1>
        <div className="flex flex-wrap gap-2"><button onClick={autoAssign} disabled={saving} className="flex items-center gap-2 rounded-xl border border-primary-purple px-4 py-2.5 text-[13px] font-bold text-primary-purple disabled:opacity-50"><WandSparkles className="h-4 w-4"/>Auto-build squads</button><button
          onClick={() => setShowCreate(true)}
          className="flex items-center gap-2 px-5 py-2.5 bg-primary-purple text-white rounded-xl text-[13px] font-bold hover:bg-deep-violet transition-colors"
        >
          <Plus className="w-4 h-4" /> New Team
        </button></div>
      </div>
      {error && <div role="alert" className="rounded-xl border border-red-200 bg-red-50 p-4 text-sm font-bold text-red-700">{error}</div>}
      {message && <div className="rounded-xl border border-emerald-200 bg-emerald-50 p-4 text-sm font-bold text-emerald-800">{message}</div>}

      {showCreate && (
        <motion.div initial={{ opacity: 0, y: -10 }} animate={{ opacity: 1, y: 0 }} className="bg-white rounded-2xl border border-border-light p-6 flex flex-col sm:flex-row gap-4 items-end">
          <div className="flex-1">
            <label className="text-[12px] font-bold text-text-muted block mb-1.5">Team Name</label>
            <input value={newTeamName} onChange={(e) => setNewTeamName(e.target.value)} placeholder="e.g. Team Alpha" className="w-full border border-border-light rounded-lg px-3 py-2 text-[14px] outline-none focus:border-primary-purple" />
          </div>
          <div>
            <label className="text-[12px] font-bold text-text-muted block mb-1.5">Target Size</label>
            <input type="number" min={3} max={12} value={newTeamSize} onChange={(e) => setNewTeamSize(Number(e.target.value))} className="w-24 border border-border-light rounded-lg px-3 py-2 text-[14px] outline-none focus:border-primary-purple" />
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
          const members = students.filter((s) => s.team_uuid === team.id);
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
          {students.filter((s) => !s.team_uuid).length === 0 && <p className="text-[13px] text-text-muted">Every student is assigned to a team.</p>}
          {students.filter((s) => !s.team_uuid).map((s) => (
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

      <div className="rounded-2xl border border-border-light bg-white p-6">
        <div className="mb-4 flex items-start gap-3"><GraduationCap className="mt-0.5 h-5 w-5 text-primary-purple"/><div><h3 className="text-[15px] font-bold text-text-main">Faculty mentor assignment</h3><p className="mt-1 text-xs text-text-muted">PR assigns the relationship for this batch. Readiness details and private mentoring conversations remain visible only to the student and faculty.</p></div></div>
        <div className="grid gap-2 lg:grid-cols-2">
          {students.map((student) => {
            const assignment = mentorAssignments.find((item) => item.student_id === student.id);
            return <div key={student.id} className="flex items-center justify-between gap-3 rounded-xl bg-page-bg p-3"><div className="min-w-0"><p className="truncate text-sm font-bold text-text-main">{student.name}</p><p className="text-[11px] text-text-muted">{student.reg_no}</p></div><select value={assignment?.mentor_id || ''} onChange={(event) => void assignMentor(student.id, event.target.value)} className="max-w-[210px] rounded-lg border border-border-light bg-white px-2 py-2 text-xs"><option value="">Choose mentor…</option>{faculty.map((member) => <option key={member.id} value={member.id}>{member.name}</option>)}</select></div>;
          })}
        </div>
      </div>
    </div>
  );
}
