'use client';

import React from 'react';
import { CheckSquare, LineChart, QrCode, Briefcase } from 'lucide-react';

export default function FeatureSection() {
  const features = [
    {
      title: "Task Management",
      desc: "Structured workflows ensuring consistent daily progress.",
      icon: <CheckSquare className="w-5 h-5 text-white" />,
      bg: "bg-[#E8B84B]",
      photo: "https://images.unsplash.com/photo-1517694712202-14dd9538aa97?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80"
    },
    {
      title: "Readiness Metrics",
      desc: "Comprehensive analytics to quantify your interview preparedness.",
      icon: <LineChart className="w-5 h-5 text-white" />,
      bg: "bg-[#FF6B4A]",
      photo: "https://images.unsplash.com/photo-1522202176988-66273c2fd55f?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80"
    },
    {
      title: "Automated Tracking",
      desc: "Frictionless attendance logging via integrated QR technology.",
      icon: <QrCode className="w-5 h-5 text-white" />,
      bg: "bg-[#FF6B4A]",
      photo: "https://images.unsplash.com/photo-1531482615713-2afd69097998?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80"
    },
    {
      title: "Placement Intelligence",
      desc: "Real-time updates on critical drives and corporate opportunities.",
      icon: <Briefcase className="w-5 h-5 text-white" />,
      bg: "bg-[#E8B84B]",
      photo: "https://images.unsplash.com/photo-1515162816999-a0c47dc192f7?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80"
    }
  ];

  const testimonials = [
    { name: "Aravind", role: "1st Year", quote: "The platform's structured approach provided actionable insights that accelerated my preparation." },
    { name: "Keerthana", role: "2nd Year", quote: "Centralizing workflows and updates has fundamentally streamlined our placement process." },
    { name: "Hari", role: "2nd Year", quote: "Readiness analytics helped me identify and resolve knowledge gaps efficiently." }
  ];

  return (
    <section id="features" className="py-20 px-6 md:px-12 lg:px-24 max-w-[1400px] mx-auto relative overflow-hidden">
      
      {/* Top Section */}
      <div className="flex flex-col xl:flex-row justify-between items-start gap-12 relative z-10">
        
        {/* Left text */}
        <div className="w-full xl:w-[50%] z-20 relative">
          <div className="inline-block px-3 py-1 bg-[#FBF6EE] rounded-sm text-[#FF6B4A] font-bold tracking-[0.2em] text-[10px] uppercase mb-6 border border-[#FF6B4A]/20">
            Data-Driven. Intelligent. Comprehensive.
          </div>
          <h2 className="text-[2.5rem] sm:text-[3rem] md:text-[4rem] font-black text-[#221F1A] tracking-tight leading-[1.05] mb-6">
            Every tool you <br /> need to <span className="text-[#FF6B4A]">succeed.</span>
          </h2>
          <p className="text-[#716D64] text-base md:text-[1.1rem] mb-12 max-w-[450px] font-medium leading-relaxed">
            PSGMX unifies essential placement workflows into a single, intelligent platform, allowing you to focus entirely on skill development and career growth.
          </p>

          {/* 4 Cards Grid/Flex */}
          <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4 xl:grid-cols-2 gap-4 mb-16 xl:mb-0 w-full">
            {features.map((feat, idx) => (
              <div key={idx} className="bg-white rounded-[24px] border border-[#EFE9E0] shadow-sm flex-1 min-w-[180px] overflow-hidden flex flex-col group hover:shadow-md transition-shadow relative">
                <div className="h-32 w-full relative">
                   <img src={feat.photo} alt={feat.title} className="w-full h-full object-cover grayscale opacity-80 group-hover:grayscale-0 group-hover:opacity-100 transition-all duration-300" />
                   <div className={`absolute -bottom-4 left-4 w-10 h-10 rounded-xl ${feat.bg} flex items-center justify-center shadow-sm border-2 border-white z-10`}>
                     {feat.icon}
                   </div>
                </div>
                <div className="p-5 pt-8 bg-white flex-1 flex flex-col">
                  <h4 className="font-bold text-[#221F1A] text-[15px] mb-2 leading-tight">{feat.title}</h4>
                  <p className="text-[#9E9A92] text-[13px] font-medium leading-relaxed">{feat.desc}</p>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Right Dashboard Visual - Massive */}
        <div className="w-full xl:w-[50%] relative flex justify-center xl:justify-end mt-10 xl:mt-0 z-10 hidden sm:flex">
          <div className="w-full xl:w-[120%] max-w-[900px] bg-[#FDFDFD] rounded-[24px] sm:rounded-[40px] border border-[#EFE9E0] shadow-2xl p-2 pb-0 flex flex-col items-center xl:translate-x-20 overflow-hidden h-[400px] sm:h-[600px] relative">
             <img src="/landing/dashboard-mockup.png" alt="Dashboard Full Mockup" className="w-full h-auto object-cover rounded-t-[16px] sm:rounded-t-[32px] border border-[#EFE9E0]" />
             {/* Phone mockup overlay */}
             <img src="/landing/mobile-mockup.png" alt="Mobile Full Mockup" className="absolute bottom-4 sm:bottom-10 right-4 sm:right-10 w-32 sm:w-64 rounded-[16px] sm:rounded-[32px] border-4 sm:border-[6px] border-[#221F1A] shadow-2xl object-cover" />
          </div>
        </div>

      </div>

      {/* Bottom Trust Row */}
      <div className="mt-20 flex flex-col xl:flex-row items-center gap-12 justify-between relative z-10 w-full">
         
         {/* Left part with mascot */}
         <div className="flex flex-col sm:flex-row items-center gap-6 text-center sm:text-left">
            <img src="/landing/mascot-hero.png" alt="Mascot Happy" className="w-[140px] h-[140px] sm:w-[180px] sm:h-[180px] object-contain drop-shadow-lg" />
            <div>
              <h3 className="text-2xl sm:text-3xl font-black text-[#221F1A] leading-tight">Empowering</h3>
              <h3 className="text-2xl sm:text-3xl font-black text-[#221F1A] leading-tight">ambitious students.</h3>
              <h3 className="text-2xl sm:text-3xl font-black text-[#221F1A] leading-tight mt-1">Trusted by</h3>
              <h3 className="text-2xl sm:text-3xl font-black text-[#FF6B4A] leading-tight">academic institutions.</h3>
            </div>
         </div>

         {/* Right part with testimonials and stats */}
         <div className="flex flex-col md:flex-row items-center gap-6 w-full xl:w-auto overflow-x-auto pb-4 custom-scrollbar">
            {testimonials.map((t, idx) => (
               <div key={idx} className="bg-white rounded-[24px] border border-[#EFE9E0] shadow-sm p-5 w-64 flex flex-col justify-between hover:shadow-md transition-shadow relative">
                 <div className="absolute top-4 right-4 text-[#FF6B4A] opacity-20 font-serif text-4xl leading-none">"</div>
                 <div className="flex items-center gap-3 mb-4">
                   <div className="w-10 h-10 rounded-full bg-[#FBF6EE] overflow-hidden">
                      <img src={`https://i.pravatar.cc/100?u=${t.name}`} alt={t.name} className="w-full h-full object-cover" />
                   </div>
                   <div>
                      <div className="w-24 h-2 bg-gray-100 rounded-sm mb-1"></div>
                      <div className="w-16 h-2 bg-gray-100 rounded-sm"></div>
                   </div>
                 </div>
                 <p className="text-[#221F1A] text-[13px] font-medium leading-relaxed italic z-10 relative">"{t.quote}"</p>
                 <div className="mt-4 border-t border-[#EFE9E0] pt-3">
                   <p className="text-[#221F1A] text-xs font-bold">— {t.name}, <span className="text-[#9E9A92] font-normal">{t.role}</span></p>
                 </div>
               </div>
            ))}
            
            <div className="bg-[#FFFBF9] rounded-[24px] border border-[#FF6B4A]/20 shadow-sm p-6 w-52 flex flex-col justify-center text-center">
               <h2 className="text-4xl font-black text-[#FF6B4A] mb-2">120+</h2>
               <p className="text-[#221F1A] text-xs font-bold leading-tight">Students. One Goal.</p>
               <p className="text-[#9E9A92] text-[11px] font-medium leading-tight">Countless Futures.</p>
               <div className="mt-4 flex justify-center">
                 <div className="w-8 h-8 rounded-full bg-[#FFE5D9] flex items-center justify-center">
                   <span className="text-xl">👨‍👩‍👧‍👦</span>
                 </div>
               </div>
            </div>
         </div>
      </div>

    </section>
  );
}
