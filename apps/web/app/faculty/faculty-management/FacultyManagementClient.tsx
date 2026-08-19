'use client';

import React from 'react';
import { LogIn } from 'lucide-react';
import { InitialsAvatar } from '@/components/basic/InitialsAvatar';

interface FacultyRow { id: string; name: string; email: string; roleLabel: string; createdAt: string }

export default function FacultyManagementClient({ initialFaculties }: { initialFaculties: FacultyRow[] }) {
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
        window.location.assign(data.redirect || '/faculty');
      } else {
        setError(data.error || 'Impersonation failed');
      }
    } catch {
      setError('Impersonation failed due to an unexpected error.');
    }
  };

  return (
    <div className="space-y-4">
      {error && (
        <div className="p-3 bg-deep-violet/10 border border-deep-violet/20 rounded-xl text-[13px] font-semibold text-deep-violet">{error}</div>
      )}
      <div className="bg-white rounded-[20px] border border-border-light overflow-hidden">
        <table className="w-full text-left border-collapse">
          <thead>
            <tr className="bg-page-bg border-b border-border-light">
              <th className="p-4 text-[12px] font-bold text-text-muted">Name</th>
              <th className="p-4 text-[12px] font-bold text-text-muted">Role</th>
              <th className="p-4 text-[12px] font-bold text-text-muted">Joined</th>
              <th className="p-4 text-[12px] font-bold text-text-muted text-right">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border-light">
            {initialFaculties.map((f) => (
              <tr key={f.id} className="hover:bg-page-bg/50 transition-colors">
                <td className="p-4">
                  <div className="flex items-center gap-3">
                    <InitialsAvatar name={f.name} size={32} />
                    <div>
                      <div className="font-bold text-text-main text-[13px]">{f.name}</div>
                      <div className="text-[11px] text-text-muted">{f.email}</div>
                    </div>
                  </div>
                </td>
                <td className="p-4">
                  <span className="px-2 py-1 bg-primary-purple/10 text-primary-purple text-[10px] rounded-full font-bold uppercase">{f.roleLabel}</span>
                </td>
                <td className="p-4 text-[12px] text-text-muted">{new Date(f.createdAt).toLocaleDateString('en-IN', { month: 'short', year: 'numeric' })}</td>
                <td className="p-4 text-right">
                  <button onClick={() => handleImpersonate(f.id)} className="inline-flex items-center gap-2 px-3 py-1.5 bg-page-bg text-primary-purple hover:bg-primary-purple/10 rounded-lg text-[12px] font-bold transition-colors">
                    <LogIn className="w-3.5 h-3.5" /> Log in as
                  </button>
                </td>
              </tr>
            ))}
            {initialFaculties.length === 0 && (
              <tr><td colSpan={4} className="p-8 text-center text-text-muted text-[13px]">No faculty accounts found.</td></tr>
            )}
          </tbody>
        </table>
      </div>
      <p className="text-[12px] text-text-muted">
        New faculty accounts are provisioned via Supabase Auth (Authentication → Users → Invite) — self-service creation from this screen isn't wired up yet.
      </p>
    </div>
  );
}
