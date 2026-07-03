'use client';

import React from 'react';
import { useProgram } from '@/lib/program-context';


export default function ProgramSwitcher({ isCollapsed = false }: { isCollapsed?: boolean }) {
  const { program, setProgram } = useProgram();

  return (
    <div className={`flex items-center gap-3 px-3 py-2 ${isCollapsed ? 'justify-center' : ''}`}>
      {!isCollapsed && <span className="text-[10px] font-black uppercase tracking-widest text-zinc-400">Program</span>}
      <div className="flex bg-zinc-100 rounded-lg p-1">
        <button
          onClick={() => setProgram('FRI')}
          className={`px-3 py-1 rounded-md text-[10px] font-black transition-all ${
            program === 'FRI' 
              ? 'bg-white text-[#6C3DFF] shadow-sm' 
              : 'text-zinc-500 hover:text-zinc-700'
          }`}
        >
          FRI
        </button>
        <button
          onClick={() => setProgram('PRI')}
          className={`px-3 py-1 rounded-md text-[10px] font-black transition-all ${
            program === 'PRI' 
              ? 'bg-white text-[#6C3DFF] shadow-sm' 
              : 'text-zinc-500 hover:text-zinc-700'
          }`}
        >
          PRI
        </button>
      </div>
    </div>
  );
}
