import { NextRequest, NextResponse } from 'next/server'
import { getUserFromRequest, isStudent } from '@/lib/auth'
import { PISTON_LANGUAGE_VERSIONS } from '../pistonConfig'

const PISTON_API_URL = process.env.PISTON_API_URL || 'https://emkc.org/api/v2/piston/execute'
const MAX_CODE_BYTES = 50_000
const MAX_STDIN_BYTES = 8_000

function byteLength(value: string) {
  return new TextEncoder().encode(value).byteLength
}

export async function POST(req: NextRequest) {
  const user = await getUserFromRequest(req)
  if (!user || !isStudent(user)) {
    return NextResponse.json({ error: 'Student authentication is required.' }, { status: 401 })
  }

  let body: { code?: unknown; language?: unknown; stdin?: unknown }
  try {
    body = await req.json()
  } catch {
    return NextResponse.json({ error: 'Invalid request body.' }, { status: 400 })
  }

  const code = typeof body.code === 'string' ? body.code : ''
  const language = typeof body.language === 'string' ? body.language.toLowerCase() : ''
  const stdin = typeof body.stdin === 'string' ? body.stdin : ''
  const version = PISTON_LANGUAGE_VERSIONS[language]

  if (!code.trim() || !version) {
    return NextResponse.json({ error: 'Choose a supported language and enter code.' }, { status: 400 })
  }
  if (byteLength(code) > MAX_CODE_BYTES || byteLength(stdin) > MAX_STDIN_BYTES) {
    return NextResponse.json({ error: 'The code or input is larger than the sandbox limit.' }, { status: 413 })
  }

  try {
    const response = await fetch(PISTON_API_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        language,
        version,
        files: [{ content: code }],
        stdin,
        run_timeout: 3_000,
        run_memory_limit: 256 * 1024 * 1024,
      }),
      signal: AbortSignal.timeout(10_000),
      cache: 'no-store',
    })

    if (!response.ok) {
      return NextResponse.json(
        { error: 'The code sandbox is busy. No result was recorded; please retry.' },
        { status: 503 },
      )
    }

    const result = await response.json()
    if (!result?.run) {
      return NextResponse.json({ error: 'The sandbox returned an invalid response.' }, { status: 502 })
    }

    return NextResponse.json({
      stdout: String(result.run.stdout || ''),
      stderr: String(result.run.stderr || ''),
      code: Number(result.run.code ?? 1),
      signal: result.run.signal ?? null,
    })
  } catch {
    return NextResponse.json(
      { error: 'The code sandbox is unavailable. No result was recorded; please retry.' },
      { status: 503 },
    )
  }
}
