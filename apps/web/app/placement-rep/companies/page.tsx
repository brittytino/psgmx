'use client';

import React from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Building2, Calendar, Plus, Search, ShieldCheck, Tag, Loader2, FileText, CheckCircle, Clock } from 'lucide-react';
import { createClient } from '@/lib/supabase/client';
import { getCurrentProfile } from '@/lib/current-profile';

interface Company {
  id: string;
  name: string;
  visit_date: string;
  roles_offered: string[];
  package_band: string | null;
  eligibility: string | null;
  rounds: Array<{ name: string; description?: string }>;
  batch_id: string;
  created_at: string;
}

interface Batch {
  id: string;
  batch_code: string;
  status: string;
}

export default function CompaniesPage() {
  const supabase = React.useMemo(() => createClient(), []);
  const [companies, setCompanies] = React.useState<Company[]>([]);
  const [batches, setBatches] = React.useState<Batch[]>([]);
  const [selectedBatchId, setSelectedBatchId] = React.useState<string>('all');
  const [loading, setLoading] = React.useState(true);
  const [query, setQuery] = React.useState('');

  // Create modal state
  const [showCreate, setShowCreate] = React.useState(false);
  const [busy, setBusy] = React.useState(false);
  const [message, setMessage] = React.useState('');
  const [error, setError] = React.useState('');

  const [form, setForm] = React.useState({
    name: '',
    visitDate: '',
    roles: '',
    packageBand: '',
    eligibility: '',
    batchId: '',
    roundCount: 3,
  });

  const load = React.useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const me = await getCurrentProfile(supabase);
      if (!me) throw new Error('Profile not loaded');

      const [{ data: compData }, { data: batchData }] = await Promise.all([
        supabase.from('companies').select('*').order('visit_date', { ascending: false }),
        supabase.from('batches').select('id, batch_code, status').order('batch_code', { ascending: false }),
      ]);

      setCompanies((compData || []) as Company[]);
      setBatches((batchData || []) as Batch[]);
      if (me.batch_id) setForm(prev => ({ ...prev, batchId: me.batch_id! }));
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load companies.');
    } finally {
      setLoading(false);
    }
  }, [supabase]);

  React.useEffect(() => { void load(); }, [load]);

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.name.trim() || !form.visitDate || !form.batchId) return;
    setBusy(true);
    setError('');
    setMessage('');

    try {
      const me = await getCurrentProfile(supabase);
      const rolesArr = form.roles.split(',').map(r => r.trim()).filter(Boolean);
      const sampleRounds = Array.from({ length: form.roundCount }, (_, i) => ({
        name: `Round ${i + 1}`,
        description: i === 0 ? 'Online Aptitude & Technical MCQ' : i === 1 ? 'Technical Interview' : 'HR & Leadership Round',
      }));

      const { error: insErr } = await supabase.from('companies').insert({
        name: form.name.trim(),
        visit_date: form.visitDate,
        roles_offered: rolesArr,
        package_band: form.packageBand.trim() || null,
        eligibility: form.eligibility.trim() || null,
        rounds: sampleRounds,
        batch_id: form.batchId,
        created_by: me?.id || null,
      });

      if (insErr) throw insErr;

      setMessage('Company record created successfully.');
      setShowCreate(false);
      setForm({ name: '', visitDate: '', roles: '', packageBand: '', eligibility: '', batchId: form.batchId, roundCount: 3 });
      await load();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to create company record.');
    } finally {
      setBusy(false);
    }
  };

  const filtered = companies.filter(c => {
    const matchesBatch = selectedBatchId === 'all' || c.batch_id === selectedBatchId;
    const term = query.toLowerCase().trim();
    const matchesQuery = !term ||
      c.name.toLowerCase().includes(term) ||
      (c.roles_offered || []).some(r => r.toLowerCase().includes(term)) ||
      (c.package_band || '').toLowerCase().includes(term);
    return matchesBatch && matchesQuery;
  });

  const batchMap = new Map(batches.map(b => [b.id, b.batch_code]));

  return (
    <div className="max-w-6xl mx-auto space-y-7 pb-10">
      <header className="flex flex-col sm:flex-row sm:items-end justify-between gap-4">
        <div>
          <div className="flex items-center gap-2 text-xs font-black uppercase tracking-wider text-primary-purple mb-1">
            <Building2 className="w-4 h-4" /> Placement Records Archive
          </div>
          <h1 className="text-3xl font-black text-text-main">Company Drive Directory</h1>
          <p className="text-sm text-text-muted mt-1">
            Historical placement drive records from 23MX, 24MX, and current active batches.
          </p>
        </div>
        <button
          onClick={() => setShowCreate(!showCreate)}
          className="flex items-center gap-2 px-5 py-3 bg-primary-purple text-white rounded-xl text-xs font-black self-start sm:self-auto">
          <Plus className="w-4 h-4" /> {showCreate ? 'Cancel' : 'Record Company Visit'}
        </button>
      </header>

      {/* Warning banner */}
      <div className="flex items-start gap-3 p-4 bg-amber-50 border border-amber-200 rounded-2xl text-xs font-semibold text-amber-900">
        <ShieldCheck className="w-5 h-5 shrink-0 text-amber-700 mt-0.5" />
        <span>
          Official company registration, live shortlists, and eligibility criteria are managed on <strong>NEO PAT</strong>. Records here preserve historical drive rounds and preparation patterns.
        </span>
      </div>

      {error && <div className="p-4 bg-red-50 border border-red-200 text-red-700 rounded-2xl text-sm font-bold">{error}</div>}
      {message && <div className="p-4 bg-emerald-50 border border-emerald-200 text-emerald-800 rounded-2xl text-sm font-bold">{message}</div>}

      {/* Create Modal Form */}
      <AnimatePresence>
        {showCreate && (
          <motion.form
            initial={{ opacity: 0, height: 0 }} animate={{ opacity: 1, height: 'auto' }} exit={{ opacity: 0, height: 0 }}
            onSubmit={handleCreate}
            className="bg-white border border-border-light rounded-3xl p-6 shadow-sm space-y-4 overflow-hidden">
            <h2 className="text-base font-black text-text-main">Record Historical / Upcoming Company Visit</h2>
            <div className="grid gap-4 sm:grid-cols-2">
              <label className="text-xs font-bold text-text-muted">
                Company Name *
                <input required value={form.name} onChange={e => setForm({ ...form, name: e.target.value })}
                  placeholder="e.g. Caterpillar, Zoho, Accenture" className="mt-1 w-full px-4 py-2.5 border border-border-light rounded-xl text-sm outline-none focus:border-primary-purple" />
              </label>
              <label className="text-xs font-bold text-text-muted">
                Visit Date *
                <input required type="date" value={form.visitDate} onChange={e => setForm({ ...form, visitDate: e.target.value })}
                  className="mt-1 w-full px-4 py-2.5 border border-border-light rounded-xl text-sm outline-none focus:border-primary-purple" />
              </label>
              <label className="text-xs font-bold text-text-muted">
                Batch *
                <select required value={form.batchId} onChange={e => setForm({ ...form, batchId: e.target.value })}
                  className="mt-1 w-full px-4 py-2.5 border border-border-light rounded-xl text-sm outline-none">
                  <option value="">Select Batch</option>
                  {batches.map(b => <option key={b.id} value={b.id}>{b.batch_code} ({b.status})</option>)}
                </select>
              </label>
              <label className="text-xs font-bold text-text-muted">
                Package Band
                <input value={form.packageBand} onChange={e => setForm({ ...form, packageBand: e.target.value })}
                  placeholder="e.g. 8–12 LPA" className="mt-1 w-full px-4 py-2.5 border border-border-light rounded-xl text-sm outline-none focus:border-primary-purple" />
              </label>
              <label className="text-xs font-bold text-text-muted sm:col-span-2">
                Roles Offered (comma-separated)
                <input value={form.roles} onChange={e => setForm({ ...form, roles: e.target.value })}
                  placeholder="Software Engineer, Data Analyst, Cloud Consultant" className="mt-1 w-full px-4 py-2.5 border border-border-light rounded-xl text-sm outline-none focus:border-primary-purple" />
              </label>
              <label className="text-xs font-bold text-text-muted sm:col-span-2">
                Eligibility Criteria
                <input value={form.eligibility} onChange={e => setForm({ ...form, eligibility: e.target.value })}
                  placeholder="CGPA 7.5+, No standing arrears" className="mt-1 w-full px-4 py-2.5 border border-border-light rounded-xl text-sm outline-none focus:border-primary-purple" />
              </label>
            </div>
            <div className="flex justify-end gap-3 pt-2">
              <button type="button" onClick={() => setShowCreate(false)} className="px-5 py-2.5 border border-border-light rounded-xl text-xs font-bold text-text-muted">Cancel</button>
              <button type="submit" disabled={busy} className="px-6 py-2.5 bg-primary-purple text-white rounded-xl text-xs font-black disabled:opacity-50 flex items-center gap-2">
                {busy ? <Loader2 className="w-4 h-4 animate-spin" /> : 'Save Record'}
              </button>
            </div>
          </motion.form>
        )}
      </AnimatePresence>

      {/* Controls: Search & Batch Filter */}
      <div className="flex flex-col sm:flex-row gap-3">
        <div className="relative flex-1">
          <Search className="absolute left-4 top-3.5 w-4 h-4 text-text-muted" />
          <input value={query} onChange={e => setQuery(e.target.value)}
            placeholder="Search by company, role, or package band…"
            className="w-full pl-11 pr-4 py-3 bg-white border border-border-light rounded-2xl text-sm outline-none focus:border-primary-purple" />
        </div>
        <select value={selectedBatchId} onChange={e => setSelectedBatchId(e.target.value)}
          className="px-4 py-3 bg-white border border-border-light rounded-2xl text-xs font-bold outline-none">
          <option value="all">All Batches</option>
          {batches.map(b => <option key={b.id} value={b.id}>{b.batch_code}</option>)}
        </select>
      </div>

      {/* Grid of Companies */}
      {loading ? (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {[1,2,3,4,5,6].map(i => <div key={i} className="h-44 bg-white border border-border-light rounded-3xl animate-pulse" />)}
        </div>
      ) : filtered.length === 0 ? (
        <div className="bg-white border border-dashed border-border-light rounded-3xl p-14 text-center">
          <Building2 className="w-10 h-10 text-primary-purple mx-auto mb-3" />
          <h3 className="text-lg font-black text-text-main">No Company Records Found</h3>
          <p className="text-sm text-text-muted mt-1">Try clearing filters or add a new record above.</p>
        </div>
      ) : (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {filtered.map(comp => {
            const batchCode = batchMap.get(comp.batch_id) || 'Historical';
            const roundsArr = (Array.isArray(comp.rounds) ? comp.rounds : []) as Array<{ name: string; description?: string }>;
            return (
              <div key={comp.id} className="bg-white border border-border-light rounded-3xl p-6 shadow-sm hover:shadow-md transition-shadow space-y-4">
                <div className="flex items-start justify-between gap-3">
                  <div>
                    <span className="text-[10px] font-black uppercase tracking-wider text-primary-purple px-2.5 py-1 bg-violet-50 rounded-full">
                      {batchCode} Batch
                    </span>
                    <h2 className="text-lg font-black text-text-main mt-2">{comp.name}</h2>
                  </div>
                  {comp.package_band && (
                    <span className="text-xs font-black text-emerald-700 bg-emerald-50 px-2.5 py-1 rounded-full shrink-0">
                      {comp.package_band}
                    </span>
                  )}
                </div>

                <div className="space-y-2 text-xs text-text-muted">
                  <div className="flex items-center gap-2">
                    <Calendar className="w-3.5 h-3.5 text-primary-purple shrink-0" />
                    <span>Visited {new Date(comp.visit_date).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' })}</span>
                  </div>
                  {comp.roles_offered?.length > 0 && (
                    <div className="flex items-start gap-2">
                      <Tag className="w-3.5 h-3.5 text-primary-purple shrink-0 mt-0.5" />
                      <span className="font-bold text-text-main">{comp.roles_offered.join(', ')}</span>
                    </div>
                  )}
                  {comp.eligibility && (
                    <div className="flex items-start gap-2">
                      <FileText className="w-3.5 h-3.5 text-primary-purple shrink-0 mt-0.5" />
                      <span>{comp.eligibility}</span>
                    </div>
                  )}
                </div>

                {roundsArr.length > 0 && (
                  <div className="pt-3 border-t border-border-light">
                    <p className="text-[10px] font-black uppercase tracking-wider text-text-muted mb-2">Selection Rounds ({roundsArr.length})</p>
                    <div className="space-y-1">
                      {roundsArr.map((r, idx) => (
                        <div key={idx} className="flex items-center gap-2 text-[11px] font-bold text-text-main">
                          <span className="w-4 h-4 rounded-full bg-violet-100 text-primary-purple text-[9px] font-black flex items-center justify-center shrink-0">
                            {idx + 1}
                          </span>
                          <span className="truncate">{r.name || `Round ${idx + 1}`}</span>
                        </div>
                      ))}
                    </div>
                  </div>
                )}
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
