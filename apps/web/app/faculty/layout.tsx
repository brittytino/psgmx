'use client';

import React from 'react';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { 
  Home, 
  BrainCircuit, 
  BookOpen, 
  Folder, 
  Target, 
  Users, 
  GraduationCap, 
  BarChart2, 
  Megaphone, 
  Settings,
  Search,
  Sun,
  Moon,
  Bell,
  Menu,
  X,
  LogOut,
  ChevronDown
} from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';

const sidebarLinks = [
  { name: 'Dashboard', href: '/faculty', icon: Home },
  { name: 'AI Senior Insights', href: '/faculty/ai-insights', icon: BrainCircuit },
  { name: 'Knowledge Brain', href: '/faculty/knowledge-brain', icon: BookOpen, badge: 5 },
  { name: 'FYP Repository', href: '/faculty/fyp-repository', icon: Folder },
  { name: 'Recovery Hub', href: '/faculty/recovery-hub', icon: Target },
  { name: 'Students', href: '/faculty/students', icon: Users },
  { name: 'Mentorship', href: '/faculty/mentorship', icon: GraduationCap },
  { name: 'Analytics', href: '/faculty/analytics', icon: BarChart2 },
  { name: 'Announcements', href: '/faculty/announcements', icon: Megaphone },
  { name: 'Settings', href: '/faculty/settings', icon: Settings },
];

const getSidebarCardContent = (pathname: string) => {
  if (pathname.includes('/ai-insights')) {
    return { title: 'AI-Powered Mentorship.', desc: 'Smarter Guidance. Stronger Outcomes.', icon: BrainCircuit };
  }
  if (pathname.includes('/knowledge-brain')) {
    return { title: 'Share Knowledge. Inspire Generations.', desc: "Every article you approve builds the department's collective brain.", icon: BookOpen };
  }
  if (pathname.includes('/fyp-repository')) {
    return { title: 'Great Projects. Stronger Future.', desc: 'Explore innovative ideas and guide the next breakthrough.', icon: Folder };
  }
  if (pathname.includes('/recovery-hub')) {
    return { title: "We're here to support your academic journey.", desc: 'Find resources, get help, and never fall behind.', icon: Target };
  }
  if (pathname.includes('/students')) {
    return { title: 'Mentor. Guide. Inspire.', desc: 'Empower students to achieve their best through the right guidance.', icon: Users };
  }
  if (pathname.includes('/mentorship')) {
    return { title: 'Mentorship drives growth. You guide, they achieve.', desc: '', icon: GraduationCap };
  }
  if (pathname.includes('/analytics')) {
    return { title: 'Data that drives decisions.', desc: "Track what matters and empower every student's journey.", icon: BarChart2 };
  }
  if (pathname.includes('/announcements')) {
    return { title: 'Share updates. Inspire progress.', desc: 'Keep students informed about important news and opportunities.', icon: Megaphone };
  }
  if (pathname.includes('/settings')) {
    return { title: 'Customize your experience.', desc: 'Manage your preferences and portal settings.', icon: Settings };
  }
  // Default (Dashboard)
  return { title: 'Empower Students. Shape Futures.', desc: 'Your guidance today builds the innovators of tomorrow.', icon: GraduationCap };
};

export default function FacultyLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();
  const [mobileMenuOpen, setMobileMenuOpen] = React.useState(false);
  const [profileOpen, setProfileOpen] = React.useState(false);
  const [notificationsOpen, setNotificationsOpen] = React.useState(false);
  const [isDarkMode, setIsDarkMode] = React.useState(false);

  React.useEffect(() => {
    if (isDarkMode) {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }
  }, [isDarkMode]);

  const cardContent = getSidebarCardContent(pathname);

  return (
    <div className="flex h-screen bg-[#F8F9FC] dark:bg-[#0F172A] text-[#1E293B] dark:text-[#F1F5F9] font-sans overflow-hidden transition-colors duration-300">
      
      {/* Sidebar */}
      <aside className="w-[280px] h-full bg-white dark:bg-[#1E293B] flex flex-col shrink-0 border-r border-[#E2E8F0] dark:border-[#334155] shadow-[4px_0_24px_rgba(0,0,0,0.02)] hidden lg:flex relative z-40 transition-colors duration-300">
        
        {/* Logo */}
        <div className="h-[88px] flex items-center px-8 shrink-0">
          <div className="flex items-center gap-3">
            <img src="/logo.webp" alt="PSGMX Logo" className="w-10 h-10 object-contain drop-shadow-sm" />
            <div>
              <h2 className="text-[17px] font-black tracking-tight text-[#1E293B] dark:text-white leading-tight">Faculty Portal</h2>
              <p className="text-[10px] font-bold text-[#64748B] dark:text-[#94A3B8] uppercase tracking-wider">Department Mentor</p>
            </div>
          </div>
        </div>

        {/* Navigation */}
        <nav className="flex-1 overflow-y-auto px-4 py-4 space-y-1.5 custom-scrollbar">
          {sidebarLinks.map((link) => {
            const isActive = pathname === link.href;
            return (
              <Link 
                key={link.name} 
                href={link.href}
                className={`flex items-center justify-between px-4 py-3 rounded-[12px] transition-all duration-200 group ${
                  isActive 
                    ? 'bg-[#6C3DFF] text-white shadow-md shadow-[#6C3DFF]/20' 
                    : 'text-[#475569] dark:text-[#94A3B8] hover:bg-[#F8F9FC] dark:hover:bg-[#334155] hover:text-[#1E293B] dark:hover:text-white font-semibold'
                }`}
              >
                <div className="flex items-center gap-3.5">
                  <link.icon className={`w-5 h-5 ${isActive ? 'text-white' : 'text-[#64748B] dark:text-[#94A3B8] group-hover:text-[#6C3DFF]'}`} />
                  <span className={`text-[14px] ${isActive ? 'font-bold' : 'font-semibold'}`}>{link.name}</span>
                </div>
                {link.badge && (
                  <span className={`w-5 h-5 rounded-full flex items-center justify-center text-[10px] font-bold ${
                    isActive ? 'bg-white text-[#6C3DFF]' : 'bg-[#6C3DFF] text-white'
                  }`}>
                    {link.badge}
                  </span>
                )}
              </Link>
            );
          })}
        </nav>

        {/* Dynamic Callout Card */}
        <div className="p-6 shrink-0">
          <div className="bg-[#F8F6FF] dark:bg-[#2D2A4A] rounded-2xl p-5 relative overflow-hidden h-[180px] flex flex-col justify-between transition-colors duration-300">
            <div className="relative z-10">
              <h4 className="text-[#6C3DFF] dark:text-[#A78BFA] font-bold text-[14px] leading-snug mb-1">{cardContent.title}</h4>
              {cardContent.desc && <p className="text-[#64748B] dark:text-[#94A3B8] text-[11px] leading-relaxed pr-2">{cardContent.desc}</p>}
            </div>
            <div className="absolute -bottom-4 -right-4 w-32 h-32 bg-white/40 dark:bg-black/20 rounded-full blur-2xl"></div>
            <div className="relative z-10 mt-auto flex justify-center opacity-80">
              <cardContent.icon className="w-16 h-16 text-[#6C3DFF]/20" />
            </div>
          </div>
        </div>
      </aside>

      {/* Mobile Sidebar Overlay */}
      <AnimatePresence>
        {mobileMenuOpen && (
          <>
            <motion.div 
              initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
              onClick={() => setMobileMenuOpen(false)}
              className="fixed inset-0 bg-[#1E293B]/60 backdrop-blur-sm z-40 lg:hidden"
            />
            <motion.aside 
              initial={{ x: '-100%' }} animate={{ x: 0 }} exit={{ x: '-100%' }} transition={{ type: 'spring', damping: 25, stiffness: 200 }}
              className="fixed top-0 left-0 w-[280px] h-full bg-white flex flex-col z-50 shadow-2xl lg:hidden"
            >
              {/* Mobile Sidebar Header */}
              <div className="h-[88px] flex items-center justify-between px-6 shrink-0 border-b border-[#F1F5F9]">
                <div className="flex items-center gap-3">
                  <img src="/logo.webp" alt="PSGMX Logo" className="w-8 h-8 object-contain" />
                  <div>
                    <h2 className="text-[15px] font-black text-[#1E293B]">Faculty Portal</h2>
                  </div>
                </div>
                <button onClick={() => setMobileMenuOpen(false)} className="w-8 h-8 flex items-center justify-center rounded-full bg-[#F8F9FC] text-[#64748B]">
                  <X className="w-4 h-4" />
                </button>
              </div>
              
              {/* Mobile Navigation */}
              <nav className="flex-1 overflow-y-auto px-4 py-4 space-y-1.5 custom-scrollbar">
                {sidebarLinks.map((link) => {
                  const isActive = pathname === link.href;
                  return (
                    <Link 
                      key={link.name} 
                      href={link.href}
                      onClick={() => setMobileMenuOpen(false)}
                      className={`flex items-center justify-between px-4 py-3 rounded-[12px] transition-all duration-200 ${isActive ? 'bg-[#6C3DFF] text-white' : 'text-[#475569] hover:bg-[#F8F9FC] font-semibold'}`}
                    >
                      <div className="flex items-center gap-3.5">
                        <link.icon className={`w-5 h-5 ${isActive ? 'text-white' : 'text-[#64748B]'}`} />
                        <span className={`text-[14px] ${isActive ? 'font-bold' : 'font-semibold'}`}>{link.name}</span>
                      </div>
                      {link.badge && (
                        <span className={`w-5 h-5 rounded-full flex items-center justify-center text-[10px] font-bold ${isActive ? 'bg-white text-[#6C3DFF]' : 'bg-[#6C3DFF] text-white'}`}>
                          {link.badge}
                        </span>
                      )}
                    </Link>
                  );
                })}
              </nav>
            </motion.aside>
          </>
        )}
      </AnimatePresence>

      {/* Main Content */}
      <main className="flex-1 flex flex-col min-w-0 h-full overflow-hidden">
        
        {/* Top Header */}
        <header className="h-[88px] bg-[#F8F9FC] dark:bg-[#0F172A] flex items-center justify-between px-8 shrink-0 relative z-30 transition-colors duration-300">
          <div className="flex items-center gap-4">
            <button onClick={() => setMobileMenuOpen(true)} className="w-10 h-10 flex lg:hidden items-center justify-center rounded-full bg-white dark:bg-[#1E293B] border border-[#E2E8F0] dark:border-[#334155] shadow-sm text-[#64748B] dark:text-[#94A3B8]">
              <Menu className="w-5 h-5" />
            </button>
            <div className="hidden md:flex items-center bg-white dark:bg-[#1E293B] border border-[#E2E8F0] dark:border-[#334155] rounded-full h-11 px-4 w-[360px] shadow-sm focus-within:border-[#6C3DFF] focus-within:ring-1 focus-within:ring-[#6C3DFF] transition-all">
              <Search className="w-4 h-4 text-[#94A3B8] mr-3" />
              <input type="text" placeholder="Search anything..." className="bg-transparent border-none outline-none text-[14px] text-[#1E293B] dark:text-white placeholder-[#94A3B8] w-full" />
              <div className="flex items-center gap-1 text-[#94A3B8] text-[12px] font-bold bg-[#F8F9FC] dark:bg-[#334155] px-2 py-1 rounded-md ml-2 shrink-0">
                <span>⌘</span><span>K</span>
              </div>
            </div>
          </div>

          <div className="flex items-center gap-6">
            {/* Theme Toggle */}
            <div className="flex items-center bg-white dark:bg-[#1E293B] border border-[#E2E8F0] dark:border-[#334155] rounded-full p-1 shadow-sm transition-colors duration-300">
              <button onClick={() => setIsDarkMode(false)} className={`w-8 h-8 rounded-full flex items-center justify-center transition-colors ${!isDarkMode ? 'bg-[#6C3DFF] text-white shadow-md' : 'text-[#94A3B8] hover:text-[#64748B]'}`}>
                <Sun className="w-4 h-4" />
              </button>
              <button onClick={() => setIsDarkMode(true)} className={`w-8 h-8 rounded-full flex items-center justify-center transition-colors ${isDarkMode ? 'bg-[#1E293B] text-white shadow-md' : 'text-[#94A3B8] hover:text-[#64748B]'}`}>
                <Moon className="w-4 h-4" />
              </button>
            </div>

            {/* Notifications */}
            <div className="relative">
              <button onClick={() => setNotificationsOpen(!notificationsOpen)} className={`relative w-10 h-10 flex items-center justify-center rounded-full bg-white border border-[#E2E8F0] shadow-sm transition-colors ${notificationsOpen ? 'text-[#6C3DFF] border-[#6C3DFF]' : 'text-[#64748B] hover:text-[#1E293B]'}`}>
                <Bell className="w-5 h-5" />
                <span className="absolute top-0 right-0 w-4 h-4 bg-[#1E293B] text-white text-[9px] font-bold rounded-full flex items-center justify-center border-2 border-white">3</span>
              </button>
              
              <AnimatePresence>
                {notificationsOpen && (
                  <>
                    <div className="fixed inset-0 z-40" onClick={() => setNotificationsOpen(false)}></div>
                    <motion.div initial={{ opacity: 0, y: 10, scale: 0.95 }} animate={{ opacity: 1, y: 0, scale: 1 }} exit={{ opacity: 0, y: 10, scale: 0.95 }} className="absolute right-0 top-12 w-80 bg-white rounded-2xl shadow-xl border border-[#E2E8F0] z-50 overflow-hidden">
                      <div className="p-4 border-b border-[#F1F5F9] flex justify-between items-center">
                        <h3 className="text-[14px] font-bold text-[#1E293B]">Notifications</h3>
                        <span className="text-[11px] font-bold text-[#6C3DFF] cursor-pointer">Mark all read</span>
                      </div>
                      <div className="p-2 max-h-[300px] overflow-y-auto">
                        <div className="p-3 hover:bg-[#F8F9FC] rounded-xl cursor-pointer transition-colors flex gap-3">
                          <div className="w-8 h-8 rounded-full bg-[#F5F3FF] flex items-center justify-center shrink-0"><BookOpen className="w-4 h-4 text-[#6C3DFF]" /></div>
                          <div>
                            <p className="text-[13px] text-[#1E293B] font-semibold">New article requires review</p>
                            <p className="text-[11px] text-[#64748B] mt-0.5">2 mins ago</p>
                          </div>
                        </div>
                        <div className="p-3 hover:bg-[#F8F9FC] rounded-xl cursor-pointer transition-colors flex gap-3">
                          <div className="w-8 h-8 rounded-full bg-[#ECFEFF] flex items-center justify-center shrink-0"><Users className="w-4 h-4 text-[#06B6D4]" /></div>
                          <div>
                            <p className="text-[13px] text-[#1E293B] font-semibold">Mentorship session scheduled</p>
                            <p className="text-[11px] text-[#64748B] mt-0.5">1 hour ago</p>
                          </div>
                        </div>
                      </div>
                    </motion.div>
                  </>
                )}
              </AnimatePresence>
            </div>

            {/* Profile */}
            <div className="relative">
              <div onClick={() => setProfileOpen(!profileOpen)} className={`flex items-center gap-3 cursor-pointer group bg-white border rounded-full pl-2 pr-4 py-1.5 shadow-sm transition-colors ${profileOpen ? 'border-[#6C3DFF]' : 'border-[#E2E8F0] hover:border-[#CBD5E1]'}`}>
                <div className="w-8 h-8 rounded-full bg-[#E2E8F0] overflow-hidden shrink-0 relative">
                  <div className="absolute inset-0 flex items-center justify-center bg-gradient-to-br from-[#6C3DFF] to-[#3B82F6] text-white font-bold text-xs">A</div>
                </div>
                <ChevronDown className={`w-4 h-4 transition-transform ${profileOpen ? 'rotate-180 text-[#6C3DFF]' : 'text-[#94A3B8] group-hover:text-[#64748B]'}`} />
              </div>

              <AnimatePresence>
                {profileOpen && (
                  <>
                    <div className="fixed inset-0 z-40" onClick={() => setProfileOpen(false)}></div>
                    <motion.div initial={{ opacity: 0, y: 10, scale: 0.95 }} animate={{ opacity: 1, y: 0, scale: 1 }} exit={{ opacity: 0, y: 10, scale: 0.95 }} className="absolute right-0 top-12 w-56 bg-white rounded-2xl shadow-xl border border-[#E2E8F0] z-50 overflow-hidden">
                      <div className="p-4 border-b border-[#F1F5F9]">
                        <p className="text-[14px] font-bold text-[#1E293B]">Dr. Arunkumar</p>
                        <p className="text-[12px] text-[#64748B]">arunkumar@psgtech.ac.in</p>
                      </div>
                      <div className="p-2">
                        <Link href="/faculty/settings" onClick={() => setProfileOpen(false)} className="flex items-center gap-2 w-full p-2 text-[13px] font-semibold text-[#475569] hover:bg-[#F8F9FC] hover:text-[#1E293B] rounded-xl transition-colors">
                          <Settings className="w-4 h-4" /> Account Settings
                        </Link>
                        <div className="h-px bg-[#F1F5F9] my-1"></div>
                        <button className="flex items-center gap-2 w-full p-2 text-[13px] font-semibold text-[#EF4444] hover:bg-[#FEF2F2] rounded-xl transition-colors">
                          <LogOut className="w-4 h-4" /> Sign out
                        </button>
                      </div>
                    </motion.div>
                  </>
                )}
              </AnimatePresence>
            </div>
          </div>
        </header>

        {/* Page Content */}
        <div className="flex-1 overflow-y-auto p-8 custom-scrollbar relative">
          {children}
        </div>
      </main>
      
    </div>
  );
}
