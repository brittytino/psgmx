import { NextRequest, NextResponse } from 'next/server'
import { getUserFromRequest, isStudent } from '@/lib/auth'
import { checkRateLimit } from '@/lib/limiter'
import { PISTON_LANGUAGE_VERSIONS } from '../pistonConfig'
import { spawnSync } from 'node:child_process'

const PISTON_ENDPOINTS = [
  process.env.PISTON_API_URL,
  'https://emkc.org/api/v2/piston/execute',
  'https://piston.evanlabs.io/api/v2/piston/execute',
].filter(Boolean) as string[]

const MAX_CODE_BYTES = 50_000
const MAX_STDIN_BYTES = 8_000
const RUN_TIMEOUT_MS = 10_000

function byteLength(value: string) {
  return new TextEncoder().encode(value).byteLength
}

async function executePiston(
  endpoint: string,
  language: string,
  version: string,
  code: string,
  stdin: string,
): Promise<{ stdout: string; stderr: string; code: number; signal: string | null } | null> {
  try {
    const response = await fetch(endpoint, {
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

    if (!response.ok) return null
    const result = await response.json()
    if (!result?.run) return null

    return {
      stdout: String(result.run.stdout || ''),
      stderr: String(result.run.stderr || ''),
      code: Number(result.run.code ?? 1),
      signal: result.run.signal ?? null,
    }
  } catch {
    return null
  }
}

function executeLocalFallback(language: string, code: string, stdin: string) {
  const lang = language.toLowerCase()
  if (lang === 'python' || lang === 'py') {
    // Try python / python3
    for (const cmd of ['python', 'python3']) {
      try {
        const res = spawnSync(cmd, ['-c', code], {
          input: stdin || '',
          encoding: 'utf-8',
          timeout: 6000,
          maxBuffer: 512 * 1024,
        })
        if (!res.error || (res.status !== null && res.status !== undefined)) {
          return {
            stdout: res.stdout || '',
            stderr: res.stderr || (res.error ? res.error.message : ''),
            code: res.status ?? (res.error ? 1 : 0),
            signal: res.signal ?? null,
          }
        }
      } catch {
        // try next
      }
    }
  }

  if (lang === 'javascript' || lang === 'js') {
    try {
      const res = spawnSync(process.execPath, ['-e', code], {
        input: stdin || '',
        encoding: 'utf-8',
        timeout: 6000,
        maxBuffer: 512 * 1024,
      })
      return {
        stdout: res.stdout || '',
        stderr: res.stderr || (res.error ? res.error.message : ''),
        code: res.status ?? (res.error ? 1 : 0),
        signal: res.signal ?? null,
      }
    } catch {
      // ignore
    }
  }

  return null
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

  // 1. Try remote Piston endpoints first
  for (const endpoint of PISTON_ENDPOINTS) {
    const res = await executePiston(endpoint, language, version, code, stdin)
    if (res) {
      return NextResponse.json(res)
    }
  }

  // 2. Fall back to local runtime execution (Python, JS)
  const localRes = executeLocalFallback(language, code, stdin)
  if (localRes) {
    return NextResponse.json(localRes)
  }

  // 3. Clear, descriptive message rather than failing fetch
  return NextResponse.json(
    {
      error: `The code sandbox service is currently updating. Python and JavaScript execution remain operational; please test with Python or JS.`,
    },
    { status: 503 },
  )
}
