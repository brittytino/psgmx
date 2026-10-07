'use client';

import React, { useState, useEffect } from 'react';
import { usePathname, useRouter } from 'next/navigation';
import {
  Home,
  PenLine,
  BookOpen,
  Award,
  Users,
  Briefcase,
  Megaphone,
  Bell,
} from 'lucide-react';
import { createClient } from '@/lib/supabase/client';
import { getCurrentProfile } from '@/lib/current-profile';
import { AlumniNotificationDrawer } from '@/components/alumni/AlumniNotificationDrawer';
import { AlumniHeaderSearch } from '@/components/alumni/AlumniHeaderSearch';
import PortalSidebar, { NavGroup } from '@/components/platform/PortalSidebar';
import DiceBearAvatar from '@/components/basic/DiceBearAvatar';

const alumniNavGroups: NavGroup[] = [
  {
    groupTitle: 'Network & Heritage',
    items: [
      { name: 'Dashboard', href: '/alumni', icon: Home },
      { name: 'Knowledge Brain', href: '/alumni/knowledge-brain', icon: BookOpen },
      { name: 'My Journey', href: '/alumni/journey', icon: Award },
      { name: 'My Lineage', href: '/alumni/lineage', icon: Users },
    ],
  },
  {
    groupTitle: 'Contributions & Community',
    items: [
      { name: 'Contribute Story', href: '/alumni/contribute', icon: PenLine },
      { name: 'Community Board', href: '/alumni/community-board', icon: Briefcase },
      { name: 'Inbox', href: '/alumni/announcements', icon: Megaphone },
    ],
  },
];

export default function AlumniLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();

  const [notificationsOpen, setNotificationsOpen] = useState(false);
  const [unreadNotifications, setUnreadNotifications] = useState(0);
  const [identity, setIdentity] = useState({
    name: 'Alumni',
    email: '',
    batchYear: 'MCA Alum',
    avatarUrl: null as string | null,
  });

  useEffect(() => {
    void (async () => {
      try {
        const supabase = createClient();
        const me = await getCurrentProfile(supabase);
        if (!me) return;
        setIdentity({
          name: me.name ?? 'Alumni Member',
          email: me.email ?? '',
          batchYear: me.batch_year ? `${me.batch_year} MX` : 'MCA Alum',
          avatarUrl: me.avatar_url ?? null,
        });
      } catch {
        // ignore
      }
    })();
  }, []);

  const handleLogout = async () => {
    try {
      await fetch('/api/auth/logout', { method: 'POST' });
    } catch {}
    router.replace('/login');
    router.refresh();
  };

  return (
    <div className="flex h-screen bg-[#FBF6EE] text-[#1A1A1A] font-sans overflow-hidden selection:bg-[#FF6B4A]/20">
      {/* Reference-Styled Collapsible Cream Sidebar */}
      <PortalSidebar
        portalTitle="Alumni Network"
        portalSubtitle={`${identity.batchYear} · Heritage`}
        logoSrc="/logo.png"
        navGroups={alumniNavGroups}
        user={{
          name: identity.name,
          emailOrReg: identity.email || identity.batchYear,
          batchOrRole: identity.batchYear,
          avatarUrl: identity.avatarUrl,
          portalType: 'alumni',
        }}
        onLogout={handleLogout}
      />

      {/* Main Content Area */}
      <main className="flex-1 flex flex-col min-w-0 h-full overflow-hidden bg-[#FBF6EE]">
        {/* Top Header */}
        <header className="h-[76px] bg-white/80 backdrop-blur-md border-b border-[#EFE9E0] flex items-center justify-between px-6 lg:px-8 shrink-0 relative z-30 transition-colors">
          <div className="flex items-center gap-4 flex-1 max-w-xl">
            <AlumniHeaderSearch />
          </div>

          <div className="flex items-center gap-3">
            <button
              type="button"
              onClick={() => setNotificationsOpen(true)}
              aria-label="Open notifications"
              className={`relative w-10 h-10 flex items-center justify-center rounded-xl bg-[#FAF6F0] hover:bg-[#F5EFE6] border border-[#EFE9E0] transition-colors shadow-2xs ${
                notificationsOpen ? 'text-[#FF6B4A] border-[#FF6B4A]' : 'text-[#706E6B] hover:text-[#1A1A1A]'
              }`}
            >
              <Bell className="w-4 h-4" />
              {unreadNotifications > 0 && (
                <span className="absolute -top-1 -right-1 flex min-h-4 min-w-4 items-center justify-center rounded-full bg-[#FF6B4A] px-1 text-[10px] font-black text-white shadow-2xs">
                  {unreadNotifications > 99 ? '99+' : unreadNotifications}
                </span>
              )}
            </button>

            <AlumniNotificationDrawer
              isOpen={notificationsOpen}
              onClose={() => setNotificationsOpen(false)}
              onUnreadCountChange={setUnreadNotifications}
            />

            <div className="flex items-center gap-2.5 pl-2">
              <DiceBearAvatar
                name={identity.name}
                avatarUrl={identity.avatarUrl}
                size={36}
              />
              <div className="hidden sm:block text-left">
                <p className="text-xs font-black text-[#1A1A1A] leading-tight truncate max-w-[120px]">
                  {identity.name}
                </p>
                <p className="text-[10px] font-semibold text-[#8C877E] truncate">
                  {identity.batchYear}
                </p>
              </div>
            </div>
          </div>
        </header>

        {/* Scrollable Canvas: Unified Layout & Smooth Scrolling */}
        <div className="flex-1 overflow-y-auto custom-scrollbar p-6 lg:p-8">
          <div className="max-w-7xl mx-auto w-full space-y-6 sm:space-y-8">
            {children}
          </div>
        </div>
      </main>
    </div>
  );
}
