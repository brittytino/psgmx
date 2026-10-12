'use client'

import React, { Suspense } from 'react'
import { useSearchParams } from 'next/navigation'
import { BookOpen, Building2, Calendar, Copy, Loader2, PenLine, Search, X } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { SubmitArticleModal } from '@/components/brain/SubmitArticleModal'
import ReactMarkdown from 'react-markdown'
import remarkGfm from 'remark-gfm'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Badge } from '@/components/ui/badge'
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from '@/components/ui/dialog'

type Article = {
  id: string
  title: string
  summary: string | null
  content: string
  tags: string[]
  company_name: string | null
  batch_year: string | null
  view_count: number
  created_at: string
  author_id: string | null
}

function TagCombobox({ tags, value, onChange }: { tags: string[], value: string | null, onChange: (val: string | null) => void }) {
  const [open, setOpen] = React.useState(false)
  const [search, setSearch] = React.useState('')
  const ref = React.useRef<HTMLDivElement>(null)

  React.useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (ref.current && !ref.current.contains(event.target as Node)) {
        setOpen(false)
      }
    }
    document.addEventListener('mousedown', handleClickOutside)
    return () => document.removeEventListener('mousedown', handleClickOutside)
  }, [])

  const filtered = tags.filter(t => t.toLowerCase().includes(search.toLowerCase()))

  return (
    <div className="relative w-full sm:w-72" ref={ref}>
      <button
        onClick={() => setOpen(!open)}
        className="flex w-full items-center justify-between rounded-xl border border-border-light bg-white px-4 py-2.5 text-sm font-medium text-text-main shadow-sm transition-all hover:bg-slate-50 focus:outline-none focus:ring-2 focus:ring-primary-purple/20"
      >
        <span className="truncate">{value || 'All topics & companies'}</span>
        <svg className={`h-4 w-4 text-text-muted transition-transform ${open ? 'rotate-180' : ''}`} xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="6 9 12 15 18 9"></polyline></svg>
      </button>

      {open && (
        <div className="absolute z-10 mt-2 w-full overflow-hidden rounded-xl border border-border-light bg-white shadow-xl animate-in fade-in zoom-in-95 duration-100">
          <div className="border-b border-border-light p-2">
            <div className="flex items-center rounded-lg bg-slate-100 px-3 py-1.5">
              <Search className="h-4 w-4 text-text-muted shrink-0" />
              <input
                type="text"
                className="ml-2 w-full bg-transparent text-sm outline-none placeholder:text-text-muted"
                placeholder="Search tags..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                autoFocus
              />
            </div>
          </div>
          <div className="max-h-60 overflow-y-auto p-1 custom-scrollbar">
            <button
              onClick={() => { onChange(null); setOpen(false) }}
              className={`flex w-full items-center rounded-lg px-3 py-2 text-sm transition-colors ${!value ? 'bg-primary-purple/10 text-primary-purple font-bold' : 'text-text-main hover:bg-slate-100'}`}
            >
              All topics & companies
            </button>
            {filtered.map(tag => (
              <button
                key={tag}
                onClick={() => { onChange(tag); setOpen(false) }}
                className={`flex w-full items-center rounded-lg px-3 py-2 text-sm transition-colors ${value === tag ? 'bg-primary-purple/10 text-primary-purple font-bold' : 'text-text-main hover:bg-slate-100'}`}
              >
                {tag}
              </button>
            ))}
            {filtered.length === 0 && (
              <div className="py-6 text-center text-sm text-text-muted">No tags found.</div>
            )}
          </div>
        </div>
      )}
    </div>
  )
}

function KnowledgeBrainContent() {
  const supabase = React.useMemo(() => createClient(), [])
  const searchParams = useSearchParams()
  const initialId = searchParams.get('id')
  const initialQ = searchParams.get('q') || ''
  const [articles, setArticles] = React.useState<Article[]>([])
  const [authors, setAuthors] = React.useState<Map<string, string>>(new Map())
  const [query, setQuery] = React.useState(initialQ)
  const [tag, setTag] = React.useState<string | null>(null)
  const [active, setActive] = React.useState<Article | null>(null)
  const [submitOpen, setSubmitOpen] = React.useState(false)
  const [loading, setLoading] = React.useState(true)
  const [error, setError] = React.useState('')

  // Sync state if URL query param changes
  React.useEffect(() => {
    if (initialQ !== undefined) {
      setQuery(initialQ)
    }
  }, [initialQ])

  const load = React.useCallback(async () => {
    setLoading(true)
    setError('')
    try {
      const { data, error: articleError } = await supabase
        .from('knowledge_brain_articles')
        .select('id,title,summary,content,tags,company_name,batch_year,view_count,created_at,author_id')
        .eq('approval_status', 'approved')
        .order('created_at', { ascending: false })
        .limit(200)

      if (articleError) throw articleError
      const list = (data ?? []) as Article[]
      setArticles(list)

      const ids = [...new Set(list.map((row) => row.author_id).filter((id): id is string => Boolean(id)))]
      if (ids.length) {
        const { data: users, error: userError } = await supabase.from('users').select('id,name').in('id', ids)
        if (userError) throw userError
        setAuthors(new Map((users ?? []).map((user) => [user.id, user.name])))
      } else {
        setAuthors(new Map())
      }

      if (initialId) {
        const matched = list.find((row) => row.id === initialId)
        if (matched) setActive(matched)
      }
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : 'Knowledge Brain could not be loaded.')
      setArticles([])
    } finally {
      setLoading(false)
    }
  }, [initialId, supabase])

  React.useEffect(() => {
    void load()
  }, [load])

  const tags = React.useMemo(
    () => [...new Set(articles.flatMap((article) => article.tags ?? []))].sort(),
    [articles]
  )

  const visible = React.useMemo(() => {
    const qLower = query.toLowerCase().trim()
    return articles.filter((article) => {
      const text = `${article.title} ${article.summary ?? ''} ${article.company_name ?? ''} ${(
        article.tags ?? []
      ).join(' ')}`.toLowerCase()
      const matchesQuery = !qLower || text.includes(qLower)
      const matchesTag = !tag || (article.tags ?? []).includes(tag)
      return matchesQuery && matchesTag
    })
  }, [articles, query, tag])

  if (loading) {
    return (
      <div className="grid min-h-64 place-items-center">
        <Loader2 className="h-6 w-6 animate-spin text-primary-purple" />
      </div>
    )
  }

  return (
    <div className="mx-auto max-w-5xl space-y-7 pb-12">
      <header className="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
        <div>
          <h1 className="flex items-center gap-2 text-2xl font-black text-text-main">
            <BookOpen className="h-6 w-6 text-primary-purple" />
            Knowledge Brain
          </h1>
          <p className="mt-1 text-sm text-text-muted">
            {articles.length} verified guides, interview patterns, and departmental resources.
          </p>
        </div>
        <Button
          onClick={() => setSubmitOpen(true)}
          className="rounded-xl bg-primary-purple px-5 py-3 text-xs font-black text-white hover:bg-deep-violet transition-colors h-auto shadow-sm"
        >
          <PenLine className="h-4 w-4 mr-2" />
          Submit an article
        </Button>
      </header>

      {error && (
        <div className="rounded-xl bg-red-50 p-4 text-sm font-bold text-red-700">
          {error}{' '}
          <button onClick={() => void load()} className="underline">
            Retry
          </button>
        </div>
      )}

      {/* In-page live search bar */}
      <div className="relative">
        <Search className="absolute left-4 top-3 h-4 w-4 text-text-muted" />
        <Input
          value={query}
          onChange={(event) => setQuery(event.target.value)}
          className="w-full rounded-2xl border-border-light bg-white py-6 pl-11 pr-10 text-sm focus-visible:ring-primary-purple shadow-sm"
          placeholder="Search approved knowledge by topic, company, or concept…"
        />
        {query && (
          <button
            onClick={() => setQuery('')}
            aria-label="Clear search"
            className="absolute right-3.5 top-3.5 p-1 rounded-full text-text-muted hover:text-text-main"
          >
            <X className="h-3.5 w-3.5" />
          </button>
        )}
      </div>

      {/* Filter Tags */}
      <div className="flex items-center gap-3">
        <TagCombobox tags={tags} value={tag} onChange={setTag} />
      </div>

      {/* Articles Grid */}
      <div className="grid gap-4 sm:grid-cols-2">
        {visible.map((article) => (
          <button
            key={article.id}
            onClick={() => setActive(article)}
            className="rounded-3xl border border-border-light bg-white p-6 text-left shadow-sm transition hover:border-primary-purple/40 hover:shadow-md flex flex-col justify-between"
          >
            <div>
              <div className="flex flex-wrap gap-2">
                {article.company_name && (
                  <Badge variant="secondary" className="bg-violet-50 text-primary-purple hover:bg-violet-100 rounded-full px-2.5 font-black text-[10px]">
                    <Building2 className="h-3 w-3 mr-1" />
                    {article.company_name}
                  </Badge>
                )}
                {article.batch_year && (
                  <Badge variant="outline" className="rounded-full bg-page-bg px-2.5 text-[10px] font-black text-text-muted border-border-light">
                    {article.batch_year}
                  </Badge>
                )}
              </div>
              <h2 className="mt-3 text-base font-black leading-6 text-text-main">{article.title}</h2>
              <p className="mt-2 line-clamp-3 text-xs leading-5 text-text-muted">
                {article.summary || article.content.replace(/[#*`_>-]/g, '').replace(/\s+/g, ' ').trim()}
              </p>
            </div>
            <p className="mt-4 text-[11px] font-bold text-text-muted">
              {article.author_id ? authors.get(article.author_id) || 'Verified contributor' : 'PSGMX archive'} ·{' '}
              {new Intl.DateTimeFormat('en-IN', { dateStyle: 'medium' }).format(new Date(article.created_at))}
            </p>
          </button>
        ))}
        {!visible.length && (
          <div className="col-span-full rounded-3xl border border-dashed border-border-light bg-white p-10 text-center text-sm text-text-muted">
            No approved article matches this view.
          </div>
        )}
      </div>

      {/* Modal: View Article */}
      <Dialog open={!!active} onOpenChange={(open) => !open && setActive(null)}>
        <DialogContent className="max-w-3xl rounded-3xl p-6 sm:p-9 bg-white border-border-light max-h-[90vh] flex flex-col">
          <DialogHeader className="hidden">
            <DialogTitle>View Article</DialogTitle>
            <DialogDescription>Read the detailed article content.</DialogDescription>
          </DialogHeader>
          <div className="flex flex-col flex-1 overflow-hidden">
            <div className="flex justify-between gap-4 shrink-0">
              <div>
                <h2 className="text-2xl font-black text-text-main">{active?.title}</h2>
                <p className="mt-2 flex items-center gap-1 text-xs text-text-muted">
                  <Calendar className="h-3.5 w-3.5" />
                  {active && new Intl.DateTimeFormat('en-IN', { dateStyle: 'medium' }).format(new Date(active.created_at))}
                </p>
              </div>
            </div>
            <div className="mt-6 text-sm leading-7 text-text-main overflow-y-auto pr-2 custom-scrollbar">
              <ReactMarkdown
                remarkPlugins={[remarkGfm]}
                components={{
                  h1: ({ ...props }) => <h1 className="text-3xl font-black mt-8 mb-4 text-slate-900" {...props} />,
                  h2: ({ ...props }) => <h2 className="text-2xl font-black mt-8 mb-4 text-slate-900 border-b pb-2" {...props} />,
                  h3: ({ ...props }) => <h3 className="text-lg font-bold mt-6 mb-3 text-slate-800" {...props} />,
                  p: ({ ...props }) => <p className="mb-4 text-slate-600 leading-relaxed" {...props} />,
                  ul: ({ ...props }) => <ul className="mb-4 ml-6 list-disc text-slate-600 marker:text-slate-400 space-y-1" {...props} />,
                  ol: ({ ...props }) => <ol className="mb-4 ml-6 list-decimal text-slate-600 marker:text-slate-400 space-y-1" {...props} />,
                  li: ({ ...props }) => <li className="" {...props} />,
                  strong: ({ ...props }) => <strong className="font-bold text-slate-900" {...props} />,
                  blockquote: ({ ...props }) => <blockquote className="border-l-4 border-primary-purple pl-4 italic text-slate-500 bg-slate-50 py-2 my-4 rounded-r-lg" {...props} />,
                  a: ({ ...props }) => <a className="text-primary-purple font-medium hover:underline" {...props} />,
                  table: ({ ...props }) => <div className="overflow-x-auto mb-6 border rounded-xl"><table className="w-full text-left border-collapse" {...props} /></div>,
                  th: ({ ...props }) => <th className="bg-slate-50 px-4 py-3 font-semibold text-slate-900 border-b" {...props} />,
                  td: ({ ...props }) => <td className="px-4 py-3 border-b text-slate-600" {...props} />,
                  code: ({ className, children, ...props }: any) => {
                    const match = /language-(\w+)/.exec(className || '')
                    return match ? (
                      <div className="overflow-hidden rounded-xl bg-slate-900 my-4 shadow-sm">
                        <div className="flex px-4 py-2 bg-slate-800/80 text-slate-400 text-xs font-mono font-medium border-b border-slate-700/50">
                          {match[1]}
                        </div>
                        <pre className="p-4 overflow-x-auto text-slate-50 text-sm font-mono leading-relaxed">
                          <code className={className} {...props}>
                            {children}
                          </code>
                        </pre>
                      </div>
                    ) : (
                      <code className="bg-slate-100 text-primary-purple px-1.5 py-0.5 rounded-md text-[13px] font-mono font-medium border border-slate-200" {...props}>
                        {children}
                      </code>
                    )
                  }
                }}
              >
                {active?.content}
              </ReactMarkdown>
            </div>
            <Button
              variant="outline"
              onClick={() => void navigator.clipboard.writeText(`${window.location.origin}/student/knowledge-brain?id=${active?.id}`)}
              className="mt-7 self-start rounded-xl text-xs font-black shadow-sm"
            >
              <Copy className="h-3.5 w-3.5 mr-2" />
              Copy share link
            </Button>
          </div>
        </DialogContent>
      </Dialog>

      <SubmitArticleModal isOpen={submitOpen} onClose={() => setSubmitOpen(false)} onSuccess={() => void load()} />
    </div>
  )
}

export default function KnowledgeBrainPage() {
  return (
    <Suspense
      fallback={
        <div className="grid min-h-64 place-items-center">
          <Loader2 className="h-6 w-6 animate-spin text-primary-purple" />
        </div>
      }
    >
      <KnowledgeBrainContent />
    </Suspense>
  )
}
