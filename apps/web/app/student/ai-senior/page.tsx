'use client';

import React, { useState, useRef, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import { BrainCircuit, Send, ChevronRight, BookOpen, Cpu, Award, Building2, MessageSquare, Sparkles, X, Bot } from 'lucide-react';

const suggestedQuestions = [
  'Which companies usually visit MCA for placements?',
  "What is Zoho's typical interview process?",
  'How do I improve my readiness score quickly?',
  'What DSA topics appear most in TCS Digital tests?',
  'How should I prepare for HR interviews?',
  'What makes a strong FYP project for placements?',
];

const topicFilters = ['All', 'DSA', 'Aptitude', 'Company-Specific', 'FYP', 'General'];

type Message = { role: 'user' | 'ai'; content: string; sources?: string[] };
type KnowledgeStats = { articles: number; interview_patterns: number; alumni_contributors: number };

const WELCOME: Message = {
  role: 'ai',
  content: "Hi, I'm **AI Senior**. I use your current preparation evidence and approved Knowledge Brain material.\n\nAsk me what to practice next, or ask about historical interview patterns at PSG Tech! Official drive announcements stay synchronized in NEO PAT.",
  sources: [],
};

export default function AISeniorPage() {
  const [messages, setMessages] = useState<Message[]>([WELCOME]);
  const [conversationId, setConversationId] = useState<string | null>(null);
  const [stats, setStats] = useState<KnowledgeStats>({ articles: 0, interview_patterns: 0, alumni_contributors: 0 });
  const [input, setInput] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [activeTopic, setActiveTopic] = useState('All');
  const bottomRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  useEffect(() => {
    const stored = window.sessionStorage.getItem('psgmx_ai_conversation');
    const url = stored ? `/api/ai-senior?conversation_id=${encodeURIComponent(stored)}` : '/api/ai-senior';
    fetch(url).then(async (response) => {
      if (!response.ok) throw new Error('History unavailable');
      const data = await response.json();
      setStats(data.knowledge_stats || { articles: 0, interview_patterns: 0, alumni_contributors: 0 });
      if (data.conversation_id) {
        setConversationId(data.conversation_id);
        const history = (data.messages || []).map((message: { role: string; content: string }) => ({
          role: message.role === 'assistant' ? 'ai' as const : 'user' as const,
          content: message.content,
        }));
        if (history.length) setMessages([WELCOME, ...history]);
      }
    }).catch(() => {});
  }, []);

  const sendMessage = async (text?: string) => {
    const query = text || input.trim();
    if (!query) return;
    setInput('');
    setMessages(prev => [...prev, { role: 'user', content: query }]);
    setIsLoading(true);
    try {
      const res = await fetch('/api/ai-senior', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ query, conversation_id: conversationId }) });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error || 'The AI Senior could not answer right now.');
      if (data.conversation_id) {
        setConversationId(data.conversation_id);
        window.sessionStorage.setItem('psgmx_ai_conversation', data.conversation_id);
      }
      setMessages(prev => [...prev, { role: 'ai', content: data.answer, sources: data.sources || [] }]);
    } catch (error) {
      setMessages(prev => [...prev, { role: 'ai', content: error instanceof Error ? error.message : 'Connection failed. Please try again.' }]);
    } finally {
      setIsLoading(false);
    }
  };

  const clearChat = () => {
    window.sessionStorage.removeItem('psgmx_ai_conversation');
    setConversationId(null);
    setMessages([WELCOME]);
  };

  return (
    <div className="max-w-[1400px] mx-auto h-full flex flex-col pb-4">

      {/* Header */}
      <div className="flex items-center justify-between mb-5 shrink-0">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-[#FAF5EE] border border-[#EAE3D6] flex items-center justify-center p-1.5 shadow-2xs">
            <img src="/logo.png" alt="AI Senior Mascot" className="w-full h-full object-contain" />
          </div>
          <div>
            <h1 className="text-xl font-black text-[#1A1A1A] tracking-tight flex items-center gap-2">
              AI Senior
              <span className="text-[10px] font-bold uppercase tracking-wider bg-[#FF6B4A]/10 text-[#FF6B4A] px-2 py-0.5 rounded-full">
                Placement Mentor
              </span>
            </h1>
            <p className="text-[12px] font-medium text-[#706E6B]">
              Grounded in real placement experience from MCA Department alumni.
            </p>
          </div>
        </div>
        <button
          onClick={clearChat}
          className="flex items-center gap-2 px-3.5 py-2 bg-white hover:bg-[#FAF6F0] border border-[#EFE9E0] rounded-xl text-xs font-bold text-[#706E6B] hover:text-[#1A1A1A] transition-colors cursor-pointer shadow-2xs"
        >
          <X className="w-3.5 h-3.5" /> Clear Chat
        </button>
      </div>

      <div className="flex flex-1 min-h-0 flex-col gap-6 xl:flex-row">

        {/* Chat Panel (2/3) */}
        <div className="flex-1 flex flex-col bg-white rounded-[22px] border border-[#EFE9E0] shadow-[0_2px_12px_rgba(0,0,0,0.02)] min-h-0 overflow-hidden">

          {/* Messages */}
          <div className="flex-1 overflow-y-auto p-6 space-y-5 custom-scrollbar">
            <AnimatePresence initial={false}>
              {messages.map((msg, i) => (
                <motion.div
                  key={i}
                  initial={{ opacity: 0, y: 12 }}
                  animate={{ opacity: 1, y: 0 }}
                  className={`flex gap-3 ${msg.role === 'user' ? 'justify-end' : 'justify-start'}`}
                >
                  {msg.role === 'ai' && (
                    <div className="w-8 h-8 rounded-full bg-[#FAF5EE] border border-[#EAE3D6] flex items-center justify-center shrink-0 shadow-2xs mt-1 p-1">
                      <img src="/logo.png" alt="AI Senior" className="w-full h-full object-contain" />
                    </div>
                  )}
                  <div className={`max-w-[82%] ${msg.role === 'user' ? 'order-first' : ''}`}>
                    <div className={`px-5 py-4 rounded-2xl text-[14px] leading-relaxed shadow-2xs ${
                      msg.role === 'user'
                        ? 'bg-[#FF6B4A] text-white rounded-tr-xs font-semibold'
                        : 'bg-[#FBF6EE] text-[#1A1A1A] rounded-tl-xs border-l-4 border-[#FF6B4A] border-t border-r border-b border-[#EFE9E0]'
                    }`}>
                      {msg.role === 'user' ? (
                        <p className="whitespace-pre-wrap">{msg.content}</p>
                      ) : (
                        <div className="prose prose-sm max-w-none text-[13.5px] leading-relaxed text-[#1A1A1A]">
                          <ReactMarkdown
                            remarkPlugins={[remarkGfm]}
                            components={{
                              h1: ({ children }) => <h1 className="text-base font-black text-[#1A1A1A] mt-3 mb-1.5">{children}</h1>,
                              h2: ({ children }) => <h2 className="text-sm font-black text-[#1A1A1A] mt-3 mb-1.5">{children}</h2>,
                              h3: ({ children }) => <h3 className="text-xs font-black text-[#1A1A1A] mt-2 mb-1 uppercase tracking-wider">{children}</h3>,
                              p: ({ children }) => <p className="mb-2.5 last:mb-0 leading-relaxed">{children}</p>,
                              ul: ({ children }) => <ul className="list-disc pl-5 my-2 space-y-1">{children}</ul>,
                              ol: ({ children }) => <ol className="list-decimal pl-5 my-2 space-y-1">{children}</ol>,
                              li: ({ children }) => <li className="text-[13px] leading-relaxed">{children}</li>,
                              strong: ({ children }) => <strong className="font-bold text-[#1A1A1A]">{children}</strong>,
                              code: ({ children }) => <code className="px-1.5 py-0.5 rounded bg-white border border-[#EAE3D6] text-xs font-mono text-[#D9532F]">{children}</code>,
                            }}
                          >
                            {msg.content}
                          </ReactMarkdown>
                        </div>
                      )}
                    </div>
                    {msg.role === 'ai' && msg.sources && msg.sources.length > 0 && (
                      <div className="flex flex-wrap gap-1.5 mt-2">
                        {msg.sources.map((s, si) => (
                          <span key={si} className="text-[10px] font-bold bg-white border border-[#EFE9E0] text-[#706E6B] px-2 py-0.5 rounded-full shadow-2xs">
                            📄 {s}
                          </span>
                        ))}
                      </div>
                    )}
                    {msg.role === 'ai' && msg.sources && msg.sources.length > 0 && (
                      <p className="text-[10px] text-[#8C877E] mt-1 ml-1 font-medium">Grounded in approved Knowledge Brain sources</p>
                    )}
                  </div>
                </motion.div>
              ))}
            </AnimatePresence>
            {isLoading && (
              <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="flex gap-3 items-start">
                <div className="w-8 h-8 rounded-full bg-[#FAF5EE] border border-[#EAE3D6] flex items-center justify-center shrink-0 shadow-2xs p-1">
                  <img src="/logo.png" alt="AI Senior" className="w-full h-full object-contain animate-pulse" />
                </div>
                <div className="px-5 py-4 bg-[#FBF6EE] rounded-2xl rounded-tl-xs border-l-4 border-[#FF6B4A] border-t border-r border-b border-[#EFE9E0] shadow-2xs">
                  <div className="flex gap-1.5 items-center">
                    <div className="w-2 h-2 bg-[#FF6B4A] rounded-full animate-bounce" style={{ animationDelay: '0ms' }} />
                    <div className="w-2 h-2 bg-[#FF6B4A] rounded-full animate-bounce" style={{ animationDelay: '150ms' }} />
                    <div className="w-2 h-2 bg-[#FF6B4A] rounded-full animate-bounce" style={{ animationDelay: '300ms' }} />
                    <span className="text-[12px] font-medium text-[#706E6B] ml-2">Searching the Knowledge Brain...</span>
                  </div>
                </div>
              </motion.div>
            )}
            <div ref={bottomRef} />
          </div>

          {/* Input Bar */}
          <div className="p-4 border-t border-[#EFE9E0] bg-[#FAF6F0]/50">
            <div className="flex gap-3 items-end">
              <textarea
                value={input}
                onChange={(e) => setInput(e.target.value)}
                onKeyDown={(e) => { if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); sendMessage(); } }}
                placeholder="Ask the AI Senior anything about placements, companies, or preparation..."
                rows={2}
                className="flex-1 bg-white border border-[#EFE9E0] focus:border-[#FF6B4A] rounded-xl px-4 py-3 text-[13.5px] text-[#1A1A1A] placeholder-[#8C877E] outline-none transition-colors resize-none shadow-2xs"
              />
              <button
                onClick={() => sendMessage()}
                disabled={isLoading || !input.trim()}
                className="p-3.5 bg-[#FF6B4A] hover:bg-[#E4572E] disabled:opacity-40 text-white rounded-xl transition-all shrink-0 cursor-pointer shadow-xs disabled:cursor-not-allowed"
              >
                <Send className="w-4 h-4" />
              </button>
            </div>
          </div>
        </div>

        {/* Sidebar (1/3) */}
        <div className="w-full shrink-0 space-y-5 overflow-y-auto custom-scrollbar xl:w-80">

          {/* Suggested Questions */}
          <div className="bg-white rounded-[22px] border border-[#EFE9E0] shadow-[0_2px_12px_rgba(0,0,0,0.02)] p-5">
            <h3 className="text-[13px] font-black uppercase tracking-wider text-[#1A1A1A] mb-3.5 flex items-center gap-2">
              <MessageSquare className="w-4 h-4 text-[#FF6B4A]" /> Suggested Questions
            </h3>
            <div className="space-y-2">
              {suggestedQuestions.map((q, i) => (
                <button
                  key={i}
                  onClick={() => sendMessage(q)}
                  className="w-full text-left px-3.5 py-3 bg-[#FAF6F0] hover:bg-[#F5EFE6] border border-[#F0EAE0] hover:border-[#E5DDD0] rounded-xl text-[12.5px] font-semibold text-[#1A1A1A] transition-all flex items-center gap-2.5 group cursor-pointer shadow-2xs"
                >
                  <ChevronRight className="w-3.5 h-3.5 text-[#FF6B4A] shrink-0 group-hover:translate-x-0.5 transition-transform" />
                  <span className="leading-snug">{q}</span>
                </button>
              ))}
            </div>
          </div>

          {/* Topic Filters */}
          <div className="bg-white rounded-[22px] border border-[#EFE9E0] shadow-[0_2px_12px_rgba(0,0,0,0.02)] p-5">
            <h3 className="text-[13px] font-black uppercase tracking-wider text-[#1A1A1A] mb-3 flex items-center gap-2">
              <Cpu className="w-4 h-4 text-[#FF6B4A]" /> Filter by Topic
            </h3>
            <div className="flex flex-wrap gap-2">
              {topicFilters.map((t) => (
                <button
                  key={t}
                  onClick={() => setActiveTopic(t)}
                  className={`px-3 py-1.5 rounded-full text-[12px] font-bold transition-all cursor-pointer ${
                    activeTopic === t
                      ? 'bg-[#FF6B4A] text-white shadow-xs'
                      : 'bg-[#FAF6F0] border border-[#EFE9E0] text-[#706E6B] hover:text-[#1A1A1A] hover:bg-[#F5EFE6]'
                  }`}
                >
                  {t}
                </button>
              ))}
            </div>
          </div>

          {/* Knowledge Brain Stats */}
          <div className="bg-white rounded-[22px] border border-[#EFE9E0] shadow-[0_2px_12px_rgba(0,0,0,0.02)] p-5">
            <h3 className="text-[13px] font-black uppercase tracking-wider text-[#1A1A1A] mb-3.5 flex items-center gap-2">
              <BookOpen className="w-4 h-4 text-[#FF6B4A]" /> Knowledge Brain
            </h3>
            <div className="space-y-2.5">
              {[
                { label: 'Approved Articles', value: stats.articles, icon: BookOpen },
                { label: 'Interview Patterns', value: stats.interview_patterns, icon: Building2 },
                { label: 'Alumni Contributors', value: stats.alumni_contributors, icon: Award },
              ].map((stat, i) => (
                <div key={i} className="flex items-center justify-between p-3 bg-[#FAF6F0] border border-[#EFE9E0] rounded-xl shadow-2xs">
                  <div className="flex items-center gap-2.5">
                    <stat.icon className="w-4 h-4 text-[#FF6B4A]" />
                    <span className="text-[12px] font-semibold text-[#706E6B]">{stat.label}</span>
                  </div>
                  <span className="text-[14px] font-black text-[#1A1A1A]">{stat.value}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
