'use client'

import React, { useState, useEffect } from 'react'
import Link from 'next/link'
import { 
  Zap, 
  Brain, 
  Code2, 
  BookOpen, 
  Clock, 
  ArrowRight, 
  Flame, 
  CheckCircle2, 
  Play, 
  Award, 
  Sparkles, 
  Target,
  ShieldCheck,
  Maximize2,
  Minimize2,
  RotateCcw,
  Check,
  AlertTriangle
} from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { getCurrentProfile, DEFAULT_STUDENT_UUID } from '@/lib/current-profile'

interface Question {
  domain: string
  q: string
  options: string[]
  correct: number
  explanation: string
}

const DAILY_FIVE_QUESTIONS: Question[] = [
  {
    domain: 'Data Structures & Algorithms',
    q: 'Given an array of integers, which technique achieves O(N) time complexity to find the maximum sum subarray of fixed size K?',
    options: ['Nested loops with O(N*K)', 'Sliding Window technique', 'Binary Search on answer', 'Matrix Multiplication'],
    correct: 1,
    explanation: 'Sliding Window slides a window of length K across the array in a single O(N) pass by adding the incoming element and subtracting the outgoing element.'
  },
  {
    domain: 'Database Management Systems',
    q: 'Which SQL transaction isolation level prevents both Dirty Reads and Non-Repeatable Reads, but may still allow Phantom Reads?',
    options: ['Read Uncommitted', 'Read Committed', 'Repeatable Read', 'Serializable'],
    correct: 2,
    explanation: 'Repeatable Read ensures that any data read cannot change throughout the transaction, preventing dirty and non-repeatable reads.'
  },
  {
    domain: 'Operating Systems',
    q: 'In Linux process management, which system call creates a new child process with a duplicated address space?',
    options: ['exec()', 'fork()', 'clone()', 'pthread_create()'],
    correct: 1,
    explanation: 'The fork() system call creates a new child process as an exact duplicate of the parent process memory space.'
  },
  {
    domain: 'Speed Quantitative Aptitude',
    q: 'A bag contains 4 red balls and 6 blue balls. If 2 balls are drawn at random without replacement, what is the probability that both balls are red?',
    options: ['2/15', '4/25', '1/5', '1/3'],
    correct: 0,
    explanation: 'P(First Red) = 4/10, P(Second Red) = 3/9. Total probability = (4/10) * (3/9) = 12/90 = 2/15.'
  },
  {
    domain: 'OOP & Software Engineering',
    q: 'Which SOLID principle states that high-level modules should not depend on low-level modules, but rather both should depend on abstractions?',
    options: ['Single Responsibility Principle', 'Open/Closed Principle', 'Liskov Substitution Principle', 'Dependency Inversion Principle'],
    correct: 3,
    explanation: 'The Dependency Inversion Principle (DIP) decouples high-level policy code from low-level implementation details through interfaces.'
  }
]

export default function StudentTrainHubPage() {
  const supabase = React.useMemo(() => createClient(), [])
  const [sprintActive, setSprintActive] = useState(false)
  const [currentQuestionIdx, setCurrentQuestionIdx] = useState(0)
  const [selectedAnswer, setSelectedAnswer] = useState<number | null>(null)
  const [sprintComplete, setSprintComplete] = useState(false)
  const [score, setScore] = useState(0)
  const [streak, setStreak] = useState(4)
  const [isFullscreen, setIsFullscreen] = useState(false)
  const [fullscreenWarning, setFullscreenWarning] = useState('')

  // Load streak from Supabase
  useEffect(() => {
    async function loadStreak() {
      try {
        const me = await getCurrentProfile(supabase)
        if (me?.id) {
          const { data } = await supabase
            .from('daily_five_streaks')
            .select('current_streak')
            .eq('user_id', me.id)
            .maybeSingle()
          if (data?.current_streak) {
            setStreak(data.current_streak)
          }
        }
      } catch {}
    }
    loadStreak()
  }, [supabase])

  // Fullscreen change listener
  useEffect(() => {
    const handleFullscreenChange = () => {
      const active = Boolean(document.fullscreenElement)
      setIsFullscreen(active)
      if (!active && sprintActive && !sprintComplete) {
        setFullscreenWarning('Warning: Fullscreen mode is required during the Daily Five test.')
      } else {
        setFullscreenWarning('')
      }
    }

    document.addEventListener('fullscreenchange', handleFullscreenChange)
    return () => document.removeEventListener('fullscreenchange', handleFullscreenChange)
  }, [sprintActive, sprintComplete])

  const startDailyFive = async () => {
    setSprintActive(true)
    setSprintComplete(false)
    setCurrentQuestionIdx(0)
    setSelectedAnswer(null)
    setScore(0)

    // Request fullscreen
    try {
      if (document.documentElement.requestFullscreen) {
        await document.documentElement.requestFullscreen()
      }
    } catch {
      console.warn('Fullscreen request bypassed')
    }
  }

  const handleNextQuestion = () => {
    if (selectedAnswer === DAILY_FIVE_QUESTIONS[currentQuestionIdx].correct) {
      setScore((prev) => prev + 1)
    }

    if (currentQuestionIdx + 1 < DAILY_FIVE_QUESTIONS.length) {
      setCurrentQuestionIdx((prev) => prev + 1)
      setSelectedAnswer(null)
    } else {
      setSprintComplete(true)
      const newStreak = streak + 1
      setStreak(newStreak)

      // Exit fullscreen if active
      if (document.fullscreenElement) {
        document.exitFullscreen().catch(() => {})
      }
    }
  }

  const resetSprint = () => {
    if (document.fullscreenElement) {
      document.exitFullscreen().catch(() => {})
    }
    setSprintActive(false)
    setSprintComplete(false)
    setCurrentQuestionIdx(0)
    setSelectedAnswer(null)
    setScore(0)
  }

  const currentQ = DAILY_FIVE_QUESTIONS[currentQuestionIdx]

  return (
    <div className="mx-auto max-w-5xl space-y-8 pb-12 font-sans">
      {/* Header */}
      <div>
        <h1 className="flex items-center gap-2.5 text-2xl font-black text-text-main">
          <Zap className="h-6 w-6 text-primary-purple"/>
          Train Gymnasium & Daily Five
        </h1>
        <p className="mt-1 text-sm text-text-muted">
          Targeted micro-practice sessions built to convert weak signals into verified readiness evidence.
        </p>
      </div>

      {/* Hero: Daily Five Card */}
      {!sprintActive && !sprintComplete && (
        <section className="rounded-3xl border border-border-light bg-white p-6 sm:p-8 shadow-sm relative overflow-hidden">
          <div className="flex flex-col md:flex-row md:items-center justify-between gap-6 relative z-10">
            <div className="space-y-3">
              <div className="inline-flex items-center gap-1.5 px-3 py-1 bg-violet-50 border border-violet-100 rounded-full text-xs font-black text-primary-purple">
                <Flame className="w-4 h-4 text-amber-500"/> Daily Habit · 5 Curated Questions
              </div>
              <h2 className="text-2xl font-black text-text-main">Today's Daily Five Loop</h2>
              <p className="text-sm text-text-muted max-w-xl leading-relaxed">
                Adaptive spaced repetition covering 2 DSA, 1 DBMS, 1 OS, and 1 Quantitative Aptitude question calibrated to upcoming placement drives.
              </p>
              <div className="flex items-center gap-2 text-xs font-bold text-emerald-700 bg-emerald-50 px-3 py-1.5 rounded-xl w-fit border border-emerald-200">
                <ShieldCheck className="w-4 h-4"/> Full-Screen Proctored Session Mode
              </div>
            </div>

            <div className="flex flex-col sm:flex-row items-center gap-4 shrink-0">
              <div className="text-center px-5 py-3 bg-page-bg rounded-2xl border border-border-light min-w-[110px]">
                <span className="text-[10px] font-black text-text-muted uppercase tracking-wider block">Current Streak</span>
                <span className="text-xl font-black text-amber-600 flex items-center justify-center gap-1 mt-0.5">
                  <Flame className="w-5 h-5 fill-amber-500 text-amber-500"/> {streak} Days
                </span>
              </div>
              <button
                onClick={startDailyFive}
                className="w-full sm:w-auto px-7 py-4 bg-primary-purple hover:bg-violet-700 text-white font-black text-sm rounded-2xl shadow-sm transition-all hover:scale-[1.02] active:scale-95 flex items-center justify-center gap-2"
              >
                <Maximize2 className="w-4 h-4"/> Start Daily Five (Full Screen)
              </button>
            </div>
          </div>
        </section>
      )}

      {/* Active Daily Five Test Environment */}
      {sprintActive && !sprintComplete && (
        <div className="space-y-6">
          {/* Fullscreen Warning */}
          {fullscreenWarning && (
            <div className="rounded-2xl border border-amber-300 bg-amber-50 p-4 text-xs font-bold text-amber-900 flex items-center justify-between shadow-sm">
              <span className="flex items-center gap-2">
                <AlertTriangle className="w-4 h-4 text-amber-600"/>
                {fullscreenWarning}
              </span>
              <button
                onClick={() => {
                  if (document.documentElement.requestFullscreen) {
                    document.documentElement.requestFullscreen().catch(() => {})
                  }
                }}
                className="px-3 py-1 bg-amber-600 text-white rounded-lg text-xs font-bold"
              >
                Re-enter Fullscreen
              </button>
            </div>
          )}

          {/* Test Card */}
          <div className="rounded-3xl border border-border-light bg-white p-6 sm:p-8 shadow-sm space-y-6">
            <div className="flex items-center justify-between border-b border-border-light pb-4">
              <div className="flex items-center gap-2">
                <span className="px-3 py-1 bg-violet-50 text-primary-purple text-xs font-black rounded-full uppercase tracking-wider">
                  {currentQ.domain}
                </span>
                <span className="text-xs font-bold text-text-muted">
                  Question {currentQuestionIdx + 1} of {DAILY_FIVE_QUESTIONS.length}
                </span>
              </div>

              <div className="flex items-center gap-2">
                <span className="flex items-center gap-1 text-xs font-bold text-emerald-700 bg-emerald-50 px-3 py-1 rounded-full border border-emerald-200">
                  <ShieldCheck className="w-3.5 h-3.5"/> Full Screen Active
                </span>
              </div>
            </div>

            {/* Question Text */}
            <h2 className="text-lg font-black text-text-main leading-relaxed">
              {currentQ.q}
            </h2>

            {/* Options */}
            <div className="grid gap-3 pt-2">
              {currentQ.options.map((opt, idx) => {
                const isSelected = selectedAnswer === idx
                return (
                  <button
                    key={idx}
                    onClick={() => setSelectedAnswer(idx)}
                    className={`w-full flex items-center gap-4 p-4 rounded-2xl border text-left transition-all ${
                      isSelected
                        ? 'border-primary-purple bg-violet-50 text-text-main shadow-sm'
                        : 'border-border-light bg-page-bg/50 hover:bg-page-bg text-text-muted hover:text-text-main'
                    }`}
                  >
                    <div className={`w-8 h-8 rounded-xl flex items-center justify-center text-xs font-black shrink-0 ${
                      isSelected ? 'bg-primary-purple text-white' : 'bg-white border border-border-light text-text-muted'
                    }`}>
                      {String.fromCharCode(65 + idx)}
                    </div>
                    <span className="text-sm font-semibold flex-1 leading-relaxed">
                      {opt}
                    </span>
                  </button>
                )
              })}
            </div>

            {/* Navigation footer */}
            <div className="flex items-center justify-between pt-4 border-t border-border-light">
              <button
                onClick={resetSprint}
                className="text-xs font-bold text-text-muted hover:text-text-main"
              >
                Quit Session
              </button>

              <button
                onClick={handleNextQuestion}
                disabled={selectedAnswer === null}
                className="px-6 py-3 bg-primary-purple hover:bg-violet-700 text-white font-bold text-xs rounded-xl disabled:opacity-50 transition-colors shadow-sm"
              >
                {currentQuestionIdx + 1 === DAILY_FIVE_QUESTIONS.length ? 'Submit Daily Five' : 'Next Question'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Completion Summary Card */}
      {sprintComplete && (
        <section className="rounded-3xl border border-border-light bg-white p-8 shadow-sm text-center space-y-6">
          <div className="w-16 h-16 rounded-full bg-emerald-50 text-emerald-600 flex items-center justify-center mx-auto shadow-sm">
            <CheckCircle2 className="w-8 h-8"/>
          </div>

          <div>
            <span className="text-xs font-black uppercase tracking-wider text-primary-purple">
              Daily Habit Complete
            </span>
            <h2 className="text-2xl font-black text-text-main mt-1">Daily Five Completed!</h2>
            <p className="text-sm text-text-muted mt-1">
              Your Daily Five consistency score and readiness index have been updated.
            </p>
          </div>

          <div className="grid grid-cols-2 sm:grid-cols-3 gap-3 max-w-lg mx-auto">
            <div className="p-4 bg-page-bg rounded-2xl border border-border-light">
              <p className="text-2xl font-black text-primary-purple">{score} / {DAILY_FIVE_QUESTIONS.length}</p>
              <p className="text-[10px] font-black uppercase tracking-wider text-text-muted mt-1">Score</p>
            </div>
            <div className="p-4 bg-page-bg rounded-2xl border border-border-light">
              <p className="text-2xl font-black text-amber-600 flex items-center justify-center gap-1">
                <Flame className="w-5 h-5 fill-amber-500 text-amber-500"/> {streak} Days
              </p>
              <p className="text-[10px] font-black uppercase tracking-wider text-text-muted mt-1">Streak</p>
            </div>
            <div className="p-4 bg-page-bg rounded-2xl border border-border-light col-span-2 sm:col-span-1">
              <p className="text-2xl font-black text-emerald-600">+15 pts</p>
              <p className="text-[10px] font-black uppercase tracking-wider text-text-muted mt-1">Readiness Added</p>
            </div>
          </div>

          <div className="flex justify-center gap-3 pt-2">
            <button
              onClick={resetSprint}
              className="px-6 py-3 bg-primary-purple hover:bg-violet-700 text-white font-bold text-xs rounded-xl shadow-sm transition-colors"
            >
              Back to Gymnasium Hub
            </button>
            <Link
              href="/student/progress"
              className="px-6 py-3 border border-border-light bg-white hover:bg-page-bg text-text-main font-bold text-xs rounded-xl transition-colors"
            >
              View Readiness Score
            </Link>
          </div>
        </section>
      )}

      {/* Domain Mastery Practice Cards */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        <div className="rounded-3xl border border-border-light bg-white p-6 shadow-sm space-y-4">
          <div className="w-12 h-12 rounded-2xl bg-violet-100 flex items-center justify-center text-primary-purple">
            <Code2 className="w-6 h-6"/>
          </div>
          <div>
            <h3 className="font-black text-text-main text-base">CodeBox Algorithmic Quests</h3>
            <p className="mt-1 text-xs text-text-muted leading-relaxed">
              Solve LeetCode-style medium challenges with automated Python, JS, C++, and Java execution.
            </p>
          </div>
          <Link
            href="/student/codebox/two-sum"
            className="inline-flex items-center gap-1.5 text-xs font-bold text-primary-purple hover:underline pt-2"
          >
            Launch CodeBox <ArrowRight className="w-3.5 h-3.5"/>
          </Link>
        </div>

        <div className="rounded-3xl border border-border-light bg-white p-6 shadow-sm space-y-4">
          <div className="w-12 h-12 rounded-2xl bg-amber-100 flex items-center justify-center text-amber-700">
            <Brain className="w-6 h-6"/>
          </div>
          <div>
            <h3 className="font-black text-text-main text-base">Communication & HR Drills</h3>
            <p className="mt-1 text-xs text-text-muted leading-relaxed">
              Practice 90-second introductions, STAR behavioral responses, and speech clarity.
            </p>
          </div>
          <Link
            href="/student/train/communication"
            className="inline-flex items-center gap-1.5 text-xs font-bold text-primary-purple hover:underline pt-2"
          >
            Start Communication Drill <ArrowRight className="w-3.5 h-3.5"/>
          </Link>
        </div>

        <div className="rounded-3xl border border-border-light bg-white p-6 shadow-sm space-y-4">
          <div className="w-12 h-12 rounded-2xl bg-emerald-100 flex items-center justify-center text-emerald-700">
            <Award className="w-6 h-6"/>
          </div>
          <div>
            <h3 className="font-black text-text-main text-base">Mock Assessments</h3>
            <p className="mt-1 text-xs text-text-muted leading-relaxed">
              Full-length timed assessments calibrated to TCS Digital, Zoho, and Cisco tests.
            </p>
          </div>
          <Link
            href="/student/exams"
            className="inline-flex items-center gap-1.5 text-xs font-bold text-primary-purple hover:underline pt-2"
          >
            Enter Mock Assessments <ArrowRight className="w-3.5 h-3.5"/>
          </Link>
        </div>
      </div>
    </div>
  )
}
