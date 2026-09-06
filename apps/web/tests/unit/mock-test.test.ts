/**
 * Test 2: Mock Test data fetching — payload structure & state
 *
 * Tests:
 * - Exam payload shape matches expected Supabase schema
 * - Question array structure is valid for submission
 * - Answer payload is correctly keyed by question_id with option letter
 * - Submission payload is correctly structured with exam_id, answers, time, flags
 * - Score percentage is correctly computed from raw/total marks
 * - Proctoring flags array is bounded to last 50 entries
 */

import { describe, it, expect } from 'vitest'

// ─── Payload shape validators ───────────────────────────────────────────────

type Question = {
  id: string
  question_text: string
  option_a: string
  option_b: string
  option_c: string
  option_d: string
  marks: number
}

type ExamRow = {
  id: string
  title: string
  description: string | null
  duration_minutes: number
  total_marks: number
  exam_date: string | null
  batch_id: string | null
}

type SubmissionPayload = {
  exam_id: string
  answers: Record<string, string>
  time_taken_seconds: number
  proctoring_flags: Array<{ type: string; at: string }>
}

function buildSubmissionPayload(
  examId: string,
  answers: Record<string, string>,
  startedAt: number,
  flags: Array<{ type: string; at: string }>,
): SubmissionPayload {
  return {
    exam_id: examId,
    answers,
    time_taken_seconds: Math.floor((Date.now() - startedAt) / 1000),
    proctoring_flags: flags.slice(-50),
  }
}

function computeScore(rawMarks: number, outOf: number): number {
  if (outOf <= 0) return 0
  return Math.round((rawMarks / outOf) * 100)
}

// ─── Tests ───────────────────────────────────────────────────────────────────

describe('Mock Test: Exam schema validation', () => {
  const mockExam: ExamRow = {
    id: 'exam-uuid-001',
    title: 'Week 1 Auto-Mock: DSA',
    description: 'Faculty-curated DSA practice exam',
    duration_minutes: 60,
    total_marks: 50,
    exam_date: new Date().toISOString(),
    batch_id: 'batch-uuid-25mx',
  }

  it('PASS: exam row has all required fields', () => {
    expect(mockExam.id).toBeTruthy()
    expect(mockExam.title).toBeTruthy()
    expect(typeof mockExam.duration_minutes).toBe('number')
    expect(mockExam.duration_minutes).toBeGreaterThan(0)
    expect(typeof mockExam.total_marks).toBe('number')
    expect(mockExam.total_marks).toBeGreaterThan(0)
  })

  it('PASS: exam allows null exam_date (open/rolling exams)', () => {
    const openExam: ExamRow = { ...mockExam, exam_date: null }
    expect(openExam.exam_date).toBeNull()
  })
})

describe('Mock Test: Question bank shape', () => {
  const mockQuestion: Question = {
    id: 'q-uuid-001',
    question_text: 'What is the time complexity of binary search?',
    option_a: 'O(n)',
    option_b: 'O(log n)',
    option_c: 'O(n log n)',
    option_d: 'O(1)',
    marks: 2,
  }

  it('PASS: question has all required four options', () => {
    expect(mockQuestion.option_a).toBeTruthy()
    expect(mockQuestion.option_b).toBeTruthy()
    expect(mockQuestion.option_c).toBeTruthy()
    expect(mockQuestion.option_d).toBeTruthy()
  })

  it('PASS: question marks is a positive number', () => {
    expect(typeof mockQuestion.marks).toBe('number')
    expect(mockQuestion.marks).toBeGreaterThan(0)
  })
})

describe('Mock Test: Answer state & submission payload', () => {
  it('PASS: answers map is keyed by question ID with option letter A-D', () => {
    const answers: Record<string, string> = {
      'q-uuid-001': 'B',
      'q-uuid-002': 'A',
      'q-uuid-003': 'D',
    }
    Object.entries(answers).forEach(([qId, letter]) => {
      expect(qId).toBeTruthy()
      expect(['A', 'B', 'C', 'D']).toContain(letter)
    })
  })

  it('PASS: submission payload includes exam_id, answers, time, and flags', () => {
    const startedAt = Date.now() - 5000
    const payload = buildSubmissionPayload(
      'exam-uuid-001',
      { 'q-uuid-001': 'B' },
      startedAt,
      [],
    )
    expect(payload.exam_id).toBe('exam-uuid-001')
    expect(payload.answers).toHaveProperty('q-uuid-001', 'B')
    expect(payload.time_taken_seconds).toBeGreaterThanOrEqual(5)
    expect(Array.isArray(payload.proctoring_flags)).toBe(true)
  })

  it('PASS: proctoring flags are bounded to the last 50 entries', () => {
    const flags = Array.from({ length: 80 }, (_, i) => ({
      type: 'tab_hidden',
      at: new Date(Date.now() + i * 1000).toISOString(),
    }))
    const payload = buildSubmissionPayload('exam-uuid-001', {}, Date.now() - 1000, flags)
    expect(payload.proctoring_flags).toHaveLength(50)
    // Should be the LAST 50, not the first 50
    expect(payload.proctoring_flags[0]).toEqual(flags[30])
  })
})

describe('Mock Test: Score computation', () => {
  it('PASS: computes correct percentage from raw marks', () => {
    expect(computeScore(40, 50)).toBe(80)
    expect(computeScore(25, 50)).toBe(50)
    expect(computeScore(50, 50)).toBe(100)
    expect(computeScore(0, 50)).toBe(0)
  })

  it('PASS: handles zero out-of without crashing', () => {
    expect(computeScore(10, 0)).toBe(0)
  })

  it('PASS: rounds fractional percentages', () => {
    expect(computeScore(1, 3)).toBe(33) // 33.33... → 33
    expect(computeScore(2, 3)).toBe(67) // 66.66... → 67
  })
})
