'use client';

import React, { useEffect, useState } from 'react';
import { ShieldCheck, Target, Calendar, CheckCircle2, Plus, MessageSquare, ArrowRight, Loader2, HeartHandshake } from 'lucide-react';
import { createClient } from '@/lib/supabase/client';
import { getCurrentProfile } from '@/lib/current-profile';

interface SupportCase {
  id: string;
  case_type: string;
  title: string;
  context: string;
  status: string;
  goal: string | null;
  action_plan: any[];
  review_at: string | null;
  resolution: string | null;
  created_at: string;
}

type CaseType = 'student_request' | 'evidence_gap' | 'assessment_support' | 'academic_continuity' | 'identity' | 'privacy' | 'technical';

export default function StudentRecoveryHubPage() {
  const [cases, setCases] = useState<SupportCase[]>([]);
  const [loading, setLoading] = useState(true);
  const [showRequestModal, setShowRequestModal] = useState(false);
  const [requestTitle, setRequestTitle] = useState('');
  const [requestContext, setRequestContext] = useState('');
  const [requestType, setRequestType] = useState<CaseType>('assessment_support');
  const [submitting, setSubmitting] = useState(false);
  const [feedbackMsg, setFeedbackMsg] = useState('');

  const supabase = createClient();

  useEffect(() => {
    loadCases();
  }, []);

  async function loadCases() {
    try {
      setLoading(true);
      const me = await getCurrentProfile(supabase);
      if (!me) {
        setLoading(false);
        return;
      }

      const { data, error } = await supabase
        .from('support_cases')
        .select('*')
        .eq('student_id', me.id)
        .order('created_at', { ascending: false });

      if (!error && data) {
        setCases(data as SupportCase[]);
      }
    } catch (err) {
      console.error('Failed to load support cases:', err);
    } finally {
      setLoading(false);
    }
  }

  async function handleCreateRequest(e: React.FormEvent) {
    e.preventDefault();
    if (!requestTitle.trim() || !requestContext.trim()) return;

    setSubmitting(true);
    try {
      const me = await getCurrentProfile(supabase);
      if (!me) throw new Error('Not authenticated');

      const { error } = await supabase.from('support_cases').insert({
        student_id: me.id,
        created_by: me.id,
        title: requestTitle.trim(),
        context: requestContext.trim(),
        case_type: requestType,
        status: 'requested',
        privacy_level: 'faculty_student',
      });

      if (error) throw error;

      setFeedbackMsg('Support request submitted successfully. Your faculty mentor will review it.');
      setRequestTitle('');
      setRequestContext('');
      setShowRequestModal(false);
      await loadCases();
    } catch (err: any) {
      alert(err.message || 'Failed to submit support request');
    } finally {
      setSubmitting(false);
    }
  }

  if (loading) {
    return (
      <div className="flex min-h-64 items-center justify-center">
        <Loader2 className="h-6 w-6 animate-spin text-primary-purple" />
      </div>
    );
  }

  return (
    <div className="max-w-5xl mx-auto space-y-6 pb-12">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <span className="text-xs font-bold text-primary-purple uppercase tracking-wider block">
            Mentorship & Academic Support · PRD Chapter 7.4
          </span>
          <h1 className="text-2xl font-black text-text-main mt-1 flex items-center gap-2">
            <HeartHandshake className="w-6 h-6 text-primary-purple" />
            Support & Recovery Hub
          </h1>
          <p className="text-sm text-text-muted">
            Personalized recovery plans and guidance from your faculty mentors to strengthen your preparation foundation.
          </p>
        </div>

        <button
          onClick={() => setShowRequestModal(true)}
          className="inline-flex items-center gap-2 px-4 py-2.5 bg-primary-purple hover:bg-deep-violet text-white text-sm font-bold rounded-xl transition-colors shadow-sm self-start sm:self-auto"
        >
          <Plus className="w-4 h-4" /> Request Mentorship Support
        </button>
      </div>

      {feedbackMsg && (
        <div className="p-4 bg-emerald-50 border border-emerald-200 text-emerald-800 text-sm font-medium rounded-xl flex items-center justify-between">
          <span>{feedbackMsg}</span>
          <button onClick={() => setFeedbackMsg('')} className="text-xs font-bold text-emerald-700 underline">Dismiss</button>
        </div>
      )}

      {/* Overview Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="bg-white border border-border-light rounded-2xl p-5 shadow-sm">
          <span className="text-xs font-bold text-text-muted uppercase">Active Support Plans</span>
          <p className="text-3xl font-black text-text-main mt-2">
            {cases.filter(c => ['active', 'review_due', 'requested'].includes(c.status)).length}
          </p>
          <p className="text-xs text-text-muted mt-1">Direct mentor interventions</p>
        </div>
        <div className="bg-white border border-border-light rounded-2xl p-5 shadow-sm">
          <span className="text-xs font-bold text-text-muted uppercase">Completed Milestones</span>
          <p className="text-3xl font-black text-emerald-600 mt-2">
            {cases.filter(c => ['resolved', 'closed'].includes(c.status)).length}
          </p>
          <p className="text-xs text-text-muted mt-1">Successfully resolved cases</p>
        </div>
        <div className="bg-white border border-border-light rounded-2xl p-5 shadow-sm">
          <span className="text-xs font-bold text-text-muted uppercase">Privacy Guarantee</span>
          <p className="text-base font-bold text-text-main mt-2 flex items-center gap-1.5">
            <ShieldCheck className="w-5 h-5 text-primary-purple" /> Faculty-Student Private
          </p>
          <p className="text-xs text-text-muted mt-1">Never shared with batch peers or external drives</p>
        </div>
      </div>

      {/* Case List */}
      <div className="space-y-4">
        <h2 className="text-lg font-bold text-text-main">Your Support Plans & Requests</h2>

        {cases.length === 0 ? (
          <div className="bg-white border border-dashed border-border-light rounded-3xl p-12 text-center space-y-3">
            <HeartHandshake className="w-12 h-12 text-text-muted mx-auto" />
            <h3 className="font-bold text-text-main text-lg">No active recovery cases</h3>
            <p className="text-sm text-text-muted max-w-md mx-auto">
              You are currently on track with regular preparation. If you ever need focused assistance with algorithms, core CS, or mock exams, click &quot;Request Mentorship Support&quot;.
            </p>
          </div>
        ) : (
          <div className="space-y-3">
            {cases.map((c) => (
              <div key={c.id} className="bg-white border border-border-light rounded-2xl p-6 shadow-sm space-y-4">
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 border-b border-border-light pb-3">
                  <div>
                    <div className="flex items-center gap-2">
                      <span className={`px-2.5 py-0.5 text-[10px] font-bold uppercase rounded-full ${
                        c.status === 'resolved' || c.status === 'closed'
                          ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                          : c.status === 'active'
                          ? 'bg-primary-purple/10 text-primary-purple border border-primary-purple/20'
                          : 'bg-amber-50 text-amber-700 border border-amber-200'
                      }`}>
                        {c.status.replace('_', ' ')}
                      </span>
                      <span className="text-xs font-semibold text-text-muted uppercase">
                        {c.case_type.replace('_', ' ')}
                      </span>
                    </div>
                    <h3 className="text-base font-bold text-text-main mt-1">{c.title}</h3>
                  </div>

                  {c.review_at && (
                    <div className="flex items-center gap-1.5 text-xs text-text-muted">
                      <Calendar className="w-4 h-4 text-primary-purple" />
                      <span>Review: {new Date(c.review_at).toLocaleDateString('en-IN', { month: 'short', day: 'numeric', year: 'numeric' })}</span>
                    </div>
                  )}
                </div>

                <div className="text-sm text-text-muted leading-relaxed">
                  <p>{c.context}</p>
                </div>

                {c.goal && (
                  <div className="bg-page-bg p-4 rounded-xl border border-border-light">
                    <span className="text-xs font-bold text-text-main flex items-center gap-1.5 mb-1">
                      <Target className="w-4 h-4 text-primary-purple" /> Support Goal
                    </span>
                    <p className="text-xs text-text-muted">{c.goal}</p>
                  </div>
                )}

                {c.resolution && (
                  <div className="bg-emerald-50/50 p-4 rounded-xl border border-emerald-100">
                    <span className="text-xs font-bold text-emerald-800 flex items-center gap-1.5 mb-1">
                      <CheckCircle2 className="w-4 h-4 text-emerald-600" /> Resolution Notes
                    </span>
                    <p className="text-xs text-emerald-950">{c.resolution}</p>
                  </div>
                )}
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Modal for Requesting Support */}
      {showRequestModal && (
        <div className="fixed inset-0 bg-black/40 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl max-w-lg w-full p-6 shadow-xl border border-border-light space-y-5">
            <div className="flex items-center justify-between border-b border-border-light pb-3">
              <h3 className="font-bold text-lg text-text-main">Request Mentorship Support</h3>
              <button onClick={() => setShowRequestModal(false)} className="text-text-muted hover:text-text-main text-sm font-bold">✕</button>
            </div>

            <form onSubmit={handleCreateRequest} className="space-y-4">
              <div>
                <label className="text-xs font-bold text-text-muted uppercase block mb-1">Support Category</label>
                <select
                  value={requestType}
                  onChange={(e) => setRequestType(e.target.value as CaseType)}
                  className="w-full text-sm border border-border-light rounded-xl p-3 bg-page-bg focus:outline-none focus:border-primary-purple"
                >
                  <option value="assessment_support">Assessment & Test Preparation</option>
                  <option value="evidence_gap">Core CS & DSA Concept Gap</option>
                  <option value="student_request">General Mentorship / Career Advice</option>
                  <option value="academic_continuity">Academic Continuity</option>
                </select>
              </div>

              <div>
                <label className="text-xs font-bold text-text-muted uppercase block mb-1">Topic / Subject</label>
                <input
                  type="text"
                  placeholder="e.g. Difficulty with Dynamic Programming or DBMS ACID"
                  value={requestTitle}
                  onChange={(e) => setRequestTitle(e.target.value)}
                  required
                  className="w-full text-sm border border-border-light rounded-xl p-3 bg-page-bg focus:outline-none focus:border-primary-purple"
                />
              </div>

              <div>
                <label className="text-xs font-bold text-text-muted uppercase block mb-1">Details & How Mentor Can Help</label>
                <textarea
                  rows={4}
                  placeholder="Describe where you feel stuck or what concept you would like personalized guidance on..."
                  value={requestContext}
                  onChange={(e) => setRequestContext(e.target.value)}
                  required
                  className="w-full text-sm border border-border-light rounded-xl p-3 bg-page-bg focus:outline-none focus:border-primary-purple"
                />
              </div>

              <div className="flex justify-end gap-3 pt-2">
                <button
                  type="button"
                  onClick={() => setShowRequestModal(false)}
                  className="px-4 py-2 text-sm font-bold text-text-muted hover:text-text-main"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={submitting}
                  className="px-5 py-2.5 bg-primary-purple hover:bg-deep-violet text-white text-sm font-bold rounded-xl transition-colors shadow-sm disabled:opacity-50"
                >
                  {submitting ? 'Submitting...' : 'Submit Request'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
