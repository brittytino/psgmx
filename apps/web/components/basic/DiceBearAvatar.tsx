'use client';

import React, { useState } from 'react';
import { getUserAvatarUrl, getDiceBearAvatar } from '@/lib/avatar';

interface DiceBearAvatarProps {
  seed?: string | null;
  name?: string | null;
  avatarUrl?: string | null;
  size?: number;
  className?: string;
  alt?: string;
}

export function DiceBearAvatar({
  seed,
  name,
  avatarUrl,
  size = 36,
  className = '',
  alt = 'Avatar',
}: DiceBearAvatarProps) {
  const [hasError, setHasError] = useState(false);

  const initialUrl = getUserAvatarUrl({
    avatarUrl,
    name: seed || name,
  });

  const finalSrc = hasError ? getDiceBearAvatar('Milo') : initialUrl;

  const hasCustomRounding = /rounded-(none|sm|md|lg|xl|2xl|3xl|full)/.test(className);
  const roundClass = hasCustomRounding ? '' : 'rounded-full';

  return (
    <div
      style={{ width: size, height: size }}
      className={`relative overflow-hidden shrink-0 bg-[#FAF5EE] border border-[#EAE3D6] shadow-2xs select-none flex items-center justify-center ${roundClass} ${className}`}
    >
      <img
        src={finalSrc}
        alt={alt}
        width={size}
        height={size}
        onError={() => setHasError(true)}
        className="w-full h-full object-cover"
        loading="lazy"
      />
    </div>
  );
}

export default DiceBearAvatar;
