// ============================================================
// PSGMX — apps/web/middleware.ts
// Supabase SSR session middleware + route-based access control.
// Refreshes sessions on every request and enforces role guards.
// ============================================================
import { createServerClient } from '@supabase/ssr'
import { NextResponse, type NextRequest } from 'next/server'

// Route → allowed roles map
// key: route prefix | value: array of allowed `role` values (from users table)
const ROLE_GUARDS: Record<string, string[]> = {
  '/faculty':     ['faculty', 'hod'],
  '/hod':         ['hod'],
  '/super-admin': ['hod'],   // HOD acts as super-admin in this system
  '/alumni':      ['alumni'],
  '/student':     ['student', 'alumni', 'faculty', 'hod'],  // broad read access
  '/knowledge':   ['student', 'alumni', 'faculty', 'hod'],
  '/exam':        ['student', 'faculty', 'hod'],
  '/onboarding':  ['student', 'alumni', 'faculty', 'hod'],
}

// Public routes that never require authentication
const PUBLIC_ROUTES = [
  '/',
  '/login',
  '/join-alumni',
  '/change-password',
  '/api/auth/login',
  '/api/auth/verify',
  '/api/health',
]

function isPublicRoute(pathname: string): boolean {
  return PUBLIC_ROUTES.some(route =>
    pathname === route || pathname.startsWith(route + '?')
  )
}

function getRequiredRoles(pathname: string): string[] | null {
  for (const [prefix, roles] of Object.entries(ROLE_GUARDS)) {
    if (pathname.startsWith(prefix)) return roles
  }
  return null  // no guard → allow any authenticated user
}

export async function middleware(request: NextRequest) {
  let supabaseResponse = NextResponse.next({ request })

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
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
  const {
    data: { user },
  } = await supabase.auth.getUser()

  const { pathname } = request.nextUrl

  // Allow public routes without authentication
  if (isPublicRoute(pathname)) {
    return supabaseResponse
  }

  // Redirect unauthenticated users to login
  if (!user) {
    const loginUrl = request.nextUrl.clone()
    loginUrl.pathname = '/login'
    loginUrl.searchParams.set('redirect', pathname)
    return NextResponse.redirect(loginUrl)
  }

  // Check role-based access for guarded routes
  const requiredRoles = getRequiredRoles(pathname)
  if (requiredRoles) {
    // Fetch user role from DB (one extra query per guarded request)
    const { data: profile } = await supabase
      .from('users')
      .select('role')
      .eq('id', user.id)
      .single()

    if (!profile || !requiredRoles.includes(profile.role)) {
      // Redirect to appropriate portal based on actual role
      const redirectUrl = request.nextUrl.clone()
      const role = profile?.role ?? 'student'

      if (role === 'faculty' || role === 'hod') redirectUrl.pathname = '/faculty'
      else if (role === 'alumni')               redirectUrl.pathname = '/alumni'
      else                                      redirectUrl.pathname = '/student'

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
