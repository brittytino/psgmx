import { createHmac, timingSafeEqual } from 'node:crypto'

interface OtpChallenge {
  email: string
  tokenHash: string
  expiresAt: number
}

function signingSecret(): string | null {
  return process.env.AUTH_SESSION_SECRET?.trim() || process.env.CRON_SECRET?.trim() || null
}

export function signOtpChallenge(challenge: OtpChallenge): string | null {
  const secret = signingSecret()
  if (!secret) return null
  const payload = Buffer.from(JSON.stringify(challenge)).toString('base64url')
  const signature = createHmac('sha256', secret).update(payload).digest('base64url')
  return `${payload}.${signature}`
}

export function readOtpChallenge(value: string | undefined): OtpChallenge | null {
  const secret = signingSecret()
  if (!secret || !value) return null
  const [payload, signature] = value.split('.')
  if (!payload || !signature) return null

  const expected = createHmac('sha256', secret).update(payload).digest()
  let received: Buffer
  try {
    received = Buffer.from(signature, 'base64url')
  } catch {
    return null
  }
  if (expected.length !== received.length || !timingSafeEqual(expected, received)) return null

  try {
    const parsed = JSON.parse(Buffer.from(payload, 'base64url').toString('utf8')) as OtpChallenge
    if (!parsed.email || !parsed.tokenHash || parsed.expiresAt < Date.now()) return null
    return parsed
  } catch {
    return null
  }
}
