'use client';

import React from 'react';
import Link from 'next/link';
import { Menu, Monitor, ChevronDown } from 'lucide-react';

export default function LandingNavbar() {
  return (
    <nav className="fixed top-0 left-0 right-0 z-50 bg-[#FBF6EE]/80 backdrop-blur-md border-b border-[#EFE9E0] h-20 flex items-center justify-between px-6 md:px-12 lg:px-24">
      {/* Logo */}
      <Link href="/" className="flex items-center gap-3">
        <img src="/logo.webp" alt="PSGMX Logo" className="w-10 h-10 object-contain drop-shadow-md" />
        <span className="text-2xl font-black text-[#221F1A] tracking-tight">PSGMX</span>
      </Link>

      {/* Desktop Links */}
      <div className="hidden lg:flex items-center gap-8">
        <div className="flex items-center gap-1 cursor-pointer text-[#221F1A] font-bold text-[15px] hover:text-[#FF6B4A] transition-colors">
          Product <ChevronDown className="w-4 h-4 text-[#9E9A92]" />
        </div>
        <Link href="#features" className="text-[#221F1A] font-bold text-[15px] hover:text-[#FF6B4A] transition-colors">
          Features
        </Link>
        <Link href="#access" className="text-[#221F1A] font-bold text-[15px] hover:text-[#FF6B4A] transition-colors">
          Access
        </Link>
        <Link href="#about" className="text-[#221F1A] font-bold text-[15px] hover:text-[#FF6B4A] transition-colors">
          About
        </Link>
      </div>

      {/* Right Actions */}
      <div className="flex items-center gap-4">
        <Link href="/app" className="hidden sm:flex items-center gap-2 px-5 py-2.5 rounded-full border border-[#FF6B4A]/30 text-[#FF6B4A] font-bold text-[14px] hover:bg-[#FF6B4A]/5 transition-colors">
          <Monitor className="w-4 h-4" /> Open Web App
        </Link>
        
        <button className="w-12 h-12 rounded-full bg-[#FFE5D9] flex items-center justify-center text-[#221F1A] hover:bg-[#FFD4C2] transition-colors lg:hidden">
          <Menu className="w-5 h-5" />
        </button>
      </div>
    </nav>
  );
}
