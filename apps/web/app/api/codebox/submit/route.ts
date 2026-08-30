import { createHash } from 'node:crypto'
import { NextRequest, NextResponse } from 'next/server'
import { getUserFromRequest, isStudent } from '@/lib/auth'
import { PISTON_LANGUAGE_VERSIONS } from '../pistonConfig'
import { supabaseAdmin } from '@/lib/supabase/admin'
import { executeOpenRouterPrompt } from '@/lib/ai/openrouter-free-chain'

const PISTON_API_URL = process.env.PISTON_API_URL || 'https://emkc.org/api/v2/piston/execute'
const MAX_CODE_BYTES = 50_000
const db = supabaseAdmin as any

type TestCase = { case_index: number; stdin: string; expected_stdout: string }

function normalizeOutput(value: unknown) {
  return String(value ?? '').replace(/\r\n/g, '\n').replace(/[ \t]+$/gm, '').trim()
}

function parseEvaluation(text: string) {
  const start = text.indexOf('{')
  const end = text.lastIndexOf('}')
  if (start < 0 || end <= start) throw new Error('AI response did not contain JSON.')
  const value = JSON.parse(text.slice(start, end + 1)) as Record<string, unknown>
  const quality = Number(value.quality_score)
  if (!Number.isFinite(quality) || quality < 0 || quality > 10) throw new Error('Invalid quality score.')
  return {
    quality_score: Math.round(quality),
    time_complexity: String(value.time_complexity || 'Not determined').slice(0, 80),
    space_complexity: String(value.space_complexity || 'Not determined').slice(0, 80),
    issues: Array.isArray(value.issues) ? value.issues.slice(0, 5).map(String) : [],
    brief_feedback: String(value.brief_feedback || '').slice(0, 800),
  }
}

async function executeCase(code: string, language: string, version: string, test: TestCase) {
  const started = Date.now()
  const response = await fetch(PISTON_API_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      language,
      version,
      files: [{ content: code }],
      stdin: test.stdin,
      run_timeout: 3_000,
      run_memory_limit: 256 * 1024 * 1024,
    }),
    signal: AbortSignal.timeout(10_000),
    cache: 'no-store',
  })
  if (!response.ok) throw new Error(`Piston returned ${response.status}`)
  const payload = await response.json()
  if (!payload?.run) throw new Error('Piston response was incomplete.')
  const stdout = normalizeOutput(payload.run.stdout)
  const stderr = normalizeOutput(payload.run.stderr || payload.compile?.stderr)
  const passed = Number(payload.run.code ?? 1) === 0 && stdout === normalizeOutput(test.expected_stdout)
  return {
    test_index: test.case_index,
    passed,
    stdout: test.case_index === 0 ? stdout : undefined,
    stderr: stderr.slice(0, 1000),
    runtime_ms: Date.now() - started,
  }
}

export async function POST(req: NextRequest) {
  const user = await getUserFromRequest(req)
  if (!user || !isStudent(user)) {
    return NextResponse.json({ error: 'Student authentication is required.' }, { status: 401 })
  }

  const body = await req.json().catch(() => null) as {
    questId?: unknown; code?: unknown; language?: unknown
  } | null
  const questId = typeof body?.questId === 'string' ? body.questId : ''
  const code = typeof body?.code === 'string' ? body.code : ''
  const language = typeof body?.language === 'string' ? body.language.toLowerCase() : ''
  const version = PISTON_LANGUAGE_VERSIONS[language]

  if (!/^[0-9a-f-]{36}$/i.test(questId) || !code.trim() || !version) {
    return NextResponse.json({ error: 'Quest, language, or source code is invalid.' }, { status: 400 })
  }
  const sourceBytes = new TextEncoder().encode(code).byteLength
  if (sourceBytes > MAX_CODE_BYTES) {
    return NextResponse.json({ error: 'Source code exceeds the 50 KB submission limit.' }, { status: 413 })
  }

  const [{ data: quest }, { data: profile }] = await Promise.all([
    db.from('quests').select('*').eq('id', questId).maybeSingle(),
    db.from('users').select('batch_id, team_uuid').eq('id', user.id).maybeSingle(),
  ])
  if (!quest || quest.status !== 'published') {
    return NextResponse.json({ error: 'This quest is not available.' }, { status: 404 })
  }
  if (quest.available_from && new Date(quest.available_from) > new Date()) {
    return NextResponse.json({ error: 'This quest has not opened yet.' }, { status: 403 })
  }
  if (quest.due_at && new Date(quest.due_at) < new Date()) {
    return NextResponse.json({ error: 'The submission window has closed.' }, { status: 403 })
  }
  if (quest.target_batch_id && quest.target_batch_id !== profile?.batch_id) {
    return NextResponse.json({ error: 'This quest belongs to another batch.' }, { status: 403 })
  }
  if (quest.target_team_ids?.length && !quest.target_team_ids.includes(profile?.team_uuid)) {
    return NextResponse.json({ error: 'This quest is not assigned to your squad.' }, { status: 403 })
  }
  if (!quest.allowed_languages.includes(language)) {
    return NextResponse.json({ error: 'This language is not enabled for the quest.' }, { status: 400 })
  }

  const { data: previous } = await db
    .from('code_submissions')
    .select('attempt_number')
    .eq('quest_id', questId)
    .eq('student_id', user.id)
    .order('attempt_number', { ascending: false })
    .limit(1)
    .maybeSingle()
  const attemptNumber = Number(previous?.attempt_number || 0) + 1
  if (attemptNumber > quest.max_attempts) {
    return NextResponse.json({ error: 'The maximum number of attempts has been reached.' }, { status: 409 })
  }

  const { data: tests, error: testError } = await db
    .from('quest_test_cases')
    .select('case_index, stdin, expected_stdout')
    .eq('quest_id', questId)
    .order('case_index')
  if (testError || !tests || tests.length < 2) {
    return NextResponse.json({ error: 'This quest is awaiting a verified hidden test suite.' }, { status: 409 })
  }

  const caseResults = []
  let sandboxError = false
  for (const test of tests as TestCase[]) {
    try {
      caseResults.push(await executeCase(code, language, version, test))
    } catch {
      sandboxError = true
      break
    }
  }

  if (sandboxError) {
    return NextResponse.json(
      { error: 'The sandbox became unavailable. No attempt was consumed; please retry.' },
      { status: 503 },
    )
  }

  const passedCount = caseResults.filter((item) => item.passed).length
  const passRate = passedCount / tests.length
  const passedTests = passRate >= Number(quest.min_pass_rate)
  let aiEvaluation: ReturnType<typeof parseEvaluation> | null = null
  let modelUsed: string | null = null

  if (passedTests) {
    try {
      const ai = await executeOpenRouterPrompt(
        `Problem:\n${quest.problem_md}\n\nLanguage: ${language}\nSource:\n${code}\n\nReturn JSON only with quality_score (0-10), time_complexity, space_complexity, issues (array), and brief_feedback. Evaluate maintainability and algorithmic quality; test correctness has already been measured by the sandbox.`,
        'code_evaluation',
        'You are the PSGMX code-quality reviewer. Never claim execution results. Return compact JSON only.',
      )
      aiEvaluation = parseEvaluation(ai.text)
      modelUsed = ai.modelUsed
    } catch {
      // A passing solution remains pending until a real model can evaluate it.
    }
  }

  const qualityPassed = Boolean(aiEvaluation && aiEvaluation.quality_score >= quest.min_ai_quality_score)
  const verified = passedTests && qualityPassed
  const verdict = verified ? 'verified_complete' : passedTests ? 'pending' : 'failed_tests'
  const submissionId = crypto.randomUUID()
  const storagePath = `submissions/${user.id}/${questId}/${submissionId}.${language}.txt`
  const upload = await supabaseAdmin.storage.from('quests').upload(storagePath, code, {
    contentType: 'text/plain; charset=utf-8',
    upsert: false,
  })
  if (upload.error) {
    return NextResponse.json({ error: 'The private submission archive is unavailable. No attempt was consumed.' }, { status: 503 })
  }

  const testSummary = {
    passed_count: passedCount,
    total_count: tests.length,
    cases: caseResults.map(({ test_index, passed, stderr, runtime_ms, stdout }) => ({
      test_index, passed, stderr, runtime_ms, ...(test_index === 0 ? { stdout } : {}),
    })),
  }
  const { error: insertError } = await db.from('code_submissions').insert({
    id: submissionId,
    quest_id: questId,
    student_id: user.id,
    attempt_number: attemptNumber,
    language,
    code_storage_path: storagePath,
    code_sha256: createHash('sha256').update(code).digest('hex'),
    source_bytes: sourceBytes,
    piston_results_json: testSummary,
    ai_evaluation_json: aiEvaluation,
    ai_model_used: modelUsed,
    verdict,
    is_verified_complete: verified,
    completed_at: verified ? new Date().toISOString() : null,
    verification_reason: verified
      ? 'Hidden tests and AI quality threshold passed.'
      : passedTests
        ? 'Hidden tests passed; AI quality review is pending.'
        : 'One or more sandbox test cases failed.',
  })
  if (insertError) {
    await supabaseAdmin.storage.from('quests').remove([storagePath])
    return NextResponse.json({ error: 'The attempt could not be recorded. Please retry.' }, { status: 409 })
  }

  return NextResponse.json({
    submission_id: submissionId,
    verdict,
    is_verified_complete: verified,
    test_results: testSummary,
    ai_evaluation: aiEvaluation,
    message: verdict === 'pending' ? 'Tests passed. AI quality review will retry when a model is available.' : undefined,
  })
}
