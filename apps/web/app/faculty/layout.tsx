'use client';

import React, { useState, useEffect } from 'react';
import { usePathname, useRouter } from 'next/navigation';
import {
  Home,
  BrainCircuit,
  BookOpen,
  ClipboardList,
  Folder,
  Target,
  Users,
  GraduationCap,
  BarChart2,
  Megaphone,
  UserCog,
  ShieldCheck,
  Bell,
  Search,
} from 'lucide-react';
import { createClient } from '@/lib/supabase/client';
import PortalSidebar, { NavGroup } from '@/components/platform/PortalSidebar';
import DiceBearAvatar from '@/components/basic/DiceBearAvatar';

const baseFacultyNavGroups: NavGroup[] = [
  {
    groupTitle: 'Instruction & Insights',
    items: [
      { name: 'Dashboard', href: '/faculty', icon: Home },
      { name: 'AI Senior Insights', href: '/faculty/ai-insights', icon: BrainCircuit },
      { name: 'Assessment Studio', href: '/faculty/assessment-studio', icon: ClipboardList },
      { name: 'Knowledge Brain', href: '/faculty/knowledge-brain', icon: BookOpen },
    ],
  },
  {
    groupTitle: 'Mentorship & Cohort',
    items: [
      { name: 'Students', href: '/faculty/students', icon: Users },
      { name: 'Mentorship', href: '/faculty/mentorship', icon: GraduationCap },
      { name: 'FYP Repository', href: '/faculty/fyp-repository', icon: Folder },
      { name: 'Recovery Hub', href: '/faculty/recovery-hub', icon: Target },
    ],
  },
  {
    groupTitle: 'Analytics & Notices',
    items: [
      { name: 'Analytics', href: '/faculty/analytics', icon: BarChart2 },
      { name: 'Announcements', href: '/faculty/announcements', icon: Megaphone },
    ],
  },
];

const hodNavGroup: NavGroup = {
  groupTitle: 'Department Governance',
  items: [
    { name: 'Batch Management', href: '/faculty/batch-management', icon: Users },
    { name: 'Faculty Management', href: '/faculty/faculty-management', icon: UserCog },
    { name: 'Governance', href: '/faculty/governance', icon: ShieldCheck },
  ],
};

export default function FacultyLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();

  const [me, setMe] = useState<{ name: string; email: string; isHod: boolean; avatarUrl?: string | null } | null>(null);

  useEffect(() => {
    void (async () => {
      try {
        const supabase = createClient();
        const {
          data: { user },
        } = await supabase.auth.getUser();
        if (!user) return;
        const { data: profile } = await supabase
          .from('users')
          .select('name, email, role_label, avatar_url')
          .eq('id', user.id)
          .single();
        if (profile) {
          setMe({
            name: profile.name,
            email: profile.email,
            isHod: profile.role_label === 'hod',
            avatarUrl: profile.avatar_url ?? null,
          });
        }
      } catch {
        // ignore
      }
    })();
  }, []);

  const handleSignOut = async () => {
    const supabase = createClient();
    await supabase.auth.signOut();
    router.push('/login');
  };

  const navGroups = me?.isHod
    ? [...baseFacultyNavGroups, hodNavGroup]
    : baseFacultyNavGroups;

  return (
    <div className="flex h-screen bg-[#FBF6EE] text-[#1A1A1A] font-sans overflow-hidden selection:bg-[#FF6B4A]/20">
      {/* Reference-Styled Collapsible Cream Sidebar */}
      <PortalSidebar
        portalTitle="Faculty Portal"
        portalSubtitle={me?.isHod ? 'Head of Department' : 'Department Mentor'}
        logoSrc="/logo.png"
        navGroups={navGroups}
        user={{
          name: me?.name || 'Faculty Member',
          emailOrReg: me?.email || 'mca.faculty@psgtech.ac.in',
          batchOrRole: me?.isHod ? 'HOD' : 'Faculty Mentor',
          avatarUrl: me?.avatarUrl,
          portalType: 'faculty',
        }}
        onLogout={handleSignOut}
      />

      {/* Main Content Area */}
      <main className="flex-1 flex flex-col min-w-0 h-full overflow-hidden bg-[#FBF6EE]">
        {/* Top Header */}
        <header className="h-[76px] bg-white/80 backdrop-blur-md border-b border-[#EFE9E0] flex items-center justify-between px-6 lg:px-8 shrink-0 relative z-30 transition-colors">
          <div>
            <h1 className="text-base font-black text-[#1A1A1A] leading-tight">
              Faculty Mentorship & Governance Console
            </h1>
            <p className="text-[10px] font-bold text-[#8C877E] uppercase tracking-wider">
              PSG College of Technology · MCA Department
            </p>
          </div>

          <div className="flex items-center gap-2.5">
            <DiceBearAvatar
              name={me?.name || 'Faculty Member'}
              avatarUrl={me?.avatarUrl}
              size={36}
            />
            <div className="hidden sm:block text-left">
              <p className="text-xs font-black text-[#1A1A1A] leading-tight truncate max-w-[140px]">
                {me?.name || 'Faculty Member'}
              </p>
              <p className="text-[10px] font-semibold text-[#8C877E] truncate">
                {me?.isHod ? 'Head of Department' : 'Mentor'}
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
