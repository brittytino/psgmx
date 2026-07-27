// ============================================================
// PSGMX — apps/web/app/api/download/android/route.ts
// Dynamically resolves the latest APK from GitHub Releases
// and redirects Android mobile browsers to the direct download.
// Falls back to the GitHub Releases page on any failure.
// ============================================================
import { NextResponse } from 'next/server'

const GITHUB_REPO = 'brittytino/psgmx'
const GITHUB_RELEASES_PAGE = `https://github.com/${GITHUB_REPO}/releases/latest`
const GITHUB_API_URL = `https://api.github.com/repos/${GITHUB_REPO}/releases/latest`

export async function GET() {
  try {
    const response = await fetch(GITHUB_API_URL, {
      headers: {
        Accept: 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
        // Use a descriptive User-Agent as required by GitHub API
        'User-Agent': 'PSGMX-Web-App/1.0',
      },
      // Do not cache — we always want the freshest release
      cache: 'no-store',
    })

    if (!response.ok) {
      console.error(`[download/android] GitHub API returned ${response.status}`)
      return NextResponse.redirect(GITHUB_RELEASES_PAGE, { status: 302 })
    }

    const release = await response.json()

    // Find the first APK asset in this release
    const apkAsset = release?.assets?.find(
      (asset: { name: string }) =>
        typeof asset.name === 'string' && asset.name.toLowerCase().endsWith('-android.apk')
    )

    if (!apkAsset?.browser_download_url) {
      console.warn('[download/android] No APK asset found in latest release, falling back to releases page')
      return NextResponse.redirect(GITHUB_RELEASES_PAGE, { status: 302 })
    }

    // Redirect the browser directly to the APK download URL
    return NextResponse.redirect(apkAsset.browser_download_url, { status: 302 })
  } catch (error) {
    console.error('[download/android] Failed to fetch release info:', error)
    return NextResponse.redirect(GITHUB_RELEASES_PAGE, { status: 302 })
  }
}
