'use client';

import React from 'react';
import Link from 'next/link';
import { Heart, Star, Sparkles, Users, Trophy, LineChart, Target, ShieldCheck } from 'lucide-react';

export default function TestimonialSection() {
  const testimonials = [
    {
      quote: "The analytical insights provided by the platform completely transformed my approach to technical interviews.",
      name: "Aravind S",
      role: "1st Year MCA",
      rating: 5,
      avatar: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?ixlib=rb-4.0.3&auto=format&fit=crop&w=150&q=80"
    },
    {
      quote: "Consolidating communications and tasks into a single ecosystem has significantly streamlined our department's workflow.",
      name: "Keerthana M",
      role: "2nd Year MCA",
      rating: 5,
      avatar: "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?ixlib=rb-4.0.3&auto=format&fit=crop&w=150&q=80"
    },
    {
      quote: "The granular readiness metrics allowed me to identify and resolve critical knowledge gaps before company drives.",
      name: "Harish R",
      role: "Placement Coordinator",
      rating: 5,
      avatar: "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-4.0.3&auto=format&fit=crop&w=150&q=80"
    }
  ];

  return (
    <section className="py-24 px-6 md:px-12 lg:px-24 max-w-[1400px] mx-auto flex flex-col relative overflow-hidden">
      
      {/* Top Testimonials Row */}
      <div className="flex flex-col xl:flex-row w-full justify-between items-start gap-12 mb-10">
        
        {/* Left Side text */}
        <div className="xl:w-[35%] w-full pt-4">
          <div className="flex items-center gap-2 px-4 py-1.5 rounded-full bg-white text-[#FF6B4A] font-bold text-[12px] mb-6 border border-[#EFE9E0] shadow-sm w-max">
            <Heart className="w-3.5 h-3.5 fill-[#FF6B4A]" /> Proven Results. Tangible Impact.
          </div>
          <h2 className="text-[2.5rem] sm:text-[3rem] md:text-[4rem] font-black text-[#221F1A] tracking-tight leading-[1.05]">
            Empowering Students. <br />
            Trusted by <span className="text-[#FF6B4A]">Institutions.</span>
          </h2>
          <p className="text-[#716D64] text-base md:text-[1.1rem] mt-6 font-medium leading-relaxed max-w-[400px]">
            From maintaining consistency to excelling in technical interviews, PSGMX equips MCA students with the tools to realize their career aspirations.
          </p>
          <div className="mt-8 flex items-center gap-4">
             <div className="flex -space-x-3">
                {[1,2,3,4,5].map(i => (
                  <div key={i} className="w-12 h-12 rounded-full bg-gray-200 border-2 border-[#FBF6EE] overflow-hidden">
                    <img src={`https://i.pravatar.cc/100?img=${i+10}`} alt="Student" className="w-full h-full object-cover" />
                  </div>
                ))}
             </div>
             <div>
               <h4 className="font-black text-[#FF6B4A] text-lg leading-tight">120+</h4>
               <p className="text-[12px] font-bold text-[#9E9A92] leading-tight">Students & growing</p>
             </div>
          </div>
        </div>

        {/* Right Side Cards */}
        <div className="xl:w-[65%] w-full grid grid-cols-1 md:grid-cols-3 gap-6">
          {testimonials.map((t, idx) => (
             <div key={idx} className="bg-white rounded-[32px] p-8 border border-[#EFE9E0] shadow-sm hover:shadow-md transition-shadow flex flex-col justify-between">
                <div>
                   <div className="text-[#FF6B4A]/20 font-serif font-black text-6xl leading-none mb-2">"</div>
                   <div className="flex items-center gap-1 mb-4">
                     {[...Array(t.rating)].map((_, i) => <Star key={i} className="w-4 h-4 fill-[#FF6B4A] text-[#FF6B4A]" />)}
                   </div>
                   <p className="text-[#221F1A] font-medium leading-relaxed text-[15px] mb-10">{t.quote}</p>
                </div>
                <div className="flex items-center gap-4">
                   <div className="w-14 h-14 rounded-full overflow-hidden bg-gray-100">
                     <img src={t.avatar} alt={t.name} className="w-full h-full object-cover" />
                   </div>
                   <div>
                     <h4 className="font-bold text-[#221F1A] text-[15px] leading-tight">{t.name}</h4>
                     <p className="text-[13px] font-medium text-[#9E9A92] leading-tight">{t.role}</p>
                   </div>
                </div>
             </div>
          ))}
        </div>
      </div>

      {/* Stat Strip */}
      <div className="w-full bg-transparent border-t border-b border-[#EFE9E0] py-8 mb-16 mt-8 flex flex-wrap items-center justify-between gap-6 px-4">
        
        <div className="flex items-center gap-4">
          <div className="w-12 h-12 rounded-full border border-[#EFE9E0] bg-white flex items-center justify-center text-[#FF6B4A]">
            <Users className="w-6 h-6" />
          </div>
          <div>
            <h4 className="font-black text-[#221F1A] text-[18px] leading-none mb-1">120+</h4>
            <p className="text-[#9E9A92] text-[12px] font-medium leading-tight">Students Onboarded</p>
          </div>
        </div>

        <div className="flex items-center gap-4">
          <div className="w-12 h-12 rounded-full border border-[#EFE9E0] bg-white flex items-center justify-center text-[#E8B84B]">
            <Trophy className="w-6 h-6" />
          </div>
          <div>
            <h4 className="font-black text-[#221F1A] text-[18px] leading-none mb-1">10K+</h4>
            <p className="text-[#9E9A92] text-[12px] font-medium leading-tight">Tasks Completed</p>
          </div>
        </div>

        <div className="flex items-center gap-4">
          <div className="w-12 h-12 rounded-full border border-[#EFE9E0] bg-white flex items-center justify-center text-[#8FB996]">
            <LineChart className="w-6 h-6" />
          </div>
          <div>
            <h4 className="font-black text-[#221F1A] text-[18px] leading-none mb-1">99%</h4>
            <p className="text-[#9E9A92] text-[12px] font-medium leading-tight">Engagement Rate</p>
          </div>
        </div>

        <div className="flex items-center gap-4">
          <div className="w-12 h-12 rounded-full border border-[#EFE9E0] bg-white flex items-center justify-center text-[#FF6B4A]">
            <Target className="w-6 h-6" />
          </div>
          <div>
            <h4 className="font-black text-[#221F1A] text-[18px] leading-none mb-1">100+</h4>
            <p className="text-[#9E9A92] text-[12px] font-medium leading-tight">Placement Opportunities</p>
          </div>
        </div>

        <div className="flex items-center gap-4">
          <div className="w-12 h-12 rounded-full border border-[#EFE9E0] bg-white flex items-center justify-center text-[#E8B84B]">
            <ShieldCheck className="w-6 h-6" />
          </div>
          <div>
            <h4 className="font-black text-[#221F1A] text-[18px] leading-none mb-1">One Goal</h4>
            <p className="text-[#9E9A92] text-[12px] font-medium leading-tight">Excellence Together</p>
          </div>
        </div>

      </div>

      {/* Final CTA Banner */}
      <div className="w-full bg-[#FFFDFB] rounded-[24px] sm:rounded-[40px] border border-[#EFE9E0] shadow-sm relative flex flex-col md:flex-row items-center overflow-hidden">
         
         {/* Left Visuals */}
         <div className="hidden md:flex w-full md:w-[40%] relative h-[300px] items-end justify-center z-10 pl-10 pt-10">
            {/* Plant */}
            <div className="absolute left-10 bottom-0 flex flex-col items-center">
              <div className="w-12 h-20 bg-[#8FB996] rounded-t-full rounded-bl-full rotate-[-10deg] shadow-inner mb-[-15px]"></div>
              <div className="w-16 h-12 bg-[#FBF6EE] border border-[#EFE9E0] rounded-b-xl shadow-sm"></div>
            </div>
            {/* Books & Mascot */}
            <div className="absolute right-0 bottom-0 flex items-end">
              <div className="flex flex-col gap-1 mr-[-20px] mb-4 rotate-[-5deg]">
                <div className="w-24 h-4 bg-[#FF6B4A] rounded-sm shadow-sm"></div>
                <div className="w-28 h-5 bg-[#FBF6EE] rounded-sm shadow-sm border border-[#EFE9E0]"></div>
                <div className="w-26 h-6 bg-[#221F1A] rounded-sm shadow-sm"></div>
              </div>
              <img src="/landing/mascot-hero.png" alt="Mascot" className="w-[150px] lg:w-[200px] object-contain drop-shadow-2xl translate-x-10 translate-y-4 z-20" />
            </div>
         </div>

         {/* Right Content */}
         <div className="w-full md:w-[60%] p-8 sm:p-12 md:p-16 z-10 flex flex-col items-center md:items-start text-center md:text-left relative">
            
            <div className="absolute top-10 right-10 lg:right-20 text-[#E8B84B] opacity-50 transform rotate-[-10deg] font-serif italic text-xl lg:text-2xl hidden md:block">
              We're with <br/> you every step! ❤️
            </div>

            <div className="flex items-center gap-2 px-4 py-1.5 rounded-full bg-white text-[#FF6B4A] font-bold text-[12px] mb-4 border border-[#FF6B4A]/20 shadow-sm w-max mx-auto md:mx-0">
              <Sparkles className="w-3.5 h-3.5" /> Commence Your Journey
            </div>
            
            <h2 className="text-[2rem] sm:text-[2.5rem] md:text-[3.5rem] font-black text-[#221F1A] tracking-tight mb-4 leading-[1.1]">
              Take command of your <br className="hidden sm:block" /> <span className="text-[#FF6B4A]">career trajectory.</span>
            </h2>
            <p className="text-[#716D64] text-base md:text-[1.1rem] font-medium leading-relaxed max-w-lg mb-8">
              Join the PSGMX ecosystem and equip yourself with the industry-standard tools necessary to excel in your placements.
            </p>

            <Link href="/app" className="px-8 sm:px-10 py-4 rounded-xl bg-white border-2 border-[#EFE9E0] text-[#221F1A] font-bold flex items-center justify-center gap-2 hover:bg-[#FBF6EE] transition-colors shadow-sm w-full sm:w-auto">
              Enter the ecosystem
            </Link>
         </div>
         
         <div className="absolute inset-0 w-[40%] bg-gradient-to-r from-[#FFFDFB] to-transparent z-0"></div>

      </div>

    </section>
  );
}
