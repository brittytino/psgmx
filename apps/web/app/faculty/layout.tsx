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
  const cardContent = getSidebarCardContent(pathname);

  return (
    <div className="flex h-screen bg-page-bg  text-text-main  font-sans overflow-hidden transition-colors duration-300">
      
      {/* Sidebar */}
      <aside className="w-[280px] h-full bg-white  flex flex-col shrink-0 border-r border-border-light  shadow-[4px_0_24px_rgba(0,0,0,0.02)] hidden lg:flex relative z-40 transition-colors duration-300">
        
        {/* Logo */}
        <div className="h-[88px] flex items-center px-8 shrink-0">
          <div className="flex items-center gap-3">
            <img src="/logo.webp" alt="PSGMX Logo" className="w-10 h-10 object-contain drop-shadow-sm" />
            <div>
              <h2 className="text-[17px] font-black tracking-tight text-text-main  leading-tight">Faculty Portal</h2>
              <p className="text-[10px] font-bold text-text-muted  uppercase tracking-wider">Department Mentor</p>
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
                    ? 'bg-primary-purple text-white shadow-md shadow-md shadow-primary-purple/10' 
                    : 'text-text-muted  hover:bg-page-bg  hover:text-text-main  font-semibold'
                }`}
              >
                <div className="flex items-center gap-3.5">
                  <link.icon className={`w-5 h-5 ${isActive ? 'text-white' : 'text-text-muted  group-hover:text-primary-purple'}`} />
                  <span className={`text-[14px] ${isActive ? 'font-bold' : 'font-semibold'}`}>{link.name}</span>
                </div>
                {link.badge && (
                  <span className={`w-5 h-5 rounded-full flex items-center justify-center text-[10px] font-bold ${
                    isActive ? 'bg-white text-primary-purple' : 'bg-primary-purple text-white'
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
          <div className="bg-white/40 backdrop-blur-md border border-white/20  rounded-2xl p-5 relative overflow-hidden h-[180px] flex flex-col justify-between transition-colors duration-300">
            <div className="relative z-10">
              <h4 className="text-primary-purple  font-bold text-[14px] leading-snug mb-1">{cardContent.title}</h4>
              {cardContent.desc && <p className="text-text-muted  text-[11px] leading-relaxed pr-2">{cardContent.desc}</p>}
            </div>
            <div className="absolute -bottom-4 -right-4 w-32 h-32 bg-white/40  rounded-full blur-2xl"></div>
            <div className="relative z-10 mt-auto flex justify-center opacity-80">
              <cardContent.icon className="w-16 h-16 text-primary-purple/20" />
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
              className="fixed inset-0 bg-rich-black/60 backdrop-blur-sm z-40 lg:hidden"
            />
            <motion.aside 
              initial={{ x: '-100%' }} animate={{ x: 0 }} exit={{ x: '-100%' }} transition={{ type: 'spring', damping: 25, stiffness: 200 }}
              className="fixed top-0 left-0 w-[280px] h-full bg-white flex flex-col z-50 shadow-2xl lg:hidden"
            >
              {/* Mobile Sidebar Header */}
              <div className="h-[88px] flex items-center justify-between px-6 shrink-0 border-b border-border-light">
                <div className="flex items-center gap-3">
                  <img src="/logo.webp" alt="PSGMX Logo" className="w-8 h-8 object-contain" />
                  <div>
                    <h2 className="text-[15px] font-black text-text-main">Faculty Portal</h2>
                  </div>
                </div>
                <button onClick={() => setMobileMenuOpen(false)} className="w-8 h-8 flex items-center justify-center rounded-full bg-page-bg text-text-muted">
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
                      className={`flex items-center justify-between px-4 py-3 rounded-[12px] transition-all duration-200 ${isActive ? 'bg-primary-purple text-white' : 'text-text-muted hover:bg-page-bg font-semibold'}`}
                    >
                      <div className="flex items-center gap-3.5">
                        <link.icon className={`w-5 h-5 ${isActive ? 'text-white' : 'text-text-muted'}`} />
                        <span className={`text-[14px] ${isActive ? 'font-bold' : 'font-semibold'}`}>{link.name}</span>
                      </div>
                      {link.badge && (
                        <span className={`w-5 h-5 rounded-full flex items-center justify-center text-[10px] font-bold ${isActive ? 'bg-white text-primary-purple' : 'bg-primary-purple text-white'}`}>
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
        <header className="h-[88px] bg-page-bg  flex items-center justify-between px-8 shrink-0 relative z-30 transition-colors duration-300">
          <div className="flex items-center gap-4">
            <button onClick={() => setMobileMenuOpen(true)} className="w-10 h-10 flex lg:hidden items-center justify-center rounded-full bg-white  border border-border-light  shadow-sm text-text-muted ">
              <Menu className="w-5 h-5" />
            </button>
            <div className="hidden md:flex items-center bg-white  border border-border-light  rounded-full h-11 px-4 w-[360px] shadow-sm focus-within:border-primary-purple focus-within:ring-1 focus-within:ring-[#6C3DFF] transition-all">
              <Search className="w-4 h-4 text-text-muted mr-3" />
              <input type="text" placeholder="Search anything..." className="bg-transparent border-none outline-none text-[14px] text-text-main  placeholder-[#94A3B8] w-full" />
              <div className="flex items-center gap-1 text-text-muted text-[12px] font-bold bg-page-bg  px-2 py-1 rounded-md ml-2 shrink-0">
                <span>⌘</span><span>K</span>
              </div>
            </div>
          </div>

          <div className="flex items-center gap-6">
            {/* Notifications */}
            <div className="relative">
              <button onClick={() => setNotificationsOpen(!notificationsOpen)} className={`relative w-10 h-10 flex items-center justify-center rounded-full bg-white border border-border-light shadow-sm transition-colors ${notificationsOpen ? 'text-primary-purple border-primary-purple' : 'text-text-muted hover:text-text-main'}`}>
                <Bell className="w-5 h-5" />
                <span className="absolute top-0 right-0 w-4 h-4 bg-rich-black text-white text-[9px] font-bold rounded-full flex items-center justify-center border-2 border-white">3</span>
              </button>
              
              <AnimatePresence>
                {notificationsOpen && (
                  <>
                    <div className="fixed inset-0 z-40" onClick={() => setNotificationsOpen(false)}></div>
                    <motion.div initial={{ opacity: 0, y: 10, scale: 0.95 }} animate={{ opacity: 1, y: 0, scale: 1 }} exit={{ opacity: 0, y: 10, scale: 0.95 }} className="absolute right-0 top-12 w-80 bg-white rounded-2xl shadow-xl border border-border-light z-50 overflow-hidden">
                      <div className="p-4 border-b border-border-light flex justify-between items-center">
                        <h3 className="text-[14px] font-bold text-text-main">Notifications</h3>
                        <span className="text-[11px] font-bold text-primary-purple cursor-pointer">Mark all read</span>
                      </div>
                      <div className="p-2 max-h-[300px] overflow-y-auto">
                        <div className="p-3 hover:bg-page-bg rounded-xl cursor-pointer transition-colors flex gap-3">
                          <div className="w-8 h-8 rounded-full bg-page-bg flex items-center justify-center shrink-0"><BookOpen className="w-4 h-4 text-primary-purple" /></div>
                          <div>
                            <p className="text-[13px] text-text-main font-semibold">New article requires review</p>
                            <p className="text-[11px] text-text-muted mt-0.5">2 mins ago</p>
                          </div>
                        </div>
                        <div className="p-3 hover:bg-page-bg rounded-xl cursor-pointer transition-colors flex gap-3">
                          <div className="w-8 h-8 rounded-full bg-page-bg flex items-center justify-center shrink-0"><Users className="w-4 h-4 text-electric-blue" /></div>
                          <div>
                            <p className="text-[13px] text-text-main font-semibold">Mentorship session scheduled</p>
                            <p className="text-[11px] text-text-muted mt-0.5">1 hour ago</p>
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
              <div onClick={() => setProfileOpen(!profileOpen)} className={`flex items-center gap-3 cursor-pointer group bg-white border rounded-full pl-2 pr-4 py-1.5 shadow-sm transition-colors ${profileOpen ? 'border-primary-purple' : 'border-border-light hover:border-border-light'}`}>
                <div className="w-8 h-8 rounded-full bg-border-light overflow-hidden shrink-0 relative">
                  <div className="absolute inset-0 flex items-center justify-center bg-gradient-to-br from-primary-purple to-deep-violet text-white font-bold text-xs">A</div>
                </div>
                <ChevronDown className={`w-4 h-4 transition-transform ${profileOpen ? 'rotate-180 text-primary-purple' : 'text-text-muted group-hover:text-text-muted'}`} />
              </div>

              <AnimatePresence>
                {profileOpen && (
                  <>
                    <div className="fixed inset-0 z-40" onClick={() => setProfileOpen(false)}></div>
                    <motion.div initial={{ opacity: 0, y: 10, scale: 0.95 }} animate={{ opacity: 1, y: 0, scale: 1 }} exit={{ opacity: 0, y: 10, scale: 0.95 }} className="absolute right-0 top-12 w-56 bg-white rounded-2xl shadow-xl border border-border-light z-50 overflow-hidden">
                      <div className="p-4 border-b border-border-light">
                        <p className="text-[14px] font-bold text-text-main">Dr. Arunkumar</p>
                        <p className="text-[12px] text-text-muted">arunkumar@psgtech.ac.in</p>
                      </div>
                      <div className="p-2">
                        <Link href="/faculty/settings" onClick={() => setProfileOpen(false)} className="flex items-center gap-2 w-full p-2 text-[13px] font-semibold text-text-muted hover:bg-page-bg hover:text-text-main rounded-xl transition-colors">
                          <Settings className="w-4 h-4" /> Account Settings
                        </Link>
                        <div className="h-px bg-page-bg my-1"></div>
                        <button className="flex items-center gap-2 w-full p-2 text-[13px] font-semibold text-deep-violet hover:bg-page-bg rounded-xl transition-colors">
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
