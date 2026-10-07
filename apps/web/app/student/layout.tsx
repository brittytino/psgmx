'use client';

import React from 'react';
import { usePathname, useRouter } from 'next/navigation';
import {
  Home,
  Zap,
  Code2,
  Award,
  BrainCircuit,
  ClipboardList,
  BookOpen,
  Users,
  GraduationCap,
  Megaphone,
  Folder,
  Building2,
  ShieldCheck,
  Inbox,
  Bell,
  Search,
  Settings,
} from 'lucide-react';
import { createClient } from '@/lib/supabase/client';
import { getCurrentProfile } from '@/lib/current-profile';
import { NotificationDrawer } from '@/components/student/NotificationDrawer';
import { StudentHeaderSearch } from '@/components/student/StudentHeaderSearch';
import PortalSidebar, { NavGroup } from '@/components/platform/PortalSidebar';
import DiceBearAvatar from '@/components/basic/DiceBearAvatar';

const studentNavGroups: NavGroup[] = [
  {
    groupTitle: 'Routine & Practice',
    items: [
      { name: 'Today', href: '/student', icon: Home, shortcut: '⌘1' },
      { name: 'Train Gymnasium', href: '/student/train', icon: Zap, shortcut: '⌘2' },
      { name: 'CodeBox Tasks', href: '/student/codebox', icon: Code2, shortcut: '⌘3' },
      { name: 'Readiness & Progress', href: '/student/progress', icon: Award },
    ],
  },
  {
    groupTitle: 'AI & Mock Exams',
    items: [
      { name: 'AI Senior', href: '/student/ai-senior', icon: BrainCircuit },
      { name: 'Mock Assessments', href: '/student/exams', icon: ClipboardList },
      { name: 'Interview Patterns', href: '/student/interview-patterns', icon: Building2 },
      { name: 'Recovery Support', href: '/student/recovery-hub', icon: ShieldCheck },
    ],
  },
  {
    groupTitle: 'Community & Projects',
    items: [
      { name: 'Knowledge Brain', href: '/student/knowledge-brain', icon: BookOpen },
      { name: 'Peer Squads', href: '/student/squads', icon: Users },
      { name: 'Lineage Mentors', href: '/student/lineage', icon: GraduationCap },
      { name: 'Community Board', href: '/student/community-board', icon: Megaphone },
      { name: 'FYP Portfolio', href: '/student/fyp', icon: Folder },
      { name: 'Unified Inbox', href: '/student/inbox', icon: Inbox },
    ],
  },
];

export default function StudentLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();

  const [notificationsOpen, setNotificationsOpen] = React.useState(false);
  const [unreadNotifications, setUnreadNotifications] = React.useState(0);
  const [identity, setIdentity] = React.useState({
    name: 'Student',
    regNo: '',
    batchCode: 'MCA',
    avatarUrl: null as string | null,
  });
  const [isPlacementRep, setIsPlacementRep] = React.useState(false);

  React.useEffect(() => {
    void (async () => {
      try {
        const supabase = createClient();
        const me = await getCurrentProfile(supabase);
        if (!me) return;
        setIsPlacementRep(me.roles?.isPlacementRep === true);
        let batchCode = 'MCA';
        if (me.batch_id) {
          const { data: batch } = await supabase
            .from('batches')
            .select('batch_code')
            .eq('id', me.batch_id)
            .maybeSingle();
          batchCode = (batch as any)?.batch_code ?? batchCode;
        }
        setIdentity({
          name: me.name ?? 'Student',
          regNo: me.reg_no ?? '',
          batchCode,
          avatarUrl: me.avatar_url ?? null,
        });
      } catch {
        /* Route protection handles an unavailable session. */
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
        portalTitle="Student Portal"
        portalSubtitle={`${identity.batchCode} · MCA`}
        logoSrc="/logo.png"
        navGroups={studentNavGroups}
        user={{
          name: identity.name,
          emailOrReg: identity.regNo || '25MX/26MX',
          batchOrRole: identity.batchCode,
          avatarUrl: identity.avatarUrl,
          isPlacementRep,
          portalType: 'student',
        }}
        onLogout={handleLogout}
      />

      {/* Main Content Area */}
      <main className="flex-1 flex flex-col min-w-0 h-full overflow-hidden bg-[#FBF6EE]">
        {/* Top Header */}
        <header className="h-[76px] bg-white/80 backdrop-blur-md border-b border-[#EFE9E0] flex items-center justify-between px-6 lg:px-8 shrink-0 relative z-30 transition-colors">
          {/* Breadcrumb / Search Bar */}
          <div className="flex items-center gap-4 flex-1 max-w-xl">
            <StudentHeaderSearch />
          </div>

          {/* Right Header Controls */}
          <div className="flex items-center gap-3">
            {/* Notifications Bell */}
            <button
              type="button"
              onClick={() => setNotificationsOpen(true)}
              aria-label="Open notifications"
              className={`relative w-10 h-10 flex items-center justify-center rounded-xl bg-[#FAF6F0] hover:bg-[#F5EFE6] border border-[#EFE9E0] transition-colors shadow-2xs cursor-pointer ${
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

            <NotificationDrawer
              isOpen={notificationsOpen}
              onClose={() => setNotificationsOpen(false)}
              onUnreadCountChange={setUnreadNotifications}
            />

            {/* Profile Avatar Pill with DiceBear Clay Avatar */}
            <div className="flex items-center gap-2.5 pl-2">
              <DiceBearAvatar
                name={identity.name}
                avatarUrl={identity.avatarUrl}
                size={36}
                className="rounded-xl shadow-2xs"
              />
              <div className="hidden sm:block text-left">
                <p className="text-xs font-black text-[#1A1A1A] leading-tight truncate max-w-[120px]">
                  {identity.name}
                </p>
                <p className="text-[10px] font-semibold text-[#8C877E] truncate">
                  {identity.regNo || identity.batchCode}
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
