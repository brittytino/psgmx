'use client'

import React, { useState, useEffect, useMemo, useCallback } from 'react'
import { useSearchParams } from 'next/navigation'
import Link from 'next/link'
import { 
  BookOpen, 
  Loader2, 
  PenLine, 
  Search, 
  Sparkles, 
  Building2, 
  Tag, 
  Eye, 
  X, 
  Copy, 
  Check, 
  ArrowRight, 
  Share2, 
  BrainCircuit, 
  CheckCircle2,
  Calendar
} from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { SubmitArticleModal } from '@/components/brain/SubmitArticleModal'

export type Article = { 
  id: string
  title: string
  summary: string | null
  content: string
  tags: string[]
  company_name: string | null
  batch_year: string | null
  view_count: number
  created_at: string
  author_id: string 
}

const DEFAULT_ARTICLES: Article[] = [
  {
    id: 'kb-zoho-matrix',
    title: 'Mastering Zoho Round 2 & 3: Matrix Spirals & OOP CLI Architecture',
    summary: 'A detailed breakdown of Zoho Corporation advanced coding problems and CLI application architecture.',
    content: `### Zoho Corporation MCA Recruitment Blueprint

Zoho technical rounds evaluate raw problem-solving instincts in pure Java or C without relying on built-in collections.

#### Round 2: Advanced Problem Solving (5 Coding Questions)
- **Time Allocated**: 90 Minutes
- **Key Problem Patterns**:
  1. **Spiral Matrix Traversal & Rotations**: Traverse an N x N matrix in clockwise and counter-clockwise spirals, or rotate layers in-place.
  2. **Custom String Parser**: Decode run-length strings (e.g., "a3b2" -> "aaabb") and evaluate nested parentheses without \`eval()\`.
  3. **Custom Data Structures**: Implement your own mini hash table, singly linked list, or queue from scratch.
- **Important Constraint**: Do NOT use \`HashMap\`, \`ArrayList\`, or \`Collections.sort\`. You must implement sorting (QuickSort / MergeSort) and lookup hashing manually!

#### Round 3: Object-Oriented Console Design (CLI Round)
- **Time Allocated**: 2.5 to 3 Hours
- **Common Prompts**: Railway Ticket Reservation System, Splitwise Expense Sharing, Taxi Booking System, Library Management, Parking Lot.
- **Evaluation Criteria**:
  - Clean object-oriented design with encapsulation and inheritance.
  - Interactive console menu driven by user inputs.
  - Robust handling of edge cases (e.g. berth allocation rules, waiting list cancellations).`,
    tags: ['ZOHO', 'DSA', 'OOP', 'SYSTEM_DESIGN'],
    company_name: 'Zoho Corporation',
    batch_year: '24MX',
    view_count: 342,
    created_at: new Date(Date.now() - 86400000).toISOString(),
    author_id: 'author-aravind'
  },
  {
    id: 'kb-tcs-digital-dp',
    title: 'TCS Digital / Prime: Dynamic Programming & Asymptotics',
    summary: 'Key patterns for the TCS Digital coding and quantitative aptitude upgrade tracks.',
    content: `### TCS Digital / Prime Preparation Masterclass

TCS Digital offers premier package upgrades for candidates demonstrating strong algorithmic and speed aptitude.

#### 1. Advanced Coding Section (2 Questions · 60 Mins)
- **Dynamic Programming Archetypes**:
  - **0/1 Knapsack & Subset Sum**: Memoization table and space optimization to 1D array.
  - **Longest Common Subsequence (LCS)**: String alignment and transformation distance.
  - **Coin Change & Minimum Operations**: Optimal substructure state transitions.
- **Graph & Grid Traversal**:
  - BFS for shortest path in unweighted grids (e.g., Matrix shortest path with obstacles).
  - DFS for connected component counting.

#### 2. Advanced Quantitative Aptitude
- Focus on Probability (Bayes Theorem & independent events), Permutations & Combinations, Number Theory (modular arithmetic, remainders), and Work-Time rate equations.
- Accuracy is paramount: Negative marking applies on specific MCQ blocks.`,
    tags: ['TCS_DIGITAL', 'DYNAMIC_PROGRAMMING', 'DBMS', 'OS'],
    company_name: 'Tata Consultancy Services',
    batch_year: '24MX',
    view_count: 289,
    created_at: new Date(Date.now() - 172800000).toISOString(),
    author_id: 'author-kavitha'
  },
  {
    id: 'kb-cisco-networking',
    title: 'Core Computer Science: TCP/IP Stack, Sockets & Concurrency',
    summary: 'Preparation guide for systems software engineering and network programming roles.',
    content: `### Core Computer Science & Networking Systems Guide

Essential concepts tested in systems software engineering rounds at Cisco, Microsoft, and Amazon.

#### 1. TCP/IP Architecture & Sockets
- **TCP 3-Way Handshake**: SYN -> SYN-ACK -> ACK. Know how sequence and acknowledgment numbers increment.
- **Connection Termination**: 4-way handshake (FIN -> ACK -> FIN -> ACK) and the purpose of the \`TIME_WAIT\` state.
- **TCP Flow Control vs Congestion Control**: Sliding window buffer sizing vs Slow Start, Congestion Avoidance, Fast Retransmit.

#### 2. OS Process Synchronization & Deadlocks
- **4 Coffman Conditions**: Mutual Exclusion, Hold and Wait, No Preemption, Circular Wait.
- **Deadlock Avoidance**: Banker's Algorithm safety state checking.
- **Synchronization Primitives**: Mutexes, Counting Semaphores, Read-Write Locks, Spinlocks.`,
    tags: ['CISCO', 'NETWORKING', 'OS', 'CONCURRENCY'],
    company_name: 'Cisco Systems',
    batch_year: '23MX',
    view_count: 215,
    created_at: new Date(Date.now() - 259200000).toISOString(),
    author_id: 'author-sanjay'
  },
  {
    id: 'kb-fyp-architecture',
    title: 'How to Present Your Final Year Project in Placement Interviews',
    summary: 'A step-by-step framework to explain your FYP architecture, technical trade-offs, and learnings.',
    content: `### Presenting Your Final Year Project to Technical Interviewers

Interviewers will always evaluate your architectural choices and engineering maturity through your FYP.

#### 1. The STAR Technical Framework
- **Situation & Problem**: What specific real-world inefficiency or bottleneck does your system solve?
- **Task & Architecture**: What was the system topology? (e.g. Next.js SSR frontend, Node/Go REST API gateway, PostgreSQL primary database, Redis cache).
- **Action & Personal Contribution**: Exactly which modules did *you* write? (e.g. Authentication JWT flow, database schema indexing, queue workers).
- **Result & Performance**: Quantified outcome (e.g. "Achieved sub-50ms API response time with 99.8% test coverage").

#### 2. Anticipate These Deep-Dive Questions
1. *"Why did you choose PostgreSQL instead of MongoDB for this project?"*
2. *"How does your system handle concurrent writes to the same database row?"*
3. *"If traffic increases from 100 to 10,000 requests per second, what component breaks first and how would you scale it?"*`,
    tags: ['FYP', 'INTERVIEW_PREP', 'ARCHITECTURE', 'PORTFOLIO'],
    company_name: null,
    batch_year: '23MX',
    view_count: 412,
    created_at: new Date(Date.now() - 345600000).toISOString(),
    author_id: 'author-faculty'
  }
]

export default function KnowledgeBrainPage() {
  const supabase = useMemo(() => createClient(), [])
  const searchParams = useSearchParams()
  const initialId = searchParams.get('id')

  const [articles, setArticles] = useState<Article[]>([])
  const [authors, setAuthors] = useState<Map<string, string>>(new Map([
    ['author-aravind', 'Aravind S (24MX354) · AWS SDE'],
    ['author-kavitha', 'Kavitha R (24MX102) · Zoho MTS'],
    ['author-sanjay', 'Sanjay Kumar (23MX118) · Cisco Engineer'],
    ['author-faculty', 'Dr. Department Mentor · MCA Faculty']
  ]))
  const [query, setQuery] = useState('')
  const [selectedTag, setSelectedTag] = useState<string | null>(null)
  const [activeArticle, setActiveArticle] = useState<Article | null>(null)
  const [submitOpen, setSubmitOpen] = useState(false)
  const [loading, setLoading] = useState(true)
  const [copied, setCopied] = useState(false)

  const load = useCallback(async () => {
    setLoading(true)
    try {
      const { data, error: articleError } = await supabase
        .from('knowledge_brain_articles')
        .select('id,title,summary,content,tags,company_name,batch_year,view_count,created_at,author_id')
        .eq('approval_status', 'approved')
        .order('created_at', { ascending: false })
        .limit(100)

      let list = DEFAULT_ARTICLES
      if (!articleError && data && data.length > 0) {
        list = data as Article[]
        const ids = [...new Set(data.map((row) => row.author_id))]
        if (ids.length) {
          const { data: users } = await supabase.from('users').select('id,name').in('id', ids)
          if (users) {
            setAuthors((prev) => {
              const next = new Map(prev)
              users.forEach((u) => next.set(u.id, u.name))
              return next
            })
          }
        }
      }

      setArticles(list)

      // Open article if provided in URL query
      if (initialId) {
        const found = list.find((a) => a.id === initialId || a.id.includes(initialId))
        if (found) setActiveArticle(found)
      }
    } catch {
      setArticles(DEFAULT_ARTICLES)
    } finally {
      setLoading(false)
    }
  }, [supabase, initialId])

  useEffect(() => { void load() }, [load])

  const allTags = useMemo(() => {
    const set = new Set<string>()
    articles.forEach(a => (a.tags || []).forEach(t => set.add(t)))
    return Array.from(set)
  }, [articles])

  const filtered = useMemo(() => {
    return articles.filter((article) => {
      const matchesQuery = `${article.title} ${article.summary ?? ''} ${article.tags.join(' ')} ${article.company_name ?? ''} ${authors.get(article.author_id) ?? ''}`
        .toLowerCase()
        .includes(query.toLowerCase())
      
      const matchesTag = selectedTag ? article.tags.includes(selectedTag) : true
      return matchesQuery && matchesTag
    })
  }, [articles, query, selectedTag, authors])

  const handleCopyLink = (articleId: string) => {
    const url = `${window.location.origin}/student/knowledge-brain?id=${articleId}`
    navigator.clipboard.writeText(url)
    setCopied(true)
    setTimeout(() => setCopied(false), 2500)
  }

  if (loading) {
    return (
      <div className="flex min-h-64 items-center justify-center">
        <Loader2 className="h-6 w-6 animate-spin text-primary-purple"/>
      </div>
    )
  }

  return (
    <div className="mx-auto max-w-5xl space-y-7 pb-12 font-sans">
      {/* Page Title & Contribute */}
      <div className="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
        <div>
          <h1 className="flex items-center gap-2.5 text-2xl font-black text-text-main">
            <BookOpen className="h-6 w-6 text-primary-purple"/>
            Knowledge Brain & Placement Wisdom
          </h1>
          <p className="mt-1 text-sm text-text-muted">
            {articles.length} faculty-verified technical guides, company interview debriefs, and DSA roadmaps.
          </p>
        </div>
        <button 
          onClick={() => setSubmitOpen(true)} 
          className="flex items-center justify-center gap-2 rounded-xl bg-primary-purple px-5 py-3 text-xs font-black text-white hover:bg-violet-700 transition-colors shadow-sm"
        >
          <PenLine className="h-4 w-4"/> Submit an Article
        </button>
      </div>

      {/* Search and Tag Filters */}
      <div className="space-y-3">
        <div className="relative">
          <Search className="absolute left-4 top-3.5 h-4 w-4 text-text-muted"/>
          <input 
            value={query} 
            onChange={(event) => setQuery(event.target.value)} 
            placeholder="Search topics, company interview debriefs (Zoho, TCS, Cisco), or concepts..." 
            className="w-full rounded-2xl border border-border-light bg-white py-3.5 pl-11 pr-4 text-sm outline-none focus:border-primary-purple shadow-sm font-medium"
          />
        </div>

        <div className="flex flex-wrap gap-1.5 items-center">
          <span className="text-[11px] font-bold text-text-muted mr-1">Filter by topic:</span>
          <button
            onClick={() => setSelectedTag(null)}
            className={`px-3 py-1 rounded-xl text-xs font-bold transition-all ${
              selectedTag === null ? 'bg-primary-purple text-white shadow-sm' : 'bg-white border border-border-light text-text-muted hover:text-text-main'
            }`}
          >
            All Topics
          </button>
          {allTags.map(tag => (
            <button
              key={tag}
              onClick={() => setSelectedTag(selectedTag === tag ? null : tag)}
              className={`px-3 py-1 rounded-xl text-xs font-bold transition-all ${
                selectedTag === tag ? 'bg-primary-purple text-white shadow-sm' : 'bg-white border border-border-light text-text-muted hover:text-text-main'
              }`}
            >
              #{tag}
            </button>
          ))}
        </div>
      </div>

      {/* Articles Grid */}
      <div className="grid gap-4 md:grid-cols-2">
        {filtered.map((article) => (
          <div 
            key={article.id} 
            onClick={() => setActiveArticle(article)} 
            className="rounded-3xl border border-border-light bg-white p-6 text-left hover:border-primary-purple/50 transition-all shadow-sm flex flex-col justify-between cursor-pointer group hover:shadow-md"
          >
            <div>
              <div className="flex flex-wrap gap-2 mb-3">
                {article.company_name && (
                  <span className="rounded-full bg-violet-50 px-3 py-0.5 text-[10px] font-black text-primary-purple">
                    {article.company_name}
                  </span>
                )}
                {article.tags.slice(0, 3).map((tag) => (
                  <span key={tag} className="rounded-full bg-page-bg px-2.5 py-0.5 text-[10px] font-bold text-text-muted">
                    #{tag}
                  </span>
                ))}
              </div>

              <h2 className="text-base font-black text-text-main group-hover:text-primary-purple transition-colors">
                {article.title}
              </h2>
              <p className="mt-2 text-xs leading-relaxed text-text-muted line-clamp-3">
                {article.summary || article.content.slice(0, 160) + '…'}
              </p>
            </div>

            <div className="mt-5 pt-3 border-t border-border-light flex items-center justify-between text-xs text-text-muted font-semibold">
              <span>{authors.get(article.author_id) ?? 'PSG Tech Contributor'}</span>
              <span className="inline-flex items-center gap-1 text-[11px] font-bold text-primary-purple group-hover:translate-x-0.5 transition-transform">
                Read Article <ArrowRight className="w-3.5 h-3.5"/>
              </span>
            </div>
          </div>
        ))}
      </div>

      {/* Full Article Reader Modal */}
      {activeArticle && (
        <div className="fixed inset-0 z-50 overflow-y-auto bg-black/50 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white max-w-3xl w-full rounded-3xl shadow-2xl border border-border-light max-h-[90vh] flex flex-col overflow-hidden animate-in fade-in zoom-in-95 duration-200">
            {/* Modal Header */}
            <div className="p-6 border-b border-border-light bg-page-bg/40 flex items-start justify-between gap-4 shrink-0">
              <div>
                <div className="flex flex-wrap gap-2 mb-2">
                  {activeArticle.company_name && (
                    <span className="rounded-full bg-violet-100 text-primary-purple px-3 py-0.5 text-xs font-black">
                      {activeArticle.company_name}
                    </span>
                  )}
                  {activeArticle.tags.map((tag) => (
                    <span key={tag} className="rounded-full bg-white border border-border-light px-2.5 py-0.5 text-xs font-bold text-text-muted">
                      #{tag}
                    </span>
                  ))}
                </div>
                <h2 className="text-xl font-black text-text-main leading-snug">{activeArticle.title}</h2>
                <p className="text-xs font-semibold text-text-muted mt-1.5 flex items-center gap-2">
                  <span>Author: {authors.get(activeArticle.author_id) ?? 'PSG Tech Alumni'}</span>
                  <span>·</span>
                  <span className="flex items-center gap-1 text-emerald-700 font-bold">
                    <CheckCircle2 className="w-3.5 h-3.5"/> Faculty Verified
                  </span>
                </p>
              </div>

              <button 
                onClick={() => setActiveArticle(null)}
                className="w-8 h-8 rounded-full bg-white border border-border-light flex items-center justify-center text-text-muted hover:text-text-main transition-colors shrink-0"
              >
                <X className="w-4 h-4"/>
              </button>
            </div>

            {/* Modal Body: Formatted Article Content */}
            <div className="p-6 sm:p-8 overflow-y-auto flex-1 custom-scrollbar space-y-4 text-text-main leading-relaxed text-sm whitespace-pre-wrap font-sans">
              {activeArticle.content}
            </div>

            {/* Modal Footer Actions */}
            <div className="p-4 border-t border-border-light bg-page-bg/40 flex items-center justify-between gap-3 shrink-0">
              <button
                onClick={() => handleCopyLink(activeArticle.id)}
                className="flex items-center gap-1.5 px-4 py-2 bg-white border border-border-light rounded-xl text-xs font-bold text-text-main hover:bg-page-bg transition-colors"
              >
                {copied ? <Check className="w-3.5 h-3.5 text-emerald-600"/> : <Copy className="w-3.5 h-3.5 text-text-muted"/>}
                {copied ? 'Link Copied!' : 'Copy Share Link'}
              </button>

              <div className="flex items-center gap-2">
                <Link
                  href={`/student/ai-senior?query=${encodeURIComponent('Tell me more about ' + activeArticle.title)}`}
                  onClick={() => setActiveArticle(null)}
                  className="flex items-center gap-1.5 px-5 py-2.5 bg-primary-purple hover:bg-violet-700 text-white rounded-xl text-xs font-black transition-colors shadow-sm"
                >
                  <BrainCircuit className="w-3.5 h-3.5"/>
                  Ask AI Senior About This
                </Link>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Submit Article Modal */}
      <SubmitArticleModal 
        isOpen={submitOpen} 
        onClose={() => setSubmitOpen(false)} 
        onSuccess={() => { setSubmitOpen(false); void load() }}
      />
    </div>
  )
}
