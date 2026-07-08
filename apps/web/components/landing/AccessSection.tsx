'use client';

import React from 'react';
import Link from 'next/link';
import { Monitor, Smartphone, Download, ShieldCheck, Users, LineChart, Clock, Heart, ArrowRight, ChevronDown, Sparkles } from 'lucide-react';

export default function AccessSection() {
  return (
    <section id="access" className="py-24 px-6 md:px-12 lg:px-24 max-w-[1400px] mx-auto flex flex-col items-center relative">
      
      {/* Floating Mascot right side */}
      <img src="/landing/mascot-hero.png" alt="Mascot" className="absolute top-0 right-10 w-32 h-32 object-contain hidden lg:block opacity-80" />

      <div className="flex items-center gap-2 px-4 py-1.5 rounded-full bg-transparent text-[#FF6B4A] font-bold text-[12px] mb-4 border border-[#FF6B4A]/20 shadow-sm w-max">
        <Sparkles className="w-3.5 h-3.5" /> One System. Three Ways to Access.
      </div>

      <h2 className="text-[2.5rem] sm:text-[3rem] md:text-[4rem] lg:text-[4.5rem] font-black text-[#221F1A] tracking-tight mb-4 text-center leading-[1.05]">
        Seamless Access. <br className="md:hidden" /> Absolute Control.
      </h2>
      <p className="text-[#716D64] text-base md:text-[1.1rem] mb-16 max-w-2xl text-center font-medium leading-relaxed px-4">
        Engineered for flexibility across all devices. <br className="hidden md:block" />
        Your data remains perfectly synchronized, empowering you to manage your placement journey <span className="text-[#FF6B4A] underline decoration-[#FF6B4A]/30 underline-offset-4 decoration-2">without interruption.</span>
      </p>

      {/* 3 Columns */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 w-full mb-16">
        
        {/* Web Card */}
        <div className="bg-[#FFFDFB] rounded-[32px] p-8 border border-[#EFE9E0] shadow-sm hover:shadow-lg transition-shadow flex flex-col items-center text-center relative overflow-hidden">
          <div className="w-16 h-16 rounded-[18px] bg-white border border-[#EFE9E0] shadow-sm flex items-center justify-center text-[#FF6B4A] mb-8">
            <Monitor className="w-8 h-8" />
          </div>
          <h3 className="text-[26px] font-black text-[#221F1A] mb-1 tracking-tight">PSGMX Web</h3>
          <p className="text-[#FF6B4A] font-bold text-[15px] mb-4">For Desktop & Laptop</p>
          <p className="text-[#9E9A92] text-[13px] md:text-[14px] font-medium mb-8 leading-relaxed px-2">
            Leverage the robust suite of tools on desktop for deep focus and detailed analytics.
          </p>
          
          <div className="w-full h-40 bg-[#FBF6EE] rounded-t-2xl border-x border-t border-[#EFE9E0] relative flex justify-center pt-6 px-6 mb-8">
            <div className="w-full h-full bg-white rounded-t-xl border-x border-t border-[#EFE9E0] shadow-sm flex flex-col">
              <div className="w-full h-4 border-b border-[#EFE9E0] flex items-center gap-1.5 px-3">
                 <div className="w-2 h-2 rounded-full bg-red-400"></div>
                 <div className="w-2 h-2 rounded-full bg-yellow-400"></div>
                 <div className="w-2 h-2 rounded-full bg-green-400"></div>
              </div>
              <div className="flex-1 bg-[#FDFDFD] p-3 flex gap-3">
                 <div className="w-[30%] h-full bg-[#FBF6EE] rounded-md"></div>
                 <div className="w-[70%] h-full bg-[#FBF6EE] rounded-md flex flex-col gap-2">
                    <div className="w-full h-4 bg-[#EFE9E0] rounded-sm"></div>
                    <div className="w-full flex-1 bg-[#EFE9E0] rounded-sm opacity-50"></div>
                 </div>
              </div>
            </div>
          </div>

          <Link href="/app" className="w-full py-4 rounded-[16px] bg-[#FF6B4A] text-white font-bold flex items-center justify-center gap-2 hover:bg-[#E4572E] transition-all shadow-lg shadow-[#FF6B4A]/25 hover:-translate-y-1">
            <Monitor className="w-5 h-5" /> Open Web App <ArrowRight className="w-5 h-5 ml-1" />
          </Link>
          <p className="text-[#9E9A92] text-[13px] font-bold mt-5">Best experience on desktop</p>
        </div>

        {/* iPhone Card */}
        <div className="bg-[#FFFDFB] rounded-[32px] p-8 border border-[#EFE9E0] shadow-sm hover:shadow-lg transition-shadow flex flex-col items-center text-center relative overflow-hidden">
          <div className="w-16 h-16 rounded-[18px] bg-white border border-[#EFE9E0] shadow-sm flex items-center justify-center text-[#221F1A] mb-8">
            <Smartphone className="w-8 h-8" />
          </div>
          <h3 className="text-[26px] font-black text-[#221F1A] mb-1 tracking-tight">PSGMX for iPhone</h3>
          <p className="text-[#FF6B4A] font-bold text-[15px] mb-4">As a PWA</p>
          <p className="text-[#9E9A92] text-[13px] md:text-[14px] font-medium mb-8 leading-relaxed px-2">
            Access the platform natively via Safari for an app-like experience without the overhead.
          </p>
          
          <div className="w-40 h-40 bg-white rounded-t-[2.5rem] border-[6px] border-[#221F1A] shadow-xl relative flex justify-center pt-2 px-2 mb-8 mx-auto">
             <div className="absolute top-0 left-1/2 -translate-x-1/2 w-14 h-4 bg-[#221F1A] rounded-b-[10px] z-10"></div>
             <div className="w-full h-full bg-[#FBF6EE] rounded-t-[2rem] pt-8 px-3 flex flex-col items-center">
                <div className="w-[60px] h-[60px] rounded-full border-4 border-[#FF6B4A] mx-auto mb-3 flex items-center justify-center text-[14px] text-[#FF6B4A] font-black bg-white">75%</div>
                <div className="w-full h-3 bg-white rounded-sm mb-2 shadow-sm"></div>
                <div className="w-full h-3 bg-white rounded-sm shadow-sm"></div>
             </div>
             
             {/* PWA arrow visual */}
             <div className="absolute right-[-40px] top-[40%] text-[#FF6B4A] hidden lg:flex flex-col items-center">
                <svg width="40" height="20" viewBox="0 0 40 20" fill="none" className="rotate-[15deg]">
                  <path d="M0 10C10 10 10 0 20 0C30 0 30 10 40 10" stroke="#FF6B4A" strokeWidth="2" strokeDasharray="4 4" />
                  <path d="M40 10L35 5M40 10L35 15" stroke="#FF6B4A" strokeWidth="2" />
                </svg>
                <div className="w-10 h-10 bg-white rounded-xl shadow-md border border-[#EFE9E0] flex items-center justify-center mt-1">
                   <img src="/logo.webp" alt="App Icon" className="w-6 h-6 object-contain" />
                </div>
             </div>
          </div>

          <button className="w-full py-4 rounded-[16px] bg-white border-2 border-[#FF6B4A]/20 text-[#FF6B4A] font-bold flex items-center justify-center gap-2 hover:bg-[#FFF5F0] transition-all hover:-translate-y-1">
            <Smartphone className="w-5 h-5" /> Open PWA <ArrowRight className="w-5 h-5 ml-1" />
          </button>
          <div className="flex items-center justify-center gap-1.5 text-[#9E9A92] text-[13px] font-bold mt-5 cursor-pointer hover:text-[#221F1A] bg-[#FBF6EE] px-4 py-1.5 rounded-full">
             How to install as PWA? <ChevronDown className="w-4 h-4" />
          </div>
        </div>

        {/* Android Card */}
        <div className="bg-[#FFFDFB] rounded-[32px] p-8 border border-[#EFE9E0] shadow-sm hover:shadow-lg transition-shadow flex flex-col items-center text-center relative overflow-hidden">
          <div className="w-16 h-16 rounded-[18px] bg-white border border-[#EFE9E0] shadow-sm flex items-center justify-center text-[#789B51] mb-8">
            <Download className="w-8 h-8" />
          </div>
          <h3 className="text-[26px] font-black text-[#221F1A] mb-1 tracking-tight">PSGMX for Android</h3>
          <p className="text-[#FF6B4A] font-bold text-[15px] mb-4">Download the App</p>
          <p className="text-[#9E9A92] text-[13px] md:text-[14px] font-medium mb-8 leading-relaxed px-2">
            Download the highly optimized Android application for seamless, on-the-go management.
          </p>
          
          <div className="w-40 h-40 bg-white rounded-t-[2.5rem] border-[6px] border-[#221F1A] shadow-xl relative flex justify-center items-center mb-8 mx-auto">
             <div className="absolute top-0 left-1/2 -translate-x-1/2 w-14 h-4 bg-[#221F1A] rounded-b-[10px] z-10"></div>
             <div className="w-full h-full bg-[#FBF6EE] rounded-t-[2rem] flex flex-col items-center justify-center">
                <img src="/logo.webp" alt="App Logo" className="w-16 h-16 object-contain mb-4 drop-shadow-md" />
                <div className="text-[11px] font-bold text-[#9E9A92] bg-[#EFE9E0] px-3 py-1 rounded-full">Installing...</div>
             </div>
          </div>

          <Link href="https://github.com/brittytino/psgmx/releases" target="_blank" className="w-full py-4 rounded-[16px] bg-[#789B51] text-white font-bold flex items-center justify-center gap-2 hover:bg-[#638042] transition-all shadow-lg shadow-[#789B51]/25 hover:-translate-y-1">
            <Download className="w-5 h-5" /> Download APK <ArrowRight className="w-5 h-5 ml-1" />
          </Link>
          <p className="text-[#9E9A92] text-[13px] font-bold mt-5">Latest release from GitHub</p>
        </div>

      </div>

      {/* Stats Banner */}
      <div className="w-full bg-white rounded-[24px] border border-[#EFE9E0] py-6 px-10 shadow-sm flex flex-col md:flex-row items-center justify-between gap-6 overflow-hidden">
        
        <div className="flex items-center gap-4">
          <div className="w-12 h-12 rounded-xl bg-white border border-[#EFE9E0] shadow-sm flex items-center justify-center text-[#E8B84B]">
            <ShieldCheck className="w-6 h-6" />
          </div>
          <div className="text-left">
            <h4 className="font-black text-[#221F1A] text-[15px] mb-0.5">Secure & Trusted</h4>
            <p className="text-[#9E9A92] text-[12px] font-medium leading-tight">Your data is safe with us<br/>and always protected.</p>
          </div>
        </div>

        <div className="hidden md:block w-px h-12 bg-[#EFE9E0]"></div>

        <div className="flex items-center gap-4">
          <div className="text-left">
            <h4 className="font-black text-[#221F1A] text-[20px] mb-0.5 flex items-center gap-2">
              <Users className="w-5 h-5 text-[#8FB996]" /> 120+
            </h4>
            <p className="text-[#9E9A92] text-[12px] font-medium leading-tight">Students already on<br/>board.</p>
          </div>
        </div>

        <div className="hidden md:block w-px h-12 bg-[#EFE9E0]"></div>

        <div className="flex items-center gap-4">
          <div className="text-left">
            <h4 className="font-black text-[#221F1A] text-[20px] mb-0.5 flex items-center gap-2">
              <LineChart className="w-5 h-5 text-[#E8B84B]" /> 10K+
            </h4>
            <p className="text-[#9E9A92] text-[12px] font-medium leading-tight">Tasks completed<br/>together.</p>
          </div>
        </div>

        <div className="hidden md:block w-px h-12 bg-[#EFE9E0]"></div>

        <div className="flex items-center gap-4">
          <div className="text-left">
            <h4 className="font-black text-[#221F1A] text-[20px] mb-0.5 flex items-center gap-2">
              <Clock className="w-5 h-5 text-[#E8B84B]" /> 99%
            </h4>
            <p className="text-[#9E9A92] text-[12px] font-medium leading-tight">Uptime. Always<br/>available when you need.</p>
          </div>
        </div>

        <div className="hidden md:block w-px h-12 bg-[#EFE9E0]"></div>

        <div className="flex items-center gap-4 w-full sm:w-auto">
          <div className="w-12 h-12 rounded-xl bg-white border border-[#EFE9E0] shadow-sm flex items-center justify-center text-[#FF6B4A] shrink-0">
            <Heart className="w-6 h-6" />
          </div>
          <div className="text-left">
            <h4 className="font-black text-[#221F1A] text-[15px] mb-0.5">Built for PSG</h4>
            <p className="text-[#9E9A92] text-[12px] font-medium leading-tight">Engineered for PSG Tech<br/>MCA excellence.</p>
          </div>
        </div>

      </div>

    </section>
  );
}
