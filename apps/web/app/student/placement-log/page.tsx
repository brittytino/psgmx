'use client';

import React from 'react';
import {
  BookOpenCheck, ChevronDown, Lightbulb, Plus, Search, ShieldCheck,
  Building2, Calendar, Tag, FileText, Sparkles, Filter
} from 'lucide-react';
import { createClient } from '@/lib/supabase/client';
import { getCurrentProfile } from '@/lib/current-profile';

type PatternType = 'aptitude_screening' | 'coding_round' | 'technical_deep_dive' | 'fyp_discussion' | 'behavioural' | 'group_discussion' | 'general';

interface Pattern {
  id: string;
  author_id: string | null;
  title: string;
  pattern_type: PatternType;
  historical_context: string | null;
  preparation_helped: string;
  mistakes: string | null;
  example_themes: string[];
  advice: string;
  company_name: string | null;
  batch_year: string | null;
  approval_status: string;
  created_at: string;
  is_system_archived?: boolean;
}

interface Company {
  id: string;
  name: string;
  visit_date: string;
  roles_offered: string[];
  package_band: string | null;
  eligibility: string | null;
  rounds: Array<{ name: string; description?: string }>;
  batch_id: string;
  batches?: { batch_code: string };
}

const labels: Record<PatternType, string> = {
  aptitude_screening: 'Aptitude screening',
  coding_round: 'Coding round',
  technical_deep_dive: 'Technical deep dive',
  fyp_discussion: 'FYP discussion',
  behavioural: 'Behavioural conversation',
  group_discussion: 'Group discussion',
  general: 'General pattern',
};

const emptyForm = { title: '', patternType: 'technical_deep_dive' as PatternType, historicalContext: '', preparationHelped: '', mistakes: '', themes: '', advice: '' };

export default function StudentPlacementLogPage() {
  const supabase = React.useMemo(() => createClient(), []);
  const [activeTab, setActiveTab] = React.useState<'drives' | 'patterns'>('drives');

  // State for Interview Patterns
  const [patterns, setPatterns] = React.useState<Pattern[]>([]);
  const [me, setMe] = React.useState<{ id: string; reg_no: string | null } | null>(null);
  const [canContribute, setCanContribute] = React.useState(false);
  const [showForm, setShowForm] = React.useState(false);
  const [form, setForm] = React.useState(emptyForm);

  // State for Companies Drives
  const [companies, setCompanies] = React.useState<Company[]>([]);

  // Shared state
  const [query, setQuery] = React.useState('');
  const [loading, setLoading] = React.useState(true);
  const [busy, setBusy] = React.useState(false);
  const [error, setError] = React.useState('');
  const [message, setMessage] = React.useState('');

  const load = React.useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const profile = await getCurrentProfile(supabase);
      if (!profile) throw new Error('Your profile could not be loaded.');
      setMe({ id: profile.id, reg_no: profile.reg_no });

      if (profile.batch_id) {
        const { data: batch } = await supabase.from('batches').select('status').eq('id', profile.batch_id).maybeSingle();
        setCanContribute(batch?.status === 'active_senior');
      }

      const [{ data: patData, error: patErr }, { data: compData, error: compErr }] = await Promise.all([
        (supabase as any).from('interview_patterns').select('*').order('created_at', { ascending: false }),
        supabase.from('companies').select('*, batches(batch_code)').order('visit_date', { ascending: false }),
      ]);

      if (patErr) throw patErr;
      if (compErr) throw compErr;

      setPatterns(patData || []);
      setCompanies((compData || []) as unknown as Company[]);
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : 'Data could not be loaded.');
    } finally {
      setLoading(false);
    }
  }, [supabase]);

  React.useEffect(() => { void load(); }, [load]);

  async function submitPattern(event: React.FormEvent) {
    event.preventDefault();
    if (!me || !canContribute) return;
    setBusy(true); setError(''); setMessage('');
    const { error: insertError } = await (supabase as any).from('interview_patterns').insert({
      author_id: me.id,
      title: form.title.trim(),
      pattern_type: form.patternType,
      historical_context: form.historicalContext.trim() || null,
      preparation_helped: form.preparationHelped.trim(),
      mistakes: form.mistakes.trim() || null,
      example_themes: form.themes.split(',').map((item) => item.trim()).filter(Boolean),
      advice: form.advice.trim(),
      batch_year: me.reg_no?.match(/^\d{2}MX/)?.[0] || null,
      approval_status: 'pending',
    });
    if (insertError) setError(insertError.message);
    else {
      setMessage('Pattern submitted for faculty review. It remains private until approved.');
      setForm(emptyForm); setShowForm(false); await load();
    }
    setBusy(false);
  }

  const term = query.trim().toLowerCase();
  const filteredPatterns = patterns.filter(item =>
    !term || [item.title, item.company_name, item.historical_context, item.preparation_helped, item.advice, ...(item.example_themes || [])].some(val => val?.toLowerCase().includes(term))
  );

  const filteredCompanies = companies.filter(c =>
    !term || c.name.toLowerCase().includes(term) || (c.roles_offered || []).some(r => r.toLowerCase().includes(term)) || (c.package_band || '').toLowerCase().includes(term)
  );

  return (
    <div className="mx-auto max-w-5xl space-y-7 pb-10">
      <header className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
        <div>
          <p className="flex items-center gap-1.5 text-[11px] font-black uppercase tracking-wider text-primary-purple">
            <BookOpenCheck className="h-4 w-4" /> Alumni &amp; Senior Experience Archive
          </p>
          <h1 className="mt-1 text-2xl font-black text-text-main">Placement Log &amp; Company Archive</h1>
          <p className="mt-1 text-sm text-text-muted">
            Historical company drives from 23MX/24MX and faculty-reviewed interview preparation patterns.
          </p>
        </div>
        {canContribute && activeTab === 'patterns' && (
          <button onClick={() => setShowForm(!showForm)} className="flex items-center gap-2 rounded-xl bg-primary-purple px-5 py-3 text-xs font-black text-white shrink-0">
            <Plus className="h-4 w-4" />{showForm ? 'Cancel' : 'Contribute Pattern'}
          </button>
        )}
      </header>

      {/* Tabs */}
      <div className="flex gap-2 border-b border-border-light pb-3">
        <button
          onClick={() => setActiveTab('drives')}
          className={`flex items-center gap-2 px-5 py-2.5 rounded-xl text-xs font-black transition-colors ${
            activeTab === 'drives' ? 'bg-primary-purple text-white' : 'bg-white border border-border-light text-text-muted hover:text-text-main'
          }`}>
          <Building2 className="w-4 h-4" /> Company Drives (23MX / 24MX) ({companies.length})
        </button>
        <button
          onClick={() => setActiveTab('patterns')}
          className={`flex items-center gap-2 px-5 py-2.5 rounded-xl text-xs font-black transition-colors ${
            activeTab === 'patterns' ? 'bg-primary-purple text-white' : 'bg-white border border-border-light text-text-muted hover:text-text-main'
          }`}>
          <Sparkles className="w-4 h-4" /> Interview Patterns ({patterns.length})
        </button>
      </div>

      <div className="flex gap-3 rounded-2xl border border-amber-200 bg-amber-50 p-4 text-xs font-semibold leading-5 text-amber-900">
        <ShieldCheck className="h-5 w-5 shrink-0 text-amber-700 mt-0.5" />
        Official application portals, live eligibility, test schedules, and shortlists are hosted on <strong>NEO PAT</strong>. PSGMX archives preparation knowledge and round experiences.
      </div>

      {error && <div role="alert" className="rounded-2xl border border-red-200 bg-red-50 p-4 text-sm font-bold text-red-700">{error}</div>}
      {message && <div className="rounded-2xl border border-emerald-200 bg-emerald-50 p-4 text-sm font-bold text-emerald-800">{message}</div>}

      {/* Search Bar */}
      <div className="relative">
        <Search className="absolute left-4 top-3.5 h-4 w-4 text-text-muted" />
        <input
          value={query} onChange={(e) => setQuery(e.target.value)}
          placeholder={activeTab === 'drives' ? "Search by company, role, or package..." : "Search company, skill, round, or theme..."}
          className="w-full rounded-2xl border border-border-light bg-white py-3 pl-11 pr-4 text-sm outline-none focus:border-primary-purple"
        />
      </div>

      {loading && <div className="h-48 animate-pulse rounded-3xl bg-white" />}

      {/* TAB 1: Company Placement Drives */}
      {!loading && activeTab === 'drives' && (
        <div className="space-y-4">
          {filteredCompanies.length === 0 ? (
            <div className="rounded-3xl border border-dashed border-border-light bg-white p-14 text-center">
              <Building2 className="mx-auto h-10 w-10 text-primary-purple" />
              <h2 className="mt-4 text-lg font-black">No company records found</h2>
              <p className="mt-2 text-sm text-text-muted">No historical company drive matches your search.</p>
            </div>
          ) : (
            <div className="grid gap-4 sm:grid-cols-2">
              {filteredCompanies.map(c => {
                const batchCode = c.batches?.batch_code || 'Historical';
                const roundsArr = (Array.isArray(c.rounds) ? c.rounds : []) as Array<{ name: string; description?: string }>;
                return (
                  <div key={c.id} className="rounded-3xl border border-border-light bg-white p-6 shadow-sm space-y-4 hover:border-primary-purple/30 transition-colors">
                    <div className="flex items-start justify-between gap-3">
                      <div>
                        <span className="text-[10px] font-black uppercase tracking-wider text-primary-purple px-2.5 py-1 bg-violet-50 rounded-full">
                          {batchCode} Batch
                        </span>
                        <h3 className="mt-2 text-lg font-black text-text-main">{c.name}</h3>
                      </div>
                      {c.package_band && (
                        <span className="text-xs font-black text-emerald-700 bg-emerald-50 px-2.5 py-1 rounded-full shrink-0">
                          {c.package_band}
                        </span>
                      )}
                    </div>

                    <div className="space-y-2 text-xs text-text-muted">
                      <div className="flex items-center gap-2">
                        <Calendar className="w-3.5 h-3.5 text-primary-purple shrink-0" />
                        <span>Visited {new Date(c.visit_date).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' })}</span>
                      </div>
                      {c.roles_offered?.length > 0 && (
                        <div className="flex items-start gap-2">
                          <Tag className="w-3.5 h-3.5 text-primary-purple shrink-0 mt-0.5" />
                          <span className="font-bold text-text-main">{c.roles_offered.join(', ')}</span>
                        </div>
                      )}
                      {c.eligibility && (
                        <div className="flex items-start gap-2">
                          <FileText className="w-3.5 h-3.5 text-primary-purple shrink-0 mt-0.5" />
                          <span>{c.eligibility}</span>
                        </div>
                      )}
                    </div>

                    {roundsArr.length > 0 && (
                      <div className="pt-3 border-t border-border-light">
                        <p className="text-[10px] font-black uppercase tracking-wider text-text-muted mb-2">Drive Format &amp; Rounds ({roundsArr.length})</p>
                        <div className="space-y-1.5">
                          {roundsArr.map((r, idx) => (
                            <div key={idx} className="text-[11px] bg-page-bg p-2 rounded-xl">
                              <span className="font-bold text-text-main">{r.name || `Round ${idx + 1}`}</span>
                              {r.description && <p className="text-text-muted text-[10px] mt-0.5">{r.description}</p>}
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
      )}

      {/* TAB 2: Interview Patterns */}
      {!loading && activeTab === 'patterns' && (
        <div className="space-y-4">
          {showForm && (
            <form onSubmit={submitPattern} className="space-y-4 rounded-3xl border border-border-light bg-white p-6 shadow-sm">
              <h2 className="font-black">Contribute reusable preparation evidence</h2>
              <div className="grid gap-4 sm:grid-cols-2">
                <Field label="Pattern title">
                  <input required minLength={5} maxLength={160} value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })} className="field" />
                </Field>
                <Field label="Round type">
                  <select value={form.patternType} onChange={(e) => setForm({ ...form, patternType: e.target.value as PatternType })} className="field">
                    {Object.entries(labels).map(([key, value]) => <option key={key} value={key}>{value}</option>)}
                  </select>
                </Field>
              </div>
              <Field label="What preparation helped?">
                <textarea required minLength={20} value={form.preparationHelped} onChange={(e) => setForm({ ...form, preparationHelped: e.target.value })} className="field min-h-24" />
              </Field>
              <Field label="Advice for the next batch">
                <textarea required minLength={20} value={form.advice} onChange={(e) => setForm({ ...form, advice: e.target.value })} className="field min-h-24" />
              </Field>
              <div className="grid gap-4 sm:grid-cols-2">
                <Field label="Historical context (optional)">
                  <textarea value={form.historicalContext} onChange={(e) => setForm({ ...form, historicalContext: e.target.value })} className="field min-h-20" />
                </Field>
                <Field label="Mistakes and lessons (optional)">
                  <textarea value={form.mistakes} onChange={(e) => setForm({ ...form, mistakes: e.target.value })} className="field min-h-20" />
                </Field>
              </div>
              <Field label="Themes, comma separated">
                <input value={form.themes} onChange={(e) => setForm({ ...form, themes: e.target.value })} className="field" />
              </Field>
              <div className="flex justify-end">
                <button disabled={busy} className="rounded-xl bg-primary-purple px-5 py-3 text-sm font-black text-white disabled:opacity-50">
                  {busy ? 'Submitting…' : 'Submit for review'}
                </button>
              </div>
              <style jsx>{`.field{margin-top:.5rem;width:100%;border:1px solid #e5e7eb;border-radius:.75rem;padding:.75rem 1rem;font-size:.875rem;outline:none}.field:focus{border-color:#6d28d9}`}</style>
            </form>
          )}

          {filteredPatterns.length === 0 ? (
            <div className="rounded-3xl border border-dashed border-border-light bg-white p-14 text-center">
              <BookOpenCheck className="mx-auto h-10 w-10 text-primary-purple" />
              <h2 className="mt-4 text-lg font-black">No approved patterns yet</h2>
              <p className="mt-2 text-sm text-text-muted">The library grows through reviewed senior and alumni evidence.</p>
            </div>
          ) : (
            <div className="space-y-3">
              {filteredPatterns.map((item) => (
                <details key={item.id} className="group rounded-2xl border border-border-light bg-white p-5 shadow-sm">
                  <summary className="flex cursor-pointer list-none items-start justify-between gap-4">
                    <div>
                      <div className="flex flex-wrap gap-2">
                        <span className="rounded-full bg-primary-purple/10 px-2.5 py-1 text-[10px] font-black text-primary-purple">{labels[item.pattern_type]}</span>
                        {item.batch_year && <span className="rounded-full bg-page-bg px-2.5 py-1 text-[10px] font-black text-text-muted">{item.batch_year}</span>}
                        {item.is_system_archived && <span className="rounded-full bg-amber-50 px-2.5 py-1 text-[10px] font-black text-amber-700">Archived record</span>}
                      </div>
                      <h2 className="mt-3 text-base font-black text-text-main">{item.title}</h2>
                      {item.company_name && <p className="mt-1 text-xs font-bold text-text-muted">{item.company_name}</p>}
                    </div>
                    <ChevronDown className="mt-2 h-5 w-5 shrink-0 text-text-muted transition group-open:rotate-180" />
                  </summary>
                  <div className="mt-5 grid gap-4 border-t border-border-light pt-5 sm:grid-cols-2">
                    <Evidence title="Preparation that helped" text={item.preparation_helped} />
                    <Evidence title="Advice" text={item.advice} />
                    {item.mistakes && <Evidence title="Mistakes and lessons" text={item.mistakes} />}
                    {item.historical_context && <Evidence title="Historical context" text={item.historical_context} />}
                  </div>
                  {item.example_themes?.length > 0 && (
                    <div className="mt-4 flex flex-wrap gap-2">
                      {item.example_themes.map((theme) => (
                        <span key={theme} className="rounded-full bg-page-bg px-3 py-1 text-[10px] font-bold text-text-muted">{theme}</span>
                      ))}
                    </div>
                  )}
                </details>
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  );
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return <label className="block text-xs font-bold text-text-muted">{label}{children}</label>;
}
function Evidence({ title, text }: { title: string; text: string }) {
  return (
    <div className="rounded-2xl bg-page-bg p-4">
      <p className="flex items-center gap-1.5 text-[10px] font-black uppercase tracking-wider text-primary-purple">
        <Lightbulb className="h-3.5 w-3.5" />{title}
      </p>
      <p className="mt-2 text-sm leading-6 text-text-muted">{text}</p>
    </div>
  );
}
