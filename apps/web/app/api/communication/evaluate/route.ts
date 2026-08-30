import { NextRequest, NextResponse } from 'next/server'
import { getUserFromRequest, isStudent } from '@/lib/auth'
import { supabaseAdmin } from '@/lib/supabase/admin'
import { executeOpenRouterPrompt } from '@/lib/ai/openrouter-free-chain'

const db = supabaseAdmin as any
const MAX_AUDIO_BYTES = 12 * 1024 * 1024
const ALLOWED_AUDIO = new Set(['audio/webm', 'audio/ogg', 'audio/mpeg', 'audio/mp4', 'audio/wav', 'audio/x-wav'])

function parseScores(text: string) {
  const start = text.indexOf('{'); const end = text.lastIndexOf('}')
  if (start < 0 || end <= start) throw new Error('Invalid AI response')
  const value = JSON.parse(text.slice(start, end + 1)) as Record<string, unknown>
  const score = (key: string) => Math.max(0, Math.min(10, Math.round(Number(value[key]))))
  const fillerCount = Math.max(0, Math.round(Number(value.filler_word_count || 0)))
  const scores = {
    clarity_score: score('clarity_score'),
    structure_score: score('structure_score'),
    relevance_score: score('relevance_score'),
    filler_word_count: fillerCount,
    brief_feedback: String(value.brief_feedback || '').slice(0, 700),
    suggested_improvement: String(value.suggested_improvement || '').slice(0, 700),
  }
  if (Object.values(scores).some((item) => typeof item === 'number' && !Number.isFinite(item))) {
    throw new Error('Invalid AI scores')
  }
  return scores
}

export async function GET(req: NextRequest) {
  const user = await getUserFromRequest(req)
  if (!user || !isStudent(user)) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  const [{ data: prompts }, { data: attempts }] = await Promise.all([
    db.from('communication_prompt_bank').select('id, prompt_text, category, difficulty, evaluation_focus').eq('is_active', true).order('difficulty').limit(30),
    db.from('communication_attempts').select('id, prompt_text, duration_seconds, transcript, ai_scores_json, created_at').eq('student_id', user.id).eq('is_active', true).order('created_at', { ascending: false }).limit(10),
  ])
  return NextResponse.json({ prompts: prompts || [], attempts: attempts || [] })
}

export async function POST(req: NextRequest) {
  const user = await getUserFromRequest(req)
  if (!user || !isStudent(user)) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  const formData = await req.formData()
  const audio = formData.get('audio')
  const promptId = String(formData.get('prompt_id') || '')
  const duration = Math.round(Number(formData.get('duration_seconds')))
  if (!(audio instanceof File) || !/^[0-9a-f-]{36}$/i.test(promptId)) {
    return NextResponse.json({ error: 'Select a prompt and record an answer.' }, { status: 400 })
  }
  if (!Number.isFinite(duration) || duration < 1 || duration > 120) {
    return NextResponse.json({ error: 'Record between 1 second and 2 minutes.' }, { status: 400 })
  }
  if (audio.size < 100 || audio.size > MAX_AUDIO_BYTES || !ALLOWED_AUDIO.has(audio.type)) {
    return NextResponse.json({ error: 'Unsupported or oversized audio recording.' }, { status: 415 })
  }

  const { data: prompt } = await db.from('communication_prompt_bank')
    .select('prompt_text, evaluation_focus').eq('id', promptId).eq('is_active', true).maybeSingle()
  if (!prompt) return NextResponse.json({ error: 'This practice prompt is unavailable.' }, { status: 404 })

  const sttKey = process.env.HUGGINGFACE_API_KEY?.trim()
  if (!sttKey) {
    return NextResponse.json({ error: 'Speech transcription is not configured yet. No clip was stored.' }, { status: 503 })
  }

  const attemptId = crypto.randomUUID()
  const extension = audio.type.includes('ogg') ? 'ogg' : audio.type.includes('mpeg') ? 'mp3' : audio.type.includes('wav') ? 'wav' : audio.type.includes('mp4') ? 'm4a' : 'webm'
  const storagePath = `communication/${user.id}/${attemptId}.${extension}`
  const upload = await supabaseAdmin.storage.from('student-media').upload(storagePath, audio, {
    contentType: audio.type,
    upsert: false,
  })
  if (upload.error) return NextResponse.json({ error: 'The private audio archive is unavailable.' }, { status: 503 })

  try {
    const sttResponse = await fetch(
      process.env.STT_API_URL || 'https://router.huggingface.co/hf-inference/models/openai/whisper-large-v3-turbo',
      {
        method: 'POST',
        headers: { Authorization: `Bearer ${sttKey}`, 'Content-Type': audio.type },
        body: await audio.arrayBuffer(),
        signal: AbortSignal.timeout(45_000),
      },
    )
    if (!sttResponse.ok) throw new Error('Speech transcription provider unavailable')
    const stt = await sttResponse.json()
    const transcript = String(stt?.text || '').trim()
    if (transcript.length < 5) throw new Error('No clear speech was detected')

    const ai = await executeOpenRouterPrompt(
      `Prompt: ${prompt.prompt_text}\nEvaluation focus: ${(prompt.evaluation_focus || []).join(', ')}\nTranscript: ${transcript}\nReturn JSON only: clarity_score, structure_score, relevance_score (0-10 integers), filler_word_count, brief_feedback, suggested_improvement. Score only evidence present in this transcript.`,
      'communication_evaluation',
      'You evaluate spoken interview-practice transcripts. Be specific, respectful, and concise. Return JSON only.',
    )
    const scores = parseScores(ai.text)
    const { error: insertError } = await db.from('communication_attempts').insert({
      id: attemptId,
      student_id: user.id,
      prompt_text: prompt.prompt_text,
      audio_storage_path: storagePath,
      duration_seconds: duration,
      transcript,
      ai_scores_json: scores,
      ai_model_used: ai.modelUsed,
      ai_evaluated_at: new Date().toISOString(),
    })
    if (insertError) throw insertError

    const { data: overflow } = await db.from('communication_attempts')
      .select('id, audio_storage_path').eq('student_id', user.id).eq('is_active', true)
      .order('created_at', { ascending: false }).range(10, 50)
    if (overflow?.length) {
      await db.from('communication_attempts').update({ is_active: false }).in('id', overflow.map((item: any) => item.id))
      const paths = overflow.map((item: any) => item.audio_storage_path).filter(Boolean)
      if (paths.length) await supabaseAdmin.storage.from('student-media').remove(paths)
    }

    return NextResponse.json({ attempt_id: attemptId, transcript, scores, model_used: ai.modelUsed })
  } catch (error) {
    await supabaseAdmin.storage.from('student-media').remove([storagePath])
    return NextResponse.json({
      error: error instanceof Error && error.message === 'No clear speech was detected'
        ? 'No clear speech was detected. Retake the recording closer to the microphone.'
        : 'Transcription or evaluation is temporarily unavailable. No clip was stored.',
    }, { status: 503 })
  }
}
