import { NextRequest, NextResponse } from 'next/server'
import { getUserFromRequest } from '@/lib/auth'
import { PISTON_LANGUAGE_VERSIONS } from '../pistonConfig'
import { createClient } from '@/lib/supabase/server'
import { supabaseAdmin } from '@/lib/supabase/admin'

export async function POST(req: NextRequest) {
  try {
    const user = await getUserFromRequest(req)
    if (!user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const body = await req.json()
    const { questId, code, language } = body

    if (!questId || !code || !language) {
      return NextResponse.json({ error: 'Missing required fields' }, { status: 400 })
    }

    const version = PISTON_LANGUAGE_VERSIONS[language]
    if (!version) {
      return NextResponse.json({ error: 'Unsupported language' }, { status: 400 })
    }

    const supabase = await createClient()

    // 1. Fetch quest details
    const { data: quest, error: questErr } = await supabase
      .from('quests')
      .select('*')
      .eq('id', questId)
      .single()

    if (questErr || !quest) {
      return NextResponse.json({ error: 'Quest not found' }, { status: 404 })
    }

    // 2. Fetch hidden test suite from storage (using admin client to bypass RLS if needed, though service_role has access)
    // For MVP, assume test_suite_storage_path points to a JSON file in 'quests' bucket
    let testSuite = []
    if (quest.test_suite_storage_path) {
      const { data: fileData, error: fileErr } = await supabaseAdmin.storage
        .from('quests')
        .download(quest.test_suite_storage_path)
      
      if (!fileErr && fileData) {
        const text = await fileData.text()
        testSuite = JSON.parse(text)
      }
    }

    // If no test suite found, fallback to sample_cases_json or fail
    if (testSuite.length === 0 && quest.sample_cases_json) {
      testSuite = quest.sample_cases_json
    }

    if (testSuite.length === 0) {
      return NextResponse.json({ error: 'Test suite not configured for this quest' }, { status: 500 })
    }

    // 3. Run each test case against Piston
    const caseResults = []
    let passedCount = 0

    // Limit to 10 test cases max per PRD
    const testsToRun = testSuite.slice(0, 10)

    for (let i = 0; i < testsToRun.length; i++) {
      const tc = testsToRun[i]
      const response = await fetch('https://emkc.org/api/v2/piston/execute', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          language,
          version,
          files: [{ content: code }],
          stdin: tc.input || '',
        }),
      })

      if (!response.ok) {
        caseResults.push({ test_index: i, passed: false, error: 'Piston API failure' })
        continue
      }

      const result = await response.json()
      
      // Clean stdout and expected output for comparison
      const actualOut = (result.run.stdout || '').trim()
      const expectedOut = (tc.expected_output || '').trim()
      const passed = actualOut === expectedOut

      if (passed) passedCount++

      caseResults.push({
        test_index: i,
        passed,
        stdout: actualOut,
        stderr: result.run.stderr,
      })
    }

    const testResultsJson = {
      passed_count: passedCount,
      total_count: testsToRun.length,
      cases: caseResults
    }

    const passRate = passedCount / testsToRun.length
    const passedTests = passRate >= quest.min_pass_rate

    // 4. OpenRouter AI Evaluation
    // Use OpenRouter client directly or fetch API
    let aiQualityScore = 0
    let aiEvaluationJson = null
    let aiModelUsed = null

    try {
      const openRouterKey = process.env.OPENROUTER_API_KEY
      if (openRouterKey) {
        // Fallback chain: deepseek/deepseek-r1:free
        aiModelUsed = 'deepseek/deepseek-r1:free'
        const prompt = `Evaluate this solution for correctness, time complexity, edge case handling, and code quality. 
        Problem: ${quest.problem_md}
        Code:
        ${code}
        Test Results: ${passedCount}/${testsToRun.length} passed.
        
        Return exactly valid JSON with no markdown formatting:
        { "quality_score": 0-10, "time_complexity": "O(n)", "space_complexity": "O(1)", "issues": ["issue1"], "brief_feedback": "feedback" }`

        const aiResponse = await fetch('https://openrouter.ai/api/v1/chat/completions', {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${openRouterKey}`,
            'Content-Type': 'application/json',
            'HTTP-Referer': 'https://psgmx.tech',
            'X-Title': 'PSGMX'
          },
          body: JSON.stringify({
            model: aiModelUsed,
            messages: [{ role: 'user', content: prompt }]
          })
        })

        if (aiResponse.ok) {
          const aiData = await aiResponse.json()
          let content = aiData.choices?.[0]?.message?.content || ''
          content = content.replace(/```json/g, '').replace(/```/g, '').trim()
          try {
            aiEvaluationJson = JSON.parse(content)
            aiQualityScore = aiEvaluationJson.quality_score || 0
          } catch (e) {
            console.error('Failed to parse AI response as JSON:', content)
          }
        }
      }
    } catch (aiErr) {
      console.error('AI evaluation failed:', aiErr)
    }

    const passedAi = aiQualityScore >= quest.min_ai_quality_score
    const isVerifiedComplete = passedTests && passedAi

    let verdict = 'pending'
    if (isVerifiedComplete) verdict = 'verified_complete'
    else if (!passedTests) verdict = 'failed_tests'
    else if (!passedAi) verdict = 'failed_ai_quality'

    // 5. Store submission
    // Determine attempt number
    const { data: existingAttempts } = await supabase
      .from('code_submissions')
      .select('attempt_number')
      .eq('quest_id', questId)
      .eq('student_id', user.id)
      .order('attempt_number', { ascending: false })
      .limit(1)

    const attemptNumber = (existingAttempts?.[0]?.attempt_number || 0) + 1

    const { error: insertErr } = await supabase
      .from('code_submissions')
      .insert({
        quest_id: questId,
        student_id: user.id,
        attempt_number: attemptNumber,
        language,
        piston_results_json: testResultsJson,
        ai_evaluation_json: aiEvaluationJson,
        ai_model_used: aiModelUsed,
        verdict,
        is_verified_complete: isVerifiedComplete,
        verification_reason: isVerifiedComplete ? 'Passed tests and AI quality' : 'Failed verification',
      })

    if (insertErr) {
      console.error('Failed to insert code submission:', insertErr)
      return NextResponse.json({ error: 'Failed to save submission' }, { status: 500 })
    }

    return NextResponse.json({
      verdict,
      is_verified_complete: isVerifiedComplete,
      test_results: testResultsJson,
      ai_evaluation: aiEvaluationJson
    })
  } catch (error) {
    console.error('CodeBox submit error:', error)
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 })
  }
}
