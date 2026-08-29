// PSGMX — knowledge-review-reminder Edge Function
// Flags knowledge items older than 18 months for re-review (PRD 7.3).
// Dispatches weekly digests to active students via Resend (PRD 13.3).
// Called by GitHub Actions every Monday at 09:00 AM IST.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const CRON_SECRET = Deno.env.get('CRON_SECRET')
const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY')

Deno.serve(async (req) => {
  // Authenticate GitHub Actions caller
  const authHeader = req.headers.get('Authorization')
  if (!CRON_SECRET || authHeader !== `Bearer ${CRON_SECRET}`) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), {
      status: 401,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    const now = new Date()
    const eighteenMonthsAgo = new Date(now.getTime() - 18 * 30 * 24 * 60 * 60 * 1000)

    // 1. Flag knowledge items older than 18 months
    const { data: staleItems, error: fetchErr } = await supabase
      .from('knowledge_articles')
      .select('id, title, created_at')
      .lt('created_at', eighteenMonthsAgo.toISOString())
      .eq('status', 'approved')

    let flaggedCount = 0
    if (staleItems && staleItems.length > 0) {
      for (const item of staleItems) {
        await supabase
          .from('knowledge_articles')
          .update({ review_due_at: now.toISOString() })
          .eq('id', item.id)
        flaggedCount++
      }
    }

    // 2. Fetch active students for weekly digest
    const { data: students, error: studentErr } = await supabase
      .from('users')
      .select('id, name, email')
      .eq('role_label', 'Student')
      .limit(100) // free tier email limits

    let emailsSent = 0

    // Send digest emails via Resend if configured
    if (RESEND_API_KEY && students && students.length > 0) {
      for (const student of students) {
        if (!student.email) continue

        try {
          const res = await fetch('https://api.resend.com/emails', {
            method: 'POST',
            headers: {
              'Authorization': `Bearer ${RESEND_API_KEY}`,
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({
              from: 'PSGMX Companion <noreply@psgmx.tech>',
              to: student.email,
              subject: 'Your Weekly PSGMX Readiness Digest',
              html: `
                <div style="font-family: sans-serif; max-width: 600px; margin: auto; padding: 20px; border: 1px solid #eee; border-radius: 12px;">
                  <h2 style="color: #6C3DFF;">Good morning, ${student.name}!</h2>
                  <p style="color: #555; line-height: 1.6;">
                    Here is your weekly preparation summary on PSGMX. Consistency is your greatest advantage for placement season.
                  </p>
                  <div style="background: #F9F8FD; padding: 16px; border-radius: 8px; margin: 20px 0;">
                    <h4 style="margin-top: 0; color: #222;">Recommended actions this week:</h4>
                    <ul style="color: #666; padding-left: 20px;">
                      <li>Complete your Daily Five sessions</li>
                      <li>Check your CodeBox verified quests</li>
                      <li>Practice a 2-minute interview audio response</li>
                    </ul>
                  </div>
                  <a href="https://psgmx.tech/student" style="display: inline-block; background: #6C3DFF; color: white; padding: 12px 24px; text-decoration: none; border-radius: 8px; font-weight: bold;">
                    Open Today's Companion
                  </a>
                  <p style="font-size: 12px; color: #999; margin-top: 30px;">
                    PSGMX · Placement Readiness Companion · PSG Tech MCA
                  </p>
                </div>
              `,
            }),
          })
          if (res.ok) emailsSent++
        } catch (e) {
          console.warn(`Failed to send digest email to ${student.email}:`, e)
        }
      }
    }

    return new Response(
      JSON.stringify({
        ok: true,
        flagged_knowledge_items: flaggedCount,
        weekly_digests_sent: emailsSent,
        timestamp: now.toISOString(),
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    )
  } catch (err) {
    console.error('Knowledge review reminder error:', err)
    return new Response(
      JSON.stringify({ error: String(err) }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})
