'use client';

import React, { useState, useEffect } from 'react';
import Editor from '@monaco-editor/react';
import { Play, Check, ChevronLeft, Loader2 } from 'lucide-react';
import Link from 'next/link';

const EMPTY_STARTER = '# Read from stdin and print the exact required output.\n'

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
  const [isEvaluating, setIsEvaluating] = useState(false);
  const [result, setResult] = useState<any>(null);

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
        const { data: questData } = await (supabase as any)
          .from('quests')
          .select('*')
          .eq('id', questId)
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

  const handleRun = async () => {
    setIsEvaluating(true);
    setOutput('Running test case in sandbox...');
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
        let out = data.stdout || '';
        if (data.stderr) out += '\n' + data.stderr;
        setOutput(out || '(program completed with no output)');
      } else {
        setOutput('Error: ' + (data.error || 'Execution failed.'));
      }
    } catch (error) {
      setOutput(`Error: ${error instanceof Error ? error.message : 'Execution failed.'}`);
    }
    setIsEvaluating(false);
  };

  const handleSubmit = async () => {
    setIsEvaluating(true);
    setOutput('Verifying against hidden test cases & AI evaluation...');
    setResult(null);
    try {
      const res = await fetch('/api/codebox/submit', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ questId, code, language })
      });
      
      const data = await res.json();
      if (!res.ok) throw new Error(data.error || 'Submission could not be verified.');
      setResult(data);
      if (data.is_verified_complete) {
        setOutput('Verification Passed! ✅ All test cases passed.');
      } else {
        setOutput(`Verification status: ${data.verdict}\nTests passed: ${data.test_results?.passed_count ?? 0}/${data.test_results?.total_count ?? 0}${data.message ? `\n${data.message}` : ''}`);
      }
    } catch (error) {
      setOutput(`Submission error: ${error instanceof Error ? error.message : 'Verification failed.'}`);
    }
    setIsEvaluating(false);
  };

  if (loading) {
    return <div className="min-h-screen flex items-center justify-center bg-gray-50 text-gray-500 font-sans">Loading CodeBox...</div>;
  }

  if (loadError || !quest) {
    return <div className="grid min-h-screen place-items-center bg-gray-50 p-6"><div className="max-w-md rounded-2xl border border-gray-200 bg-white p-8 text-center"><h1 className="text-xl font-bold text-gray-900">Quest unavailable</h1><p className="mt-2 text-sm text-gray-600">{loadError}</p><Link href="/student/train" className="mt-5 inline-block font-bold text-primary-purple">Return to Train</Link></div></div>;
  }

  return (
    <div className="flex min-h-screen flex-col bg-gray-100 font-sans lg:h-screen">
      {/* Header */}
      <header className="min-h-14 bg-white border-b border-gray-200 flex flex-wrap items-center justify-between gap-3 px-4 py-3 sm:px-6 shrink-0">
        <div className="flex items-center gap-4">
          <Link href="/student" className="text-gray-400 hover:text-gray-900 transition-colors">
            <ChevronLeft className="w-5 h-5" />
          </Link>
          <div>
            <h1 className="font-bold text-gray-900 leading-tight">{quest.title}</h1>
            <p className="text-[11px] font-medium text-gray-500 uppercase tracking-wide">Coding Quest</p>
          </div>
        </div>
        <div className="flex items-center gap-3">
          <select 
            value={language}
            onChange={(e) => handleLanguageChange(e.target.value)}
            className="text-sm border border-gray-300 rounded-md px-3 py-1.5 focus:outline-none focus:ring-2 focus:ring-primary-purple font-medium text-gray-800 bg-white"
          >
            {quest.allowed_languages.map((l: string) => (
              <option key={l} value={l}>{l.toUpperCase()}</option>
            ))}
          </select>
          <button 
            onClick={handleRun}
            disabled={isEvaluating}
            className="flex items-center gap-1.5 px-4 py-1.5 bg-gray-100 hover:bg-gray-200 text-gray-800 font-semibold text-sm rounded-md transition-colors disabled:opacity-50"
          >
            {isEvaluating ? <Loader2 className="w-4 h-4 animate-spin" /> : <Play className="w-4 h-4" />}
            Run
          </button>
          <button 
            onClick={handleSubmit}
            disabled={isEvaluating}
            className="flex items-center gap-1.5 px-4 py-1.5 bg-primary-purple hover:bg-violet-700 text-white font-semibold text-sm rounded-md transition-colors disabled:opacity-50 shadow-sm"
          >
            <Check className="w-4 h-4" />
            Submit
          </button>
        </div>
      </header>

      {/* Main Content */}
      <div className="flex flex-1 flex-col overflow-visible lg:flex-row lg:overflow-hidden">
        {/* Left Panel: Problem Statement */}
        <div className="w-full bg-white border-r border-gray-200 p-5 sm:p-6 overflow-y-auto lg:w-[40%]">
          <h2 className="text-xl font-bold text-gray-900 mb-4">Problem Statement</h2>
          <div className="prose prose-sm text-gray-700 max-w-none whitespace-pre-wrap leading-relaxed">
            {quest.problem_md}
          </div>
          
          <div className="mt-8 border-t border-gray-100 pt-6">
            <h3 className="text-sm font-bold text-gray-900 mb-3 uppercase tracking-wide">Visible Sample Cases</h3>
            <div className="space-y-4">
              {quest.sample_cases_json?.map((tc: any, i: number) => (
                <div key={i} className="bg-gray-50 rounded-lg p-4 border border-gray-200/80">
                  <div className="mb-2">
                    <span className="text-[11px] font-bold text-gray-500 uppercase tracking-wide">Input</span>
                    <pre className="mt-1 text-sm text-gray-800 bg-white p-2.5 rounded border border-gray-200 font-mono">{tc.input}</pre>
                  </div>
                  <div>
                    <span className="text-[11px] font-bold text-gray-500 uppercase tracking-wide">Expected Output</span>
                    <pre className="mt-1 text-sm text-gray-800 bg-white p-2.5 rounded border border-gray-200 font-mono">{tc.expected_output}</pre>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Right Panel: Editor & Output */}
        <div className="flex min-h-[720px] flex-1 flex-col bg-[#1e1e1e] lg:min-h-0">
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
                padding: { top: 16 }
              }}
            />
          </div>
          
          {/* Output Terminal */}
          <div className="h-[30%] bg-gray-900 border-t border-gray-800 flex flex-col">
            <div className="flex items-center justify-between px-4 py-2 bg-gray-800/50 border-b border-gray-800 shrink-0">
              <span className="text-[11px] font-bold text-gray-400 uppercase tracking-wide">Execution Output</span>
            </div>
            <div className="flex-1 p-4 overflow-y-auto font-mono">
              <pre className="text-sm text-gray-200 whitespace-pre-wrap">{output || 'Click "Run" to test your solution against visible test cases.'}</pre>
              
              {result?.ai_evaluation && (
                <div className="mt-4 p-4 bg-violet-950/40 border border-violet-700/50 rounded-lg">
                  <h4 className="text-xs font-bold text-violet-300 uppercase tracking-wide mb-2 flex items-center gap-2">
                    <BrainCircuit className="w-4 h-4" /> AI Evaluation (Quality Score: {result.ai_evaluation.quality_score}/10)
                  </h4>
                  <p className="text-sm text-gray-200 mb-2 font-sans">{result.ai_evaluation.brief_feedback}</p>
                  <div className="flex gap-4 text-xs text-violet-300 font-mono">
                    <span>Time Complexity: {result.ai_evaluation.time_complexity}</span>
                    <span>Space Complexity: {result.ai_evaluation.space_complexity}</span>
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
