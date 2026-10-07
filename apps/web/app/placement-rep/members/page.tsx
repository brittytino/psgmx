'use client';

import React, { useState, useEffect, useMemo, useCallback } from 'react';
import {
  Upload, Download, Search, CheckCircle2, AlertTriangle,
  XCircle, Loader2, Users, Filter
} from 'lucide-react';
import { createClient } from '@/lib/supabase/client';
import { getCurrentProfile } from '@/lib/current-profile';
import { parseCsv } from '@/lib/csv';

interface Member {
  id: string | null;
  name: string;
  reg_no: string;
  email: string;
  personal_email: string | null;
  college_email: string | null;
  section: string | null;
  team_uuid: string | null;
  activated: boolean;
  user_permissions: { permission_key: string }[];
  batch_code?: string;
  batch_id?: string;
}

interface BatchInfo {
  id: string;
  batch_code: string;
}

interface ParsedStudent {
  register_number: string;
  full_name: string;
  personal_email: string;
  college_email?: string;
  batch_year?: string;
  stage?: string;
  phone?: string;
  github_username?: string;
  leetcode_username?: string;
  validationStatus: 'create' | 'update' | 'reject';
  rejectReason?: string;
}

export default function MembersPage() {
  const supabase = useMemo(() => createClient(), []);
  const [members, setMembers] = useState<Member[]>([]);
  const [batches, setBatches] = useState<BatchInfo[]>([]);
  const [myBatchId, setMyBatchId] = useState('');
  const [selectedBatchId, setSelectedBatchId] = useState('');
  const [query, setQuery] = useState('');
  const [busy, setBusy] = useState(false);
  const [loading, setLoading] = useState(true);
  const [message, setMessage] = useState('');

  const [showPreviewModal, setShowPreviewModal] = useState(false);
  const [previewData, setPreviewData] = useState<{
    create: ParsedStudent[];
    update: ParsedStudent[];
    reject: ParsedStudent[];
    rawList: ParsedStudent[];
  }>({ create: [], update: [], reject: [], rawList: [] });

  // Load batches list (25MX and 26MX)
  const loadBatches = useCallback(async () => {
    const { data } = await supabase
      .from('batches')
      .select('id,batch_code')
      .order('start_year', { ascending: false });
    return (data ?? []) as BatchInfo[];
  }, [supabase]);

  const loadMembers = useCallback(async (batchId: string, currentBatches?: BatchInfo[]) => {
    if (!batchId) return;
    setLoading(true);
    try {
      const activeBatches = currentBatches || batches;
      const batchObj = activeBatches.find((b) => b.id === batchId);
      const batchCode = batchObj?.batch_code || '';

      const [rosterRes, usersRes, permissionsRes] = await Promise.all([
        batchCode
          ? supabase
              .from('whitelist')
              .select('email,name,reg_no,personal_email,college_email,batch,team_id')
              .or(`batch_id.eq.${batchId},reg_no.ilike.${batchCode}%`)
              .order('reg_no')
          : supabase
              .from('whitelist')
              .select('email,name,reg_no,personal_email,college_email,batch,team_id')
              .eq('batch_id', batchId)
              .order('reg_no'),
        batchCode
          ? supabase
              .from('users')
              .select('id,name,reg_no,email,personal_email,college_email,batch,team_uuid')
              .or(`batch_id.eq.${batchId},reg_no.ilike.${batchCode}%`)
              .order('reg_no')
          : supabase
              .from('users')
              .select('id,name,reg_no,email,personal_email,college_email,batch,team_uuid')
              .eq('batch_id', batchId)
              .order('reg_no'),
        supabase.from('user_permissions').select('user_id,permission_key'),
      ]);

      const roster = rosterRes.data ?? [];
      const users = usersRes.data ?? [];
      const permissions = permissionsRes.data ?? [];

      const usersByRegNo = new Map(users.map((u) => [(u.reg_no || '').trim().toUpperCase(), u]));
      const usersByEmail = new Map(users.map((u) => [(u.email || '').trim().toLowerCase(), u]));

      const permissionMap = new Map<string, { permission_key: string }[]>();
      for (const permission of permissions) {
        permissionMap.set(permission.user_id, [
          ...(permissionMap.get(permission.user_id) ?? []),
          { permission_key: permission.permission_key },
        ]);
      }

      const memberList: Member[] = [];
      const seenRegNos = new Set<string>();

      // 1. Process whitelist entries
      for (const entry of roster) {
        const regNo = (entry.reg_no ?? 'Unassigned').trim();
        const regKey = regNo.toUpperCase();
        seenRegNos.add(regKey);

        const user = usersByRegNo.get(regKey) || (entry.email ? usersByEmail.get(entry.email.toLowerCase()) : undefined);

        memberList.push({
          id: user?.id ?? null,
          name: entry.name || user?.name || regNo,
          reg_no: regNo,
          email: entry.email || user?.email || '',
          personal_email: entry.personal_email || user?.personal_email || null,
          college_email: entry.college_email || user?.college_email || null,
          section: entry.batch || user?.batch || null,
          team_uuid: user?.team_uuid ?? null,
          activated: Boolean(user),
          user_permissions: user ? permissionMap.get(user.id) ?? [] : [],
          batch_id: batchId,
        });
      }

      // 2. Include any users that were in the users table but not in whitelist
      for (const u of users) {
        const regKey = (u.reg_no || '').trim().toUpperCase();
        if (regKey && !seenRegNos.has(regKey)) {
          seenRegNos.add(regKey);
          memberList.push({
            id: u.id,
            name: u.name || u.reg_no,
            reg_no: u.reg_no || 'Unassigned',
            email: u.email,
            personal_email: u.personal_email,
            college_email: u.college_email,
            section: u.batch,
            team_uuid: u.team_uuid,
            activated: true,
            user_permissions: permissionMap.get(u.id) ?? [],
            batch_id: batchId,
          });
        }
      }

      setMembers(memberList);
    } catch (e) {
      console.warn('Members load error:', e);
    } finally {
      setLoading(false);
    }
  }, [supabase, batches]);

  const load = useCallback(async () => {
    const me = await getCurrentProfile(supabase);
    if (!me?.batch_id) { setLoading(false); return; }
    setMyBatchId(me.batch_id);

    const batchList = await loadBatches();
    setBatches(batchList);

    // Default to own batch
    const defaultBatch = me.batch_id;
    setSelectedBatchId(defaultBatch);
    await loadMembers(defaultBatch, batchList);
  }, [supabase, loadBatches, loadMembers]);

  useEffect(() => {
    const timer = window.setTimeout(() => void load(), 0);
    return () => window.clearTimeout(timer);
  }, [load]);

  // Switch batch tab
  const handleBatchSwitch = useCallback(async (batchId: string) => {
    setSelectedBatchId(batchId);
    setQuery('');
    await loadMembers(batchId, batches);
  }, [loadMembers, batches]);

  const downloadTemplate = () => {
    const headers = 'register_number,full_name,personal_email,college_email,batch_year,stage,phone,github_username,leetcode_username';
    const sample = '25MX101,Aarav Kumar,aarav@gmail.com,25mx101@psgtech.ac.in,2026,junior,9876543210,aarav_dev,aarav_lc';
    const csvContent = `data:text/csv;charset=utf-8,${headers}\n${sample}\n`;
    const encodedUri = encodeURI(csvContent);
    const link = document.createElement('a');
    link.setAttribute('href', encodedUri);
    link.setAttribute('download', 'psgmx_student_roster_template.csv');
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  const handleFileSelect = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file || !selectedBatchId) return;

    try {
      const text = await file.text();
      const rows = parseCsv(text);
      const existingRegNos = new Set(members.map((m) => (m.reg_no || '').trim().toUpperCase()));

      const toCreate: ParsedStudent[] = [];
      const toUpdate: ParsedStudent[] = [];
      const toReject: ParsedStudent[] = [];
      const rawList: ParsedStudent[] = [];

      for (const row of rows) {
        const regNo = (row.register_number || row.reg_no || '').trim().toUpperCase();
        const fullName = (row.full_name || row.name || '').trim();
        const personalEmail = (row.personal_email || row.email || '').trim().toLowerCase();

        if (!regNo || !fullName || !personalEmail) {
          const item: ParsedStudent = {
            register_number: regNo || 'MISSING',
            full_name: fullName || 'MISSING',
            personal_email: personalEmail || 'MISSING',
            validationStatus: 'reject',
            rejectReason: 'Missing register number, full name, or email.',
          };
          toReject.push(item); rawList.push(item);
          continue;
        }

        if (!personalEmail.includes('@')) {
          const item: ParsedStudent = {
            register_number: regNo, full_name: fullName, personal_email: personalEmail,
            validationStatus: 'reject', rejectReason: 'Invalid email format.',
          };
          toReject.push(item); rawList.push(item);
          continue;
        }

        const item: ParsedStudent = {
          register_number: regNo, full_name: fullName, personal_email: personalEmail,
          college_email: row.college_email || `${regNo.toLowerCase()}@psgtech.ac.in`,
          batch_year: row.batch_year || '2026', stage: row.stage || 'junior',
          phone: row.phone, github_username: row.github_username, leetcode_username: row.leetcode_username,
          validationStatus: existingRegNos.has(regNo) ? 'update' : 'create',
        };

        if (item.validationStatus === 'update') toUpdate.push(item);
        else toCreate.push(item);
        rawList.push(item);
      }

      setPreviewData({ create: toCreate, update: toUpdate, reject: toReject, rawList });
      setShowPreviewModal(true);
    } catch (err: any) {
      setMessage(`CSV Error: ${err.message || 'Failed to parse file'}`);
    }
    event.target.value = '';
  };

  const commitImport = async () => {
    setBusy(true);
    setShowPreviewModal(false);
    setMessage('Committing valid roster records…');

    const validStudents = [...previewData.create, ...previewData.update].map((s) => ({
      reg_no: s.register_number,
      name: s.full_name,
      personal_email: s.personal_email,
      college_email: s.college_email,
      section: 'A',
      phone: s.phone,
      github_username: s.github_username,
      leetcode_username: s.leetcode_username,
    }));

    try {
      const response = await fetch('/api/faculty/batch-import', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ students: validStudents, batch_id: selectedBatchId }),
      });
      const result = await response.json();
      if (response.ok) {
        setMessage(`Roster imported! ${result.created || validStudents.length} students processed.`);
        await loadMembers(selectedBatchId);
      } else {
        setMessage(`Import failed: ${result.error || 'Unknown error'}`);
      }
    } catch (err: any) {
      setMessage(`Server error: ${err.message}`);
    }
    setBusy(false);
  };

  const filteredMembers = members.filter(
    (m) =>
      m.name.toLowerCase().includes(query.toLowerCase()) ||
      m.reg_no.toLowerCase().includes(query.toLowerCase()) ||
      (m.email || '').toLowerCase().includes(query.toLowerCase())
  );

  const selectedBatch = batches.find((b) => b.id === selectedBatchId);

  return (
    <div className="max-w-7xl mx-auto space-y-6 pb-12">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-black text-slate-900 tracking-tight">Roster &amp; Access Management</h1>
          <p className="text-sm text-slate-500">
            Batch-scoped student roster for all active batches. Bulk CSV onboarding is the exclusive entry point.
          </p>
        </div>
        <div className="flex items-center gap-3">
          <button
            onClick={downloadTemplate}
            className="flex items-center gap-2 px-4 py-2 bg-slate-100 hover:bg-slate-200 text-slate-700 font-bold text-xs rounded-xl transition-colors"
          >
            <Download className="w-4 h-4" /> Template CSV
          </button>
          <label className="flex items-center gap-2 px-4 py-2 bg-violet-600 hover:bg-violet-700 text-white font-bold text-xs rounded-xl cursor-pointer shadow-sm transition-colors">
            <Upload className="w-4 h-4" /> Import CSV
            <input type="file" accept=".csv" onChange={handleFileSelect} className="hidden" />
          </label>
        </div>
      </div>

      {message && (
        <div className="p-4 bg-violet-50 border border-violet-200 rounded-xl text-sm font-semibold text-violet-900 flex items-center justify-between">
          <span>{message}</span>
          <button onClick={() => setMessage('')} className="text-xs text-violet-500 hover:text-violet-700 ml-4">Dismiss</button>
        </div>
      )}

      {/* Batch Tabs */}
      {batches.length > 0 && (
        <div className="flex gap-2 flex-wrap">
          {batches.map((batch) => (
            <button
              key={batch.id}
              onClick={() => handleBatchSwitch(batch.id)}
              className={`flex items-center gap-2 px-4 py-2 rounded-xl text-sm font-bold border transition-all ${
                selectedBatchId === batch.id
                  ? 'bg-violet-600 text-white border-violet-600 shadow-sm'
                  : 'bg-white text-slate-600 border-slate-200 hover:border-violet-300 hover:text-violet-700'
              }`}
            >
              <Users className="w-4 h-4" />
              {batch.batch_code}
              {batch.id === myBatchId && (
                <span className="text-[10px] font-black px-1.5 py-0.5 rounded-full bg-white/20 text-white border border-white/30">
                  MINE
                </span>
              )}
            </button>
          ))}
        </div>
      )}

      {/* Search & Stats */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 bg-white p-4 rounded-xl border border-slate-200">
        <div className="relative flex-1 max-w-md">
          <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Search by register number, name, or email…"
            className="w-full pl-9 pr-4 py-2 text-sm border border-slate-200 rounded-lg outline-none focus:border-violet-400"
          />
        </div>
        <div className="text-xs font-bold text-slate-500 flex gap-4 flex-wrap">
          <span>
            Batch: <strong className="text-slate-900">{selectedBatch?.batch_code ?? '—'}</strong>
          </span>
          <span>
            Total Rostered: <strong className="text-slate-900">{members.length}</strong>
          </span>
          <span>
            Activated: <strong className="text-emerald-600">{members.filter((m) => m.activated).length}</strong>
          </span>
        </div>
      </div>

      {/* Members Table */}
      <div className="bg-white rounded-2xl border border-slate-200 overflow-hidden shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse min-w-[640px]">
            <thead>
              <tr className="bg-slate-50 border-b border-slate-200 text-xs font-bold text-slate-500 uppercase tracking-wider">
                <th className="p-4">Reg No</th>
                <th className="p-4">Name &amp; Email</th>
                <th className="p-4">College Email</th>
                <th className="p-4">Status</th>
                <th className="p-4 text-right">Capabilities</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 text-sm">
              {loading ? (
                <tr>
                  <td colSpan={5} className="p-8 text-center">
                    <Loader2 className="w-5 h-5 animate-spin text-violet-500 mx-auto" />
                  </td>
                </tr>
              ) : filteredMembers.length === 0 ? (
                <tr>
                  <td colSpan={5} className="p-8 text-center text-slate-400">
                    {query ? 'No students match your search.' : 'No rostered students found for this batch.'}
                  </td>
                </tr>
              ) : (
                filteredMembers.map((m) => (
                  <tr key={m.reg_no} className="hover:bg-slate-50/50 transition-colors">
                    <td className="p-4 font-mono font-bold text-violet-600">{m.reg_no}</td>
                    <td className="p-4">
                      <div className="font-bold text-slate-900">{m.name}</div>
                      <div className="text-xs text-slate-500">{m.personal_email || m.email}</div>
                    </td>
                    <td className="p-4 text-slate-600 font-mono text-xs">{m.college_email || '—'}</td>
                    <td className="p-4">
                      <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-bold ${
                        m.activated ? 'bg-emerald-50 text-emerald-700' : 'bg-slate-100 text-slate-600'
                      }`}>
                        {m.activated ? <CheckCircle2 className="w-3.5 h-3.5" /> : null}
                        {m.activated ? 'Activated' : 'Rostered'}
                      </span>
                    </td>
                    <td className="p-4 text-right">
                      {m.user_permissions.length > 0 ? (
                        <span className="text-xs font-bold px-2 py-0.5 bg-violet-50 text-violet-700 rounded border border-violet-200">
                          {m.user_permissions.map((p) => p.permission_key).join(', ')}
                        </span>
                      ) : (
                        <span className="text-xs text-slate-400">Student</span>
                      )}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* 3-Column Preview Modal */}
      {showPreviewModal && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white w-full max-w-4xl rounded-2xl shadow-2xl border border-slate-200 overflow-hidden flex flex-col max-h-[90vh]">
            <div className="p-6 border-b border-slate-200 flex items-center justify-between">
              <div>
                <h3 className="text-lg font-black text-slate-900">Roster Import Review</h3>
                <p className="text-xs text-slate-500">Verify parsed records before committing to the database.</p>
              </div>
              <button onClick={() => setShowPreviewModal(false)} className="text-slate-400 hover:text-slate-600 text-sm font-bold px-3 py-1">✕</button>
            </div>

            <div className="flex-1 overflow-y-auto p-6 grid grid-cols-1 md:grid-cols-3 gap-6 bg-slate-50">
              {/* Will Create */}
              <div className="bg-white p-4 rounded-xl border border-emerald-200 shadow-sm space-y-3">
                <div className="flex items-center gap-1.5 border-b border-emerald-100 pb-2">
                  <CheckCircle2 className="w-4 h-4 text-emerald-600" />
                  <span className="text-xs font-bold text-emerald-700 uppercase tracking-wider">Will Create ({previewData.create.length})</span>
                </div>
                <div className="space-y-2 max-h-72 overflow-y-auto pr-1">
                  {previewData.create.map((s) => (
                    <div key={s.register_number} className="bg-emerald-50/50 p-2.5 rounded-lg border border-emerald-100 text-xs">
                      <div className="font-bold text-slate-800">{s.register_number} · {s.full_name}</div>
                      <div className="text-slate-500 font-mono text-[11px] truncate">{s.personal_email}</div>
                    </div>
                  ))}
                  {previewData.create.length === 0 && <div className="text-center py-6 text-slate-400 text-xs">No new records</div>}
                </div>
              </div>

              {/* Will Update */}
              <div className="bg-white p-4 rounded-xl border border-amber-200 shadow-sm space-y-3">
                <div className="flex items-center gap-1.5 border-b border-amber-100 pb-2">
                  <AlertTriangle className="w-4 h-4 text-amber-600" />
                  <span className="text-xs font-bold text-amber-700 uppercase tracking-wider">Will Update ({previewData.update.length})</span>
                </div>
                <div className="space-y-2 max-h-72 overflow-y-auto pr-1">
                  {previewData.update.map((s) => (
                    <div key={s.register_number} className="bg-amber-50/50 p-2.5 rounded-lg border border-amber-100 text-xs">
                      <div className="font-bold text-slate-800">{s.register_number} · {s.full_name}</div>
                      <div className="text-slate-500 font-mono text-[11px] truncate">{s.personal_email}</div>
                    </div>
                  ))}
                  {previewData.update.length === 0 && <div className="text-center py-6 text-slate-400 text-xs">No updates</div>}
                </div>
              </div>

              {/* Will Reject */}
              <div className="bg-white p-4 rounded-xl border border-rose-200 shadow-sm space-y-3">
                <div className="flex items-center gap-1.5 border-b border-rose-100 pb-2">
                  <XCircle className="w-4 h-4 text-rose-600" />
                  <span className="text-xs font-bold text-rose-700 uppercase tracking-wider">Will Reject ({previewData.reject.length})</span>
                </div>
                <div className="space-y-2 max-h-72 overflow-y-auto pr-1">
                  {previewData.reject.map((s, idx) => (
                    <div key={idx} className="bg-rose-50/50 p-2.5 rounded-lg border border-rose-100 text-xs">
                      <div className="font-bold text-rose-900">{s.register_number} · {s.full_name}</div>
                      <div className="text-rose-600 text-[11px] mt-0.5">{s.rejectReason}</div>
                    </div>
                  ))}
                  {previewData.reject.length === 0 && <div className="text-center py-6 text-slate-400 text-xs">No rejections</div>}
                </div>
              </div>
            </div>

            <div className="p-4 bg-white border-t border-slate-200 flex items-center justify-between">
              <span className="text-xs text-slate-500">
                {previewData.create.length + previewData.update.length} valid students will be rostered.
              </span>
              <div className="flex gap-3">
                <button
                  onClick={() => setShowPreviewModal(false)}
                  className="px-4 py-2 border border-slate-300 hover:bg-slate-50 text-slate-700 font-bold text-xs rounded-xl"
                >
                  Cancel
                </button>
                <button
                  onClick={commitImport}
                  disabled={previewData.create.length + previewData.update.length === 0 || busy}
                  className="px-5 py-2 bg-violet-600 hover:bg-violet-700 disabled:opacity-50 text-white font-bold text-xs rounded-xl shadow-sm flex items-center gap-2"
                >
                  {busy ? <Loader2 className="w-4 h-4 animate-spin" /> : null}
                  Confirm &amp; Commit Roster
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
