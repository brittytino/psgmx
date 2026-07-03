'use client';

import React from 'react';
import { LogIn } from 'lucide-react';

export default function StudentsClientPage({ initialStudents }: { initialStudents: any[] }) {

  const handleImpersonate = async (targetUserId: string) => {
    try {
      const res = await fetch('/api/super-admin/impersonate', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ targetUserId })
      });
      const data = await res.json();
      if (res.ok) {
        window.location.assign(data.redirect);
      } else {
        alert(data.error);
      }
    } catch (err) {
      console.error(err);
      alert('Impersonation failed');
    }
  };

  return (
    <div>
      <div className="bg-black/20 border border-border rounded-xl overflow-hidden">
        <table className="w-full text-left border-collapse">
          <thead>
            <tr className="bg-white/5 border-b border-border">
              <th className="p-4 text-sm font-bold text-text-muted">Token</th>
              <th className="p-4 text-sm font-bold text-text-muted">Name & Email</th>
              <th className="p-4 text-sm font-bold text-text-muted">Type</th>
              <th className="p-4 text-sm font-bold text-text-muted">Status</th>
              <th className="p-4 text-sm font-bold text-text-muted text-right">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border">
            {initialStudents.map(s => (
              <tr key={s._id} className="hover:bg-white/5 transition-colors">
                <td className="p-4 font-mono text-sm text-electric-blue">{s.token}</td>
                <td className="p-4">
                  <div className="font-bold text-white">{s.fullName || 'No Name'}</div>
                  <div className="text-sm text-text-muted">{s.email}</div>
                </td>
                <td className="p-4 uppercase text-xs font-bold text-text-muted">{s.accountType}</td>
                <td className="p-4">
                  <span className="px-2 py-1 bg-green-500/10 text-green-400 text-xs rounded font-bold uppercase">{s.status}</span>
                </td>
                <td className="p-4 text-right">
                  <button onClick={() => handleImpersonate(s._id)} className="inline-flex items-center gap-2 px-3 py-1.5 bg-purple-500/20 text-purple-400 hover:bg-purple-500/30 rounded-lg text-sm font-bold transition-colors">
                    <LogIn className="w-4 h-4" /> Login As
                  </button>
                </td>
              </tr>
            ))}
            {initialStudents.length === 0 && (
              <tr><td colSpan={5} className="p-8 text-center text-text-muted">No students found.</td></tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
