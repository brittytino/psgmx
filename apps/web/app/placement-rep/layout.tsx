'use client';

import React, { useEffect, useState } from 'react';
import { usePathname, useRouter } from 'next/navigation';
import {
  LayoutDashboard,
  Users,
  CalendarClock,
  UserRoundCog,
  ClipboardCheck,
  ListTodo,
  Megaphone,
  LibraryBig,
  BarChart3,
  Activity,
  Rocket,
  Route,
  CheckSquare,
} from 'lucide-react';
import { createClient } from '@/lib/supabase/client';
import { getCurrentProfile } from '@/lib/current-profile';
import PortalSidebar, { NavGroup } from '@/components/platform/PortalSidebar';
import DiceBearAvatar from '@/components/basic/DiceBearAvatar';

const prNavGroups: NavGroup[] = [
  {
    groupTitle: 'Pulse & Reports',
    items: [
      { name: 'Command Center', href: '/placement-rep', icon: LayoutDashboard },
      { name: 'Readiness Pulse', href: '/placement-rep/pulse', icon: Activity },
      { name: 'Preparation Health', href: '/placement-rep/reports', icon: BarChart3 },
    ],
  },
  {
    groupTitle: 'Cohort Operations',
    items: [
      { name: 'Roster & Members', href: '/placement-rep/members', icon: UserRoundCog },
      { name: 'Daily Tasks', href: '/placement-rep/tasks', icon: CheckSquare },
      { name: 'Participation', href: '/placement-rep/participation', icon: ClipboardCheck },
      { name: 'Preparation Squads', href: '/placement-rep/squads', icon: Users },
    ],
  },
  {
    groupTitle: 'Curriculum & Sessions',
    items: [
      { name: 'Quest Studio', href: '/placement-rep/quest-studio', icon: ListTodo },
      { name: 'Question Bank', href: '/placement-rep/question-bank', icon: LibraryBig },
      { name: 'Programme Calendar', href: '/placement-rep/sessions', icon: CalendarClock },
      { name: 'Preparation Tracks', href: '/placement-rep/tracks', icon: Route },
      { name: 'Communication', href: '/placement-rep/communication', icon: Megaphone },
      { name: 'Rollout', href: '/placement-rep/rollout', icon: Rocket },
    ],
  },
];

export default function PlacementRepLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();

  const [identity, setIdentity] = useState({
    name: 'Placement Rep',
    regNo: '',
    batchCode: '25MX · 26MX',
    avatarUrl: null as string | null,
  });

  useEffect(() => {
    void (async () => {
      try {
        const supabase = createClient();
        const me = await getCurrentProfile(supabase);
        if (!me) return;
        let batchCode = '25MX · 26MX';
        if (me.batch_id) {
          const { data: batch } = await supabase
            .from('batches')
            .select('batch_code')
            .eq('id', me.batch_id)
            .maybeSingle();
          if ((batch as any)?.batch_code) batchCode = (batch as any).batch_code;
        }
        setIdentity({
          name: me.name ?? 'Placement Rep',
          regNo: me.reg_no ?? '',
          batchCode,
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
        portalTitle="Placement Rep"
        portalSubtitle={`${identity.batchCode} Console`}
        logoSrc="/logo.png"
        navGroups={prNavGroups}
        user={{
          name: identity.name,
          emailOrReg: identity.regNo || identity.batchCode,
          batchOrRole: 'Placement Lead',
          avatarUrl: identity.avatarUrl,
          isPlacementRep: true,
          portalType: 'placement-rep',
        }}
        onLogout={handleLogout}
      />

      {/* Main Content Area */}
      <main className="flex-1 flex flex-col min-w-0 h-full overflow-hidden bg-[#FBF6EE]">
        {/* Top Header */}
        <header className="h-[76px] bg-white/80 backdrop-blur-md border-b border-[#EFE9E0] flex items-center justify-between px-6 lg:px-8 shrink-0 relative z-30 transition-colors">
          <div className="flex items-center gap-3">
            <div>
              <h1 className="text-base font-black text-[#1A1A1A] leading-tight">
                Placement Representative Console
              </h1>
              <p className="text-[10px] font-bold text-[#8C877E] uppercase tracking-wider">
                Cohort Readiness · 25MX & 26MX Department OS
              </p>
            </div>
          </div>

          <div className="flex items-center gap-2.5">
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
                {identity.batchCode}
              </p>
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
