'use client';

import React from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import {
  Home,
  PenLine,
  BookOpen,
  Award,
  Users,
  Briefcase,
  Megaphone,
  Settings,
  Search,
  Bell,
  Menu,
  X,
  LogOut,
  ChevronDown,
  GraduationCap,
} from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import { createClient } from '@/lib/supabase/client';
import { InitialsAvatar } from '@/components/basic/InitialsAvatar';

type NotificationItem = { id: string; title: string; message: string; generatedAt: string };

const sidebarLinks = [
  { name: 'Dashboard', href: '/alumni', icon: Home },
  { name: 'Contribute', href: '/alumni/contribute', icon: PenLine },
  { name: 'Knowledge Brain', href: '/alumni/knowledge-brain', icon: BookOpen },
  { name: 'My Journey', href: '/alumni/journey', icon: Award },
  { name: 'My Lineage', href: '/alumni/lineage', icon: Users },
  { name: 'Community Board', href: '/alumni/community-board', icon: Briefcase },
  { name: 'Inbox', href: '/alumni/announcements', icon: Megaphone },
  { name: 'Account', href: '/alumni/settings', icon: Settings },
];

const getSidebarCardContent = (pathname: string) => {
  if (pathname.includes('/contribute')) {
    return { title: 'Every article you write helps 200+ students prepare better.', desc: 'Your experience is someone\'s roadmap.', icon: PenLine };
  }
  if (pathname.includes('/knowledge-brain')) {
    return { title: 'You helped build this. Keep exploring.', desc: 'The department\'s collective intelligence.', icon: BookOpen };
  }
  if (pathname.includes('/journey')) {
    return { title: 'Your batch journey, archived forever.', desc: 'Two years of work, permanently recorded.', icon: Award };
  }
  if (pathname.includes('/lineage')) {
    return { title: 'Your junior has the same suffix. Be the senior you needed.', desc: '', icon: Users };
  }
  if (pathname.includes('/community-board') || pathname.includes('/marketplace')) {
    return { title: 'Collaborate without replacing NEO PAT.', desc: 'Projects, mentoring and clearly unofficial community information.', icon: Briefcase };
  }
  if (pathname.includes('/settings')) {
    return { title: 'Your alumni profile is your department legacy.', desc: 'Keep it current for your junior.', icon: Settings };
  }
  return { title: 'Your experience is someone\'s roadmap. Share it.', desc: 'Alumni who contribute shape all future batches.', icon: GraduationCap };
};

export default function AlumniLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const [mobileMenuOpen, setMobileMenuOpen] = React.useState(false);
  const [profileOpen, setProfileOpen] = React.useState(false);
  const [notificationsOpen, setNotificationsOpen] = React.useState(false);
  const [me, setMe] = React.useState<{ name: string; email: string; batchCode: string } | null>(null);
  const [notifications, setNotifications] = React.useState<NotificationItem[]>([]);
  const cardContent = getSidebarCardContent(pathname);

  React.useEffect(() => {
    let cancelled = false;
    const supabase = createClient();
    (async () => {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;
      const [{ data: profileRows }, { data: notifs }] = await Promise.all([
        supabase.rpc('get_my_profile'),
        supabase.from('notifications').select('id, title, message, generated_at').eq('is_active', true).order('generated_at', { ascending: false }).limit(5),
      ]);
      if (cancelled) return;
      const profile = Array.isArray(profileRows) ? profileRows[0] : profileRows;
      if (profile) {
        let batchCode = '';
        if (profile.batch_id) {
          const { data: batch } = await supabase.from('batches').select('batch_code').eq('id', profile.batch_id).maybeSingle();
          batchCode = (batch as { batch_code?: string } | null)?.batch_code || '';
        }
        if (!cancelled) setMe({ name: profile.name, email: profile.email, batchCode });
      }
      setNotifications((notifs || []).map((n) => ({ id: n.id, title: n.title, message: n.message, generatedAt: n.generated_at })));
    })();
    return () => { cancelled = true; };
  }, []);

  const handleLogout = async () => {
    try { await fetch('/api/auth/logout', { method: 'POST' }); } catch {}
    window.location.href = '/login';
  };

  return (
    <div className="flex h-screen bg-page-bg text-text-main font-sans overflow-hidden transition-colors duration-300">

      {/* Sidebar */}
      <aside className="w-[280px] h-full bg-white flex flex-col shrink-0 border-r border-border-light shadow-[4px_0_24px_rgba(0,0,0,0.02)] hidden lg:flex relative z-40 transition-colors duration-300">

        {/* Logo */}
        <div className="h-[88px] flex items-center px-8 shrink-0">
          <div className="flex items-center gap-3">
            <img src="/logo.webp" alt="PSGMX Logo" className="w-10 h-10 object-contain drop-shadow-sm" />
            <div>
              <h2 className="text-[17px] font-black tracking-tight text-text-main leading-tight">Alumni Portal</h2>
              <p className="text-[10px] font-bold text-text-muted uppercase tracking-wider">MCA Network</p>
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
                    ? 'bg-primary-purple text-white shadow-md shadow-primary-purple/10'
                    : 'text-text-muted hover:bg-page-bg hover:text-text-main font-semibold'
                }`}
              >
                <div className="flex items-center gap-3.5">
                  <link.icon className={`w-5 h-5 ${isActive ? 'text-white' : 'text-text-muted group-hover:text-primary-purple'}`} />
                  <span className={`text-[14px] ${isActive ? 'font-bold' : 'font-semibold'}`}>{link.name}</span>
                </div>
              </Link>
            );
          })}
        </nav>

        {/* Dynamic Callout Card */}
        <div className="p-6 shrink-0">
          <div className="bg-white/40 backdrop-blur-md border border-white/20 rounded-2xl p-5 relative overflow-hidden h-[180px] flex flex-col justify-between transition-colors duration-300">
            <div className="relative z-10">
              <h4 className="text-primary-purple font-bold text-[14px] leading-snug mb-1">{cardContent.title}</h4>
              {cardContent.desc && <p className="text-text-muted text-[11px] leading-relaxed pr-2">{cardContent.desc}</p>}
            </div>
            <div className="absolute -bottom-4 -right-4 w-32 h-32 bg-white/40 rounded-full blur-2xl"></div>
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
            <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} onClick={() => setMobileMenuOpen(false)} className="fixed inset-0 bg-rich-black/60 backdrop-blur-sm z-40 lg:hidden" />
            <motion.aside initial={{ x: '-100%' }} animate={{ x: 0 }} exit={{ x: '-100%' }} transition={{ type: 'spring', damping: 25, stiffness: 200 }} className="fixed top-0 left-0 w-[280px] h-full bg-white flex flex-col z-50 shadow-2xl lg:hidden">
              <div className="h-[88px] flex items-center justify-between px-6 shrink-0 border-b border-border-light">
                <div className="flex items-center gap-3">
                  <img src="/logo.webp" alt="PSGMX Logo" className="w-8 h-8 object-contain" />
                  <h2 className="text-[15px] font-black text-text-main">Alumni Portal</h2>
                </div>
                <button onClick={() => setMobileMenuOpen(false)} className="w-8 h-8 flex items-center justify-center rounded-full bg-page-bg text-text-muted"><X className="w-4 h-4" /></button>
              </div>
              <nav className="flex-1 overflow-y-auto px-4 py-4 space-y-1.5">
                {sidebarLinks.map((link) => {
                  const isActive = pathname === link.href;
                  return (
                    <Link key={link.name} href={link.href} onClick={() => setMobileMenuOpen(false)} className={`flex items-center justify-between px-4 py-3 rounded-[12px] transition-all duration-200 ${isActive ? 'bg-primary-purple text-white' : 'text-text-muted hover:bg-page-bg font-semibold'}`}>
                      <div className="flex items-center gap-3.5">
                        <link.icon className={`w-5 h-5 ${isActive ? 'text-white' : 'text-text-muted'}`} />
                        <span className={`text-[14px] ${isActive ? 'font-bold' : 'font-semibold'}`}>{link.name}</span>
                      </div>
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
        <header className="h-[88px] bg-page-bg flex items-center justify-between px-8 shrink-0 relative z-30">
          <div className="flex items-center gap-4">
            <button onClick={() => setMobileMenuOpen(true)} className="w-10 h-10 flex lg:hidden items-center justify-center rounded-full bg-white border border-border-light shadow-sm text-text-muted">
              <Menu className="w-5 h-5" />
            </button>
            <div className="hidden md:flex items-center bg-white border border-border-light rounded-full h-11 px-4 w-[360px] shadow-sm focus-within:border-primary-purple focus-within:ring-1 focus-within:ring-primary-purple transition-all">
              <Search className="w-4 h-4 text-text-muted mr-3" />
              <input type="text" placeholder="Search knowledge brain, opportunities..." className="bg-transparent border-none outline-none text-[14px] text-text-main placeholder-text-muted w-full" />
            </div>
          </div>
          <div className="flex items-center gap-6">
            <div className="relative">
              <button onClick={() => setNotificationsOpen(!notificationsOpen)} className={`relative w-10 h-10 flex items-center justify-center rounded-full bg-white border border-border-light shadow-sm transition-colors ${notificationsOpen ? 'text-primary-purple border-primary-purple' : 'text-text-muted'}`}>
                <Bell className="w-5 h-5" />
                {notifications.length > 0 && (
                  <span className="absolute top-0 right-0 w-4 h-4 bg-deep-violet text-white text-[9px] font-bold rounded-full flex items-center justify-center border-2 border-white">{notifications.length}</span>
                )}
              </button>
              <AnimatePresence>
                {notificationsOpen && (
                  <>
                    <div className="fixed inset-0 z-40" onClick={() => setNotificationsOpen(false)} />
                    <motion.div initial={{ opacity: 0, y: 10, scale: 0.95 }} animate={{ opacity: 1, y: 0, scale: 1 }} exit={{ opacity: 0, y: 10, scale: 0.95 }} className="absolute right-0 top-12 w-72 bg-white rounded-2xl shadow-xl border border-border-light z-50 overflow-hidden">
                      <div className="p-4 border-b border-border-light"><h3 className="text-[14px] font-bold text-text-main">Notifications</h3></div>
                      <div className="p-2 max-h-[300px] overflow-y-auto">
                        {notifications.length === 0 && (
                          <p className="p-4 text-[13px] text-text-muted text-center">No notifications yet.</p>
                        )}
                        {notifications.map((n) => (
                          <div key={n.id} className="p-3 hover:bg-page-bg rounded-xl transition-colors flex gap-3">
                            <div className="w-8 h-8 rounded-full bg-page-bg flex items-center justify-center shrink-0"><BookOpen className="w-4 h-4 text-primary-purple" /></div>
                            <div><p className="text-[13px] font-semibold text-text-main">{n.title}</p><p className="text-[11px] text-text-muted mt-0.5">{new Date(n.generatedAt).toLocaleDateString('en-IN', { month: 'short', day: 'numeric' })}</p></div>
                          </div>
                        ))}
                      </div>
                    </motion.div>
                  </>
                )}
              </AnimatePresence>
            </div>
            <div className="relative">
              <div onClick={() => setProfileOpen(!profileOpen)} className={`flex items-center gap-3 cursor-pointer bg-white border rounded-full pl-2 pr-4 py-1.5 shadow-sm transition-colors ${profileOpen ? 'border-primary-purple' : 'border-border-light'}`}>
                <InitialsAvatar name={me?.name || '?'} size={32} />
                <ChevronDown className={`w-4 h-4 transition-transform ${profileOpen ? 'rotate-180 text-primary-purple' : 'text-text-muted'}`} />
              </div>
              <AnimatePresence>
                {profileOpen && (
                  <>
                    <div className="fixed inset-0 z-40" onClick={() => setProfileOpen(false)} />
                    <motion.div initial={{ opacity: 0, y: 10, scale: 0.95 }} animate={{ opacity: 1, y: 0, scale: 1 }} exit={{ opacity: 0, y: 10, scale: 0.95 }} className="absolute right-0 top-12 w-56 bg-white rounded-2xl shadow-xl border border-border-light z-50 overflow-hidden">
                      <div className="p-4 border-b border-border-light"><p className="text-[14px] font-bold text-text-main">{me?.name || 'Loading…'}</p><p className="text-[12px] text-text-muted">Alumni{me?.batchCode ? ` · ${me.batchCode}` : ''}</p></div>
                      <div className="p-2">
                        <Link href="/alumni/settings" onClick={() => setProfileOpen(false)} className="flex items-center gap-2 w-full p-2 text-[13px] font-semibold text-text-muted hover:bg-page-bg hover:text-text-main rounded-xl transition-colors"><Settings className="w-4 h-4" /> Settings</Link>
                        <div className="h-px bg-page-bg my-1" />
                        <button onClick={handleLogout} className="flex items-center gap-2 w-full p-2 text-[13px] font-semibold text-deep-violet hover:bg-page-bg rounded-xl transition-colors"><LogOut className="w-4 h-4" /> Sign out</button>
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
