// PSGMX — send-push Edge Function
// Delivers a real FCM push for a notification row (PRD Ch. 13.1) instead of
// the mobile app's previous foreground-only delivery (a Realtime
// subscription that did nothing for a backgrounded/killed app).
//
// Called by an authenticated client right after it inserts a row into
// `notifications` (e.g. AnnouncementProvider.createAnnouncement on mobile,
// or the equivalent web path) with { notification_id }. Recipients and
// message content are always re-derived server-side from that row — the
// caller cannot push arbitrary text to arbitrary users.
//
// Needs one Edge Function secret, FCM_SERVICE_ACCOUNT_JSON: the full JSON
// key for a Firebase service account with the "Firebase Cloud Messaging
// API" role, downloaded from Firebase Console -> Project Settings -> Service
// Accounts -> Generate new private key. Until that secret is set, this
// function returns a clear 501 instead of silently no-op'ing.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const fcmServiceAccountJson = Deno.env.get('FCM_SERVICE_ACCOUNT_JSON')

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: { 'Content-Type': 'application/json' } })
}

function base64UrlEncode(bytes: Uint8Array): string {
  let str = ''
  for (const b of bytes) str += String.fromCharCode(b)
  return btoa(str).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const b64 = pem
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\s+/g, '')
  const binary = atob(b64)
  const bytes = new Uint8Array(binary.length)
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i)
  return bytes.buffer
}

async function getAccessToken(): Promise<string> {
  const account = JSON.parse(fcmServiceAccountJson!) as {
    client_email: string
    private_key: string
    project_id: string
  }

  const header = { alg: 'RS256', typ: 'JWT' }
  const now = Math.floor(Date.now() / 1000)
  const claims = {
    iss: account.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  }
  const encoder = new TextEncoder()
  const unsigned = `${base64UrlEncode(encoder.encode(JSON.stringify(header)))}.${base64UrlEncode(encoder.encode(JSON.stringify(claims)))}`

  const key = await crypto.subtle.importKey(
    'pkcs8',
    pemToArrayBuffer(account.private_key),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign']
  )
  const signature = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, encoder.encode(unsigned))
  const jwt = `${unsigned}.${base64UrlEncode(new Uint8Array(signature))}`

  const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  })
  if (!tokenResponse.ok) {
    throw new Error(`OAuth2 token exchange failed: ${await tokenResponse.text()}`)
  }
  const tokenBody = await tokenResponse.json()
  return tokenBody.access_token as string
}

Deno.serve(async (req: Request) => {
  if (req.method !== 'POST') return json({ error: 'Method Not Allowed' }, 405)
  if (!fcmServiceAccountJson) {
    return json({ error: 'FCM_SERVICE_ACCOUNT_JSON secret is not configured yet.' }, 501)
  }

  const authHeader = req.headers.get('authorization')
  if (!authHeader?.startsWith('Bearer ')) return json({ error: 'Unauthorized' }, 401)

  let notificationId: string
  try {
    const body = await req.json()
    notificationId = body.notification_id
    if (typeof notificationId !== 'string' || notificationId.length === 0) {
      throw new Error('Missing notification_id')
    }
  } catch (error) {
    return json({ error: 'Invalid request body', detail: String(error) }, 400)
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey)
  const token = authHeader.slice(7)
  if (token !== serviceRoleKey) {
    const { data: { user }, error } = await supabase.auth.getUser(token)
    if (error || !user) return json({ error: 'Unauthorized' }, 401)
  }

  const { data: notification, error: notifError } = await supabase
    .from('notifications')
    .select('id, title, message, target_audience, notification_type')
    .eq('id', notificationId)
    .maybeSingle()
  if (notifError || !notification) return json({ error: 'Notification not found' }, 404)

  // Resolve recipients: 'all' targets every user with a registered device;
  // anything else is treated as a specific user id (matches the audience
  // check already used client-side in notification_service.dart).
  let tokenQuery = supabase.from('device_tokens').select('token, platform')
  if (notification.target_audience && notification.target_audience !== 'all') {
    tokenQuery = tokenQuery.eq('user_id', notification.target_audience)
  }
  const { data: tokens, error: tokensError } = await tokenQuery
  if (tokensError) return json({ error: 'Could not load device tokens' }, 500)
  if (!tokens || tokens.length === 0) return json({ success: true, sent: 0, reason: 'No registered devices' })

  let accessToken: string
  try {
    accessToken = await getAccessToken()
  } catch (error) {
    console.error(JSON.stringify({ event: 'fcm_oauth_failed', message: String(error) }))
    return json({ error: 'Could not authenticate with FCM' }, 502)
  }

  const projectId = JSON.parse(fcmServiceAccountJson).project_id as string
  let sent = 0
  let failed = 0
  for (const row of tokens) {
    try {
      const response = await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${accessToken}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({
          message: {
            token: row.token,
            notification: { title: notification.title, body: notification.message },
            data: { notification_id: notification.id, notification_type: notification.notification_type ?? 'announcement' },
          },
        }),
      })
      if (response.ok) {
        sent++
      } else {
        failed++
        const detail = await response.text()
        // An invalid/expired token is expected over time (uninstalled app,
        // reinstalled app, etc.) — prune it instead of retrying forever.
        if (detail.includes('UNREGISTERED') || detail.includes('NOT_FOUND')) {
          await supabase.from('device_tokens').delete().eq('token', row.token)
        }
      }
    } catch {
      failed++
    }
  }

  return json({ success: true, sent, failed, total: tokens.length })
})
