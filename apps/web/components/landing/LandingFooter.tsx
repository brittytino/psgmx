'use client';

import React from 'react';
import Link from 'next/link';
import { Instagram, Linkedin, Github, Heart } from 'lucide-react';

export default function LandingFooter() {
  return (
    <footer className="pt-20 pb-8 px-6 md:px-12 lg:px-24 max-w-7xl mx-auto border-t border-[#EFE9E0] mt-10">
      
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-12 gap-12 mb-16">
        
        {/* Brand Column */}
        <div className="lg:col-span-4">
          <Link href="/" className="flex items-center gap-3 mb-6">
            <img src="/logo.webp" alt="PSGMX Logo" className="w-10 h-10 object-contain drop-shadow-md" />
            <span className="text-2xl font-black text-[#221F1A] tracking-tight">PSGMX</span>
          </Link>
          <p className="text-[#9E9A92] text-sm font-medium leading-relaxed pr-8">
            The placement operating system for PSG Tech MCA. Track, prepare, collaborate and succeed—together.
          </p>
        </div>

        {/* Links Columns */}
        <div className="lg:col-span-2">
          <h4 className="font-bold text-[#221F1A] mb-6">Product</h4>
          <ul className="space-y-4">
            <li><Link href="#features" className="text-[#9E9A92] hover:text-[#FF6B4A] text-sm font-medium transition-colors">Features</Link></li>
            <li><Link href="#access" className="text-[#9E9A92] hover:text-[#FF6B4A] text-sm font-medium transition-colors">Access</Link></li>
            <li><Link href="/app" className="text-[#9E9A92] hover:text-[#FF6B4A] text-sm font-medium transition-colors">Web App</Link></li>
          </ul>
        </div>

        <div className="lg:col-span-2">
          <h4 className="font-bold text-[#221F1A] mb-6">Resources</h4>
          <ul className="space-y-4">
            <li><Link href="#" className="text-[#9E9A92] hover:text-[#FF6B4A] text-sm font-medium transition-colors">Help & Support</Link></li>
            <li><Link href="#" className="text-[#9E9A92] hover:text-[#FF6B4A] text-sm font-medium transition-colors">Updates</Link></li>
          </ul>
        </div>

        <div className="lg:col-span-2">
          <h4 className="font-bold text-[#221F1A] mb-6">Legal</h4>
          <ul className="space-y-4">
            <li><Link href="#" className="text-[#9E9A92] hover:text-[#FF6B4A] text-sm font-medium transition-colors">Privacy Policy</Link></li>
            <li><Link href="#" className="text-[#9E9A92] hover:text-[#FF6B4A] text-sm font-medium transition-colors">Terms of Service</Link></li>
          </ul>
        </div>

        <div className="lg:col-span-2 flex flex-col items-start lg:items-end">
          <h4 className="font-bold text-[#221F1A] mb-6 w-full lg:text-right">Connect</h4>
          <div className="flex items-center gap-4 w-full lg:justify-end">
            <Link href="#" className="w-10 h-10 rounded-full bg-white border border-[#EFE9E0] flex items-center justify-center text-[#221F1A] hover:bg-[#FBF6EE] transition-colors hover:text-[#FF6B4A] shadow-sm">
              <Instagram className="w-4 h-4" />
            </Link>
            <Link href="#" className="w-10 h-10 rounded-full bg-white border border-[#EFE9E0] flex items-center justify-center text-[#221F1A] hover:bg-[#FBF6EE] transition-colors hover:text-[#FF6B4A] shadow-sm">
              <Linkedin className="w-4 h-4" />
            </Link>
            <Link href="https://github.com/brittytino/psgmx" className="w-10 h-10 rounded-full bg-white border border-[#EFE9E0] flex items-center justify-center text-[#221F1A] hover:bg-[#FBF6EE] transition-colors hover:text-[#FF6B4A] shadow-sm">
              <Github className="w-4 h-4" />
            </Link>
          </div>
        </div>

      </div>

      <div className="flex flex-col md:flex-row items-center justify-between pt-8 border-t border-[#EFE9E0] gap-6">
        
        <p className="text-[#9E9A92] text-[13px] font-medium text-center md:text-left">
          © {new Date().getFullYear()} PSGMX. All rights reserved.
        </p>

        <div className="px-6 py-3 rounded-full bg-[#FFFBF9] border border-[#EFE9E0] shadow-sm flex items-center gap-2 relative overflow-hidden">
          <div className="absolute top-0 right-0 w-8 h-8 bg-[#8FB996]/10 rotate-45 translate-x-4 -translate-y-4"></div>
          <span className="text-[#221F1A] text-[13px] font-bold">Made with</span>
          <Heart className="w-3.5 h-3.5 fill-[#FF6B4A] text-[#FF6B4A]" />
          <span className="text-[#221F1A] text-[13px] font-bold">for</span>
          <div className="flex flex-col ml-1">
             <span className="text-[#FF6B4A] text-[13px] font-black leading-tight">PSG Tech MCA</span>
             <span className="text-[#9E9A92] text-[10px] font-bold tracking-wider uppercase leading-tight">Batch of 2025–2027</span>
          </div>
        </div>
        
      </div>
    </footer>
  );
}
