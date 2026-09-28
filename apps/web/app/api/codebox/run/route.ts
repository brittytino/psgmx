import { NextRequest, NextResponse } from 'next/server'
import { getUserFromRequest, isStudent } from '@/lib/auth'
import { checkRateLimit } from '@/lib/limiter'
import { PISTON_LANGUAGE_VERSIONS } from '../pistonConfig'

// Primary + fallback Piston endpoints for reliability
const PISTON_ENDPOINTS = [
  process.env.PISTON_API_URL || 'https://emkc.org/api/v2/piston/execute',
  'https://piston.evanlabs.io/api/v2/piston/execute',
]

const MAX_CODE_BYTES = 50_000
const MAX_STDIN_BYTES = 8_000
const RUN_TIMEOUT_MS = 15_000  // 15s total per attempt (up from 10s)
const MAX_RETRIES = 2           // try up to 2 endpoints before giving up

function byteLength(value: string) {
  return new TextEncoder().encode(value).byteLength
}

async function executePiston(
  endpoint: string,
  language: string,
  version: string,
  code: string,
  stdin: string,
): Promise<Response> {
  return fetch(endpoint, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      language,
      version,
      files: [{ content: code }],
      stdin,
      run_timeout: 5_000,
      run_memory_limit: 256 * 1024 * 1024,
    }),
    signal: AbortSignal.timeout(RUN_TIMEOUT_MS),
    cache: 'no-store',
  })
}

export async function POST(req: NextRequest) {
  const user = await getUserFromRequest(req)
  if (!user || !isStudent(user)) {
    return NextResponse.json({ error: 'Student authentication is required.' }, { status: 401 })
  }

  if (!checkRateLimit(`codebox-run:${user.id}`).success) {
    return NextResponse.json({ error: 'Please wait before running more code.' }, { status: 429 })
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

  // Try each endpoint in order until one succeeds (retry/fallback logic)
  let lastError = 'unknown'
  for (let attempt = 0; attempt < MAX_RETRIES; attempt++) {
    const endpoint = PISTON_ENDPOINTS[attempt % PISTON_ENDPOINTS.length]
    try {
      const response = await executePiston(endpoint, language, version, code, stdin)

      if (!response.ok) {
        lastError = `HTTP ${response.status} from ${new URL(endpoint).hostname}`
        // Short delay before trying fallback
        if (attempt < MAX_RETRIES - 1) await new Promise(r => setTimeout(r, 500))
        continue
      }

      const result = await response.json()
      if (!result?.run) {
        lastError = 'Invalid response shape from sandbox'
        continue
      }

      return NextResponse.json({
        stdout: String(result.run.stdout || ''),
        stderr: String(result.run.stderr || ''),
        code: Number(result.run.code ?? 1),
        signal: result.run.signal ?? null,
      })
    } catch (err) {
      lastError = err instanceof Error ? err.message : String(err)
      if (attempt < MAX_RETRIES - 1) await new Promise(r => setTimeout(r, 600))
    }
  }

  // All attempts failed
  return NextResponse.json(
    { error: `The sandbox is temporarily busy — please retry in a moment. (${lastError})` },
    { status: 503 },
  )
}
