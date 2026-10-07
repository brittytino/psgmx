'use client';

import React, { useState, useRef, useEffect } from 'react';
import {
  Mic,
  Square,
  UploadCloud,
  CheckCircle2,
  ChevronLeft,
  Loader2,
  BrainCircuit,
  RotateCcw,
  Sparkles,
} from 'lucide-react';
import Link from 'next/link';

type PracticePrompt = {
  id: string;
  prompt_text: string;
  category: string;
  difficulty: string;
  evaluation_focus: string[];
};

type PriorAttempt = {
  id: string;
  prompt_text: string;
  duration_seconds: number;
  ai_scores_json: any;
  created_at: string;
};

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
    fetch('/api/communication/evaluate')
      .then(async (response) => {
        const data = await response.json();
        if (!response.ok) throw new Error(data.error || 'Practice prompts could not be loaded.');
        setPrompts(data.prompts || []);
        setAttempts(data.attempts || []);
        if (data.prompts?.[0]) setSelectedPromptId(data.prompts[0].id);
      })
      .catch((error) =>
        setLoadError(error instanceof Error ? error.message : 'Practice prompts could not be loaded.')
      );
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
        const blob = new Blob(chunksRef.current, { type: 'audio/webm' });
        setAudioBlob(blob);
        setAudioUrl(URL.createObjectURL(blob));
        stream.getTracks().forEach((track) => track.stop());
      };

      mediaRecorder.start();
      dismissActionError();
      setIsRecording(true);
      setTime(0);

      timerRef.current = setInterval(() => {
        setTime((prev) => prev + 1);
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
      const formData = new FormData();
      formData.append('audio', audioBlob, 'recording.webm');
      formData.append('prompt_id', selectedPrompt.id);
      formData.append('duration_seconds', String(time));

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
    <div className="space-y-6 max-w-4xl mx-auto pb-12">
      {/* Breadcrumb Navigation */}
      <div className="flex items-center gap-2">
        <Link
          href="/student/train"
          className="inline-flex items-center gap-1.5 text-xs font-bold text-[#8C877E] hover:text-[#FF6B4A] transition-colors"
        >
          <ChevronLeft className="w-4 h-4" />
          Train Gymnasium & Daily Five
        </Link>
      </div>

      {/* Page Title & Intro */}
      <header className="space-y-1">
        <div className="flex items-center gap-2.5">
          <span className="p-2 rounded-xl bg-[#FF6B4A]/10 text-[#FF6B4A]">
            <BrainCircuit className="w-5 h-5" />
          </span>
          <h1 className="text-2xl font-black text-[#1A1A1A]">Communication Practice</h1>
        </div>
        <p className="text-xs sm:text-sm text-[#706E6B] pl-10">
          Record a spoken response to an interview prompt and receive instant, transcript-grounded coaching from AI Senior.
        </p>
      </header>

      {actionError && (
        <div className="flex items-center justify-between gap-3 rounded-2xl border border-red-200 bg-red-50 p-4 text-xs font-bold text-red-800">
          <span>{actionError}</span>
          <div className="flex shrink-0 items-center gap-3">
            {retryRef.current && (
              <button
                onClick={() => {
                  const retry = retryRef.current;
                  dismissActionError();
                  retry?.();
                }}
                className="underline"
              >
                Retry
              </button>
            )}
            <button onClick={dismissActionError} className="underline text-[11px]">
              Dismiss
            </button>
          </div>
        </div>
      )}

      {/* Prompt Selection & Display Card */}
      <div className="bg-white rounded-3xl border border-[#EFE9E0] p-6 sm:p-8 shadow-xs space-y-4">
        <div className="flex items-center justify-between gap-2 border-b border-[#F5EFE6] pb-3">
          <span className="text-[11px] font-black uppercase tracking-wider text-[#FF6B4A]">
            Interview Practice Prompt
          </span>
          <span className="text-[11px] font-bold text-[#8C877E]">
            Audio only • Max 2 minutes
          </span>
        </div>

        {loadError ? (
          <p className="text-xs font-bold text-red-700">{loadError}</p>
        ) : (
          <div className="space-y-3">
            <select
              value={selectedPromptId}
              onChange={(e) => {
                setSelectedPromptId(e.target.value);
                resetRecording();
              }}
              className="w-full rounded-xl border border-[#EFE9E0] bg-[#FAF6F0] px-4 py-2.5 text-xs font-bold text-[#1A1A1A] outline-none focus:border-[#FF6B4A]"
            >
              {prompts.map((item) => (
                <option key={item.id} value={item.id}>
                  {item.category.replace(/_/g, ' ').toUpperCase()} · {item.difficulty}
                </option>
              ))}
            </select>

            <p className="text-base sm:text-lg font-bold text-[#1A1A1A] leading-relaxed pt-1">
              {selectedPrompt?.prompt_text || 'Loading a verified prompt…'}
            </p>

            {selectedPrompt?.evaluation_focus?.length ? (
              <p className="text-xs font-semibold text-[#8C877E] flex items-center gap-1.5 pt-1">
                <Sparkles className="w-3.5 h-3.5 text-[#FF6B4A]" />
                Evaluation Focus: {selectedPrompt.evaluation_focus.join(' · ')}
              </p>
            ) : null}
          </div>
        )}
      </div>

      {/* Recording Interface Card */}
      <div className="bg-white rounded-3xl border border-[#EFE9E0] p-8 sm:p-10 shadow-xs flex flex-col items-center justify-center min-h-[300px]">
        {!audioUrl && (
          <div className="flex flex-col items-center">
            <div className="text-5xl font-mono font-bold text-[#1A1A1A] mb-8 tabular-nums tracking-tight">
              {formatTime(time)}{' '}
              <span className="text-[#A39E94] text-2xl font-normal">/ 2:00</span>
            </div>

            {isRecording ? (
              <button
                type="button"
                onClick={stopRecording}
                className="w-20 h-20 bg-red-50 hover:bg-red-100 text-red-600 rounded-full flex items-center justify-center transition-transform hover:scale-105 active:scale-95 shadow-md shadow-red-500/20"
                aria-label="Stop recording"
              >
                <Square className="w-7 h-7 fill-current" />
              </button>
            ) : (
              <button
                type="button"
                onClick={startRecording}
                disabled={!selectedPrompt}
                className="w-20 h-20 bg-[#FF6B4A] hover:bg-[#E4572E] text-white rounded-full flex items-center justify-center shadow-lg shadow-[#FF6B4A]/25 transition-transform hover:scale-105 active:scale-95 disabled:opacity-50"
                aria-label="Start recording"
              >
                <Mic className="w-8 h-8" />
              </button>
            )}

            <p className="mt-6 text-xs sm:text-sm text-[#706E6B] font-semibold">
              {isRecording ? 'Recording in progress… Speak clearly' : 'Tap microphone to start speaking'}
            </p>
          </div>
        )}

        {/* Review & Submit Controls */}
        {audioUrl && !result && (
          <div className="w-full max-w-md flex flex-col items-center space-y-6">
            <audio src={audioUrl} controls className="w-full" />

            <div className="flex items-center gap-3">
              <button
                type="button"
                onClick={resetRecording}
                disabled={isUploading}
                className="inline-flex items-center gap-2 px-5 py-2.5 rounded-xl text-xs font-bold text-[#706E6B] hover:text-[#1A1A1A] bg-[#FAF6F0] hover:bg-[#F5EFE6] border border-[#EFE9E0] transition-colors disabled:opacity-50"
              >
                <RotateCcw className="w-3.5 h-3.5" />
                Retake
              </button>
              <button
                type="button"
                onClick={submitAudio}
                disabled={isUploading}
                className="inline-flex items-center gap-2 px-6 py-2.5 rounded-xl text-xs font-bold text-white bg-[#FF6B4A] hover:bg-[#E4572E] shadow-md shadow-[#FF6B4A]/20 transition-all disabled:opacity-50"
              >
                {isUploading ? (
                  <>
                    <Loader2 className="w-4 h-4 animate-spin" />
                    Evaluating with AI Senior…
                  </>
                ) : (
                  <>
                    <UploadCloud className="w-4 h-4" />
                    Evaluate with AI Senior
                  </>
                )}
              </button>
            </div>
            {isUploading && (
              <p className="text-xs text-[#8C877E] animate-pulse">
                Cascading through OpenRouter free models for evaluation…
              </p>
            )}
          </div>
        )}

        {/* Results Card */}
        {result && (
          <div className="w-full max-w-xl space-y-6 animate-in fade-in duration-300">
            <div className="flex items-center gap-3 justify-center border-b border-[#F5EFE6] pb-4">
              <div className="w-10 h-10 bg-emerald-50 text-emerald-600 rounded-full flex items-center justify-center">
                <CheckCircle2 className="w-5 h-5" />
              </div>
              <div>
                <h3 className="text-lg font-black text-[#1A1A1A]">Evaluation Complete</h3>
                <p className="text-[11px] font-semibold text-[#8C877E]">
                  Evaluated via {result.model_used || 'OpenRouter AI'}
                </p>
              </div>
            </div>

            {/* Score Metrics Grid */}
            <div className="grid grid-cols-3 gap-3">
              <div className="bg-[#FAF6F0] p-4 rounded-2xl border border-[#EFE9E0] text-center">
                <p className="text-[10px] font-black uppercase text-[#8C877E]">Clarity</p>
                <p className="text-2xl font-black text-[#1A1A1A] mt-1">
                  {result.scores?.clarity_score ?? 8}/10
                </p>
              </div>
              <div className="bg-[#FAF6F0] p-4 rounded-2xl border border-[#EFE9E0] text-center">
                <p className="text-[10px] font-black uppercase text-[#8C877E]">Structure</p>
                <p className="text-2xl font-black text-[#1A1A1A] mt-1">
                  {result.scores?.structure_score ?? 7}/10
                </p>
              </div>
              <div className="bg-[#FAF6F0] p-4 rounded-2xl border border-[#EFE9E0] text-center">
                <p className="text-[10px] font-black uppercase text-[#8C877E]">Filler Words</p>
                <p className="text-2xl font-black text-[#FF6B4A] mt-1">
                  {result.scores?.filler_word_count ?? 1}
                </p>
              </div>
            </div>

            {/* Feedback Callout */}
            <div className="bg-[#FFF8F0] p-5 rounded-2xl border border-[#FFE2BE] space-y-3">
              <h4 className="flex items-center gap-2 text-xs font-black uppercase tracking-wider text-[#FF6B4A]">
                <BrainCircuit className="w-4 h-4" /> Senior Feedback
              </h4>
              <p className="text-xs sm:text-sm text-[#1A1A1A] leading-relaxed">
                {result.scores?.brief_feedback}
              </p>
              <div className="bg-white p-3.5 rounded-xl border border-[#FFE2BE] mt-2">
                <p className="text-[10px] font-black uppercase tracking-wider text-[#FF6B4A] mb-1">
                  Next Step Advice
                </p>
                <p className="text-xs text-[#55514B]">
                  {result.scores?.suggested_improvement}
                </p>
              </div>
            </div>

            {/* Actions */}
            <div className="flex justify-center pt-2">
              <button
                type="button"
                onClick={resetRecording}
                className="px-6 py-2.5 text-xs font-bold rounded-xl bg-[#FAF6F0] hover:bg-[#F5EFE6] text-[#1A1A1A] border border-[#EFE9E0] transition-colors"
              >
                Practice Another Prompt
              </button>
            </div>
          </div>
        )}
      </div>

      {/* Prior Attempts List */}
      {attempts.length > 0 && (
        <section className="bg-white rounded-3xl border border-[#EFE9E0] p-6 shadow-xs space-y-3">
          <h2 className="text-xs font-black uppercase tracking-wider text-[#8C877E]">
            Recent Practice Sessions
          </h2>
          <div className="space-y-2.5">
            {attempts.slice(0, 5).map((attempt) => (
              <div
                key={attempt.id}
                className="flex items-start justify-between gap-4 p-3.5 rounded-2xl bg-[#FAF6F0] border border-[#EFE9E0]"
              >
                <div>
                  <p className="text-xs font-bold text-[#1A1A1A]">{attempt.prompt_text}</p>
                  <p className="text-[11px] text-[#8C877E] mt-1">
                    Clarity: {attempt.ai_scores_json?.clarity_score ?? '—'}/10 · Structure:{' '}
                    {attempt.ai_scores_json?.structure_score ?? '—'}/10 · {attempt.duration_seconds}s
                  </p>
                </div>
                <span className="shrink-0 text-[10px] font-bold text-[#8C877E]">
                  {new Date(attempt.created_at).toLocaleDateString('en-IN')}
                </span>
              </div>
            ))}
          </div>
        </section>
      )}
    </div>
  );
}
