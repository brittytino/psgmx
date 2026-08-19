'use client';

const PALETTE = ['#C4B5FD', '#93C5FD', '#FCA5A5', '#FCD34D', '#6EE7B7', '#F9A8D4', '#A5B4FC', '#FDBA74'];

function colorForName(name: string): string {
  let hash = 0;
  for (let i = 0; i < name.length; i++) {
    hash = name.charCodeAt(i) + ((hash << 5) - hash);
  }
  return PALETTE[Math.abs(hash) % PALETTE.length];
}

function initialsForName(name: string): string {
  const parts = name.trim().split(/\s+/).filter(Boolean);
  if (parts.length === 0) return '?';
  if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase();
  return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
}

/**
 * Renders initials on a colored circle entirely client-side — no external
 * network call, so no student/faculty name is ever sent to a third-party CDN.
 */
export function InitialsAvatar({
  name,
  size = 32,
  className = '',
}: {
  name: string;
  size?: number;
  className?: string;
}) {
  return (
    <div
      className={`rounded-full flex items-center justify-center text-white font-bold shrink-0 ${className}`}
      style={{ width: size, height: size, backgroundColor: colorForName(name || '?'), fontSize: Math.round(size * 0.4) }}
      aria-label={name || 'Avatar'}
      role="img"
    >
      {initialsForName(name || '?')}
    </div>
  );
}
