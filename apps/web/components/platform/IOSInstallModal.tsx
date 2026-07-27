'use client'

// ============================================================
// PSGMX — components/platform/IOSInstallModal.tsx
// Shows a polished "Add to Home Screen" install guide to iOS
// users on their first visit. Dismissal is persisted in
// localStorage so the modal never re-appears after closing.
// ============================================================
import { useEffect, useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { X } from 'lucide-react'

const DISMISSED_KEY = 'psgmx_ios_install_dismissed'

/** True when running on iOS Safari (or any iOS browser) and not already installed as a PWA. */
function shouldShowModal(): boolean {
  if (typeof window === 'undefined') return false
  const ua = navigator.userAgent
  const isIOS = /iPhone|iPad|iPod/.test(ua)
  const isStandalone = ('standalone' in navigator) && (navigator as Navigator & { standalone?: boolean }).standalone === true
  const wasDismissed = localStorage.getItem(DISMISSED_KEY) === '1'
  return isIOS && !isStandalone && !wasDismissed
}

// ── SVG icons ────────────────────────────────────────────────

function ShareIcon() {
  return (
    <svg viewBox="0 0 24 24" fill="none" className="w-7 h-7" aria-hidden="true">
      <rect x="3" y="11" width="18" height="11" rx="2" stroke="#FF6B4A" strokeWidth="1.8" />
      <path d="M12 2v12M8.5 5.5 12 2l3.5 3.5" stroke="#FF6B4A" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  )
}

function AddToHomeIcon() {
  return (
    <svg viewBox="0 0 24 24" fill="none" className="w-7 h-7" aria-hidden="true">
      <rect x="3" y="3" width="18" height="18" rx="4" stroke="#FF6B4A" strokeWidth="1.8" />
      <path d="M12 8v8M8 12h8" stroke="#FF6B4A" strokeWidth="1.8" strokeLinecap="round" />
    </svg>
  )
}

function TapAddIcon() {
  return (
    <svg viewBox="0 0 24 24" fill="none" className="w-7 h-7" aria-hidden="true">
      <circle cx="12" cy="12" r="9" stroke="#FF6B4A" strokeWidth="1.8" />
      <path d="M9 12l2 2 4-4" stroke="#FF6B4A" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  )
}

// ── PSGMX logo mark ──────────────────────────────────────────

function PSGMXMark() {
  return (
    <div className="w-14 h-14 rounded-2xl flex items-center justify-center shadow-lg"
      style={{ background: 'linear-gradient(135deg, #FF6B4A, #E4572E)' }}>
      <span className="text-white font-black text-xl tracking-tight" style={{ fontFamily: 'var(--font-sans)' }}>
        MX
      </span>
    </div>
  )
}

// ── Step row ─────────────────────────────────────────────────

function Step({ number, icon, text }: { number: number; icon: React.ReactNode; text: string }) {
  return (
    <div className="flex items-center gap-4 py-3 px-1">
      {/* Step number */}
      <span
        className="flex-none w-7 h-7 rounded-full flex items-center justify-center text-[11px] font-black text-white"
        style={{ background: 'linear-gradient(135deg, #FF6B4A, #E4572E)' }}
        aria-hidden="true"
      >
        {number}
      </span>

      {/* Icon */}
      <span className="flex-none">{icon}</span>

      {/* Description */}
      <p className="text-sm font-semibold leading-snug" style={{ color: 'var(--text-primary)' }}>
        {text}
      </p>
    </div>
  )
}

// ── Main modal ───────────────────────────────────────────────

export default function IOSInstallModal() {
  const [visible, setVisible] = useState(false)

  useEffect(() => {
    // Brief delay so the page fully renders before the modal glides in
    const timer = setTimeout(() => {
      if (shouldShowModal()) setVisible(true)
    }, 900)
    return () => clearTimeout(timer)
  }, [])

  function dismiss(remember: boolean) {
    if (remember) localStorage.setItem(DISMISSED_KEY, '1')
    setVisible(false)
  }

  return (
    <AnimatePresence>
      {visible && (
        <>
          {/* Backdrop */}
          <motion.div
            key="ios-modal-backdrop"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.25 }}
            className="fixed inset-0 z-[9998]"
            style={{ background: 'rgba(10, 10, 12, 0.55)', backdropFilter: 'blur(6px)', WebkitBackdropFilter: 'blur(6px)' }}
            onClick={() => dismiss(false)}
            aria-hidden="true"
          />

          {/* Modal sheet — slides up from bottom */}
          <motion.div
            key="ios-modal"
            role="dialog"
            aria-modal="true"
            aria-labelledby="ios-modal-title"
            initial={{ y: '100%', opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            exit={{ y: '100%', opacity: 0 }}
            transition={{ type: 'spring', damping: 30, stiffness: 320 }}
            className="fixed bottom-0 left-0 right-0 z-[9999] rounded-t-[28px] overflow-hidden"
            style={{
              background: 'var(--surface)',
              boxShadow: '0 -8px 60px rgba(0,0,0,0.25)',
              borderTop: '1px solid var(--border)',
            }}
          >
            {/* Drag handle indicator */}
            <div className="flex justify-center pt-3 pb-1">
              <div className="w-10 h-1 rounded-full" style={{ background: 'var(--border)' }} />
            </div>

            <div className="px-6 pb-8 pt-2">
              {/* Close button */}
              <div className="flex justify-end mb-2">
                <button
                  id="ios-modal-close"
                  onClick={() => dismiss(false)}
                  className="w-8 h-8 rounded-full flex items-center justify-center transition-opacity hover:opacity-60 active:opacity-40"
                  style={{ background: 'var(--border)' }}
                  aria-label="Close install guide"
                >
                  <X size={14} strokeWidth={2.5} style={{ color: 'var(--text-muted)' }} />
                </button>
              </div>

              {/* Header */}
              <div className="flex items-center gap-4 mb-5">
                <PSGMXMark />
                <div>
                  <p className="psgmx-subtitle mb-1">Install App</p>
                  <h2
                    id="ios-modal-title"
                    className="text-xl font-black leading-tight tracking-tight"
                    style={{ color: 'var(--text-primary)', letterSpacing: '-0.03em' }}
                  >
                    Add PSGMX to your Home Screen
                  </h2>
                </div>
              </div>

              {/* Description */}
              <p className="text-sm leading-relaxed mb-5" style={{ color: 'var(--text-muted)' }}>
                iOS doesn&apos;t support APK installs, but you can still get the native app experience — just add PSGMX to your Home Screen in 3 taps.
              </p>

              {/* Divider */}
              <div className="landing-section-divider mb-4" />

              {/* Steps */}
              <div className="divide-y" style={{ borderColor: 'var(--border)' }}>
                <Step
                  number={1}
                  icon={<ShareIcon />}
                  text='Tap the Share button at the bottom of Safari'
                />
                <Step
                  number={2}
                  icon={<AddToHomeIcon />}
                  text='Scroll down and select "Add to Home Screen"'
                />
                <Step
                  number={3}
                  icon={<TapAddIcon />}
                  text='Tap "Add" in the top-right corner — done!'
                />
              </div>

              {/* Divider */}
              <div className="landing-section-divider mt-4 mb-6" />

              {/* CTAs */}
              <div className="flex flex-col gap-3">
                <button
                  id="ios-modal-install-guide-btn"
                  onClick={() => dismiss(true)}
                  className="w-full py-3.5 rounded-2xl font-bold text-sm text-white transition-all active:scale-[0.98]"
                  style={{
                    background: 'linear-gradient(135deg, #FF6B4A, #E4572E)',
                    boxShadow: '0 4px 20px rgba(255,107,74,0.35)',
                  }}
                >
                  Got it — I&apos;ll Install
                </button>
                <button
                  id="ios-modal-maybe-later-btn"
                  onClick={() => dismiss(false)}
                  className="w-full py-3 rounded-2xl font-semibold text-sm transition-opacity hover:opacity-70 active:opacity-50"
                  style={{ color: 'var(--text-muted)', background: 'var(--border)' }}
                >
                  Maybe Later
                </button>
              </div>
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  )
}
