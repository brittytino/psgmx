'use client';

import React from 'react';
import DiceBearAvatar from './DiceBearAvatar';

/**
 * Universal profile avatar matching mobile app specifications.
 * Uses DiceBear Clay API: https://api.dicebear.com/10.x/clay/svg?seed=...
 * If user has custom avatar_url in DB, uses it. Falls back to name seed or 'Milo'.
 */
export function InitialsAvatar({
  name,
  avatarUrl,
  avatar_url,
  size = 32,
  className = '',
}: {
  name: string;
  avatarUrl?: string | null;
  avatar_url?: string | null;
  size?: number;
  className?: string;
}) {
  return (
    <DiceBearAvatar
      name={name}
      avatarUrl={avatarUrl || avatar_url}
      size={size}
      className={className}
    />
  );
}

export default InitialsAvatar;

