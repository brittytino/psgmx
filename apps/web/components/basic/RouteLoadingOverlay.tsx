'use client';

import React, { useEffect, useRef, useState } from 'react';
import { usePathname } from 'next/navigation';
import { AnimatePresence, motion } from 'framer-motion';
import FullScreenLoader from './FullScreenLoader';

const DURATION_MS = 400;

/**
 * Shows a full-screen loading overlay briefly whenever the route changes
 * (pathname or search params). This gives feedback on sidebar clicks,
 * page reloads, and navigations between major areas.
 */
export default function RouteLoadingOverlay() {
  const pathname = usePathname();
  const [visible, setVisible] = useState(false);
  const lastPathnameRef = useRef(pathname);
  const firstRunRef = useRef(true);

  useEffect(() => {
    const hasPathChanged = pathname !== lastPathnameRef.current;
    lastPathnameRef.current = pathname;

    if (firstRunRef.current) {
      firstRunRef.current = false;
      return;
    }

    if (!hasPathChanged) return;

    const startTimer = setTimeout(() => setVisible(true), 0);
    const timer = setTimeout(() => setVisible(false), DURATION_MS);
    return () => {
      clearTimeout(startTimer);
      clearTimeout(timer);
    };
  }, [pathname]);

  return (
    <AnimatePresence>
      {visible && (
        <motion.div
          key="route-loader"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{ duration: 0.25, ease: 'easeOut' }}
          className="fixed inset-0 z-9975"
        >
          <FullScreenLoader message="Preparing your workspace..." />
        </motion.div>
      )}
    </AnimatePresence>
  );
}
