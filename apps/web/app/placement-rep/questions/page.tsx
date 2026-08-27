'use client'

import React from 'react'
import { LibraryBig, Plus, Power, Search } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { getCurrentProfile } from '@/lib/current-profile'

type Question = { id: string; question_text: string; options: unknown[]; correct_option: number; topic: string; difficulty: string; is_active: boolean }

export default function QuestionsPage() {
  const supabase = React.useMemo(() => createClient(), [])
  const [actorId, setActorId] = React.useState('')
  const [questions, setQuestions] = React.useState<Question[]>([])
  const [query, setQuery] = React.useState('')
  const [message, setMessage] = React.useState('')
  const [form, setForm] = React.useState({ question_text: '', option0: '', option1: '', option2: '', option3: '', correct_option: 0, topic: 'dsa', difficulty: 'easy' })

  const load = React.useCallback(async () => {
    const me = await getCurrentProfile(supabase); if (me) setActorId(me.id)
    const { data, error } = await supabase.rpc('get_question_bank_full')
    if (error) setMessage(error.message)
    setQuestions((data ?? []) as Question[])
  }, [supabase])
  React.useEffect(() => { void load() }, [load])

  async function add(event: React.FormEvent) {
    event.preventDefault()
    const options = [form.option0, form.option1, form.option2, form.option3].map((item) => item.trim())
    if (options.some((item) => !item)) return setMessage('All four options are required.')
    const { error } = await supabase.from('question_bank').insert({ question_text: form.question_text.trim(), options, correct_option: form.correct_option, topic: form.topic.trim().toLowerCase(), difficulty: form.difficulty, created_by: actorId })
    setMessage(error ? error.message : 'Question added to Daily Five.')
    if (!error) { setForm({ question_text: '', option0: '', option1: '', option2: '', option3: '', correct_option: 0, topic: 'dsa', difficulty: 'easy' }); await load() }
  }

  async function toggle(question: Question) { await supabase.from('question_bank').update({ is_active: !question.is_active }).eq('id', question.id); await load() }
  const filtered = questions.filter((q) => `${q.question_text} ${q.topic}`.toLowerCase().includes(query.toLowerCase()))

  return <div className="max-w-6xl space-y-6">
    <div><h1 className="text-2xl font-black">Daily Five Question Bank</h1><p className="mt-1 text-sm text-text-muted">Curate useful questions; answer keys remain protected from student clients.</p></div>
    <form onSubmit={add} className="grid gap-4 rounded-2xl border border-border-light bg-white p-5 sm:grid-cols-2">
      <textarea required value={form.question_text} onChange={(e) => setForm({ ...form, question_text: e.target.value })} placeholder="Question" className="min-h-24 rounded-xl border border-border-light px-4 py-3 text-sm sm:col-span-2" />
      {[0,1,2,3].map((index) => <input key={index} required value={form[`option${index}` as keyof typeof form] as string} onChange={(e) => setForm({ ...form, [`option${index}`]: e.target.value })} placeholder={`Option ${index + 1}`} className="rounded-xl border border-border-light px-4 py-3 text-sm" />)}
      <input required value={form.topic} onChange={(e) => setForm({ ...form, topic: e.target.value })} placeholder="Topic" className="rounded-xl border border-border-light px-4 py-3 text-sm" />
      <div className="grid grid-cols-2 gap-3"><select value={form.difficulty} onChange={(e) => setForm({ ...form, difficulty: e.target.value })} className="rounded-xl border border-border-light px-3 py-3 text-sm"><option>easy</option><option>medium</option><option>hard</option></select><select value={form.correct_option} onChange={(e) => setForm({ ...form, correct_option: Number(e.target.value) })} className="rounded-xl border border-border-light px-3 py-3 text-sm">{[0,1,2,3].map((i) => <option key={i} value={i}>Answer {i + 1}</option>)}</select></div>
      <div className="flex items-center justify-between sm:col-span-2"><p className="text-sm text-text-muted">{message}</p><button className="flex items-center gap-2 rounded-xl bg-primary-purple px-5 py-3 text-sm font-bold text-white"><Plus className="h-4 w-4" />Add question</button></div>
    </form>
    <div className="relative max-w-md"><Search className="absolute left-3 top-3 h-4 w-4 text-text-muted" /><input value={query} onChange={(e) => setQuery(e.target.value)} placeholder="Search questions or topics" className="w-full rounded-xl border border-border-light bg-white py-2.5 pl-10 pr-4 text-sm" /></div>
    <div className="space-y-3">{filtered.slice(0, 100).map((question) => <div key={question.id} className={`rounded-2xl border bg-white p-5 ${question.is_active ? 'border-border-light' : 'border-dashed border-gray-300 opacity-60'}`}><div className="flex gap-3"><LibraryBig className="mt-0.5 h-5 w-5 shrink-0 text-primary-purple" /><div className="flex-1"><p className="font-bold">{question.question_text}</p><p className="mt-1 text-xs text-text-muted">{question.topic} · {question.difficulty} · answer {question.correct_option + 1}</p></div><button onClick={() => toggle(question)} title={question.is_active ? 'Deactivate' : 'Activate'} className="rounded-lg p-2 text-text-muted hover:bg-page-bg"><Power className="h-4 w-4" /></button></div></div>)}</div>
  </div>
}
