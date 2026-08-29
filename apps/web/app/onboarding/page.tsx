'use client';

import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { 
  Sparkles, CheckCircle2, ChevronRight, AlertCircle, 
  Code2, Brain, BookOpen, MessageSquare, ShieldCheck, 
  ArrowRight, Award, Zap 
} from 'lucide-react';
import { createClient } from '@/lib/supabase/client';

export default function OnboardingPage() {
  const router = useRouter();
  const supabase = createClient();

  const [step, setStep] = useState(1);
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [profile, setProfile] = useState<any>(null);

  // Calibration Form State per PRD Chapter 3.2
  const [targetRole, setTargetRole] = useState('Product engineering');
  const [confidence, setConfidence] = useState({
    aptitude: 2, // 1: Novice, 2: Practicing, 3: Confident
    coding: 2,
    core_cs: 2,
    communication: 2,
  });
  const [leetcodeUsername, setLeetcodeUsername] = useState('');
  const [practiceDays, setPracticeDays] = useState(5);
  const [reminderWindow, setReminderWindow] = useState('Evening (6 PM - 9 PM)');

  // 5-Question sample responses
  const [sampleAnswers, setSampleAnswers] = useState<Record<number, number>>({});
  const [xpAwarded, setXpAwarded] = useState(false);

  useEffect(() => {
    async function loadProfile() {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        router.push('/login');
        return;
      }

      const { data } = await supabase
        .from('users')
        .select('*')
        .eq('id', user.id)
        .maybeSingle();

      if (data) {
        setProfile(data);
        if (data.onboarding_complete) {
          router.push('/student');
          return;
        }
      }
      setLoading(false);
    }
    loadProfile();
  }, [router, supabase]);

  const sampleQuestions = [
    {
      id: 1,
      category: 'Core CS (DBMS)',
      question: 'Which property of ACID ensures that concurrent transactions do not interfere with each other?',
      options: ['Atomicity', 'Consistency', 'Isolation', 'Durability'],
      correct: 2,
    },
    {
      id: 2,
      category: 'Coding (DSA)',
      question: 'What is the average time complexity of searching in a balanced Binary Search Tree?',
      options: ['O(1)', 'O(log n)', 'O(n)', 'O(n log n)'],
      correct: 1,
    },
    {
      id: 3,
      category: 'Core CS (OS)',
      question: 'Which scheduling algorithm guarantees prevention of starvation?',
      options: ['First-Come First-Served', 'Shortest Job First', 'Round Robin', 'Priority Scheduling'],
      correct: 2,
    },
    {
      id: 4,
      category: 'Aptitude',
      question: 'If a train traveling at 60 km/h crosses a 100m pole in 6 seconds, what is its length?',
      options: ['80m', '100m', '120m', '150m'],
      correct: 1,
    },
    {
      id: 5,
      category: 'Communication',
      question: 'When asked "Tell me about a time you failed", what is the best strategy?',
      options: [
        'Deny ever failing to show competence',
        'Blame team members for unforeseen issues',
        'State the situation honestly, explain your proactive solution, and detail what you learned (STAR method)',
        'Change the subject to your greatest achievement'
      ],
      correct: 2,
    },
  ];

  const handleFinishOnboarding = async () => {
    setSubmitting(true);
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (user) {
        await (supabase as any)
          .from('users')
          .update({
            leetcode_username: leetcodeUsername || null,
            onboarding_complete: true,
            role_family: targetRole,
            calibration_meta: {
              confidence,
              practice_days: practiceDays,
              reminder_window: reminderWindow,
              sample_score: Object.keys(sampleAnswers).length,
            },
          })
          .eq('id', user.id);
      }
      setXpAwarded(true);
      setTimeout(() => {
        router.push('/student');
      }, 1800);
    } catch (err) {
      console.error(err);
      router.push('/student');
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-slate-950 flex items-center justify-center text-slate-400">
        Calibrating your PSGMX companion...
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 flex flex-col justify-center py-12 px-4 sm:px-6 lg:px-8 font-sans">
      <div className="max-w-2xl w-full mx-auto space-y-8">
        
        {/* Step Indicator */}
        <div className="flex items-center justify-between border-b border-slate-800 pb-4">
          <div>
            <span className="text-xs font-bold text-electric-blue uppercase tracking-widest">
              5-Minute Calibration · Step {step} of 6
            </span>
            <h1 className="text-xl font-bold text-white mt-0.5">
              {step === 1 && "1. Verify Your Identity"}
              {step === 2 && "2. Target Role Family"}
              {step === 3 && "3. Baseline Confidence"}
              {step === 4 && "4. Practice Habits"}
              {step === 5 && "5. Quick Adaptive Sample"}
              {step === 6 && "6. Your Starting Plan"}
            </h1>
          </div>
          <div className="flex gap-1.5">
            {[1, 2, 3, 4, 5, 6].map((i) => (
              <div
                key={i}
                className={`h-2 rounded-full transition-all ${
                  i === step ? 'w-8 bg-electric-blue' : i < step ? 'w-2 bg-emerald-500' : 'w-2 bg-slate-800'
                }`}
              />
            ))}
          </div>
        </div>

        {/* Step 1: Identity Confirmation */}
        {step === 1 && (
          <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6 space-y-6">
            <p className="text-sm text-slate-400">
              Your account was rostered by your batch Placement Representative. Please confirm your academic identity details.
            </p>
            <div className="grid grid-cols-2 gap-4 bg-slate-950 p-4 rounded-xl border border-slate-800/60 font-mono text-sm">
              <div>
                <span className="text-xs text-slate-500 block">Full Name</span>
                <span className="font-bold text-white">{profile?.name || 'Student'}</span>
              </div>
              <div>
                <span className="text-xs text-slate-500 block">Register Number</span>
                <span className="font-bold text-white">{profile?.reg_no || 'Unassigned'}</span>
              </div>
              <div>
                <span className="text-xs text-slate-500 block">Batch</span>
                <span className="text-slate-300">{profile?.batch_year ? `${profile.batch_year} MCA` : 'Active Batch'}</span>
              </div>
              <div>
                <span className="text-xs text-slate-500 block">Stage</span>
                <span className="text-slate-300">Junior Year</span>
              </div>
            </div>

            <div className="flex items-center justify-between pt-2">
              <span className="text-xs text-slate-500">Notice an error? Your PR can request a governance correction.</span>
              <button
                onClick={() => setStep(2)}
                className="px-6 py-2.5 bg-electric-blue hover:bg-electric-blue/90 text-white font-bold text-sm rounded-xl flex items-center gap-2"
              >
                Confirm & Next <ChevronRight className="w-4 h-4" />
              </button>
            </div>
          </div>
        )}

        {/* Step 2: Target Role Family */}
        {step === 2 && (
          <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6 space-y-4">
            <p className="text-sm text-slate-400">
              Select your primary aspiration. PSGMX will prioritize relevant interview patterns and quests.
            </p>
            <div className="space-y-3">
              {[
                { id: 'Product engineering', desc: 'DSA, System Design, Full-Stack and High-Scale Systems' },
                { id: 'Service engineering', desc: 'Core CS, Aptitude, Java/Spring, Cloud and Enterprise Solutions' },
                { id: 'Research & AI', desc: 'Machine Learning, Data Engineering, Algorithms and Systems' },
                { id: "I don't know yet", desc: 'Balanced coverage across all six readiness dimensions' },
              ].map((role) => (
                <div
                  key={role.id}
                  onClick={() => setTargetRole(role.id)}
                  className={`p-4 rounded-xl border cursor-pointer transition-all ${
                    targetRole === role.id
                      ? 'border-electric-blue bg-electric-blue/10 text-white'
                      : 'border-slate-800 bg-slate-950 text-slate-400 hover:border-slate-700'
                  }`}
                >
                  <div className="font-bold text-sm text-white">{role.id}</div>
                  <div className="text-xs text-slate-400 mt-0.5">{role.desc}</div>
                </div>
              ))}
            </div>

            <div className="flex justify-end pt-4">
              <button
                onClick={() => setStep(3)}
                className="px-6 py-2.5 bg-electric-blue hover:bg-electric-blue/90 text-white font-bold text-sm rounded-xl flex items-center gap-2"
              >
                Next <ChevronRight className="w-4 h-4" />
              </button>
            </div>
          </div>
        )}

        {/* Step 3: Baseline Confidence */}
        {step === 3 && (
          <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6 space-y-6">
            <p className="text-sm text-slate-400">
              Rate your current comfort in each dimension (1 = Novice, 2 = Practicing, 3 = Confident).
            </p>

            {[
              { key: 'aptitude', label: 'Aptitude & Quantitative Reasoning', icon: Brain },
              { key: 'coding', label: 'Data Structures & Coding Problem Solving', icon: Code2 },
              { key: 'core_cs', label: 'Core CS (DBMS, OS, Networks)', icon: BookOpen },
              { key: 'communication', label: 'Technical Communication & English Speaking', icon: MessageSquare },
            ].map(({ key, label, icon: Icon }) => (
              <div key={key} className="space-y-2">
                <div className="flex items-center gap-2 text-sm font-bold text-white">
                  <Icon className="w-4 h-4 text-electric-blue" />
                  {label}
                </div>
                <div className="grid grid-cols-3 gap-2">
                  {[
                    { val: 1, text: 'Novice' },
                    { val: 2, text: 'Practicing' },
                    { val: 3, text: 'Confident' },
                  ].map(({ val, text }) => (
                    <button
                      key={val}
                      type="button"
                      onClick={() => setConfidence({ ...confidence, [key]: val })}
                      className={`py-2 rounded-lg text-xs font-bold border transition-all ${
                        confidence[key as keyof typeof confidence] === val
                          ? 'bg-electric-blue text-white border-electric-blue'
                          : 'bg-slate-950 text-slate-400 border-slate-800 hover:border-slate-700'
                      }`}
                    >
                      {text}
                    </button>
                  ))}
                </div>
              </div>
            ))}

            <div className="flex justify-end pt-4">
              <button
                onClick={() => setStep(4)}
                className="px-6 py-2.5 bg-electric-blue hover:bg-electric-blue/90 text-white font-bold text-sm rounded-xl flex items-center gap-2"
              >
                Next <ChevronRight className="w-4 h-4" />
              </button>
            </div>
          </div>
        )}

        {/* Step 4: Practice Habits */}
        {step === 4 && (
          <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6 space-y-6">
            <div>
              <label className="block text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">
                LeetCode Username (Optional)
              </label>
              <input
                type="text"
                value={leetcodeUsername}
                onChange={(e) => setLeetcodeUsername(e.target.value)}
                placeholder="e.g. tinobritty"
                className="w-full bg-slate-950 border border-slate-800 rounded-xl px-4 py-3 text-white text-sm focus:border-electric-blue outline-none"
              />
              <p className="text-xs text-slate-500 mt-1">
                Your stats are synced automatically every 6 hours via GitHub Actions.
              </p>
            </div>

            <div>
              <label className="block text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">
                Days Available to Practice per Week: <span className="text-electric-blue">{practiceDays} days</span>
              </label>
              <input
                type="range"
                min={2}
                max={7}
                value={practiceDays}
                onChange={(e) => setPracticeDays(Number(e.target.value))}
                className="w-full accent-electric-blue"
              />
            </div>

            <div>
              <label className="block text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">
                Preferred Reminder Window
              </label>
              <select
                value={reminderWindow}
                onChange={(e) => setReminderWindow(e.target.value)}
                className="w-full bg-slate-950 border border-slate-800 rounded-xl px-4 py-3 text-white text-sm focus:border-electric-blue outline-none"
              >
                <option value="Morning (7 AM - 9 AM)">Morning (7 AM - 9 AM)</option>
                <option value="Afternoon (12 PM - 2 PM)">Afternoon (12 PM - 2 PM)</option>
                <option value="Evening (6 PM - 9 PM)">Evening (6 PM - 9 PM)</option>
              </select>
            </div>

            <div className="flex justify-end pt-4">
              <button
                onClick={() => setStep(5)}
                className="px-6 py-2.5 bg-electric-blue hover:bg-electric-blue/90 text-white font-bold text-sm rounded-xl flex items-center gap-2"
              >
                Start Adaptive Sample <ChevronRight className="w-4 h-4" />
              </button>
            </div>
          </div>
        )}

        {/* Step 5: 5-Question Sample */}
        {step === 5 && (
          <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6 space-y-6">
            <p className="text-sm text-slate-400">
              Answer these 5 quick concept checks. This sample calibrates your Daily Five difficulty without grading pressure.
            </p>

            <div className="space-y-6">
              {sampleQuestions.map((q, idx) => (
                <div key={q.id} className="bg-slate-950 p-4 rounded-xl border border-slate-800 space-y-3">
                  <div className="flex justify-between items-center text-xs">
                    <span className="font-bold text-electric-blue">{q.category}</span>
                    <span className="text-slate-500">Question {idx + 1}/5</span>
                  </div>
                  <p className="text-sm font-semibold text-white">{q.question}</p>
                  <div className="space-y-2">
                    {q.options.map((opt, optIdx) => (
                      <button
                        key={optIdx}
                        type="button"
                        onClick={() => setSampleAnswers({ ...sampleAnswers, [q.id]: optIdx })}
                        className={`w-full text-left p-3 rounded-lg text-xs font-medium border transition-all ${
                          sampleAnswers[q.id] === optIdx
                            ? 'bg-electric-blue/20 border-electric-blue text-white font-bold'
                            : 'bg-slate-900 border-slate-800 text-slate-400 hover:border-slate-700'
                        }`}
                      >
                        {opt}
                      </button>
                    ))}
                  </div>
                </div>
              ))}
            </div>

            <div className="flex justify-end pt-4">
              <button
                onClick={() => setStep(6)}
                disabled={Object.keys(sampleAnswers).length < 5}
                className="px-6 py-2.5 bg-electric-blue hover:bg-electric-blue/90 disabled:opacity-50 text-white font-bold text-sm rounded-xl flex items-center gap-2"
              >
                Reveal Starting Plan <ChevronRight className="w-4 h-4" />
              </button>
            </div>
          </div>
        )}

        {/* Step 6: Starting Plan Reveal & XP */}
        {step === 6 && (
          <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6 space-y-6 text-center">
            <div className="w-16 h-16 bg-emerald-500/10 text-emerald-400 rounded-full flex items-center justify-center mx-auto border border-emerald-500/20">
              <Award className="w-8 h-8" />
            </div>

            <div>
              <h2 className="text-2xl font-black text-white">Calibration Complete!</h2>
              <p className="text-sm text-slate-400 mt-1">
                Your initial 7-day preparation journey has been generated.
              </p>
            </div>

            <div className="grid grid-cols-2 gap-4 text-left">
              <div className="bg-slate-950 p-4 rounded-xl border border-slate-800">
                <span className="text-xs font-bold text-emerald-400 uppercase tracking-wider block">Identified Strength</span>
                <span className="font-bold text-white text-sm mt-1 block">Consistent Baseline Motivation</span>
                <p className="text-xs text-slate-500 mt-1">Strong foundation ready for adaptive DSA sprints.</p>
              </div>
              <div className="bg-slate-950 p-4 rounded-xl border border-slate-800">
                <span className="text-xs font-bold text-amber-400 uppercase tracking-wider block">Focus Priority</span>
                <span className="font-bold text-white text-sm mt-1 block">Core CS (DBMS & OS)</span>
                <p className="text-xs text-slate-500 mt-1">Scheduled for refreshing in your Daily Five queue.</p>
              </div>
            </div>

            {xpAwarded ? (
              <div className="bg-emerald-500/10 border border-emerald-500/30 text-emerald-400 p-4 rounded-xl flex items-center justify-center gap-2 font-bold animate-pulse">
                <Zap className="w-5 h-5" /> +50 Starter XP Awarded! Entering Today...
              </div>
            ) : (
              <button
                onClick={handleFinishOnboarding}
                disabled={submitting}
                className="w-full py-3.5 bg-electric-blue hover:bg-electric-blue/90 text-white font-bold rounded-xl shadow-lg transition-all flex items-center justify-center gap-2"
              >
                {submitting ? 'Setting up Companion...' : 'Claim Starter XP & Enter Today'}
                <ArrowRight className="w-4 h-4" />
              </button>
            )}
          </div>
        )}

      </div>
    </div>
  );
}
