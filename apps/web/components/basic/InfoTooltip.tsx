'use client';

import React, { useState, useRef } from 'react';
import { Info } from 'lucide-react';

interface InfoTooltipProps {
  text: string;
  side?: 'top' | 'bottom' | 'left' | 'right';
}

export default function InfoTooltip({ text, side = 'top' }: InfoTooltipProps) {
  const [visible, setVisible] = useState(false);
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  const show = () => {
    if (timerRef.current) clearTimeout(timerRef.current);
    setVisible(true);
  };

  const hide = () => {
    timerRef.current = setTimeout(() => setVisible(false), 120);
  };

  const positionClasses: Record<string, string> = {
    top: 'bottom-full left-1/2 -translate-x-1/2 mb-2',
    bottom: 'top-full left-1/2 -translate-x-1/2 mt-2',
    left: 'right-full top-1/2 -translate-y-1/2 mr-2',
    right: 'left-full top-1/2 -translate-y-1/2 ml-2',
  };

  return (
    <span
      className="relative inline-flex items-center cursor-help"
      onMouseEnter={show}
      onMouseLeave={hide}
      onFocus={show}
      onBlur={hide}
      onClick={() => setVisible((v) => !v)}
      tabIndex={0}
      role="button"
      aria-label="More information"
    >
      <Info className="w-4 h-4 text-gray-400 hover:text-[#6C3DFF] transition-colors flex-shrink-0" />

      {visible && (
        <span
          className={`absolute z-50 w-72 bg-zinc-900 text-white text-xs font-medium leading-relaxed px-4 py-2.5 rounded-xl shadow-2xl pointer-events-none ${positionClasses[side]}`}
        >
          {text}
          <span
            className={`absolute w-2 h-2 bg-zinc-900 rotate-45 ${
              side === 'top' ? 'top-full left-1/2 -translate-x-1/2 -translate-y-1/2' :
              side === 'bottom' ? 'bottom-full left-1/2 -translate-x-1/2 translate-y-1/2 rotate-[225deg]' :
              side === 'left' ? 'left-full top-1/2 -translate-x-1/2 -translate-y-1/2' :
              'right-full top-1/2 translate-x-1/2 -translate-y-1/2'
            }`}
          />
        </span>
      )}
    </span>
  );
}
