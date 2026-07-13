'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import {
  Monitor, Smartphone, Download, ArrowRight, ChevronRight,
  ShieldCheck, Users, Clock, Check, Globe
} from 'lucide-react';

const platforms = [
  {
    id: 'web',
    icon: <Monitor className="w-6 h-6" />,
    iconColor: '#FF6B4A',
    iconBg: 'bg-[#FFF0EA]',
    name: 'PSGMX Web',
    tag: 'For Desktop & Laptop',
    tagColor: '#FF6B4A',
    desc: 'The full-power desktop experience. Deep analytics, multi-panel views, and keyboard-first navigation for maximum productivity.',
    cta: 'Open Web App',
    ctaHref: '/app',
    ctaStyle: 'bg-[#FF6B4A] text-white shadow-lg shadow-[#FF6B4A]/25 hover:bg-[#E4572E]',
    note: 'Best experience on desktop',
    highlights: ['Full feature access', 'Multi-panel layout', 'Keyboard shortcuts'],
    visual: (
      <div className="w-full bg-[#FBF6EE] rounded-2xl border border-[#EFE9E0] p-3 shadow-inner">
        {/* Browser chrome */}
        <div className="bg-white rounded-xl border border-[#EFE9E0] overflow-hidden shadow-sm">
          <div className="flex items-center gap-1.5 px-3 py-2 border-b border-[#EFE9E0] bg-[#FAFAFA]">
            <div className="w-2.5 h-2.5 rounded-full bg-red-400" />
            <div className="w-2.5 h-2.5 rounded-full bg-yellow-400" />
            <div className="w-2.5 h-2.5 rounded-full bg-green-400" />
            <div className="flex-1 mx-3 h-5 bg-[#F0EAE1] rounded-md flex items-center px-2">
              <Globe className="w-2.5 h-2.5 text-[#9E9A92] mr-1" />
              <div className="h-2 w-20 bg-[#E0D9CE] rounded-full" />
            </div>
          </div>
          <div className="flex h-28">
            <div className="w-1/4 border-r border-[#EFE9E0] bg-[#FAFAFA] p-2 flex flex-col gap-1.5">
              {[1,2,3,4].map(i => <div key={i} className="h-4 bg-[#EFE9E0] rounded-md" style={{ opacity: i === 1 ? 1 : 0.5 }} />)}
            </div>
            <div className="flex-1 p-2.5 flex flex-col gap-2">
              <div className="h-4 bg-[#FF6B4A]/15 rounded-md w-3/4" />
              <div className="h-2.5 bg-[#EFE9E0] rounded-md" />
              <div className="h-2.5 bg-[#EFE9E0] rounded-md w-5/6" />
              <div className="flex gap-2 mt-1">
                <div className="h-5 w-16 bg-[#FF6B4A] rounded-md" />
                <div className="h-5 w-16 bg-[#EFE9E0] rounded-md" />
              </div>
            </div>
          </div>
        </div>
      </div>
    ),
  },
  {
    id: 'iphone',
    icon: <Smartphone className="w-6 h-6" />,
    iconColor: '#221F1A',
    iconBg: 'bg-[#F5F5F5]',
    name: 'PSGMX for iPhone',
    tag: 'Install as PWA',
    tagColor: '#221F1A',
    desc: 'Add PSGMX to your iPhone home screen from Safari for a full app-like experience. No App Store needed—always up to date.',
    cta: 'Open in Safari',
    ctaHref: '/app',
    ctaStyle: 'bg-[#221F1A] text-white shadow-lg shadow-black/20 hover:bg-black',
    note: 'Add to Home Screen from Safari',
    highlights: ['PWA support', 'Offline mode', 'Push notifications'],
    visual: (
      <div className="flex justify-center">
        <div className="relative w-28 h-52 bg-[#221F1A] rounded-[2.2rem] border-[3px] border-[#333] shadow-2xl overflow-hidden flex flex-col">
          {/* Notch */}
          <div className="absolute top-0 left-1/2 -translate-x-1/2 w-16 h-4 bg-[#221F1A] rounded-b-2xl z-10" />
          <div className="flex-1 bg-[#FBF6EE] mt-4 rounded-t-[1.8rem] p-2 flex flex-col gap-1.5 overflow-hidden">
            <div className="h-3 bg-[#EFE9E0] rounded-md mt-1 w-3/4 mx-auto" />
            <div className="flex-1 grid grid-cols-3 gap-1 mt-1">
              {['FF6B4A','E8B84B','8FB996','6B8CFF','E87070','C47ED6'].map((c, i) => (
                <div key={i} className="aspect-square rounded-xl flex items-center justify-center" style={{ background: `#${c}25` }}>
                  <div className="w-3 h-3 rounded-md" style={{ background: `#${c}` }} />
                </div>
              ))}
            </div>
            <div className="mt-auto">
              <div className="w-8 h-1 bg-[#221F1A] rounded-full mx-auto mb-1" />
            </div>
          </div>
        </div>
      </div>
    ),
  },
  {
    id: 'android',
    icon: <Download className="w-6 h-6" />,
    iconColor: '#5A8A2E',
    iconBg: 'bg-[#EAF4E0]',
    name: 'PSGMX for Android',
    tag: 'Native APK',
    tagColor: '#5A8A2E',
    desc: 'Download the highly optimised Android application for a native, blazing-fast experience with hardware-level performance.',
    cta: 'Download APK',
    ctaHref: 'https://github.com/brittytino/psgmx/releases',
    ctaStyle: 'bg-[#5A8A2E] text-white shadow-lg shadow-[#5A8A2E]/25 hover:bg-[#4A7225]',
    note: 'Latest release from GitHub',
    highlights: ['Native performance', 'Background sync', 'Offline support'],
    visual: (
      <div className="flex justify-center">
        <div className="relative w-28 h-52 bg-[#221F1A] rounded-[2.2rem] border-[3px] border-[#333] shadow-2xl overflow-hidden flex flex-col">
          <div className="flex-1 bg-[#FBF6EE] m-1 rounded-[1.8rem] flex flex-col items-center justify-center gap-3 p-3">
            <div className="w-14 h-14 rounded-2xl bg-white shadow-md border border-[#EFE9E0] flex items-center justify-center">
              <img src="/logo.webp" alt="PSGMX" className="w-10 h-10 object-contain" />
            </div>
            <div className="text-[8px] font-black text-[#221F1A] tracking-wide">PSGMX</div>
            <div className="w-full">
              <div className="h-1 bg-[#EFE9E0] rounded-full overflow-hidden">
                <div className="h-full w-2/3 bg-[#5A8A2E] rounded-full animate-pulse" />
              </div>
              <div className="text-[7px] text-[#9E9A92] font-bold text-center mt-1">Installing...</div>
            </div>
          </div>
          <div className="flex justify-center py-2 gap-4">
            <div className="w-4 h-4 rounded-full border-2 border-[#555]" />
            <div className="w-4 h-4 rounded border-2 border-[#555]" />
            <div className="w-4 h-4 border-t-2 border-l-2 border-r-2 border-[#555]" style={{ borderRadius: '0 0 50% 50%' }} />
          </div>
        </div>
      </div>
    ),
  },
];

const trustItems = [
  { icon: <ShieldCheck className="w-5 h-5" />, label: 'Secure & Trusted', sub: 'Row-level auth, zero data leaks', color: '#E8B84B' },
  { icon: <Users className="w-5 h-5" />, label: '120+ Students', sub: 'Active on the platform', color: '#FF6B4A' },
  { icon: <Clock className="w-5 h-5" />, label: '99% Uptime', sub: 'Always there when it counts', color: '#8FB996' },
];

export default function AccessSection() {
  const [activePlatform, setActivePlatform] = useState(0);
  const plat = platforms[activePlatform];

  return (
    <section id="access" className="py-24 relative overflow-hidden">
      {/* Subtle bg */}
      <div className="absolute inset-0 -z-10 bg-[#F5EFE6]/40 pointer-events-none" />
      <div className="absolute top-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-[#EFE9E0] to-transparent" />

      <div className="max-w-[1400px] mx-auto px-6 md:px-10 lg:px-16">

        {/* Header */}
        <div className="text-center mb-16">
          <div className="inline-flex items-center gap-2 px-4 py-2 bg-white border border-[#EFE9E0] rounded-full text-[#FF6B4A] font-bold text-[11px] uppercase tracking-widest mb-6 shadow-sm">
            <span className="w-1.5 h-1.5 rounded-full bg-[#FF6B4A] animate-pulse" />
            Three Ways to Access
          </div>
          <h2 className="text-[2.8rem] sm:text-[3.5rem] md:text-[4rem] font-black text-[#221F1A] tracking-[-0.03em] leading-[1.05] mb-5">
            Seamless Access.<br />
            <span className="text-[#FF6B4A]">Absolute Control.</span>
          </h2>
          <p className="text-[#716D64] text-[1.05rem] md:text-[1.1rem] font-medium leading-relaxed max-w-[520px] mx-auto">
            Whether you're on desktop, iPhone, or Android—PSGMX is always at your fingertips, perfectly synced.
          </p>
        </div>

        {/* Platform Selector */}
        <div className="flex flex-wrap justify-center gap-2 mb-12">
          {platforms.map((p, i) => (
            <button
              key={p.id}
              onClick={() => setActivePlatform(i)}
              className={`flex items-center gap-2.5 px-5 py-3 rounded-2xl border font-bold text-[14px] transition-all ${
                activePlatform === i
                  ? 'bg-white border-[#EFE9E0] shadow-md text-[#221F1A]'
                  : 'bg-transparent border-[#EFE9E0] text-[#9E9A92] hover:bg-white/70 hover:text-[#221F1A]'
              }`}
            >
              <span className={`w-7 h-7 rounded-xl flex items-center justify-center ${p.iconBg} transition-all`} style={{ color: p.iconColor }}>
                {React.cloneElement(p.icon as React.ReactElement<{ className: string }>, { className: 'w-3.5 h-3.5' })}
              </span>
              {p.name}
            </button>
          ))}
        </div>

        {/* Active Platform Card */}
        <div className="bg-white rounded-3xl border border-[#EFE9E0] shadow-xl overflow-hidden mb-10">
          <div className="flex flex-col md:flex-row">
            {/* Visual */}
            <div className="md:w-[40%] bg-[#FBF6EE] p-10 flex items-center justify-center min-h-[280px]">
              {plat.visual}
            </div>

            {/* Details */}
            <div className="md:w-[60%] p-10 flex flex-col justify-center">
              <div className="flex items-center gap-3 mb-6">
                <div className={`w-12 h-12 rounded-2xl ${plat.iconBg} flex items-center justify-center`} style={{ color: plat.iconColor }}>
                  {plat.icon}
                </div>
                <div>
                  <div className="text-[11px] font-bold uppercase tracking-widest mb-0.5" style={{ color: plat.tagColor }}>
                    {plat.tag}
                  </div>
                  <h3 className="text-[1.5rem] font-black text-[#221F1A] tracking-tight leading-none">
                    {plat.name}
                  </h3>
                </div>
              </div>

              <p className="text-[#716D64] text-[15px] font-medium leading-relaxed mb-7">
                {plat.desc}
              </p>

              <div className="flex flex-wrap gap-2 mb-8">
                {plat.highlights.map((h, i) => (
                  <span key={i} className="inline-flex items-center gap-1.5 px-3 py-1.5 bg-[#FBF6EE] rounded-xl text-[#221F1A] text-[12px] font-bold border border-[#EFE9E0]">
                    <Check className="w-3 h-3 text-[#8FB996]" />
                    {h}
                  </span>
                ))}
              </div>

              <div className="flex flex-col sm:flex-row items-start sm:items-center gap-4">
                <Link
                  href={plat.ctaHref}
                  target={plat.id === 'android' ? '_blank' : undefined}
                  className={`inline-flex items-center gap-2 px-7 py-3.5 rounded-2xl font-bold text-[15px] transition-all hover:-translate-y-0.5 group ${plat.ctaStyle}`}
                >
                  {plat.cta}
                  <ArrowRight className="w-4 h-4 group-hover:translate-x-0.5 transition-transform" />
                </Link>
                <span className="text-[#9E9A92] text-[13px] font-medium flex items-center gap-1.5">
                  <ShieldCheck className="w-3.5 h-3.5 text-[#8FB996]" />
                  {plat.note}
                </span>
              </div>
            </div>
          </div>
        </div>

        {/* Trust Strip */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          {trustItems.map((t, i) => (
            <div key={i} className="bg-white rounded-2xl border border-[#EFE9E0] p-6 flex items-center gap-4 shadow-sm hover:shadow-md transition-shadow">
              <div className="w-12 h-12 rounded-2xl flex items-center justify-center shrink-0" style={{ background: t.color + '18', color: t.color }}>
                {t.icon}
              </div>
              <div>
                <div className="text-[#221F1A] font-bold text-[15px] leading-tight">{t.label}</div>
                <div className="text-[#9E9A92] text-[12px] font-medium mt-0.5">{t.sub}</div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
