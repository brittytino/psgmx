'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { Menu, Monitor, ChevronDown, X, ArrowRight } from 'lucide-react';

export default function LandingNavbar() {
  const [scrolled, setScrolled] = useState(false);
  const [mobileOpen, setMobileOpen] = useState(false);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 20);
    window.addEventListener('scroll', onScroll, { passive: true });
    return () => window.removeEventListener('scroll', onScroll);
  }, []);

  return (
    <>
      <nav
        className={`fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${
          scrolled
            ? 'bg-[#FBF6EE]/95 backdrop-blur-xl border-b border-[#EFE9E0] shadow-sm'
            : 'bg-transparent'
        }`}
      >
        <div className="max-w-[1400px] mx-auto h-[72px] flex items-center justify-between px-6 md:px-10 lg:px-16">
          {/* Logo */}
          <Link href="/" className="flex items-center gap-2.5 group">
            <div className="relative">
              <img src="/logo.webp" alt="PSGMX Logo" className="w-9 h-9 object-contain drop-shadow-md transition-transform group-hover:scale-105" />
            </div>
            <span className="text-[22px] font-black text-[#221F1A] tracking-tight">PSGMX</span>
          </Link>

          {/* Desktop Links */}
          <div className="hidden lg:flex items-center gap-1">
            <NavLink href="#features">Features</NavLink>
            <NavLink href="#access">Access</NavLink>
            <NavLink href="#testimonials">Reviews</NavLink>
            <NavLink href="#about">About</NavLink>
          </div>

          {/* Right Actions */}
          <div className="flex items-center gap-3">
            <Link
              href="/app"
              className="hidden sm:flex items-center gap-2 px-5 py-2 rounded-full bg-[#FF6B4A] text-white font-bold text-[13px] hover:bg-[#E4572E] transition-all shadow-md shadow-[#FF6B4A]/20 hover:shadow-lg hover:shadow-[#FF6B4A]/30 hover:-translate-y-0.5"
            >
              <Monitor className="w-3.5 h-3.5" />
              Open App
            </Link>

            <button
              onClick={() => setMobileOpen(!mobileOpen)}
              className="w-10 h-10 rounded-full bg-white border border-[#EFE9E0] flex items-center justify-center text-[#221F1A] hover:bg-[#FBF6EE] transition-colors lg:hidden shadow-sm"
            >
              {mobileOpen ? <X className="w-4 h-4" /> : <Menu className="w-4 h-4" />}
            </button>
          </div>
        </div>
      </nav>

      {/* Mobile Menu */}
      <div
        className={`fixed inset-0 z-40 lg:hidden transition-all duration-300 ${
          mobileOpen ? 'opacity-100 pointer-events-auto' : 'opacity-0 pointer-events-none'
        }`}
      >
        <div
          className="absolute inset-0 bg-black/20 backdrop-blur-sm"
          onClick={() => setMobileOpen(false)}
        />
        <div
          className={`absolute top-[72px] left-4 right-4 bg-white rounded-2xl border border-[#EFE9E0] shadow-2xl p-6 transition-all duration-300 ${
            mobileOpen ? 'translate-y-0 opacity-100' : '-translate-y-4 opacity-0'
          }`}
        >
          <div className="flex flex-col gap-1 mb-6">
            {[['#features','Features'],['#access','Access'],['#testimonials','Reviews'],['#about','About']].map(([href, label]) => (
              <a
                key={href}
                href={href}
                onClick={() => setMobileOpen(false)}
                className="px-4 py-3 rounded-xl text-[#221F1A] font-bold text-[15px] hover:bg-[#FBF6EE] transition-colors"
              >
                {label}
              </a>
            ))}
          </div>
          <Link
            href="/app"
            onClick={() => setMobileOpen(false)}
            className="w-full flex items-center justify-center gap-2 px-6 py-3.5 rounded-xl bg-[#FF6B4A] text-white font-bold text-[14px] hover:bg-[#E4572E] transition-all"
          >
            <Monitor className="w-4 h-4" />
            Open Web App
            <ArrowRight className="w-4 h-4 ml-1" />
          </Link>
        </div>
      </div>
    </>
  );
}

function NavLink({ href, children }: { href: string; children: React.ReactNode }) {
  return (
    <a
      href={href}
      className="px-4 py-2 rounded-full text-[#221F1A] font-semibold text-[14px] hover:text-[#FF6B4A] hover:bg-[#FF6B4A]/5 transition-all"
    >
      {children}
    </a>
  );
}
