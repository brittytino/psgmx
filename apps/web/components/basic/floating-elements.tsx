'use client';

import React from 'react';

interface FloatingElementsProps {
  mode?: 'login' | 'dashboard';
  density?: 'low' | 'high';
}

export default function FloatingElements({ mode = 'login' }: FloatingElementsProps) {
  if (mode === 'dashboard') {
    return (
      <div className="absolute inset-0 pointer-events-none overflow-hidden z-0 opacity-30">
        <div className="absolute inset-0 bg-[linear-gradient(to_right,#80808008_1px,transparent_1px),linear-gradient(to_bottom,#80808008_1px,transparent_1px)] bg-[size:40px_40px]" />
      </div>
    );
  }

  return (
    <div className="absolute inset-0 pointer-events-none overflow-hidden z-0">
      <div className="absolute top-[-10%] left-[-10%] w-[40%] h-[40%] bg-red-100/30 rounded-full blur-[100px] animate-blob" />
      <div className="absolute bottom-[-10%] right-[-10%] w-[40%] h-[40%] bg-zinc-200/40 rounded-full blur-[100px] animate-blob [animation-delay:2s]" />
      <div className="absolute top-[20%] right-[10%] w-[30%] h-[30%] bg-red-50/50 rounded-full blur-[80px] animate-blob [animation-delay:5s]" />
      <div className="absolute inset-0 bg-[linear-gradient(to_right,#80808008_1px,transparent_1px),linear-gradient(to_bottom,#80808008_1px,transparent_1px)] bg-[size:40px_40px]" />
    </div>
  );
}
