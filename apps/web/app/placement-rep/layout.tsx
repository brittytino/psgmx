'use client';

import React from 'react';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { LayoutDashboard, Users, CalendarClock, LogOut, Menu, X, UserRoundCog, ClipboardCheck, ListTodo, Building2, Megaphone, LibraryBig, BarChart3, Rocket } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import { createClient } from '@/lib/supabase/client';

const sidebarLinks = [
  { name: 'Command Center', href: '/placement-rep', icon: LayoutDashboard },
  { name: 'Members & Access', href: '/placement-rep/members', icon: UserRoundCog },
  { name: 'Team Management', href: '/placement-rep/teams', icon: Users },
  { name: 'Session Scheduling', href: '/placement-rep/sessions', icon: CalendarClock },
  { name: 'Attendance', href: '/placement-rep/attendance', icon: ClipboardCheck },
  { name: 'Daily Tasks', href: '/placement-rep/tasks', icon: ListTodo },
  { name: 'Companies', href: '/placement-rep/companies', icon: Building2 },
  { name: 'Announcements', href: '/placement-rep/announcements', icon: Megaphone },
  { name: 'Question Bank', href: '/placement-rep/questions', icon: LibraryBig },
  { name: 'Reports & Audit', href: '/placement-rep/reports', icon: BarChart3 },
  { name: 'Staged Rollout', href: '/placement-rep/rollout', icon: Rocket },
];

function NavLinks({ pathname, onNavigate }: { pathname: string; onNavigate?: () => void }) {
  return (
    <>
      {sidebarLinks.map((link) => {
        const isActive = pathname === link.href;
        return (
          <Link
            key={link.name}
            href={link.href}
            onClick={onNavigate}
            className={`flex items-center gap-3.5 px-4 py-3 rounded-[12px] transition-all duration-200 ${
              isActive
                ? 'bg-primary-purple text-white shadow-md shadow-primary-purple/10'
                : 'text-text-muted hover:bg-page-bg hover:text-text-main font-semibold'
            }`}
          >
            <link.icon className={`w-5 h-5 ${isActive ? 'text-white' : 'text-text-muted'}`} />
            <span className={`text-[14px] ${isActive ? 'font-bold' : 'font-semibold'}`}>{link.name}</span>
          </Link>
        );
      })}
    </>
  );
}

export default function PlacementRepLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();
  const [mobileMenuOpen, setMobileMenuOpen] = React.useState(false);

  const handleLogout = async () => {
    const supabase = createClient();
    await supabase.auth.signOut();
    router.push('/login');
  };

  return (
    <div className="flex h-screen bg-page-bg text-text-main font-sans overflow-hidden">
      <aside className="w-[260px] h-full bg-white flex-col shrink-0 border-r border-border-light shadow-[4px_0_24px_rgba(0,0,0,0.02)] hidden lg:flex">
        <div className="h-[88px] flex items-center px-8 shrink-0">
          <div>
            <h2 className="text-[17px] font-black tracking-tight text-text-main leading-tight">Placement Rep</h2>
            <p className="text-[10px] font-bold text-text-muted uppercase tracking-wider">Web Console</p>
          </div>
        </div>
        <nav className="flex-1 px-4 py-4 space-y-1.5">
          <NavLinks pathname={pathname} />
        </nav>
        <div className="p-4 shrink-0">
          <button
            onClick={handleLogout}
            className="w-full flex items-center gap-3 px-4 py-3 rounded-[12px] text-text-muted hover:bg-page-bg hover:text-deep-violet font-semibold text-[14px] transition-colors"
          >
            <LogOut className="w-5 h-5" /> Log out
          </button>
        </div>
      </aside>

      <AnimatePresence>
        {mobileMenuOpen && (
          <>
            <motion.div
              initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
              onClick={() => setMobileMenuOpen(false)}
              className="fixed inset-0 bg-black/50 z-40 lg:hidden"
            />
            <motion.aside
              initial={{ x: '-100%' }} animate={{ x: 0 }} exit={{ x: '-100%' }} transition={{ type: 'spring', damping: 25, stiffness: 200 }}
              className="fixed top-0 left-0 w-[260px] h-full bg-white flex flex-col z-50 shadow-2xl lg:hidden"
            >
              <div className="h-[72px] flex items-center justify-between px-6 shrink-0 border-b border-border-light">
                <h2 className="text-[15px] font-black text-text-main">Placement Rep</h2>
                <button onClick={() => setMobileMenuOpen(false)} className="w-8 h-8 flex items-center justify-center rounded-full bg-page-bg text-text-muted">
                  <X className="w-4 h-4" />
                </button>
              </div>
              <nav className="flex-1 px-4 py-4 space-y-1.5">
                <NavLinks pathname={pathname} onNavigate={() => setMobileMenuOpen(false)} />
              </nav>
            </motion.aside>
          </>
        )}
      </AnimatePresence>

      <main className="flex-1 flex flex-col min-w-0 h-full overflow-y-auto">
        <header className="h-[72px] flex items-center px-6 lg:hidden shrink-0 border-b border-border-light bg-white">
          <button onClick={() => setMobileMenuOpen(true)} className="w-10 h-10 flex items-center justify-center rounded-full bg-page-bg text-text-muted">
            <Menu className="w-5 h-5" />
          </button>
          <h1 className="ml-4 text-[16px] font-black text-text-main">Placement Rep</h1>
        </header>
        <div className="flex-1 p-6 lg:p-8">
          {children}
        </div>
      </main>
    </div>
  );
}
