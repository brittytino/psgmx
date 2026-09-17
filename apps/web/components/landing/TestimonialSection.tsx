'use client';

import React from 'react';
import Link from 'next/link';
import { ArrowRight, BookOpenCheck, Heart, LockKeyhole, ShieldCheck, Sparkles } from 'lucide-react';

const principles = [
  {
    title: 'Your progress stays yours',
    description: 'Readiness scores, streaks and gaps are private. Staff dashboards use cohort aggregates, never named student rankings.',
    icon: LockKeyhole,
    color: '#FF6B4A',
  },
  {
    title: 'Evidence before encouragement',
    description: 'Scores and guidance are grounded in verified attempts, participation and submitted work. Missing evidence is shown as missing.',
    icon: BookOpenCheck,
    color: '#E8B84B',
  },
  {
    title: 'Clear product boundaries',
    description: 'PSGMX supports preparation and historical interview learning. NEO PAT remains the source for official drives and applications.',
    icon: ShieldCheck,
    color: '#789B51',
  },
];

const guardrails = [
  { value: '5', label: 'Daily practice questions' },
  { value: '2 min', label: 'Maximum audio answer' },
  { value: '10', label: 'Saved audio attempts' },
  { value: '10 PM–7 AM', label: 'Notification quiet hours' },
];

export default function TestimonialSection() {
  return (
    <section id="testimonials" className="relative overflow-hidden py-24">
      <div className="absolute inset-x-0 top-0 h-px bg-gradient-to-r from-transparent via-[#EFE9E0] to-transparent" />
      <div className="mx-auto max-w-[1400px] px-6 md:px-10 lg:px-16">
        <div className="mb-16 max-w-4xl">
          <div className="mb-6 inline-flex items-center gap-2 rounded-full border border-[#EFE9E0] bg-white px-4 py-2 text-[11px] font-bold uppercase tracking-widest text-[#FF6B4A] shadow-sm">
            <Heart className="h-3 w-3 fill-[#FF6B4A]" /> Product principles
          </div>
          <h2 className="text-[2.8rem] font-black leading-[1.05] tracking-[-0.03em] text-[#221F1A] sm:text-[3.5rem] md:text-[4rem]">
            Supportive by design.<br />Honest about <span className="text-[#FF6B4A]">every signal.</span>
          </h2>
          <p className="mt-5 max-w-2xl text-[1.05rem] font-medium leading-relaxed text-[#716D64]">
            PSGMX is built to reduce preparation anxiety—not turn learning into public competition or make placement promises.
          </p>
        </div>

        <div className="mb-16 grid grid-cols-1 gap-6 md:grid-cols-3">
          {principles.map((principle) => (
            <article key={principle.title} className="rounded-3xl border border-[#EFE9E0] bg-white p-8 shadow-sm">
              <div className="mb-6 flex h-12 w-12 items-center justify-center rounded-2xl" style={{ background: `${principle.color}18`, color: principle.color }}>
                <principle.icon className="h-6 w-6" />
              </div>
              <h3 className="text-lg font-black text-[#221F1A]">{principle.title}</h3>
              <p className="mt-3 text-sm font-medium leading-6 text-[#716D64]">{principle.description}</p>
            </article>
          ))}
        </div>

        <div className="mb-16 grid grid-cols-2 gap-4 md:grid-cols-4">
          {guardrails.map((item) => (
            <div key={item.label} className="rounded-2xl border border-[#EFE9E0] bg-white p-6 text-center shadow-sm">
              <div className="text-2xl font-black text-[#FF6B4A]">{item.value}</div>
              <div className="mt-2 text-xs font-bold leading-tight text-[#9E9A92]">{item.label}</div>
            </div>
          ))}
        </div>

        <div id="about" className="relative flex flex-col items-center justify-between gap-10 overflow-hidden rounded-3xl bg-[#221F1A] p-10 md:flex-row md:p-16">
          <div className="pointer-events-none absolute -right-20 -top-20 h-80 w-80 rounded-full bg-[#FF6B4A]/20 blur-[100px]" />
          <div className="relative z-10 text-center md:text-left">
            <div className="mb-6 inline-flex items-center gap-2 rounded-full border border-white/10 bg-white/10 px-4 py-2 text-[11px] font-bold uppercase tracking-widest text-white/60">
              <Sparkles className="h-3 w-3" /> Continue your preparation
            </div>
            <h2 className="text-[2.2rem] font-black leading-[1.05] tracking-[-0.03em] text-white sm:text-[2.8rem] md:text-[3.5rem]">
              Build readiness through<br /><span className="text-[#FF6B4A]">small verified steps.</span>
            </h2>
            <p className="mt-4 max-w-[540px] text-[15px] font-medium leading-relaxed text-white/50">
              Access is limited to department-approved student, staff and alumni identities using passwordless OTP.
            </p>
          </div>
          <Link href="/app" className="group relative z-10 flex shrink-0 items-center gap-2 rounded-2xl bg-[#FF6B4A] px-8 py-4 text-[15px] font-bold text-white shadow-2xl shadow-[#FF6B4A]/30 transition-all hover:-translate-y-0.5 hover:bg-[#E4572E]">
            Open PSGMX <ArrowRight className="h-4 w-4 transition-transform group-hover:translate-x-0.5" />
          </Link>
        </div>
      </div>
    </section>
  );
}
