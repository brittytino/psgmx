'use client';

import { useEffect, useState, FormEvent } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';

export default function LandingPage() {
  const router = useRouter();
  const [query, setQuery] = useState('');

  useEffect(() => {
    document.documentElement.classList.add('anim');
    const timer = setTimeout(() => {
      document.documentElement.classList.remove('anim');
    }, 2600);
    return () => {
      clearTimeout(timer);
      document.documentElement.classList.remove('anim');
    };
  }, []);

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault();
    if (query.trim()) {
      router.push(`/student?q=${encodeURIComponent(query)}`);
    } else {
      router.push('/login');
    }
  };

  return (
    <>
      <style dangerouslySetInnerHTML={{ __html: `
        :root {
          --u: min(0.06410256vw, 0.12400794vh);
          --vu: 0.09920635vh;
          --inset-top: 41; --inset-bottom: 106;
          
          /* Nav */
          --brand-x:225; --brand-y:45; --mark:34; --brand-gap:12; --brand-fs:18.49;
          --links-y:50.5; --links-gap:50; --links-fs:21.69;
          --cta-x:1195; --cta-y:42; --cta-w:140; --cta-h:43; --cta-r:12; --cta-fs:15.70; --cta-dy:2;
          
          /* Hero */
          --hero-gap:51;
          --h1-y:323; --h1-fs:36.25; --display-ls:0.0018em;
          --nav-ls:-0.0115em; --brand-ls:-0.0154em; --cta-ls:-0.0127em; --body-ls:0.007em;
          --label-ls:normal; --model-ls:normal; --proof-ls:0.0065em;
          
          /* Composer */
          --card-x:425; --card-y:413; --card-w:708; --card-h:143; --card-r:26;
          --ph-x:452; --ph-y:446; --ph-fs:9.97;
          --chips-x:444; --chips-y:505; --chip-h:30; --chip-r:9; --chip-fs:9.0; --chip-gap:5.5;
          --son-fs:10.4; --son-top:15.5; --chev-gap:6.2;
          --chev-x:1013.5; --chev-y:522.3;
          --att-x:1043.2; --att-y:515.1;
          --send-x:1084; --send-y:507; --send-d:35;
          
          /* Footer */
          --by-y:799; --by-fs:14.01; --logo-y:867; --logo-gap:62;
        }
        @supports (height:100dvh) {
          :root {
            --u: min(0.06410256vw, 0.12400794dvh);
            --vu: 0.09920635dvh;
          }
        }
        @media (min-width:1561px) { :root { --inset-top:27; --inset-bottom:74; } }
        
        *,*::before,*::after { box-sizing:border-box; margin:0; padding:0 }
        button,input,textarea { font:inherit; color:inherit; background:none; border:0; outline:none; }
        img,svg { display:block }
        
        :focus-visible { outline: 2px solid #F8B285; outline-offset: 3px; border-radius: 4px; }

        body {
          font-family: Inter, -apple-system, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
          font-synthesis: none;
          -webkit-font-smoothing: antialiased;
          -moz-osx-font-smoothing: grayscale;
          text-rendering: geometricPrecision;
          overflow: hidden;
          background: #0a0d12; /* Fallback */
        }
        
        .stage {
          position: fixed; inset: 0; overflow: hidden; background: #FBF6EE;
        }
        .stage-bg {
          position: absolute; inset: 0; width: 100%; height: 100%;
          background: radial-gradient(circle at 50% -20%, #FFFFFF 0%, #FBF6EE 60%);
          z-index: 0;
        }
        
        .frame {
          position: absolute; inset: 0; z-index: 1; display: flex; flex-direction: column;
          padding: calc(var(--inset-top)*var(--vu)) calc(225*var(--u)) calc(var(--inset-bottom)*var(--vu));
        }
        
        /* Mobile Menu Checkbox */
        #menu { display: none; }
        .burger { display: none; }
        .sheet { display: none; }
        
        /* Nav */
        .nav {
          height: calc(43*var(--u)); display: flex; align-items: center; justify-content: space-between;
          position: relative;
        }
        .brand {
          display: flex; align-items: center; gap: calc(var(--brand-gap)*var(--u));
          text-decoration: none; color: #221F1A;
          font-size: calc(var(--brand-fs)*var(--u)); font-weight: 500;
          letter-spacing: var(--brand-ls); font-variation-settings: "opsz" 32;
        }
        .brand-text { transform: translateY(calc(1 * var(--u))); }
        
        .links {
          position: absolute; left: 50%; transform: translateX(-50%);
          top: calc((50.5 - 41)*var(--u));
          display: flex; gap: calc(var(--links-gap)*var(--u));
        }
        .links a {
          font-size: calc(var(--links-fs)*var(--u)); font-weight: 400;
          letter-spacing: var(--nav-ls); line-height: 1.2; color: #4A4A4C;
          text-decoration: none;
          transition: color 0.18s ease;
        }
        .links a:hover { color: #111; }
        
        .cta {
          width: calc(var(--cta-w)*var(--u)); height: calc(var(--cta-h)*var(--u));
          border-radius: calc(var(--cta-r)*var(--u));
          font-size: calc(var(--cta-fs)*var(--u)); font-weight: 520;
          letter-spacing: var(--cta-ls);
          align-self: flex-start; margin-top: calc((42 - 41)*var(--u));
          background: linear-gradient(180deg, #3d3d3f 0%, #1d1d20 100%);
          color: white; text-decoration: none;
          display: flex; align-items: center; justify-content: center;
          box-shadow: inset 0 calc(1*var(--u)) 0 rgba(255,255,255,.10), 0 calc(2*var(--u)) calc(14*var(--u)) rgba(0,0,0,.15);
          transition: filter 0.2s, transform 0.1s;
          cursor: pointer;
        }
        .cta span { transform: translateY(calc(2*var(--u))); }
        .cta:hover { filter: brightness(1.16); }
        .cta:active { transform: scale(0.98); }
        
        /* Hero */
        .hero {
          flex: 1; display: flex; flex-direction: column; align-items: center; justify-content: center;
          gap: calc(var(--hero-gap)*var(--vu)); padding-bottom: calc(4*var(--vu));
        }
        
        .h1 {
          font-size: calc(var(--h1-fs)*var(--u)); font-weight: 410;
          line-height: 1.10; letter-spacing: var(--display-ls);
          color: #1a1a1a; font-variation-settings: "opsz" 32;
        }
        
        /* Composer Card */
        .card {
          width: calc(var(--card-w)*var(--u)); height: calc(var(--card-h)*var(--u));
          border-radius: calc(var(--card-r)*var(--u)); margin-right: calc(3*var(--u));
          background: rgba(255, 255, 255, 0.95);
          backdrop-filter: blur(calc(26*var(--u))) saturate(112%);
          box-shadow: inset 0 0 0 1px rgba(0,0,0,.06), 0 calc(22*var(--u)) calc(60*var(--u)) rgba(0,0,0,.08);
          position: relative;
        }
        
        .input-field {
          position: absolute;
          left: calc((452 - 425)*var(--u));
          top: calc((446 - 413)*var(--u));
          right: calc(24*var(--u));
          font-size: calc(var(--ph-fs)*var(--u));
          font-weight: 400; line-height: 1.35; letter-spacing: var(--body-ls);
          color: #221F1A;
          width: calc(100% - calc(51*var(--u)));
        }
        .input-field::placeholder { color: #8B8C8E; }
        
        /* Toolbar Strip */
        .tools {
          position: absolute;
          left: calc((444 - 425)*var(--u));
          top: calc((505 - 413)*var(--u));
          height: calc(var(--chip-h)*var(--u));
          right: calc(-1*var(--u));
        }
        
        .chips {
          display: flex; align-items: center; gap: calc(var(--chip-gap)*var(--u));
          height: 100%;
        }
        
        .chip {
          height: calc(var(--chip-h)*var(--u));
          border-radius: calc(var(--chip-r)*var(--u));
          font-size: calc(var(--chip-fs)*var(--u)); font-weight: 500;
          color: #555; line-height: 1;
          background: linear-gradient(180deg, rgba(0,0,0,.02) 0%, rgba(0,0,0,.04) 100%);
          border: 1px solid rgba(0,0,0,.05);
          display: flex; align-items: center; gap: 0;
          cursor: pointer; transition: all 0.2s;
        }
        .chip:hover {
          background: linear-gradient(180deg, rgba(0,0,0,.04), rgba(0,0,0,.06));
          color: #111;
        }
        .chip span { transform: translateY(calc(2*var(--u))); }
        
        /* Right Cluster (Absolute relative to .tools) */
        .right {
          position: absolute; inset: 0; pointer-events: none;
        }
        .right > * { position: absolute; pointer-events: auto; }
        
        .model {
          left: calc((955 - 444 - 0.8)*var(--u));
          top: calc(15.5*var(--u));
          font-size: calc(var(--son-fs)*var(--u)); font-weight: 500; color: #98999C; line-height: 1;
          display: inline-flex; align-items: center; gap: calc(var(--chev-gap)*var(--u));
        }
        .chev { width: calc(6.8*var(--u)); fill: currentColor; }
        
        .attach {
          left: calc((1043.15 - 444)*var(--u));
          top: calc((515.14 - 505)*var(--u));
          color: #A9AAAD; cursor: pointer; transition: color 0.2s;
        }
        .attach svg { width: calc(19.79*var(--u)); fill: currentColor; }
        .attach:hover { color: #111; }
        
        .send {
          left: calc((1084 - 444)*var(--u));
          top: calc((507 - 505)*var(--u));
          width: calc(var(--send-d)*var(--u)); height: calc(var(--send-d)*var(--u));
          border-radius: 50%;
          background: linear-gradient(163deg, #FBBC94 0%, #F49D70 46%, #E88654 100%);
          box-shadow: 0 calc(3*var(--u)) calc(12*var(--u)) rgba(210,110,60,.34);
          display: flex; align-items: center; justify-content: center;
          cursor: pointer; transition: all 0.2s;
        }
        .send svg { width: calc(11.66*var(--u)); fill: white; }
        .send:hover { filter: brightness(1.07); }
        .send:active { transform: scale(0.95); }
        
        /* Proof Footer */
        .proof {
          flex: none; display: flex; flex-direction: column; align-items: center;
          gap: calc(24*var(--vu));
        }
        .proof p {
          font-size: calc(var(--by-fs)*var(--u)); font-weight: 480;
          letter-spacing: var(--proof-ls); color: #888; font-variation-settings: "opsz" 32;
        }
        .logos {
          display: flex; align-items: center; gap: calc(var(--logo-gap)*var(--u));
          color: #b0b0b0;
        }
        .logos svg { fill: currentColor; }
        
        /* TABLET */
        @media (min-width:600px) and (max-width:1180px) and (min-height:600px) {
          :root { --u: 1px; }
          .frame { padding: clamp(24px,3.4vh,44px) clamp(28px,4.2vw,60px) clamp(26px,4.4vh,56px); }
          .h1 { font-size: clamp(27px,4.3vw,44px); line-height: 1.12; }
          .card {
            width: min(100%, clamp(516px,74vw,760px)); height: auto; margin-right: 0;
            padding: clamp(15px,1.9vw,24px); border-radius: clamp(17px,2.1vw,26px);
            display: flex; flex-direction: column; gap: clamp(20px,3.2vh,44px);
          }
          .input-field {
            position: static; font-size: clamp(12px,1.4vw,16px); line-height: 1.4; width: 100%;
          }
          .tools {
            position: static; height: auto; display: flex; flex-direction: row; flex-wrap: wrap;
            gap: clamp(10px,1.4vw,18px); align-items: center;
          }
          .chips { gap: clamp(6px,0.85vw,10px); flex-wrap: nowrap; }
          .chip { width: auto; height: clamp(29px,3.4vh,34px); padding: 0 clamp(7px,1vw,13px); font-size: clamp(9.6px,1.12vw,12.5px); }
          .right { position: static; display: flex; align-items: center; margin-left: auto; gap: 0; pointer-events: auto; }
          .right > * { position: static; }
          .model { font-size: clamp(9.8px,1.12vw,12.5px); }
          .attach { margin-left: clamp(9px, 1.4vw, 20px); }
          .attach svg { width: clamp(16px, 1.8vw, 22px); }
          .send { margin-left: clamp(9px, 1.3vw, 18px); width: clamp(32px, 3.5vw, 38px); height: clamp(32px, 3.5vw, 38px); }
          .proof { gap: clamp(15px,2.5vh,30px); }
        }
        
        /* PHONE */
        @media (max-width:599px), (max-height:599px) and (max-width:1180px) {
          :root { --u: 1px; }
          .frame {
            padding: max(18px, env(safe-area-inset-top)) max(clamp(18px,5.2vw,40px), env(safe-area-inset-right)) max(20px, env(safe-area-inset-bottom)) max(clamp(18px,5.2vw,40px), env(safe-area-inset-left));
          }
          .links, .cta { display: none; }
          .burger {
            display: flex; width: 38px; height: 38px; border-radius: 11px;
            background: rgba(0,0,0,.04); border: 1px solid rgba(0,0,0,.08);
            align-items: center; justify-content: center; color: #111;
          }
          .brand-text { font-size: 18px; }
          .h1 { width: 100%; max-width: 15ch; font-size: clamp(29px,7.6vw,50px); line-height: 1.14; letter-spacing: -.012em; text-align: center; }
          .card {
            width: 100%; max-width: 600px; height: auto; flex-direction: column;
            gap: clamp(16px,4.6vh,34px); padding: clamp(13px,3.4vw,18px); display: flex;
          }
          .input-field { position: static; font-size: clamp(12px, 3.5vw, 16px); width: 100%; }
          .tools { position: static; height: auto; display: flex; flex-direction: column; align-items: stretch; gap: 12px; }
          .chips { flex-wrap: wrap; gap: 8px; }
          .chip { height: 32px; padding: 0 12px; font-size: 12px; }
          .right { position: static; display: flex; align-items: center; justify-content: flex-start; pointer-events: auto; }
          .right > * { position: static; }
          .attach { margin-left: auto; }
          .attach svg { width: 22px; }
          .send { margin-left: 14px; width: 40px; height: 40px; }
          .proof { gap: 16px; margin-top: auto; }
          .logos svg { max-width: 60px; }
        }
        
        /* ENTRANCE ANIMATION */
        html.anim .brand { animation: e-settle-down .58s cubic-bezier(.22,1,.36,1) .06s both; }
        html.anim .brand img { animation: e-mark .62s cubic-bezier(.16,1,.3,1) .06s both; }
        html.anim .links a:nth-child(1) { animation: e-settle-down .50s cubic-bezier(.22,1,.36,1) .16s both; }
        html.anim .links a:nth-child(2) { animation: e-settle-down .50s cubic-bezier(.22,1,.36,1) .21s both; }
        html.anim .links a:nth-child(3) { animation: e-settle-down .50s cubic-bezier(.22,1,.36,1) .26s both; }
        html.anim .links a:nth-child(4) { animation: e-settle-down .50s cubic-bezier(.22,1,.36,1) .31s both; }
        html.anim .cta { animation: e-settle-down .55s cubic-bezier(.22,1,.36,1) .34s both; }
        html.anim .h1 { animation: e-focus 1.00s cubic-bezier(.16,1,.3,1) .30s both; will-change: transform, opacity; }
        html.anim .card { animation: e-panel .90s cubic-bezier(.16,1,.3,1) .62s both; will-change: transform, opacity; }
        html.anim .input-field { animation: e-populate .50s cubic-bezier(.22,1,.36,1) .88s both; }
        html.anim .chips { animation: e-populate .50s cubic-bezier(.22,1,.36,1) .94s both; }
        html.anim .right { animation: e-populate .50s cubic-bezier(.22,1,.36,1) 1.00s both; }
        html.anim .send { animation: e-send .50s cubic-bezier(.16,1,.3,1) 1.00s both; }
        html.anim .proof p { animation: e-settle-up .55s cubic-bezier(.22,1,.36,1) 1.08s both; }
        html.anim .logos svg:nth-child(1) { animation: e-settle-up .55s cubic-bezier(.22,1,.36,1) 1.16s both; }
        html.anim .logos svg:nth-child(2) { animation: e-settle-up .55s cubic-bezier(.22,1,.36,1) 1.22s both; }
        html.anim .logos svg:nth-child(3) { animation: e-settle-up .55s cubic-bezier(.22,1,.36,1) 1.28s both; }
        
        @keyframes e-settle-down { from { opacity: 0; transform: translateY(calc(-5*var(--u))); } to { opacity: 1; transform: none; } }
        @keyframes e-settle-up { from { opacity: 0; transform: translateY(calc(6*var(--u))); } to { opacity: 1; transform: none; } }
        @keyframes e-mark { from { transform: scale(0.9); } to { transform: none; } }
        @keyframes e-focus { from { opacity: 0; transform: translateY(calc(14*var(--u))); filter: blur(calc(6*var(--u))); } to { opacity: 1; transform: none; filter: blur(0); } }
        @keyframes e-panel { from { opacity: 0; transform: translateY(calc(18*var(--u))) scale(0.985); } to { opacity: 1; transform: none; } }
        @keyframes e-populate { from { opacity: 0; transform: translateY(calc(4*var(--u))); } to { opacity: 1; transform: none; } }
        @keyframes e-send { from { transform: scale(0.82); } to { transform: none; } }
        
        @media (prefers-reduced-motion: reduce) {
          *, *::before, *::after { animation-duration: 0.01ms !important; transition-duration: 0.01ms !important; }
        }
      `}} />
      <div className="stage">
        <div className="stage-bg"></div>
        <div className="frame">
          <input type="checkbox" id="menu" />
          
          <header className="nav">
            <Link href="/" className="brand" aria-label="PSGMX home">
              <img src="/logo.png" alt="PSGMX" style={{ width: 'calc(var(--mark)*var(--u))', height: 'calc(var(--mark)*var(--u))', objectFit: 'contain' }} />
              <span className="brand-text">PSGMX</span>
            </Link>
            <div className="links">
              <a href="#features">Features</a>
              <a href="#community">Community</a>
              <a href="#stats">Stats</a>
              <a href="#support">Support</a>
            </div>
            <Link href="/login" className="cta">
              <span>Dashboard</span>
            </Link>
            <label htmlFor="menu" className="burger">
              <svg width="17" height="12" viewBox="0 0 17 12" fill="none"><path d="M1 1H16M1 6H16M1 11H16" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round"/></svg>
            </label>
          </header>
          
          <main className="hero">
            <h1 className="h1">Ask anything about PSGMX.</h1>
            <form className="card" onSubmit={handleSubmit}>
              <input 
                type="text" 
                className="input-field" 
                placeholder="Ask about placement stats, app features, or MCA queries..." 
                value={query}
                onChange={e => setQuery(e.target.value)}
              />
              
              <div className="tools">
                <div className="chips">
                  <button type="button" className="chip" style={{ width: 'calc(107*var(--u))', paddingLeft: 'calc(12*var(--u))', gap: 'calc(3.7*var(--u))' }}>
                    <svg width="15" height="15" viewBox="0 0 24 24" fill="currentColor"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8l-6-6zm-1 2.5L18.5 10H13V4.5zM6 20V4h5v7h7v9H6z"/></svg>
                    <span>Stats</span>
                  </button>
                  <button type="button" className="chip" style={{ width: 'calc(108*var(--u))', paddingLeft: 'calc(16*var(--u))', gap: 'calc(3.9*var(--u))' }}>
                    <svg width="12" height="12" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-1 15h-2v-2h2v2zm0-4h-2V7h2v6z"/></svg>
                    <span>Issues</span>
                  </button>
                  <button type="button" className="chip" style={{ width: 'calc(107*var(--u))', paddingLeft: 'calc(15.8*var(--u))', gap: 'calc(2.9*var(--u))' }}>
                    <svg width="12" height="12" viewBox="0 0 24 24" fill="currentColor"><path d="M11.99 2C6.47 2 2 6.48 2 12s4.47 10 9.99 10C17.52 22 22 17.52 22 12S17.52 2 11.99 2zM12 20c-4.42 0-8-3.58-8-8s3.58-8 8-8 8 3.58 8 8-3.58 8-8 8zm.5-13H11v6l5.25 3.15.75-1.23-4.5-2.67z"/></svg>
                    <span>Timeline</span>
                  </button>
                </div>
                
                <div className="right">
                  <div className="model">
                    PSGMX Guide
                    <svg className="chev" viewBox="0 0 24 24"><path d="M7 10l5 5 5-5z"/></svg>
                  </div>
                  <button type="button" className="attach" aria-label="Attach context">
                    <svg viewBox="0 0 24 24"><path d="M16.5 6v11.5c0 2.21-1.79 4-4 4s-4-1.79-4-4V5a2.5 2.5 0 0 1 5 0v10.5c0 .55-.45 1-1 1s-1-.45-1-1V6H10v9.5a2.5 2.5 0 0 0 5 0V5c0-2.21-1.79-4-4-4S7 2.79 7 5v12.5c0 3.87 3.13 7 7 7s7-3.13 7-7V6h-1.5z"/></svg>
                  </button>
                  <button type="submit" className="send" aria-label="Send question">
                    <svg viewBox="0 0 24 24"><path d="M4 12l1.41 1.41L11 7.83V20h2V7.83l5.58 5.59L20 12l-8-8-8 8z"/></svg>
                  </button>
                </div>
              </div>
            </form>
          </main>
          
          <footer className="proof">
            <p>Made exclusively for</p>
            <div className="logos">
               <span style={{ fontSize: 'calc(24*var(--u))', fontWeight: 600, color: '#FF5A1F' }}>PSG</span>
               <span style={{ fontSize: 'calc(24*var(--u))', fontWeight: 400, color: '#555' }}>Tech</span>
               <span style={{ fontSize: 'calc(24*var(--u))', fontWeight: 600, color: '#555' }}>MCA</span>
            </div>
          </footer>
        </div>
      </div>
    </>
  );
}
