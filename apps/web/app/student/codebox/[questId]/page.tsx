'use client';

import React, { useState, useEffect, useRef } from 'react';
import Editor, { useMonaco } from '@monaco-editor/react';
import { Play, Check, ChevronLeft, Loader2, AlertCircle } from 'lucide-react';
import Link from 'next/link';

export default function CodeBoxPage({ params }: { params: { questId: string } }) {
  const [quest, setQuest] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [code, setCode] = useState('// Write your solution here...\n');
  const [language, setLanguage] = useState('python');
  
  const [output, setOutput] = useState('');
  const [isEvaluating, setIsEvaluating] = useState(false);
  const [result, setResult] = useState<any>(null);
  
  const monaco = useMonaco();

  useEffect(() => {
    // In a real app, fetch quest details from Supabase using an API route or client supabase
    const fetchQuest = async () => {
      // Mocked for the demo, since we don't have the client setup in this file
      setQuest({
        id: params.questId,
        title: 'Two Sum',
        problem_md: 'Given an array of integers `nums` and an integer `target`, return indices of the two numbers such that they add up to `target`.\n\nYou may assume that each input would have exactly one solution, and you may not use the same element twice.\n\nYou can return the answer in any order.',
        allowed_languages: ['python', 'java', 'cpp', 'javascript'],
        sample_cases_json: [
          { input: '[2,7,11,15]\n9', expected_output: '[0,1]' },
          { input: '[3,2,4]\n6', expected_output: '[1,2]' }
        ]
      });
      setLoading(false);
    };
    fetchQuest();
  }, [params.questId]);

  const handleRun = async () => {
    setIsEvaluating(true);
    setOutput('Running...');
    try {
      // Run against visible sample case (just using the first one for the demo)
      const sample = quest.sample_cases_json?.[0] || { input: '' };
      
      const res = await fetch('/api/codebox/run', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ code, language, stdin: sample.input })
      });
      
      const data = await res.json();
      if (res.ok) {
        let out = data.stdout || '';
        if (data.stderr) out += '\nError:\n' + data.stderr;
        setOutput(out || 'Executed with no output.');
      } else {
        setOutput('Error: ' + data.error);
      }
    } catch (e) {
      setOutput('Failed to run code.');
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
        body: JSON.stringify({ questId: params.questId, code, language })
      });
      
      const data = await res.json();
      setResult(data);
      if (data.is_verified_complete) {
        setOutput('Verification Passed! ✅');
      } else {
        setOutput(`Verification Failed ❌\nTests Passed: ${data.test_results?.passed_count}/${data.test_results?.total_count}`);
      }
    } catch (e) {
      setOutput('Failed to submit code.');
    }
    setIsEvaluating(false);
  };

  if (loading) {
    return <div className="min-h-screen flex items-center justify-center bg-gray-50 text-gray-500">Loading CodeBox...</div>;
  }

  return (
    <div className="flex flex-col h-screen bg-gray-100 font-sans">
      {/* Header */}
      <header className="h-14 bg-white border-b border-gray-200 flex items-center justify-between px-6 shrink-0">
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
            onChange={(e) => setLanguage(e.target.value)}
            className="text-sm border border-gray-300 rounded-md px-3 py-1.5 focus:outline-none focus:ring-2 focus:ring-brand-500"
          >
            {quest.allowed_languages.map((l: string) => (
              <option key={l} value={l}>{l.toUpperCase()}</option>
            ))}
          </select>
          <button 
            onClick={handleRun}
            disabled={isEvaluating}
            className="flex items-center gap-1.5 px-4 py-1.5 bg-gray-100 hover:bg-gray-200 text-gray-800 font-medium text-sm rounded-md transition-colors disabled:opacity-50"
          >
            {isEvaluating ? <Loader2 className="w-4 h-4 animate-spin" /> : <Play className="w-4 h-4" />}
            Run
          </button>
          <button 
            onClick={handleSubmit}
            disabled={isEvaluating}
            className="flex items-center gap-1.5 px-4 py-1.5 bg-brand-500 hover:bg-brand-600 text-white font-medium text-sm rounded-md transition-colors disabled:opacity-50 shadow-sm"
          >
            <Check className="w-4 h-4" />
            Submit
          </button>
        </div>
      </header>

      {/* Main Content */}
      <div className="flex-1 flex overflow-hidden">
        {/* Left Panel: Problem Statement */}
        <div className="w-[40%] bg-white border-r border-gray-200 p-6 overflow-y-auto">
          <h2 className="text-xl font-bold text-gray-900 mb-4">Problem Statement</h2>
          <div className="prose prose-sm text-gray-700 max-w-none whitespace-pre-wrap">
            {quest.problem_md}
          </div>
          
          <div className="mt-8 border-t border-gray-100 pt-6">
            <h3 className="text-sm font-bold text-gray-900 mb-3 uppercase tracking-wide">Visible Sample Cases</h3>
            <div className="space-y-4">
              {quest.sample_cases_json?.map((tc: any, i: number) => (
                <div key={i} className="bg-gray-50 rounded-lg p-4 border border-gray-100">
                  <div className="mb-2">
                    <span className="text-[11px] font-bold text-gray-500 uppercase">Input</span>
                    <pre className="mt-1 text-sm text-gray-800 bg-white p-2 rounded border border-gray-200 font-mono">{tc.input}</pre>
                  </div>
                  <div>
                    <span className="text-[11px] font-bold text-gray-500 uppercase">Expected Output</span>
                    <pre className="mt-1 text-sm text-gray-800 bg-white p-2 rounded border border-gray-200 font-mono">{tc.expected_output}</pre>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Right Panel: Editor & Output */}
        <div className="flex-1 flex flex-col bg-[#1e1e1e]">
          <div className="flex-1 relative">
            <Editor
              height="100%"
              language={language === 'c' || language === 'cpp' ? 'cpp' : language}
              theme="vs-dark"
              value={code}
              onChange={(val) => setCode(val || '')}
              options={{
                minimap: { enabled: false },
                fontSize: 14,
                fontFamily: "'JetBrains Mono', 'Fira Code', monospace",
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
            <div className="flex-1 p-4 overflow-y-auto">
              <pre className="text-sm text-gray-300 font-mono whitespace-pre-wrap">{output}</pre>
              
              {result?.ai_evaluation && (
                <div className="mt-4 p-4 bg-brand-900/20 border border-brand-500/30 rounded-lg">
                  <h4 className="text-xs font-bold text-brand-400 uppercase tracking-wide mb-2 flex items-center gap-2">
                    <BrainCircuit className="w-4 h-4" /> AI Evaluation (Quality: {result.ai_evaluation.quality_score}/10)
                  </h4>
                  <p className="text-sm text-gray-300 mb-2">{result.ai_evaluation.brief_feedback}</p>
                  <div className="flex gap-4 text-xs text-gray-400 font-mono">
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

// Ensure the icon is imported
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
