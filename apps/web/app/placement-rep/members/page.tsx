'use client';

import React, { useState, useEffect, useMemo, useCallback } from 'react';
import { 
  Upload, Download, Search, ShieldCheck, MailPlus, 
  CheckCircle2, AlertTriangle, XCircle, FileText, Loader2, ArrowRight
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
  const [batchId, setBatchId] = useState('');
  const [query, setQuery] = useState('');
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState('');

  // 3-Column Preview Modal State per PRD Chapter 3.1
  const [showPreviewModal, setShowPreviewModal] = useState(false);
  const [previewData, setPreviewData] = useState<{
    create: ParsedStudent[];
    update: ParsedStudent[];
    reject: ParsedStudent[];
    rawList: ParsedStudent[];
  }>({ create: [], update: [], reject: [], rawList: [] });

  const load = useCallback(async () => {
    const me = await getCurrentProfile(supabase);
    if (!me?.batch_id) return;
    setBatchId(me.batch_id);

    const [{ data: roster }, { data: users }, { data: permissions }] = await Promise.all([
      supabase.from('whitelist').select('email,name,reg_no,personal_email,college_email,batch,team_id').eq('batch_id', me.batch_id).order('reg_no'),
      supabase.from('users').select('id,reg_no,team_uuid').eq('batch_id', me.batch_id).eq('role_label', 'Student'),
      supabase.from('user_permissions').select('user_id,permission_key'),
    ]);

    const usersByRegisterNumber = new Map((users ?? []).map((user) => [user.reg_no, user]));
    const permissionMap = new Map<string, { permission_key: string }[]>();
    for (const permission of permissions ?? []) {
      permissionMap.set(permission.user_id, [
        ...(permissionMap.get(permission.user_id) ?? []),
        { permission_key: permission.permission_key },
      ]);
    }

    setMembers((roster ?? []).map((entry) => {
      const registerNumber = entry.reg_no ?? 'Unassigned';
      const user = usersByRegisterNumber.get(registerNumber);
      return {
        id: user?.id ?? null,
        name: entry.name ?? registerNumber,
        reg_no: registerNumber,
        email: entry.email,
        personal_email: entry.personal_email,
        college_email: entry.college_email,
        section: entry.batch,
        team_uuid: user?.team_uuid ?? null,
        activated: Boolean(user),
        user_permissions: user ? permissionMap.get(user.id) ?? [] : [],
      };
    }));
  }, [supabase]);

  useEffect(() => {
    const timer = window.setTimeout(() => void load(), 0);
    return () => window.clearTimeout(timer);
  }, [load]);

  // Download CSV Import Template per PRD Chapter 3.1
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

  // Client-Side CSV Parser & 3-Column Conflict Analyzer
  const handleFileSelect = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file || !batchId) return;

    try {
      const text = await file.text();
      const rows = parseCsv(text);
      const existingRegNos = new Set(members.map(m => (m.reg_no || '').trim().toUpperCase()));

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
          toReject.push(item);
          rawList.push(item);
          continue;
        }

        // Email basic validation
        if (!personalEmail.includes('@')) {
          const item: ParsedStudent = {
            register_number: regNo,
            full_name: fullName,
            personal_email: personalEmail,
            validationStatus: 'reject',
            rejectReason: 'Invalid email address format.',
          };
          toReject.push(item);
          rawList.push(item);
          continue;
        }

        if (existingRegNos.has(regNo)) {
          const item: ParsedStudent = {
            register_number: regNo,
            full_name: fullName,
            personal_email: personalEmail,
            college_email: row.college_email || `${regNo.toLowerCase()}@psgtech.ac.in`,
            batch_year: row.batch_year || '2026',
            stage: row.stage || 'junior',
            phone: row.phone,
            github_username: row.github_username,
            leetcode_username: row.leetcode_username,
            validationStatus: 'update',
          };
          toUpdate.push(item);
          rawList.push(item);
        } else {
          const item: ParsedStudent = {
            register_number: regNo,
            full_name: fullName,
            personal_email: personalEmail,
            college_email: row.college_email || `${regNo.toLowerCase()}@psgtech.ac.in`,
            batch_year: row.batch_year || '2026',
            stage: row.stage || 'junior',
            phone: row.phone,
            github_username: row.github_username,
            leetcode_username: row.leetcode_username,
            validationStatus: 'create',
          };
          toCreate.push(item);
          rawList.push(item);
        }
      }

      setPreviewData({
        create: toCreate,
        update: toUpdate,
        reject: toReject,
        rawList,
      });
      setShowPreviewModal(true);
    } catch (err: any) {
      setMessage(`CSV Error: ${err.message || 'Failed to parse file'}`);
    }
    event.target.value = '';
  };

  // Commit valid students to DB
  const commitImport = async () => {
    setBusy(true);
    setShowPreviewModal(false);
    setMessage('Committing valid roster records...');

    const validStudents = [...previewData.create, ...previewData.update].map(s => ({
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
        body: JSON.stringify({ students: validStudents, batch_id: batchId }),
      });

      const result = await response.json();
      if (response.ok) {
        setMessage(`Roster successfully imported! ${result.created || validStudents.length} students processed.`);
        await load();
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
      m.email.toLowerCase().includes(query.toLowerCase())
  );

  return (
    <div className="max-w-7xl mx-auto space-y-6 pb-12">
      
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-black text-slate-900 tracking-tight">Roster & Access Management</h1>
          <p className="text-sm text-slate-500">
            Batch-scoped student roster. Bulk CSV onboarding is the exclusive student entry point.
          </p>
        </div>
        <div className="flex items-center gap-3">
          <button
            onClick={downloadTemplate}
            className="flex items-center gap-2 px-4 py-2 bg-slate-100 hover:bg-slate-200 text-slate-700 font-bold text-xs rounded-xl transition-colors"
          >
            <Download className="w-4 h-4" /> Download Template CSV
          </button>
          <label className="flex items-center gap-2 px-4 py-2 bg-brand-500 hover:bg-brand-600 text-white font-bold text-xs rounded-xl cursor-pointer shadow-sm transition-colors">
            <Upload className="w-4 h-4" /> Import Filled CSV
            <input type="file" accept=".csv" onChange={handleFileSelect} className="hidden" />
          </label>
        </div>
      </div>

      {message && (
        <div className="p-4 bg-violet-50 border border-violet-200 rounded-xl text-sm font-semibold text-violet-900 flex items-center justify-between">
          <span>{message}</span>
          <button onClick={() => setMessage('')} className="text-xs text-violet-500 hover:text-violet-700">Dismiss</button>
        </div>
      )}

      {/* Search & Stats */}
      <div className="flex items-center justify-between gap-4 bg-white p-4 rounded-xl border border-slate-200">
        <div className="relative flex-1 max-w-md">
          <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Search by register number, name, or email..."
            className="w-full pl-9 pr-4 py-2 text-sm border border-slate-200 rounded-lg outline-none focus:border-brand-500"
          />
        </div>
        <div className="text-xs font-bold text-slate-500 flex gap-4">
          <span>Total Rostered: <strong className="text-slate-900">{members.length}</strong></span>
          <span>Activated (Logged in): <strong className="text-emerald-600">{members.filter(m => m.activated).length}</strong></span>
        </div>
      </div>

      {/* Members Table */}
      <div className="bg-white rounded-2xl border border-slate-200 overflow-hidden shadow-sm">
        <table className="w-full text-left border-collapse">
          <thead>
            <tr className="bg-slate-50 border-b border-slate-200 text-xs font-bold text-slate-500 uppercase tracking-wider">
              <th className="p-4">Reg No</th>
              <th className="p-4">Name & Personal Email</th>
              <th className="p-4">College Email</th>
              <th className="p-4">Status</th>
              <th className="p-4 text-right">Capabilities</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100 text-sm">
            {filteredMembers.map((m) => (
              <tr key={m.reg_no} className="hover:bg-slate-50/50 transition-colors">
                <td className="p-4 font-mono font-bold text-brand-600">{m.reg_no}</td>
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
                      {m.user_permissions.map(p => p.permission_key).join(', ')}
                    </span>
                  ) : (
                    <span className="text-xs text-slate-400">Student</span>
                  )}
                </td>
              </tr>
            ))}
            {filteredMembers.length === 0 && (
              <tr>
                <td colSpan={5} className="p-8 text-center text-slate-400">
                  No rostered students found.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {/* 3-Column Preview Modal per PRD Chapter 3.1 */}
      {showPreviewModal && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white w-full max-w-4xl rounded-2xl shadow-2xl border border-slate-200 overflow-hidden flex flex-col max-h-[85vh]">
            
            <div className="p-6 border-b border-slate-200 flex items-center justify-between">
              <div>
                <h3 className="text-lg font-black text-slate-900">Roster Import Review</h3>
                <p className="text-xs text-slate-500">
                  Verify the parsed CSV records before committing to the database.
                </p>
              </div>
              <button onClick={() => setShowPreviewModal(false)} className="text-slate-400 hover:text-slate-600 text-sm font-bold">
                ✕ Cancel
              </button>
            </div>

            <div className="flex-1 overflow-y-auto p-6 grid grid-cols-1 md:grid-cols-3 gap-6 bg-slate-50">
              
              {/* Column 1: Will Create (Green) */}
              <div className="bg-white p-4 rounded-xl border border-emerald-200 shadow-sm space-y-3">
                <div className="flex items-center justify-between border-b border-emerald-100 pb-2">
                  <span className="flex items-center gap-1.5 text-xs font-bold text-emerald-700 uppercase tracking-wider">
                    <CheckCircle2 className="w-4 h-4" /> Will Create ({previewData.create.length})
                  </span>
                </div>
                <div className="space-y-2 max-h-72 overflow-y-auto pr-1">
                  {previewData.create.map((s) => (
                    <div key={s.register_number} className="bg-emerald-50/50 p-2.5 rounded-lg border border-emerald-100 text-xs">
                      <div className="font-bold text-slate-800">{s.register_number} · {s.full_name}</div>
                      <div className="text-slate-500 font-mono text-[11px] truncate">{s.personal_email}</div>
                    </div>
                  ))}
                  {previewData.create.length === 0 && (
                    <div className="text-center py-6 text-slate-400 text-xs">No new records</div>
                  )}
                </div>
              </div>

              {/* Column 2: Will Update (Amber) */}
              <div className="bg-white p-4 rounded-xl border border-amber-200 shadow-sm space-y-3">
                <div className="flex items-center justify-between border-b border-amber-100 pb-2">
                  <span className="flex items-center gap-1.5 text-xs font-bold text-amber-700 uppercase tracking-wider">
                    <AlertTriangle className="w-4 h-4" /> Will Update ({previewData.update.length})
                  </span>
                </div>
                <div className="space-y-2 max-h-72 overflow-y-auto pr-1">
                  {previewData.update.map((s) => (
                    <div key={s.register_number} className="bg-amber-50/50 p-2.5 rounded-lg border border-amber-100 text-xs">
                      <div className="font-bold text-slate-800">{s.register_number} · {s.full_name}</div>
                      <div className="text-slate-500 font-mono text-[11px] truncate">{s.personal_email}</div>
                    </div>
                  ))}
                  {previewData.update.length === 0 && (
                    <div className="text-center py-6 text-slate-400 text-xs">No updates</div>
                  )}
                </div>
              </div>

              {/* Column 3: Will Reject (Red) */}
              <div className="bg-white p-4 rounded-xl border border-rose-200 shadow-sm space-y-3">
                <div className="flex items-center justify-between border-b border-rose-100 pb-2">
                  <span className="flex items-center gap-1.5 text-xs font-bold text-rose-700 uppercase tracking-wider">
                    <XCircle className="w-4 h-4" /> Will Reject ({previewData.reject.length})
                  </span>
                </div>
                <div className="space-y-2 max-h-72 overflow-y-auto pr-1">
                  {previewData.reject.map((s, idx) => (
                    <div key={idx} className="bg-rose-50/50 p-2.5 rounded-lg border border-rose-100 text-xs">
                      <div className="font-bold text-rose-900">{s.register_number} · {s.full_name}</div>
                      <div className="text-rose-600 text-[11px] mt-0.5">{s.rejectReason}</div>
                    </div>
                  ))}
                  {previewData.reject.length === 0 && (
                    <div className="text-center py-6 text-slate-400 text-xs">No rejections</div>
                  )}
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
                  className="px-5 py-2 bg-brand-500 hover:bg-brand-600 disabled:opacity-50 text-white font-bold text-xs rounded-xl shadow-sm flex items-center gap-2"
                >
                  {busy ? <Loader2 className="w-4 h-4 animate-spin" /> : null}
                  Confirm & Commit Roster
                </button>
              </div>
            </div>

          </div>
        </div>
      )}

    </div>
  );
}
