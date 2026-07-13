'use client';

import React from 'react';
import Link from 'next/link';
import {
  Heart, Star, Users, Trophy, LineChart,
  Target, ArrowRight, Sparkles, Quote
} from 'lucide-react';

const testimonials = [
  {
    quote: "The analytical insights completely transformed my approach to technical interviews. I went from feeling lost to confident in 3 weeks.",
    name: 'Aravind S',
    role: '1st Year MCA',
    dept: 'Student',
    rating: 5,
    avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?ixlib=rb-4.0.3&auto=format&fit=crop&w=150&q=80',
    highlight: '85% readiness score achieved',
    accentColor: '#FF6B4A',
  },
  {
    quote: "Consolidating everything into one platform—tasks, announcements, attendance—has cut our coordinator workload by 60%.",
    name: 'Keerthana M',
    role: '2nd Year MCA',
    dept: 'Placement Coordinator',
    rating: 5,
    avatar: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?ixlib=rb-4.0.3&auto=format&fit=crop&w=150&q=80',
    highlight: '60% less admin overhead',
    accentColor: '#E8B84B',
  },
  {
    quote: "Readiness metrics helped me pinpoint exactly which topics to focus on. I cleared three drives in one placement season.",
    name: 'Harish R',
    role: 'Alumni, Batch 2025',
    dept: 'Software Engineer @ TCS',
    rating: 5,
    avatar: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-4.0.3&auto=format&fit=crop&w=150&q=80',
    highlight: '3 offers in one season',
    accentColor: '#8FB996',
  },
];

const stats = [
  { value: '120+', label: 'Students Onboarded', icon: <Users className="w-5 h-5" />, color: '#FF6B4A' },
  { value: '10K+', label: 'Tasks Completed', icon: <Trophy className="w-5 h-5" />, color: '#E8B84B' },
  { value: '99%', label: 'Engagement Rate', icon: <LineChart className="w-5 h-5" />, color: '#8FB996' },
  { value: '100+', label: 'Placement Opportunities', icon: <Target className="w-5 h-5" />, color: '#6B8CFF' },
];

export default function TestimonialSection() {
  return (
    <section id="testimonials" className="py-24 relative overflow-hidden">
      {/* Top divider */}
      <div className="absolute top-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-[#EFE9E0] to-transparent" />

      <div className="max-w-[1400px] mx-auto px-6 md:px-10 lg:px-16">

        {/* ── SECTION HEADER ── */}
        <div className="flex flex-col lg:flex-row items-start lg:items-end justify-between gap-8 mb-16">
          <div>
            <div className="inline-flex items-center gap-2 px-4 py-2 bg-white border border-[#EFE9E0] rounded-full text-[#FF6B4A] font-bold text-[11px] uppercase tracking-widest mb-6 shadow-sm">
              <Heart className="w-3 h-3 fill-[#FF6B4A]" />
              Proven Impact
            </div>
            <h2 className="text-[2.8rem] sm:text-[3.5rem] md:text-[4rem] font-black text-[#221F1A] tracking-[-0.03em] leading-[1.05]">
              Empowering Students.<br />
              Trusted by <span className="text-[#FF6B4A]">Institutions.</span>
            </h2>
          </div>
          <div className="flex items-center gap-4 shrink-0">
            <div className="flex -space-x-3">
              {[11,12,13,14,15].map(i => (
                <img key={i} src={`https://i.pravatar.cc/100?img=${i}`} alt="" className="w-10 h-10 rounded-full border-2 border-white object-cover shadow-sm" />
              ))}
            </div>
            <div>
              <div className="font-black text-[#FF6B4A] text-[18px] leading-none">120+</div>
              <div className="text-[#9E9A92] text-[12px] font-medium mt-0.5">Active students</div>
            </div>
          </div>
        </div>

        {/* ── TESTIMONIAL CARDS ── */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-16">
          {testimonials.map((t, idx) => (
            <div
              key={idx}
              className="bg-white rounded-3xl border border-[#EFE9E0] shadow-sm hover:shadow-xl transition-all hover:-translate-y-1 p-8 flex flex-col justify-between group"
            >
              <div>
                {/* Top row */}
                <div className="flex items-start justify-between mb-6">
                  <div className="flex gap-1">
                    {[...Array(t.rating)].map((_, i) => (
                      <Star key={i} className="w-4 h-4 fill-[#FF6B4A] text-[#FF6B4A]" />
                    ))}
                  </div>
                  <Quote className="w-8 h-8 text-[#EFE9E0] group-hover:text-[#FF6B4A]/20 transition-colors" />
                </div>

                {/* Quote */}
                <p className="text-[#221F1A] font-medium leading-relaxed text-[15px] mb-6">
                  &ldquo;{t.quote}&rdquo;
                </p>

                {/* Highlight chip */}
                <div
                  className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-[12px] font-bold mb-6"
                  style={{ background: t.accentColor + '18', color: t.accentColor }}
                >
                  <span className="w-1.5 h-1.5 rounded-full" style={{ background: t.accentColor }} />
                  {t.highlight}
                </div>
              </div>

              {/* Author */}
              <div className="flex items-center gap-3 border-t border-[#F0EAE1] pt-5">
                <img
                  src={t.avatar}
                  alt={t.name}
                  className="w-11 h-11 rounded-full object-cover shadow-sm"
                />
                <div>
                  <div className="text-[#221F1A] font-bold text-[14px] leading-tight">{t.name}</div>
                  <div className="text-[#9E9A92] text-[12px] font-medium">{t.role}</div>
                  <div className="text-[11px] font-bold mt-0.5" style={{ color: t.accentColor }}>{t.dept}</div>
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* ── STATS STRIP ── */}
        <div className="bg-white rounded-3xl border border-[#EFE9E0] shadow-sm py-8 px-6 md:px-12 flex flex-wrap items-center justify-between gap-8 mb-16">
          {stats.map((s, i) => (
            <React.Fragment key={i}>
              <div className="flex items-center gap-4">
                <div className="w-12 h-12 rounded-2xl flex items-center justify-center shrink-0" style={{ background: s.color + '18', color: s.color }}>
                  {s.icon}
                </div>
                <div>
                  <div className="font-black text-[#221F1A] text-[22px] leading-none">{s.value}</div>
                  <div className="text-[#9E9A92] text-[12px] font-medium mt-0.5">{s.label}</div>
                </div>
              </div>
              {i < stats.length - 1 && <div className="hidden md:block w-px h-12 bg-[#EFE9E0]" />}
            </React.Fragment>
          ))}
        </div>

        {/* ── FINAL CTA BANNER ── */}
        <div
          id="about"
          className="relative rounded-3xl overflow-hidden bg-[#221F1A] p-10 md:p-16 flex flex-col md:flex-row items-center justify-between gap-10"
        >
          {/* Background glow */}
          <div className="absolute -top-20 -right-20 w-80 h-80 rounded-full bg-[#FF6B4A]/20 blur-[100px] pointer-events-none" />
          <div className="absolute -bottom-20 -left-20 w-80 h-80 rounded-full bg-[#E8B84B]/10 blur-[100px] pointer-events-none" />

          {/* Decorative circles */}
          <div className="absolute top-6 left-6 w-24 h-24 border border-white/5 rounded-full" />
          <div className="absolute top-4 left-4 w-32 h-32 border border-white/5 rounded-full" />

          <div className="relative z-10 text-center md:text-left">
            <div className="inline-flex items-center gap-2 px-4 py-2 bg-white/10 border border-white/10 rounded-full text-white/60 font-bold text-[11px] uppercase tracking-widest mb-6">
              <Sparkles className="w-3 h-3" />
              Commence Your Journey
            </div>
            <h2 className="text-[2.2rem] sm:text-[2.8rem] md:text-[3.5rem] font-black text-white tracking-[-0.03em] leading-[1.05] mb-4">
              Take command of your<br />
              <span className="text-[#FF6B4A]">career trajectory.</span>
            </h2>
            <p className="text-white/50 text-[15px] font-medium leading-relaxed max-w-[500px]">
              Join the PSGMX ecosystem and equip yourself with industry-grade tools to excel in placements—built by students, for students.
            </p>
          </div>

          <div className="relative z-10 flex flex-col items-center md:items-start gap-4 shrink-0">
            <Link
              href="/app"
              className="flex items-center gap-2 px-8 py-4 rounded-2xl bg-[#FF6B4A] text-white font-bold text-[15px] hover:bg-[#E4572E] transition-all shadow-2xl shadow-[#FF6B4A]/30 hover:-translate-y-0.5 group"
            >
              Enter the Ecosystem
              <ArrowRight className="w-4 h-4 group-hover:translate-x-0.5 transition-transform" />
            </Link>
            <div className="flex items-center gap-2 text-white/40 text-[13px] font-medium">
              <Heart className="w-3.5 h-3.5 fill-white/40" />
              Made with love for PSG Tech MCA
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
