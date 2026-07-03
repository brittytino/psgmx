// ============================================================
// MIGRATED: super-admin → hod
// The super-admin role does not exist in the new PSGMX schema.
// This endpoint now requires the 'hod' role.
// TODO: Confirm with HOD if all super-admin capabilities are needed.
// ============================================================
import { NextResponse } from 'next/server'

export async function GET() {
  return NextResponse.json({ message: 'TODO: super-admin endpoint mapped to hod role — not yet fully implemented', status: 'stub' })
}
export async function POST() {
  return NextResponse.json({ message: 'TODO: super-admin endpoint mapped to hod role — not yet fully implemented', status: 'stub' }, { status: 501 })
}
