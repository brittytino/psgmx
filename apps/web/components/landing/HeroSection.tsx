'use client';

import React from 'react';
import Link from 'next/link';
import { Heart, Monitor, ArrowRight, ChevronRight, CheckSquare, LineChart, CalendarCheck, ShieldCheck } from 'lucide-react';

export default function HeroSection() {
  return (
    <section className="relative pt-28 pb-20 px-6 md:px-12 lg:px-16 xl:px-20 max-w-[1500px] mx-auto overflow-hidden flex flex-col lg:flex-row items-center justify-between gap-8 lg:gap-12">
      
      {/* Background abstract elements */}
      <div className="absolute top-20 right-10 w-96 h-96 bg-[#FF6B4A]/5 rounded-full blur-[100px] -z-10 pointer-events-none"></div>
      <div className="absolute bottom-10 left-10 w-80 h-80 bg-[#E8B84B]/5 rounded-full blur-[80px] -z-10 pointer-events-none"></div>

      {/* Left Content */}
      <div className="w-full lg:w-[45%] xl:w-[42%] flex flex-col items-start z-10">
        
        <div className="flex items-center gap-2 px-4 py-1.5 rounded-full bg-[#FFF0EA] text-[#FF6B4A] font-bold text-sm mb-6 w-max">
          <Heart className="w-4 h-4 fill-[#FF6B4A]" />
          Welcome to the crew!
        </div>

        <h1 className="text-[.25rem] sm:text-[4rem] md:text-[4.5rem] xl:text-[4.7rem] font-black text-[#221F1A] leading-[1.05] tracking-tight mb-6">
          Your Placement <br />
          Journey. <br />
          <span className="text-[#FF6B4A]">Simplified.</span>
        </h1>

        <p className="text-base md:text-lg text-[#716D64] leading-relaxed max-w-lg mb-10 font-medium">
          PSGMX is the placement operating system for PSG Tech MCA. Track, prepare, collaborate and succeed—together.
        </p>

        {/* Info Pills */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-10 w-full">
          <div className="flex items-center gap-3 bg-white/80 rounded-2xl py-2 px-3 shadow-[0_2px_10px_rgba(0,0,0,0.03)] backdrop-blur-sm">
            <div className="w-10 h-10 shrink-0 rounded-[10px] bg-[#FFF8E7] flex items-center justify-center">
              <CheckSquare className="w-5 h-5 text-[#E8B84B]" />
            </div>
            <div>
              <h4 className="text-[#221F1A] font-bold text-[14px] leading-tight">Daily Tasks</h4>
              <p className="text-[#9E9A92] text-[12px] font-medium leading-tight">Stay on track</p>
            </div>
          </div>

          <div className="flex items-center gap-3 bg-white/80 rounded-2xl py-2 px-3 shadow-[0_2px_10px_rgba(0,0,0,0.03)] backdrop-blur-sm">
            <div className="w-10 h-10 shrink-0 rounded-[10px] bg-[#FFF0EA] flex items-center justify-center">
              <LineChart className="w-5 h-5 text-[#FF6B4A]" />
            </div>
            <div>
              <h4 className="text-[#221F1A] font-bold text-[14px] leading-tight">Readiness</h4>
              <p className="text-[#9E9A92] text-[12px] font-medium leading-tight">Know your score</p>
            </div>
          </div>

          <div className="flex items-center gap-3 bg-white/80 rounded-2xl py-2 px-3 shadow-[0_2px_10px_rgba(0,0,0,0.03)] backdrop-blur-sm">
            <div className="w-10 h-10 shrink-0 rounded-[10px] bg-[#EAF6EC] flex items-center justify-center">
              <CalendarCheck className="w-5 h-5 text-[#8FB996]" />
            </div>
            <div>
              <h4 className="text-[#221F1A] font-bold text-[14px] leading-tight">Attendance</h4>
              <p className="text-[#9E9A92] text-[12px] font-medium leading-tight">Never miss</p>
            </div>
          </div>
        </div>

        {/* CTAs */}
        <div className="flex flex-col sm:flex-row items-center gap-4 mb-8 w-full sm:w-auto">
          <Link href="/app" className="w-full sm:w-auto flex items-center justify-center gap-2 px-8 py-3.5 rounded-full bg-[#FF6B4A] text-white font-bold text-[15px] hover:bg-[#E4572E] transition-all shadow-lg shadow-[#FF6B4A]/25">
            <Monitor className="w-5 h-5" /> Open Web App <ArrowRight className="w-5 h-5 ml-1" />
          </Link>
          <Link href="#features" className="w-full sm:w-auto flex items-center justify-center gap-2 px-8 py-3.5 rounded-full bg-white text-[#221F1A] font-bold text-[15px] hover:bg-[#FBF6EE] border border-[#EFE9E0] shadow-sm transition-all">
            Explore Features <ChevronRight className="w-5 h-5 ml-1 text-[#221F1A]" />
          </Link>
        </div>

        <div className="flex items-center gap-2 text-[#9E9A92] text-sm font-medium">
          <ShieldCheck className="w-5 h-5 text-[#8FB996] shrink-0" />
          <span>Trusted by students, coordinators & departments</span>
        </div>

      </div>

      {/* Right Content - Visuals exactly matching the mockup */}
      <div className="w-full lg:w-[55%] xl:w-[58%] flex items-center justify-center lg:justify-end mt-10 lg:mt-0">
         <img 
           src="/landing/hero.png" 
           alt="PSGMX Placement Ecosystem Illustration" 
           className="w-full h-auto object-contain max-w-[550px] sm:max-w-[650px] lg:max-w-none mix-blend-multiply" 
         />
      </div>

    </section>
  );
}
