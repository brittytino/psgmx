'use client';

import React from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { LayoutDashboard, Users, UserCog, Library, DatabaseZap, GraduationCap, HeartPulse, ShieldCheck } from 'lucide-react';

export default function SuperAdminLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();

  const navLinks = [
    { name: 'Dashboard', href: '/super-admin', icon: LayoutDashboard },
    { name: 'Faculty', href: '/super-admin/faculty', icon: UserCog },
    { name: 'Students', href: '/super-admin/students', icon: Users },
    { name: 'Batches', href: '/super-admin/batches', icon: GraduationCap },
    { name: 'Governance', href: '/super-admin/governance', icon: ShieldCheck },
    { name: 'Knowledge Brain', href: '/super-admin/knowledge-brain', icon: Library },
    { name: 'AI Senior', href: '/super-admin/ai-senior', icon: DatabaseZap },
    { name: 'System Health', href: '/super-admin/health', icon: HeartPulse },
  ];

  return (
    <div className="min-h-screen bg-page-bg text-text-main flex">
      {/* Sidebar Navigation */}
      <aside className="w-64 border-r border-border bg-black/20 hidden md:flex flex-col">
        <div className="p-6 border-b border-border">
          <h1 className="text-xl font-bold text-electric-blue flex items-center gap-2">
            <DatabaseZap className="w-6 h-6" />
            Super Admin
          </h1>
        </div>
        <nav className="p-4 flex-1 space-y-2">
          {navLinks.map((link) => {
            const isActive = pathname === link.href;
            const Icon = link.icon;
            return (
              <Link
                key={link.name}
                href={link.href}
                className={`flex items-center gap-3 px-4 py-3 rounded-xl transition-colors font-medium ${
                  isActive 
                  ? 'bg-electric-blue/10 text-electric-blue' 
                  : 'text-text-muted hover:text-white hover:bg-white/5'
                }`}
              >
                <Icon className={`w-5 h-5 ${isActive ? 'text-electric-blue' : 'opacity-70'}`} />
                {link.name}
              </Link>
            );
          })}
        </nav>
        <div className="p-4 border-t border-border">
          <div className="text-xs text-text-muted">Logged in as Root</div>
        </div>
      </aside>

      {/* Main Content Area */}
      <main className="flex-1 flex flex-col h-screen overflow-hidden">
        {/* Mobile Header (minimal) */}
        <header className="md:hidden p-4 border-b border-border bg-page-bg flex items-center justify-between">
          <div className="font-bold text-electric-blue">Super Admin</div>
        </header>
        
        <div className="flex-1 overflow-y-auto p-4 md:p-8">
          {children}
        </div>
      </main>
    </div>
  );
}
