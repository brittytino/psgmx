// ============================================================
// PSGMX — apps/web/app/download/page.tsx
// Android-targeted download landing page.
// Served when Android mobile browsers visit psgmx.tech.
// Fetches latest release info from GitHub on the server side,
// then presents a polished download experience before the APK
// is ever triggered.
// ============================================================
import type { Metadata } from 'next'
import Link from 'next/link'
import Image from 'next/image'
import {
  Download,
  Smartphone,
  Zap,
  ShieldCheck,
  Globe,
  ArrowRight,
  Star,
  Package,
  CalendarDays,
} from 'lucide-react'

export const metadata: Metadata = {
  title: 'Download PSGMX | Android App',
  description:
    'Download the PSGMX Android app. Track placements, prep for interviews, collaborate with your batch — all in one place.',
  robots: 'noindex', // internal redirect page
}

// ── GitHub Release types ─────────────────────────────────────

interface GHAsset {
  name: string
  size: number
  download_count: number
  browser_download_url: string
}

interface GHRelease {
  tag_name: string
  name: string
  published_at: string
  assets: GHAsset[]
}

// ── Data fetching ────────────────────────────────────────────

async function getLatestRelease(): Promise<GHRelease | null> {
  try {
    const res = await fetch(
      'https://api.github.com/repos/brittytino/psgmx/releases/latest',
      {
        headers: {
          Accept: 'application/vnd.github+json',
          'X-GitHub-Api-Version': '2022-11-28',
          'User-Agent': 'PSGMX-Web-App/1.0',
        },
        next: { revalidate: 300 }, // re-fetch every 5 minutes at most
      }
    )
    if (!res.ok) return null
    return res.json()
  } catch {
    return null
  }
}

// ── Helpers ──────────────────────────────────────────────────

function formatBytes(bytes: number): string {
  const mb = bytes / 1024 / 1024
  return `${mb.toFixed(1)} MB`
}

function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString('en-IN', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  })
}

// ── Feature bullets ──────────────────────────────────────────

const FEATURES = [
  { icon: Zap,         label: 'Placement Tracker',   sub: 'Monitor drives and applications in real time' },
  { icon: Star,        label: 'Daily Streaks',        sub: 'Stay consistent with DSA and mock tests' },
  { icon: ShieldCheck, label: 'Secure & Fast',        sub: 'Signed APK with end-to-end encryption' },
  { icon: Globe,       label: 'Offline-Ready',        sub: 'Core features work without internet' },
]

// ── Page ─────────────────────────────────────────────────────

export default async function DownloadPage() {
  const release = await getLatestRelease()

  const apkAsset = release?.assets.find(
    (a) => a.name.toLowerCase().endsWith('-android.apk')
  )

  const version     = release?.tag_name   ?? null
  const fileSize    = apkAsset ? formatBytes(apkAsset.size) : null
  const releaseDate = release?.published_at ? formatDate(release.published_at) : null
  const downloads   = apkAsset?.download_count ?? null

  return (
    <main
      style={{
        minHeight: '100dvh',
        background: 'linear-gradient(160deg, #FBF6EE 0%, #FFF8F5 50%, #FBF6EE 100%)',
        fontFamily: 'var(--font-sans, "Plus Jakarta Sans", sans-serif)',
        display: 'flex',
        flexDirection: 'column',
      }}
    >
      {/* ── Ambient background blobs ── */}
      <div
        aria-hidden="true"
        style={{
          position: 'fixed',
          inset: 0,
          zIndex: 0,
          pointerEvents: 'none',
          overflow: 'hidden',
        }}
      >
        <div style={{
          position: 'absolute',
          top: '-10%',
          right: '-10%',
          width: '60vw',
          height: '60vw',
          maxWidth: 480,
          maxHeight: 480,
          borderRadius: '50%',
          background: 'radial-gradient(circle, rgba(255,107,74,0.12) 0%, transparent 70%)',
        }} />
        <div style={{
          position: 'absolute',
          bottom: '-5%',
          left: '-10%',
          width: '50vw',
          height: '50vw',
          maxWidth: 400,
          maxHeight: 400,
          borderRadius: '50%',
          background: 'radial-gradient(circle, rgba(228,87,46,0.08) 0%, transparent 70%)',
        }} />
      </div>

      {/* ── Content ── */}
      <div
        style={{
          position: 'relative',
          zIndex: 1,
          flex: 1,
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          padding: '3rem 1.25rem 2rem',
          maxWidth: 480,
          margin: '0 auto',
          width: '100%',
          boxSizing: 'border-box',
        }}
      >
        {/* ── Logo + wordmark ── */}
        <div style={{ textAlign: 'center', marginBottom: '2rem' }}>
          <div style={{ display: 'inline-flex', alignItems: 'center', justifyContent: 'center', marginBottom: '1rem' }}>
            <Image
              src="/logo.webp"
              alt="PSGMX Logo"
              width={72}
              height={72}
              style={{ borderRadius: 20, boxShadow: '0 8px 32px rgba(255,107,74,0.25)' }}
              priority
            />
          </div>
          <h1 style={{
            margin: 0,
            fontSize: '2rem',
            fontWeight: 900,
            letterSpacing: '-0.04em',
            lineHeight: 1.1,
            background: 'linear-gradient(135deg, #221F1A 0%, #E4572E 100%)',
            WebkitBackgroundClip: 'text',
            WebkitTextFillColor: 'transparent',
          }}>
            PSGMX
          </h1>
          <p style={{
            margin: '0.25rem 0 0',
            fontSize: '0.8125rem',
            fontWeight: 800,
            textTransform: 'uppercase',
            letterSpacing: '0.2em',
            color: '#FF6B4A',
          }}>
            Department OS
          </p>
        </div>

        {/* ── Hero card ── */}
        <div style={{
          width: '100%',
          background: 'rgba(255,255,255,0.85)',
          backdropFilter: 'blur(20px)',
          WebkitBackdropFilter: 'blur(20px)',
          borderRadius: 28,
          border: '1px solid rgba(255,107,74,0.15)',
          boxShadow: '0 16px 48px rgba(255,107,74,0.10), 0 2px 8px rgba(0,0,0,0.04)',
          padding: '1.75rem 1.5rem',
          marginBottom: '1rem',
          boxSizing: 'border-box',
        }}>
          {/* Release meta */}
          <div style={{ display: 'flex', gap: '0.5rem', flexWrap: 'wrap', marginBottom: '1.25rem' }}>
            {version && (
              <span style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: '0.3rem',
                fontSize: '0.75rem',
                fontWeight: 700,
                color: '#FF6B4A',
                background: 'rgba(255,107,74,0.1)',
                borderRadius: 100,
                padding: '0.25rem 0.7rem',
                border: '1px solid rgba(255,107,74,0.2)',
              }}>
                <Package size={11} />
                {version}
              </span>
            )}
            {fileSize && (
              <span style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: '0.3rem',
                fontSize: '0.75rem',
                fontWeight: 600,
                color: '#9E9A92',
                background: '#F5F0E8',
                borderRadius: 100,
                padding: '0.25rem 0.7rem',
              }}>
                <Smartphone size={11} />
                {fileSize}
              </span>
            )}
            {releaseDate && (
              <span style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: '0.3rem',
                fontSize: '0.75rem',
                fontWeight: 600,
                color: '#9E9A92',
                background: '#F5F0E8',
                borderRadius: 100,
                padding: '0.25rem 0.7rem',
              }}>
                <CalendarDays size={11} />
                {releaseDate}
              </span>
            )}
          </div>

          {/* Headline */}
          <h2 style={{
            margin: '0 0 0.5rem',
            fontSize: '1.375rem',
            fontWeight: 900,
            letterSpacing: '-0.03em',
            lineHeight: 1.2,
            color: '#221F1A',
          }}>
            The full PSGMX experience, now on Android
          </h2>
          <p style={{
            margin: '0 0 1.5rem',
            fontSize: '0.9rem',
            fontWeight: 500,
            color: '#6B6862',
            lineHeight: 1.55,
          }}>
            Track placements, build streaks, and stay ahead — built for PSG Tech MCA students.
          </p>

          {/* Download CTA */}
          <a
            id="android-download-apk-btn"
            href="/api/download/android"
            style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: '0.6rem',
              width: '100%',
              padding: '1rem 1.5rem',
              borderRadius: 16,
              background: 'linear-gradient(135deg, #FF6B4A 0%, #E4572E 100%)',
              color: '#fff',
              fontWeight: 800,
              fontSize: '1rem',
              letterSpacing: '-0.01em',
              textDecoration: 'none',
              boxShadow: '0 8px 24px rgba(255,107,74,0.40)',
              boxSizing: 'border-box',
              transition: 'transform 0.15s ease, box-shadow 0.15s ease',
              WebkitTapHighlightColor: 'transparent',
            }}
            // Inline pseudo-hover via onMouseEnter/Leave doesn't work in RSC —
            // the CSS active state is handled natively by mobile browsers.
          >
            <Download size={20} strokeWidth={2.5} />
            Download APK
          </a>

          {downloads !== null && downloads > 0 && (
            <p style={{
              margin: '0.75rem 0 0',
              textAlign: 'center',
              fontSize: '0.75rem',
              fontWeight: 600,
              color: '#9E9A92',
            }}>
              {downloads.toLocaleString('en-IN')} downloads so far
            </p>
          )}
        </div>

        {/* ── Install hint ── */}
        <div style={{
          width: '100%',
          background: 'rgba(255,107,74,0.06)',
          border: '1px solid rgba(255,107,74,0.15)',
          borderRadius: 16,
          padding: '1rem 1.25rem',
          marginBottom: '1.5rem',
          boxSizing: 'border-box',
          display: 'flex',
          gap: '0.75rem',
          alignItems: 'flex-start',
        }}>
          <div style={{
            flexShrink: 0,
            width: 32,
            height: 32,
            borderRadius: 8,
            background: 'linear-gradient(135deg, #FF6B4A, #E4572E)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
          }}>
            <Smartphone size={16} color="#fff" strokeWidth={2.5} />
          </div>
          <div>
            <p style={{ margin: 0, fontSize: '0.8125rem', fontWeight: 700, color: '#221F1A', lineHeight: 1.3 }}>
              How to install
            </p>
            <p style={{ margin: '0.2rem 0 0', fontSize: '0.75rem', fontWeight: 500, color: '#6B6862', lineHeight: 1.5 }}>
              After downloading, open the APK file. If prompted, allow installs from unknown sources in your settings.
            </p>
          </div>
        </div>

        {/* ── Feature grid ── */}
        <div style={{
          width: '100%',
          display: 'grid',
          gridTemplateColumns: '1fr 1fr',
          gap: '0.75rem',
          marginBottom: '2rem',
        }}>
          {FEATURES.map(({ icon: Icon, label, sub }) => (
            <div
              key={label}
              style={{
                background: 'rgba(255,255,255,0.7)',
                backdropFilter: 'blur(12px)',
                WebkitBackdropFilter: 'blur(12px)',
                borderRadius: 16,
                border: '1px solid rgba(239,233,224,0.8)',
                padding: '1rem',
                boxSizing: 'border-box',
              }}
            >
              <div style={{
                width: 32,
                height: 32,
                borderRadius: 8,
                background: 'rgba(255,107,74,0.1)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                marginBottom: '0.5rem',
              }}>
                <Icon size={16} color="#FF6B4A" strokeWidth={2} />
              </div>
              <p style={{ margin: 0, fontSize: '0.8125rem', fontWeight: 700, color: '#221F1A', lineHeight: 1.3 }}>
                {label}
              </p>
              <p style={{ margin: '0.2rem 0 0', fontSize: '0.7rem', fontWeight: 500, color: '#9E9A92', lineHeight: 1.4 }}>
                {sub}
              </p>
            </div>
          ))}
        </div>

        {/* ── Web app fallback link ── */}
        <Link
          href="/"
          id="android-open-web-app-link"
          style={{
            display: 'inline-flex',
            alignItems: 'center',
            gap: '0.4rem',
            fontSize: '0.875rem',
            fontWeight: 700,
            color: '#9E9A92',
            textDecoration: 'none',
            padding: '0.6rem 1.25rem',
            borderRadius: 100,
            border: '1px solid #EFE9E0',
            background: 'rgba(255,255,255,0.6)',
            marginBottom: '2rem',
          }}
        >
          Open Web App instead
          <ArrowRight size={14} strokeWidth={2.5} />
        </Link>
      </div>

      {/* ── Footer ── */}
      <footer style={{
        position: 'relative',
        zIndex: 1,
        textAlign: 'center',
        padding: '1rem 1.25rem 2rem',
        fontSize: '0.75rem',
        fontWeight: 600,
        color: '#C4BEB5',
        letterSpacing: '0.02em',
      }}>
        © {new Date().getFullYear()} PSGMX · PSG College of Technology · MCA Department
      </footer>
    </main>
  )
}
