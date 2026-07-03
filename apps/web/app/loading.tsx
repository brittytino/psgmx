import React from 'react';
import FullScreenLoader from '@/components/basic/FullScreenLoader';

// Global App Router loading UI for initial page loads and
// server-side suspense boundaries.
export default function Loading() {
  return <FullScreenLoader message="Loading portal, please wait..." />;
}
