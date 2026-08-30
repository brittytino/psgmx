'use client';

import React from 'react';
import { InitialsAvatar } from '@/components/basic/InitialsAvatar';

interface FacultyRow { id: string; name: string; email: string; roleLabel: string; createdAt: string }

export default function FacultyManagementClient({ initialFaculties }: { initialFaculties: FacultyRow[] }) {
  return (
    <div className="space-y-4">
      <div className="bg-white rounded-[20px] border border-border-light overflow-hidden">
        <table className="w-full text-left border-collapse">
          <thead>
            <tr className="bg-page-bg border-b border-border-light">
              <th className="p-4 text-[12px] font-bold text-text-muted">Name</th>
              <th className="p-4 text-[12px] font-bold text-text-muted">Role</th>
              <th className="p-4 text-[12px] font-bold text-text-muted">Joined</th>
              <th className="p-4 text-[12px] font-bold text-text-muted text-right">Account</th>
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
                  <span className="rounded-full bg-emerald-50 px-3 py-1 text-[11px] font-bold text-emerald-700">Verified faculty</span>
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
        Faculty identities are provisioned from the approved department roster and authenticate with OTP.
      </p>
    </div>
  );
}
