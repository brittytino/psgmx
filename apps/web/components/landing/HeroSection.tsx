'use client';

import React from 'react';
import Link from 'next/link';
import { Heart, Monitor, ArrowRight, CheckSquare, LineChart, CalendarCheck, ShieldCheck } from 'lucide-react';

export default function HeroSection() {
  return (
    <section className="relative pt-32 pb-20 px-6 md:px-12 lg:px-24 max-w-[1400px] mx-auto overflow-hidden flex flex-col lg:flex-row items-center justify-between gap-12">
      
      {/* Background abstract elements (similar to confetti in mockup) */}
      <div className="absolute top-20 right-10 w-96 h-96 bg-[#FF6B4A]/10 rounded-full blur-[100px] -z-10 pointer-events-none"></div>
      <div className="absolute bottom-10 left-10 w-80 h-80 bg-[#E8B84B]/10 rounded-full blur-[80px] -z-10 pointer-events-none"></div>

      {/* Confetti pieces */}
      <div className="absolute top-[25%] right-[40%] w-4 h-4 bg-[#8FB996] rotate-45 -z-10"></div>
      <div className="absolute top-[15%] right-[20%] w-5 h-5 bg-[#FF6B4A] rounded-full -z-10"></div>
      <div className="absolute top-[35%] right-[10%] w-4 h-4 bg-[#E8B84B] rotate-12 -z-10"></div>
      <div className="absolute top-[50%] right-[45%] w-3 h-3 bg-[#FF6B4A] rotate-45 -z-10"></div>

      {/* Left Content */}
      <div className="w-full lg:w-[45%] flex flex-col items-start z-10">
        
        <div className="flex items-center gap-2 px-4 py-1.5 rounded-full bg-[#FFE5D9] text-[#FF6B4A] font-bold text-sm mb-6 w-max">
          <Heart className="w-4 h-4 fill-[#FF6B4A]" />
          Welcome to the ecosystem
        </div>

        <h1 className="text-[3rem] md:text-[4rem] lg:text-[4.5rem] font-black text-[#221F1A] leading-[1.05] tracking-tight mb-6">
          Your Placement <br /> Journey. <br />
          <span className="text-[#FF6B4A]">Elevated.</span>
        </h1>

        <p className="text-base md:text-lg text-[#716D64] leading-relaxed max-w-lg mb-10 font-medium">
          PSGMX is the definitive placement operating system for PSG Tech MCA. Seamlessly track progress, prepare for interviews, collaborate with peers, and achieve your career goals.
        </p>

        {/* Info Pills */}
        <div className="flex flex-col sm:flex-row flex-wrap xl:flex-nowrap items-start sm:items-center gap-4 mb-10 w-full">
          <div className="flex items-center gap-3 bg-white/50 py-2 pr-4 rounded-2xl w-full sm:w-auto">
            <div className="w-10 h-10 shrink-0 rounded-[10px] bg-[#FFF5F0] flex items-center justify-center text-[#FF6B4A]">
              <CheckSquare className="w-5 h-5" />
            </div>
            <div>
              <h4 className="text-[#221F1A] font-bold text-[14px] leading-tight">Structured Prep</h4>
              <p className="text-[#9E9A92] text-[12px] font-medium leading-tight">Daily actionable tasks</p>
            </div>
          </div>

          <div className="flex items-center gap-3 bg-white/50 py-2 pr-4 rounded-2xl w-full sm:w-auto">
            <div className="w-10 h-10 shrink-0 rounded-[10px] bg-[#FFF8E7] flex items-center justify-center text-[#E8B84B]">
              <LineChart className="w-5 h-5" />
            </div>
            <div>
              <h4 className="text-[#221F1A] font-bold text-[14px] leading-tight">Performance Analytics</h4>
              <p className="text-[#9E9A92] text-[12px] font-medium leading-tight">Data-driven insights</p>
            </div>
          </div>

          <div className="flex items-center gap-3 bg-white/50 py-2 pr-4 rounded-2xl w-full sm:w-auto">
            <div className="w-10 h-10 shrink-0 rounded-[10px] bg-[#F2F9F4] flex items-center justify-center text-[#8FB996]">
              <CalendarCheck className="w-5 h-5" />
            </div>
            <div>
              <h4 className="text-[#221F1A] font-bold text-[14px] leading-tight">Seamless Tracking</h4>
              <p className="text-[#9E9A92] text-[12px] font-medium leading-tight">Automated attendance</p>
            </div>
          </div>
        </div>

        {/* CTAs */}
        <div className="flex flex-col sm:flex-row items-center gap-4 mb-8 w-full sm:w-auto">
          <Link href="/app" className="w-full sm:w-auto flex items-center justify-center gap-2 px-8 py-3.5 rounded-2xl bg-[#FF6B4A] text-white font-bold text-[15px] hover:bg-[#E4572E] transition-all shadow-lg shadow-[#FF6B4A]/25">
            <Monitor className="w-5 h-5" /> Open Web App <ArrowRight className="w-5 h-5 ml-1" />
          </Link>
          <Link href="#features" className="w-full sm:w-auto flex items-center justify-center gap-2 px-8 py-3.5 rounded-2xl bg-white text-[#221F1A] font-bold text-[15px] hover:bg-[#FBF6EE] border-2 border-[#EFE9E0] transition-all">
            Explore Features <ArrowRight className="w-5 h-5 ml-1" />
          </Link>
        </div>

        <div className="flex items-center gap-2 text-[#9E9A92] text-sm font-medium">
          <ShieldCheck className="w-5 h-5 text-[#8FB996] shrink-0" />
          <span>Trusted by top-tier students, placement coordinators, & academic departments</span>
        </div>

      </div>

      {/* Right Content - Visuals exactly matching the mockup */}
      <div className="w-full lg:w-[55%] relative h-[400px] md:h-[600px] flex items-end justify-center mt-12 lg:mt-0">
         
         {/* UI Mockups (Hidden on very small screens to avoid clutter, visible on md+) */}
         <img src="/landing/dashboard-mockup.png" alt="Dashboard Mockup" className="hidden md:block absolute top-0 right-0 md:right-10 w-[80%] md:w-[70%] max-w-[600px] rounded-3xl shadow-2xl opacity-90 z-0 object-cover" />
         <img src="/landing/mobile-mockup.png" alt="Mobile Mockup" className="hidden md:block absolute bottom-10 right-0 w-[35%] md:w-[28%] max-w-[200px] rounded-[2rem] shadow-2xl z-20 object-cover" />

         {/* 3D Mascot & Elements */}
         <div className="relative z-30 flex flex-col items-center justify-end h-full lg:ml-[-20%] w-full md:w-auto">
           {/* Mascot */}
           <img src="/landing/mascot-hero.png" alt="PSGMX Mascot" className="w-[280px] h-[280px] md:w-[380px] md:h-[380px] object-contain drop-shadow-2xl z-20 translate-y-4 md:translate-y-6" />
           {/* Podium (CSS constructed) */}
           <div className="w-[220px] md:w-[300px] h-[80px] md:h-[100px] bg-gradient-to-b from-[#FFFFFF] to-[#F1EAE0] rounded-[100px/30px] border border-[#EFE9E0] shadow-xl z-10 relative">
             <div className="absolute inset-0 w-full h-[20px] md:h-[30px] bg-white rounded-[100px/30px]"></div>
           </div>
         </div>
         
         {/* Plant and Books next to mobile mockup */}
         <div className="hidden md:flex absolute bottom-4 right-[15%] lg:right-[25%] z-30 items-end gap-2">
            {/* Plant */}
            <div className="flex flex-col items-center translate-y-4">
              <div className="w-12 h-16 bg-[#8FB996] rounded-t-full rounded-bl-full rotate-[-15deg] shadow-inner mb-[-10px]"></div>
              <div className="w-14 h-10 bg-[#FFD4C2] rounded-b-xl border border-[#FF6B4A]/10 shadow-sm"></div>
            </div>
            {/* Books */}
            <div className="flex flex-col gap-1">
              <div className="w-24 h-4 bg-[#FF6B4A] rounded-sm shadow-sm rotate-2 origin-bottom-right"></div>
              <div className="w-28 h-5 bg-[#FBF6EE] rounded-sm shadow-sm border border-[#EFE9E0]"></div>
              <div className="w-26 h-6 bg-[#E8B84B] rounded-sm shadow-sm"></div>
            </div>
         </div>
         
      </div>

    </section>
  );
}
