'use client';

import React, { useState } from 'react';
import { Plus, LogIn } from 'lucide-react';
import ConfirmationModal from '@/components/basic/confirmation-modal';

export default function FacultyClientPage({ initialFaculties }: { initialFaculties: any[] }) {
  const [faculties, setFaculties] = useState(initialFaculties);
  const [showAddModal, setShowAddModal] = useState(false);
  const [form, setForm] = useState({ fullName: '', username: '', email: '' });
  const [loading, setLoading] = useState(false);
  const [dialog, setDialog] = useState<{title: string, message: string, variant: 'success'|'danger'|'info'} | null>(null);

  const handleAdd = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    try {
      const res = await fetch('/api/super-admin/users', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ role: 'faculty', ...form })
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error);
      
      setFaculties([data.user, ...faculties]);
      setShowAddModal(false);
      setForm({ fullName: '', username: '', email: '' });
      setDialog({ title: 'Faculty Created', message: 'Faculty created with default password: Faculty@123', variant: 'success' });
    } catch (err: any) {
      setDialog({ title: 'Action Failed', message: err.message || 'Error adding faculty', variant: 'danger' });
    } finally {
      setLoading(false);
    }
  };

  const handleImpersonate = async (targetUserId: string) => {
    try {
      const res = await fetch('/api/super-admin/impersonate', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ targetUserId })
      });
      const data = await res.json();
      if (res.ok) {
        window.location.href = data.redirect;
      } else {
        setDialog({ title: 'Impersonation Failed', message: data.error, variant: 'danger' });
      }
    } catch (err) {
      console.error(err);
      setDialog({ title: 'Error', message: 'Impersonation failed due to an unexpected error.', variant: 'danger' });
    }
  };

  return (
    <div>
      <div className="flex justify-end mb-4">
        <button onClick={() => setShowAddModal(true)} className="flex items-center gap-2 px-4 py-2 bg-electric-blue text-white rounded-lg font-bold">
          <Plus className="w-5 h-5" /> Add Faculty
        </button>
      </div>

      <div className="bg-black/20 border border-border rounded-xl overflow-hidden">
        <table className="w-full text-left border-collapse">
          <thead>
            <tr className="bg-white/5 border-b border-border">
              <th className="p-4 text-sm font-bold text-text-muted">Name & Email</th>
              <th className="p-4 text-sm font-bold text-text-muted">Username</th>
              <th className="p-4 text-sm font-bold text-text-muted">Status</th>
              <th className="p-4 text-sm font-bold text-text-muted text-right">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border">
            {faculties.map(f => (
              <tr key={f._id} className="hover:bg-white/5 transition-colors">
                <td className="p-4">
                  <div className="font-bold text-white">{f.fullName || 'No Name'}</div>
                  <div className="text-sm text-text-muted">{f.email}</div>
                </td>
                <td className="p-4 font-mono text-sm text-electric-blue">@{f.username}</td>
                <td className="p-4">
                  <span className="px-2 py-1 bg-green-500/10 text-green-400 text-xs rounded font-bold uppercase">{f.status}</span>
                </td>
                <td className="p-4 text-right">
                  <button onClick={() => handleImpersonate(f._id)} className="inline-flex items-center gap-2 px-3 py-1.5 bg-purple-500/20 text-purple-400 hover:bg-purple-500/30 rounded-lg text-sm font-bold transition-colors">
                    <LogIn className="w-4 h-4" /> Login As
                  </button>
                </td>
              </tr>
            ))}
            {faculties.length === 0 && (
              <tr><td colSpan={4} className="p-8 text-center text-text-muted">No faculty found.</td></tr>
            )}
          </tbody>
        </table>
      </div>

      {showAddModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm">
          <div className="w-full max-w-md bg-page-bg border border-border rounded-2xl p-6">
            <h2 className="text-xl font-bold text-white mb-4">Add Faculty</h2>
            <form onSubmit={handleAdd} className="space-y-4">
              <div>
                <label className="block text-xs font-bold text-text-muted uppercase mb-1">Full Name</label>
                <input required className="w-full bg-black/40 border border-border rounded-lg px-3 py-2 text-white" value={form.fullName} onChange={e => setForm({...form, fullName: e.target.value})} />
              </div>
              <div>
                <label className="block text-xs font-bold text-text-muted uppercase mb-1">Username (3-5 chars)</label>
                <input required minLength={3} maxLength={5} className="w-full bg-black/40 border border-border rounded-lg px-3 py-2 text-white" placeholder="e.g. hod" value={form.username} onChange={e => setForm({...form, username: e.target.value})} />
              </div>
              <div>
                <label className="block text-xs font-bold text-text-muted uppercase mb-1">Email</label>
                <input required type="email" className="w-full bg-black/40 border border-border rounded-lg px-3 py-2 text-white" value={form.email} onChange={e => setForm({...form, email: e.target.value})} />
              </div>
              <div className="flex justify-end gap-3 mt-6">
                <button type="button" onClick={() => setShowAddModal(false)} className="px-4 py-2 text-text-muted font-bold">Cancel</button>
                <button type="submit" disabled={loading} className="px-4 py-2 bg-electric-blue text-white rounded-lg font-bold disabled:opacity-50">Save Faculty</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {dialog && (
        <ConfirmationModal
          title={dialog.title}
          message={dialog.message}
          variant={dialog.variant}
          confirmLabel="OK"
          cancelLabel="Close"
          onConfirm={() => setDialog(null)}
          onClose={() => setDialog(null)}
        />
      )}
    </div>
  );
}
