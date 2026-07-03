'use client';

import React, { createContext, useContext, useState, useEffect } from 'react';

export type ProgramType = 'PRI' | 'FRI';

interface Terminology {
  scoreName: string;
  programName: string;
  focus: string;
  readinessTerm: string;
  tooltip: {
    score: string;
    metrics: string;
  }
}

interface ProgramContextType {
  program: ProgramType;
  setProgram: (program: ProgramType) => void;
  terminology: Terminology;
}

const terminologyMap: Record<ProgramType, Terminology> = {
  FRI: {
    scoreName: 'Foundational Score',
    programName: 'FRI Program',
    focus: 'Foundational Learning',
    readinessTerm: 'Foundational Readiness',
    tooltip: {
      score: 'A measure of fundamental knowledge and core concepts.',
      metrics: 'Core metrics focusing on foundational understanding.'
    }
  },
  PRI: {
    scoreName: 'Professional Score',
    programName: 'PRI Program',
    focus: 'Professional Skills',
    readinessTerm: 'Career Readiness',
    tooltip: {
      score: 'A measure of industry-relevant skills and job readiness.',
      metrics: 'Advanced metrics focusing on professional competence.'
    }
  }
};

const ProgramContext = createContext<ProgramContextType | undefined>(undefined);

export function ProgramProvider({ children }: { children: React.ReactNode }) {
  const [program, setProgramState] = useState<ProgramType>('FRI');
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    const saved = localStorage.getItem('active_program') as ProgramType;
    if (saved === 'PRI' || saved === 'FRI') {
      setTimeout(() => setProgramState(saved), 0);
    }
    setTimeout(() => setMounted(true), 0);
  }, []);

  const setProgram = (newProgram: ProgramType) => {
    setProgramState(newProgram);
    localStorage.setItem('active_program', newProgram);
  };

  const value = {
    program,
    setProgram,
    terminology: terminologyMap[program]
  };

  if (!mounted) {
    return <>{children}</>;
  }

  return (
    <ProgramContext.Provider value={value}>
      {children}
    </ProgramContext.Provider>
  );
}

export function useProgram() {
  const context = useContext(ProgramContext);
  if (context === undefined) {
    throw new Error('useProgram must be used within a ProgramProvider');
  }
  return context;
}
