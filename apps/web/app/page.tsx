'use client';

import { useState, useRef, useEffect } from 'react';
import Link from 'next/link';

// --- Types ---
type Message = { id: string; role: 'user' | 'bot'; text: string; isStreaming?: boolean };
type ChatSession = { id: string; title: string; messages: Message[]; updatedAt: number };

// --- Constants ---
const SUGGESTIONS = [
  "How does PSGMX help with placements?",
  "What is the AI Mentor?",
  "How can I download the app?",
  "Tell me about Codebox"
];

// --- Helper: Bot Logic ---
function generateResponse(text: string, history: Message[]): string {
  const lower = text.toLowerCase();
  
  if (lower.includes('download') || lower.includes('apk') || lower.includes('android') || lower.includes('install') || lower.includes('app')) {
    return "You can experience the full power of PSGMX by downloading our native mobile app. It includes all features like the AI Mentor, Codebox, and Placement Tracking.\n\n**Android Users:**\nYou can download the latest APK directly from our GitHub releases page: https://github.com/brittytino/psgmx/releases\n\n**iOS Users:**\nWhile we don't have a native App Store app yet, you get a first-class PWA experience! Just open **app.psgmx.tech** in Safari, tap the Share icon at the bottom, and select **'Add to Home Screen'**. It functions exactly like a native app with full audio recording and offline support.";
  }
  if (lower.includes('ai') || lower.includes('mentor') || lower.includes('interview') || lower.includes('coach')) {
    return "The **AI Mentor** is your personal, voice-enabled interview coach built right into PSGMX.\n\nYou can practice Technical, HR, and Communication interviews using real-time audio. The AI listens to your voice responses, transcribes them, and provides incredibly detailed feedback, scoring, and suggestions for improvement—just like a real recruiter would. It's designed to build your confidence before actual placement drives.";
  }
  if (lower.includes('codebox') || lower.includes('code') || lower.includes('programming') || lower.includes('dsa') || lower.includes('compiler')) {
    return "**Codebox** is our built-in IDE where you can practice Data Structures and Algorithms without leaving the platform.\n\nIt supports multiple languages including C, C++, Java, Python, and Dart. When you submit your code, it automatically evaluates it against hidden test cases. It also tracks your problem-solving speed and accuracy to prepare you for the intense technical coding rounds of top product companies.";
  }
  if (lower.includes('daily five') || lower.includes('daily') || lower.includes('five') || lower.includes('aptitude')) {
    return "The **Daily Five** is a micro-learning feature designed to build consistency in your preparation.\n\nEvery single day, you receive exactly 5 curated questions covering Aptitude, Core Subjects (like OS, DBMS, Networks), and Coding logic. By spending just 10 minutes a day, it ensures you stay sharp with your placement preparation without feeling overwhelmed by massive question banks.";
  }
  if (lower.includes('what is') || lower.includes('about') || lower.includes('psgmx') || lower.includes('platform') || lower.includes('features')) {
    return "PSGMX is the ultimate **Placement Operating System** built exclusively for PSG Tech MCA students.\n\nWe provide a completely unified, premium platform to track, prepare, and collaborate for placements. Instead of using multiple apps for coding, interview prep, and tracking, PSGMX brings it all together. Key features include the AI Mentor, Codebox, Daily Five, and an extensive Placement Dashboard for representatives to track student progress.";
  }
  if (lower.includes('hi') || lower.includes('hello') || lower.includes('hey') || lower.includes('morning') || lower.includes('evening')) {
    return "Hello there! I am **PSGMX Intelligence**, the AI assistant for the PSGMX Placement OS.\n\nI can help you understand how to use our platform, explain features like the AI Mentor or Codebox, or guide you on how to install the app. What would you like to know today?";
  }
  if (lower.includes('thank') || lower.includes('thanks')) {
    return "You're very welcome! If you have any more questions about PSGMX or need help navigating the platform, just let me know. Good luck with your placement preparation!";
  }
  if (lower.includes('who are you') || lower.includes('your name') || lower.includes('created you') || lower.includes('who made you')) {
    return "I am **PSGMX Intelligence**, a specialized AI assistant designed to help students navigate and utilize the PSGMX Placement Operating System effectively. I was created as part of the PSGMX ecosystem to ensure you get the most out of features like Codebox, AI Mentor, and Daily Five.";
  }
  if (lower.includes('good') || lower.includes('great') || lower.includes('awesome') || lower.includes('nice') || lower.includes('amazing')) {
    return "I'm glad you think so! We've put a lot of effort into making PSGMX the best possible tool for your placement journey. Let me know if you want to explore any specific features in more detail.";
  }
  
  if (history.length > 2) {
     return `That's an interesting point! Following up on our conversation, I want to emphasize that PSGMX is designed to adapt to your specific placement needs.\n\nWhile I am an AI tuned specifically to answer questions about the **PSGMX Platform**, I'm here to ensure you have a smooth experience. Is there a specific feature you're trying to use right now?`;
  }
  
  return `I understand you're asking about "${text.length > 30 ? text.substring(0, 30) + '...' : text}".\n\nWhile my primary expertise is the **PSGMX Placement Operating System**, I can tell you that our platform is designed to handle all aspects of your placement journey seamlessly. Could you specify which part of PSGMX you'd like to explore? (e.g., AI Mentor, Codebox, App Download)`;
}

function getRelativeTime(timestamp: number) {
  const diff = Date.now() - timestamp;
  if (diff < 60000) return 'Just now';
  if (diff < 3600000) return `${Math.floor(diff / 60000)}m ago`;
  if (diff < 86400000) return `${Math.floor(diff / 3600000)}h ago`;
  if (diff < 31536000000) return `${Math.floor(diff / 86400000)}d ago`;
  return 'A long time ago';
}

const STORAGE_KEY = 'psgmx_chats_v4';

export default function LandingPage() {
  const [chats, setChats] = useState<ChatSession[]>([]);
  const [activeChatId, setActiveChatId] = useState<string | null>(null);
  const [query, setQuery] = useState('');
  const [isSidebarOpen, setIsSidebarOpen] = useState(true);
  const [isSidebarMobileOpen, setIsSidebarMobileOpen] = useState(false);
  const [isTyping, setIsTyping] = useState(false);
  const [activeMenuId, setActiveMenuId] = useState<string | null>(null);
  const [deleteModal, setDeleteModal] = useState<string | null>(null);
  const [renameModal, setRenameModal] = useState<string | null>(null);
  const [renameValue, setRenameValue] = useState('');

  const messagesEndRef = useRef<HTMLDivElement>(null);
  const textareaRef = useRef<HTMLTextAreaElement>(null);

  useEffect(() => {
    try {
      const saved = localStorage.getItem(STORAGE_KEY);
      if (saved) {
        const parsed: ChatSession[] = JSON.parse(saved);
        if (parsed && parsed.length > 0) {
          setChats(parsed);
          setActiveChatId(parsed[0].id);
          return;
        }
      }
    } catch (_) {}
    
    const newId = crypto.randomUUID();
    const newChat: ChatSession = { id: newId, title: 'New Chat', messages: [], updatedAt: Date.now() };
    setChats([newChat]);
    setActiveChatId(newId);

    if (window.innerWidth < 768) setIsSidebarOpen(false);
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    if (chats.length > 0) {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(chats));
    }
  }, [chats]);

  useEffect(() => {
    if (messagesEndRef.current) {
      messagesEndRef.current.scrollIntoView({ behavior: 'smooth' });
    }
  }, [chats, isTyping, activeChatId]);

  const createNewChat = () => {
    const newId = crypto.randomUUID();
    const newChat: ChatSession = { id: newId, title: 'New Chat', messages: [], updatedAt: Date.now() };
    setChats(prev => [newChat, ...prev]);
    setActiveChatId(newId);
    setIsSidebarMobileOpen(false);
    setTimeout(() => {
      if (textareaRef.current) {
        textareaRef.current.style.height = 'auto';
        textareaRef.current.focus();
      }
    }, 50);
  };

  const adjustTextareaHeight = () => {
    if (textareaRef.current) {
      textareaRef.current.style.height = 'auto';
      textareaRef.current.style.height = `${Math.min(textareaRef.current.scrollHeight, 200)}px`;
    }
  };

  const activeChat = chats.find(c => c.id === activeChatId);
  const messages = activeChat?.messages || [];

  const simulateStream = (fullText: string, chatId: string) => {
    setIsTyping(false);
    const words = fullText.split(' ');
    let currentText = '';
    const msgId = crypto.randomUUID();

    setChats(prev => prev.map(c =>
      c.id === chatId
        ? { ...c, messages: [...c.messages, { id: msgId, role: 'bot', text: '', isStreaming: true }] }
        : c
    ));

    let i = 0;
    const interval = setInterval(() => {
      if (i < words.length) {
        currentText += (i === 0 ? '' : ' ') + words[i];
        setChats(prev => prev.map(c =>
          c.id === chatId
            ? { ...c, messages: c.messages.map(m => m.id === msgId ? { ...m, text: currentText } : m) }
            : c
        ));
        i++;
      } else {
        clearInterval(interval);
        setChats(prev => prev.map(c =>
          c.id === chatId
            ? { ...c, messages: c.messages.map(m => m.id === msgId ? { ...m, isStreaming: false } : m) }
            : c
        ));
      }
    }, 35);
  };

  const handleSend = (text: string) => {
    if (!text.trim() || !activeChatId || isTyping) return;

    const userMsg: Message = { id: crypto.randomUUID(), role: 'user', text };
    const isFirstMessage = messages.length === 0;
    const words = text.split(' ');
    const newTitle = isFirstMessage
      ? words.slice(0, 5).join(' ') + (words.length > 5 ? '...' : '')
      : undefined;

    setChats(prev => prev.map(c =>
      c.id === activeChatId
        ? { ...c, messages: [...c.messages, userMsg], title: newTitle || c.title, updatedAt: Date.now() }
        : c
    ));
    setQuery('');
    if (textareaRef.current) textareaRef.current.style.height = 'auto';

    setIsTyping(true);
    const capturedChatId = activeChatId;

    setTimeout(() => {
      const response = generateResponse(text, messages);
      simulateStream(response, capturedChatId);
    }, 600 + Math.random() * 400);
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSend(query);
    }
  };

  const confirmDelete = () => {
    if (deleteModal) {
      const nextChats = chats.filter(c => c.id !== deleteModal);
      if (nextChats.length === 0) {
        const newId = crypto.randomUUID();
        const nc: ChatSession = { id: newId, title: 'New Chat', messages: [], updatedAt: Date.now() };
        setChats([nc]);
        setActiveChatId(newId);
      } else {
        setChats(nextChats);
        if (activeChatId === deleteModal) {
          setActiveChatId(nextChats[0].id);
        }
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

  const theme = {
    sidebarBg: '#F8F4EC',
    mainBg: '#FEFCFA',
    accentOrange: '#F97316',
  };

  return (
    <div className="flex h-[100dvh] w-full font-sans overflow-hidden text-[15px] antialiased" style={{ backgroundColor: theme.mainBg, color: '#1E1B18' }}>

      {/* Delete Modal */}
      {deleteModal && (
        <div className="fixed inset-0 z-[100] flex items-center justify-center bg-black/40 backdrop-blur-sm p-4 animate-in fade-in duration-200">
          <div className="bg-white rounded-3xl p-8 w-full max-w-sm shadow-2xl border border-[#E8DFD1] animate-in zoom-in-95 duration-200">
            <h3 className="text-xl font-bold mb-2">Delete chat?</h3>
            <p className="text-[15px] text-[#78716C] mb-8 leading-relaxed">This will permanently delete this chat history. Are you sure?</p>
            <div className="flex justify-end gap-3">
              <button onClick={() => setDeleteModal(null)} className="px-5 py-2.5 rounded-full text-[15px] font-medium hover:bg-[#F8F4EC] transition-colors">Cancel</button>
              <button onClick={confirmDelete} className="px-5 py-2.5 rounded-full text-[15px] font-medium text-white shadow-md hover:shadow-lg transition-all" style={{ backgroundColor: theme.accentOrange }}>Delete</button>
            </div>
          </div>
        </div>
      )}

      {/* Rename Modal */}
      {renameModal && (
        <div className="fixed inset-0 z-[100] flex items-center justify-center bg-black/40 backdrop-blur-sm p-4 animate-in fade-in duration-200">
          <div className="bg-white rounded-3xl p-8 w-full max-w-sm shadow-2xl border border-[#E8DFD1] animate-in zoom-in-95 duration-200">
            <h3 className="text-xl font-bold mb-5">Rename chat</h3>
            <input
              autoFocus
              value={renameValue}
              onChange={e => setRenameValue(e.target.value)}
              onKeyDown={e => { if (e.key === 'Enter') confirmRename(); }}
              className="w-full px-5 py-3.5 bg-[#F8F4EC] border border-[#E8DFD1] rounded-2xl outline-none focus:ring-2 focus:ring-[#F97316]/30 mb-8 text-[15px] transition-all"
              placeholder="Enter new name..."
            />
            <div className="flex justify-end gap-3">
              <button onClick={() => setRenameModal(null)} className="px-5 py-2.5 rounded-full text-[15px] font-medium hover:bg-[#F8F4EC] transition-colors">Cancel</button>
              <button onClick={confirmRename} className="px-5 py-2.5 rounded-full text-[15px] font-medium bg-[#1E1B18] text-white hover:bg-black shadow-md transition-all">Save</button>
            </div>
          </div>
        </div>
      )}

      <div
        className={`fixed inset-0 bg-black/40 z-40 md:hidden transition-opacity duration-300 ${isSidebarMobileOpen ? 'opacity-100' : 'opacity-0 pointer-events-none'}`}
        onClick={() => setIsSidebarMobileOpen(false)}
      />

      {/* Sidebar */}
      <div
        className={`fixed md:relative z-50 h-full flex flex-col transition-all duration-300 ease-[cubic-bezier(0.16,1,0.3,1)] overflow-hidden shrink-0 border-r border-[#EBE5DE] ${isSidebarMobileOpen || isSidebarOpen ? 'translate-x-0 w-[280px]' : '-translate-x-full w-0 md:translate-x-0 md:w-0'}`}
        style={{ backgroundColor: theme.sidebarBg }}
      >
        <div className="w-[280px] h-full flex flex-col">
          <div className="flex items-center justify-between p-4 pt-5 pb-3">
            <div className="flex items-center gap-2.5">
              <div className="w-8 h-8 rounded-full bg-white shadow-sm flex items-center justify-center p-1 border border-[#EAE4DD]">
                <img src="/logo.png" alt="Logo" className="w-full h-full object-contain" />
              </div>
              <div className="flex flex-col">
                <span className="font-bold text-[16px] leading-tight tracking-tight">PSGMX</span>
                <span className="text-[12px] font-medium text-[#78716C] leading-none">Intelligence</span>
              </div>
            </div>
            <button onClick={() => setIsSidebarOpen(false)} className="hidden md:flex items-center justify-center w-8 h-8 rounded-lg hover:bg-white border border-transparent hover:border-[#EBE5DE] text-[#78716C] transition-colors">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><rect x="3" y="3" width="18" height="18" rx="2" /><line x1="9" y1="3" x2="9" y2="21" /></svg>
            </button>
            <button onClick={() => setIsSidebarMobileOpen(false)} className="md:hidden p-2 text-[#78716C] hover:bg-white rounded-lg transition-colors">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M18 6L6 18M6 6l12 12" /></svg>
            </button>
          </div>

          <div className="px-4 pb-4">
            <button onClick={createNewChat} className="w-full flex items-center justify-between bg-white hover:bg-[#FEFCFA] px-4 py-3 rounded-[16px] shadow-sm border border-[#EBE5DE] transition-all hover:shadow-md font-semibold text-[14.5px]">
              <div className="flex items-center gap-3">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><path d="M12 5v14M5 12h14" /></svg>
                New chat
              </div>
              <span className="text-[11px] font-medium text-[#A8A29D] border border-[#EBE5DE] px-1.5 py-0.5 rounded-md hidden md:block">Ctrl K</span>
            </button>
          </div>

          <div className="flex-1 overflow-y-auto px-2" onClick={() => { if (activeMenuId) setActiveMenuId(null); }}>
            {chats.length > 0 && (
              <p className="text-[12px] font-bold text-[#A8A29D] uppercase tracking-wider px-3 mb-2 mt-1">Recent chats</p>
            )}
            <div className="space-y-1">
              {chats.map(chat => (
                <div key={chat.id} className="relative group">
                  <button
                    onClick={() => { setActiveChatId(chat.id); setIsSidebarMobileOpen(false); }}
                    className={`w-full text-left px-3 py-2.5 rounded-[16px] transition-all flex items-start gap-3 ${activeChatId === chat.id ? 'bg-[#FCEBE1] border border-[#F97316]/10 shadow-sm' : 'hover:bg-[#F0EBE3] border border-transparent'}`}
                  >
                    <div className={`mt-0.5 shrink-0 ${activeChatId === chat.id ? 'text-[#F97316]' : 'text-[#78716C]'}`}>
                      <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" /></svg>
                    </div>
                    <div className="flex flex-col flex-1 min-w-0 pr-6">
                      <span className="text-[13.5px] truncate font-semibold">{chat.title}</span>
                      <div className="flex items-center gap-1.5 mt-0.5">
                        <span className="text-[11px] font-medium text-[#A8A29D]">{getRelativeTime(chat.updatedAt)}</span>
                      </div>
                    </div>
                  </button>
                  <button
                    onClick={(e) => { e.stopPropagation(); setActiveMenuId(activeMenuId === chat.id ? null : chat.id); }}
                    className={`absolute right-2 top-1/2 -translate-y-1/2 p-2 rounded-lg text-[#78716C] hover:text-[#1E1B18] transition-all ${activeMenuId === chat.id ? 'opacity-100 bg-white shadow-sm' : 'opacity-0 md:group-hover:opacity-100 hover:bg-white hover:shadow-sm'}`}
                  >
                    <svg width="15" height="15" viewBox="0 0 24 24" fill="currentColor"><path d="M12 8c1.1 0 2-.9 2-2s-.9-2-2-2-2 .9-2 2 .9 2 2 2zm0 2c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm0 6c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2z" /></svg>
                  </button>
                  {activeMenuId === chat.id && (
                    <div className="absolute right-2 top-10 w-44 bg-white border border-[#EAE4DD] shadow-xl rounded-[16px] overflow-hidden z-[100] animate-in fade-in zoom-in-95 duration-100">
                      <button
                        onClick={(e) => { e.stopPropagation(); setRenameValue(chat.title); setRenameModal(chat.id); setActiveMenuId(null); }}
                        className="w-full text-left px-4 py-3 text-[13.5px] font-semibold hover:bg-[#F8F4EC] flex items-center gap-3 transition-colors"
                      >
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7" /><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z" /></svg>
                        Rename
                      </button>
                      <div className="h-px bg-[#EAE4DD]" />
                      <button
                        onClick={(e) => { e.stopPropagation(); setDeleteModal(chat.id); setActiveMenuId(null); }}
                        className="w-full text-left px-4 py-3 text-[13.5px] font-semibold hover:bg-[#FFF0F0] text-red-500 flex items-center gap-3 transition-colors"
                      >
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M3 6h18M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2" /></svg>
                        Delete
                      </button>
                    </div>
                  )}
                </div>
              ))}
            </div>
          </div>

          <div className="pt-2 px-3 pb-4 border-t border-[#EBE5DE] mt-2">
            <a href="https://github.com/brittytino/psgmx/releases" target="_blank" className="flex items-center justify-between px-3 py-3 hover:bg-[#F0EBE3] rounded-[16px] transition-all group">
              <div className="flex items-center gap-3">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor" className="text-[#1E1B18]"><path d="M12 2C6.47 2 2 6.48 2 12c0 4.42 2.87 8.17 6.84 9.5.5.08.66-.23.66-.5v-1.69c-2.77.6-3.36-1.34-3.36-1.34-.45-1.15-1.11-1.46-1.11-1.46-.91-.62.07-.6.07-.6 1 .07 1.53 1.03 1.53 1.03.87 1.52 2.34 1.07 2.91.83.09-.65.35-1.09.63-1.34-2.22-.25-4.55-1.11-4.55-4.92 0-1.11.38-2 1.03-2.71-.1-.25-.45-1.29.1-2.64 0 0 .84-.27 2.75 1.02.79-.22 1.65-.33 2.5-.33.85 0 1.71.11 2.5.33 1.91-1.29 2.75-1.02 2.75-1.02.55 1.35.2 2.39.1 2.64.65.71 1.03 1.6 1.03 2.71 0 3.82-2.34 4.66-4.57 4.91.36.31.69.92.69 1.85V21c0 .27.16.59.67.5C19.14 20.16 22 16.42 22 12A10 10 0 0012 2z"/></svg>
                <div>
                  <p className="text-[13.5px] font-bold text-[#1E1B18]">Download App</p>
                  <p className="text-[11px] text-[#78716C] font-medium">Android APK • iOS PWA</p>
                </div>
              </div>
              <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="text-[#A8A29D] group-hover:text-[#1E1B18] transition-colors"><path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6" /><polyline points="15 3 21 3 21 9" /><line x1="10" y1="14" x2="21" y2="3" /></svg>
            </a>
            <div className="h-px bg-[#EBE5DE] my-1 mx-3" />
            <Link href="/login" className="flex items-center justify-between px-3 py-3 hover:bg-[#F0EBE3] rounded-[16px] transition-all group">
              <div className="flex items-center gap-3">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="text-[#1E1B18]"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" /><circle cx="12" cy="7" r="4" /></svg>
                <span className="text-[13.5px] font-bold text-[#1E1B18]">Log in</span>
              </div>
              <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="text-[#A8A29D] group-hover:text-[#1E1B18] transition-colors"><path d="M9 18l6-6-6-6" /></svg>
            </Link>
          </div>
        </div>
      </div>

      {/* Main Area */}
      <div className="flex-1 flex flex-col relative z-10 w-full min-w-0 bg-[#FEFCFA]" onClick={() => { if (activeMenuId) setActiveMenuId(null); }}>

        {/* Navbar */}
        <div className="flex items-center justify-between p-4 px-5 sticky top-0 z-20 shrink-0 h-[68px] bg-white/70 backdrop-blur-md border-b border-[#EBE5DE]/50">
          <div className="flex items-center gap-2">
            {!isSidebarOpen && (
              <button onClick={(e) => { e.stopPropagation(); setIsSidebarOpen(true); }} className="hidden md:flex p-2 mr-1 text-[#78716C] hover:bg-[#F0EBE3] rounded-lg transition-colors">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><rect x="3" y="3" width="18" height="18" rx="2" /><line x1="9" y1="3" x2="9" y2="21" /></svg>
              </button>
            )}
            <button onClick={(e) => { e.stopPropagation(); setIsSidebarMobileOpen(true); }} className="p-2 mr-1 text-[#1E1B18] hover:bg-[#F0EBE3] rounded-lg transition-colors md:hidden">
              <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M4 6h16M4 12h16M4 18h16" /></svg>
            </button>
            <div className="font-bold text-[16px] flex items-center gap-2">
              <div className="w-6 h-6 rounded-full bg-white shadow-sm flex items-center justify-center border border-[#EAE4DD]">
                <img src="/logo.png" alt="Logo" className="w-4 h-4 object-contain" />
              </div>
              PSGMX Intelligence
              <span className="bg-[#FDE8D8] text-[#F97316] text-[10px] font-extrabold px-2 py-0.5 rounded-full uppercase tracking-wider hidden sm:inline-block">Core</span>
            </div>
          </div>
          <Link href="/login" className="px-5 py-2.5 bg-[#1E1B18] text-white rounded-full font-semibold text-[13.5px] hover:bg-black shadow-md hover:shadow-lg hover:-translate-y-0.5 transition-all flex items-center gap-2">
            Dashboard
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><path d="M5 12h14M12 5l7 7-7 7" /></svg>
          </Link>
        </div>

        {/* Chat Content */}
        <div className="flex-1 overflow-y-auto scroll-smooth min-h-0 flex flex-col pt-2">
          {messages.length === 0 ? (
            <div className="flex-1 flex flex-col items-center justify-center max-w-2xl mx-auto text-center px-6 pb-24 animate-in fade-in zoom-in-95 duration-500">
              <div className="w-[84px] h-[84px] bg-white rounded-full shadow-[0_8px_30px_rgb(0,0,0,0.08)] border border-[#EAE4DD] flex items-center justify-center mb-8 relative overflow-hidden">
                <img src="/logo.png" alt="PSGMX" className="w-[48px] h-[48px] object-contain z-10" />
                <div className="absolute inset-0 bg-gradient-to-t from-[#F97316]/5 to-transparent" />
              </div>
              <h1 className="text-[32px] md:text-[40px] font-extrabold mb-4 tracking-tight leading-tight text-[#1E1B18]">How can I help you today?</h1>
            </div>
          ) : (
            <div className="max-w-[800px] mx-auto flex flex-col w-full pb-8 pt-4 px-4 md:px-8">
              {messages.map(m => (
                <div key={m.id} className={`flex w-full mb-8 animate-in slide-in-from-bottom-2 fade-in duration-300 ${m.role === 'user' ? 'justify-end' : 'justify-start'}`}>
                  {m.role === 'user' ? (
                    <div className="bg-[#F0EBE3] text-[#1E1B18] px-5 py-3.5 rounded-[24px] rounded-br-[8px] max-w-[80%] whitespace-pre-wrap leading-relaxed font-medium text-[15.5px]">
                      {m.text}
                    </div>
                  ) : (
                    <div className="flex gap-4 w-full max-w-[90%] group">
                      <div className="w-8 h-8 rounded-full border border-[#EAE4DD] flex items-center justify-center flex-shrink-0 mt-0.5 bg-white shadow-sm">
                        <img src="/logo.png" alt="Bot" className="w-5 h-5 object-contain" />
                      </div>
                      <div className="flex-1 pt-1 text-[15.5px] font-medium text-[#1E1B18] leading-relaxed whitespace-pre-wrap">
                        {m.text.split('**').map((part, index) =>
                          index % 2 === 1 ? <strong key={index} className="font-extrabold text-black">{part}</strong> : part
                        )}
                        {m.isStreaming && <span className="inline-block w-2.5 h-[1.1em] ml-0.5 bg-[#1E1B18] rounded-full animate-pulse align-middle" />}
                      </div>
                    </div>
                  )}
                </div>
              ))}

              {isTyping && (
                <div className="flex gap-4 mb-8 animate-in fade-in">
                  <div className="w-8 h-8 rounded-full border border-[#EAE4DD] flex items-center justify-center flex-shrink-0 mt-0.5 bg-white shadow-sm">
                    <img src="/logo.png" alt="Bot" className="w-5 h-5 object-contain animate-pulse" />
                  </div>
                  <div className="pt-3 flex gap-1.5">
                    <div className="w-2 h-2 rounded-full bg-[#1E1B18]/40 animate-bounce" />
                    <div className="w-2 h-2 rounded-full bg-[#1E1B18]/60 animate-bounce" style={{ animationDelay: '0.15s' }} />
                    <div className="w-2 h-2 rounded-full bg-[#1E1B18] animate-bounce" style={{ animationDelay: '0.3s' }} />
                  </div>
                </div>
              )}
              <div ref={messagesEndRef} className="h-4" />
            </div>
          )}
        </div>

        {/* Input Area */}
        <div className="px-4 pb-6 md:pb-8 pt-2 shrink-0 relative z-20">
          <div className="absolute inset-0 bg-gradient-to-t from-[#FEFCFA] via-[#FEFCFA]/90 to-transparent pointer-events-none" />
          <div className="max-w-[800px] mx-auto relative flex flex-col gap-3 px-0 md:px-8">

            {messages.length === 0 && (
              <div className="grid grid-cols-1 md:grid-cols-2 gap-3 mb-4 animate-in slide-in-from-bottom-2 fade-in duration-500">
                {SUGGESTIONS.map((s, i) => (
                  <button
                    key={i}
                    onClick={() => handleSend(s)}
                    className="text-left px-5 py-3.5 bg-white border border-[#EBE5DE] rounded-[18px] text-[14px] font-semibold text-[#78716C] hover:bg-[#F8F4EC] hover:text-[#1E1B18] transition-all shadow-sm hover:shadow-md flex items-center justify-between group"
                  >
                    <span className="truncate pr-4">{s}</span>
                    <div className="w-6 h-6 rounded-full bg-[#F0EBE3] flex items-center justify-center text-[#1E1B18] opacity-0 group-hover:opacity-100 transition-opacity shrink-0">
                      <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3"><path d="M5 12h14M12 5l7 7-7 7" /></svg>
                    </div>
                  </button>
                ))}
              </div>
            )}

            <form
              onSubmit={(e) => { e.preventDefault(); handleSend(query); }}
              className="relative flex items-end bg-[#F0EBE3] rounded-[32px] focus-within:ring-2 focus-within:ring-[#EAE4DD] transition-all p-1.5 shadow-sm"
            >
              <textarea
                ref={textareaRef}
                value={query}
                onChange={e => { setQuery(e.target.value); adjustTextareaHeight(); }}
                onKeyDown={handleKeyDown}
                placeholder="Message PSGMX Intelligence..."
                disabled={isTyping}
                className="flex-1 bg-transparent py-[14px] px-5 outline-none text-[#1E1B18] font-medium placeholder-[#A8A29D] resize-none min-h-[52px] h-[52px] max-h-[200px] text-[15.5px] leading-relaxed overflow-y-auto disabled:opacity-50"
                style={{ scrollbarWidth: 'none' }}
              />
              <button
                type="submit"
                disabled={!query.trim() || isTyping}
                className={`p-2.5 mr-1 mb-1 rounded-full transition-all flex items-center justify-center w-[38px] h-[38px] shrink-0 ${query.trim() && !isTyping ? 'bg-[#1E1B18] text-white hover:bg-black shadow-md hover:-translate-y-0.5' : 'bg-[#E5DFD5] text-[#A8A29D]'}`}
              >
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><path d="M12 19V5M5 12l7-7 7 7" /></svg>
              </button>
            </form>

            <p className="text-center text-[12px] text-[#A8A29D] font-medium mt-1">
              PSGMX Intelligence can make mistakes. Consider verifying important information.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
