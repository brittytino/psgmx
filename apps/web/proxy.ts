// ============================================================
// PSGMX — apps/web/proxy.ts
// Next.js 16 proxy (formerly middleware).
// Supabase SSR session refresh + route-based access control.
// ============================================================
import { createServerClient } from '@supabase/ssr'
import { NextResponse, type NextRequest } from 'next/server'
import type { Database } from '../../supabase/types/database.types'

// ── Platform detection ──────────────────────────────────────
// Returns true for Android *phone* browsers (not tablets, not bots).
// Android phones include both "Android" and "Mobile" in their UA.
// Android tablets omit "Mobile", so they continue to get the web app.
function isAndroidMobileBrowser(userAgent: string): boolean {
  if (!userAgent) return false
  const ua = userAgent.toLowerCase()
  // Exclude common bots/crawlers that might spoof a mobile UA
  const isBot = /bot|crawl|spider|slurp|bingpreview|googlebot|facebookexternalhit/.test(ua)
  if (isBot) return false
  return ua.includes('android') && ua.includes('mobile')
}

// Route → allowed roles map
// key: route prefix | value: array of allowed `role_label` values (lowercased)
// or a special 'placement_rep' token checked against roles.isPlacementRep.
// More specific prefixes MUST come before their parent prefix, since
// getRequiredRoles() below returns the first match found.
const ROLE_GUARDS: Record<string, string[]> = {
  // HOD-only sub-screens folded in under /faculty/* (plan Section 10) —
  // must be listed before the general '/faculty' guard.
  '/faculty/batch-management':   ['hod'],
  '/faculty/faculty-management': ['hod'],
  '/faculty/governance':         ['hod'],
  '/faculty':     ['faculty', 'hod'],   // hod kept so existing hod accounts can still access faculty portal
  '/placement-rep': ['placement_rep'],  // student with roles.isPlacementRep = true (Section 8)
  '/alumni':      ['alumni'],
  '/student':     ['student', 'alumni', 'faculty', 'hod'],
  '/knowledge':   ['student', 'alumni', 'faculty', 'hod'],
  '/exam':        ['student', 'faculty', 'hod'],
  '/onboarding':  ['student', 'alumni', 'faculty', 'hod'],
}

// Public routes that never require authentication
const PUBLIC_ROUTES = [
  '/',
  '/login',
  '/join-alumni',
  '/download',        // Android download landing page
  '/api/auth',        // covers /api/auth/login, /api/auth/verify, /api/auth/logout, etc.
  '/api/health',
  '/api/download',    // APK redirect API
]

function isPublicRoute(pathname: string): boolean {
  return PUBLIC_ROUTES.some(route =>
    pathname === route ||
    pathname.startsWith(route + '?') ||
    pathname.startsWith(route + '/')
  )
}

function getRequiredRoles(pathname: string): string[] | null {
  for (const [prefix, roles] of Object.entries(ROLE_GUARDS)) {
    if (pathname.startsWith(prefix)) return roles
  }
  return null  // no guard → allow any authenticated user
}

export async function proxy(request: NextRequest) {
  const { pathname } = request.nextUrl
  const userAgent = request.headers.get('user-agent') ?? ''

  // ── Android redirect ──────────────────────────────────────
  // Android mobile visitors hitting the landing page are sent to the
  // branded download page first — not directly to the APK.
  // Deep links (/login, /student, etc.) are unaffected.
  if (pathname === '/' && isAndroidMobileBrowser(userAgent)) {
    return NextResponse.redirect(new URL('/download', request.url))
  }

  let supabaseResponse = NextResponse.next({ request })

  const supabase = createServerClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL || 'http://localhost',
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || 'dummy',
    {
      cookies: {
        getAll() {
          return request.cookies.getAll()
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value }) =>
            request.cookies.set(name, value)
          )
          supabaseResponse = NextResponse.next({ request })
          cookiesToSet.forEach(({ name, value, options }) =>
            supabaseResponse.cookies.set(name, value, options)
          )
        },
      },
    }
  )

  // IMPORTANT: Always call getUser() to refresh the session token.
  // Do not remove this — it keeps sessions alive.
  let user = null
  try {
    const { data } = await supabase.auth.getUser()
    user = data.user
  } catch {
    // If Supabase is unreachable or unconfigured in local dev mode, proceed gracefully
  }

  // pathname was already extracted above for the Android check

  // Allow public routes without authentication
  if (isPublicRoute(pathname)) {
    return supabaseResponse
  }

  // Redirect unauthenticated users to login (unless in local development)
  if (!user && process.env.NODE_ENV !== 'development') {
    const loginUrl = request.nextUrl.clone()
    loginUrl.pathname = '/login'
    loginUrl.searchParams.set('redirect', pathname)
    return NextResponse.redirect(loginUrl)
  }

  // Check role-based access for guarded routes.
  // NOTE: `role`/`app_role` columns do not exist on the live `users` table
  // — the real role model is `role_label` (TEXT) + `roles` (JSONB student
  // sub-flags, e.g. isPlacementRep). See supabase/migrations/
  // 08_security_fixes_sprint0.sql header for how this was verified.
  const requiredRoles = getRequiredRoles(pathname)
  if (requiredRoles) {
    let role = 'student'
    let isPlacementRep = false
    let onboardingComplete = true

    if (user) {
      const { data: profileRows } = await supabase.rpc('get_my_profile')
      const profile = Array.isArray(profileRows) ? profileRows[0] : profileRows
      role = (profile?.role_label ?? 'student').toLowerCase()
      isPlacementRep = (profile?.roles as Record<string, boolean> | null)?.isPlacementRep === true
      onboardingComplete = profile?.onboarding_complete ?? false
    }

    if (user && !onboardingComplete && pathname !== '/onboarding' && !pathname.startsWith('/onboarding/')) {
      if (role !== 'faculty' && role !== 'hod') {
        return NextResponse.redirect(new URL('/onboarding', request.url))
      }
    }

    const allowed = requiredRoles.includes(role) || (requiredRoles.includes('placement_rep') && role === 'student' && isPlacementRep)

    if (!allowed && process.env.NODE_ENV !== 'development') {
      // Redirect to appropriate portal based on actual role
      const redirectUrl = request.nextUrl.clone()

      if (role === 'faculty' || role === 'hod')  redirectUrl.pathname = '/faculty'  // hod treated as faculty
      else if (role === 'alumni')                redirectUrl.pathname = '/alumni'
      else if (role === 'student' && isPlacementRep) redirectUrl.pathname = '/placement-rep'
      else                                        redirectUrl.pathname = '/student'

      // Prevent infinite redirect loops if we are already on the target path
      if (request.nextUrl.pathname === redirectUrl.pathname) {
        return supabaseResponse
      }

      return NextResponse.redirect(redirectUrl)
    }
  }

  return supabaseResponse
}

export const config = {
  matcher: [
    /*
     * Match all request paths EXCEPT:
     * - _next/static (static files)
     * - _next/image (image optimization)
     * - favicon.ico (browser icon)
     * - public folder files
     */
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
}
