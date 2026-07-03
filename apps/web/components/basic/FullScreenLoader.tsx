import React from "react";
import Image from "next/image";

interface FullScreenLoaderProps {
  message?: string;
}

/**
 * Branded full-screen loading overlay used across the app.
 * Pure presentational component (no hooks) so it can be rendered
 * from both client and server components.
 */
export function FullScreenLoader({ message }: FullScreenLoaderProps) {
  return (
    <div
      className="fixed inset-0 z-[9980] flex items-center justify-center bg-slate-950/70 backdrop-blur-sm"
      aria-busy="true"
      aria-live="polite"
      role="status"
    >
      <div className="flex flex-col items-center gap-4">
        <div className="relative">
          <div className="h-16 w-16 rounded-full border-4 border-slate-600 border-t-[#6C3DFF] animate-spin" />
        </div>
        <Image src="/logo.webp" alt="psgmx" width={120} height={40} style={{ width: 'auto', height: 'auto', objectFit: 'contain', filter: 'brightness(0) invert(1)' }} priority />
        <p className="max-w-xs text-center text-[11px] font-semibold uppercase tracking-[0.16em] text-slate-100/80">
          {message ?? "Loading, please wait..."}
        </p>
      </div>
    </div>
  );
}

export default FullScreenLoader;
