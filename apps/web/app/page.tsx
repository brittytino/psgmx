'use client';

import { useState, useRef, useEffect } from 'react';
import Link from 'next/link';

// --- Types ---
type Message = { id: string; role: 'user' | 'bot'; text: string; isStreaming?: boolean };
type ChatSession = { id: string; title: string; messages: Message[]; updatedAt: number };

// --- Constants ---
const SUGGESTIONS = [
  "Tell me about the AI Mentor",
  "How does Codebox work?",
  "What is the Daily Five?",
  "How do I install the app?"
];

// --- Helper: Bot Logic ---
function generateResponse(text: string): string {
  const lower = text.toLowerCase();
  if (lower.includes('download') || lower.includes('apk') || lower.includes('android') || lower.includes('install')) {
    return "You can experience the full power of PSGMX by downloading our native Android app. It includes all features like the AI Mentor, Codebox, and Placement Tracking. \n\nYou can download the latest APK directly from our GitHub repository: https://github.com/brittytino/psgmx/releases\n\nIf you're on iOS, you can easily install the Web App by opening app.psgmx.tech in Safari, tapping the Share icon, and selecting 'Add to Home Screen'.";
  }
  if (lower.includes('ios') || lower.includes('iphone') || lower.includes('apple') || lower.includes('mac')) {
    return "While we don't have a native App Store app yet, iOS users get a first-class PWA experience! \n\nJust open **app.psgmx.tech** in Safari, tap the Share icon at the bottom, and select **'Add to Home Screen'**. It will function exactly like a native app with full audio recording and offline support.";
  }
  if (lower.includes('ai') || lower.includes('mentor') || lower.includes('interview')) {
    return "The **AI Mentor** is your personal interview coach. You can practice Technical, HR, and Communication interviews using real-time audio.\n\nThe AI listens to your voice responses, transcribes them, and provides incredibly detailed feedback, scoring, and suggestions for improvement just like a real recruiter would.";
  }
  if (lower.includes('codebox') || lower.includes('code') || lower.includes('programming') || lower.includes('dsa')) {
    return "**Codebox** is our built-in IDE where you can practice Data Structures and Algorithms. \n\nIt supports multiple languages (C, C++, Java, Python, Dart) and automatically evaluates your code against hidden test cases. It tracks your problem-solving speed and accuracy to prepare you for technical coding rounds.";
  }
  if (lower.includes('daily five') || lower.includes('daily') || lower.includes('five')) {
    return "The **Daily Five** is a micro-learning feature designed for consistency. \n\nEvery day, you receive exactly 5 curated questions covering Aptitude, Core Subjects, and Coding logic. It ensures you stay sharp with your placement preparation every single day without feeling overwhelmed.";
  }
  if (lower.includes('what is') || lower.includes('about') || lower.includes('psgmx')) {
    return "PSGMX is the ultimate **Placement Operating System** built exclusively for PSG Tech MCA students. \n\nWe provide a completely unified platform to track, prepare, and collaborate for placements. Key features include the AI Mentor, Codebox, Daily Five, and an extensive Placement Rep Dashboard for analytics.";
  }
  return "That's a great question! PSGMX is a comprehensive Placement Operating System with many features including the AI Mentor, Codebox, and Daily Five. \n\nTo see it in action, I highly recommend logging into the dashboard or downloading the Android app. Can I help you with information about a specific feature?";
}

export default function LandingPage() {
  // --- State ---
  const [chats, setChats] = useState<ChatSession[]>([]);
  const [activeChatId, setActiveChatId] = useState<string | null>(null);
  const [query, setQuery] = useState('');
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);
  const [isTyping, setIsTyping] = useState(false);
  
  // Modals / Dropdowns
  const [activeMenuId, setActiveMenuId] = useState<string | null>(null);
  const [deleteModal, setDeleteModal] = useState<string | null>(null); // chat ID to delete
  const [renameModal, setRenameModal] = useState<string | null>(null); // chat ID to rename
  const [renameValue, setRenameValue] = useState('');

  // Refs
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const textareaRef = useRef<HTMLTextAreaElement>(null);

  // --- Initialization & Local Storage ---
  useEffect(() => {
    const saved = localStorage.getItem('psgmx_landing_chats');
    if (saved) {
      try {
        const parsed = JSON.parse(saved);
        if (parsed && parsed.length > 0) {
          setChats(parsed);
          setActiveChatId(parsed[0].id);
        } else {
          createNewChat();
        }
      } catch (e) {
        createNewChat();
      }
    } else {
      createNewChat();
    }
    
    // Auto-open sidebar on desktop
    if (window.innerWidth >= 768) {
      setIsSidebarOpen(true);
    }
  }, []);

  useEffect(() => {
    if (chats.length > 0) {
      localStorage.setItem('psgmx_landing_chats', JSON.stringify(chats));
    } else if (chats.length === 0 && activeChatId) {
      localStorage.removeItem('psgmx_landing_chats');
    }
  }, [chats]);

  // --- Derived State ---
  const activeChat = chats.find(c => c.id === activeChatId);
  const messages = activeChat?.messages || [];

  // --- Scroll & Resize ---
  useEffect(() => {
    if (messagesEndRef.current) {
      messagesEndRef.current.scrollIntoView({ behavior: "smooth" });
    }
  }, [messages, isTyping]);

  const adjustTextareaHeight = () => {
    if (textareaRef.current) {
      textareaRef.current.style.height = 'auto';
      textareaRef.current.style.height = `${Math.min(textareaRef.current.scrollHeight, 200)}px`;
    }
  };

  // --- Actions ---
  const createNewChat = () => {
    const newId = crypto.randomUUID();
    const newChat: ChatSession = { id: newId, title: "New Chat", messages: [], updatedAt: Date.now() };
    setChats(prev => [newChat, ...prev]);
    setActiveChatId(newId);
    if (window.innerWidth < 768) setIsSidebarOpen(false);
    if (textareaRef.current) {
      textareaRef.current.style.height = 'auto';
      textareaRef.current.focus();
    }
  };

  const updateActiveChat = (newMessages: Message[], newTitle?: string) => {
    setChats(prev => prev.map(c => {
      if (c.id === activeChatId) {
        return {
          ...c,
          messages: newMessages,
          title: newTitle || c.title,
          updatedAt: Date.now()
        };
      }
      return c;
    }).sort((a, b) => b.updatedAt - a.updatedAt));
  };

  const simulateStream = (fullText: string, chatId: string) => {
    setIsTyping(false);
    const words = fullText.split(' ');
    let currentText = '';
    const msgId = crypto.randomUUID();
    
    setChats(prev => prev.map(c => {
      if (c.id === chatId) return { ...c, messages: [...c.messages, { id: msgId, role: 'bot', text: '', isStreaming: true }] };
      return c;
    }));

    let i = 0;
    const interval = setInterval(() => {
      if (i < words.length) {
        currentText += (i === 0 ? '' : ' ') + words[i];
        setChats(prev => prev.map(c => {
          if (c.id === chatId) {
            return {
              ...c,
              messages: c.messages.map(m => m.id === msgId ? { ...m, text: currentText } : m)
            };
          }
          return c;
        }));
        i++;
      } else {
        clearInterval(interval);
        setChats(prev => prev.map(c => {
          if (c.id === chatId) {
            return {
              ...c,
              messages: c.messages.map(m => m.id === msgId ? { ...m, isStreaming: false } : m)
            };
          }
          return c;
        }));
      }
    }, 45);
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSend(query);
    }
  };

  const handleSend = (text: string) => {
    if (!text.trim() || !activeChatId) return;
    
    const userMsg: Message = { id: crypto.randomUUID(), role: 'user', text };
    const isFirstMessage = messages.length === 0;
    const newTitle = isFirstMessage ? text.split(' ').slice(0, 4).join(' ') + (text.split(' ').length > 4 ? '...' : '') : undefined;
    
    updateActiveChat([...messages, userMsg], newTitle);
    setQuery('');
    if (textareaRef.current) textareaRef.current.style.height = 'auto';

    setIsTyping(true);
    const capturedChatId = activeChatId;

    setTimeout(() => {
      const response = generateResponse(text);
      simulateStream(response, capturedChatId);
    }, 1200 + Math.random() * 800);
  };

  // --- Chat Management ---
  const confirmDelete = () => {
    if (deleteModal) {
      const nextChats = chats.filter(c => c.id !== deleteModal);
      setChats(nextChats);
      if (activeChatId === deleteModal) {
        setActiveChatId(nextChats.length > 0 ? nextChats[0].id : null);
        if (nextChats.length === 0) createNewChat();
      }
    }
    setDeleteModal(null);
  };

  const confirmRename = () => {
    if (renameModal && renameValue.trim()) {
      setChats(prev => prev.map(c => c.id === renameModal ? { ...c, title: renameValue.trim() } : c));
    }
    setRenameModal(null);
  };

  return (
    <div className="flex h-[100dvh] w-full bg-[#FBF6EE] text-[#221F1A] font-sans overflow-hidden text-[15px]">
      
      {/* --- Modals --- */}
      {deleteModal && (
        <div className="fixed inset-0 z-[100] flex items-center justify-center bg-black/40 backdrop-blur-sm p-4 animate-in fade-in duration-200">
          <div className="bg-white rounded-2xl p-6 w-full max-w-sm shadow-xl border border-[#E8DFD1] animate-in zoom-in-95 duration-200">
            <h3 className="text-lg font-semibold mb-2">Delete chat?</h3>
            <p className="text-sm text-[#555] mb-6">This will permanently delete the chat history. Are you sure you want to proceed?</p>
            <div className="flex justify-end gap-3">
              <button onClick={() => setDeleteModal(null)} className="px-4 py-2 rounded-xl text-sm font-medium hover:bg-[#F5EDE1] transition-colors">Cancel</button>
              <button onClick={confirmDelete} className="px-4 py-2 rounded-xl text-sm font-medium bg-[#FF5A1F] text-white hover:bg-[#E04810] shadow-sm transition-colors">Delete</button>
            </div>
          </div>
        </div>
      )}

      {renameModal && (
        <div className="fixed inset-0 z-[100] flex items-center justify-center bg-black/40 backdrop-blur-sm p-4 animate-in fade-in duration-200">
          <div className="bg-white rounded-2xl p-6 w-full max-w-sm shadow-xl border border-[#E8DFD1] animate-in zoom-in-95 duration-200">
            <h3 className="text-lg font-semibold mb-4">Rename chat</h3>
            <input 
              autoFocus
              value={renameValue} 
              onChange={e => setRenameValue(e.target.value)} 
              onKeyDown={e => { if (e.key === 'Enter') confirmRename(); }}
              className="w-full px-4 py-3 bg-[#FBF6EE] border border-[#E8DFD1] rounded-xl outline-none focus:ring-2 ring-[#FF5A1F]/30 focus:border-[#FF5A1F] transition-all mb-6"
              placeholder="Enter new name..."
            />
            <div className="flex justify-end gap-3">
              <button onClick={() => setRenameModal(null)} className="px-4 py-2 rounded-xl text-sm font-medium hover:bg-[#F5EDE1] transition-colors">Cancel</button>
              <button onClick={confirmRename} className="px-4 py-2 rounded-xl text-sm font-medium bg-[#221F1A] text-white hover:bg-black shadow-sm transition-colors">Save</button>
            </div>
          </div>
        </div>
      )}
      
      {/* --- Sidebar Overlay (Mobile) --- */}
      <div 
        className={`fixed inset-0 bg-black/40 z-40 md:hidden transition-opacity duration-300 ${isSidebarOpen ? 'opacity-100' : 'opacity-0 pointer-events-none'}`} 
        onClick={() => setIsSidebarOpen(false)}
      />
      
      {/* --- Sidebar --- */}
      <div 
        className={`fixed md:relative z-50 h-full bg-[#F5EDE1] border-r border-[#EAE0D3] flex flex-col transition-all duration-300 ease-[cubic-bezier(0.16,1,0.3,1)] shrink-0 overflow-visible
          ${isSidebarOpen ? 'w-[280px] translate-x-0' : 'w-0 -translate-x-full md:translate-x-0 md:w-0'}
        `}
      >
        <div className="w-[280px] h-full flex flex-col p-3">
          {/* New Chat Button */}
          <div className="flex items-center justify-between mb-4">
            <button 
              onClick={createNewChat}
              className="flex-1 flex items-center gap-3 hover:bg-white px-3 py-2.5 rounded-xl shadow-sm border border-transparent hover:border-[#EAE0D3] transition-all font-semibold text-[14px]"
            >
              <div className="bg-white p-1 rounded-md shadow-sm border border-[#EAE0D3]">
                 <img src="/logo.png" alt="Logo" className="w-4 h-4 object-contain" />
              </div>
              New chat
            </button>
            <button onClick={() => setIsSidebarOpen(false)} className="p-2 ml-2 text-[#4A4A4C] hover:bg-white rounded-xl md:hidden">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M18 6L6 18M6 6l12 12"/></svg>
            </button>
          </div>
          
          {/* Chat History List */}
          <div className="flex-1 overflow-y-auto px-1 -mx-1" onClick={() => { if(activeMenuId) setActiveMenuId(null); }}>
            <div className="text-xs font-semibold text-[#8B8C8E] mb-3 px-3 uppercase tracking-wider">Recent History</div>
            
            <div className="space-y-1">
              {chats.map(chat => (
                <div key={chat.id} className="relative group">
                  <button 
                    onClick={() => { setActiveChatId(chat.id); if(window.innerWidth < 768) setIsSidebarOpen(false); }} 
                    className={`w-full text-left px-3 py-2.5 text-[14px] rounded-xl truncate transition-all pr-10
                      ${activeChatId === chat.id ? 'bg-[#EAE0D3] font-medium text-[#221F1A]' : 'text-[#4A4A4C] hover:bg-white/60'}
                    `}
                  >
                    {chat.title}
                  </button>
                  
                  {/* 3-dots menu button */}
                  <button 
                    onClick={(e) => { e.stopPropagation(); setActiveMenuId(activeMenuId === chat.id ? null : chat.id); }}
                    className={`absolute right-2 top-1/2 -translate-y-1/2 p-1.5 rounded-lg text-[#8B8C8E] hover:text-[#221F1A] hover:bg-white transition-all
                      ${activeMenuId === chat.id ? 'opacity-100' : 'opacity-0 md:group-hover:opacity-100'}
                      ${activeChatId === chat.id ? 'opacity-100' : ''}
                    `}
                  >
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><path d="M12 8c1.1 0 2-.9 2-2s-.9-2-2-2-2 .9-2 2 .9 2 2 2zm0 2c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm0 6c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2z"/></svg>
                  </button>

                  {/* Dropdown Menu */}
                  {activeMenuId === chat.id && (
                    <div className="absolute right-2 top-10 w-36 bg-white border border-[#EAE0D3] shadow-lg rounded-xl overflow-hidden z-[100] animate-in fade-in zoom-in-95 duration-100">
                      <button 
                        onClick={(e) => { e.stopPropagation(); setRenameValue(chat.title); setRenameModal(chat.id); setActiveMenuId(null); }}
                        className="w-full text-left px-4 py-2.5 text-sm hover:bg-[#F5EDE1] flex items-center gap-2"
                      >
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
                        Rename
                      </button>
                      <button 
                        onClick={(e) => { e.stopPropagation(); setDeleteModal(chat.id); setActiveMenuId(null); }}
                        className="w-full text-left px-4 py-2.5 text-sm hover:bg-[#FFF0F0] text-red-600 flex items-center gap-2"
                      >
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M3 6h18M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2M10 11v6M14 11v6"/></svg>
                        Delete
                      </button>
                    </div>
                  )}
                </div>
              ))}
            </div>
          </div>

          <div className="border-t border-[#EAE0D3] pt-3 mt-2 space-y-1 bg-[#F5EDE1]">
             <a href="https://github.com/brittytino/psgmx/releases" target="_blank" className="flex items-center gap-3 px-3 py-3 hover:bg-white rounded-xl text-[14px] font-medium transition-all border border-transparent hover:border-[#EAE0D3] shadow-sm">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.47 2 2 6.48 2 12c0 4.42 2.87 8.17 6.84 9.5.5.08.66-.23.66-.5v-1.69c-2.77.6-3.36-1.34-3.36-1.34-.45-1.15-1.11-1.46-1.11-1.46-.91-.62.07-.6.07-.6 1 .07 1.53 1.03 1.53 1.03.87 1.52 2.34 1.07 2.91.83.09-.65.35-1.09.63-1.34-2.22-.25-4.55-1.11-4.55-4.92 0-1.11.38-2 1.03-2.71-.1-.25-.45-1.29.1-2.64 0 0 .84-.27 2.75 1.02.79-.22 1.65-.33 2.5-.33.85 0 1.71.11 2.5.33 1.91-1.29 2.75-1.02 2.75-1.02.55 1.35.2 2.39.1 2.64.65.71 1.03 1.6 1.03 2.71 0 3.82-2.34 4.66-4.57 4.91.36.31.69.92.69 1.85V21c0 .27.16.59.67.5C19.14 20.16 22 16.42 22 12A10 10 0 0012 2z"/></svg>
                Download App
             </a>
             <Link href="/login" className="flex items-center gap-3 px-3 py-3 hover:bg-white rounded-xl text-[14px] font-medium transition-all border border-transparent hover:border-[#EAE0D3] shadow-sm">
                <div className="w-6 h-6 rounded-full bg-gradient-to-tr from-[#FF5A1F] to-[#FFA27F] flex items-center justify-center text-[10px] text-white shadow-inner">
                  PT
                </div>
                Log in to Dashboard
             </Link>
          </div>
        </div>
      </div>

      {/* --- Main Chat Area --- */}
      <div className="flex-1 flex flex-col relative z-10 w-full min-w-0" onClick={() => { if(activeMenuId) setActiveMenuId(null); }}>
        
        {/* Navbar */}
        <div className="flex items-center justify-between p-3 sticky top-0 z-20 shrink-0 h-[60px] bg-[#FBF6EE]/90 backdrop-blur-md">
          <div className="flex items-center">
            {!isSidebarOpen && (
              <button 
                onClick={(e) => { e.stopPropagation(); setIsSidebarOpen(true); }} 
                className="p-2 mr-2 text-[#4A4A4C] hover:bg-[#EAE0D3]/80 rounded-xl transition-colors md:mr-4"
              >
                <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M4 6h16M4 12h16M4 18h16"/></svg>
              </button>
            )}
            <div className="font-semibold text-lg flex items-center gap-2 cursor-pointer hover:bg-[#EAE0D3]/50 px-3 py-1.5 rounded-xl transition-colors">
              PSGMX Guide <span className="text-[#8B8C8E] text-sm">v4</span>
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M6 9l6 6 6-6"/></svg>
            </div>
          </div>
          <Link href="/login" className="md:hidden w-9 h-9 rounded-full bg-gradient-to-tr from-[#FF5A1F] to-[#FFA27F] flex items-center justify-center text-[12px] font-bold text-white shadow-md shadow-[#FF5A1F]/20 border border-white/20">
            PT
          </Link>
        </div>

        {/* Chat Content */}
        <div className="flex-1 overflow-y-auto px-4 md:px-0 scroll-smooth min-h-0 relative flex flex-col">
          {messages.length === 0 ? (
            <div className="flex-1 flex flex-col items-center justify-center max-w-2xl mx-auto text-center px-4 animate-in fade-in duration-700">
              <div className="w-16 h-16 bg-white rounded-3xl shadow-sm border border-[#EAE0D3] flex items-center justify-center mb-8 transform hover:scale-105 transition-transform duration-500">
                 <img src="/logo.png" alt="PSGMX" className="w-10 h-10 object-contain" />
              </div>
              <h1 className="text-3xl md:text-4xl font-semibold mb-6 text-[#221F1A] tracking-tight">Where should we begin?</h1>
            </div>
          ) : (
            <div className="max-w-3xl mx-auto flex flex-col w-full pb-8 pt-4 md:px-8">
              {messages.map(m => (
                <div key={m.id} className={`flex w-full mb-6 ${m.role === 'user' ? 'justify-end' : 'justify-start'} animate-in slide-in-from-bottom-2 fade-in duration-300`}>
                  {m.role === 'user' ? (
                    <div className="bg-[#EAE0D3] text-[#221F1A] px-5 py-3 rounded-[24px] max-w-[85%] whitespace-pre-wrap leading-relaxed shadow-sm font-medium">
                      {m.text}
                    </div>
                  ) : (
                    <div className="flex gap-4 w-full max-w-[100%] group">
                      <div className="w-[32px] h-[32px] rounded-full border border-[#EAE0D3] flex items-center justify-center flex-shrink-0 mt-1 bg-white shadow-sm">
                        <img src="/logo.png" alt="Bot" className="w-[20px] h-[20px] object-contain" />
                      </div>
                      <div className="flex-1 space-y-4">
                        <div className="text-[#221F1A] leading-relaxed whitespace-pre-wrap pt-1.5 text-[15.5px]">
                          {/* Parse markdown bolding */}
                          {m.text.split('**').map((part, index) => 
                            index % 2 === 1 ? <strong key={index} className="text-black font-bold">{part}</strong> : part
                          )}
                          {m.isStreaming && <span className="inline-block w-2 h-4 ml-1 bg-[#FF5A1F] animate-pulse rounded-sm align-middle"></span>}
                        </div>
                        
                        {!m.isStreaming && (
                          <div className="flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                            <button className="p-1.5 text-[#8B8C8E] hover:text-[#221F1A] hover:bg-[#EAE0D3] rounded-lg transition-colors"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z"/></svg></button>
                            <button className="p-1.5 text-[#8B8C8E] hover:text-[#221F1A] hover:bg-[#EAE0D3] rounded-lg transition-colors"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M14 9V5a3 3 0 0 0-3-3l-4 9v11h11.28a2 2 0 0 0 2-1.7l1.38-9a2 2 0 0 0-2-2.3zM7 22H4a2 2 0 0 1-2-2v-7a2 2 0 0 1 2-2h3"/></svg></button>
                            <button className="p-1.5 text-[#8B8C8E] hover:text-[#221F1A] hover:bg-[#EAE0D3] rounded-lg transition-colors"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M10 15v4a3 3 0 0 0 3 3l4-9V2H5.72a2 2 0 0 0-2 1.7l-1.38 9a2 2 0 0 0 2 2.3zm7-13h3a2 2 0 0 1 2 2v7a2 2 0 0 1-2 2h-3"/></svg></button>
                          </div>
                        )}
                      </div>
                    </div>
                  )}
                </div>
              ))}
              
              {/* Thinking Indicator */}
              {isTyping && (
                <div className="flex gap-4 w-full max-w-[100%] animate-in fade-in duration-300 md:px-8">
                  <div className="w-[32px] h-[32px] rounded-full border border-[#EAE0D3] flex items-center justify-center flex-shrink-0 mt-1 bg-white relative overflow-hidden shadow-sm">
                     <img src="/logo.png" alt="Bot" className="w-[20px] h-[20px] object-contain animate-pulse" />
                     <div className="absolute inset-0 bg-transparent animate-[spin_1.5s_linear_infinite] rounded-full" style={{ borderTop: '2px solid #FF5A1F' }}></div>
                  </div>
                  <div className="pt-2.5">
                     <div className="flex gap-1.5">
                       <div className="w-2 h-2 rounded-full bg-[#FF5A1F]/50 animate-bounce"></div>
                       <div className="w-2 h-2 rounded-full bg-[#FF5A1F]/70 animate-bounce" style={{ animationDelay: '0.15s' }}></div>
                       <div className="w-2 h-2 rounded-full bg-[#FF5A1F] animate-bounce" style={{ animationDelay: '0.3s' }}></div>
                     </div>
                  </div>
                </div>
              )}
              
              <div ref={messagesEndRef} className="h-2" />
            </div>
          )}
        </div>

        {/* --- Input Area --- */}
        <div className="px-4 pb-4 md:pb-6 pt-2 shrink-0 relative z-20 bg-gradient-to-t from-[#FBF6EE] via-[#FBF6EE] to-transparent">
          <div className="max-w-3xl mx-auto relative flex flex-col gap-3 md:px-8">
            
            {/* Suggestions (Only show if there are messages and not typing) */}
            {messages.length > 0 && !isTyping && (
              <div className="flex gap-2 overflow-x-auto pb-1 scrollbar-hide snap-x animate-in slide-in-from-bottom-2 fade-in">
                {SUGGESTIONS.map((s, i) => (
                  <button 
                    key={i} 
                    onClick={() => handleSend(s)}
                    className="whitespace-nowrap px-4 py-2 bg-white border border-[#EAE0D3] rounded-full text-[13px] font-medium text-[#4A4A4C] hover:bg-[#F5EDE1] hover:text-[#221F1A] transition-colors shadow-sm snap-start"
                  >
                    {s}
                  </button>
                ))}
              </div>
            )}

            <form 
              onSubmit={(e) => { e.preventDefault(); handleSend(query); }} 
              className="relative flex items-end bg-white border border-[#EAE0D3] rounded-[26px] shadow-lg shadow-black/5 focus-within:ring-2 ring-[#FF5A1F]/20 focus-within:border-[#FF5A1F]/40 transition-all"
            >
              <button type="button" className="p-3 m-1.5 text-[#8B8C8E] hover:bg-[#F5EDE1] rounded-full transition-colors shrink-0">
                <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M21.44 11.05l-9.19 9.19a6 6 0 01-8.49-8.49l9.19-9.19a4 4 0 015.66 5.66l-9.2 9.19a2 2 0 01-2.83-2.83l8.49-8.48"/></svg>
              </button>
              <textarea
                ref={textareaRef}
                value={query}
                onChange={e => {
                  setQuery(e.target.value);
                  adjustTextareaHeight();
                }}
                onKeyDown={handleKeyDown}
                placeholder="Message PSGMX Guide..."
                className="flex-1 bg-transparent py-[18px] outline-none text-[#221F1A] placeholder-[#8B8C8E] resize-none min-h-[60px] h-[60px] max-h-[200px] text-[15.5px] leading-relaxed overflow-y-auto"
              />
              {query.trim() ? (
                <button 
                  type="submit" 
                  className="p-2.5 m-2 rounded-full shrink-0 transition-all bg-[#FF5A1F] text-white hover:bg-[#E04810] shadow-sm transform hover:scale-105"
                >
                  <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M4 12l1.41 1.41L11 7.83V20h2V7.83l5.58 5.59L20 12l-8-8-8 8z"/></svg>
                </button>
              ) : (
                <button type="button" className="p-3 m-1.5 text-[#8B8C8E] hover:bg-[#F5EDE1] rounded-full transition-colors shrink-0">
                  <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M12 2a3 3 0 0 0-3 3v7a3 3 0 0 0 6 0V5a3 3 0 0 0-3-3z"/><path d="M19 10v2a7 7 0 0 1-14 0v-2M12 19v4M8 23h8"/></svg>
                </button>
              )}
            </form>
            <div className="text-center text-[11px] text-[#8B8C8E] tracking-wide">
              PSGMX Guide acts as an interactive landing page for product queries.
            </div>
          </div>
        </div>
      </div>
      
    </div>
  );
}
