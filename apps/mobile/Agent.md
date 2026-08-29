# PSGMX Mobile App — Agent Brief

## READ THIS FIRST

**The single source of truth for all product decisions is the frozen PRD:**
`docs/user-flow.md` in the root of this repository.

Do NOT make product decisions based on this file alone. This file only contains:
1. How to build and run the Flutter mobile app
2. What the mobile app is responsible for (vs the web app)
3. Mobile-specific technical constraints

Everything else — roles, capabilities, routes, AI models, free tier services, database schema, readiness engine, CodeBox, batch handover, authentication flow — is defined in `docs/user-flow.md` and is frozen. If anything in this file contradicts `docs/user-flow.md`, the PRD wins.

---

## What This App Is

Flutter mobile app hosted at `app.psgmx.tech` via Firebase Hosting (Spark free plan).
Android APK distributed via GitHub Releases (sideloaded, no Play Store).
iOS: Progressive Web App (add-to-home-screen) from `app.psgmx.tech`.

---

## Tech Stack

- Flutter 3.27+ (Dart)
- State management: Provider (existing — do not switch without a reason)
- Routing: Go Router (existing)
- Backend: Supabase (supabase_flutter package, anon key + RLS)
- Auth: Supabase Auth with OTP — Resend handles email delivery
- Push notifications: Firebase Cloud Messaging (firebase_messaging package)
- Local storage: drift or sqflite for offline caching
- CodeBox: deep links to `psgmx.tech/student/codebox/:questId` — CodeBox runs on the web app, not in Flutter

---

## Mobile Responsibilities (what lives here)

- Today screen (daily companion home)
- Daily Five session
- Adaptive Skill Sprint
- Communication practice (audio recording, 2-minute MP3 max — audio only, no video)
- Progress / Readiness dimensions view
- Community: squads, lineage, Knowledge Brain search
- You: profile, connected services (LeetCode/GitHub), settings, journey archive
- Unified Inbox (push + in-app)
- PR quick actions panel (capability-gated: session status, participation correction, approved templates, pause quest)
- Authentication: login, OTP verification, identity confirmation, calibration wizard

## What Does NOT Live in Flutter (lives in the web app)

- CodeBox (Monaco editor + Piston API execution) — opened via deep link
- Mock Assessment full attempt (timed, proctored) — opened via deep link to `psgmx.tech/student/exam/:id`
- PR full admin console (import, quest studio, question bank, analytics, rollout)
- Faculty dashboard (assessment studio, knowledge moderation, recovery hub, FYP repository)
- HOD governance panel
- AI Senior full Q&A (mobile shows a summarised version; full session is on web)

---

## Mobile Routes

See `docs/user-flow.md` Chapter 20 for the full route map. Key routes:

- /splash — auth + version + lifecycle resolution
- /login — OTP login
- /onboarding — calibration wizard (first login only)
- / — Today
- /train/daily-five — Daily Five session
- /train/sprint — Adaptive sprint
- /progress — Readiness overview
- /inbox — Unified inbox
- /admin — PR quick actions (capability-gated)

---

## Build and Release

Development:
  cd apps/mobile
  flutter pub get
  flutter run

Release APK is built by GitHub Actions (.github/workflows/android-release.yml) on push to release/* branch.
Android signing uses GitHub Secrets: KEYSTORE_BASE64, KEYSTORE_PASSWORD, KEY_ALIAS, KEY_PASSWORD.
Firebase Hosting deploy: firebase deploy --only hosting (done by GitHub Actions after build).

---

## Free Tier Constraints (mobile-specific)

- No video recording for communication practice — audio only (MP3, 2-minute max, approx 2MB per clip)
- No in-app code execution — CodeBox opens via deep link to psgmx.tech
- Push notifications via FCM (Firebase Spark, free forever)
- OTP via Resend (3000 emails/month free, configured in Supabase Auth custom SMTP)

---

## Key Environment Variables

See .env.flutter.example for all required variables. Required:
- SUPABASE_URL
- SUPABASE_ANON_KEY
- FIREBASE_PROJECT_ID
- WEB_APP_URL (= https://psgmx.tech, used for deep links to CodeBox and exams)

---

## Before Changing Anything

1. Read docs/user-flow.md fully — especially Chapter 0 (free tier constraints) and Appendix A (frozen decisions).
2. Check supabase/migrations/ for the current schema before adding new tables.
3. Check supabase/functions/ for existing edge functions before writing new logic.
4. All capability checks must match the capability table in docs/user-flow.md Chapter 19.
5. Never bypass RLS — always use the anon key client for user-facing operations.
6. All AI calls go through the Supabase Edge Function, never directly from Flutter.
