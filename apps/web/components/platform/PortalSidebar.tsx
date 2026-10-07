'use client';

import React, { useState, useEffect, useRef } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { motion, AnimatePresence } from 'framer-motion';
import {
  PanelLeftClose,
  PanelLeftOpen,
  Pin,
  PinOff,
  Search,
  Settings,
  HelpCircle,
  LogOut,
  ChevronRight,
  ShieldCheck,
  GraduationCap,
  type LucideIcon,
} from 'lucide-react';
import DiceBearAvatar from '@/components/basic/DiceBearAvatar';

export interface NavLinkItem {
  name: string;
  href: string;
  icon: LucideIcon;
  badge?: number | string;
  shortcut?: string;
}

export interface NavGroup {
  groupTitle?: string;
  items: NavLinkItem[];
}

export interface PortalSidebarProps {
  portalTitle: string;
  portalSubtitle: string;
  logoSrc?: string;
  navGroups: NavGroup[];
  user: {
    name: string;
    emailOrReg: string;
    batchOrRole?: string;
    avatarUrl?: string | null;
    isPlacementRep?: boolean;
    portalType?: 'student' | 'placement-rep' | 'faculty' | 'alumni';
  };
  onOpenSearch?: () => void;
  onLogout?: () => void;
}

export default function PortalSidebar({
  portalTitle,
  portalSubtitle,
  logoSrc = '/logo.png',
  navGroups,
  user,
  onOpenSearch,
  onLogout,
}: PortalSidebarProps) {
  const pathname = usePathname();
  const [isPinned, setIsPinned] = useState(true);
  const [isHovered, setIsHovered] = useState(false);
  const [hoveredLink, setHoveredLink] = useState<{ name: string; top: number } | null>(null);
  const [profileMenuOpen, setProfileMenuOpen] = useState(false);
  const hoverTimeoutRef = useRef<NodeJS.Timeout | null>(null);

  // Restore pinned state from localStorage
  useEffect(() => {
    try {
      const saved = localStorage.getItem('psgmx_sidebar_pinned');
      if (saved !== null) {
        setIsPinned(saved === 'true');
      }
    } catch {
      // ignore
    }
  }, []);

  const togglePin = () => {
    setIsPinned((prev) => {
      const next = !prev;
      try {
        localStorage.setItem('psgmx_sidebar_pinned', String(next));
      } catch {
        // ignore
      }
      return next;
    });
  };

  const handleMouseEnter = () => {
    if (hoverTimeoutRef.current) clearTimeout(hoverTimeoutRef.current);
    setIsHovered(true);
  };

  const handleMouseLeave = () => {
    hoverTimeoutRef.current = setTimeout(() => {
      setIsHovered(false);
      setHoveredLink(null);
    }, 150);
  };

  const isExpanded = isPinned || isHovered;

  const triggerSearch = () => {
    if (onOpenSearch) {
      onOpenSearch();
    } else {
      window.dispatchEvent(new CustomEvent('open-global-search'));
    }
  };

  return (
    <>
      <motion.aside
        animate={{ width: isExpanded ? 260 : 76 }}
        transition={{ type: 'spring', stiffness: 350, damping: 32 }}
        onMouseEnter={handleMouseEnter}
        onMouseLeave={handleMouseLeave}
        className="h-full bg-white border-r border-[#EFE9E0] flex flex-col shrink-0 relative z-40 select-none shadow-[2px_0_12px_rgba(34,31,26,0.02)] transition-colors"
      >
        {/* Top Header / Workspace Info */}
        <div className="h-[76px] px-3.5 flex items-center justify-between border-b border-[#F5EFE6] shrink-0">
          <Link
            href={user.portalType === 'placement-rep' ? '/placement-rep' : '/student'}
            className="flex items-center gap-3 overflow-hidden group cursor-pointer"
          >
            <div className="w-10 h-10 rounded-xl bg-[#FAF5EE] border border-[#EAE3D6] flex items-center justify-center shrink-0 p-1 group-hover:scale-105 transition-transform shadow-2xs">
              <img
                src={logoSrc}
                alt="PSGMX Mascot"
                className="w-full h-full object-contain"
              />
            </div>

            <AnimatePresence initial={false}>
              {isExpanded && (
                <motion.div
                  initial={{ opacity: 0, x: -8 }}
                  animate={{ opacity: 1, x: 0 }}
                  exit={{ opacity: 0, x: -8 }}
                  transition={{ duration: 0.15 }}
                  className="min-w-0"
                >
                  <h2 className="text-[14px] font-black text-[#1A1A1A] leading-tight truncate">
                    {portalTitle}
                  </h2>
                  <p className="text-[10px] font-bold text-[#8C877E] uppercase tracking-wider truncate mt-0.5">
                    {portalSubtitle}
                  </p>
                </motion.div>
              )}
            </AnimatePresence>
          </Link>

          {/* Pin / Collapse Toggle Button */}
          {isExpanded && (
            <button
              type="button"
              onClick={togglePin}
              aria-label={isPinned ? 'Unpin sidebar (hover to open)' : 'Pin sidebar open'}
              className="w-8 h-8 rounded-lg text-[#8C877E] hover:text-[#1A1A1A] hover:bg-[#F5EFE6] flex items-center justify-center transition-colors cursor-pointer"
              title={isPinned ? 'Unpin sidebar (auto-collapses, hover to peek)' : 'Pin sidebar open'}
            >
              {isPinned ? (
                <PanelLeftClose className="w-4 h-4" />
              ) : (
                <PinOff className="w-4 h-4 text-[#FF6B4A]" />
              )}
            </button>
          )}
        </div>

        {/* Collapsed Expand / Search Trigger */}
        {!isExpanded && (
          <div className="pt-2 px-2.5 flex flex-col items-center gap-1.5 shrink-0">
            <button
              type="button"
              onClick={togglePin}
              aria-label="Pin sidebar open"
              className="w-10 h-10 rounded-xl text-[#8C877E] hover:text-[#1A1A1A] hover:bg-[#FAF5EE] border border-transparent hover:border-[#EAE3D6] flex items-center justify-center transition-all cursor-pointer"
              title="Pin sidebar open"
            >
              <PanelLeftOpen className="w-4 h-4" />
            </button>
            <button
              type="button"
              onClick={triggerSearch}
              aria-label="Search (⌘K)"
              className="w-10 h-10 rounded-xl text-[#8C877E] hover:text-[#FF6B4A] hover:bg-[#FAF5EE] border border-[#EFE9E0] flex items-center justify-center transition-all cursor-pointer shadow-2xs"
              title="Search Knowledge Brain & Tasks (Ctrl+K)"
            >
              <Search className="w-4 h-4" />
            </button>
          </div>
        )}

        {/* Quick Search Bar Trigger (in Expanded Mode) */}
        {isExpanded && (
          <div className="px-3 pt-3 pb-2 shrink-0">
            <button
              type="button"
              onClick={triggerSearch}
              className="w-full h-9 px-3 rounded-xl bg-[#FAF6F0] hover:bg-[#F5EFE6] border border-[#EFE9E0] hover:border-[#E2D8C9] flex items-center justify-between text-xs text-[#8C877E] hover:text-[#1A1A1A] transition-all group cursor-pointer"
            >
              <span className="flex items-center gap-2 truncate font-medium">
                <Search className="w-3.5 h-3.5 text-[#A39E94] group-hover:text-[#FF6B4A] shrink-0 transition-colors" />
                <span className="text-[12px]">Quick search…</span>
              </span>
              <kbd className="px-1.5 py-0.5 rounded text-[10px] font-mono font-semibold bg-white border border-[#EAE3D6] text-[#8C877E] shadow-2xs">
                ⌘K
              </kbd>
            </button>
          </div>
        )}

        {/* Navigation Groups Container */}
        <div className="flex-1 overflow-y-auto px-2.5 py-2 space-y-3.5 custom-scrollbar">
          {navGroups.map((group, groupIdx) => (
            <div key={group.groupTitle || groupIdx} className="space-y-1">
              {/* Group Title in Expanded Mode */}
              {isExpanded && group.groupTitle && (
                <div className="px-3 pt-2 pb-1 text-[10px] font-black uppercase tracking-wider text-[#A39E94]">
                  {group.groupTitle}
                </div>
              )}

              {/* Items */}
              {group.items.map((link) => {
                const isActive =
                  pathname === link.href ||
                  (link.href !== '/student' &&
                    link.href !== '/placement-rep' &&
                    pathname.startsWith(link.href));
                const Icon = link.icon;

                return (
                  <div key={link.href} className="relative group/link">
                    <Link
                      href={link.href}
                      onMouseEnter={(e) => {
                        if (!isExpanded) {
                          const rect = e.currentTarget.getBoundingClientRect();
                          setHoveredLink({
                            name: link.name,
                            top: rect.top + rect.height / 2,
                          });
                        }
                      }}
                      onMouseLeave={() => setHoveredLink(null)}
                      className={`flex items-center rounded-xl transition-all duration-150 cursor-pointer ${
                        !isExpanded
                          ? 'w-11 h-10 mx-auto justify-center'
                          : 'w-full px-3 py-2.5 justify-between'
                      } ${
                        isActive
                          ? 'bg-[#F3ECE2] text-[#1A1A1A] font-bold border border-[#E5DACD] shadow-2xs'
                          : 'text-[#6B665E] hover:bg-[#FAF6F0] hover:text-[#1A1A1A] font-semibold border border-transparent'
                      }`}
                    >
                      <div className="flex items-center gap-3 min-w-0">
                        <Icon
                          className={`w-4 h-4 shrink-0 transition-colors ${
                            isActive
                              ? 'text-[#FF6B4A]'
                              : 'text-[#8C877E] group-hover/link:text-[#1A1A1A]'
                          }`}
                        />
                        {isExpanded && (
                          <span className="text-[13px] truncate">
                            {link.name}
                          </span>
                        )}
                      </div>

                      {/* Badge / Shortcut in Expanded Mode */}
                      {isExpanded && (
                        <div className="flex items-center gap-1.5 shrink-0">
                          {link.badge !== undefined && (
                            <span className="px-1.5 py-0.5 text-[10px] font-black rounded-full bg-[#FF6B4A]/10 text-[#FF6B4A] border border-[#FF6B4A]/20">
                              {link.badge}
                            </span>
                          )}
                          {link.shortcut && (
                            <span className="text-[10px] font-mono text-[#A39E94]">
                              {link.shortcut}
                            </span>
                          )}
                        </div>
                      )}
                    </Link>
                  </div>
                );
              })}
            </div>
          ))}

          {/* Portal Switcher Shortcut if Placement Rep */}
          {user.isPlacementRep && (
            <div className="pt-2 border-t border-[#F5EFE6]">
              {user.portalType === 'student' ? (
                <Link
                  href="/placement-rep"
                  className={`flex items-center rounded-xl text-violet-700 bg-violet-50/70 hover:bg-violet-100/70 border border-violet-200/60 font-bold transition-all cursor-pointer ${
                    !isExpanded
                      ? 'w-11 h-10 mx-auto justify-center'
                      : 'px-3 py-2.5 justify-between text-xs'
                  }`}
                  title="Switch to PR Command Center"
                >
                  <div className="flex items-center gap-2.5">
                    <ShieldCheck className="w-4 h-4 text-violet-600 shrink-0" />
                    {isExpanded && <span>PR Command Center</span>}
                  </div>
                  {isExpanded && <ChevronRight className="w-3.5 h-3.5 text-violet-400" />}
                </Link>
              ) : (
                <Link
                  href="/student"
                  className={`flex items-center rounded-xl text-emerald-800 bg-emerald-50/70 hover:bg-emerald-100/70 border border-emerald-200/60 font-bold transition-all cursor-pointer ${
                    !isExpanded
                      ? 'w-11 h-10 mx-auto justify-center'
                      : 'px-3 py-2.5 justify-between text-xs'
                  }`}
                  title="Switch to Student Companion"
                >
                  <div className="flex items-center gap-2.5">
                    <GraduationCap className="w-4 h-4 text-emerald-600 shrink-0" />
                    {isExpanded && <span>Student Companion</span>}
                  </div>
                  {isExpanded && <ChevronRight className="w-3.5 h-3.5 text-emerald-400" />}
                </Link>
              )}
            </div>
          )}
        </div>

        {/* Bottom Section: User Profile Pill with DiceBear Avatar */}
        <div className="p-3 border-t border-[#F5EFE6] bg-[#FCFAF7] shrink-0 space-y-2 relative">
          <div className="relative">
            <button
              type="button"
              onClick={() => setProfileMenuOpen((prev) => !prev)}
              aria-expanded={profileMenuOpen}
              className={`w-full rounded-2xl border transition-all duration-150 flex items-center cursor-pointer ${
                !isExpanded
                  ? 'h-11 justify-center border-transparent hover:border-[#EFE9E0] hover:bg-[#F5EFE6]'
                  : 'p-2 justify-between border-[#EFE9E0] hover:border-[#E2D8C9] bg-white hover:bg-[#FAF6F0] shadow-2xs'
              }`}
            >
              <div className="flex items-center gap-2.5 min-w-0">
                <DiceBearAvatar
                  name={user.name}
                  avatarUrl={user.avatarUrl}
                  size={32}
                  className="rounded-xl shadow-2xs shrink-0"
                />
                {isExpanded && (
                  <div className="min-w-0 text-left">
                    <p className="text-[12px] font-black text-[#1A1A1A] truncate leading-tight">
                      {user.name}
                    </p>
                    <p className="text-[10px] font-semibold text-[#8C877E] truncate">
                      {user.emailOrReg || user.batchOrRole || 'MCA'}
                    </p>
                  </div>
                )}
              </div>

              {isExpanded && (
                <div className="text-[#8C877E] shrink-0 pr-1">
                  <motion.div animate={{ rotate: profileMenuOpen ? 180 : 0 }}>
                    <ChevronRight className="w-3.5 h-3.5 rotate-90" />
                  </motion.div>
                </div>
              )}
            </button>

            {/* Profile Floating Card Menu */}
            <AnimatePresence>
              {profileMenuOpen && (
                <>
                  <div
                    className="fixed inset-0 z-50 cursor-default"
                    onClick={() => setProfileMenuOpen(false)}
                  />
                  <motion.div
                    initial={{ opacity: 0, y: 8, scale: 0.96 }}
                    animate={{ opacity: 1, y: 0, scale: 1 }}
                    exit={{ opacity: 0, y: 8, scale: 0.96 }}
                    transition={{ duration: 0.15 }}
                    className={`fixed z-50 bg-white rounded-2xl border border-[#EAE3D6] shadow-xl p-2 w-64 overflow-hidden text-left ${
                      !isExpanded
                        ? 'left-[86px] bottom-4'
                        : 'left-4 bottom-[74px]'
                    }`}
                  >
                    {/* Header with user info and Clay Avatar */}
                    <div className="p-3 border-b border-[#F5EFE6] flex items-center gap-3">
                      <DiceBearAvatar
                        name={user.name}
                        avatarUrl={user.avatarUrl}
                        size={40}
                        className="rounded-xl shadow-2xs"
                      />
                      <div className="min-w-0">
                        <p className="text-xs font-bold text-[#1A1A1A] truncate">{user.name}</p>
                        <p className="text-[11px] text-[#8C877E] truncate">{user.emailOrReg}</p>
                        {user.batchOrRole && (
                          <span className="inline-block mt-0.5 px-1.5 py-0.2 rounded text-[9px] font-bold bg-[#FAF5EE] text-[#8C877E] border border-[#EAE3D6]">
                            {user.batchOrRole}
                          </span>
                        )}
                      </div>
                    </div>

                    {/* Menu links */}
                    <div className="py-1 text-xs font-medium space-y-0.5">
                      {user.isPlacementRep && (
                        <Link
                          href={user.portalType === 'placement-rep' ? '/student' : '/placement-rep'}
                          onClick={() => setProfileMenuOpen(false)}
                          className="flex items-center gap-2.5 px-3 py-2 rounded-xl text-violet-700 hover:bg-violet-50 font-bold transition-colors cursor-pointer"
                        >
                          <ShieldCheck className="w-4 h-4 text-violet-600" />
                          <span>
                            {user.portalType === 'placement-rep' ? 'Student View' : 'PR Console'}
                          </span>
                        </Link>
                      )}

                      <Link
                        href="/student/settings"
                        onClick={() => setProfileMenuOpen(false)}
                        className="flex items-center gap-2.5 px-3 py-2 rounded-xl text-[#55514B] hover:bg-[#FAF6F0] hover:text-[#1A1A1A] transition-colors cursor-pointer"
                      >
                        <Settings className="w-4 h-4 text-[#8C877E]" />
                        <span>Account Settings</span>
                      </Link>

                      <Link
                        href="/student/knowledge-brain"
                        onClick={() => setProfileMenuOpen(false)}
                        className="flex items-center gap-2.5 px-3 py-2 rounded-xl text-[#55514B] hover:bg-[#FAF6F0] hover:text-[#1A1A1A] transition-colors cursor-pointer"
                      >
                        <HelpCircle className="w-4 h-4 text-[#8C877E]" />
                        <span>Help & Knowledge Brain</span>
                      </Link>

                      <div className="h-px bg-[#F5EFE6] my-1" />

                      {onLogout && (
                        <button
                          type="button"
                          onClick={() => {
                            setProfileMenuOpen(false);
                            onLogout();
                          }}
                          className="w-full flex items-center gap-2.5 px-3 py-2 rounded-xl text-red-600 hover:bg-red-50 font-bold transition-colors cursor-pointer"
                        >
                          <LogOut className="w-4 h-4 text-red-500" />
                          <span>Sign Out</span>
                        </button>
                      )}
                    </div>
                  </motion.div>
                </>
              )}
            </AnimatePresence>
          </div>
        </div>
      </motion.aside>

      {/* Floating Tooltips in Collapsed Mode */}
      <AnimatePresence>
        {!isExpanded && hoveredLink && (
          <motion.div
            initial={{ opacity: 0, x: -6 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -6 }}
            transition={{ duration: 0.12 }}
            style={{ top: hoveredLink.top }}
            className="fixed left-[86px] -translate-y-1/2 z-[9999] pointer-events-none"
          >
            <div className="px-3 py-1.5 rounded-lg bg-[#1F1E1C] text-white text-xs font-semibold shadow-lg whitespace-nowrap">
              {hoveredLink.name}
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </>
  );
}
