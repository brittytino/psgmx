'use client'

import React, { useState, useEffect, useCallback, useMemo } from 'react'
import {
  BookOpenCheck,
  CalendarDays,
  Code2,
  HandHeart,
  Info,
  Plus,
  ShieldCheck,
  UsersRound,
  X,
  Search,
  Loader2,
  CheckCircle2,
} from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { getCurrentProfile } from '@/lib/current-profile'
import { InitialsAvatar } from '@/components/basic/InitialsAvatar'
import { useUI } from '@/components/providers/ui-provider'
import type { Database } from '@/../../supabase/types/database.types'

type Post = Database['public']['Tables']['collaboration_posts']['Row']
type PostType = Exclude<Post['post_type'], 'job'>

interface AuthorInfo {
  id: string
  name: string
  reg_no: string | null
  current_role_title: string | null
  current_company: string | null
}

const typeConfig: Record<PostType, { label: string; icon: React.ComponentType<{ className?: string }> }> = {
  project: { label: 'Project Collaboration', icon: Code2 },
  mentorship: { label: 'Mentoring Circle', icon: HandHeart },
  learning_event: { label: 'Learning Event', icon: CalendarDays },
  career_information: { label: 'Career Information', icon: BookOpenCheck },
  unofficial_opportunity: { label: 'Unofficial Opportunity', icon: Info },
}

export default function CommunityBoardPage() {
  const supabase = useMemo(() => createClient(), [])
  const { showToast } = useUI()
  const [posts, setPosts] = useState<Post[]>([])
  const [authors, setAuthors] = useState<Map<string, AuthorInfo>>(new Map())
  const [userId, setUserId] = useState('')
  const [showForm, setShowForm] = useState(false)
  const [type, setType] = useState<PostType>('project')
  const [title, setTitle] = useState('')
  const [description, setDescription] = useState('')
  const [visibility, setVisibility] = useState<Post['visibility']>('department')
  const [selectedFilter, setSelectedFilter] = useState<'all' | PostType>('all')
  const [searchQuery, setSearchQuery] = useState('')
  const [loading, setLoading] = useState(true)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')

  const load = useCallback(async () => {
    setLoading(true)
    setError('')
    try {
      const me = await getCurrentProfile(supabase)
      if (!me) throw new Error('Your alumni profile could not be loaded.')
      setUserId(me.id)

      const { data, error: loadError } = await supabase
        .from('collaboration_posts')
        .select('*')
        .eq('is_active', true)
        .order('created_at', { ascending: false })
        .limit(100)

      if (loadError) throw loadError
      const postList = data ?? []
      setPosts(postList)

      const authorIds = [...new Set(postList.map((p) => p.posted_by).filter((id): id is string => Boolean(id)))]
      if (authorIds.length > 0) {
        const { data: authorRows } = await supabase
          .from('users')
          .select('id, name, reg_no, current_role_title, current_company')
          .in('id', authorIds)

        const map = new Map<string, AuthorInfo>()
        for (const u of authorRows || []) {
          map.set(u.id, u)
        }
        setAuthors(map)
      }
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : 'The Community Board could not be loaded.')
    } finally {
      setLoading(false)
    }
  }, [supabase])

  useEffect(() => {
    void load()
  }, [load])

  async function publish(event: React.FormEvent) {
    event.preventDefault()
    if (!userId) return
    setBusy(true)
    setError('')
    try {
      const { error: insertError } = await supabase.from('collaboration_posts').insert({
        posted_by: userId,
        post_type: type,
        title: title.trim(),
        description: description.trim(),
        visibility,
        is_active: true,
      })
      if (insertError) throw insertError

      setTitle('')
      setDescription('')
      setShowForm(false)
      showToast('Your community post has been published.', 'success')
      await load()
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'Failed to publish post'
      setError(msg)
      showToast(msg, 'error')
    } finally {
      setBusy(false)
    }
  }

  async function deactivate(postId: string) {
    try {
      const { error: updateError } = await supabase
        .from('collaboration_posts')
        .update({ is_active: false })
        .eq('id', postId)
        .eq('posted_by', userId)

      if (updateError) throw updateError
      setPosts((current) => current.filter((post) => post.id !== postId))
      showToast('Post closed successfully.', 'info')
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'Failed to close post'
      setError(msg)
      showToast(msg, 'error')
    }
  }

  const filteredPosts = useMemo(() => {
    return posts.filter((p) => {
      const actualType = p.post_type === 'job' ? 'unofficial_opportunity' : p.post_type
      const matchesType = selectedFilter === 'all' || actualType === selectedFilter
      const author = authors.get(p.posted_by)
      const textToMatch = `${p.title} ${p.description} ${author?.name || ''} ${p.visibility}`.toLowerCase()
      const matchesSearch = !searchQuery.trim() || textToMatch.includes(searchQuery.toLowerCase().trim())
      return matchesType && matchesSearch
    })
  }, [posts, selectedFilter, searchQuery, authors])

  return (
    <div className="mx-auto max-w-5xl space-y-7 pb-12">
      {/* Header */}
      <header className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
        <div>
          <div className="mb-2 flex items-center gap-2 text-xs font-black uppercase tracking-[.16em] text-primary-purple">
            <UsersRound className="h-4 w-4" /> MX Network Community
          </div>
          <h1 className="text-3xl font-black tracking-tight text-text-main">Community Board</h1>
          <p className="mt-2 max-w-2xl text-sm leading-6 text-text-muted">
            Collaborate on open projects, mentorship circles, learning events, and industry guidance across batches.
          </p>
        </div>
        <button
          onClick={() => setShowForm((value) => !value)}
          className="inline-flex items-center justify-center gap-2 rounded-xl bg-primary-purple px-5 py-3 text-sm font-black text-white shadow-sm hover:bg-deep-violet transition-colors shrink-0"
        >
          {showForm ? <X className="h-4 w-4" /> : <Plus className="h-4 w-4" />}
          {showForm ? 'Cancel' : 'Create Community Post'}
        </button>
      </header>

      {/* Disclaimers */}
      <div className="flex gap-3 rounded-2xl border border-amber-200 bg-amber-50/70 p-4 text-xs font-semibold leading-5 text-amber-900">
        <ShieldCheck className="mt-0.5 h-5 w-5 shrink-0 text-amber-700" />
        <span>
          Use NEO PAT for official placement drives, eligibility, applications, and shortlists. Community posts are informal department collaborations.
        </span>
      </div>

      {error && (
        <div role="alert" className="rounded-2xl border border-red-200 bg-red-50 p-4 text-sm font-bold text-red-700">
          {error}
        </div>
      )}

      {/* Create Post Modal / Form */}
      {showForm && (
        <form onSubmit={publish} className="space-y-5 rounded-3xl border border-border-light bg-white p-6 md:p-8 shadow-md">
          <div>
            <h2 className="text-lg font-black text-text-main">New Community Collaboration</h2>
            <p className="mt-1 text-xs text-text-muted">
              Be specific about the expected outcome, time commitment, and target participants.
            </p>
          </div>

          <div>
            <span className="block text-xs font-bold text-text-muted mb-2">Post Category</span>
            <div className="flex flex-wrap gap-2">
              {(Object.entries(typeConfig) as [PostType, (typeof typeConfig)[PostType]][]).map(([value, config]) => {
                const Icon = config.icon
                return (
                  <button
                    key={value}
                    type="button"
                    onClick={() => setType(value)}
                    className={`inline-flex items-center gap-2 rounded-xl px-3.5 py-2 text-xs font-bold transition-all ${
                      type === value
                        ? 'bg-primary-purple text-white shadow-sm'
                        : 'bg-page-bg text-text-muted hover:text-text-main'
                    }`}
                  >
                    <Icon className="h-3.5 w-3.5" />
                    {config.label}
                  </button>
                )
              })}
            </div>
          </div>

          <label className="block text-xs font-bold text-text-muted">
            Title
            <input
              required
              minLength={5}
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="e.g. Building an Open Source Distributed Cache in Rust"
              className="mt-2 w-full rounded-xl border border-border-light px-4 py-3 text-sm outline-none focus:border-primary-purple"
            />
          </label>

          <label className="block text-xs font-bold text-text-muted">
            Description
            <textarea
              required
              minLength={20}
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="Outline the project scope, required prerequisites, schedule, and how interested peers can join or reach out."
              className="mt-2 min-h-28 w-full rounded-xl border border-border-light px-4 py-3 text-sm outline-none focus:border-primary-purple"
            />
          </label>

          <label className="block text-xs font-bold text-text-muted">
            Audience Visibility
            <select
              value={visibility}
              onChange={(e) => setVisibility(e.target.value as Post['visibility'])}
              className="mt-2 w-full rounded-xl border border-border-light px-4 py-3 text-sm outline-none focus:border-primary-purple"
            >
              <option value="department">All MX Batches (Students & Alumni)</option>
              <option value="batch">My Cohort Only</option>
              <option value="lineage_only">My Register Lineage Only</option>
            </select>
          </label>

          <button
            disabled={busy}
            type="submit"
            className="w-full rounded-xl bg-primary-purple px-5 py-3 text-sm font-black text-white shadow-sm hover:bg-deep-violet disabled:opacity-50 transition-colors"
          >
            {busy ? 'Publishing…' : 'Publish with Community Disclaimer'}
          </button>
        </form>
      )}

      {/* Filter and Search Bar */}
      <div className="flex flex-col md:flex-row items-center justify-between gap-4">
        {/* Category Pills */}
        <div className="flex flex-wrap items-center gap-1.5 w-full md:w-auto">
          <button
            onClick={() => setSelectedFilter('all')}
            className={`rounded-xl px-3.5 py-1.5 text-xs font-bold transition-all ${
              selectedFilter === 'all'
                ? 'bg-primary-purple text-white shadow-sm'
                : 'bg-white border border-border-light text-text-muted hover:text-text-main'
            }`}
          >
            All Posts ({posts.length})
          </button>
          {(Object.entries(typeConfig) as [PostType, (typeof typeConfig)[PostType]][]).map(([value, config]) => {
            const count = posts.filter((p) => (p.post_type === 'job' ? 'unofficial_opportunity' : p.post_type) === value).length
            return (
              <button
                key={value}
                onClick={() => setSelectedFilter(value)}
                className={`rounded-xl px-3.5 py-1.5 text-xs font-bold transition-all ${
                  selectedFilter === value
                    ? 'bg-primary-purple text-white shadow-sm'
                    : 'bg-white border border-border-light text-text-muted hover:text-text-main'
                }`}
              >
                {config.label} {count > 0 && `(${count})`}
              </button>
            )
          })}
        </div>

        {/* Search */}
        <div className="relative w-full md:w-64">
          <Search className="absolute left-3.5 top-2.5 h-4 w-4 text-text-muted" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search posts or authors..."
            className="w-full rounded-xl border border-border-light bg-white py-2 pl-9 pr-3 text-xs font-semibold outline-none focus:border-primary-purple shadow-sm"
          />
        </div>
      </div>

      {/* Posts Grid */}
      {loading && (
        <div className="grid gap-5 md:grid-cols-2">
          {[1, 2, 3, 4].map((item) => (
            <div key={item} className="h-56 animate-pulse rounded-3xl bg-white border border-border-light" />
          ))}
        </div>
      )}

      {!loading && filteredPosts.length === 0 && (
        <div className="rounded-3xl border border-dashed border-border-light bg-white p-14 text-center">
          <HandHeart className="mx-auto h-10 w-10 text-primary-purple" />
          <h2 className="mt-4 text-lg font-black text-text-main">No active posts in this view</h2>
          <p className="mt-2 text-sm text-text-muted">
            {searchQuery ? 'No community posts match your search.' : 'Start a focused project, learning circle, or mentoring collaboration.'}
          </p>
        </div>
      )}

      <div className="grid gap-5 md:grid-cols-2">
        {filteredPosts.map((post) => {
          const config = post.post_type === 'job' ? typeConfig.unofficial_opportunity : typeConfig[post.post_type]
          const Icon = config.icon
          const author = authors.get(post.posted_by)
          const isMine = post.posted_by === userId

          return (
            <article
              key={post.id}
              className="rounded-3xl border border-border-light bg-white p-6 shadow-sm hover:shadow-md transition-shadow flex flex-col justify-between"
            >
              <div>
                <div className="flex items-start justify-between gap-4">
                  <div className="flex items-center gap-3">
                    <div className="grid h-10 w-10 place-items-center rounded-2xl bg-primary-purple/10 text-primary-purple shrink-0">
                      <Icon className="h-5 w-5" />
                    </div>
                    <div>
                      <span className="block text-[10px] font-black uppercase tracking-[.14em] text-primary-purple">
                        {config.label}
                      </span>
                      <span className="text-[11px] font-bold text-text-muted">
                        Visibility: {post.visibility.replace('_', ' ')}
                      </span>
                    </div>
                  </div>

                  {isMine && (
                    <button
                      onClick={() => void deactivate(post.id)}
                      title="Close your post"
                      className="rounded-xl p-2 text-text-muted hover:bg-page-bg hover:text-rose-600 transition-colors"
                    >
                      <X className="h-4 w-4" />
                    </button>
                  )}
                </div>

                <h2 className="mt-4 text-base font-black text-text-main leading-snug">{post.title}</h2>
                <p className="mt-2.5 whitespace-pre-wrap text-xs leading-6 text-text-muted line-clamp-4">
                  {post.description}
                </p>
              </div>

              <div className="mt-6 pt-4 border-t border-border-light/60 space-y-3">
                {/* Author Info */}
                <div className="flex items-center justify-between gap-2">
                  <div className="flex items-center gap-2.5 min-w-0">
                    <InitialsAvatar name={author?.name || 'PSGMX Member'} size={28} />
                    <div className="min-w-0">
                      <p className="text-xs font-bold text-text-main truncate">
                        {author?.name || 'Department Member'}
                        {isMine && <span className="ml-1.5 text-[10px] text-primary-purple font-black">(You)</span>}
                      </p>
                      <p className="text-[10px] text-text-muted truncate">
                        {[author?.reg_no, author?.current_role_title || author?.current_company].filter(Boolean).join(' · ') || 'MCA Alumni Network'}
                      </p>
                    </div>
                  </div>
                  <span className="text-[10px] font-medium text-text-muted shrink-0">
                    {new Date(post.created_at).toLocaleDateString('en-IN', { month: 'short', day: 'numeric' })}
                  </span>
                </div>

                {post.disclaimer && (
                  <div className="rounded-xl bg-amber-50/80 p-2.5 text-[10px] font-medium leading-4 text-amber-900">
                    {post.disclaimer}
                  </div>
                )}
              </div>
            </article>
          )
        })}
      </div>
    </div>
  )
}
