'use client';

import React from 'react';
import Image from 'next/image';
import { LogOut, User, ChevronLeft, ChevronRight, Building2 } from 'lucide-react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import FloatingElements from './floating-elements';

interface SidebarItem {
  icon: React.ElementType;
  label: string;
  href?: string;
  onClick?: () => void;
  active?: boolean;
}

interface DashboardLayoutProps {
  children: React.ReactNode;
  userType: 'Admin' | 'Trainer' | 'Contributor' | 'Faculty' | 'Candidate' | 'Assessments' | 'Campus Partner';
  username?: string | null;
  onLogout: () => void;
  sidebarItems: SidebarItem[];
  headerTitle?: string;
  headerSubtitle?: string;
  onBack?: () => void;
  headerActions?: React.ReactNode;
  isBlurred?: boolean;
  showBackButton?: boolean;
  institutionName?: string;
  campusPartnerName?: string;
  sidebarExtras?: React.ReactNode;
}

export default function DashboardLayout({
  children,
  userType,
  username,
  onLogout,
  sidebarItems,
  headerTitle,
  headerSubtitle,
  headerActions,
  isBlurred,
  showBackButton = false,
  institutionName,
  campusPartnerName,
  sidebarExtras,
  onBack,
}: DashboardLayoutProps) {
  const router = useRouter();
  const [isCollapsed, setIsCollapsed] = React.useState(false);
  const [mounted, setMounted] = React.useState(false);

  React.useEffect(() => {
    // Restore sidebar state from localStorage after mount
    const saved = localStorage.getItem('sidebar_collapsed');
    if (saved === 'true') setIsCollapsed(true);
    setMounted(true);
  }, []);

  function toggleSidebar() {
    setIsCollapsed(prev => {
      const next = !prev;
      localStorage.setItem('sidebar_collapsed', String(next));
      return next;
    });
  }

  if (!mounted) return null;

  const displayInstitutionName = institutionName?.toLowerCase() === 'college of technology' ? 'Sona College of Technology' : (institutionName || 'FRISONA CAMPUS 2026');
  const displayCampusPartnerName = campusPartnerName?.toLowerCase() === 'college of technology' ? 'Sona College of Technology' : (campusPartnerName || institutionName || 'FRISONA2026');
  
  return (
    <div className="flex h-screen w-full bg-page-bg font-sans overflow-hidden relative transition-colors duration-300">
      <style jsx global>{`
        #mobile-nav-container::-webkit-scrollbar {
          display: none;
        }
        #mobile-nav-container {
          -ms-overflow-style: none;
          scrollbar-width: none;
        }
      `}</style>
      <aside 
        className={`relative z-40 hidden md:flex flex-col border-r border-gray-100 bg-white h-full transition-all duration-500 ease-in-out group ${
          isCollapsed ? 'w-24' : 'w-64 md:w-72'
        } ${isBlurred ? 'blur-[2px] opacity-70 pointer-events-none' : ''}`}
      >
        {/* Logo Section & Toggle */}
        <div className={`flex items-center px-6 h-[80px] shrink-0 border-b border-gray-100 relative ${isCollapsed ? 'justify-center' : 'justify-between'}`}>
            {isCollapsed ? (
              <div 
                className="animate-in fade-in zoom-in duration-500 cursor-pointer hover:scale-105 transition-transform"
                onClick={toggleSidebar}
              >
                <Image
                  src="/logo.webp"
                  alt="Logo"
                  width={42}
                  height={42}
                  className="object-contain"
                  priority
                />
              </div>
            ) : (
              <Image
                src="/login.webp"
                alt="PSGMX"
                width={180}
                height={60}
                style={{ objectFit: 'contain' }}
                className="animate-in fade-in slide-in-from-left-4 duration-500"
                priority
              />
            )}
            <button 
              onClick={toggleSidebar}
              className="absolute -right-3 top-1/2 -translate-y-1/2 p-1.5 bg-white border border-gray-200 shadow-md rounded-full z-50 text-primary-purple hover:bg-primary-purple hover:text-white transition-all duration-300"
              title={isCollapsed ? "Expand Sidebar" : "Collapse Sidebar"}
            >
              <ChevronLeft className={`w-4 h-4 transition-transform duration-500 ${isCollapsed ? 'rotate-180' : ''}`} />
            </button>
        </div>

        <nav className="flex-1 space-y-3 flex flex-col px-6 pt-6 overflow-x-hidden custom-scrollbar">
            {sidebarItems.map((item, index) => {
              const Icon = item.icon;
              const isActive = item.active;
              
              const activeClass = isActive
                ? 'bg-primary-purple text-white shadow-sm'
                : 'text-slate-600 hover:text-zinc-950 hover:bg-zinc-50';
                
              const iconClass = isActive 
                ? 'text-white' 
                : 'text-slate-500 group-hover:text-zinc-950';

              const content = (
                <>
                  <Icon className={`w-5 h-5 shrink-0 transition-colors ${iconClass}`} />
                  {!isCollapsed && (
                    <span className="font-medium text-[15px] tracking-tight truncate animate-in fade-in slide-in-from-left-2 duration-300">
                      {item.label}
                    </span>
                  )}
                </>
              );

              if (item.href) {
                return (
                  <Link
                    key={index}
                    href={item.href}
                    className={`flex items-center gap-4 px-4 py-3 rounded-[16px] transition-all duration-300 group ${activeClass} ${isCollapsed ? 'justify-center px-0' : ''} hover:scale-[1.02] active:scale-95`}
                  >
                    {content}
                  </Link>
                );
              }
              return (
                <button
                  key={index}
                  onClick={item.onClick}
                  className={`flex w-full items-center gap-4 px-4 py-3 rounded-[16px] transition-all duration-300 group ${activeClass} ${isCollapsed ? 'justify-center px-0' : ''} hover:scale-[1.02] active:scale-95`}
                >
                  {content}
                </button>
              );
            })}
        </nav>
        
        {/* Sidebar Extras Slot (e.g., Batch Selector) */}
        {!isCollapsed && sidebarExtras && (
          <div className="px-6 py-4 animate-in fade-in slide-in-from-left-4 duration-500">
            {sidebarExtras}
          </div>
        )}

        {/* Sidebar Footer: Profile & Sign Out */}
        <div className={`mt-auto px-6 pb-8 pt-6 flex flex-col gap-4 w-full ${isCollapsed ? 'items-center' : ''}`}>
            {/* User Profile Info Card */}
            {!isCollapsed && (
              <div className="bg-purple-50/20 rounded-2xl p-4 border border-purple-100/40 flex flex-col gap-3 w-full shadow-sm">
                <div className="flex items-start gap-3">
                  <div className="w-10 h-10 shrink-0 flex items-center justify-center bg-purple-50 rounded-xl shadow-sm border border-purple-100/60 text-primary-purple mt-0.5">
                    {userType === 'Assessments' || userType === 'Candidate' ? (
                      <User className="w-5 h-5" />
                    ) : (
                      <Building2 className="w-5 h-5" />
                    )}
                  </div>
                  <div className="flex flex-col min-w-0">
                    {userType === 'Assessments' || userType === 'Candidate' ? (
                      <>
                        <span className="text-[12px] font-black text-zinc-900 tracking-tight leading-tight mb-1.5 uppercase" title={username || 'Student'}>
                          {username || 'Student'}
                        </span>
                        <span className="text-[9px] font-black text-primary-purple uppercase tracking-widest leading-relaxed" title={displayInstitutionName}>
                          {displayInstitutionName}
                        </span>
                      </>
                    ) : (
                      <>
                        <span className="text-[11px] font-black text-zinc-900 tracking-tight leading-tight uppercase" title={displayCampusPartnerName}>
                          {displayCampusPartnerName}
                        </span>
                        <span className="text-[9px] font-bold text-zinc-400 uppercase tracking-widest leading-tight mt-1" title="Campus Partner Admin">
                          Campus Partner Admin
                        </span>
                      </>
                    )}
                  </div>
                </div>

                {userType === 'Campus Partner' && (
                  <button className="w-full py-2.5 rounded-xl border border-purple-100 bg-purple-50/40 hover:bg-purple-50/80 text-primary-purple flex items-center justify-center gap-2 text-[9px] font-black uppercase tracking-widest transition-all shadow-xs group">
                    <span className="w-3.5 h-3.5 rounded-full bg-primary-purple text-white flex items-center justify-center text-[8px] font-bold group-hover:scale-110 transition-transform">✓</span>
                    <span>Verified Institution</span>
                  </button>
                )}
              </div>
            )}
            
            {isCollapsed && (
              <div className="w-12 h-12 flex shrink-0 items-center justify-center text-zinc-900 bg-zinc-50 rounded-xl border border-zinc-100 shadow-sm">
                  <User className="w-5 h-5 text-zinc-600" strokeWidth={2.5} />
              </div>
            )}

            {/* Logout Button */}
            <button 
                onClick={onLogout}
                className={`flex items-center justify-center gap-3 py-4 rounded-xl bg-[#0f172a] hover:bg-black text-white transition-all duration-300 shadow-xl group active:scale-[0.98] ${
                  isCollapsed ? 'w-12 h-12' : 'w-full'
                }`}
                title={isCollapsed ? "Sign Out" : ""}
            >
                <LogOut className="w-4 h-4 text-white group-hover:translate-x-0.5 transition-transform shrink-0" />
                {!isCollapsed && <span className="text-[11px] font-black tracking-[0.2em] uppercase whitespace-nowrap">Sign Out</span>}
            </button>
        </div>
      </aside>

      {/* Main Content Area */}
      <main className={`relative ${isBlurred ? 'z-50' : 'z-auto'} flex-1 flex flex-col h-full overflow-hidden bg-page-bg`}>
        <FloatingElements mode="dashboard" density="low" />
         <header className="min-h-[80px] h-auto py-4 shrink-0 bg-white/80 backdrop-blur-md border-b border-gray-100 z-30 sticky top-0">
           <div className="max-w-[1600px] mx-auto w-full h-full flex items-center justify-between px-[15px]">
             {/* Left side: Mobile branding / Desktop context */}
              <div className="flex items-center gap-2">
                  {/* Mobile Logo */}
                  <div className="md:hidden flex items-center">
                    <Image src="/login.webp" alt="psgmx" width={110} height={36} style={{ objectFit: 'contain' }} priority />
                  </div>
                  
                  {/* Title and Subtitle in Header */}
                  <div className="hidden md:flex flex-col gap-1 max-w-[800px]">
                      {headerTitle && (
                          <h2 className="text-[28px] font-black text-zinc-950 tracking-[-0.04em] leading-tight uppercase">
                              {headerTitle}
                          </h2>
                      )}
                      {headerSubtitle && (
                          <p className="g360-subheading mt-1.5 leading-relaxed">
                              {headerSubtitle}
                          </p>
                      )}
                  </div>
              </div>

             {/* Right side: External Controls (Sign Out, etc.) */}
             <div className="flex items-center gap-3">
                 {headerActions}

                 {showBackButton && (
                   <button 
                      onClick={() => (onBack ? onBack() : router.back())}
                      className="flex items-center gap-2 px-4 py-2 rounded-xl bg-white border border-border-light text-[10px] font-black text-text-muted hover:text-primary-purple hover:border-red-100 hover:bg-red-50/30 transition-all uppercase tracking-widest shadow-sm group"
                   >
                      <ChevronLeft className="w-3.5 h-3.5 transition-transform group-hover:-translate-x-0.5" />
                      <span>Back</span>
                   </button>
                 )}
             </div>
           </div>
         </header>

         {/* Content Scroll Container */}
         <div className="flex-1 overflow-y-auto w-full custom-scrollbar relative z-auto">
            <div className="max-w-[1600px] mx-auto w-full p-[15px] pb-12">
               {children}
            </div>
         </div>

         {/* Mobile Bottom Navigation Bar */}
         <div className="md:hidden fixed bottom-0 left-0 right-0 bg-white/95 backdrop-blur-xl border-t border-zinc-100 z-50 flex items-center shadow-[0_-15px_50px_-15px_rgba(0,0,0,0.15)] pb-safe-offset-1 h-[72px]">
            {/* Left Arrow */}
            <button 
              onClick={() => {
                const nav = document.getElementById('mobile-nav-container');
                if (nav) nav.scrollBy({ left: -100, behavior: 'smooth' });
              }}
              className="w-10 h-full flex items-center justify-center text-zinc-400 hover:text-primary-purple active:scale-90 transition-all bg-gradient-to-r from-white to-transparent z-10"
            >
              <ChevronLeft className="w-5 h-5" />
            </button>

            <nav 
              id="mobile-nav-container"
              className="flex-1 flex items-center overflow-x-auto scroll-smooth custom-scrollbar-hide h-full"
            >
              {sidebarItems.map((item, index) => {
                const Icon = item.icon;
                const isActive = item.active;
                
                return (
                  <button
                    key={index}
                    onClick={item.onClick}
                    className={`flex flex-col items-center justify-center gap-1 transition-all duration-300 relative shrink-0 w-1/4 h-full ${
                      isActive ? 'text-primary-purple' : 'text-zinc-400'
                    }`}
                  >
                    <Icon className={`w-5 h-5 ${isActive ? 'scale-110 mb-0.5' : 'scale-100'}`} />
                    <span className={`text-[9px] font-black uppercase tracking-tighter text-center px-0.5 break-words max-w-full leading-none ${isActive ? 'opacity-100' : 'opacity-60'}`}>
                      {item.label.split(' ').pop()}
                    </span>
                    {isActive && (
                      <span className="absolute bottom-1.5 left-1/2 -translate-x-1/2 w-1 h-1 bg-primary-purple rounded-full shadow-[0_0_8px_#6C3DFF]" />
                    )}
                  </button>
                );
              })}
            </nav>

            {/* Right Arrow */}
            <button 
              onClick={() => {
                const nav = document.getElementById('mobile-nav-container');
                if (nav) nav.scrollBy({ left: 100, behavior: 'smooth' });
              }}
              className="w-10 h-full flex items-center justify-center text-zinc-400 hover:text-primary-purple active:scale-90 transition-all bg-gradient-to-l from-white to-transparent z-10"
            >
              <ChevronRight className="w-5 h-5" />
            </button>
         </div>
      </main>
    </div>
  );
}
