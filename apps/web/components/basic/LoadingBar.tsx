'use client';

import React, { useEffect, useRef, useState } from 'react';
import { usePathname } from 'next/navigation';
import { motion, AnimatePresence } from 'framer-motion';

export default function LoadingBar() {
  const pathname = usePathname();
  const [loading, setLoading] = useState(false);

  const lastPathnameRef = useRef(pathname);

  useEffect(() => {
    const hasPathChanged = pathname !== lastPathnameRef.current;
    lastPathnameRef.current = pathname;

    if (!hasPathChanged) return;

    const startTimer = setTimeout(() => setLoading(true), 0);
    const endTimer = setTimeout(() => setLoading(false), 600);

    return () => {
      clearTimeout(startTimer);
      clearTimeout(endTimer);
    };
  }, [pathname]);

  return (
    <AnimatePresence>
      {loading && (
        <motion.div
          initial={{ scaleX: 0, opacity: 1 }}
          animate={{ scaleX: 1, opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{ 
            duration: 0.6, 
            ease: "circOut"
          }}
          style={{ originX: 0 }}
          className="fixed top-0 left-0 right-0 h-[3px] bg-linear-to-r from-[#6C3DFF] via-[#ef4444] to-[#f87171] z-9999 shadow-[0_0_10px_rgba(214,32,39,0.5)]"
        />
      )}
    </AnimatePresence>
  );
}
