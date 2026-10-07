'use client';

import React, { useState, useEffect, useCallback } from 'react';
import { motion } from 'framer-motion';
import {
  Users,
  TrendingUp,
  AlertTriangle,
  Download,
  CalendarClock,
  Activity,
  Cpu,
  CheckCircle2,
  Play,
  RotateCcw,
  Sparkles,
  Save,
} from 'lucide-react';

interface CommandCenterData {
  batchCode: string;
  totalStudents: number;
  activeThisWeekPct: number;
  avgReadinessScore: number | null;
  bandCounts: { strong: number; building: number; needs_attention: number; at_risk: number };
  avgAttendance: number | null;
  flaggedAttempts: number;
  upcomingSessions: number;
  declineSignalCount: number;
  generatedAt: string;
}

const DEFAULT_FREE_MODELS = [
  'nvidia/nemotron-3-ultra-550b-a55b:free',
  'poolside/laguna-s-2.1:free',
  'nvidia/nemotron-3.5-lightning:free',
  'nvidia/nemotron-3-super-120b-a12b:free',
  'dots-studio/dots-3-note-preview:free',
  'thinkingmachines/inkling:free',
  'poolside/laguna-xs-2.1:free',
  'google/gemma-4-26b-a4b-it:free',
  'google/gemma-4-31b-it:free',
  'fish-audio/s2.1-pro-free:free',
];

export default function CommandCenterPage() {
  const [data, setData] = useState<CommandCenterData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  // AI Model Routing State
  const [mainModel, setMainModel] = useState<string>('nvidia/nemotron-3-ultra-550b-a55b:free');
  const [fallbackModels, setFallbackModels] = useState<string[]>([
    'poolside/laguna-s-2.1:free',
    'nvidia/nemotron-3.5-lightning:free',
    'nvidia/nemotron-3-super-120b-a12b:free',
    'dots-studio/dots-3-note-preview:free',
    'thinkingmachines/inkling:free',
  ]);
  const [customModelInput, setCustomModelInput] = useState('');
  const [savingModels, setSavingModels] = useState(false);
  const [testingModel, setTestingModel] = useState(false);
  const [aiTestResult, setAiTestResult] = useState<string | null>(null);
  const [aiConfigMessage, setAiConfigMessage] = useState<{ text: string; success: boolean } | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const response = await fetch('/api/placement-rep/pulse', { cache: 'no-store' });
      const payload = await response.json();
      if (!response.ok) throw new Error(payload.error || 'Could not load the batch pulse.');
      setData(payload);
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : 'Could not load the batch pulse.');
    } finally {
      setLoading(false);
    }
  }, []);

  const loadAiConfig = useCallback(async () => {
    try {
      const res = await fetch('/api/placement-rep/ai-models');
      if (res.ok) {
        const json = await res.json();
        if (json?.config?.mainModel) setMainModel(json.config.mainModel);
        if (Array.isArray(json?.config?.fallbackModels) && json.config.fallbackModels.length > 0) {
          setFallbackModels(json.config.fallbackModels);
        }
      }
    } catch {
      // ignore
    }
  }, []);

  useEffect(() => {
    void load();
    void loadAiConfig();
  }, [load, loadAiConfig]);

  const handleSaveAiConfig = async () => {
    setSavingModels(true);
    setAiConfigMessage(null);
    try {
      const res = await fetch('/api/placement-rep/ai-models', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ mainModel, fallbackModels }),
      });
      const resData = await res.json();
      if (res.ok) {
        setAiConfigMessage({ text: 'AI Model Fallback Chain updated successfully!', success: true });
      } else {
        setAiConfigMessage({ text: resData.error || 'Failed to update AI config.', success: false });
      }
    } catch (err) {
      setAiConfigMessage({ text: 'Network error saving AI config.', success: false });
    } finally {
      setSavingModels(false);
    }
  };

  const handleTestAiModel = async () => {
    setTestingModel(true);
    setAiTestResult(null);
    try {
      const res = await fetch('/api/placement-rep/ai-models', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action: 'test', model: mainModel }),
      });
      const resData = await res.json();
      if (res.ok) {
        setAiTestResult(`✅ ${resData.message} (via ${resData.modelUsed})`);
      } else {
        setAiTestResult(`❌ Ping failed: ${resData.error || 'No response'}`);
      }
    } catch (err) {
      setAiTestResult('❌ Ping failed due to network error.');
    } finally {
      setTestingModel(false);
    }
  };

  const toggleFallbackModel = (model: string) => {
    if (fallbackModels.includes(model)) {
      setFallbackModels(fallbackModels.filter((m) => m !== model));
    } else {
      setFallbackModels([...fallbackModels, model]);
    }
  };

  const handleAddCustomModel = (e: React.FormEvent) => {
    e.preventDefault();
    const trimmed = customModelInput.trim();
    if (!trimmed) return;
    if (!fallbackModels.includes(trimmed)) {
      setFallbackModels([...fallbackModels, trimmed]);
    }
    setCustomModelInput('');
  };

  const handleExportCsv = () => {
    if (!data) return;
    const rows = [
      ['metric', 'value'],
      ['batch', data.batchCode],
      ['students', data.totalStudents],
      ['active_this_week_pct', data.activeThisWeekPct],
      ['average_readiness', data.avgReadinessScore ?? 'not_measured'],
      ['average_attendance_pct', data.avgAttendance ?? 'not_measured'],
      ['strong_band_count', data.bandCounts.strong],
      ['building_band_count', data.bandCounts.building],
      ['needs_attention_band_count', data.bandCounts.needs_attention],
      ['at_risk_band_count', data.bandCounts.at_risk],
      ['flagged_exam_attempts', data.flaggedAttempts],
      ['upcoming_sessions', data.upcomingSessions],
      ['decline_signals_routed_to_faculty', data.declineSignalCount],
      ['generated_at', data.generatedAt],
    ];
    const csv = rows.map((row) => row.map((value) => `"${String(value).replaceAll('"', '""')}"`).join(',')).join('\n');
    const url = URL.createObjectURL(new Blob([csv], { type: 'text/csv;charset=utf-8' }));
    const anchor = document.createElement('a');
    anchor.href = url;
    anchor.download = `batch-readiness-${data.batchCode}-${new Date().toISOString().slice(0, 10)}.csv`;
    anchor.click();
    URL.revokeObjectURL(url);
  };

  if (loading) return <div className="space-y-6 animate-pulse">{[0, 1, 2].map((i) => <div key={i} className="h-32 bg-white border border-border-light rounded-2xl" />)}</div>;

  if (error || !data) {
    return <div className="rounded-2xl border border-red-200 bg-red-50 p-6 text-sm font-semibold text-red-800">{error || 'No batch assignment was found.'}<button onClick={() => void load()} className="ml-3 underline">Retry</button></div>;
  }

  const bandTotal = Object.values(data.bandCounts).reduce((sum, value) => sum + value, 0);
  const summaries = [
    { label: 'Batch size', value: data.totalStudents, note: `${data.activeThisWeekPct}% active this week`, icon: Users, colour: 'text-primary-purple' },
    { label: 'Average readiness', value: data.avgReadinessScore == null ? '—' : `${data.avgReadinessScore}/100`, note: 'Verified evidence only', icon: Activity, colour: 'text-electric-blue' },
    { label: 'Average attendance', value: data.avgAttendance == null ? '—' : `${Math.round(data.avgAttendance)}%`, note: 'Preparation sessions', icon: TrendingUp, colour: 'text-electric-blue' },
    { label: 'Flagged attempts', value: data.flaggedAttempts, note: 'Review handled by faculty', icon: AlertTriangle, colour: 'text-illus-gold' },
  ];

  return (
    <div className="space-y-8 max-w-6xl pb-12">
      {/* Header */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-[24px] font-black text-text-main">Command Center</h1>
          <p className="text-[13px] text-text-muted mt-1">Batch {data.batchCode} · aggregate analytics & placement operations</p>
        </div>
        <button
          onClick={handleExportCsv}
          className="flex items-center justify-center gap-2 px-5 py-2.5 bg-primary-purple text-white rounded-xl text-[13px] font-bold hover:bg-deep-violet transition-colors shadow-sm"
        >
          <Download className="w-4 h-4" /> Export aggregate CSV
        </button>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-5">
        {summaries.map((summary, index) => (
          <motion.div key={summary.label} initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: index * 0.04 }} className="bg-white rounded-2xl border border-border-light p-6 shadow-sm">
            <div className="flex items-center gap-2 mb-4">
              <summary.icon className={`w-5 h-5 ${summary.colour}`} />
              <h3 className="text-[13px] font-bold text-slate-700">{summary.label}</h3>
            </div>
            <p className="text-[30px] font-black text-text-main">{summary.value}</p>
            <p className="mt-1 text-[11px] font-semibold text-text-muted">{summary.note}</p>
          </motion.div>
        ))}
      </div>

      {/* Readiness distribution */}
      <div className="bg-white rounded-2xl border border-border-light p-6 shadow-sm">
        <h3 className="text-[16px] font-bold text-text-main mb-2">Readiness distribution</h3>
        <p className="mb-5 text-[12px] text-text-muted">Counts only—individual readiness is visible to the student and authorised faculty, never to a peer representative.</p>
        {bandTotal === 0 ? (
          <p className="text-[13px] text-text-muted">No readiness evidence has been computed for this batch yet.</p>
        ) : (
          <div className="space-y-4">
            {([['strong', 'Strong', 'bg-electric-blue'], ['building', 'Building', 'bg-illus-gold'], ['needs_attention', 'Needs attention', 'bg-primary-purple'], ['at_risk', 'At risk', 'bg-deep-violet']] as const).map(([key, label, colour]) => {
              const count = data.bandCounts[key];
              return (
                <div key={key}>
                  <div className="flex justify-between text-[13px] font-semibold mb-1.5">
                    <span className="text-text-muted">{label}</span>
                    <span className="text-text-main font-black">{count}</span>
                  </div>
                  <div className="h-2 bg-border-light rounded-full overflow-hidden">
                    <div className={`h-full rounded-full ${colour}`} style={{ width: `${(count / bandTotal) * 100}%` }} />
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>

      {/* Sessions and signals */}
      <div className="grid gap-5 sm:grid-cols-2">
        <div className="bg-white rounded-2xl border border-border-light p-6 flex items-center justify-between shadow-sm">
          <div className="flex items-center gap-3">
            <CalendarClock className="w-5 h-5 text-primary-purple" />
            <div>
              <h3 className="text-[14px] font-bold text-text-main">Upcoming sessions</h3>
              <p className="text-[12px] text-text-muted">Scheduled for this batch</p>
            </div>
          </div>
          <span className="text-[24px] font-black text-text-main">{data.upcomingSessions}</span>
        </div>
        <div className="bg-white rounded-2xl border border-border-light p-6 flex items-center justify-between shadow-sm">
          <div className="flex items-center gap-3">
            <AlertTriangle className="w-5 h-5 text-illus-gold" />
            <div>
              <h3 className="text-[14px] font-bold text-text-main">Recovery signals</h3>
              <p className="text-[12px] text-text-muted">Automatically routed to faculty</p>
            </div>
          </div>
          <span className="text-[24px] font-black text-text-main">{data.declineSignalCount}</span>
        </div>
      </div>

      {/* OpenRouter AI Model Routing & Fallback Control */}
      <div className="bg-white rounded-2xl border border-border-light p-6 shadow-sm space-y-6">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 border-b border-slate-100 pb-4">
          <div className="flex items-center gap-3">
            <div className="p-2.5 rounded-xl bg-violet-50 text-violet-600">
              <Cpu className="w-5 h-5" />
            </div>
            <div>
              <h2 className="text-base font-black text-slate-900">AI Model Routing & Fallback Engine</h2>
              <p className="text-xs text-slate-400 mt-0.5">
                Configure primary and cascading free-tier OpenRouter models for AI evaluation and communication grading.
              </p>
            </div>
          </div>
          <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-black bg-emerald-50 text-emerald-700 border border-emerald-200">
            <Sparkles className="w-3.5 h-3.5 text-emerald-600" />
            100% Free Tier Chain
          </span>
        </div>

        {aiConfigMessage && (
          <div
            className={`p-3.5 rounded-xl text-xs font-bold flex items-center justify-between ${
              aiConfigMessage.success
                ? 'bg-emerald-50 text-emerald-800 border border-emerald-200'
                : 'bg-red-50 text-red-800 border border-red-200'
            }`}
          >
            <span>{aiConfigMessage.text}</span>
            <button onClick={() => setAiConfigMessage(null)} className="underline text-[11px]">
              Dismiss
            </button>
          </div>
        )}

        <div className="grid gap-6 md:grid-cols-2">
          {/* Main Model Selector */}
          <div className="space-y-3">
            <label className="block text-xs font-black uppercase tracking-wider text-slate-500">
              Primary Active Model
            </label>
            <select
              value={mainModel}
              onChange={(e) => setMainModel(e.target.value)}
              className="w-full rounded-xl border border-slate-200 bg-slate-50/50 px-4 py-3 text-xs font-bold text-slate-900 outline-none focus:border-violet-500 focus:bg-white transition-all"
            >
              {DEFAULT_FREE_MODELS.map((m) => (
                <option key={m} value={m}>
                  {m}
                </option>
              ))}
            </select>
            <p className="text-[11px] text-slate-400">
              This model receives incoming AI requests first. If it rate-limits or times out, the system cascades to fallbacks.
            </p>

            {/* Test Connection Button */}
            <div className="pt-2 flex items-center gap-3">
              <button
                type="button"
                onClick={handleTestAiModel}
                disabled={testingModel}
                className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 text-xs font-bold transition-all disabled:opacity-50"
              >
                <Play className="w-3.5 h-3.5 text-violet-600" />
                {testingModel ? 'Pinging Model…' : 'Test Model Connection'}
              </button>
              {aiTestResult && (
                <span className="text-xs font-semibold text-slate-700 truncate max-w-xs">{aiTestResult}</span>
              )}
            </div>
          </div>

          {/* Fallback Models Selection */}
          <div className="space-y-3">
            <div className="flex items-center justify-between">
              <label className="block text-xs font-black uppercase tracking-wider text-slate-500">
                Fallback Models Queue ({fallbackModels.length} active)
              </label>
              <span className="text-[11px] font-semibold text-violet-600">At least 5 recommended</span>
            </div>

            <div className="space-y-2 max-h-48 overflow-y-auto p-1">
              {DEFAULT_FREE_MODELS.map((m) => {
                const isSelected = fallbackModels.includes(m);
                return (
                  <div
                    key={m}
                    onClick={() => toggleFallbackModel(m)}
                    className={`flex items-center justify-between p-2.5 rounded-xl border text-xs font-medium cursor-pointer transition-all ${
                      isSelected
                        ? 'bg-violet-50/70 border-violet-200 text-violet-900'
                        : 'bg-slate-50/40 border-slate-100 text-slate-500 hover:bg-slate-100/50'
                    }`}
                  >
                    <span className="truncate pr-2 font-mono text-[11px]">{m}</span>
                    <span
                      className={`w-4 h-4 rounded-full flex items-center justify-center text-[10px] font-black shrink-0 ${
                        isSelected ? 'bg-violet-600 text-white' : 'border border-slate-300'
                      }`}
                    >
                      {isSelected ? '✓' : ''}
                    </span>
                  </div>
                );
              })}
            </div>

            {/* Custom Model Input */}
            <form onSubmit={handleAddCustomModel} className="flex gap-2 pt-1">
              <input
                type="text"
                placeholder="Add custom free model ID..."
                value={customModelInput}
                onChange={(e) => setCustomModelInput(e.target.value)}
                className="flex-1 px-3 py-2 text-xs rounded-xl border border-slate-200 outline-none focus:border-violet-500 font-mono"
              />
              <button
                type="submit"
                disabled={!customModelInput.trim()}
                className="px-3 py-2 rounded-xl bg-slate-100 hover:bg-slate-200 text-xs font-bold text-slate-700 disabled:opacity-50"
              >
                Add
              </button>
            </form>
          </div>
        </div>

        {/* Save Bar */}
        <div className="pt-4 border-t border-slate-100 flex items-center justify-between">
          <p className="text-xs text-slate-400">
            Chain order: Primary model &rarr; {fallbackModels.slice(0, 3).join(', ')} ...
          </p>
          <button
            onClick={handleSaveAiConfig}
            disabled={savingModels}
            className="inline-flex items-center gap-2 px-6 py-3 rounded-xl bg-violet-600 hover:bg-violet-700 text-white font-black text-xs transition-colors shadow-sm disabled:opacity-50"
          >
            <Save className="w-4 h-4" />
            {savingModels ? 'Saving Models…' : 'Save AI Configuration'}
          </button>
        </div>
      </div>
    </div>
  );
}
