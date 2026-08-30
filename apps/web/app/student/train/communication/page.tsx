'use client';

import React, { useState, useRef, useEffect } from 'react';
import { Mic, Square, Play, UploadCloud, CheckCircle2, ChevronLeft, Loader2, BrainCircuit } from 'lucide-react';
import Link from 'next/link';

type PracticePrompt = { id: string; prompt_text: string; category: string; difficulty: string; evaluation_focus: string[] };
type PriorAttempt = { id: string; prompt_text: string; duration_seconds: number; ai_scores_json: any; created_at: string };

export default function CommunicationPracticePage() {
  const [isRecording, setIsRecording] = useState(false);
  const [audioUrl, setAudioUrl] = useState<string | null>(null);
  const [audioBlob, setAudioBlob] = useState<Blob | null>(null);
  const [time, setTime] = useState(0);
  
  const [isUploading, setIsUploading] = useState(false);
  const [result, setResult] = useState<any>(null);
  const [prompts, setPrompts] = useState<PracticePrompt[]>([]);
  const [selectedPromptId, setSelectedPromptId] = useState('');
  const [attempts, setAttempts] = useState<PriorAttempt[]>([]);
  const [loadError, setLoadError] = useState('');

  const mediaRecorderRef = useRef<MediaRecorder | null>(null);
  const chunksRef = useRef<Blob[]>([]);
  const timerRef = useRef<NodeJS.Timeout | null>(null);
  const maxTimeoutRef = useRef<NodeJS.Timeout | null>(null);

  const MAX_TIME = 120; // 2 minutes

  const selectedPrompt = prompts.find((item) => item.id === selectedPromptId);

  useEffect(() => {
    fetch('/api/communication/evaluate').then(async (response) => {
      const data = await response.json();
      if (!response.ok) throw new Error(data.error || 'Practice prompts could not be loaded.');
      setPrompts(data.prompts || []);
      setAttempts(data.attempts || []);
      if (data.prompts?.[0]) setSelectedPromptId(data.prompts[0].id);
    }).catch((error) => setLoadError(error instanceof Error ? error.message : 'Practice prompts could not be loaded.'));
  }, []);

  const stopRecording = React.useCallback(() => {
    if (mediaRecorderRef.current && isRecording) {
      mediaRecorderRef.current.stop();
      setIsRecording(false);
      if (timerRef.current) clearInterval(timerRef.current);
      if (maxTimeoutRef.current) clearTimeout(maxTimeoutRef.current);
    }
  }, [isRecording]);

  const startRecording = async () => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      const mediaRecorder = new MediaRecorder(stream);
      mediaRecorderRef.current = mediaRecorder;
      chunksRef.current = [];

      mediaRecorder.ondataavailable = (e) => {
        if (e.data.size > 0) chunksRef.current.push(e.data);
      };

      mediaRecorder.onstop = () => {
        const blob = new Blob(chunksRef.current, { type: 'audio/webm' }); // Use webm for browser compatibility, backend can convert or handle
        setAudioBlob(blob);
        setAudioUrl(URL.createObjectURL(blob));
        stream.getTracks().forEach(track => track.stop());
      };

      mediaRecorder.start();
      setIsRecording(true);
      setTime(0);
      
      timerRef.current = setInterval(() => {
        setTime(prev => prev + 1);
      }, 1000);
      maxTimeoutRef.current = setTimeout(() => {
        if (mediaRecorderRef.current?.state === 'recording') mediaRecorderRef.current.stop();
        setIsRecording(false);
        if (timerRef.current) clearInterval(timerRef.current);
      }, MAX_TIME * 1000);
    } catch (err) {
      console.error('Error accessing microphone', err);
      alert('Could not access microphone. Please check permissions.');
    }
  };

  const resetRecording = () => {
    setAudioUrl(null);
    setAudioBlob(null);
    setTime(0);
    setResult(null);
  };

  const submitAudio = async () => {
    if (!audioBlob || !selectedPrompt) return;
    setIsUploading(true);
    
    try {
      // 1. Convert blob to File or send as form data
      const formData = new FormData();
      formData.append('audio', audioBlob, 'recording.webm');
      formData.append('prompt_id', selectedPrompt.id);
      formData.append('duration_seconds', String(time));

      // 2. Call our API route which handles STT and AI evaluation
      const res = await fetch('/api/communication/evaluate', {
        method: 'POST',
        body: formData,
      });

      const data = await res.json();
      
      if (res.ok) {
        setResult(data);
      } else {
        alert(data.error || 'Failed to evaluate audio.');
      }
    } catch (err) {
      console.error(err);
      alert('Error submitting audio');
    }
    
    setIsUploading(false);
  };

  const formatTime = (seconds: number) => {
    const m = Math.floor(seconds / 60);
    const s = seconds % 60;
    return `${m}:${s < 10 ? '0' : ''}${s}`;
  };

  return (
    <div className="min-h-screen bg-gray-50 pb-20">
      <header className="bg-white border-b border-gray-200 px-6 py-4 flex items-center gap-4 sticky top-0 z-10">
        <Link href="/student" className="text-gray-400 hover:text-gray-900 transition-colors">
          <ChevronLeft className="w-5 h-5" />
        </Link>
        <div>
          <h1 className="text-xl font-bold text-gray-900 leading-tight">Communication Practice</h1>
          <p className="text-xs font-medium text-gray-500 uppercase tracking-wide">Audio only • Max 2 minutes</p>
        </div>
      </header>

      <main className="max-w-2xl mx-auto pt-10 px-6">
        {/* Prompt Card */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6 mb-8 relative overflow-hidden">
          <div className="absolute top-0 left-0 w-1 h-full bg-brand-500"></div>
          <h2 className="text-sm font-bold text-gray-500 uppercase tracking-wider mb-2">Practice Prompt</h2>
          {loadError ? <p className="text-sm font-semibold text-red-600">{loadError}</p> : (
            <>
              <select value={selectedPromptId} onChange={(event) => { setSelectedPromptId(event.target.value); resetRecording(); }} className="mb-4 w-full rounded-lg border border-gray-200 bg-gray-50 px-3 py-2 text-sm font-bold text-gray-700">
                {prompts.map((item) => <option key={item.id} value={item.id}>{item.category.replace('_', ' ')} · {item.difficulty}</option>)}
              </select>
              <p className="text-lg font-medium text-gray-900 leading-relaxed">{selectedPrompt?.prompt_text || 'Loading a verified prompt…'}</p>
              {selectedPrompt?.evaluation_focus?.length ? <p className="mt-3 text-xs font-semibold text-gray-500">Focus: {selectedPrompt.evaluation_focus.join(' · ')}</p> : null}
            </>
          )}
        </div>

        {/* Recording Interface */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-8 flex flex-col items-center justify-center min-h-[300px]">
          
          {!audioUrl && (
            <>
              <div className="text-5xl font-mono text-gray-800 mb-8 tabular-nums">
                {formatTime(time)} <span className="text-gray-400 text-2xl">/ 2:00</span>
              </div>
              
              {isRecording ? (
                <button 
                  onClick={stopRecording}
                  className="w-20 h-20 bg-red-50 hover:bg-red-100 text-red-500 rounded-full flex items-center justify-center transition-transform hover:scale-105 active:scale-95"
                >
                  <Square className="w-8 h-8 fill-current" />
                </button>
              ) : (
                <button 
                  onClick={startRecording}
                  disabled={!selectedPrompt}
                  className="w-20 h-20 bg-brand-500 hover:bg-brand-600 text-white rounded-full flex items-center justify-center shadow-lg transition-transform hover:scale-105 active:scale-95"
                >
                  <Mic className="w-8 h-8" />
                </button>
              )}
              <p className="mt-6 text-sm text-gray-500 font-medium">
                {isRecording ? 'Recording in progress...' : 'Tap microphone to start recording'}
              </p>
            </>
          )}

          {/* Review and Submit Interface */}
          {audioUrl && !result && (
            <div className="w-full flex flex-col items-center">
              <audio src={audioUrl} controls className="w-full max-w-md mb-8" />
              
              <div className="flex gap-4">
                <button 
                  onClick={resetRecording}
                  disabled={isUploading}
                  className="px-6 py-2.5 text-sm font-bold text-gray-600 hover:bg-gray-100 rounded-lg transition-colors disabled:opacity-50"
                >
                  Retake
                </button>
                <button 
                  onClick={submitAudio}
                  disabled={isUploading}
                  className="px-6 py-2.5 text-sm font-bold text-white bg-brand-500 hover:bg-brand-600 rounded-lg shadow-sm transition-colors flex items-center gap-2 disabled:opacity-50"
                >
                  {isUploading ? <Loader2 className="w-4 h-4 animate-spin" /> : <UploadCloud className="w-4 h-4" />}
                  {isUploading ? 'Evaluating...' : 'Submit for Feedback'}
                </button>
              </div>
              {isUploading && (
                <p className="mt-4 text-xs text-gray-500 animate-pulse">Running Speech-to-Text and AI evaluation...</p>
              )}
            </div>
          )}

          {/* Result Interface */}
          {result && (
            <div className="w-full animate-in fade-in slide-in-from-bottom-4 duration-500">
              <div className="flex items-center gap-3 mb-6 justify-center">
                <div className="w-12 h-12 bg-green-100 text-green-600 rounded-full flex items-center justify-center">
                  <CheckCircle2 className="w-6 h-6" />
                </div>
                <h3 className="text-xl font-bold text-gray-900">Evaluation Complete</h3>
              </div>
              
              <div className="grid grid-cols-3 gap-4 mb-6">
                <div className="bg-gray-50 p-4 rounded-lg border border-gray-100 text-center">
                  <p className="text-xs font-bold text-gray-500 uppercase">Clarity</p>
                  <p className="text-2xl font-black text-brand-600">{result.scores.clarity_score}/10</p>
                </div>
                <div className="bg-gray-50 p-4 rounded-lg border border-gray-100 text-center">
                  <p className="text-xs font-bold text-gray-500 uppercase">Structure</p>
                  <p className="text-2xl font-black text-brand-600">{result.scores.structure_score}/10</p>
                </div>
                <div className="bg-gray-50 p-4 rounded-lg border border-gray-100 text-center">
                  <p className="text-xs font-bold text-gray-500 uppercase">Filler Words</p>
                  <p className="text-2xl font-black text-amber-500">{result.scores.filler_word_count}</p>
                </div>
              </div>

              <div className="bg-brand-50 p-6 rounded-xl border border-brand-100 mb-6">
                <h4 className="flex items-center gap-2 text-sm font-bold text-brand-700 uppercase tracking-wide mb-3">
                  <BrainCircuit className="w-4 h-4" /> AI Feedback
                </h4>
                <p className="text-gray-800 text-sm leading-relaxed mb-4">{result.scores.brief_feedback}</p>
                <div className="bg-white p-4 rounded-lg border border-brand-100">
                  <p className="text-xs font-bold text-brand-600 uppercase mb-1">Suggested Improvement</p>
                  <p className="text-gray-700 text-sm">{result.scores.suggested_improvement}</p>
                </div>
              </div>

              <div className="flex justify-center">
                <button onClick={resetRecording} className="px-6 py-2.5 text-sm font-bold text-gray-600 hover:bg-gray-100 rounded-lg transition-colors">
                  Practice Another Prompt
                </button>
              </div>
            </div>
          )}

        </div>
      </main>
      {attempts.length > 0 && <section className="mx-auto w-full max-w-2xl px-6 pb-12"><h2 className="mb-3 text-sm font-black uppercase tracking-wider text-gray-500">Recent practice</h2><div className="space-y-3">{attempts.map((attempt) => <article key={attempt.id} className="rounded-xl border border-gray-200 bg-white p-4"><div className="flex items-start justify-between gap-4"><p className="text-sm font-bold text-gray-800">{attempt.prompt_text}</p><span className="shrink-0 text-xs text-gray-500">{new Date(attempt.created_at).toLocaleDateString('en-IN')}</span></div><p className="mt-2 text-xs text-gray-600">Clarity {attempt.ai_scores_json?.clarity_score ?? '—'}/10 · Structure {attempt.ai_scores_json?.structure_score ?? '—'}/10 · {attempt.duration_seconds}s</p></article>)}</div></section>}
    </div>
  );
}
