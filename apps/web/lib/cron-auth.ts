import { timingSafeEqual } from 'node:crypto'
import { NextRequest } from 'next/server'

export function isAuthorizedCron(request: NextRequest): boolean {
  const expected = process.env.CRON_SECRET?.trim() || ''
  const received = request.headers.get('authorization')?.replace(/^Bearer\s+/i, '')
    || request.headers.get('x-cron-secret')?.trim()
    || ''
  if (!expected || expected.length !== received.length) return false
  return timingSafeEqual(Buffer.from(expected), Buffer.from(received))
}
