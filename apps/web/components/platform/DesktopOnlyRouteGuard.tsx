'use client';

import React, { useState, useEffect } from 'react';
import { usePathname } from 'next/navigation';
import Link from 'next/link';
import { Monitor, Copy, Check, AlertTriangle, ArrowLeft } from 'lucide-react';

export default function DesktopOnlyRouteGuard() {
  const pathname = usePathname();
  const [isMobile, setIsMobile] = useState(false);
  const [copied, setCopied] = useState(false);

  useEffect(() => {
    // Check if device is mobile or viewport is below desktop width (< 1024px)
    const checkMobile = () => {
      if (typeof window === 'undefined') return;
      const isNarrow = window.innerWidth < 1024;
      const ua = (navigator.userAgent || navigator.vendor || (window as any).opera || '').toLowerCase();
      const isMobileUA = /android|webos|iphone|ipad|ipod|blackberry|iemobile|opera mini/i.test(ua);
      const isTouch = navigator.maxTouchPoints > 1 && (isNarrow || isMobileUA);

      setIsMobile(isNarrow || isMobileUA || isTouch);
    };

    checkMobile();
    window.addEventListener('resize', checkMobile);
    return () => window.removeEventListener('resize', checkMobile);
  }, []);

  // Root landing page "/" is always accessible on mobile
  if (!pathname || pathname === '/' || !isMobile) {
    return null;
  }

  const handleCopyLink = async () => {
    try {
      await navigator.clipboard.writeText(window.location.href);
      setCopied(true);
      setTimeout(() => setCopied(false), 2500);
    } catch {
      const input = document.createElement('input');
      input.value = window.location.href;
      document.body.appendChild(input);
      input.select();
      document.execCommand('copy');
      document.body.removeChild(input);
      setCopied(true);
      setTimeout(() => setCopied(false), 2500);
    }
  };

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-label="Desktop browser required"
      className="fixed inset-0 z-[999999] bg-[#FBF6EE] flex items-center justify-center p-6 overflow-y-auto selection:bg-[#FF6B4A]/20"
    >
      <div className="w-full max-w-[420px] bg-white rounded-3xl border border-[#EFE9E0] shadow-xl p-7 text-center my-auto space-y-5">
        {/* Official Mascot Logo */}
        <div className="flex justify-center">
          <img
            src="/logo.png"
            alt="PSGMX Mascot"
            className="w-28 h-28 object-contain drop-shadow-md select-none"
          />
        </div>

        {/* Badge */}
        <div>
          <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-[11px] font-black uppercase tracking-wider bg-[#FF6B4A]/10 text-[#FF6B4A] border border-[#FF6B4A]/20">
            <Monitor className="w-3.5 h-3.5" />
            Desktop Workstation Only
          </span>
        </div>

        {/* Title & Description */}
        <div className="space-y-2">
          <h1 className="text-xl sm:text-2xl font-black text-[#1A1A1A] tracking-tight leading-tight">
            Please Open on Your Laptop or PC
          </h1>
          <p className="text-xs sm:text-sm text-[#706E6B] leading-relaxed">
            PSGMX is engineered for desktop screens with code sandboxes, proctored mock exams, and analytics requiring a full display and keyboard.
          </p>
        </div>

        {/* Strict Warning: Do NOT use Desktop Site */}
        <div className="bg-[#FFF8F0] border border-[#FFE2BE] rounded-2xl p-4 text-left flex items-start gap-3">
          <AlertTriangle className="w-5 h-5 text-[#E4572E] shrink-0 mt-0.5" />
          <div className="text-xs leading-relaxed text-[#733B22]">
            <p className="font-extrabold uppercase tracking-wide text-[#E4572E] mb-0.5">
              Do NOT enable &quot;Desktop site&quot;
            </p>
            <p>
              Enabling &quot;Desktop site&quot; in mobile Chrome or Safari distorts placement views and disrupts timers. Please open your laptop or PC browser directly.
            </p>
          </div>
        </div>

        {/* Action Buttons */}
        <div className="space-y-2.5 pt-1">
          <button
            onClick={handleCopyLink}
            className="w-full py-3.5 px-5 rounded-2xl bg-[#FF6B4A] hover:bg-[#E4572E] active:scale-[0.98] text-white font-bold text-sm shadow-md shadow-[#FF6B4A]/25 transition-all flex items-center justify-center gap-2"
          >
            {copied ? (
              <>
                <Check className="w-4 h-4 text-white" />
                Copied! Paste in PC browser
              </>
            ) : (
              <>
                <Copy className="w-4 h-4" />
                Copy Portal Link
              </>
            )}
          </button>

          <Link
            href="/"
            className="w-full py-3 px-5 rounded-2xl bg-[#FAF6F0] hover:bg-[#F3EDE2] active:scale-[0.98] text-[#55514B] font-bold text-xs border border-[#EFE9E0] transition-all flex items-center justify-center gap-2"
          >
            <ArrowLeft className="w-3.5 h-3.5" />
            Back to Mobile Home
          </Link>
        </div>
      </div>
    </div>
  );
}
