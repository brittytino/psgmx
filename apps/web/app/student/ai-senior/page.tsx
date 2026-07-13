'use client';

import React, { useState, useRef, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { BrainCircuit, Send, ChevronRight, BookOpen, Cpu, Award, Building2, MessageSquare, Sparkles, X } from 'lucide-react';

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

export default function AISeniorPage() {
  const [messages, setMessages] = useState<Message[]>([
    {
      role: 'ai',
      content: "Hi! I'm the AI Senior — I know everything that happened in this department's placement history. Ask me anything about preparation, specific companies, or how to boost your readiness score. My answers are grounded in real experiences from your seniors.",
      sources: [],
    },
  ]);
  const [input, setInput] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [activeTopic, setActiveTopic] = useState('All');
  const bottomRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const sendMessage = async (text?: string) => {
    const query = text || input.trim();
    if (!query) return;
    setInput('');
    setMessages(prev => [...prev, { role: 'user', content: query }]);
    setIsLoading(true);
    try {
      const res = await fetch('/api/ai-senior', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ query }) });
      const data = await res.json();
      setMessages(prev => [...prev, { role: 'ai', content: data.success ? data.answer : 'Sorry, I encountered an error connecting to the Knowledge Brain. Please try again.', sources: data.sources || [] }]);
    } catch {
      setMessages(prev => [...prev, { role: 'ai', content: 'Connection failed. Please check your internet and try again.' }]);
    } finally {
      setIsLoading(false);
    }
  };

  const clearChat = () => {
    setMessages([{ role: 'ai', content: "Hi! I'm the AI Senior — ready to help. What would you like to know?", sources: [] }]);
  };

  return (
    <div className="max-w-[1400px] mx-auto h-full flex flex-col pb-4">

      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-[24px] font-black text-text-main tracking-tight flex items-center gap-2">
            <BrainCircuit className="w-6 h-6 text-primary-purple" /> AI Senior
          </h1>
          <p className="text-[13px] text-text-muted mt-0.5">Grounded in real placement experience from MCA Department alumni.</p>
        </div>
        <button onClick={clearChat} className="flex items-center gap-2 px-4 py-2 bg-white border border-border-light rounded-xl text-[13px] font-bold text-text-muted hover:bg-page-bg transition-colors">
          <X className="w-4 h-4" /> Clear Chat
        </button>
      </div>

      <div className="flex gap-6 flex-1 min-h-0">

        {/* Chat Panel (2/3) */}
        <div className="flex-1 flex flex-col bg-white rounded-[20px] border border-border-light shadow-[0_2px_12px_rgba(0,0,0,0.02)] min-h-0">

          {/* Messages */}
          <div className="flex-1 overflow-y-auto p-6 space-y-4 custom-scrollbar">
            <AnimatePresence initial={false}>
              {messages.map((msg, i) => (
                <motion.div
                  key={i}
                  initial={{ opacity: 0, y: 12 }}
                  animate={{ opacity: 1, y: 0 }}
                  className={`flex gap-3 ${msg.role === 'user' ? 'justify-end' : 'justify-start'}`}
                >
                  {msg.role === 'ai' && (
                    <div className="w-8 h-8 rounded-full bg-gradient-to-br from-primary-purple to-deep-violet flex items-center justify-center shrink-0 shadow-sm mt-1">
                      <Sparkles className="w-4 h-4 text-white" />
                    </div>
                  )}
                  <div className={`max-w-[75%] ${msg.role === 'user' ? 'order-first' : ''}`}>
                    <div className={`px-5 py-4 rounded-2xl text-[14px] leading-relaxed ${
                      msg.role === 'user'
                        ? 'bg-primary-purple text-white rounded-tr-sm font-semibold'
                        : 'bg-page-bg text-text-main rounded-tl-sm border-l-4 border-primary-purple'
                    }`}>
                      {msg.content}
                    </div>
                    {msg.role === 'ai' && msg.sources && msg.sources.length > 0 && (
                      <div className="flex flex-wrap gap-1.5 mt-2">
                        {msg.sources.map((s, si) => (
                          <span key={si} className="text-[10px] font-bold bg-white border border-border-light text-text-muted px-2 py-0.5 rounded-full">
                            📄 {s}
                          </span>
                        ))}
                      </div>
                    )}
                    {msg.role === 'ai' && (
                      <p className="text-[10px] text-text-muted mt-1 ml-1">Sourced from Knowledge Brain</p>
                    )}
                  </div>
                </motion.div>
              ))}
            </AnimatePresence>
            {isLoading && (
              <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="flex gap-3 items-start">
                <div className="w-8 h-8 rounded-full bg-gradient-to-br from-primary-purple to-deep-violet flex items-center justify-center shrink-0 shadow-sm">
                  <Sparkles className="w-4 h-4 text-white" />
                </div>
                <div className="px-5 py-4 bg-page-bg rounded-2xl rounded-tl-sm border-l-4 border-primary-purple">
                  <div className="flex gap-1.5 items-center">
                    <div className="w-2 h-2 bg-primary-purple rounded-full animate-bounce" style={{ animationDelay: '0ms' }} />
                    <div className="w-2 h-2 bg-primary-purple rounded-full animate-bounce" style={{ animationDelay: '150ms' }} />
                    <div className="w-2 h-2 bg-primary-purple rounded-full animate-bounce" style={{ animationDelay: '300ms' }} />
                    <span className="text-[12px] text-text-muted ml-2">Searching the Knowledge Brain...</span>
                  </div>
                </div>
              </motion.div>
            )}
            <div ref={bottomRef} />
          </div>

          {/* Input Bar */}
          <div className="p-4 border-t border-border-light">
            <div className="flex gap-3 items-end">
              <textarea
                value={input}
                onChange={(e) => setInput(e.target.value)}
                onKeyDown={(e) => { if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); sendMessage(); } }}
                placeholder="Ask the AI Senior anything about placements, companies, or preparation..."
                rows={2}
                className="flex-1 bg-page-bg border border-border-light rounded-xl px-4 py-3 text-[14px] text-text-main placeholder-text-muted outline-none focus:border-primary-purple transition-colors resize-none"
              />
              <button
                onClick={() => sendMessage()}
                disabled={isLoading || !input.trim()}
                className="p-3.5 bg-primary-purple hover:bg-deep-violet disabled:opacity-50 text-white rounded-xl transition-colors shrink-0"
              >
                <Send className="w-5 h-5" />
              </button>
            </div>
          </div>
        </div>

        {/* Sidebar (1/3) */}
        <div className="w-80 shrink-0 space-y-5 overflow-y-auto custom-scrollbar">

          {/* Suggested Questions */}
          <div className="bg-white rounded-[20px] border border-border-light shadow-[0_2px_12px_rgba(0,0,0,0.02)] p-5">
            <h3 className="text-[14px] font-bold text-text-main mb-4 flex items-center gap-2">
              <MessageSquare className="w-4 h-4 text-primary-purple" /> Suggested Questions
            </h3>
            <div className="space-y-2">
              {suggestedQuestions.map((q, i) => (
                <button
                  key={i}
                  onClick={() => sendMessage(q)}
                  className="w-full text-left px-4 py-3 bg-page-bg hover:bg-border-light rounded-xl text-[13px] font-semibold text-text-main transition-colors flex items-center gap-2 group"
                >
                  <ChevronRight className="w-3.5 h-3.5 text-primary-purple shrink-0 group-hover:translate-x-0.5 transition-transform" />
                  {q}
                </button>
              ))}
            </div>
          </div>

          {/* Topic Filters */}
          <div className="bg-white rounded-[20px] border border-border-light shadow-[0_2px_12px_rgba(0,0,0,0.02)] p-5">
            <h3 className="text-[14px] font-bold text-text-main mb-3 flex items-center gap-2">
              <Cpu className="w-4 h-4 text-primary-purple" /> Filter by Topic
            </h3>
            <div className="flex flex-wrap gap-2">
              {topicFilters.map((t) => (
                <button
                  key={t}
                  onClick={() => setActiveTopic(t)}
                  className={`px-3 py-1.5 rounded-full text-[12px] font-bold transition-colors ${
                    activeTopic === t ? 'bg-primary-purple text-white' : 'bg-page-bg text-text-muted hover:bg-border-light'
                  }`}
                >
                  {t}
                </button>
              ))}
            </div>
          </div>

          {/* Knowledge Brain Stats */}
          <div className="bg-white rounded-[20px] border border-border-light shadow-[0_2px_12px_rgba(0,0,0,0.02)] p-5">
            <h3 className="text-[14px] font-bold text-text-main mb-4 flex items-center gap-2">
              <BookOpen className="w-4 h-4 text-primary-purple" /> Knowledge Brain
            </h3>
            <div className="space-y-3">
              {[
                { label: 'Articles Indexed', value: '147', icon: BookOpen },
                { label: 'Placement Experiences', value: '83', icon: Building2 },
                { label: 'Alumni Contributors', value: '31', icon: Award },
              ].map((stat, i) => (
                <div key={i} className="flex items-center justify-between p-3 bg-page-bg rounded-xl">
                  <div className="flex items-center gap-2">
                    <stat.icon className="w-4 h-4 text-primary-purple" />
                    <span className="text-[12px] font-semibold text-text-muted">{stat.label}</span>
                  </div>
                  <span className="text-[14px] font-black text-text-main">{stat.value}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
