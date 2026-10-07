// DiceBear avatar generator matching mobile app specifications
// API: https://api.dicebear.com/10.x/clay/svg?seed=Milo

export function getDiceBearAvatar(seedOrName?: string | null): string {
  const seed = seedOrName && seedOrName.trim() ? seedOrName.trim() : 'Milo'
  return `https://api.dicebear.com/10.x/clay/svg?seed=${encodeURIComponent(seed)}`
}

export function getUserAvatarUrl(user?: {
  avatar_url?: string | null
  avatarUrl?: string | null
  name?: string | null
  reg_no?: string | null
  regNo?: string | null
  email?: string | null
} | null): string {
  const custom = user?.avatar_url || user?.avatarUrl
  if (custom && typeof custom === 'string' && (custom.startsWith('http') || custom.startsWith('data:'))) {
    return custom.trim()
  }
  const seed = user?.name || user?.reg_no || user?.regNo || user?.email || 'Milo'
  return getDiceBearAvatar(seed)
}
