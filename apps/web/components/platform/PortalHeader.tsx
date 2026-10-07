'use client';

import React from 'react';
import { Bell, Search, Sparkles } from 'lucide-react';
import DiceBearAvatar from '@/components/basic/DiceBearAvatar';

interface PortalHeaderProps {
  title?: string;
  subtitle?: string;
  onOpenSearch?: () => void;
  onOpenNotifications?: () => void;
  unreadCount?: number;
  user?: {
    name: string;
    roleOrReg?: string;
    avatarUrl?: string | null;
  };
  children?: React.ReactNode;
}

export default function PortalHeader({
  title,
  subtitle,
  onOpenSearch,
  onOpenNotifications,
  unreadCount = 0,
  user,
  children,
}: PortalHeaderProps) {

  return (
    <header className="h-[72px] bg-white/80 backdrop-blur-md border-b border-[#EFE9E0] flex items-center justify-between px-6 lg:px-8 shrink-0 relative z-30 transition-colors">
      {/* Title / Breadcrumb */}
      <div className="flex items-center gap-3 min-w-0">
        <div>
          {title && (
            <h1 className="text-base font-black text-[#1A1A1A] leading-tight truncate">
              {title}
            </h1>
          )}
          {subtitle && (
            <p className="text-[11px] font-bold text-[#8C877E] uppercase tracking-wider truncate">
              {subtitle}
            </p>
          )}
        </div>
      </div>

      {/* Middle Custom Content (e.g. Search Bar) */}
      <div className="flex-1 max-w-xl mx-4 hidden md:block">
        {children}
      </div>

      {/* Right Controls */}
      <div className="flex items-center gap-3 shrink-0">
        {/* Quick Search Button (mobile/tablet or header click) */}
        {onOpenSearch && (
          <button
            type="button"
            onClick={onOpenSearch}
            aria-label="Open search"
            className="w-10 h-10 md:hidden rounded-xl bg-[#FAF6F0] border border-[#EFE9E0] text-[#706E6B] hover:text-[#1A1A1A] flex items-center justify-center transition-colors"
          >
            <Search className="w-4 h-4" />
          </button>
        )}

        {/* Notifications Bell */}
        {onOpenNotifications && (
          <button
            type="button"
            onClick={onOpenNotifications}
            aria-label="Notifications"
            className="relative w-10 h-10 rounded-xl bg-[#FAF6F0] hover:bg-[#F5EFE6] border border-[#EFE9E0] text-[#706E6B] hover:text-[#1A1A1A] flex items-center justify-center transition-all shadow-2xs"
          >
            <Bell className="w-4 h-4" />
            {unreadCount > 0 && (
              <span className="absolute -top-1 -right-1 flex min-h-4 min-w-4 items-center justify-center rounded-full bg-[#FF6B4A] px-1 text-[10px] font-black text-white shadow-xs">
                {unreadCount > 99 ? '99+' : unreadCount}
              </span>
            )}
          </button>
        )}

        {/* User Mini Avatar */}
        {user && (
          <div className="flex items-center gap-2 pl-1">
            <DiceBearAvatar
              name={user.name}
              avatarUrl={user.avatarUrl}
              size={36}
            />
          </div>
        )}
      </div>
    </header>
  );
}
