'use client';

import React from 'react';
import Link from 'next/link';
import {
  Heart, Monitor, ArrowRight, ChevronRight,
  CheckSquare, LineChart, CalendarCheck, ShieldCheck,
  TrendingUp, Users, Star
} from 'lucide-react';

export default function HeroSection() {
  return (
    <section className="relative pt-24 pb-0 overflow-hidden min-h-screen flex flex-col justify-center">
      {/* Background decorations */}
      <div className="absolute inset-0 -z-10 pointer-events-none">
        <div className="absolute top-1/4 right-[10%] w-[500px] h-[500px] bg-[#FF6B4A]/8 rounded-full blur-[120px]" />
        <div className="absolute bottom-1/4 left-[5%] w-[400px] h-[400px] bg-[#E8B84B]/8 rounded-full blur-[100px]" />
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[800px] h-[800px] bg-[#8FB996]/4 rounded-full blur-[150px]" />
      </div>

      {/* Grid overlay */}
      <div
        className="absolute inset-0 -z-10 opacity-[0.02] pointer-events-none"
        style={{
          backgroundImage: `linear-gradient(#221F1A 1px, transparent 1px), linear-gradient(90deg, #221F1A 1px, transparent 1px)`,
          backgroundSize: '60px 60px',
        }}
      />

      <div className="max-w-[1400px] mx-auto px-6 md:px-10 lg:px-16 w-full">
        <div className="flex flex-col lg:flex-row items-center justify-between gap-12 lg:gap-8 py-16 lg:py-20">
          {/* ── LEFT CONTENT ── */}
          <div className="w-full lg:w-[48%] flex flex-col items-start">
            {/* Badge */}
            <div className="flex items-center gap-2 px-4 py-2 rounded-full bg-white border border-[#FFE2D6] text-[#FF6B4A] font-bold text-[12px] mb-8 w-max shadow-sm">
              <Heart className="w-3 h-3 fill-[#FF6B4A]" />
              Welcome to the crew!
              <span className="w-1 h-1 rounded-full bg-[#FF6B4A]/40" />
              PSG Tech MCA
            </div>

            {/* Headline */}
            <h1 className="text-[3.2rem] sm:text-[3.8rem] md:text-[4.4rem] xl:text-[5rem] font-black text-[#221F1A] leading-[1.02] tracking-[-0.03em] mb-6">
              Your Placement<br />
              Journey.<br />
              <span
                className="text-transparent"
                style={{
                  WebkitTextStroke: '2px #FF6B4A',
                  paintOrder: 'stroke fill',
                }}
              >
                Simplified.
              </span>
            </h1>

            <p className="text-[1.05rem] md:text-[1.15rem] text-[#716D64] leading-relaxed max-w-[480px] mb-10 font-medium">
              PSGMX is the all-in-one placement operating system built for PSG Tech MCA. Track progress, prepare smarter, and succeed—together.
            </p>

            {/* Stat pills row */}
            <div className="flex flex-wrap items-center gap-3 mb-10">
              {[
                { icon: <CheckSquare className="w-4 h-4 text-[#E8B84B]" />, bg: 'bg-[#FFF8E7]', label: 'Daily Tasks', sub: 'Stay on track' },
                { icon: <LineChart className="w-4 h-4 text-[#FF6B4A]" />, bg: 'bg-[#FFF0EA]', label: 'Readiness', sub: 'Know your score' },
                { icon: <CalendarCheck className="w-4 h-4 text-[#8FB996]" />, bg: 'bg-[#EAF6EC]', label: 'Attendance', sub: 'Never miss' },
              ].map((pill, i) => (
                <div
                  key={i}
                  className="flex items-center gap-3 bg-white rounded-2xl py-2.5 px-4 shadow-sm border border-[#F0EAE1] hover:-translate-y-0.5 transition-transform cursor-default"
                >
                  <div className={`w-8 h-8 rounded-lg ${pill.bg} flex items-center justify-center shrink-0`}>
                    {pill.icon}
                  </div>
                  <div>
                    <div className="text-[#221F1A] font-bold text-[13px] leading-tight">{pill.label}</div>
                    <div className="text-[#9E9A92] text-[11px] font-medium leading-tight">{pill.sub}</div>
                  </div>
                </div>
              ))}
            </div>

            {/* CTAs */}
            <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-3 w-full sm:w-auto mb-8">
              <Link
                href="/app"
                className="flex items-center justify-center gap-2 px-7 py-4 rounded-2xl bg-[#FF6B4A] text-white font-bold text-[15px] hover:bg-[#E4572E] transition-all shadow-xl shadow-[#FF6B4A]/25 hover:shadow-[#FF6B4A]/40 hover:-translate-y-0.5 group"
              >
                <Monitor className="w-4 h-4" />
                Open Web App
                <ArrowRight className="w-4 h-4 ml-1 group-hover:translate-x-0.5 transition-transform" />
              </Link>
              <a
                href="#features"
                className="flex items-center justify-center gap-2 px-7 py-4 rounded-2xl bg-white text-[#221F1A] font-bold text-[15px] hover:bg-[#F7F0E6] border border-[#EFE9E0] shadow-sm transition-all hover:-translate-y-0.5"
              >
                Explore Features
                <ChevronRight className="w-4 h-4 text-[#9E9A92]" />
              </a>
            </div>

            {/* Trust line */}
            <div className="flex items-center gap-2 text-[#9E9A92] text-sm font-medium">
              <ShieldCheck className="w-4 h-4 text-[#8FB996] shrink-0" />
              <span>Trusted by students, coordinators &amp; departments at PSG Tech</span>
            </div>
          </div>

          {/* ── RIGHT CONTENT ── */}
          <div className="w-full lg:w-[52%] relative flex items-center justify-center lg:justify-end">
            <div className="relative w-full max-w-[600px] lg:max-w-none">
              {/* Main hero image */}
              <div className="relative rounded-3xl overflow-hidden">
                <img
                  src="/landing/hero.png"
                  alt="PSGMX Dashboard"
                  className="w-full h-auto object-contain drop-shadow-2xl"
                />
              </div>

              {/* Floating stat card – top left */}
              <div className="absolute -left-4 top-8 bg-white rounded-2xl shadow-xl border border-[#F0EAE1] p-4 hidden sm:flex items-center gap-3 animate-float-slow">
                <div className="w-10 h-10 rounded-xl bg-[#FFF0EA] flex items-center justify-center">
                  <TrendingUp className="w-5 h-5 text-[#FF6B4A]" />
                </div>
                <div>
                  <div className="text-[#221F1A] font-black text-[18px] leading-none">85%</div>
                  <div className="text-[#9E9A92] text-[11px] font-medium mt-0.5">Readiness Score</div>
                </div>
              </div>

              {/* Floating badge – bottom left */}
              <div className="absolute -left-2 bottom-16 bg-white rounded-2xl shadow-xl border border-[#F0EAE1] py-3 px-4 hidden sm:flex items-center gap-2.5" style={{ animationDelay: '2s' }}>
                <div className="flex -space-x-2">
                  {[11,12,13].map(i => (
                    <img key={i} src={`https://i.pravatar.cc/40?img=${i}`} alt="" className="w-7 h-7 rounded-full border-2 border-white object-cover" />
                  ))}
                </div>
                <div>
                  <div className="text-[#221F1A] font-bold text-[12px]">120+ Students</div>
                  <div className="flex items-center gap-1">
                    {[1,2,3,4,5].map(s => <Star key={s} className="w-2.5 h-2.5 fill-[#E8B84B] text-[#E8B84B]" />)}
                  </div>
                </div>
              </div>

              {/* Floating task pill – top right */}
              <div className="absolute -right-2 top-1/4 bg-white rounded-2xl shadow-xl border border-[#F0EAE1] p-3 hidden lg:flex items-center gap-2.5 animate-float-slow" style={{ animationDelay: '1s' }}>
                <div className="w-8 h-8 rounded-xl bg-[#EAF6EC] flex items-center justify-center">
                  <CheckSquare className="w-4 h-4 text-[#8FB996]" />
                </div>
                <div>
                  <div className="text-[#221F1A] font-bold text-[12px] leading-tight">3 Tasks Done</div>
                  <div className="text-[#9E9A92] text-[10px] font-medium">Today's progress</div>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* ── MARQUEE TRUST BAR ── */}
        <div className="border-t border-[#EFE9E0] py-6 flex items-center gap-8 overflow-hidden">
          <span className="text-[#9E9A92] text-[12px] font-bold uppercase tracking-widest shrink-0">Used by</span>
          <div className="flex items-center gap-12 text-[#B5AFA5] font-black text-[13px] tracking-tight overflow-hidden">
            {['PSG Tech MCA', 'Placement Cell', 'Faculty Council', 'Alumni Network', 'Student Senate'].map((t, i) => (
              <React.Fragment key={i}>
                <span className="shrink-0 hover:text-[#FF6B4A] transition-colors cursor-default">{t}</span>
                {i < 4 && <span className="shrink-0 text-[#E0D9CE]">·</span>}
              </React.Fragment>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
