'use client';

import { useState, useRef, useEffect } from 'react';
import Link from 'next/link';

// --- Types ---
type Message = { id: string; role: 'user' | 'bot'; text: string; isStreaming?: boolean };
type ChatSession = { id: string; title: string; messages: Message[]; updatedAt: number };

// --- Constants ---
const SUGGESTIONS = [
  "How does PSGMX help with placements?",
  "How can I download the app?"
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
  if (lower.includes('hi') || lower.includes('hello') || lower.includes('hey')) {
    return "Hello! I am PSGMX Intelligence. I am here to help you navigate our Placement Operating System. You can ask me about features like the AI Mentor, Codebox, or how to install the app. How can I assist you today?";
  }
  
  // Generic fallback for any other text
  return `I understand you're asking about "${text.length > 30 ? text.substring(0, 30) + '...' : text}".\n\nWhile I am highly specialized in answering questions about the **PSGMX Placement Operating System**, I can tell you that our platform is designed to handle all aspects of your placement journey—from tracking attendance to practicing coding in the Codebox. Is there a specific feature of PSGMX you'd like to explore?`;
}

export default function LandingPage() {
  // --- State ---
  const [chats, setChats] = useState<ChatSession[]>([]);
  const [activeChatId, setActiveChatId] = useState<string | null>(null);
  const [query, setQuery] = useState('');
  
  // Sidebar State
  const [isSidebarHovered, setIsSidebarHovered] = useState(false);
  const [isSidebarMobileOpen, setIsSidebarMobileOpen] = useState(false);
  
  const [isTyping, setIsTyping] = useState(false);
  
  // Modals / Dropdowns
  const [activeMenuId, setActiveMenuId] = useState<string | null>(null);
  const [deleteModal, setDeleteModal] = useState<string | null>(null);
  const [renameModal, setRenameModal] = useState<string | null>(null);
  const [renameValue, setRenameValue] = useState('');

  // Refs
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const textareaRef = useRef<HTMLTextAreaElement>(null);
  const sidebarHoverTimer = useRef<NodeJS.Timeout | null>(null);

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
  }, []);

  useEffect(() => {
    if (chats.length > 0) {
      localStorage.setItem('psgmx_landing_chats', JSON.stringify(chats));
    } else if (chats.length === 0 && activeChatId) {
      localStorage.removeItem('psgmx_landing_chats');
    }
  }, [chats]);

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
    setIsSidebarMobileOpen(false);
    setIsSidebarHovered(false);
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

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSend(query);
    }
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

  // Hover triggers for Desktop Sidebar
  const handleMouseEnterSidebarArea = () => {
    if (sidebarHoverTimer.current) clearTimeout(sidebarHoverTimer.current);
    setIsSidebarHovered(true);
  };
  
  const handleMouseLeaveSidebar = () => {
    sidebarHoverTimer.current = setTimeout(() => {
      setIsSidebarHovered(false);
      setActiveMenuId(null);
    }, 300); // 300ms delay to prevent accidental closing
  };

  const isSidebarVisible = isSidebarHovered || isSidebarMobileOpen;

  return (
    <div className="flex h-[100dvh] w-full bg-[#FBF6EE] text-[#221F1A] font-sans overflow-hidden text-[15px]">
      
      {/* --- Desktop Hover Hit Area --- */}
      <div 
        className="hidden md:block fixed left-0 top-0 h-full w-8 z-40 bg-transparent"
        onMouseEnter={handleMouseEnterSidebarArea}
      />

      {/* --- Modals --- */}
      {deleteModal && (
        <div className="fixed inset-0 z-[100] flex items-center justify-center bg-black/40 backdrop-blur-sm p-4 animate-in fade-in duration-200">
          <div className="bg-white rounded-[24px] p-7 w-full max-w-sm shadow-2xl border border-[#E8DFD1] animate-in zoom-in-95 duration-200">
            <h3 className="text-xl font-semibold mb-2 text-[#221F1A]">Delete chat?</h3>
            <p className="text-[15px] text-[#555] mb-8 leading-relaxed">This will permanently delete this chat history. Are you sure you want to proceed?</p>
            <div className="flex justify-end gap-3">
              <button onClick={() => setDeleteModal(null)} className="px-5 py-2.5 rounded-full text-[15px] font-medium hover:bg-[#F5EDE1] transition-colors">Cancel</button>
              <button onClick={confirmDelete} className="px-5 py-2.5 rounded-full text-[15px] font-medium bg-[#FF5A1F] text-white hover:bg-[#E04810] shadow-sm transition-colors">Delete</button>
            </div>
          </div>
        </div>
      )}

      {renameModal && (
        <div className="fixed inset-0 z-[100] flex items-center justify-center bg-black/40 backdrop-blur-sm p-4 animate-in fade-in duration-200">
          <div className="bg-white rounded-[24px] p-7 w-full max-w-sm shadow-2xl border border-[#E8DFD1] animate-in zoom-in-95 duration-200">
            <h3 className="text-xl font-semibold mb-5 text-[#221F1A]">Rename chat</h3>
            <input 
              autoFocus
              value={renameValue} 
              onChange={e => setRenameValue(e.target.value)} 
              onKeyDown={e => { if (e.key === 'Enter') confirmRename(); }}
              className="w-full px-5 py-3.5 bg-[#FBF6EE] border border-[#E8DFD1] rounded-2xl outline-none focus:ring-2 ring-[#FF5A1F]/30 focus:border-[#FF5A1F] transition-all mb-8 text-[15px]"
              placeholder="Enter new name..."
            />
            <div className="flex justify-end gap-3">
              <button onClick={() => setRenameModal(null)} className="px-5 py-2.5 rounded-full text-[15px] font-medium hover:bg-[#F5EDE1] transition-colors">Cancel</button>
              <button onClick={confirmRename} className="px-5 py-2.5 rounded-full text-[15px] font-medium bg-[#221F1A] text-white hover:bg-black shadow-sm transition-colors">Save</button>
            </div>
          </div>
        </div>
      )}
      
      {/* --- Sidebar Overlay (Mobile) --- */}
      <div 
        className={`fixed inset-0 bg-black/40 z-40 md:hidden transition-opacity duration-300 ${isSidebarMobileOpen ? 'opacity-100' : 'opacity-0 pointer-events-none'}`} 
        onClick={() => setIsSidebarMobileOpen(false)}
      />
      
      {/* --- Sidebar (Floating on Desktop on Hover, Fixed on Mobile) --- */}
      <div 
        onMouseEnter={handleMouseEnterSidebarArea}
        onMouseLeave={handleMouseLeaveSidebar}
        className={`fixed z-50 h-full bg-[#F5EDE1]/95 backdrop-blur-xl border-r border-[#EAE0D3] flex flex-col transition-transform duration-300 ease-[cubic-bezier(0.16,1,0.3,1)] shadow-2xl md:shadow-[20px_0_40px_rgba(0,0,0,0.05)] w-[280px]
          ${isSidebarVisible ? 'translate-x-0' : '-translate-x-full'}
        `}
      >
        <div className="w-[280px] h-full flex flex-col p-4">
          
          <div className="flex items-center justify-between mb-6">
            <button 
              onClick={createNewChat}
              className="flex-1 flex items-center gap-3 bg-white hover:bg-[#FBF6EE] px-4 py-3 rounded-2xl shadow-sm border border-[#EAE0D3] transition-all font-semibold text-[15px] text-[#221F1A]"
            >
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><path d="M12 5v14M5 12h14"/></svg>
              New chat
            </button>
            <button onClick={() => setIsSidebarMobileOpen(false)} className="p-2 ml-2 text-[#4A4A4C] hover:bg-white rounded-xl md:hidden">
              <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M18 6L6 18M6 6l12 12"/></svg>
            </button>
          </div>
          
          <div className="flex-1 overflow-y-auto px-1 -mx-1" onClick={() => { if(activeMenuId) setActiveMenuId(null); }}>
            <div className="text-xs font-bold text-[#8B8C8E] mb-3 px-3 uppercase tracking-wider">Recent History</div>
            
            <div className="space-y-1">
              {chats.map(chat => (
                <div key={chat.id} className="relative group">
                  <button 
                    onClick={() => { setActiveChatId(chat.id); setIsSidebarMobileOpen(false); setIsSidebarHovered(false); }} 
                    className={`w-full text-left px-4 py-3 text-[15px] rounded-xl truncate transition-all pr-10
                      ${activeChatId === chat.id ? 'bg-[#EAE0D3] font-medium text-[#221F1A] shadow-sm' : 'text-[#4A4A4C] hover:bg-white/50'}
                    `}
                  >
                    {chat.title}
                  </button>
                  
                  <button 
                    onClick={(e) => { e.stopPropagation(); setActiveMenuId(activeMenuId === chat.id ? null : chat.id); }}
                    className={`absolute right-2 top-1/2 -translate-y-1/2 p-2 rounded-lg text-[#8B8C8E] hover:text-[#221F1A] hover:bg-white transition-all shadow-sm
                      ${activeMenuId === chat.id ? 'opacity-100 bg-white' : 'opacity-0 md:group-hover:opacity-100'}
                      ${activeChatId === chat.id && !activeMenuId ? 'opacity-100' : ''}
                    `}
                  >
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><path d="M12 8c1.1 0 2-.9 2-2s-.9-2-2-2-2 .9-2 2 .9 2 2 2zm0 2c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm0 6c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2z"/></svg>
                  </button>

                  {/* Dropdown Menu */}
                  {activeMenuId === chat.id && (
                    <div className="absolute right-2 top-12 w-40 bg-white border border-[#EAE0D3] shadow-xl rounded-[16px] overflow-hidden z-[100] animate-in fade-in zoom-in-95 duration-100">
                      <button 
                        onClick={(e) => { e.stopPropagation(); setRenameValue(chat.title); setRenameModal(chat.id); setActiveMenuId(null); }}
                        className="w-full text-left px-4 py-3 text-[14px] font-medium hover:bg-[#F5EDE1] flex items-center gap-2.5 transition-colors"
                      >
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
                        Rename
                      </button>
                      <div className="h-[1px] bg-[#EAE0D3]/50 w-full"></div>
                      <button 
                        onClick={(e) => { e.stopPropagation(); setDeleteModal(chat.id); setActiveMenuId(null); }}
                        className="w-full text-left px-4 py-3 text-[14px] font-medium hover:bg-[#FFF0F0] text-red-600 flex items-center gap-2.5 transition-colors"
                      >
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M3 6h18M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2M10 11v6M14 11v6"/></svg>
                        Delete
                      </button>
                    </div>
                  )}
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* --- Main Chat Area --- */}
      <div className="flex-1 flex flex-col relative z-10 w-full min-w-0" onClick={() => { if(activeMenuId) setActiveMenuId(null); }}>
        
        {/* Navbar */}
        <div className="flex items-center justify-between p-4 sticky top-0 z-20 shrink-0 h-[72px] bg-gradient-to-b from-[#FBF6EE] to-[#FBF6EE]/80 backdrop-blur-md">
          <div className="flex items-center">
            {/* Mobile Hamburger */}
            <button 
              onClick={(e) => { e.stopPropagation(); setIsSidebarMobileOpen(true); }} 
              className="p-2 mr-3 text-[#221F1A] hover:bg-[#EAE0D3]/80 rounded-xl transition-colors md:hidden"
            >
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M4 6h16M4 12h16M4 18h16"/></svg>
            </button>
            
            {/* Desktop Hover Hint (Only visible when sidebar is closed) */}
            <div className="hidden md:flex items-center text-[#8B8C8E] text-[13px] font-medium mr-4 px-3 py-1.5 rounded-full border border-[#EAE0D3] bg-white/50 opacity-50 hover:opacity-100 transition-opacity">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="mr-1.5"><path d="M9 18l6-6-6-6"/></svg>
              Hover left for history
            </div>

            <div className="font-bold text-[19px] flex items-center gap-2 text-[#221F1A]">
              PSGMX Intelligence
              <span className="bg-[#EAE0D3] text-[#4A4A4C] text-[11px] px-2 py-0.5 rounded-md uppercase tracking-wide">Core</span>
            </div>
          </div>
          
          {/* Top Right Curved Login Button */}
          <Link href="/login" className="px-5 py-2.5 bg-[#221F1A] text-white rounded-[20px] font-medium text-[14px] hover:bg-black shadow-md hover:shadow-lg hover:-translate-y-0.5 transition-all flex items-center gap-2">
            Dashboard
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><path d="M5 12h14M12 5l7 7-7 7"/></svg>
          </Link>
        </div>

        {/* Chat Content */}
        <div className="flex-1 overflow-y-auto px-4 md:px-0 scroll-smooth min-h-0 relative flex flex-col">
          {messages.length === 0 ? (
            <div className="flex-1 flex flex-col items-center justify-center max-w-2xl mx-auto text-center px-4 animate-in fade-in duration-700">
              <div className="w-[80px] h-[80px] bg-white rounded-[28px] shadow-lg shadow-[#FF5A1F]/10 border border-[#EAE0D3] flex items-center justify-center mb-8 transform hover:scale-105 transition-transform duration-500">
                 <img src="/logo.png" alt="PSGMX" className="w-[44px] h-[44px] object-contain" />
              </div>
              <h1 className="text-[34px] md:text-[40px] font-bold mb-4 text-[#221F1A] tracking-tight">How can I help you today?</h1>
              <p className="text-[#8B8C8E] text-[16px] max-w-md mx-auto">I'm your intelligent assistant for the PSGMX Placement OS. Ask me anything about our features.</p>
            </div>
          ) : (
            <div className="max-w-3xl mx-auto flex flex-col w-full pb-8 pt-4 md:px-8">
              {messages.map(m => (
                <div key={m.id} className={`flex w-full mb-8 ${m.role === 'user' ? 'justify-end' : 'justify-start'} animate-in slide-in-from-bottom-2 fade-in duration-300`}>
                  {m.role === 'user' ? (
                    <div className="bg-[#EAE0D3] text-[#221F1A] px-5 py-3.5 rounded-[24px] rounded-br-sm max-w-[85%] whitespace-pre-wrap leading-relaxed shadow-sm font-medium text-[16px]">
                      {m.text}
                    </div>
                  ) : (
                    <div className="flex gap-5 w-full max-w-[100%] group">
                      <div className="w-[36px] h-[36px] rounded-full border border-[#EAE0D3] flex items-center justify-center flex-shrink-0 mt-1 bg-white shadow-sm">
                        <img src="/logo.png" alt="Bot" className="w-[22px] h-[22px] object-contain" />
                      </div>
                      <div className="flex-1 space-y-4">
                        <div className="text-[#221F1A] leading-relaxed whitespace-pre-wrap pt-1.5 text-[16px]">
                          {/* Parse markdown bolding */}
                          {m.text.split('**').map((part, index) => 
                            index % 2 === 1 ? <strong key={index} className="text-black font-bold">{part}</strong> : part
                          )}
                          {m.isStreaming && <span className="inline-block w-2.5 h-4.5 ml-1.5 bg-[#FF5A1F] animate-pulse rounded-sm align-middle"></span>}
                        </div>
                        
                        {!m.isStreaming && (
                          <div className="flex gap-1.5 opacity-0 group-hover:opacity-100 transition-opacity mt-2">
                            <button className="p-1.5 text-[#8B8C8E] hover:text-[#221F1A] hover:bg-[#EAE0D3] rounded-lg transition-colors"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z"/></svg></button>
                            <button className="p-1.5 text-[#8B8C8E] hover:text-[#221F1A] hover:bg-[#EAE0D3] rounded-lg transition-colors"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M14 9V5a3 3 0 0 0-3-3l-4 9v11h11.28a2 2 0 0 0 2-1.7l1.38-9a2 2 0 0 0-2-2.3zM7 22H4a2 2 0 0 1-2-2v-7a2 2 0 0 1 2-2h3"/></svg></button>
                            <button className="p-1.5 text-[#8B8C8E] hover:text-[#221F1A] hover:bg-[#EAE0D3] rounded-lg transition-colors"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M10 15v4a3 3 0 0 0 3 3l4-9V2H5.72a2 2 0 0 0-2 1.7l-1.38 9a2 2 0 0 0 2 2.3zm7-13h3a2 2 0 0 1 2 2v7a2 2 0 0 1-2 2h-3"/></svg></button>
                          </div>
                        )}
                      </div>
                    </div>
                  )}
                </div>
              ))}
              
              {/* Thinking Indicator */}
              {isTyping && (
                <div className="flex gap-5 w-full max-w-[100%] animate-in fade-in duration-300 md:px-8">
                  <div className="w-[36px] h-[36px] rounded-full border border-[#EAE0D3] flex items-center justify-center flex-shrink-0 mt-1 bg-white relative overflow-hidden shadow-sm">
                     <img src="/logo.png" alt="Bot" className="w-[22px] h-[22px] object-contain animate-pulse" />
                     <div className="absolute inset-0 bg-transparent animate-[spin_1.5s_linear_infinite] rounded-full" style={{ borderTop: '2px solid #FF5A1F' }}></div>
                  </div>
                  <div className="pt-3.5">
                     <div className="flex gap-1.5">
                       <div className="w-2.5 h-2.5 rounded-full bg-[#FF5A1F]/40 animate-bounce"></div>
                       <div className="w-2.5 h-2.5 rounded-full bg-[#FF5A1F]/70 animate-bounce" style={{ animationDelay: '0.15s' }}></div>
                       <div className="w-2.5 h-2.5 rounded-full bg-[#FF5A1F] animate-bounce" style={{ animationDelay: '0.3s' }}></div>
                     </div>
                  </div>
                </div>
              )}
              
              <div ref={messagesEndRef} className="h-4" />
            </div>
          )}
        </div>

        {/* --- Input Area --- */}
        <div className="px-4 pb-6 md:pb-8 pt-2 shrink-0 relative z-20 bg-gradient-to-t from-[#FBF6EE] via-[#FBF6EE] to-transparent">
          <div className="max-w-3xl mx-auto relative flex flex-col gap-4 md:px-8">
            
            {/* Suggestions (Only show a few tightly curated ones) */}
            {messages.length > 0 && !isTyping && (
              <div className="flex gap-2.5 overflow-x-auto pb-2 scrollbar-hide snap-x animate-in slide-in-from-bottom-2 fade-in">
                {SUGGESTIONS.map((s, i) => (
                  <button 
                    key={i} 
                    onClick={() => handleSend(s)}
                    className="whitespace-nowrap px-4 py-2.5 bg-white border border-[#EAE0D3] rounded-full text-[14px] font-semibold text-[#4A4A4C] hover:bg-[#F5EDE1] hover:text-[#221F1A] transition-all shadow-sm hover:shadow-md snap-start"
                  >
                    {s}
                  </button>
                ))}
              </div>
            )}

            <form 
              onSubmit={(e) => { e.preventDefault(); handleSend(query); }} 
              className="relative flex items-end bg-white border border-[#EAE0D3] rounded-[28px] shadow-lg shadow-black/5 focus-within:ring-2 ring-[#FF5A1F]/20 focus-within:border-[#FF5A1F]/40 transition-all"
            >
              <button type="button" className="p-3.5 m-1.5 text-[#8B8C8E] hover:bg-[#F5EDE1] hover:text-[#221F1A] rounded-full transition-colors shrink-0">
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
                placeholder="Ask PSGMX Intelligence..."
                className="flex-1 bg-transparent py-[20px] outline-none text-[#221F1A] placeholder-[#8B8C8E] resize-none min-h-[64px] h-[64px] max-h-[200px] text-[16px] leading-relaxed overflow-y-auto"
              />
              {query.trim() ? (
                <button 
                  type="submit" 
                  className="p-3 m-2 rounded-full shrink-0 transition-all bg-[#FF5A1F] text-white hover:bg-[#E04810] shadow-md transform hover:scale-105"
                >
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor"><path d="M4 12l1.41 1.41L11 7.83V20h2V7.83l5.58 5.59L20 12l-8-8-8 8z"/></svg>
                </button>
              ) : (
                <button type="button" className="p-3.5 m-1.5 text-[#8B8C8E] hover:bg-[#F5EDE1] hover:text-[#221F1A] rounded-full transition-colors shrink-0">
                  <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M12 2a3 3 0 0 0-3 3v7a3 3 0 0 0 6 0V5a3 3 0 0 0-3-3z"/><path d="M19 10v2a7 7 0 0 1-14 0v-2M12 19v4M8 23h8"/></svg>
                </button>
              )}
            </form>
            <div className="text-center text-[12px] font-medium text-[#8B8C8E] tracking-wide">
              PSGMX Intelligence acts as an interactive landing page to help you discover the product.
            </div>
          </div>
        </div>
      </div>
      
    </div>
  );
}
