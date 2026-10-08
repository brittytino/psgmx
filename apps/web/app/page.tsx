'use client';

import { useState, useRef, useEffect, FormEvent } from 'react';
import Link from 'next/link';

type Message = { id: string; role: 'user' | 'bot'; text: string };

const SUGGESTIONS = [
  "What is PSGMX?",
  "How do I download the app?",
  "What features are available?",
  "Is there an iOS version?"
];

export default function LandingPage() {
  const [query, setQuery] = useState('');
  const [messages, setMessages] = useState<Message[]>([]);
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const bgRef = useRef<HTMLDivElement>(null);

  // GSAP animation for background orbs
  useEffect(() => {
    const script = document.createElement('script');
    script.src = "https://cdnjs.cloudflare.com/ajax/libs/gsap/3.12.2/gsap.min.js";
    script.onload = () => {
      const gsap = (window as any).gsap;
      if (gsap && bgRef.current) {
        const orbs = Array.from(bgRef.current.children);
        orbs.forEach((orb, i) => {
          gsap.to(orb, {
            x: "random(-150, 150)",
            y: "random(-150, 150)",
            duration: "random(8, 15)",
            repeat: -1,
            yoyo: true,
            ease: "sine.inOut",
            delay: i * -2,
          });
        });
      }
    };
    document.body.appendChild(script);
    return () => { 
      if (document.body.contains(script)) {
        document.body.removeChild(script); 
      }
    };
  }, []);

  // Auto-scroll to latest message
  useEffect(() => {
    if (messagesEndRef.current) {
      messagesEndRef.current.scrollIntoView({ behavior: "smooth" });
    }
  }, [messages]);

  const handleSend = (text: string) => {
    if (!text.trim()) return;
    
    const newMsg: Message = { id: crypto.randomUUID(), role: 'user', text };
    setMessages(prev => [...prev, newMsg]);
    setQuery('');

    // Predefined product logic responses
    setTimeout(() => {
      let reply = "This web interface is designed to answer product questions. To access the full placement operating system, including the AI Mentor, Codebox, and Daily Five, please download the Android app from GitHub or log in to the dashboard.";
      
      const lower = text.toLowerCase();
      if (lower.includes('download') || lower.includes('apk') || lower.includes('android') || lower.includes('github') || lower.includes('install') || lower.includes('app')) {
        reply = "You can download the latest Android APK directly from our GitHub repository at github.com/brittytino/psgmx/releases. The web portal is currently optimized for desktop and product previews.";
      } else if (lower.includes('what is') || lower.includes('about')) {
        reply = "PSGMX is a Placement Operating System built exclusively for PSG Tech MCA students. It offers AI-assisted interview training, coding practice, and placement tracking all in one cream-themed app.";
      } else if (lower.includes('feature')) {
        reply = "PSGMX features include: The Daily Five (micro-learning loops), AI Senior (technical doubts), AI Mentor (interview practice with audio recording), Codebox, and real-time placement tracking.";
      } else if (lower.includes('ios') || lower.includes('iphone') || lower.includes('apple') || lower.includes('mac')) {
        reply = "For iOS users, you can install PSGMX as a Progressive Web App (PWA). Just open app.psgmx.tech in Safari, tap the Share icon, and select 'Add to Home Screen'.";
      }

      setMessages(prev => [...prev, { id: crypto.randomUUID(), role: 'bot', text: reply }]);
    }, 600);
  };

  return (
    <div className="flex h-[100dvh] w-full bg-[#FBF6EE] text-[#221F1A] font-sans overflow-hidden selection:bg-[#FF5A1F]/20">
      
      {/* Background GSAP Orbs */}
      <div ref={bgRef} className="absolute inset-0 overflow-hidden pointer-events-none z-0 opacity-60">
        <div className="absolute top-[10%] left-[20%] w-[30rem] h-[30rem] bg-[#FF5A1F] rounded-full mix-blend-multiply filter blur-[100px] opacity-15"></div>
        <div className="absolute top-[50%] left-[60%] w-[40rem] h-[40rem] bg-[#FF8C66] rounded-full mix-blend-multiply filter blur-[120px] opacity-20"></div>
        <div className="absolute top-[30%] left-[50%] w-[25rem] h-[25rem] bg-[#FFD7C2] rounded-full mix-blend-multiply filter blur-[80px] opacity-30"></div>
      </div>

      {/* Sidebar Overlay (Mobile) */}
      <div 
        className={`fixed inset-0 bg-black/20 z-40 md:hidden transition-opacity ${isSidebarOpen ? 'opacity-100' : 'opacity-0 pointer-events-none'}`} 
        onClick={() => setIsSidebarOpen(false)}
      />
      
      {/* Sidebar */}
      <div className={`fixed md:relative z-50 w-[260px] h-full bg-[#F5EDE1] border-r border-[#EAE0D3] flex flex-col transition-transform duration-300 ${isSidebarOpen ? 'translate-x-0' : '-translate-x-full md:translate-x-0'}`}>
        
        <div className="p-4 flex items-center justify-between">
          <button 
            onClick={() => { setMessages([]); setIsSidebarOpen(false); }} 
            className="flex-1 flex items-center gap-3 hover:bg-[#EAE0D3]/60 p-2.5 rounded-xl transition-colors font-medium text-[15px]"
          >
            <div className="bg-white p-1 rounded-md shadow-sm border border-[#EAE0D3]">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><path d="M12 5v14M5 12h14"/></svg>
            </div>
            New chat
          </button>
          <button className="md:hidden p-2 text-[#8B8C8E]" onClick={() => setIsSidebarOpen(false)}>
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M18 6L6 18M6 6l12 12"/></svg>
          </button>
        </div>
        
        <div className="flex-1 overflow-y-auto p-4 pt-2 space-y-1">
          <div className="text-xs font-semibold text-[#8B8C8E] mb-3 px-2 uppercase tracking-wider">Suggested Queries</div>
          {SUGGESTIONS.map((s, i) => (
            <button 
              key={i} 
              onClick={() => { handleSend(s); setIsSidebarOpen(false); }} 
              className="w-full text-left px-3 py-2.5 text-[14px] text-[#4A4A4C] hover:bg-[#EAE0D3]/60 hover:text-[#221F1A] rounded-xl transition-colors truncate block"
            >
              {s}
            </button>
          ))}
        </div>

        <div className="p-4 border-t border-[#EAE0D3] flex flex-col gap-2 bg-[#F5EDE1]">
           <a href="https://github.com/brittytino/psgmx/releases" target="_blank" className="flex items-center gap-3 px-3 py-3 hover:bg-white rounded-xl text-[14px] font-medium transition-all shadow-sm border border-transparent hover:border-[#EAE0D3]">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.47 2 2 6.48 2 12c0 4.42 2.87 8.17 6.84 9.5.5.08.66-.23.66-.5v-1.69c-2.77.6-3.36-1.34-3.36-1.34-.45-1.15-1.11-1.46-1.11-1.46-.91-.62.07-.6.07-.6 1 .07 1.53 1.03 1.53 1.03.87 1.52 2.34 1.07 2.91.83.09-.65.35-1.09.63-1.34-2.22-.25-4.55-1.11-4.55-4.92 0-1.11.38-2 1.03-2.71-.1-.25-.45-1.29.1-2.64 0 0 .84-.27 2.75 1.02.79-.22 1.65-.33 2.5-.33.85 0 1.71.11 2.5.33 1.91-1.29 2.75-1.02 2.75-1.02.55 1.35.2 2.39.1 2.64.65.71 1.03 1.6 1.03 2.71 0 3.82-2.34 4.66-4.57 4.91.36.31.69.92.69 1.85V21c0 .27.16.59.67.5C19.14 20.16 22 16.42 22 12A10 10 0 0012 2z"/></svg>
              Download APK
           </a>
           <Link href="/login" className="flex items-center gap-3 px-3 py-3 hover:bg-white rounded-xl text-[14px] font-medium transition-all shadow-sm border border-transparent hover:border-[#EAE0D3]">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4M10 17l5-5-5-5M15 12H3"/></svg>
              Log in to Dashboard
           </Link>
        </div>
      </div>

      {/* Main Chat Area */}
      <div className="flex-1 flex flex-col relative z-10 w-full min-w-0">
        
        {/* Navbar (Mobile) */}
        <div className="flex items-center justify-between p-3 border-b border-[#E8DFD1]/50 md:hidden bg-[#FBF6EE]/80 backdrop-blur-md sticky top-0 z-20 shrink-0">
          <button onClick={() => setIsSidebarOpen(true)} className="p-2.5 text-[#4A4A4C] hover:bg-[#EAE0D3]/50 rounded-lg transition-colors">
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M3 12h18M3 6h18M3 18h18"/></svg>
          </button>
          <span className="font-semibold text-base text-[#221F1A]">PSGMX Guide</span>
          <div className="w-10"></div>
        </div>

        {/* Top Banner (Desktop & Mobile) */}
        <div className="bg-white/40 text-[#C74514] text-xs md:text-sm px-4 py-2.5 text-center border-b border-[#FF8C66]/10 backdrop-blur-md shrink-0">
          ⚠️ This web interface is a preview for product questions. <a href="https://github.com/brittytino/psgmx/releases" target="_blank" className="font-semibold underline decoration-[#C74514]/40 hover:decoration-[#C74514] underline-offset-2 transition-colors">Download the Android app on GitHub</a> for full features.
        </div>

        {/* Chat History */}
        <div className="flex-1 overflow-y-auto px-4 py-6 scroll-smooth min-h-0">
          {messages.length === 0 ? (
            <div className="h-full flex flex-col items-center justify-center max-w-2xl mx-auto text-center px-4 animate-in fade-in duration-700">
              <div className="w-16 h-16 bg-white rounded-[20px] shadow-sm border border-[#E8DFD1] flex items-center justify-center mb-6">
                 <img src="/logo.png" alt="PSGMX" className="w-10 h-10 object-contain" />
              </div>
              <h1 className="text-3xl md:text-4xl font-semibold mb-10 text-[#221F1A] tracking-tight">How can I help you today?</h1>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 w-full">
                {SUGGESTIONS.map((s, i) => (
                  <button 
                    key={i} 
                    onClick={() => handleSend(s)} 
                    className="p-4 border border-[#E8DFD1] bg-white/60 hover:bg-white rounded-2xl text-left transition-all shadow-sm hover:shadow-md hover:border-[#FF5A1F]/30 group"
                  >
                    <div className="font-medium text-[#221F1A] text-[15px] mb-1 group-hover:text-[#FF5A1F] transition-colors">{s.split('?')[0]}?</div>
                    <div className="text-[13px] text-[#8B8C8E]">Ask about this topic</div>
                  </button>
                ))}
              </div>
            </div>
          ) : (
            <div className="max-w-3xl mx-auto flex flex-col gap-6 pb-4">
              {messages.map(m => (
                <div key={m.id} className={`flex gap-4 ${m.role === 'user' ? 'justify-end' : 'justify-start'} animate-in slide-in-from-bottom-2 fade-in duration-300`}>
                  {m.role === 'bot' && (
                    <div className="w-8 h-8 rounded-full bg-white shadow-sm border border-[#E8DFD1] flex items-center justify-center flex-shrink-0 mt-0.5">
                      <img src="/logo.png" alt="Bot" className="w-5 h-5 object-contain" />
                    </div>
                  )}
                  <div className={`px-5 py-3.5 max-w-[85%] text-[15px] leading-relaxed ${m.role === 'user' ? 'bg-[#221F1A] text-white rounded-2xl rounded-tr-sm shadow-sm' : 'bg-white border border-[#E8DFD1] text-[#221F1A] rounded-2xl rounded-tl-sm shadow-sm'}`}>
                    {m.text}
                  </div>
                </div>
              ))}
              <div ref={messagesEndRef} className="h-4" />
            </div>
          )}
        </div>

        {/* Input Area */}
        <div className="p-4 shrink-0 relative z-20 pb-4 md:pb-6">
          <div className="max-w-3xl mx-auto relative">
            <form 
              onSubmit={(e) => { e.preventDefault(); handleSend(query); }} 
              className="relative flex items-end bg-white border border-[#E8DFD1] rounded-[24px] shadow-lg shadow-black/5 focus-within:ring-2 ring-[#FF5A1F]/20 focus-within:border-[#FF5A1F]/40 transition-all"
            >
              <button type="button" className="p-3 m-1.5 text-[#8B8C8E] hover:bg-[#F5EDE1] rounded-full transition-colors shrink-0">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M21.44 11.05l-9.19 9.19a6 6 0 01-8.49-8.49l9.19-9.19a4 4 0 015.66 5.66l-9.2 9.19a2 2 0 01-2.83-2.83l8.49-8.48"/></svg>
              </button>
              <textarea
                value={query}
                onChange={e => {
                  setQuery(e.target.value);
                  e.target.style.height = '56px';
                  e.target.style.height = Math.min(e.target.scrollHeight, 128) + 'px';
                }}
                onKeyDown={e => {
                  if (e.key === 'Enter' && !e.shiftKey) {
                    e.preventDefault();
                    handleSend(query);
                  }
                }}
                placeholder="Message PSGMX Guide..."
                className="flex-1 bg-transparent py-4 outline-none text-[#221F1A] placeholder-[#8B8C8E] resize-none min-h-[56px] h-[56px] text-[15px] leading-relaxed"
              />
              <button 
                type="submit" 
                disabled={!query.trim()} 
                className={`p-2 m-2 rounded-full shrink-0 transition-all ${query.trim() ? 'bg-[#221F1A] text-white hover:bg-black shadow-sm transform hover:scale-105' : 'bg-[#F5EDE1] text-[#C4C4C4]'}`}
              >
                <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M4 12l1.41 1.41L11 7.83V20h2V7.83l5.58 5.59L20 12l-8-8-8 8z"/></svg>
              </button>
            </form>
            <div className="text-center text-[11px] text-[#8B8C8E] mt-3 tracking-wide">
              PSGMX Guide is for product queries only. Log in for full AI Mentor access.
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
