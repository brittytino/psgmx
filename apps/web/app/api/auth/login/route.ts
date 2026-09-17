// Password authentication was removed from PSGMX. Keep this route as an
// explicit tombstone so old clients cannot silently revive the legacy flow.
import { NextResponse } from 'next/server'

export async function POST() {
  return NextResponse.json(
    { error: 'Password sign-in is no longer supported. Request a six-digit OTP instead.' },
    { status: 410, headers: { Allow: 'POST /api/auth/request-otp' } },
  )
}
