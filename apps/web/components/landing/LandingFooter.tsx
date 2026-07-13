'use client';

import React from 'react';
import Link from 'next/link';
import { Instagram, Linkedin, Github, Heart, ArrowUpRight } from 'lucide-react';

const navLinks = {
  Product: [
    { label: 'Features', href: '#features' },
    { label: 'Access', href: '#access' },
    { label: 'Web App', href: '/app' },
    { label: 'Android APK', href: 'https://github.com/brittytino/psgmx/releases' },
  ],
  Platform: [
    { label: 'For Students', href: '/app' },
    { label: 'For Faculty', href: '/app' },
    { label: 'For Coordinators', href: '/app' },
    { label: 'For Alumni', href: '/app' },
  ],
  Resources: [
    { label: 'Help & Support', href: '#' },
    { label: 'Release Notes', href: 'https://github.com/brittytino/psgmx/releases' },
    { label: 'GitHub', href: 'https://github.com/brittytino/psgmx' },
  ],
  Legal: [
    { label: 'Privacy Policy', href: '#' },
    { label: 'Terms of Service', href: '#' },
  ],
};

const socials = [
  { icon: <Github className="w-4 h-4" />, href: 'https://github.com/brittytino/psgmx', label: 'GitHub' },
  { icon: <Instagram className="w-4 h-4" />, href: '#', label: 'Instagram' },
  { icon: <Linkedin className="w-4 h-4" />, href: '#', label: 'LinkedIn' },
];

export default function LandingFooter() {
  return (
    <footer className="relative border-t border-[#EFE9E0] bg-white">
      {/* Top section */}
      <div className="max-w-[1400px] mx-auto px-6 md:px-10 lg:px-16 pt-16 pb-10">
        <div className="grid grid-cols-2 md:grid-cols-12 gap-10 mb-14">

          {/* Brand */}
          <div className="col-span-2 md:col-span-4">
            <Link href="/" className="flex items-center gap-2.5 mb-5 group w-max">
              <img src="/logo.webp" alt="PSGMX Logo" className="w-9 h-9 object-contain drop-shadow-md transition-transform group-hover:scale-105" />
              <span className="text-[22px] font-black text-[#221F1A] tracking-tight">PSGMX</span>
            </Link>
            <p className="text-[#9E9A92] text-[14px] font-medium leading-relaxed max-w-[280px] mb-7">
              The all-in-one placement operating system built for PSG Tech MCA. Track, prepare, collaborate and succeed—together.
            </p>
            <div className="flex items-center gap-2">
              {socials.map((s, i) => (
                <Link
                  key={i}
                  href={s.href}
                  target="_blank"
                  aria-label={s.label}
                  className="w-10 h-10 rounded-full bg-[#FBF6EE] border border-[#EFE9E0] flex items-center justify-center text-[#716D64] hover:bg-[#FF6B4A] hover:text-white hover:border-[#FF6B4A] transition-all shadow-sm"
                >
                  {s.icon}
                </Link>
              ))}
            </div>
          </div>

          {/* Nav links */}
          {Object.entries(navLinks).map(([section, links]) => (
            <div key={section} className="col-span-1 md:col-span-2">
              <h5 className="font-bold text-[#221F1A] text-[13px] uppercase tracking-widest mb-5">{section}</h5>
              <ul className="space-y-3">
                {links.map((link, i) => (
                  <li key={i}>
                    <Link
                      href={link.href}
                      target={link.href.startsWith('http') ? '_blank' : undefined}
                      className="text-[#9E9A92] hover:text-[#FF6B4A] text-[14px] font-medium transition-colors flex items-center gap-1 group"
                    >
                      {link.label}
                      {link.href.startsWith('http') && (
                        <ArrowUpRight className="w-3 h-3 opacity-0 group-hover:opacity-100 transition-opacity" />
                      )}
                    </Link>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>

        {/* Newsletter strip */}
        <div className="bg-[#FBF6EE] rounded-2xl border border-[#EFE9E0] p-6 md:p-8 flex flex-col md:flex-row items-center justify-between gap-6 mb-10">
          <div>
            <h5 className="font-bold text-[#221F1A] text-[16px] mb-1">Stay in the loop</h5>
            <p className="text-[#9E9A92] text-[13px] font-medium">Get placement updates, feature launches, and tips.</p>
          </div>
          <div className="flex w-full md:w-auto gap-2">
            <input
              type="email"
              placeholder="your@email.com"
              className="flex-1 md:w-60 px-4 py-3 rounded-xl border border-[#EFE9E0] bg-white text-[14px] text-[#221F1A] font-medium placeholder-[#C5BFB4] outline-none focus:border-[#FF6B4A] transition-colors"
            />
            <button className="px-5 py-3 rounded-xl bg-[#FF6B4A] text-white font-bold text-[14px] hover:bg-[#E4572E] transition-colors shrink-0 shadow-md shadow-[#FF6B4A]/20">
              Subscribe
            </button>
          </div>
        </div>

        {/* Bottom bar */}
        <div className="flex flex-col md:flex-row items-center justify-between pt-6 border-t border-[#EFE9E0] gap-4">
          <p className="text-[#B5AFA5] text-[13px] font-medium">
            © {new Date().getFullYear()} PSGMX. All rights reserved.
          </p>

          <div className="flex items-center gap-1.5 px-5 py-2.5 rounded-full bg-[#FFFBF9] border border-[#EFE9E0] shadow-sm">
            <span className="text-[#716D64] text-[13px] font-bold">Made with</span>
            <Heart className="w-3.5 h-3.5 fill-[#FF6B4A] text-[#FF6B4A]" />
            <span className="text-[#716D64] text-[13px] font-bold">for</span>
            <span className="text-[#FF6B4A] text-[13px] font-black">PSG Tech MCA</span>
            <span className="text-[#B5AFA5] text-[11px] font-bold ml-1">· Batch 2025–2027</span>
          </div>

          <div className="flex items-center gap-5 text-[#B5AFA5] text-[13px] font-medium">
            <Link href="#" className="hover:text-[#FF6B4A] transition-colors">Privacy</Link>
            <Link href="#" className="hover:text-[#FF6B4A] transition-colors">Terms</Link>
          </div>
        </div>
      </div>
    </footer>
  );
}
