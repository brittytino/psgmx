'use client'

import React, { useState, useEffect, useRef, useMemo, useCallback } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { motion, AnimatePresence } from 'framer-motion'
import {
  Search,
  X,
  BookOpen,
  Code2,
  ClipboardList,
  Building2,
  Megaphone,
  Users,
  ArrowRight,
  Loader2,
  Zap,
  BrainCircuit,
} from 'lucide-react'
import { createClient } from '@/lib/supabase/client'

interface SearchResultItem {
  id: string
  title: string
  subtitle: string
  type: 'article' | 'quest' | 'exam' | 'pattern' | 'announcement' | 'person'
  link: string
}

export function StudentHeaderSearch() {
  const router = useRouter()
  const supabase = useMemo(() => createClient(), [])
  const [query, setQuery] = useState('')
  const [isOpen, setIsOpen] = useState(false)
  const [loading, setLoading] = useState(false)
  const [results, setResults] = useState<SearchResultItem[]>([])
  const [selectedIndex, setSelectedIndex] = useState<number>(-1)
  const containerRef = useRef<HTMLDivElement>(null)

  const performSearch = useCallback(
    async (searchTerm: string) => {
      const q = searchTerm.trim()
      if (!q) {
        setResults([])
        setSelectedIndex(-1)
        setLoading(false)
        return
      }

      setLoading(true)
      try {
        const db = supabase as any
        const [
          { data: articles },
          { data: quests },
          { data: exams },
          { data: patterns },
          { data: announcements },
        ] = await Promise.all([
          db
            .from('knowledge_brain_articles')
            .select('id, title, summary, company_name')
            .eq('approval_status', 'approved')
            .or(`title.ilike.%${q}%,summary.ilike.%${q}%,content.ilike.%${q}%`)
            .limit(3),
          db
            .from('quests')
            .select('id, title, difficulty, track_key')
            .eq('is_active', true)
            .or(`title.ilike.%${q}%,prompt.ilike.%${q}%`)
            .limit(3),
          db
            .from('mock_exams')
            .select('id, title, duration_minutes')
            .or(`title.ilike.%${q}%,description.ilike.%${q}%`)
            .limit(3),
          db
            .from('interview_patterns')
            .select('id, title, company_name, pattern_type')
            .eq('approval_status', 'approved')
            .or(`title.ilike.%${q}%,company_name.ilike.%${q}%,advice.ilike.%${q}%`)
            .limit(2),
          db
            .from('announcements')
            .select('id, title, is_priority')
            .or(`title.ilike.%${q}%,message.ilike.%${q}%`)
            .limit(2),
        ])

        const searchResults: SearchResultItem[] = [
          ...((articles || []) as any[]).map((a) => ({
            id: `article-${a.id}`,
            title: a.title,
            subtitle: a.company_name ? `${a.company_name} · Knowledge Brain` : 'Knowledge Brain Article',
            type: 'article' as const,
            link: `/student/knowledge-brain?id=${a.id}&q=${encodeURIComponent(q)}`,
          })),
          ...((quests || []) as any[]).map((quest) => ({
            id: `quest-${quest.id}`,
            title: quest.title,
            subtitle: `${quest.difficulty?.toUpperCase()} · CodeBox Task`,
            type: 'quest' as const,
            link: `/student/codebox/${quest.id}`,
          })),
          ...((exams || []) as any[]).map((exam) => ({
            id: `exam-${exam.id}`,
            title: exam.title,
            subtitle: `${exam.duration_minutes} min · Mock Assessment`,
            type: 'exam' as const,
            link: `/student/exams`,
          })),
          ...((patterns || []) as any[]).map((p) => ({
            id: `pattern-${p.id}`,
            title: p.title,
            subtitle: `${p.company_name || 'Alumni Experience'} · Interview Pattern`,
            type: 'pattern' as const,
            link: `/student/interview-patterns`,
          })),
          ...((announcements || []) as any[]).map((ann) => ({
            id: `ann-${ann.id}`,
            title: ann.title,
            subtitle: ann.is_priority ? 'Priority Notice' : 'Department Notice',
            type: 'announcement' as const,
            link: `/student/announcements`,
          })),
        ]

        setResults(searchResults)
        setSelectedIndex(-1)
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
        setSelectedIndex(-1)
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
    } else if (e.key === 'ArrowDown') {
      e.preventDefault()
      if (results.length > 0) {
        setSelectedIndex((prev) => (prev < results.length - 1 ? prev + 1 : 0))
      }
    } else if (e.key === 'ArrowUp') {
      e.preventDefault()
      if (results.length > 0) {
        setSelectedIndex((prev) => (prev > 0 ? prev - 1 : results.length - 1))
      }
    } else if (e.key === 'Enter') {
      e.preventDefault()
      if (selectedIndex >= 0 && results[selectedIndex]) {
        setIsOpen(false)
        router.push(results[selectedIndex].link)
      } else if (query.trim()) {
        setIsOpen(false)
        router.push(`/student/knowledge-brain?q=${encodeURIComponent(query.trim())}`)
      }
    }
  }

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    if (selectedIndex >= 0 && results[selectedIndex]) {
      setIsOpen(false)
      router.push(results[selectedIndex].link)
    } else if (query.trim()) {
      setIsOpen(false)
      router.push(`/student/knowledge-brain?q=${encodeURIComponent(query.trim())}`)
    }
  }

  const getIcon = (type: SearchResultItem['type']) => {
    switch (type) {
      case 'article':
        return <BookOpen className="w-3.5 h-3.5 text-primary-purple" />
      case 'quest':
        return <Code2 className="w-3.5 h-3.5 text-emerald-600" />
      case 'exam':
        return <ClipboardList className="w-3.5 h-3.5 text-electric-blue" />
      case 'pattern':
        return <Building2 className="w-3.5 h-3.5 text-illus-gold" />
      case 'announcement':
        return <Megaphone className="w-3.5 h-3.5 text-amber-600" />
      default:
        return <Zap className="w-3.5 h-3.5 text-primary-purple" />
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
          placeholder="Search Knowledge Brain, quests, exams..."
          className="bg-transparent border-none outline-none text-[13px] text-text-main placeholder-text-muted w-full font-medium"
        />

        {loading && <Loader2 className="w-3.5 h-3.5 text-primary-purple animate-spin ml-2 shrink-0" />}

        {query && !loading && (
          <button
            type="button"
            onClick={() => {
              setQuery('')
              setResults([])
              setSelectedIndex(-1)
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
            className="absolute top-13 left-0 w-[420px] max-w-[90vw] bg-white rounded-2xl shadow-2xl border border-border-light z-50 overflow-hidden font-sans"
          >
            {/* If Query has text */}
            {query.trim() ? (
              <div>
                <div className="p-3 border-b border-border-light bg-page-bg/40 flex items-center justify-between">
                  <span className="text-[11px] font-bold text-text-muted uppercase tracking-wider">
                    {loading ? 'Searching Department OS…' : `${results.length} Matches Found`}
                  </span>
                  <span className="text-[10px] text-text-muted font-semibold flex items-center gap-1">
                    Use <kbd className="px-1 py-0.5 rounded bg-white border text-[9px]">↑</kbd><kbd className="px-1 py-0.5 rounded bg-white border text-[9px]">↓</kbd> or <kbd className="px-1.5 py-0.5 rounded bg-white border text-[9px]">↵ Enter</kbd>
                  </span>
                </div>

                <div className="max-h-[340px] overflow-y-auto p-2 space-y-1 custom-scrollbar">
                  {results.length === 0 && !loading && (
                    <div className="p-6 text-center">
                      <p className="text-xs font-bold text-text-main">No direct matches for &ldquo;{query}&rdquo;</p>
                      <p className="text-[11px] text-text-muted mt-1">Try searching another keyword, concept, or topic.</p>
                      <button
                        type="button"
                        onClick={() => {
                          setIsOpen(false)
                          router.push(`/student/knowledge-brain?q=${encodeURIComponent(query.trim())}`)
                        }}
                        className="mt-3 inline-flex items-center gap-1 text-xs font-bold text-primary-purple hover:underline"
                      >
                        Search Knowledge Brain anyway <ArrowRight className="w-3 h-3" />
                      </button>
                    </div>
                  )}

                  {results.map((item, idx) => {
                    const isSelected = idx === selectedIndex
                    return (
                      <Link
                        key={item.id}
                        href={item.link}
                        onClick={() => setIsOpen(false)}
                        onMouseEnter={() => setSelectedIndex(idx)}
                        className={`flex items-center gap-3 p-2.5 rounded-xl transition-colors group ${
                          isSelected
                            ? 'bg-primary-purple/10 border border-primary-purple/20'
                            : 'hover:bg-page-bg'
                        }`}
                      >
                        <div className={`w-8 h-8 rounded-lg flex items-center justify-center shrink-0 border border-border-light/60 transition-colors ${
                          isSelected ? 'bg-white shadow-sm' : 'bg-page-bg group-hover:bg-white'
                        }`}>
                          {getIcon(item.type)}
                        </div>
                        <div className="min-w-0 flex-1">
                          <p className={`text-xs font-bold truncate transition-colors ${
                            isSelected ? 'text-primary-purple' : 'text-text-main group-hover:text-primary-purple'
                          }`}>
                            {item.title}
                          </p>
                          <p className="text-[10px] font-medium text-text-muted truncate mt-0.5">{item.subtitle}</p>
                        </div>
                        <ArrowRight className={`w-3.5 h-3.5 text-text-muted transition-all shrink-0 ${
                          isSelected ? 'opacity-100 translate-x-0.5 text-primary-purple' : 'opacity-0 group-hover:opacity-100 group-hover:translate-x-0.5'
                        }`} />
                      </Link>
                    )
                  })}
                </div>

                <div className="p-2.5 border-t border-border-light bg-page-bg/30">
                  <button
                    type="button"
                    onClick={() => {
                      setIsOpen(false)
                      router.push(`/student/knowledge-brain?q=${encodeURIComponent(query.trim())}`)
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
                    { label: 'Search Knowledge Brain Guides', href: '/student/knowledge-brain', icon: BookOpen },
                    { label: 'CodeBox Coding Tasks', href: '/student/codebox', icon: Code2 },
                    { label: 'Mock Assessments & Tests', href: '/student/exams', icon: ClipboardList },
                    { label: 'Ask AI Senior RAG Mentor', href: '/student/ai-senior', icon: BrainCircuit },
                    { label: 'Daily Five & Train Gymnasium', href: '/student/train', icon: Zap },
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
