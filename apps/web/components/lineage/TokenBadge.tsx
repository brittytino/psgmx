'use client';

import React from 'react';
import { motion } from 'framer-motion';

export function TokenBadge({ token, className = '' }: { token: string; className?: string }) {
  const isAlumni = parseInt(token.substring(0, 2)) < 24;

  return (
    <motion.div
      whileHover={{ scale: 1.05, y: -2 }}
      className={`px-3 py-1 rounded-full text-xs font-bold tracking-wider inline-flex items-center gap-1.5 shadow-lg border backdrop-blur-md ${
        isAlumni
          ? 'bg-primary-purple/20 text-white border-primary-purple/40 shadow-primary-purple/20'
          : 'bg-electric-blue/10 text-electric-blue border-electric-blue/30 shadow-electric-blue/10'
      } ${className}`}
    >
      <div className={`w-1.5 h-1.5 rounded-full animate-pulse-slow ${isAlumni ? 'bg-primary-purple' : 'bg-electric-blue'}`} />
      {token}
    </motion.div>
  );
}
