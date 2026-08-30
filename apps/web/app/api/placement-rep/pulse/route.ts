import { NextRequest, NextResponse } from 'next/server'

import { requireAppRole } from '@/lib/auth'
import { supabaseAdmin } from '@/lib/supabase/admin'

const DIMENSIONS = [
  'aptitude_reasoning',
  'coding_problem_solving',
  'core_computer_science',
  'communication_interview',
  'assessment_performance',
  'portfolio_project',
] as const

function average(values: Array<number | null | undefined>) {
  const measured = values.filter((value): value is number => typeof value === 'number' && Number.isFinite(value))
  if (measured.length === 0) return null
  return Math.round((measured.reduce((sum, value) => sum + value, 0) / measured.length) * 10) / 10
}

function readinessBand(score: number) {
  if (score >= 80) return 'strong'
  if (score >= 60) return 'building'
  if (score >= 40) return 'needs_attention'
  return 'at_risk'
}

function hasFlags(value: unknown) {
  if (Array.isArray(value)) return value.length > 0
  if (value && typeof value === 'object') return Object.keys(value).length > 0
  return typeof value === 'string' && value !== '' && value !== '[]' && value !== '{}'
}

export async function GET(request: NextRequest) {
  const representative = await requireAppRole(request, 'placement_rep')
  if (!representative) return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
  if (!representative.batch_id) return NextResponse.json({ error: 'No batch is assigned to this account.' }, { status: 409 })

  const batchId = representative.batch_id
  const weekAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString()

  const [batchResult, studentsResult, attendanceResult, sessionsResult, examsResult] = await Promise.all([
    supabaseAdmin.from('batches').select('batch_code').eq('id', batchId).maybeSingle(),
    supabaseAdmin.from('users').select('id').eq('batch_id', batchId).eq('role_label', 'Student'),
    supabaseAdmin.from('placement_attendance_summary').select('attendance_pct').eq('batch_id', batchId),
    supabaseAdmin.from('placement_sessions').select('id').eq('batch_id', batchId).gte('session_datetime', new Date().toISOString()),
    supabaseAdmin.from('mock_exams').select('id').eq('batch_id', batchId),
  ])

  const firstError = [batchResult.error, studentsResult.error, attendanceResult.error, sessionsResult.error, examsResult.error].find(Boolean)
  if (firstError) return NextResponse.json({ error: firstError.message }, { status: 500 })

  const studentIds = (studentsResult.data || []).map(({ id }) => id)
  const examIds = (examsResult.data || []).map(({ id }) => id)
  const empty = { data: [], error: null }

  const [scoresResult, dimensionsResult, streaksResult, tasksResult, examResultsResult, historyResult] = await Promise.all([
    studentIds.length
      ? supabaseAdmin.from('current_readiness_scores').select('user_id, score').in('user_id', studentIds)
      : Promise.resolve(empty),
    studentIds.length
      ? supabaseAdmin.from('readiness_dimension_scores').select('user_id, dimension, score, evidence_count').in('user_id', studentIds).eq('algorithm_version', 'v2')
      : Promise.resolve(empty),
    studentIds.length
      ? supabaseAdmin.from('daily_five_streaks').select('user_id').in('user_id', studentIds).gte('updated_at', weekAgo)
      : Promise.resolve(empty),
    studentIds.length
      ? supabaseAdmin.from('task_completions').select('user_id').in('user_id', studentIds).gte('updated_at', weekAgo)
      : Promise.resolve(empty),
    examIds.length
      ? supabaseAdmin.from('mock_exam_results').select('proctoring_flags').in('exam_id', examIds)
      : Promise.resolve(empty),
    studentIds.length
      ? supabaseAdmin.from('readiness_scores').select('user_id, score, computed_at').in('user_id', studentIds).gte('computed_at', weekAgo).order('computed_at', { ascending: false })
      : Promise.resolve(empty),
  ])

  const aggregateError = [scoresResult.error, dimensionsResult.error, streaksResult.error, tasksResult.error, examResultsResult.error, historyResult.error].find(Boolean)
  if (aggregateError) return NextResponse.json({ error: aggregateError.message }, { status: 500 })

  const scores = (scoresResult.data || []) as Array<{ user_id: string; score: number }>
  const bandCounts = { strong: 0, building: 0, needs_attention: 0, at_risk: 0 }
  for (const row of scores) bandCounts[readinessBand(Number(row.score))] += 1

  const dimensionRows = (dimensionsResult.data || []) as Array<{
    dimension: typeof DIMENSIONS[number]
    score: number
    evidence_count: number
  }>
  const dimensions = DIMENSIONS.map((dimension) => ({
    key: dimension,
    average: average(dimensionRows
      .filter((row) => row.dimension === dimension && Number(row.evidence_count) > 0)
      .map((row) => Number(row.score))),
    measuredStudents: dimensionRows.filter((row) => row.dimension === dimension && Number(row.evidence_count) > 0).length,
  }))

  const activeIds = new Set<string>()
  for (const row of (streaksResult.data || []) as Array<{ user_id: string }>) activeIds.add(row.user_id)
  for (const row of (tasksResult.data || []) as Array<{ user_id: string }>) activeIds.add(row.user_id)

  const scoreHistory = new Map<string, number[]>()
  for (const row of (historyResult.data || []) as Array<{ user_id: string; score: number }>) {
    const values = scoreHistory.get(row.user_id) || []
    values.push(Number(row.score))
    scoreHistory.set(row.user_id, values)
  }
  const declineSignalCount = [...scoreHistory.values()].filter((values) => values.length > 1 && values[0] <= values.at(-1)! - 5).length

  return NextResponse.json({
    batchCode: batchResult.data?.batch_code || '',
    totalStudents: studentIds.length,
    activeThisWeekPct: studentIds.length ? Math.round((activeIds.size / studentIds.length) * 100) : 0,
    avgReadinessScore: average(scores.map((row) => Number(row.score))),
    dimensions,
    bandCounts,
    avgAttendance: average((attendanceResult.data || []).map((row) => row.attendance_pct == null ? null : Number(row.attendance_pct))),
    flaggedAttempts: ((examResultsResult.data || []) as Array<{ proctoring_flags: unknown }>).filter((row) => hasFlags(row.proctoring_flags)).length,
    upcomingSessions: sessionsResult.data?.length || 0,
    declineSignalCount,
    generatedAt: new Date().toISOString(),
  }, {
    headers: { 'Cache-Control': 'private, no-store' },
  })
}
