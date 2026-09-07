'use client'

import React, { useState, useEffect, useRef, useMemo, useCallback } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { motion, AnimatePresence } from 'framer-motion'
import {
  Search,
  X,
  BookOpen,
  Briefcase,
  Megaphone,
  Users,
  ArrowRight,
  Loader2,
  Sparkles,
  Command,
} from 'lucide-react'
import { createClient } from '@/lib/supabase/client'

interface SearchResultItem {
  id: string
  title: string
  subtitle: string
  type: 'article' | 'community' | 'announcement' | 'person'
  link: string
}

export function AlumniHeaderSearch() {
  const router = useRouter()
  const supabase = useMemo(() => createClient(), [])
  const [query, setQuery] = useState('')
  const [isOpen, setIsOpen] = useState(false)
  const [loading, setLoading] = useState(false)
  const [results, setResults] = useState<SearchResultItem[]>([])
  const containerRef = useRef<HTMLDivElement>(null)

  const performSearch = useCallback(
    async (searchTerm: string) => {
      const q = searchTerm.trim()
      if (!q) {
        setResults([])
        setLoading(false)
        return
      }

      setLoading(true)
      try {
        const [
          { data: articles },
          { data: communityPosts },
          { data: announcements },
          { data: users },
        ] = await Promise.all([
          supabase
            .from('knowledge_brain_articles')
            .select('id, title, summary, company_name')
            .eq('approval_status', 'approved')
            .or(`title.ilike.%${q}%,summary.ilike.%${q}%,content.ilike.%${q}%`)
            .limit(4),
          supabase
            .from('collaboration_posts')
            .select('id, title, post_type')
            .eq('is_active', true)
            .or(`title.ilike.%${q}%,description.ilike.%${q}%`)
            .limit(3),
          supabase
            .from('announcements')
            .select('id, title, is_priority')
            .or(`title.ilike.%${q}%,message.ilike.%${q}%`)
            .limit(3),
          supabase
            .from('users')
            .select('id, name, reg_no, current_role_title, current_company')
            .or(`name.ilike.%${q}%,reg_no.ilike.%${q}%,current_company.ilike.%${q}%`)
            .limit(3),
        ])

        const searchResults: SearchResultItem[] = [
          ...(articles || []).map((a) => ({
            id: `article-${a.id}`,
            title: a.title,
            subtitle: a.company_name ? `${a.company_name} · Knowledge Brain` : 'Knowledge Brain Article',
            type: 'article' as const,
            link: `/alumni/knowledge-brain?id=${a.id}&q=${encodeURIComponent(q)}`,
          })),
          ...(communityPosts || []).map((cp) => ({
            id: `cp-${cp.id}`,
            title: cp.title,
            subtitle: `${cp.post_type.replace('_', ' ')} · Community Board`,
            type: 'community' as const,
            link: '/alumni/community-board',
          })),
          ...(announcements || []).map((ann) => ({
            id: `ann-${ann.id}`,
            title: ann.title,
            subtitle: ann.is_priority ? 'Priority Notice' : 'Department Announcement',
            type: 'announcement' as const,
            link: '/alumni/announcements',
          })),
          ...(users || []).map((u) => ({
            id: `user-${u.id}`,
            title: u.name,
            subtitle: [u.reg_no, u.current_role_title || u.current_company].filter(Boolean).join(' · ') || 'Member',
            type: 'person' as const,
            link: '/alumni/lineage',
          })),
        ]

        setResults(searchResults)
      } catch {
        // Safe fallback
      } finally {
        setLoading(false)
      }
    },
    [supabase]
  )

  // Debounced search on input change
  useEffect(() => {
    const timer = setTimeout(() => {
      if (query.trim()) {
        void performSearch(query)
      } else {
        setResults([])
      }
    }, 150)
    return () => clearTimeout(timer)
  }, [query, performSearch])

  // Handle click outside to close dropdown
  useEffect(() => {
    function handleClickOutside(e: MouseEvent) {
      if (containerRef.current && !containerRef.current.contains(e.target as Node)) {
        setIsOpen(false)
      }
    }
    document.addEventListener('mousedown', handleClickOutside)
    return () => document.removeEventListener('mousedown', handleClickOutside)
  }, [])

  // Keyboard navigation
  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Escape') {
      setIsOpen(false)
    } else if (e.key === 'Enter') {
      e.preventDefault()
      if (query.trim()) {
        setIsOpen(false)
        router.push(`/alumni/knowledge-brain?q=${encodeURIComponent(query.trim())}`)
      }
    }
  }

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    if (query.trim()) {
      setIsOpen(false)
      router.push(`/alumni/knowledge-brain?q=${encodeURIComponent(query.trim())}`)
    }
  }

  const getIcon = (type: SearchResultItem['type']) => {
    switch (type) {
      case 'article':
        return <BookOpen className="w-3.5 h-3.5 text-primary-purple" />
      case 'community':
        return <Briefcase className="w-3.5 h-3.5 text-illus-gold" />
      case 'announcement':
        return <Megaphone className="w-3.5 h-3.5 text-amber-600" />
      case 'person':
        return <Users className="w-3.5 h-3.5 text-emerald-600" />
    }
  }

  return (
    <div ref={containerRef} className="relative w-full max-w-[380px]">
      <form
        onSubmit={handleSubmit}
        className={`flex items-center bg-white border rounded-full h-11 px-4 shadow-sm transition-all ${
          isOpen
            ? 'border-primary-purple ring-2 ring-primary-purple/20'
            : 'border-border-light hover:border-border-light/80'
        }`}
      >
        <Search className="w-4 h-4 text-text-muted mr-3 shrink-0" />
        <input
          type="text"
          value={query}
          onFocus={() => setIsOpen(true)}
          onChange={(e) => {
            setQuery(e.target.value)
            setIsOpen(true)
          }}
          onKeyDown={handleKeyDown}
          placeholder="Search articles, community, lineage..."
          className="bg-transparent border-none outline-none text-[13px] text-text-main placeholder-text-muted w-full font-medium"
        />

        {loading && <Loader2 className="w-3.5 h-3.5 text-primary-purple animate-spin ml-2 shrink-0" />}

        {query && !loading && (
          <button
            type="button"
            onClick={() => {
              setQuery('')
              setResults([])
            }}
            aria-label="Clear search"
            className="p-1 rounded-full text-text-muted hover:text-text-main hover:bg-page-bg transition ml-1 shrink-0"
          >
            <X className="w-3.5 h-3.5" />
          </button>
        )}
      </form>

      {/* Floating Dynamic Search Popover */}
      <AnimatePresence>
        {isOpen && (
          <motion.div
            initial={{ opacity: 0, y: 6, scale: 0.98 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: 6, scale: 0.98 }}
            transition={{ duration: 0.15 }}
            className="absolute top-13 left-0 w-[420px] max-w-[90vw] bg-white rounded-2xl shadow-2xl border border-border-light z-50 overflow-hidden"
          >
            {/* If Query has text */}
            {query.trim() ? (
              <div>
                <div className="p-3 border-b border-border-light bg-page-bg/40 flex items-center justify-between">
                  <span className="text-[11px] font-bold text-text-muted uppercase tracking-wider">
                    {loading ? 'Searching Department Brain…' : `${results.length} Matches Found`}
                  </span>
                  <span className="text-[10px] text-text-muted font-semibold flex items-center gap-1">
                    Press <kbd className="px-1.5 py-0.5 rounded bg-white border text-[9px]">↵ Enter</kbd> for full view
                  </span>
                </div>

                <div className="max-h-[340px] overflow-y-auto p-2 space-y-1 custom-scrollbar">
                  {results.length === 0 && !loading && (
                    <div className="p-6 text-center">
                      <p className="text-xs font-bold text-text-main">No direct matches for &ldquo;{query}&rdquo;</p>
                      <p className="text-[11px] text-text-muted mt-1">Try searching another keyword or topic.</p>
                      <button
                        type="button"
                        onClick={() => {
                          setIsOpen(false)
                          router.push(`/alumni/knowledge-brain?q=${encodeURIComponent(query.trim())}`)
                        }}
                        className="mt-3 inline-flex items-center gap-1 text-xs font-bold text-primary-purple hover:underline"
                      >
                        Search Knowledge Brain anyway <ArrowRight className="w-3 h-3" />
                      </button>
                    </div>
                  )}

                  {results.map((item) => (
                    <Link
                      key={item.id}
                      href={item.link}
                      onClick={() => setIsOpen(false)}
                      className="flex items-center gap-3 p-2.5 rounded-xl hover:bg-page-bg transition-colors group"
                    >
                      <div className="w-8 h-8 rounded-lg bg-page-bg flex items-center justify-center shrink-0 border border-border-light/60 group-hover:bg-white transition-colors">
                        {getIcon(item.type)}
                      </div>
                      <div className="min-w-0 flex-1">
                        <p className="text-xs font-bold text-text-main truncate group-hover:text-primary-purple transition-colors">
                          {item.title}
                        </p>
                        <p className="text-[10px] font-medium text-text-muted truncate mt-0.5">{item.subtitle}</p>
                      </div>
                      <ArrowRight className="w-3.5 h-3.5 text-text-muted opacity-0 group-hover:opacity-100 group-hover:translate-x-0.5 transition-all shrink-0" />
                    </Link>
                  ))}
                </div>

                <div className="p-2.5 border-t border-border-light bg-page-bg/30">
                  <button
                    type="button"
                    onClick={() => {
                      setIsOpen(false)
                      router.push(`/alumni/knowledge-brain?q=${encodeURIComponent(query.trim())}`)
                    }}
                    className="w-full flex items-center justify-center gap-2 py-2 px-3 rounded-xl bg-primary-purple/10 text-primary-purple text-xs font-bold hover:bg-primary-purple hover:text-white transition-colors"
                  >
                    <BookOpen className="w-3.5 h-3.5" />
                    Search Knowledge Brain for &ldquo;{query}&rdquo;
                  </button>
                </div>
              </div>
            ) : (
              /* Quick Suggestions When Empty */
              <div className="p-3">
                <p className="text-[11px] font-bold text-text-muted uppercase tracking-wider px-2 py-1">
                  Quick Navigation
                </p>
                <div className="space-y-1 mt-1">
                  {[
                    { label: 'Explore Knowledge Brain Guides', href: '/alumni/knowledge-brain', icon: BookOpen },
                    { label: 'Browse Community Opportunities', href: '/alumni/community-board', icon: Briefcase },
                    { label: 'Department Announcements', href: '/alumni/announcements', icon: Megaphone },
                    { label: 'Connected Lineage Juniors', href: '/alumni/lineage', icon: Users },
                  ].map((nav) => (
                    <Link
                      key={nav.label}
                      href={nav.href}
                      onClick={() => setIsOpen(false)}
                      className="flex items-center gap-2.5 p-2 rounded-xl text-xs font-semibold text-text-main hover:bg-page-bg hover:text-primary-purple transition-colors"
                    >
                      <nav.icon className="w-4 h-4 text-primary-purple" />
                      <span>{nav.label}</span>
                    </Link>
                  ))}
                </div>
              </div>
            )}
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  )
}
