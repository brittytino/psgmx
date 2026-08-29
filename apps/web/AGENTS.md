# PSGMX Web App — Agent Brief

## READ THIS FIRST

**The single source of truth for all product decisions is the frozen PRD:**
`docs/user-flow.md` in the root of this repository.

Do NOT make product decisions based on this file alone. This file only contains:
1. How to build and run the Next.js web app
2. What the web app is responsible for (vs the Flutter mobile app)
3. Web-specific technical constraints

Everything else — roles, capabilities, routes, AI models, free tier services, database schema, readiness engine, CodeBox, batch handover, authentication flow — is defined in `docs/user-flow.md` and is frozen. If anything in this file contradicts `docs/user-flow.md`, the PRD wins.

---

## What This App Is

Next.js web app hosted at `psgmx.tech` via Vercel Hobby plan (free).
This is both the public landing page and the full web application for all roles.

---

## Tech Stack

- Next.js (App Router, TypeScript)
- Styling: Vanilla CSS / CSS Modules (no Tailwind unless explicitly requested)
- Backend: Supabase (@supabase/ssr package, anon key + RLS for client, service role for server actions)
- Auth: Supabase Auth with OTP — Resend handles email delivery
- CodeBox: Monaco Editor (@monaco-editor/react) + Piston API (emkc.org) for code execution
- AI: OpenRouter API (free models only, called from server-side Edge Functions — never from client)
- Push notifications: Web Push API via Firebase Cloud Messaging
- Email: Resend (3000/month free)
- Deployment: Vercel Hobby plan

---

## Web App Responsibilities (what lives here)

- Public landing page (psgmx.tech/)
- APK download page (psgmx.tech/download — links to latest GitHub Release)
- OTP login for all roles
- Alumni first-time registration (/join-alumni)
- Student first-session calibration wizard (/onboarding)
- Student full workspace: Today, Prepare (CodeBox, assessments), Progress, Community, Build (FYP)
- PR full admin console: Command Center, Members & Import, Squads, Sessions, Quest Studio, Question Bank, Participation, Communication, Pulse, Reports, Rollout
- Faculty dashboard: Assessment Studio, Student Explorer, Recovery Hub, Knowledge Moderation, FYP Repository, Mentorship, AI Insights
- HOD governance panel: Governance Dashboard, Batch Management, Faculty Management
- Alumni workspace: Journey Archive, Contribute, Lineage, Community Board, Settings
- API routes for: version check, CodeBox execution proxy to Piston, scheduled job triggers from GitHub Actions

---

## The CodeBox (Critical Feature)

CodeBox is the most important differentiating feature. It is a VS Code-like code editor for verified coding tasks.

Built with Monaco Editor (@monaco-editor/react):
- Left panel: problem statement (Markdown rendered)
- Right panel: Monaco editor with syntax highlighting
- Run button: calls /api/codebox/run — sends code to Piston API for visible sample cases
- Submit button: calls Supabase Edge Function (compute-codebox-result) — runs hidden tests + OpenRouter AI evaluation

See docs/user-flow.md Chapter 4.3 for the full CodeBox story.
See docs/user-flow.md Chapter 11.2 for the Piston API integration architecture.

Piston API endpoint: https://emkc.org/api/v2/piston/execute
Never call Piston from the client — always go through the API route or Edge Function.

---

## Web Routes

See `docs/user-flow.md` Chapter 20 for the full route map.

---

## Build and Run

Development:
  cd apps/web
  npm install
  npm run dev

Production build (Vercel does this automatically on push to main):
  npm run build

---

## Free Tier Constraints (web-specific)

- Vercel Hobby: 100GB bandwidth/month, 1 cron job (used for nothing — GitHub Actions handles all cron)
- No self-hosted code execution — Piston API only
- All OpenRouter calls must use free models only (see docs/user-flow.md Chapter 0.2 for the fallback chain)
- Audio only for communication practice recordings (no video) — stored in Supabase Storage (1GB free)
- No paid Vercel features — no Vercel KV, no Vercel AI SDK paid features

---

## Key Environment Variables

See .env.example for all required variables. Required:
- NEXT_PUBLIC_SUPABASE_URL
- NEXT_PUBLIC_SUPABASE_ANON_KEY
- SUPABASE_SERVICE_ROLE_KEY (server-side only, never exposed to client)
- OPENROUTER_API_KEY (server-side only)
- RESEND_API_KEY (server-side only)
- CRON_SECRET (for authenticating GitHub Actions webhook calls)
- PISTON_API_URL (= https://emkc.org/api/v2/piston)

---

## Before Changing Anything

1. Read docs/user-flow.md fully — especially Chapter 0 (free tier constraints) and Appendix A (frozen decisions).
2. Check supabase/migrations/ for the current schema before adding new tables.
3. Check supabase/functions/ for existing edge functions before writing new logic.
4. All capability checks must match the capability table in docs/user-flow.md Chapter 19.
5. All AI calls must use the free model fallback chain defined in docs/user-flow.md Chapter 0.2.
6. Never expose SUPABASE_SERVICE_ROLE_KEY, OPENROUTER_API_KEY, or RESEND_API_KEY to client-side code.
7. All Piston API calls go through server-side API routes — never called directly from browser.
