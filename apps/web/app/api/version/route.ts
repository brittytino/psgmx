// ============================================================
// GET /api/version
// Returns the latest released APK version from GitHub Releases.
// Consumed by Flutter mobile app UpdateGate on launch.
// See: docs/user-flow.md Chapter 11.6
// ============================================================
import { NextResponse } from 'next/server'

interface GitHubRelease {
  tag_name: string
  name: string
  body: string
  published_at: string
  assets: Array<{
    name: string
    browser_download_url: string
    size: number
  }>
}

export async function GET() {
  try {
    const res = await fetch(
      'https://api.github.com/repos/brittytino/psgmx/releases/latest',
      {
        headers: {
          Accept: 'application/vnd.github+json',
          'X-GitHub-Api-Version': '2022-11-28',
          'User-Agent': 'PSGMX-Version-Checker/1.0',
        },
        next: { revalidate: 300 }, // Cache for 5 mins
      }
    )

    if (!res.ok) {
      // Fallback version if GitHub API rate limit is reached
      return NextResponse.json({
        latest_version: '5.0.0',
        min_supported_version: '4.0.0',
        download_url: 'https://psgmx.tech/download',
        release_notes: 'Regular performance and readiness tracking updates.',
        published_at: new Date().toISOString(),
      })
    }

    const release: GitHubRelease = await res.json()
    const apkAsset = release.assets?.find((a) =>
      a.name.toLowerCase().endsWith('.apk')
    )

    const rawTag = release.tag_name || 'v5.0.0'
    const cleanVersion = rawTag.startsWith('v') ? rawTag.slice(1) : rawTag

    return NextResponse.json({
      latest_version: cleanVersion,
      min_supported_version: '4.0.0', // Enforces minimum supported version
      download_url: apkAsset?.browser_download_url || 'https://psgmx.tech/download',
      release_name: release.name,
      release_notes: release.body || 'New features and readiness improvements.',
      published_at: release.published_at,
    })
  } catch (err) {
    console.error('Error fetching latest release version:', err)
    return NextResponse.json(
      {
        latest_version: '5.0.0',
        min_supported_version: '4.0.0',
        download_url: 'https://psgmx.tech/download',
        release_notes: 'Performance improvements and bug fixes.',
      },
      { status: 200 }
    )
  }
}
