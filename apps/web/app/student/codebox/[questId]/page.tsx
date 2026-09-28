'use client';

import React, { useState, useEffect, useCallback } from 'react';
import Editor from '@monaco-editor/react';
import { Play, Check, ChevronLeft, Loader2, RefreshCw } from 'lucide-react';
import Link from 'next/link';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';

const EMPTY_STARTER = '# Read from stdin and print the exact required output.\n'

// ── Markdown renderer with proper heading hierarchy ──────────────────────────
function ProblemMarkdown({ content }: { content: string }) {
  return (
    <ReactMarkdown
      remarkPlugins={[remarkGfm]}
      components={{
        // ## → large section heading
        h2: ({ children }) => (
          <h2 className="text-xl font-extrabold text-gray-900 mt-6 mb-2 leading-snug">
            {children}
          </h2>
        ),
        // ### → subsection (Input / Output / Constraints)
        h3: ({ children }) => (
          <h3 className="text-[13px] font-black text-gray-700 mt-5 mb-1.5 uppercase tracking-widest">
            {children}
          </h3>
        ),
        // #### → minor label
        h4: ({ children }) => (
          <h4 className="text-sm font-bold text-gray-600 mt-4 mb-1">
            {children}
          </h4>
        ),
        p: ({ children }) => (
          <p className="text-sm text-gray-700 leading-relaxed mb-3">{children}</p>
        ),
        code: ({ children, className }) => {
          const isBlock = className?.includes('language-')
          return isBlock ? (
            <pre className="bg-gray-50 border border-gray-200 rounded-lg px-4 py-3 text-sm font-mono text-gray-800 overflow-x-auto my-3 whitespace-pre-wrap">
              <code>{children}</code>
            </pre>
          ) : (
            <code className="bg-gray-100 text-orange-600 font-mono text-[13px] px-1.5 py-0.5 rounded">
              {children}
            </code>
          )
        },
        strong: ({ children }) => (
          <strong className="font-bold text-gray-900">{children}</strong>
        ),
        ul: ({ children }) => (
          <ul className="list-disc list-inside text-sm text-gray-700 space-y-1 mb-3 pl-2">
            {children}
          </ul>
        ),
        ol: ({ children }) => (
          <ol className="list-decimal list-inside text-sm text-gray-700 space-y-1 mb-3 pl-2">
            {children}
          </ol>
        ),
        blockquote: ({ children }) => (
          <blockquote className="border-l-4 border-orange-300 pl-4 italic text-sm text-gray-600 my-3">
            {children}
          </blockquote>
        ),
        hr: () => <hr className="border-gray-200 my-4" />,
      }}
    >
      {content}
    </ReactMarkdown>
  )
}

export default function CodeBoxPage({ params }: { params: Promise<{ questId: string }> }) {
  const [questId, setQuestId] = useState<string>('');

  useEffect(() => {
    params.then(p => setQuestId(p.questId));
  }, [params]);

  const [quest, setQuest] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [language, setLanguage] = useState('python');
  const [code, setCode] = useState(EMPTY_STARTER);
  const [loadError, setLoadError] = useState('');

  const [output, setOutput] = useState('');
  const [outputType, setOutputType] = useState<'idle' | 'running' | 'success' | 'error'>('idle');
  const [isEvaluating, setIsEvaluating] = useState(false);
  const [result, setResult] = useState<any>(null);
  const [runRetryCount, setRunRetryCount] = useState(0);

  // Suppress Monaco editor internal cancellation warnings in Next dev
  useEffect(() => {
    const handleRejection = (event: PromiseRejectionEvent) => {
      if (event?.reason?.msg === 'operation is manually canceled' || event?.reason?.type === 'cancelation') {
        event.preventDefault();
      }
    };
    window.addEventListener('unhandledrejection', handleRejection);
    return () => window.removeEventListener('unhandledrejection', handleRejection);
  }, []);

  const handleLanguageChange = (newLang: string) => {
    setLanguage(newLang);
    setCode(quest?.starter_code_json?.[newLang] || '');
  };

  useEffect(() => {
    if (!questId) return;

    const fetchQuest = async () => {
      try {
        const { createClient } = await import('@/lib/supabase/client');
        const supabase = createClient();
        const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(questId);
        const { data: questData } = await (supabase as any)
          .from('quests')
          .select('*')
          .eq(isUuid ? 'id' : 'slug', questId)
          .maybeSingle();

        if (questData) {
          setQuest(questData);
          setCode(questData.starter_code_json?.python || EMPTY_STARTER);
          setLoading(false);
          return;
        }
      } catch (err) {
        console.warn('Could not load quest from Supabase:', err);
      }
      setLoadError('This quest is unavailable or is not assigned to your batch.');
      setLoading(false);
    };
    fetchQuest();
  }, [questId]);

  const handleRun = useCallback(async () => {
    setIsEvaluating(true);
    setOutputType('running');
    setOutput('Running your code against the visible test case...');
    try {
      const sample = quest?.sample_cases_json?.[0];
      if (!sample) throw new Error('This quest has no visible sample case.');

      const res = await fetch('/api/codebox/run', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ code, language, stdin: sample.input })
      });

      const data = await res.json();
      if (res.ok) {
        const stdout = data.stdout?.trim() || '';
        const stderr = data.stderr?.trim() || '';
        const expected = String(sample.expected_output || '').trim();
        const passed = stdout === expected && data.code === 0;

        let out = stdout || '(no stdout output)';
        if (stderr) out += `\n\n--- stderr ---\n${stderr}`;
        if (data.code !== 0) out += `\n\nProcess exited with code ${data.code}`;

        setOutput(out);
        setOutputType(passed ? 'success' : 'error');
        setRunRetryCount(0);
      } else {
        // Server returned error — might be sandbox busy
        const errMsg = data.error || 'Execution failed.';
        setOutput(errMsg);
        setOutputType('error');
        if (res.status === 503) setRunRetryCount(c => c + 1);
      }
    } catch (error) {
      setOutput(`Network error: ${error instanceof Error ? error.message : 'Check your connection.'}`);
      setOutputType('error');
    }
    setIsEvaluating(false);
  }, [code, language, quest]);

  const handleSubmit = async () => {
    setIsEvaluating(true);
    setOutputType('running');
    setOutput('Verifying against hidden test cases & AI evaluation...');
    setResult(null);
    try {
      const res = await fetch('/api/codebox/submit', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ questId: quest.id, code, language })
      });

      const data = await res.json();
      if (!res.ok) throw new Error(data.error || 'Submission could not be verified.');
      setResult(data);
      if (data.is_verified_complete) {
        setOutput('✅ All test cases passed! Submission verified.');
        setOutputType('success');
      } else {
        setOutput(
          `Verdict: ${data.verdict}\nTests passed: ${data.test_results?.passed_count ?? 0}/${data.test_results?.total_count ?? 0}${data.message ? `\n\n${data.message}` : ''}`
        );
        setOutputType(data.verdict === 'pending' ? 'running' : 'error');
      }
    } catch (error) {
      setOutput(`Submission error: ${error instanceof Error ? error.message : 'Verification failed.'}`);
      setOutputType('error');
    }
    setIsEvaluating(false);
  };

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="flex flex-col items-center gap-3 text-gray-500">
          <Loader2 className="w-7 h-7 animate-spin text-orange-500" />
          <span className="text-sm font-medium">Loading CodeBox…</span>
        </div>
      </div>
    );
  }

  if (loadError || !quest) {
    return (
      <div className="grid min-h-screen place-items-center bg-gray-50 p-6">
        <div className="max-w-md rounded-2xl border border-gray-200 bg-white p-8 text-center shadow-sm">
          <h1 className="text-xl font-bold text-gray-900">Quest unavailable</h1>
          <p className="mt-2 text-sm text-gray-600">{loadError}</p>
          <Link href="/student/codebox" className="mt-5 inline-block font-bold text-orange-500 hover:text-orange-600">
            Return to CodeBox
          </Link>
        </div>
      </div>
    );
  }

  // Determine output panel colors
  const outputColors = {
    idle:    { bg: 'bg-gray-900',   text: 'text-gray-300',  label: 'text-gray-400' },
    running: { bg: 'bg-gray-900',   text: 'text-yellow-300', label: 'text-yellow-400' },
    success: { bg: 'bg-gray-900',   text: 'text-green-300',  label: 'text-green-400' },
    error:   { bg: 'bg-gray-900',   text: 'text-red-300',    label: 'text-red-400' },
  }[outputType];

  return (
    <div className="flex min-h-screen flex-col bg-gray-100 font-sans lg:h-screen">
      {/* ── Header ─────────────────────────────────────────────────────── */}
      <header className="min-h-14 bg-white border-b border-gray-200 flex flex-wrap items-center justify-between gap-3 px-4 py-3 sm:px-6 shrink-0 shadow-sm">
        <div className="flex items-center gap-4">
          <Link href="/student/codebox" className="text-gray-400 hover:text-gray-900 transition-colors">
            <ChevronLeft className="w-5 h-5" />
          </Link>
          <div>
            <h1 className="font-bold text-gray-900 leading-tight">{quest.title}</h1>
            <p className="text-[11px] font-medium text-gray-500 uppercase tracking-wide">Coding Quest · PSGMX</p>
          </div>
        </div>
        <div className="flex items-center gap-3">
          <select
            value={language}
            onChange={(e) => handleLanguageChange(e.target.value)}
            className="text-sm border border-gray-300 rounded-lg px-3 py-1.5 focus:outline-none focus:ring-2 focus:ring-orange-400 font-medium text-gray-800 bg-white"
          >
            {quest.allowed_languages.map((l: string) => (
              <option key={l} value={l}>{l.toUpperCase()}</option>
            ))}
          </select>
          <button
            onClick={handleRun}
            disabled={isEvaluating}
            className="flex items-center gap-1.5 px-4 py-1.5 bg-gray-100 hover:bg-gray-200 text-gray-800 font-semibold text-sm rounded-lg transition-colors disabled:opacity-50"
          >
            {isEvaluating ? <Loader2 className="w-4 h-4 animate-spin" /> : <Play className="w-4 h-4 fill-gray-700" />}
            Run
          </button>
          <button
            onClick={handleSubmit}
            disabled={isEvaluating}
            className="flex items-center gap-1.5 px-4 py-1.5 bg-orange-500 hover:bg-orange-600 text-white font-semibold text-sm rounded-lg transition-colors disabled:opacity-50 shadow-sm"
          >
            <Check className="w-4 h-4" />
            Submit
          </button>
        </div>
      </header>

      {/* ── Main Content ────────────────────────────────────────────────── */}
      <div className="flex flex-1 flex-col overflow-visible lg:flex-row lg:overflow-hidden">

        {/* Left Panel: Problem Statement */}
        <div className="w-full bg-white border-r border-gray-200 overflow-y-auto lg:w-[42%]">

          {/* Problem description */}
          <div className="p-5 sm:p-6">
            <ProblemMarkdown content={quest.problem_md} />
          </div>

          {/* Visible sample cases */}
          <div className="border-t border-gray-100 px-5 py-5 sm:px-6">
            <h3 className="text-[11px] font-black text-gray-500 uppercase tracking-widest mb-3">
              Visible Sample Cases
            </h3>
            <div className="space-y-3">
              {quest.sample_cases_json?.map((tc: any, i: number) => (
                <div key={i} className="rounded-xl border border-gray-200 overflow-hidden">
                  <div className="px-4 py-2 bg-gray-50 border-b border-gray-200">
                    <span className="text-[10px] font-black text-gray-400 uppercase tracking-widest">
                      Case {i + 1}
                    </span>
                  </div>
                  <div className="grid grid-cols-2 divide-x divide-gray-200">
                    <div className="p-3">
                      <span className="block text-[10px] font-bold text-gray-400 uppercase mb-1.5">Input</span>
                      <pre className="text-sm text-gray-800 font-mono whitespace-pre-wrap">{tc.input}</pre>
                    </div>
                    <div className="p-3">
                      <span className="block text-[10px] font-bold text-gray-400 uppercase mb-1.5">Expected</span>
                      <pre className="text-sm text-gray-800 font-mono whitespace-pre-wrap">{tc.expected_output}</pre>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Right Panel: Editor & Output */}
        <div className="flex min-h-[720px] flex-1 flex-col bg-[#1e1e1e] lg:min-h-0">
          {/* Monaco Editor */}
          <div className="min-h-[480px] flex-1 relative">
            <Editor
              height="100%"
              language={language === 'c' || language === 'cpp' ? 'cpp' : language}
              theme="vs-dark"
              value={code}
              onChange={(val: string | undefined) => setCode(val || '')}
              options={{
                minimap: { enabled: false },
                fontSize: 14,
                fontFamily: "'JetBrains Mono', 'Fira Code', Consolas, monospace",
                scrollBeyondLastLine: false,
                padding: { top: 16 },
                lineNumbersMinChars: 3,
                renderLineHighlight: 'all',
              }}
            />
          </div>

          {/* Output Terminal */}
          <div className="h-[32%] bg-[#0d1117] border-t border-gray-800 flex flex-col">
            <div className="flex items-center justify-between px-4 py-2 bg-gray-800/60 border-b border-gray-800 shrink-0">
              <span className={`text-[11px] font-black uppercase tracking-widest ${outputColors.label}`}>
                {outputType === 'running' ? '⏳ Running…' :
                 outputType === 'success' ? '✅ Output' :
                 outputType === 'error'   ? '❌ Output' :
                 'Execution Output'}
              </span>
              {/* Retry button when sandbox is busy */}
              {outputType === 'error' && runRetryCount > 0 && (
                <button
                  onClick={handleRun}
                  disabled={isEvaluating}
                  className="flex items-center gap-1 text-[11px] font-bold text-yellow-400 hover:text-yellow-300 transition-colors"
                >
                  <RefreshCw className="w-3 h-3" />
                  Retry
                </button>
              )}
            </div>
            <div className="flex-1 p-4 overflow-y-auto font-mono">
              <pre className={`text-sm whitespace-pre-wrap ${outputColors.text}`}>
                {output || 'Click "Run" to test your solution against the visible test case.'}
              </pre>

              {result?.ai_evaluation && (
                <div className="mt-4 p-4 bg-violet-950/40 border border-violet-700/50 rounded-xl">
                  <h4 className="text-xs font-black text-violet-300 uppercase tracking-widest mb-2 flex items-center gap-2">
                    <BrainCircuit className="w-4 h-4" />
                    AI Evaluation · Quality Score: {result.ai_evaluation.quality_score}/10
                  </h4>
                  <p className="text-sm text-gray-200 mb-3 font-sans leading-relaxed">
                    {result.ai_evaluation.brief_feedback}
                  </p>
                  <div className="flex gap-6 text-xs text-violet-300 font-mono">
                    <span>Time: {result.ai_evaluation.time_complexity}</span>
                    <span>Space: {result.ai_evaluation.space_complexity}</span>
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function BrainCircuit(props: any) {
  return (
    <svg {...props} xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 4.5a2.5 2.5 0 0 0-4.96-.46 2.5 2.5 0 0 0-1.98 3 2.5 2.5 0 0 0-1.32 4.24 3 3 0 0 0 .34 5.58 2.5 2.5 0 0 0 2.96 3.08 2.5 2.5 0 0 0 4.91.05L12 20V4.5Z"/>
      <path d="M16 8V5c0-1.1.9-2 2-2"/>
      <path d="M12 13h4"/>
      <path d="M12 17h6"/>
      <path d="M19 13v4"/>
      <path d="M22 13a2 2 0 1 0-4 0 2 2 0 0 0 4 0Z"/>
      <path d="M19 5a2 2 0 1 0 0-4 2 2 0 0 0 0 4Z"/>
    </svg>
  );
}
