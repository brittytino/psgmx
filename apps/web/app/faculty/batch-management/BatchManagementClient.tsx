'use client';

import React from 'react';
import { LogIn } from 'lucide-react';
import { InitialsAvatar } from '@/components/basic/InitialsAvatar';

interface StudentRow { id: string; name: string; email: string; regNo: string; batchCode: string; createdAt: string }
interface BatchRow { id: string; code: string; status: string }

export default function BatchManagementClient({ initialStudents, batches }: { initialStudents: StudentRow[]; batches: BatchRow[] }) {
  const [filterBatch, setFilterBatch] = React.useState('all');
  const [error, setError] = React.useState('');

  const handleImpersonate = async (targetUserId: string) => {
    try {
      const res = await fetch('/api/super-admin/impersonate', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ targetUserId }),
      });
      const data = await res.json();
      if (res.ok) {
        window.location.assign(data.redirect || '/student');
      } else {
        setError(data.error || 'Impersonation failed');
      }
    } catch {
      setError('Impersonation failed due to an unexpected error.');
    }
  };

  const filtered = filterBatch === 'all' ? initialStudents : initialStudents.filter((s) => s.batchCode === filterBatch);

  return (
    <div className="space-y-4">
      {error && (
        <div className="p-3 bg-deep-violet/10 border border-deep-violet/20 rounded-xl text-[13px] font-semibold text-deep-violet">{error}</div>
      )}

      <div className="flex items-center gap-3">
        <span className="text-[12px] font-bold text-text-muted">Filter by batch:</span>
        <select value={filterBatch} onChange={(e) => setFilterBatch(e.target.value)} className="border border-border-light rounded-lg px-3 py-1.5 text-[12px] outline-none">
          <option value="all">All batches</option>
          {batches.map((b) => <option key={b.id} value={b.code}>{b.code} ({b.status})</option>)}
        </select>
      </div>

      <div className="bg-white rounded-[20px] border border-border-light overflow-hidden">
        <table className="w-full text-left border-collapse">
          <thead>
            <tr className="bg-page-bg border-b border-border-light">
              <th className="p-4 text-[12px] font-bold text-text-muted">Reg No.</th>
              <th className="p-4 text-[12px] font-bold text-text-muted">Name & Email</th>
              <th className="p-4 text-[12px] font-bold text-text-muted">Batch</th>
              <th className="p-4 text-[12px] font-bold text-text-muted text-right">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border-light">
            {filtered.map((s) => (
              <tr key={s.id} className="hover:bg-page-bg/50 transition-colors">
                <td className="p-4 font-mono text-[12px] text-primary-purple">{s.regNo}</td>
                <td className="p-4">
                  <div className="flex items-center gap-3">
                    <InitialsAvatar name={s.name} size={32} />
                    <div>
                      <div className="font-bold text-text-main text-[13px]">{s.name}</div>
                      <div className="text-[11px] text-text-muted">{s.email}</div>
                    </div>
                  </div>
                </td>
                <td className="p-4 text-[12px] font-bold text-text-muted">{s.batchCode}</td>
                <td className="p-4 text-right">
                  <button onClick={() => handleImpersonate(s.id)} className="inline-flex items-center gap-2 px-3 py-1.5 bg-page-bg text-primary-purple hover:bg-primary-purple/10 rounded-lg text-[12px] font-bold transition-colors">
                    <LogIn className="w-3.5 h-3.5" /> Log in as
                  </button>
                </td>
              </tr>
            ))}
            {filtered.length === 0 && (
              <tr><td colSpan={4} className="p-8 text-center text-text-muted text-[13px]">No students found.</td></tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
