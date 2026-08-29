import { NextRequest, NextResponse } from 'next/server'
import { getUserFromRequest } from '@/lib/auth'
import { PISTON_LANGUAGE_VERSIONS } from '../pistonConfig'

export async function POST(req: NextRequest) {
  try {
    const user = await getUserFromRequest(req)
    if (!user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const body = await req.json()
    const { code, language, stdin } = body

    if (!code || !language) {
      return NextResponse.json({ error: 'Missing code or language' }, { status: 400 })
    }

    const version = PISTON_LANGUAGE_VERSIONS[language]
    if (!version) {
      return NextResponse.json({ error: 'Unsupported language' }, { status: 400 })
    }

    // Call Piston API
    const response = await fetch('https://emkc.org/api/v2/piston/execute', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        language,
        version,
        files: [{ content: code }],
        stdin: stdin || '',
      }),
    })

    if (!response.ok) {
      const errorText = await response.text()
      console.error('Piston API error:', errorText)
      return NextResponse.json({ error: 'Failed to execute code' }, { status: 500 })
    }

    const result = await response.json()

    return NextResponse.json({
      stdout: result.run.stdout,
      stderr: result.run.stderr,
      code: result.run.code,
      signal: result.run.signal,
    })
  } catch (error) {
    console.error('CodeBox run error:', error)
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 })
  }
}
