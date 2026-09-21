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
  const [actionError, setActionError] = useState('');

  const mediaRecorderRef = useRef<MediaRecorder | null>(null);
  const chunksRef = useRef<Blob[]>([]);
  const timerRef = useRef<NodeJS.Timeout | null>(null);
  const maxTimeoutRef = useRef<NodeJS.Timeout | null>(null);
  const retryRef = useRef<(() => void) | null>(null);

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

  const showActionError = (message: string, retry?: () => void) => {
    setActionError(message);
    retryRef.current = retry ?? null;
  };

  const dismissActionError = () => {
    setActionError('');
    retryRef.current = null;
  };

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
      dismissActionError();
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
      showActionError('Could not access microphone. Please check permissions.', startRecording);
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
    dismissActionError();

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
        showActionError(data.error || 'Failed to evaluate audio.', submitAudio);
      }
    } catch (err) {
      console.error(err);
      showActionError('Error submitting audio. Please try again.', submitAudio);
    }

    setIsUploading(false);
  };

  const formatTime = (seconds: number) => {
    const m = Math.floor(seconds / 60);
    const s = seconds % 60;
    return `${m}:${s < 10 ? '0' : ''}${s}`;
  };

  return (
    <div className="min-h-screen bg-page-bg pb-20">
      <header className="bg-white border-b border-border-light px-6 py-4 flex items-center gap-4 sticky top-0 z-10">
        <Link href="/student" className="text-text-muted hover:text-text-main transition-colors">
          <ChevronLeft className="w-5 h-5" />
        </Link>
        <div>
          <h1 className="text-xl font-bold text-text-main leading-tight">Communication Practice</h1>
          <p className="text-xs font-medium text-text-muted uppercase tracking-wide">Audio only • Max 2 minutes</p>
        </div>
      </header>

      <main className="max-w-2xl mx-auto pt-10 px-6">
        {actionError && (
          <div className="mb-6 flex items-center justify-between gap-3 rounded-2xl border border-red-200 bg-red-50 p-4 text-sm font-bold text-red-700">
            <span>{actionError}</span>
            <div className="flex shrink-0 items-center gap-3">
              {retryRef.current && (
                <button
                  onClick={() => { const retry = retryRef.current; dismissActionError(); retry?.(); }}
                  className="underline"
                >
                  Retry
                </button>
              )}
              <button onClick={dismissActionError} className="underline">Dismiss</button>
            </div>
          </div>
        )}

        {/* Prompt Card */}
        <div className="bg-white rounded-xl shadow-sm border border-border-light p-6 mb-8 relative overflow-hidden">
          <div className="absolute top-0 left-0 w-1 h-full bg-primary-purple"></div>
          <h2 className="text-sm font-bold text-text-muted uppercase tracking-wider mb-2">Practice Prompt</h2>
          {loadError ? <p className="text-sm font-semibold text-red-700">{loadError}</p> : (
            <>
              <select value={selectedPromptId} onChange={(event) => { setSelectedPromptId(event.target.value); resetRecording(); }} className="mb-4 w-full rounded-lg border border-border-light bg-page-bg px-3 py-2 text-sm font-bold text-text-main">
                {prompts.map((item) => <option key={item.id} value={item.id}>{item.category.replace('_', ' ')} · {item.difficulty}</option>)}
              </select>
              <p className="text-lg font-medium text-text-main leading-relaxed">{selectedPrompt?.prompt_text || 'Loading a verified prompt…'}</p>
              {selectedPrompt?.evaluation_focus?.length ? <p className="mt-3 text-xs font-semibold text-text-muted">Focus: {selectedPrompt.evaluation_focus.join(' · ')}</p> : null}
            </>
          )}
        </div>

        {/* Recording Interface */}
        <div className="bg-white rounded-xl shadow-sm border border-border-light p-8 flex flex-col items-center justify-center min-h-[300px]">

          {!audioUrl && (
            <>
              <div className="text-5xl font-mono text-text-main mb-8 tabular-nums">
                {formatTime(time)} <span className="text-text-muted text-2xl">/ 2:00</span>
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
                  className="w-20 h-20 bg-primary-purple hover:bg-deep-violet text-white rounded-full flex items-center justify-center shadow-lg transition-transform hover:scale-105 active:scale-95 disabled:opacity-50"
                >
                  <Mic className="w-8 h-8" />
                </button>
              )}
              <p className="mt-6 text-sm text-text-muted font-medium">
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
                  className="px-6 py-2.5 text-sm font-bold text-text-muted hover:bg-page-bg rounded-lg transition-colors disabled:opacity-50"
                >
                  Retake
                </button>
                <button
                  onClick={submitAudio}
                  disabled={isUploading}
                  className="px-6 py-2.5 text-sm font-bold text-white bg-primary-purple hover:bg-deep-violet rounded-lg shadow-sm transition-colors flex items-center gap-2 disabled:opacity-50"
                >
                  {isUploading ? <Loader2 className="w-4 h-4 animate-spin" /> : <UploadCloud className="w-4 h-4" />}
                  {isUploading ? 'Evaluating...' : 'Submit for Feedback'}
                </button>
              </div>
              {isUploading && (
                <p className="mt-4 text-xs text-text-muted animate-pulse">Running Speech-to-Text and AI evaluation...</p>
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
                <h3 className="text-xl font-bold text-text-main">Evaluation Complete</h3>
              </div>

              <div className="grid grid-cols-3 gap-4 mb-6">
                <div className="bg-page-bg p-4 rounded-lg border border-border-light text-center">
                  <p className="text-xs font-bold text-text-muted uppercase">Clarity</p>
                  <p className="text-2xl font-black text-primary-purple">{result.scores.clarity_score}/10</p>
                </div>
                <div className="bg-page-bg p-4 rounded-lg border border-border-light text-center">
                  <p className="text-xs font-bold text-text-muted uppercase">Structure</p>
                  <p className="text-2xl font-black text-primary-purple">{result.scores.structure_score}/10</p>
                </div>
                <div className="bg-page-bg p-4 rounded-lg border border-border-light text-center">
                  <p className="text-xs font-bold text-text-muted uppercase">Filler Words</p>
                  <p className="text-2xl font-black text-amber-500">{result.scores.filler_word_count}</p>
                </div>
              </div>

              <div className="bg-primary-purple/5 p-6 rounded-xl border border-primary-purple/15 mb-6">
                <h4 className="flex items-center gap-2 text-sm font-bold text-primary-purple uppercase tracking-wide mb-3">
                  <BrainCircuit className="w-4 h-4" /> AI Feedback
                </h4>
                <p className="text-text-main text-sm leading-relaxed mb-4">{result.scores.brief_feedback}</p>
                <div className="bg-white p-4 rounded-lg border border-primary-purple/15">
                  <p className="text-xs font-bold text-primary-purple uppercase mb-1">Suggested Improvement</p>
                  <p className="text-text-main text-sm">{result.scores.suggested_improvement}</p>
                </div>
              </div>

              <div className="flex justify-center">
                <button onClick={resetRecording} className="px-6 py-2.5 text-sm font-bold text-text-muted hover:bg-page-bg rounded-lg transition-colors">
                  Practice Another Prompt
                </button>
              </div>
            </div>
          )}

        </div>
      </main>
      {attempts.length > 0 && <section className="mx-auto w-full max-w-2xl px-6 pb-12"><h2 className="mb-3 text-sm font-black uppercase tracking-wider text-text-muted">Recent practice</h2><div className="space-y-3">{attempts.map((attempt) => <article key={attempt.id} className="rounded-xl border border-border-light bg-white p-4"><div className="flex items-start justify-between gap-4"><p className="text-sm font-bold text-text-main">{attempt.prompt_text}</p><span className="shrink-0 text-xs text-text-muted">{new Date(attempt.created_at).toLocaleDateString('en-IN')}</span></div><p className="mt-2 text-xs text-text-muted">Clarity {attempt.ai_scores_json?.clarity_score ?? '—'}/10 · Structure {attempt.ai_scores_json?.structure_score ?? '—'}/10 · {attempt.duration_seconds}s</p></article>)}</div></section>}
    </div>
  );
}
