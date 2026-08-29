'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { 
  Zap, Brain, Code2, BookOpen, MessageSquare, Clock, 
  ArrowRight, Flame, CheckCircle2, Play, Award, Sparkles, Target
} from 'lucide-react';

export default function StudentTrainHubPage() {
  const [selectedSprintDomain, setSelectedSprintDomain] = useState('Core CS (DBMS & OS)');
  const [selectedDuration, setSelectedDuration] = useState(10);
  const [sprintActive, setSprintActive] = useState(false);
  const [currentQuestionIdx, setCurrentQuestionIdx] = useState(0);
  const [selectedAnswer, setSelectedAnswer] = useState<number | null>(null);
  const [sprintComplete, setSprintComplete] = useState(false);
  const [score, setScore] = useState(0);

  const sprintQuestions = [
    {
      domain: 'Core CS (DBMS & OS)',
      q: 'Which isolation level prevents Dirty Reads but allows Non-Repeatable Reads?',
      options: ['Read Uncommitted', 'Read Committed', 'Repeatable Read', 'Serializable'],
      correct: 1,
      explanation: 'Read Committed ensures that any data read is committed at the moment it is read, preventing dirty reads.'
    },
    {
      domain: 'Core CS (DBMS & OS)',
      q: 'In Linux process management, which system call creates a new child process with a duplicated address space?',
      options: ['exec()', 'fork()', 'clone()', 'pthread_create()'],
      correct: 1,
      explanation: 'fork() creates a new child process which is an exact duplicate of the calling parent process.'
    },
    {
      domain: 'Core CS (DBMS & OS)',
      q: 'What is the primary condition required for a Deadlock to occur involving multiple threads?',
      options: ['Mutual Exclusion', 'Hold and Wait', 'No Preemption & Circular Wait', 'All of the above'],
      correct: 3,
      explanation: 'Coffman conditions require all 4 conditions (Mutual Exclusion, Hold & Wait, No Preemption, Circular Wait) to hold simultaneously.'
    }
  ];

  const handleNextQuestion = () => {
    if (selectedAnswer === sprintQuestions[currentQuestionIdx].correct) {
      setScore(prev => prev + 1);
    }
    if (currentQuestionIdx + 1 < sprintQuestions.length) {
      setCurrentQuestionIdx(prev => prev + 1);
      setSelectedAnswer(null);
    } else {
      setSprintComplete(true);
    }
  };

  const resetSprint = () => {
    setSprintActive(false);
    setSprintComplete(false);
    setCurrentQuestionIdx(0);
    setSelectedAnswer(null);
    setScore(0);
  };

  return (
    <div className="max-w-5xl mx-auto space-y-8 pb-12">
      <div>
        <span className="text-xs font-bold text-electric-blue uppercase tracking-wider block">
          Daily Training & Adaptive Mastery · PRD Chapter 4.2
        </span>
        <h1 className="text-3xl font-black text-white mt-1 flex items-center gap-2">
          <Zap className="w-7 h-7 text-electric-blue" />
          Preparation Gymnasium
        </h1>
        <p className="text-sm text-slate-400">
          Targeted micro-practice sessions built to convert weak signals into verified readiness evidence.
        </p>
      </div>

      {/* Hero: Daily Five */}
      <div className="bg-gradient-to-r from-slate-900 via-slate-900 to-electric-blue/10 border border-slate-800 rounded-3xl p-6 sm:p-8 shadow-sm relative overflow-hidden">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-6 relative z-10">
          <div className="space-y-2">
            <div className="inline-flex items-center gap-2 px-3 py-1 bg-electric-blue/10 border border-electric-blue/20 rounded-full text-xs font-bold text-electric-blue">
              <Flame className="w-4 h-4 text-amber-400" /> Daily Habit · 5 Questions
            </div>
            <h2 className="text-2xl font-black text-white">Today's Daily Five</h2>
            <p className="text-sm text-slate-300 max-w-xl">
              Curated by spaced repetition. 2 DSA, 1 DBMS, 1 OS, and 1 Aptitude question customized to your recent error patterns.
            </p>
          </div>
          <div className="flex items-center gap-4">
            <div className="text-center px-4 py-2 bg-slate-950/80 rounded-2xl border border-slate-800">
              <span className="text-xs font-bold text-slate-400 block">Streak</span>
              <span className="text-2xl font-black text-amber-400">8 Days 🔥</span>
            </div>
            <button
              onClick={() => { setSprintActive(true); }}
              className="px-6 py-3.5 bg-electric-blue hover:bg-electric-blue/90 text-white font-bold text-sm rounded-2xl shadow-lg transition-transform hover:scale-105 active:scale-95 flex items-center gap-2"
            >
              <Play className="w-4 h-4 fill-current" /> Start Daily Five
            </button>
          </div>
        </div>
      </div>

      {/* Interactive Adaptive Sprint Runner Modal/Section */}
      {sprintActive && !sprintComplete && (
        <div className="bg-slate-900 border-2 border-electric-blue/50 rounded-3xl p-6 sm:p-8 shadow-2xl space-y-6 animate-in fade-in">
          <div className="flex items-center justify-between border-b border-slate-800 pb-4">
            <div>
              <span className="text-xs font-bold text-electric-blue uppercase">
                {sprintQuestions[currentQuestionIdx].domain} · Question {currentQuestionIdx + 1} of {sprintQuestions.length}
              </span>
              <h3 className="text-lg font-bold text-white mt-1">Adaptive Concept Drill</h3>
            </div>
            <span className="text-xs font-mono text-slate-400 px-3 py-1 bg-slate-950 rounded-lg border border-slate-800">
              Score: {score}
            </span>
          </div>

          <p className="text-base font-medium text-white leading-relaxed">
            {sprintQuestions[currentQuestionIdx].q}
          </p>

          <div className="space-y-3">
            {sprintQuestions[currentQuestionIdx].options.map((opt, idx) => (
              <button
                key={idx}
                onClick={() => setSelectedAnswer(idx)}
                className={`w-full text-left p-4 rounded-xl border text-sm font-medium transition-all ${
                  selectedAnswer === idx
                    ? 'bg-electric-blue/20 border-electric-blue text-white font-bold'
                    : 'bg-slate-950 border-slate-800 text-slate-300 hover:border-slate-700'
                }`}
              >
                <span className="text-xs font-mono text-slate-500 mr-2">{String.fromCharCode(65 + idx)}.</span>
                {opt}
              </button>
            ))}
          </div>

          <div className="flex items-center justify-between pt-4 border-t border-slate-800">
            <button onClick={resetSprint} className="text-xs text-slate-400 hover:text-white font-bold">
              Exit Sprint
            </button>
            <button
              onClick={handleNextQuestion}
              disabled={selectedAnswer === null}
              className="px-6 py-2.5 bg-electric-blue hover:bg-electric-blue/90 disabled:opacity-50 text-white font-bold text-xs rounded-xl flex items-center gap-2"
            >
              {currentQuestionIdx + 1 === sprintQuestions.length ? 'Finish Sprint' : 'Next Question'}
              <ArrowRight className="w-4 h-4" />
            </button>
          </div>
        </div>
      )}

      {sprintComplete && (
        <div className="bg-slate-900 border border-emerald-500/30 rounded-3xl p-8 text-center space-y-4 animate-in fade-in">
          <div className="w-16 h-16 bg-emerald-500/10 text-emerald-400 rounded-full flex items-center justify-center mx-auto border border-emerald-500/20">
            <CheckCircle2 className="w-8 h-8" />
          </div>
          <h3 className="text-2xl font-black text-white">Sprint Completed!</h3>
          <p className="text-sm text-slate-400 max-w-md mx-auto">
            You scored {score}/{sprintQuestions.length}. Evidence recorded in your Core CS dimension snapshot (+35 XP).
          </p>
          <button
            onClick={resetSprint}
            className="px-6 py-2.5 bg-slate-800 hover:bg-slate-700 text-white font-bold text-xs rounded-xl"
          >
            Back to Gymnasium
          </button>
        </div>
      )}

      {/* Grid: 3 Training Modules */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        
        {/* Module 1: Adaptive Sprints */}
        <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6 flex flex-col justify-between space-y-4">
          <div className="space-y-3">
            <div className="w-10 h-10 rounded-xl bg-electric-blue/10 text-electric-blue flex items-center justify-center">
              <Brain className="w-5 h-5" />
            </div>
            <h3 className="text-lg font-bold text-white">Adaptive Skill Sprint</h3>
            <p className="text-xs text-slate-400 leading-relaxed">
              Targeted 5, 10, or 20 minute focus drills that escalate in difficulty based on your live accuracy.
            </p>
            
            <div className="space-y-2 pt-2">
              <span className="text-[11px] font-bold text-slate-500 uppercase block">Duration</span>
              <div className="flex gap-2">
                {[5, 10, 20].map((m) => (
                  <button
                    key={m}
                    onClick={() => setSelectedDuration(m)}
                    className={`px-3 py-1 rounded-lg text-xs font-bold border ${
                      selectedDuration === m
                        ? 'bg-electric-blue text-white border-electric-blue'
                        : 'bg-slate-950 text-slate-400 border-slate-800'
                    }`}
                  >
                    {m} mins
                  </button>
                ))}
              </div>
            </div>
          </div>

          <button
            onClick={() => { setSprintActive(true); }}
            className="w-full py-2.5 bg-slate-800 hover:bg-slate-700 text-white font-bold text-xs rounded-xl flex items-center justify-center gap-2 transition-colors"
          >
            Launch Sprint <ArrowRight className="w-4 h-4" />
          </button>
        </div>

        {/* Module 2: CodeBox Quests */}
        <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6 flex flex-col justify-between space-y-4">
          <div className="space-y-3">
            <div className="w-10 h-10 rounded-xl bg-emerald-500/10 text-emerald-400 flex items-center justify-center">
              <Code2 className="w-5 h-5" />
            </div>
            <h3 className="text-lg font-bold text-white">CodeBox Tasks</h3>
            <p className="text-xs text-slate-400 leading-relaxed">
              Monaco-powered coding sandbox. Verified via Piston API test suites and DeepSeek AI evaluation.
            </p>
            <div className="text-xs text-slate-500 space-y-1">
              <div>• Active Quest: <strong className="text-white">Two Sum & Graph BFS</strong></div>
              <div>• Verification Threshold: 70% Tests + AI 5/10</div>
            </div>
          </div>

          <Link
            href="/student/codebox/two-sum"
            className="w-full py-2.5 bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-xs rounded-xl flex items-center justify-center gap-2 transition-colors text-center"
          >
            Open CodeBox <ArrowRight className="w-4 h-4" />
          </Link>
        </div>

        {/* Module 3: Communication Practice */}
        <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6 flex flex-col justify-between space-y-4">
          <div className="space-y-3">
            <div className="w-10 h-10 rounded-xl bg-violet-500/10 text-violet-400 flex items-center justify-center">
              <MessageSquare className="w-5 h-5" />
            </div>
            <h3 className="text-lg font-bold text-white">Interview Audio Lab</h3>
            <p className="text-xs text-slate-400 leading-relaxed">
              2-minute audio recordings evaluated for clarity, STAR answer structure, and filler word frequency.
            </p>
            <div className="text-xs text-slate-500 space-y-1">
              <div>• Prompt: <strong className="text-white">Overcoming Technical Roadblocks</strong></div>
              <div>• Mode: Audio Only (2-min limit)</div>
            </div>
          </div>

          <Link
            href="/student/train/communication"
            className="w-full py-2.5 bg-violet-600 hover:bg-violet-700 text-white font-bold text-xs rounded-xl flex items-center justify-center gap-2 transition-colors text-center"
          >
            Record Response <ArrowRight className="w-4 h-4" />
          </Link>
        </div>

      </div>
    </div>
  );
}
