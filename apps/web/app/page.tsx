'use client';

import { useState, useRef, useEffect } from 'react';
import Link from 'next/link';

type Message = { id: string; role: 'user' | 'bot'; text: string; isStreaming?: boolean };

// Advanced Product Logic
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
    return "PSGMX is the ultimate **Placement Operating System** built exclusively for PSG Tech MCA students. \n\nWe provide a completely unified platform to track, prepare, and collaborate for placements. Key features include the AI Mentor, Codebox, Daily Five, and an extensive Placement Rep Dashboard for analytics.\n\nWhat specific feature would you like to know more about?";
  }
  if (lower.includes('hello') || lower.includes('hi') || lower.includes('hey')) {
    return "Hello! I'm the PSGMX AI Guide. \n\nI can help you understand all the features of our Placement Operating System, from the AI Mentor to the Codebox, or help you download the app. What would you like to explore today?";
  }
  
  return "That's a great question. PSGMX is a comprehensive Placement Operating System with many features including the AI Mentor, Codebox, and Daily Five. \n\nTo see it in action, I highly recommend logging into the dashboard or downloading the Android app from our GitHub repository. Can I help you with information about a specific feature?";
}

export default function LandingPage() {
  const [query, setQuery] = useState('');
  const [messages, setMessages] = useState<Message[]>([]);
  const [isSidebarOpen, setIsSidebarOpen] = useState(true);
  const [isTyping, setIsTyping] = useState(false);
  
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const textareaRef = useRef<HTMLTextAreaElement>(null);

  // Auto-resize textarea
  const adjustTextareaHeight = () => {
    if (textareaRef.current) {
      textareaRef.current.style.height = 'auto';
      textareaRef.current.style.height = `${Math.min(textareaRef.current.scrollHeight, 200)}px`;
    }
  };

  useEffect(() => {
    if (messagesEndRef.current) {
      messagesEndRef.current.scrollIntoView({ behavior: "smooth" });
    }
  }, [messages, isTyping]);

  // Handle mobile sidebar auto-close
  useEffect(() => {
    const checkWidth = () => {
      if (window.innerWidth < 768) setIsSidebarOpen(false);
      else setIsSidebarOpen(true);
    };
    checkWidth();
    window.addEventListener('resize', checkWidth);
    return () => window.removeEventListener('resize', checkWidth);
  }, []);

  const simulateStream = (fullText: string) => {
    setIsTyping(false);
    const words = fullText.split(' ');
    let currentText = '';
    const msgId = crypto.randomUUID();
    
    setMessages(prev => [...prev, { id: msgId, role: 'bot', text: '', isStreaming: true }]);

    let i = 0;
    const interval = setInterval(() => {
      if (i < words.length) {
        currentText += (i === 0 ? '' : ' ') + words[i];
        setMessages(prev => prev.map(m => m.id === msgId ? { ...m, text: currentText } : m));
        i++;
      } else {
        clearInterval(interval);
        setMessages(prev => prev.map(m => m.id === msgId ? { ...m, isStreaming: false } : m));
      }
    }, 45); // Speed of typing
  };

  const handleSend = (text: string) => {
    if (!text.trim()) return;
    
    const newMsg: Message = { id: crypto.randomUUID(), role: 'user', text };
    setMessages(prev => [...prev, newMsg]);
    setQuery('');
    if (textareaRef.current) {
      textareaRef.current.style.height = 'auto';
    }

    setIsTyping(true);

    // Simulate thinking delay
    setTimeout(() => {
      const response = generateResponse(text);
      simulateStream(response);
    }, 1200 + Math.random() * 800);
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSend(query);
    }
  };

  return (
    <div className="flex h-[100dvh] w-full bg-[#212121] text-[#ECECEC] font-sans overflow-hidden text-[15px]">
      
      {/* Sidebar Overlay (Mobile) */}
      <div 
        className={`fixed inset-0 bg-black/50 z-40 md:hidden transition-opacity duration-300 ${isSidebarOpen ? 'opacity-100' : 'opacity-0 pointer-events-none'}`} 
        onClick={() => setIsSidebarOpen(false)}
      />
      
      {/* Sidebar */}
      <div 
        className={`fixed md:relative z-50 h-full bg-[#171717] flex flex-col transition-all duration-300 ease-in-out shrink-0 overflow-hidden
          ${isSidebarOpen ? 'w-[260px] translate-x-0' : 'w-0 -translate-x-full md:translate-x-0 md:w-0'}
        `}
      >
        <div className="w-[260px] h-full flex flex-col p-3">
          <div className="flex items-center justify-between mb-4">
            <button 
              onClick={() => { setIsSidebarOpen(false); setTimeout(() => setIsSidebarOpen(true), 10); setMessages([]); }}
              className="flex-1 flex items-center gap-2 hover:bg-[#202123] px-3 py-2 rounded-lg transition-colors font-medium text-sm text-[#ECECEC]"
            >
              <div className="bg-white text-black p-0.5 rounded-full mr-1">
                 <img src="/logo.png" alt="Logo" className="w-5 h-5 object-contain" />
              </div>
              New chat
            </button>
            <button onClick={() => setIsSidebarOpen(false)} className="p-2 text-[#ECECEC] hover:bg-[#202123] rounded-lg md:hidden">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M18 6L6 18M6 6l12 12"/></svg>
            </button>
          </div>
          
          <div className="flex-1 overflow-y-auto">
            <div className="text-xs font-semibold text-[#8E8EA0] mb-3 px-3 uppercase">Today</div>
            {['What is PSGMX?', 'How to download the app?', 'Tell me about AI Mentor'].map((t, i) => (
              <button key={i} onClick={() => { handleSend(t); if(window.innerWidth < 768) setIsSidebarOpen(false); }} className="w-full text-left px-3 py-2 text-sm text-[#ECECEC] hover:bg-[#2A2B32] rounded-lg truncate transition-colors">
                {t}
              </button>
            ))}
          </div>

          <div className="border-t border-[#4D4D4F] pt-2 mt-2 space-y-1">
             <a href="https://github.com/brittytino/psgmx/releases" target="_blank" className="flex items-center gap-3 px-3 py-3 hover:bg-[#2A2B32] rounded-lg text-sm font-medium transition-colors">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.47 2 2 6.48 2 12c0 4.42 2.87 8.17 6.84 9.5.5.08.66-.23.66-.5v-1.69c-2.77.6-3.36-1.34-3.36-1.34-.45-1.15-1.11-1.46-1.11-1.46-.91-.62.07-.6.07-.6 1 .07 1.53 1.03 1.53 1.03.87 1.52 2.34 1.07 2.91.83.09-.65.35-1.09.63-1.34-2.22-.25-4.55-1.11-4.55-4.92 0-1.11.38-2 1.03-2.71-.1-.25-.45-1.29.1-2.64 0 0 .84-.27 2.75 1.02.79-.22 1.65-.33 2.5-.33.85 0 1.71.11 2.5.33 1.91-1.29 2.75-1.02 2.75-1.02.55 1.35.2 2.39.1 2.64.65.71 1.03 1.6 1.03 2.71 0 3.82-2.34 4.66-4.57 4.91.36.31.69.92.69 1.85V21c0 .27.16.59.67.5C19.14 20.16 22 16.42 22 12A10 10 0 0012 2z"/></svg>
                Download App
             </a>
             <Link href="/login" className="flex items-center gap-3 px-3 py-3 hover:bg-[#2A2B32] rounded-lg text-sm font-medium transition-colors">
                <div className="w-6 h-6 rounded-full bg-gradient-to-tr from-[#FF5A1F] to-[#FFA27F] flex items-center justify-center text-[10px] text-white">
                  PT
                </div>
                Log in to Dashboard
             </Link>
          </div>
        </div>
      </div>

      {/* Main Chat Area */}
      <div className="flex-1 flex flex-col relative z-10 w-full min-w-0 bg-[#212121]">
        
        {/* Navbar */}
        <div className="flex items-center justify-between p-3 sticky top-0 z-20 shrink-0 h-[60px]">
          <div className="flex items-center">
            {!isSidebarOpen && (
              <button onClick={() => setIsSidebarOpen(true)} className="p-2 mr-2 text-[#ECECEC] hover:bg-[#2f2f2f] rounded-lg transition-colors">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M4 6h16M4 12h16M4 18h16"/></svg>
              </button>
            )}
            <div className="font-semibold text-lg flex items-center gap-2 cursor-pointer hover:bg-[#2f2f2f] px-3 py-1.5 rounded-xl transition-colors">
              PSGMX Guide <span className="text-[#8E8EA0] text-sm">v4</span>
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M6 9l6 6 6-6"/></svg>
            </div>
          </div>
          <Link href="/login" className="md:hidden w-8 h-8 rounded-full bg-gradient-to-tr from-[#FF5A1F] to-[#FFA27F] flex items-center justify-center text-[12px] font-bold text-white shadow-sm">
            PT
          </Link>
        </div>

        {/* Chat History */}
        <div className="flex-1 overflow-y-auto px-4 scroll-smooth min-h-0 relative">
          {messages.length === 0 ? (
            <div className="h-full flex flex-col items-center justify-center max-w-2xl mx-auto text-center px-4 animate-in fade-in duration-700">
              <h1 className="text-3xl font-semibold mb-8 text-[#ECECEC]">Where should we begin?</h1>
              {/* Optional: Add suggestions here if you want them in the center before chatting, but ChatGPT UI usually keeps it clean. */}
            </div>
          ) : (
            <div className="max-w-3xl mx-auto flex flex-col pb-8 pt-4">
              {messages.map(m => (
                <div key={m.id} className={`flex w-full mb-6 ${m.role === 'user' ? 'justify-end' : 'justify-start'}`}>
                  {m.role === 'user' ? (
                    <div className="bg-[#2f2f2f] text-[#ECECEC] px-5 py-3 rounded-3xl max-w-[85%] whitespace-pre-wrap leading-relaxed shadow-sm">
                      {m.text}
                    </div>
                  ) : (
                    <div className="flex gap-4 w-full max-w-[100%] group">
                      <div className="w-[30px] h-[30px] rounded-full border border-[#4D4D4F] flex items-center justify-center flex-shrink-0 mt-1 bg-white">
                        <img src="/logo.png" alt="Bot" className="w-[20px] h-[20px] object-contain" />
                      </div>
                      <div className="flex-1 space-y-4">
                        <div className="text-[#ECECEC] leading-relaxed whitespace-pre-wrap pt-1 font-medium">
                          {/* Parse markdown-like bolding for realistic feel */}
                          {m.text.split('**').map((part, index) => 
                            index % 2 === 1 ? <strong key={index} className="text-white font-bold">{part}</strong> : part
                          )}
                          {m.isStreaming && <span className="inline-block w-2 h-4 ml-1 bg-white animate-pulse rounded-sm align-middle"></span>}
                        </div>
                        
                        {!m.isStreaming && (
                          <div className="flex gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                            <button className="p-1.5 text-[#8E8EA0] hover:text-[#ECECEC] hover:bg-[#2f2f2f] rounded-md transition-colors"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z"/></svg></button>
                            <button className="p-1.5 text-[#8E8EA0] hover:text-[#ECECEC] hover:bg-[#2f2f2f] rounded-md transition-colors"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M14 9V5a3 3 0 0 0-3-3l-4 9v11h11.28a2 2 0 0 0 2-1.7l1.38-9a2 2 0 0 0-2-2.3zM7 22H4a2 2 0 0 1-2-2v-7a2 2 0 0 1 2-2h3"/></svg></button>
                            <button className="p-1.5 text-[#8E8EA0] hover:text-[#ECECEC] hover:bg-[#2f2f2f] rounded-md transition-colors"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M10 15v4a3 3 0 0 0 3 3l4-9V2H5.72a2 2 0 0 0-2 1.7l-1.38 9a2 2 0 0 0 2 2.3zm7-13h3a2 2 0 0 1 2 2v7a2 2 0 0 1-2 2h-3"/></svg></button>
                          </div>
                        )}
                      </div>
                    </div>
                  )}
                </div>
              ))}
              
              {/* Thinking Indicator */}
              {isTyping && (
                <div className="flex gap-4 w-full max-w-[100%] animate-in fade-in duration-300">
                  <div className="w-[30px] h-[30px] rounded-full border border-[#4D4D4F] flex items-center justify-center flex-shrink-0 mt-1 bg-white relative overflow-hidden">
                     <img src="/logo.png" alt="Bot" className="w-[20px] h-[20px] object-contain animate-pulse" />
                     {/* Cool GSAP-like circular sweep effect using CSS */}
                     <div className="absolute inset-0 bg-white/40 animate-[spin_2s_linear_infinite] rounded-full" style={{ borderTop: '2px solid #FF5A1F' }}></div>
                  </div>
                  <div className="pt-2">
                     <div className="flex gap-1.5">
                       <div className="w-2 h-2 rounded-full bg-[#8E8EA0] animate-bounce"></div>
                       <div className="w-2 h-2 rounded-full bg-[#8E8EA0] animate-bounce" style={{ animationDelay: '0.15s' }}></div>
                       <div className="w-2 h-2 rounded-full bg-[#8E8EA0] animate-bounce" style={{ animationDelay: '0.3s' }}></div>
                     </div>
                  </div>
                </div>
              )}
              
              <div ref={messagesEndRef} className="h-2" />
            </div>
          )}
        </div>

        {/* Input Area */}
        <div className="px-4 pb-4 md:pb-6 pt-2 shrink-0 relative z-20 bg-gradient-to-t from-[#212121] via-[#212121] to-transparent">
          <div className="max-w-3xl mx-auto relative">
            <form 
              onSubmit={(e) => { e.preventDefault(); handleSend(query); }} 
              className="relative flex items-end bg-[#2f2f2f] border border-[#4D4D4F]/50 rounded-[26px] shadow-lg transition-all"
            >
              <button type="button" className="p-3 m-1 text-[#ECECEC] hover:bg-[#404040] rounded-full transition-colors shrink-0">
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
                className="flex-1 bg-transparent py-[18px] outline-none text-[#ECECEC] placeholder-[#8E8EA0] resize-none min-h-[60px] h-[60px] max-h-[200px] text-[15px] leading-relaxed overflow-y-auto"
              />
              {query.trim() ? (
                <button 
                  type="submit" 
                  className="p-2 m-2 rounded-full shrink-0 transition-all bg-white text-black hover:bg-[#ececec] shadow-sm transform hover:scale-105"
                >
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor"><path d="M4 12l1.41 1.41L11 7.83V20h2V7.83l5.58 5.59L20 12l-8-8-8 8z"/></svg>
                </button>
              ) : (
                <button type="button" className="p-3 m-1 text-[#ECECEC] hover:bg-[#404040] rounded-full transition-colors shrink-0">
                  <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M12 2a3 3 0 0 0-3 3v7a3 3 0 0 0 6 0V5a3 3 0 0 0-3-3z"/><path d="M19 10v2a7 7 0 0 1-14 0v-2M12 19v4M8 23h8"/></svg>
                </button>
              )}
            </form>
            <div className="text-center text-[12px] text-[#8E8EA0] mt-3">
              PSGMX Guide can make mistakes. Please verify important placement updates on the dashboard.
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
