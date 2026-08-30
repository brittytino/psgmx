'use client';

import React from 'react';
import { Activity, ShieldCheck, Brain, Code2, BookOpen, MessageSquare, Award, FolderKanban, RefreshCw } from 'lucide-react';

const dimensionMeta = {
  aptitude_reasoning: { name: 'Aptitude & reasoning', icon: Brain },
  coding_problem_solving: { name: 'Coding & problem solving', icon: Code2 },
  core_computer_science: { name: 'Core computer science', icon: BookOpen },
  communication_interview: { name: 'Communication & interview', icon: MessageSquare },
  assessment_performance: { name: 'Assessment performance', icon: Award },
  portfolio_project: { name: 'Portfolio & project proof', icon: FolderKanban },
} as const;

type DimensionKey = keyof typeof dimensionMeta;
interface PulseData {
  batchCode: string;
  totalStudents: number;
  activeThisWeekPct: number;
  avgReadinessScore: number | null;
  declineSignalCount: number;
  generatedAt: string;
  dimensions: Array<{ key: DimensionKey; average: number | null; measuredStudents: number }>;
}

function statusFor(value: number | null) {
  if (value == null) return { label: 'Awaiting evidence', colour: 'bg-slate-100 text-slate-600' };
  if (value >= 70) return { label: 'Healthy', colour: 'bg-emerald-100 text-emerald-800' };
  if (value >= 50) return { label: 'Building', colour: 'bg-blue-100 text-blue-800' };
  return { label: 'Needs focus', colour: 'bg-amber-100 text-amber-800' };
}

export default function ReadinessPulsePage() {
  const [data, setData] = React.useState<PulseData | null>(null);
  const [loading, setLoading] = React.useState(true);
  const [error, setError] = React.useState('');

  const load = React.useCallback(async () => {
    setLoading(true); setError('');
    try {
      const response = await fetch('/api/placement-rep/pulse', { cache: 'no-store' });
      const payload = await response.json();
      if (!response.ok) throw new Error(payload.error || 'Could not refresh readiness.');
      setData(payload);
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : 'Could not refresh readiness.');
    } finally { setLoading(false); }
  }, []);

  React.useEffect(() => { void load(); }, [load]);

  if (loading) return <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">{[0, 1, 2, 3, 4, 5].map((item) => <div key={item} className="h-40 animate-pulse rounded-2xl border border-slate-200 bg-white" />)}</div>;
  if (error || !data) return <div className="rounded-2xl border border-red-200 bg-red-50 p-6 text-sm font-semibold text-red-800">{error || 'No readiness data is available.'}<button onClick={() => void load()} className="ml-3 underline">Retry</button></div>;

  const measured = data.dimensions.filter((item) => item.average != null);
  const strongest = measured.length ? measured.reduce((best, item) => item.average! > best.average! ? item : best) : null;
  const focus = measured.length ? measured.reduce((lowest, item) => item.average! < lowest.average! ? item : lowest) : null;

  return (
    <div className="max-w-6xl mx-auto space-y-6 pb-12">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
        <div><span className="text-xs font-bold text-brand-600 uppercase tracking-wider block">Live batch aggregates</span><h1 className="text-2xl font-black text-slate-900 mt-1 flex items-center gap-2"><Activity className="w-6 h-6 text-brand-600" />Batch Readiness Pulse ({data.batchCode})</h1><p className="text-sm text-slate-500">Evidence-backed trends with peer privacy enforced at the server.</p></div>
        <button onClick={() => void load()} className="inline-flex items-center justify-center gap-2 rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-xs font-bold text-slate-700"><RefreshCw className="h-4 w-4" /> Refresh</button>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {[
          ['Students', data.totalStudents, `${data.activeThisWeekPct}% active this week`],
          ['Average readiness', data.avgReadinessScore == null ? '—' : `${data.avgReadinessScore}/100`, 'Verified evidence only'],
          ['Strongest dimension', strongest ? dimensionMeta[strongest.key].name : 'Awaiting evidence', strongest ? `${strongest.average}% batch average` : 'Complete activities to establish it'],
          ['Priority focus', focus ? dimensionMeta[focus.key].name : 'Awaiting evidence', focus ? `${focus.average}% batch average` : 'No synthetic score is shown'],
        ].map(([label, value, note]) => <div key={String(label)} className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm"><span className="text-xs font-bold text-slate-500 uppercase block">{label}</span><div className="text-xl font-black text-slate-900 mt-2">{value}</div><span className="text-xs text-slate-400 mt-1 block">{note}</span></div>)}
      </div>

      <div className="bg-white rounded-2xl border border-slate-200 p-6 shadow-sm space-y-4">
        <h2 className="text-sm font-bold text-slate-900 uppercase tracking-wider border-b border-slate-100 pb-3">Six-dimension aggregate mastery</h2>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {data.dimensions.map((dimension) => {
            const meta = dimensionMeta[dimension.key]; const Icon = meta.icon; const status = statusFor(dimension.average);
            return <div key={dimension.key} className="p-4 rounded-xl border border-slate-100 bg-slate-50 space-y-3"><div className="flex items-start justify-between gap-2"><div className="flex items-center gap-2 text-xs font-bold text-slate-800"><Icon className="w-4 h-4 text-brand-600" />{meta.name}</div><span className={`shrink-0 text-[10px] font-bold px-2 py-0.5 rounded-full ${status.colour}`}>{status.label}</span></div><div className="flex items-end justify-between"><span className="text-2xl font-black text-slate-900">{dimension.average == null ? '—' : `${dimension.average}%`}</span><span className="text-xs text-slate-400">{dimension.measuredStudents} measured</span></div><div className="h-1.5 w-full bg-slate-200 rounded-full overflow-hidden"><div className="h-full bg-brand-500 rounded-full" style={{ width: `${dimension.average || 0}%` }} /></div></div>;
          })}
        </div>
      </div>

      <div className="p-4 bg-slate-50 border border-slate-200 rounded-xl flex flex-col gap-2 text-xs text-slate-600 sm:flex-row sm:items-center sm:justify-between"><div className="flex items-center gap-2 font-medium"><ShieldCheck className="w-4 h-4 text-emerald-600" /><span>{data.declineSignalCount} recovery signals were routed privately to faculty. No student identity is exposed here.</span></div><span className="font-mono text-slate-400">Updated {new Date(data.generatedAt).toLocaleString('en-IN')}</span></div>
    </div>
  );
}
