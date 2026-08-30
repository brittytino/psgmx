import { NextRequest, NextResponse } from 'next/server'
import { supabaseAdmin } from '@/lib/supabase/admin'
import { executeOpenRouterPrompt } from '@/lib/ai/openrouter-free-chain'

const db = supabaseAdmin as any

/**
 * POST /api/cron/mock-test-auto
 * Called by GitHub Actions cron (Monday + Thursday 9AM IST).
 * Generates one 10-question MCQ test for the rotating domain and publishes it
 * to all active batches. Faculty can review/edit before the exam window opens.
 *
 * Authentication: CRON_SECRET header
 */
export async function POST(req: NextRequest) {
  const secret = req.headers.get('x-cron-secret') || req.headers.get('authorization')?.replace('Bearer ', '')
  if (!secret || secret !== process.env.CRON_SECRET) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  try {
    const now = new Date()
    const { week, year } = getISOWeekInfo(now)

    // Rotating domain schedule
    const DOMAINS = ['aptitude', 'coding', 'dbms', 'os', 'networks', 'core_cs', 'general'] as const
    type Domain = typeof DOMAINS[number]
    const domain: Domain = DOMAINS[week % DOMAINS.length]

    const { data: existingRows } = await db
      .from('ai_generated_tests')
      .select('id, status, batch_id')
      .eq('week_number', week)
      .eq('year', year)
      .eq('domain', domain)
      .neq('status', 'cancelled')

    // Get active batches
    const { data: batches } = await db
      .from('batches')
      .select('id, batch_code')
      .in('status', ['active_junior', 'active_senior'])

    if (!batches?.length) {
      return NextResponse.json({ message: 'No active batches found', skipped: true })
    }
    const completedBatchIds = new Set((existingRows || []).map((row: { batch_id: string }) => row.batch_id))
    const targetBatches = batches.filter((batch: { id: string }) => !completedBatchIds.has(batch.id))
    if (!targetBatches.length) {
      return NextResponse.json({ message: `Weekly ${domain} test already exists for every active batch.`, skipped: true })
    }

    // Generate questions via OpenRouter
    const domainTopics: Record<Domain, string> = {
      aptitude: 'quantitative aptitude: number systems, percentages, profit/loss, time-speed-distance, work problems',
      coding: 'data structures & algorithms: arrays, strings, recursion, trees, graphs, sorting',
      dbms: 'database management: SQL joins, normalization, transactions, ACID properties, indexing',
      os: 'operating systems: process scheduling, deadlocks, memory management, paging, semaphores',
      networks: 'computer networks: OSI model, TCP/IP, HTTP, DNS, subnetting, routing protocols',
      core_cs: 'computer science fundamentals: OOP concepts, design patterns, SDLC, version control',
      general: 'general technical knowledge: aptitude, verbal reasoning, and basic programming concepts',
    }

    const prompt = `Generate exactly 10 multiple-choice questions for a placement preparation test on the topic: ${domainTopics[domain]}.

Rules:
- Each question must have exactly 4 options labeled A, B, C, D
- One correct answer per question
- Difficulty: mix of easy (3), medium (5), and hard (2) questions
- Questions should match what IT companies test in written aptitude/technical rounds
- No questions about current events or subjective opinions

Return ONLY valid JSON in this exact format:
{
  "questions": [
    {
      "question_text": "What is the output of...",
      "options": ["Option A text", "Option B text", "Option C text", "Option D text"],
      "correct_option": "A",
      "explanation": "Brief explanation of why A is correct",
      "difficulty": "easy",
      "topic_tag": "specific subtopic"
    }
  ]
}`

    const aiResponse = await executeOpenRouterPrompt(
      prompt,
      'code_evaluation', // programming chain for technical content
      `You are an expert placement preparation instructor. Generate MCQ questions that are clear, unambiguous, and directly relevant to what IT companies test.`,
      1800,
    )

    // Parse the AI response
    const jsonStart = aiResponse.text.indexOf('{')
    const jsonEnd = aiResponse.text.lastIndexOf('}')
    if (jsonStart < 0 || jsonEnd <= jsonStart) {
      throw new Error('AI response did not contain valid JSON')
    }

    const parsed = JSON.parse(aiResponse.text.slice(jsonStart, jsonEnd + 1))
    const questions: Array<{
      question_text: string
      options: string[]
      correct_option: string
      explanation: string
      difficulty: string
      topic_tag: string
    }> = parsed.questions

    if (!Array.isArray(questions) || questions.length !== 10 || questions.some((question) =>
      !question || typeof question.question_text !== 'string' || question.question_text.trim().length < 10 ||
      !Array.isArray(question.options) || question.options.length !== 4 || question.options.some((option) => typeof option !== 'string' || !option.trim()) ||
      !['A', 'B', 'C', 'D'].includes(String(question.correct_option).toUpperCase()) ||
      !['easy', 'medium', 'hard'].includes(question.difficulty)
    )) {
      throw new Error('AI response did not contain exactly 10 valid reviewed-format questions')
    }

    // Create an exam for each active batch
    const createdExams: string[] = []
    const failures: string[] = []

    for (const batch of targetBatches) {
      const { data: generation, error: reservationError } = await db
        .from('ai_generated_tests')
        .insert({
          batch_id: batch.id,
          week_number: week,
          year,
          domain,
          question_count: questions.length,
          status: 'generated',
          model_used: aiResponse.modelUsed,
        })
        .select('id')
        .single()
      if (reservationError || !generation) {
        failures.push(`${batch.batch_code}: generation already reserved or unavailable`)
        continue
      }

      const examDate = getNextExamDate() // Next Monday or Thursday, whichever is sooner
      const { data: exam, error: examErr } = await db
        .from('mock_exams')
        .insert({
          title: `Week ${week} Auto-Mock: ${domain.replace('_', ' ').toUpperCase()}`,
          description: `AI-generated weekly practice test. Domain: ${domainTopics[domain].split(':')[0]}. Review and edit before the exam window opens.`,
          exam_date: examDate.toISOString(),
          duration_minutes: 20,
          batch_id: batch.id,
          ai_generated: true,
          domain,
        })
        .select('id')
        .single()

      if (examErr || !exam) {
        await db.from('ai_generated_tests').delete().eq('id', generation.id)
        failures.push(`${batch.batch_code}: exam creation failed`)
        continue
      }

      // Insert questions
      const questionInserts = questions.slice(0, 10).map((q, idx) => ({
        exam_id: exam.id,
        question_text: q.question_text,
        option_a: q.options[0] || '',
        option_b: q.options[1] || '',
        option_c: q.options[2] || '',
        option_d: q.options[3] || '',
        correct_option: (q.correct_option || 'A').charAt(0).toUpperCase(),
        explanation: q.explanation || null,
        difficulty: q.difficulty,
        marks: q.difficulty === 'hard' ? 2 : 1,
        order_index: idx + 1,
        topic_tag: q.topic_tag || domain,
      }))

      const { error: questionError } = await db.from('mock_exam_questions').insert(questionInserts)
      if (questionError) {
        await db.from('mock_exams').delete().eq('id', exam.id)
        await db.from('ai_generated_tests').delete().eq('id', generation.id)
        failures.push(`${batch.batch_code}: question persistence failed`)
        continue
      }
      const totalMarks = questionInserts.reduce((sum, question) => sum + question.marks, 0)
      const { error: examUpdateError } = await db.from('mock_exams')
        .update({ total_marks: totalMarks })
        .eq('id', exam.id)
      if (examUpdateError) {
        await db.from('mock_exams').delete().eq('id', exam.id)
        await db.from('ai_generated_tests').delete().eq('id', generation.id)
        failures.push(`${batch.batch_code}: exam finalization failed`)
        continue
      }

      const { error: publishError } = await db.from('ai_generated_tests').update({
        exam_id: exam.id,
        status: 'published',
        published_at: now.toISOString(),
      }).eq('id', generation.id)
      if (publishError) {
        await db.from('mock_exams').delete().eq('id', exam.id)
        await db.from('ai_generated_tests').delete().eq('id', generation.id)
        failures.push(`${batch.batch_code}: publication failed`)
        continue
      }

      createdExams.push(`${batch.batch_code}: ${exam.id}`)
    }

    if (!createdExams.length && failures.length) {
      return NextResponse.json({
        error: 'No weekly mock tests could be published.',
        failures,
      }, { status: 503 })
    }

    return NextResponse.json({
      success: true,
      domain,
      week,
      year,
      questionsGenerated: questions.length,
      batches: createdExams,
      failures,
      modelUsed: aiResponse.modelUsed,
      isFallback: aiResponse.isFallback,
    })

  } catch (err) {
    const message = err instanceof Error ? err.message : 'Unknown error'
    console.error('[mock-test-auto] Error:', message)
    return NextResponse.json({ error: message }, { status: 500 })
  }
}

// GET for manual trigger by PR/Faculty from the dashboard
export async function GET(req: NextRequest) {
  const secret = req.headers.get('x-cron-secret')
  if (!secret || secret !== process.env.CRON_SECRET) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  const { data: recent } = await db
    .from('ai_generated_tests')
    .select('id, week_number, year, domain, status, model_used, published_at, mock_exams(title, batch_id)')
    .order('published_at', { ascending: false })
    .limit(20)

  return NextResponse.json({ recentTests: recent || [] })
}

function getISOWeekInfo(date: Date): { week: number; year: number } {
  const d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()))
  const dayNum = d.getUTCDay() || 7
  d.setUTCDate(d.getUTCDate() + 4 - dayNum)
  const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1))
  return {
    week: Math.ceil((((d.getTime() - yearStart.getTime()) / 86400000) + 1) / 7),
    year: d.getUTCFullYear(),
  }
}

function getNextExamDate(): Date {
  const now = new Date()
  const day = now.getUTCDay() // Vercel runs in UTC
  // Next Monday or Thursday, whichever is first, at 9:30 AM
  const daysToMonday = (8 - day) % 7 || 7
  const daysToThursday = (4 - day + 7) % 7 || 7
  const daysAhead = Math.min(daysToMonday, daysToThursday)
  const date = new Date(now)
  date.setUTCDate(date.getUTCDate() + daysAhead)
  date.setUTCHours(4, 0, 0, 0) // 09:30 Asia/Kolkata
  return date
}
