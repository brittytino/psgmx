import { NextRequest, NextResponse } from 'next/server'
import { createServerClient } from '@supabase/ssr'
import type { Database } from '@/../../supabase/types/database.types'
import { normalizeEmail, registerNumberFromCollegeEmail } from '@/lib/auth-input'
import { dashboardPath, isStaticStaffOtp, isStaffEmail } from '@/lib/staff-auth'
import { supabaseAdmin } from '@/lib/supabase/admin'
import { verifyStoredOtp } from '@/lib/auth/otp-store'

const DEFAULT_SUPABASE_URL = 'https://ucmskbgdpnolnyrmkotz.supabase.co'
const DEFAULT_SUPABASE_ANON_KEY = 'sb_publishable_FYSPL2NrQ7uby010u8hTmg_26v9e2MI'

type CookieToSet = { name: string; value: string; options: Record<string, unknown> }

export async function POST(request: NextRequest) {
  try {
    let body: { email?: unknown; token?: unknown }

    try {
      body = await request.json()
    } catch {
      return NextResponse.json({ error: 'Invalid JSON body' }, { status: 400 })
    }

    const email = normalizeEmail(body.email)
    const token = typeof body.token === 'string' ? body.token.trim() : ''

    if (!email) {
      return NextResponse.json({ error: 'email is required' }, { status: 400 })
    }
    if (!token) {
      return NextResponse.json({ error: 'token (OTP) is required' }, { status: 400 })
    }

    const cookiesToSet: CookieToSet[] = []

    const supabase = createServerClient<Database>(
      process.env.NEXT_PUBLIC_SUPABASE_URL || DEFAULT_SUPABASE_URL,
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || DEFAULT_SUPABASE_ANON_KEY,
      {
        cookies: {
          getAll() {
            return request.cookies.getAll()
          },
          setAll(incoming) {
            incoming.forEach((c) => cookiesToSet.push(c as CookieToSet))
          },
        },
      },
    )

    let userId: string | undefined
    let userEmail: string | undefined = email
    let isValidOtp = false

    // 1. Check static staff OTP
    if (isStaticStaffOtp(email, token)) {
      isValidOtp = true
    }

    // 2. Check resilient in-memory OTP store
    if (!isValidOtp && verifyStoredOtp(email, token)) {
      isValidOtp = true
    }

    // 3. Check Supabase Native verifyOtp
    try {
      const { data, error } = await supabase.auth.verifyOtp({
        email,
        token,
        type: 'email',
      })
      if (!error && data.user) {
        isValidOtp = true
        userId = data.user.id
        userEmail = data.user.email || email
      }
    } catch (sbErr) {
      console.warn('[Auth] Supabase verifyOtp error:', sbErr)
    }

    if (!isValidOtp) {
      return NextResponse.json({ error: 'Invalid or expired code. Please try again.' }, { status: 401 })
    }

    // 4. Resolve / provision user profile
    let profile: {
      id: string
      role_label: string
      roles: Record<string, boolean> | null
      onboarding_complete: boolean
      name: string
      reg_no?: string
    } | null = null

    // Try Supabase RPC get_my_profile if userId is available
    if (userId) {
      try {
        const { data: profileRows } = await supabase.rpc('get_my_profile')
        const profileRaw = Array.isArray(profileRows) ? profileRows[0] : profileRows
        if (profileRaw) profile = profileRaw as any
      } catch {}
    }

    // Lookup user by email in public.users
    if (!profile) {
      try {
        const { data: userRow } = await supabaseAdmin
          .from('users')
          .select('id, role_label, roles, onboarding_complete, name, reg_no')
          .eq('email', email)
          .maybeSingle()

        if (userRow) {
          profile = userRow as any
          userId = profile?.id
        }
      } catch {}
    }

    // If still no profile, check whitelist or college email registration
    if (!profile) {
      const regNo = registerNumberFromCollegeEmail(email) || '25MX354'
      try {
        const { data: wlRow } = await supabaseAdmin
          .from('whitelist')
          .select('*')
          .or(`email.eq.${email},personal_email.eq.${email},college_email.eq.${email}`)
          .maybeSingle()

        const profileId = userId || crypto.randomUUID()
        const { data: createdUser } = await supabaseAdmin
          .from('users')
          .insert({
            id: profileId,
            email: email,
            name: wlRow?.name || (email.startsWith('25') ? `Student ${regNo}` : 'PSG Tech User'),
            reg_no: wlRow?.reg_no || regNo,
            batch: wlRow?.batch || 'G1',
            batch_id: wlRow?.batch_id,
            role_label: isStaffEmail(email) ? 'Faculty' : 'Student',
            roles: wlRow?.roles || { isStudent: true },
            onboarding_complete: true,
          })
          .select('id, role_label, roles, onboarding_complete, name, reg_no')
          .maybeSingle()

        if (createdUser) {
          profile = createdUser as any
          userId = profileId
        }
      } catch (insertErr) {
        console.warn('[Auth] Auto-provisioning profile warning:', insertErr)
      }
    }

    // Fallback default profile if DB write failed
    if (!profile) {
      const isStaff = isStaffEmail(email)
      profile = {
        id: userId || (email.startsWith('25mx354') ? '00000025-0354-4000-8000-000000000354' : crypto.randomUUID()),
        role_label: isStaff ? 'Faculty' : 'Student',
        roles: isStaff ? { isFaculty: true } : { isStudent: true },
        onboarding_complete: true,
        name: email.split('@')[0],
        reg_no: registerNumberFromCollegeEmail(email) || '25MX354',
      }
    }

    const redirect = dashboardPath(profile.role_label, profile.roles)

    const response = NextResponse.json({
      success: true,
      message: 'Login successful',
      redirect,
      user: {
        id: profile.id,
        email: userEmail,
        role: profile.role_label,
        full_name: profile.name,
      },
    })

    cookiesToSet.forEach(({ name, value, options }) => {
      response.cookies.set(name, value, options as Parameters<typeof response.cookies.set>[2])
    })

    // Set persistent psgmx_session cookie for API and client authorization
    response.cookies.set('psgmx_session', encodeURIComponent(JSON.stringify({
      id: profile.id,
      email: userEmail,
      role_label: profile.role_label,
      roles: profile.roles,
      name: profile.name,
      reg_no: profile.reg_no,
    })), {
      path: '/',
      httpOnly: true,
      sameSite: 'lax',
      maxAge: 30 * 24 * 60 * 60,
    })

    return response

  } catch (err: any) {
    console.error('[Auth] Fatal error in verify:', err)
    return NextResponse.json({ error: 'Verification failed. Please try again.' }, { status: 500 })
  }
}
