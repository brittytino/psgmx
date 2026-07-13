'use client';

import React, { useState } from 'react';
import {
  CheckSquare, LineChart, QrCode, Briefcase,
  Bell, BookOpen, ArrowRight, Zap, Shield, Target
} from 'lucide-react';

const features = [
  {
    id: 'tasks',
    title: 'Task Management',
    subtitle: 'Daily Progress Engine',
    desc: 'Structured daily workflows that keep every student on track. Assign, monitor, and complete tasks with full accountability across your cohort.',
    icon: <CheckSquare className="w-5 h-5 text-white" />,
    accentBg: 'bg-[#E8B84B]',
    accentLight: 'bg-[#FFF8E7]',
    accentColor: '#E8B84B',
    metrics: ['10K+ tasks logged', 'Daily reminders', 'Progress tracking'],
    photo: 'https://images.unsplash.com/photo-1611532736597-de2d4265fba3?ixlib=rb-4.0.3&auto=format&fit=crop&w=600&q=80',
  },
  {
    id: 'readiness',
    title: 'Readiness Metrics',
    subtitle: 'Interview Preparedness',
    desc: 'Comprehensive analytics engine that quantifies your interview readiness with a composite score derived from mock tests, attendance, and task completion.',
    icon: <LineChart className="w-5 h-5 text-white" />,
    accentBg: 'bg-[#FF6B4A]',
    accentLight: 'bg-[#FFF0EA]',
    accentColor: '#FF6B4A',
    metrics: ['Score 0–100', 'Weekly reports', 'Gap analysis'],
    photo: 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?ixlib=rb-4.0.3&auto=format&fit=crop&w=600&q=80',
  },
  {
    id: 'attendance',
    title: 'Auto Attendance',
    subtitle: 'QR-Based Tracking',
    desc: 'Frictionless attendance via integrated QR technology. Students scan, records are logged instantly, coordinators get real-time visibility—no paperwork needed.',
    icon: <QrCode className="w-5 h-5 text-white" />,
    accentBg: 'bg-[#789B51]',
    accentLight: 'bg-[#EAF6EC]',
    accentColor: '#789B51',
    metrics: ['Zero paperwork', 'Real-time sync', 'Auto-reports'],
    photo: 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?ixlib=rb-4.0.3&auto=format&fit=crop&w=600&q=80',
  },
  {
    id: 'placements',
    title: 'Placement Intel',
    subtitle: 'Opportunity Dashboard',
    desc: 'Centralised feed of active placement drives, company requirements, deadlines and application statuses—all in one intelligent dashboard.',
    icon: <Briefcase className="w-5 h-5 text-white" />,
    accentBg: 'bg-[#6B8CFF]',
    accentLight: 'bg-[#EEF2FF]',
    accentColor: '#6B8CFF',
    metrics: ['100+ drives', 'Live updates', 'Company profiles'],
    photo: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?ixlib=rb-4.0.3&auto=format&fit=crop&w=600&q=80',
  },
  {
    id: 'announcements',
    title: 'Announcements',
    subtitle: 'Instant Notifications',
    desc: 'Push critical announcements directly to students and faculty. Never miss a deadline, drive, or update with the smart notification engine.',
    icon: <Bell className="w-5 h-5 text-white" />,
    accentBg: 'bg-[#E87070]',
    accentLight: 'bg-[#FEEEEE]',
    accentColor: '#E87070',
    metrics: ['Push alerts', 'Priority tagging', 'Read receipts'],
    photo: 'https://images.unsplash.com/photo-1586281380349-632531db7ed4?ixlib=rb-4.0.3&auto=format&fit=crop&w=600&q=80',
  },
  {
    id: 'knowledge',
    title: 'Knowledge Brain',
    subtitle: 'Resource Library',
    desc: 'Curated resource repository: notes, previous interview questions, company profiles and study materials—all searchable, all accessible.',
    icon: <BookOpen className="w-5 h-5 text-white" />,
    accentBg: 'bg-[#C47ED6]',
    accentLight: 'bg-[#F7EEFB]',
    accentColor: '#C47ED6',
    metrics: ['Curated resources', 'Company-specific', 'Always updated'],
    photo: 'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?ixlib=rb-4.0.3&auto=format&fit=crop&w=600&q=80',
  },
];

const whyPoints = [
  { icon: <Zap className="w-5 h-5" />, title: 'Built for Speed', desc: 'Everything loads instantly. No bloat, no lag.' },
  { icon: <Shield className="w-5 h-5" />, title: 'Secure by Design', desc: 'Row-level auth ensures your data stays private.' },
  { icon: <Target className="w-5 h-5" />, title: 'PSG-Specific', desc: 'Engineered around PSG Tech MCA placement workflows.' },
];

export default function FeatureSection() {
  const [active, setActive] = useState(0);
  const feat = features[active];

  return (
    <section id="features" className="py-24 relative overflow-hidden">
      {/* Background */}
      <div className="absolute inset-0 -z-10 pointer-events-none">
        <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[900px] h-px bg-gradient-to-r from-transparent via-[#EFE9E0] to-transparent" />
      </div>

      <div className="max-w-[1400px] mx-auto px-6 md:px-10 lg:px-16">

        {/* ── SECTION HEADER ── */}
        <div className="text-center mb-20">
          <div className="inline-flex items-center gap-2 px-4 py-2 bg-white border border-[#EFE9E0] rounded-full text-[#FF6B4A] font-bold text-[11px] uppercase tracking-widest mb-6 shadow-sm">
            <span className="w-1.5 h-1.5 rounded-full bg-[#FF6B4A] animate-pulse" />
            Platform Features
          </div>
          <h2 className="text-[2.8rem] sm:text-[3.5rem] md:text-[4rem] font-black text-[#221F1A] tracking-[-0.03em] leading-[1.05] mb-5">
            Every tool you need<br />to <span className="text-[#FF6B4A]">succeed.</span>
          </h2>
          <p className="text-[#716D64] text-[1.05rem] md:text-[1.1rem] font-medium leading-relaxed max-w-[560px] mx-auto">
            PSGMX unifies your entire placement preparation into a single, intelligent platform—so you can focus on growth, not logistics.
          </p>
        </div>

        {/* ── INTERACTIVE FEATURE EXPLORER ── */}
        <div className="flex flex-col xl:flex-row gap-8 mb-24">
          {/* Left: Tab list */}
          <div className="xl:w-[38%] flex flex-row xl:flex-col gap-2 overflow-x-auto pb-2 xl:pb-0 xl:overflow-visible">
            {features.map((f, i) => (
              <button
                key={f.id}
                onClick={() => setActive(i)}
                className={`group flex items-center gap-4 p-4 rounded-2xl border transition-all text-left shrink-0 xl:shrink w-max xl:w-full ${
                  active === i
                    ? 'bg-white border-[#EFE9E0] shadow-md'
                    : 'bg-transparent border-transparent hover:bg-white/70 hover:border-[#EFE9E0]'
                }`}
              >
                <div
                  className={`w-10 h-10 rounded-xl flex items-center justify-center shrink-0 transition-all ${f.accentBg}`}
                  style={active !== i ? { opacity: 0.5, filter: 'grayscale(0.3)' } : {}}
                >
                  {f.icon}
                </div>
                <div className="hidden sm:block">
                  <div className={`font-bold text-[14px] leading-tight transition-colors ${active === i ? 'text-[#221F1A]' : 'text-[#9E9A92]'}`}>
                    {f.title}
                  </div>
                  <div className={`text-[12px] font-medium leading-tight mt-0.5 transition-colors ${active === i ? 'text-[#716D64]' : 'text-[#B5AFA5]'}`}>
                    {f.subtitle}
                  </div>
                </div>
                {active === i && (
                  <div className="ml-auto shrink-0 w-1.5 h-1.5 rounded-full hidden sm:block" style={{ background: feat.accentColor }} />
                )}
              </button>
            ))}
          </div>

          {/* Right: Feature detail card */}
          <div className="xl:w-[62%] bg-white rounded-3xl border border-[#EFE9E0] shadow-xl overflow-hidden flex flex-col md:flex-row min-h-[420px]">
            {/* Photo */}
            <div className="md:w-[45%] relative overflow-hidden bg-[#F5EFE6] min-h-[250px] md:min-h-0">
              <img
                key={feat.id}
                src={feat.photo}
                alt={feat.title}
                className="w-full h-full object-cover opacity-90 transition-opacity duration-300"
              />
              <div className="absolute inset-0 bg-gradient-to-br from-black/20 to-transparent" />
              <div className={`absolute top-4 left-4 w-12 h-12 rounded-2xl ${feat.accentBg} flex items-center justify-center shadow-lg`}>
                {feat.icon}
              </div>
            </div>

            {/* Content */}
            <div className="md:w-[55%] p-8 flex flex-col justify-between">
              <div>
                <div className="text-[11px] font-bold uppercase tracking-widest mb-2" style={{ color: feat.accentColor }}>
                  {feat.subtitle}
                </div>
                <h3 className="text-[1.6rem] font-black text-[#221F1A] tracking-tight leading-tight mb-4">
                  {feat.title}
                </h3>
                <p className="text-[#716D64] text-[14px] font-medium leading-relaxed mb-6">
                  {feat.desc}
                </p>
                <div className="flex flex-wrap gap-2 mb-8">
                  {feat.metrics.map((m, i) => (
                    <span
                      key={i}
                      className="px-3 py-1.5 rounded-xl text-[12px] font-bold"
                      style={{ background: feat.accentColor + '18', color: feat.accentColor }}
                    >
                      {m}
                    </span>
                  ))}
                </div>
              </div>
              <a
                href="/app"
                className="inline-flex items-center gap-2 font-bold text-[14px] group"
                style={{ color: feat.accentColor }}
              >
                Explore in the app
                <ArrowRight className="w-4 h-4 group-hover:translate-x-0.5 transition-transform" />
              </a>
            </div>
          </div>
        </div>

        {/* ── WHY PSGMX ── */}
        <div className="bg-[#221F1A] rounded-3xl p-10 md:p-14 flex flex-col md:flex-row items-start gap-12 md:gap-8 mb-16">
          <div className="md:w-[40%]">
            <div className="inline-flex items-center gap-2 px-3 py-1.5 bg-white/10 border border-white/10 rounded-full text-white/60 font-bold text-[11px] uppercase tracking-widest mb-6">
              Why PSGMX
            </div>
            <h3 className="text-[2rem] md:text-[2.5rem] font-black text-white tracking-tight leading-tight mb-4">
              Purpose-built for<br /><span className="text-[#FF6B4A]">your cohort.</span>
            </h3>
            <p className="text-white/50 text-[14px] font-medium leading-relaxed">
              Not a generic SaaS. Not repurposed software. PSGMX was built ground-up for PSG Tech MCA placement workflows by people who lived through them.
            </p>
          </div>
          <div className="md:w-[60%] grid grid-cols-1 sm:grid-cols-3 gap-4">
            {whyPoints.map((pt, i) => (
              <div key={i} className="bg-white/5 border border-white/8 rounded-2xl p-6 hover:bg-white/10 transition-colors">
                <div className="w-10 h-10 rounded-xl bg-[#FF6B4A]/20 flex items-center justify-center text-[#FF6B4A] mb-4">
                  {pt.icon}
                </div>
                <h4 className="text-white font-bold text-[15px] mb-2 leading-tight">{pt.title}</h4>
                <p className="text-white/40 text-[13px] font-medium leading-relaxed">{pt.desc}</p>
              </div>
            ))}
          </div>
        </div>

        {/* ── STATS ROW ── */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          {[
            { value: '120+', label: 'Students Onboarded', color: '#FF6B4A' },
            { value: '10K+', label: 'Tasks Completed', color: '#E8B84B' },
            { value: '99%', label: 'Uptime', color: '#8FB996' },
            { value: '100+', label: 'Placement Drives', color: '#6B8CFF' },
          ].map((s, i) => (
            <div key={i} className="bg-white rounded-2xl border border-[#EFE9E0] p-6 text-center shadow-sm hover:shadow-md transition-shadow">
              <div className="text-[2.2rem] font-black leading-none mb-2" style={{ color: s.color }}>
                {s.value}
              </div>
              <div className="text-[#9E9A92] text-[12px] font-bold leading-tight">{s.label}</div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
