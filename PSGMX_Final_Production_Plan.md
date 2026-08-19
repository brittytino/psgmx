# PSGMX — Final Production Development Plan
**PSG Technology · MCA Department Placement Excellence Program**
**Plan Date:** August 19, 2026 | **Status:** LOCKED FOR EXECUTION — No further scope debate, build this.
**Baseline:** Web v5.0.0 · Mobile v4.0.0 · Supabase (PostgreSQL + RLS)

> This document is the single execution plan. It resolves every open decision from the review report, defines exactly what gets built, in what order, and what "done" looks like. No hardcoded data, no plain-text secrets, no cheating loopholes ship to production.

---

## 0. How To Read This Document

- **Section 1** — the 5 decisions, now answered (no more waiting).
- **Section 2** — the 3 rules every engineer follows on this build.
- **Section 3** — security fixes (must happen before anything else touches production).
- **Section 4** — the full anti-cheating system (new, comprehensive).
- **Section 5** — readiness score integrity (so the score is real and can't be gamed).
- **Section 6** — birthday notification system (casual + formal tone, fully specified).
- **Section 7** — web data-wiring plan (kill every hardcoded value).
- **Section 8** — Placement Rep web panel (MVP spec).
- **Section 9** — Alumni mobile handling.
- **Section 10** — HOD/Faculty consolidation.
- **Section 11** — the Sprint Plan (Sprint 0 → Sprint 3, day-level).
- **Section 12** — DB migration checklist.
- **Section 13** — QA test matrix.
- **Section 14** — production launch checklist (go/no-go).
- **Section 15** — what's deliberately deferred to v1.1/v2.

---

## 1. Decisions — Locked

We don't have time to keep these open. Here's what we're building. Each can be revisited *after* launch, not before.

| # | Question | **Locked Decision** | Why |
|---|---|---|---|
| **D1** | Is HOD separate from Faculty? | **Same portal.** HOD = Faculty account with an `is_hod` flag that unlocks extra screens inside `/faculty/*` (batch management, faculty management, governance). `/super-admin/*` is renamed and folded in; `/hod/` dead route is deleted. | One portal to build and test instead of two. HOD is just "Faculty with more buttons." |
| **D2** | What does "mobile read-only" mean? | **Option B — Admin/management is web-only, everything else stays read+write on mobile.** Daily Five, LeetCode linking, placement log submission, attendance-by-team-leader stay on mobile exactly as they are. Only the 6 Placement Rep admin screens move to (and become exclusive to) the new web panel. | Option A kills the entire daily engagement loop (Daily Five) — unacceptable for a habit-building app. Option B is the only version that keeps the product useful while still centralizing admin ops where they belong: a browser. |
| **D3** | Keep eCampus integration? | **Cut from v1.** Remove `ecampus_password` column, remove `ecampus_api.py`, remove the eCampus provider screen and settings field. Ship a stub "Coming soon" if needed for continuity. | It's the single worst security liability in the app (plain-text password) and it's not required for the readiness score or placement workflow. Re-introduce in v1.1 only via Supabase Vault + a separate secured microservice with explicit per-user consent — never inline in the mobile app again. |
| **D4** | Should alumni get mobile? | **Not in v1.** Instead: if an alumni account opens the Flutter app, they see a clean "Alumni access is on the web app" screen with a link/QR — never a crash, never the student home screen. | Building real alumni mobile screens (lineage messaging, marketplace, contribute) is a multi-week job. A graceful redirect is a 1-day job and fully closes gap G5/H2 for launch. |
| **D5** | Placement Rep web panel — Phase 2 or now? | **Now, as an MVP, in Sprint 1 — not full mobile parity, just the 3 highest-value screens.** Command Center (read-only analytics + export), Team Management, Session Scheduling. Question Bank, Bulk Upload, and Member Permissions stay mobile-only for v1 and land on web in v1.1. | This was flagged Critical in the review — a Rep literally cannot operate from a laptop today. We can't skip it, but we also can't build all 6 screens in the time we have. This is the 80/20 cut. |

---

## 2. Three Non-Negotiable Rules

These apply to every screen, every PR, every developer, for the rest of this build.

1. **No hardcoded data, anywhere, ever again.** Every number a user sees (`readinessScore`, streak, dates, review-queue counts, article lists) is fetched from Supabase at request time. If real data isn't ready for a screen, show a loading skeleton or an honest empty state — never a fake number.
2. **The client never computes or writes a trust-sensitive value.** Readiness score, LeetCode percentile, exam results, attendance status — all computed server-side (RPC or Edge Function) and written by a role Postgres trusts (`service_role` or `SECURITY DEFINER` function), never directly by a student's own `UPDATE`.
3. **Every write path has an RLS policy that was actually tested with a non-owner account,** not just written and assumed correct. "It compiled" is not "it's secure."

---

## 3. Security Fixes — Do These First (Sprint 0, before anything else)

| ID | Fix | Action |
|---|---|---|
| **S1** | `ecampus_password` plain text | **Delete the column and the feature** (per D3). Migration: `ALTER TABLE users DROP COLUMN ecampus_password;` after confirming no code path reads it. Remove settings UI field on both platforms. |
| **S2** | `/hod/` dead route | Delete `apps/web/app/hod/page.tsx` entirely. Redirect any lingering links to `/faculty/`. |
| **S3** | `/api/maintainer/*` unguarded | Wrap every route handler with a check that the caller is using the `service_role` key or a hardcoded internal admin allowlist — never accept a normal user JWT. Add IP allowlisting at the edge if the hosting platform supports it. |
| **S4** | FYP read policy too open (`auth.uid() IS NOT NULL`) | Rewrite RLS: students see own FYP only; faculty/HOD see all; team members see nothing unless explicitly shared. Test with a second student's JWT to confirm denial. |
| **S5** | External avatar CDN (`ui-avatars.com`) | Replace with initials rendered client-side (SVG/CSS) or a Supabase Storage bucket for uploaded avatars. Zero external calls with student names/emails. |
| **S6** | No audit trail on score/permission changes | Add `audit_logs` inserts (via trigger or Edge Function) for: readiness score recompute, permission grants, team changes, exam grading overrides. |

**Exit criterion for Sprint 0 security work:** a second engineer, given only a student's login, cannot read another student's FYP, cannot see the maintainer API respond, and cannot find `ecampus_password` anywhere in the schema.

---

## 4. Anti-Cheating System (Full Spec — New Build)

Goal: **the readiness score must be something a faculty member and a recruiter can trust.** Every mechanism below is either "must-have for launch" or explicitly flagged "v1.1" so we don't blow the timeline chasing perfection.

### 4.1 Exam Integrity (Mock Exams)

| Mechanism | Status | Implementation |
|---|---|---|
| Server-side grading | ✅ Already exists (`submit_exam_server_side` RPC) | Keep. Never move grading logic to the client. |
| Per-student question order randomization | 🔴 Build now | Shuffle question order and MCQ option order deterministically per `(user_id, exam_id)` seed, computed server-side at exam-start RPC — not in Dart/TS. |
| Server-authoritative timer | 🔴 Build now | Exam start time is written server-side (`mock_exam_results.started_at`). Submission past `started_at + duration` is auto-rejected/auto-graded-as-is server-side, regardless of what the client sends. |
| Tab-switch / window-blur detection (web) | 🔴 Build now | `visibilitychange` + `blur` listeners push a `proctoring_flags` event (`{type: 'tab_switch', ts}`) to the exam session on every occurrence — not just once. |
| Copy-paste blocking (web) | 🔴 Build now | Disable paste (`oncopy`, `onpaste`, `oncontextmenu` prevented) on the exam question/answer surface. Log any attempted paste as a flag rather than silently blocking only. |
| Fullscreen enforcement (web) | 🔴 Build now | Exam requires Fullscreen API; exiting fullscreen logs a flag and shows a warning; 3 exits auto-submits the exam. |
| Mobile app-switch / background detection | 🔴 Build now | Flutter `AppLifecycleState.paused` triggers the same `proctoring_flags` event via the existing JSONB column already in the schema. |
| Single active session per exam attempt | 🔴 Build now | `mock_exam_results` gets a `session_token` (UUID) issued at start; if a second start request arrives for the same exam while one is active, reject it. Prevents opening the exam on two devices at once. |
| Faculty-facing flag review | 🔴 Build now | Faculty analytics gets a "Flagged Attempts" table showing flag count/type per student per exam, sortable, with a manual override/void action. |
| Webcam / face-detection proctoring | ⏭️ v1.1 (out of scope for this launch — heavy infra, privacy review needed) | Not required for launch; document as future enhancement. |

### 4.2 Daily Five Integrity

| Mechanism | Status | Implementation |
|---|---|---|
| One submission per user per day | ✅ Enforce via DB | `UNIQUE (user_id, date)` constraint on the daily-five-attempt row if not already present — reject duplicate inserts at the database, not just the UI. |
| Server-picked question set | 🔴 Build now | Question selection RPC runs server-side using a seeded random tied to `(user_id, date)` so it can't be replayed or predicted, and the client never receives the answer key until after submission. |
| Impossible-speed detection | 🔴 Build now | Log `started_at`/`submitted_at`; if total time < a floor threshold (e.g., 3 seconds for 5 questions), flag the attempt for review — don't silently accept it as a perfect streak day. |
| Answer key never shipped to client pre-submission | 🔴 Build now — audit existing API | Confirm `question_bank` reads for the daily set strip the `correct_answer` field server-side before the response leaves the API/Edge Function. This is a **must-audit item** even if the mobile app is otherwise fine, because the review didn't confirm this. |

### 4.3 LeetCode Integrity

| Mechanism | Status | Implementation |
|---|---|---|
| Username claim whitelist (prevents duplicate/fake claims) | ✅ Already exists | Keep `update_leetcode_username_unified`. |
| Server-side polling, not self-reported scores | ✅ Already exists | Keep — students cannot type in their own solved-count. |
| Rate-limit username changes | 🔴 Build now | Max 1 username change per 30 days without Rep approval, to stop swapping to a stronger public profile right before a review window. |
| Anomaly flag on sudden jumps | 🔴 Build now | If a user's solved-count jumps implausibly between two daily syncs (e.g., +50 in a day), flag for Rep/Faculty review rather than silently recomputing percentile. |

### 4.4 Readiness Score Tamper-Proofing

See Section 5 — it's significant enough to get its own section.

### 4.5 General Anti-Cheat Principles Applied App-Wide

- Every "read the answer key / correct value" API strips the sensitive field server-side before responding — never trust the client to "just not look."
- Every score-affecting table (`daily_five_streaks`, `leetcode_stats`, `readiness_scores`, `mock_exam_results`) has RLS that allows students **SELECT on their own row only**, and **zero direct INSERT/UPDATE/DELETE** — all writes go through `SECURITY DEFINER` RPCs or Edge Functions using the service role.
- All `proctoring_flags`/anomaly data rolls up into a single **"Integrity" tab** on the Faculty/Rep analytics dashboards so misconduct is visible in one place instead of buried in JSON blobs no one opens.

---

## 5. Readiness Score Integrity

The whole product's promise is "this score reflects real readiness." That only holds if it can't be gamed.

**Rules:**
1. `readiness_scores` and `readiness_score_history` are **never client-writable**. Only `compute_readiness_score(uuid)` (RPC, `SECURITY DEFINER`) may write to them.
2. The RPC is called only from: (a) the nightly Edge Function cron, (b) an event trigger after a Daily Five submission, exam result, LeetCode sync, or attendance mark — never from a button the user clicks directly claiming "recompute my score now" without a real underlying event.
3. `readiness_score_history` keeps one row per day per user — this is the audit trail. If a score looks suspicious, faculty can see exactly which component moved and when.
4. Any component flagged by the anti-cheat system (Section 4) **excludes that data point** from the score computation until a faculty member clears the flag — a flagged exam attempt shouldn't inflate the score while under review.
5. Faculty analytics gets a **"Score Breakdown" drill-down** per student (the 5 weighted components from the existing formula), not just the final number — so nobody has to trust a black box, including us.

---

## 6. Birthday Notification System (New Build)

**Tone brief:** warm and a little playful, but still reads like it's from the department, not a random app. Mix of casual language with a properly formal sign-off. Short — one push line, slightly longer in-app card.

### 6.1 Data Requirement

Add `date_of_birth DATE` to `users` (nullable, filled during onboarding or profile settings, optional field — don't block signup if a student prefers not to share it).

### 6.2 Trigger

New Supabase Edge Function: **`send-birthday-notifications`**
- Runs daily via `pg_cron` at **7:00 AM IST**.
- Query: `SELECT * FROM users WHERE EXTRACT(MONTH FROM date_of_birth) = EXTRACT(MONTH FROM CURRENT_DATE) AND EXTRACT(DAY FROM date_of_birth) = EXTRACT(DAY FROM CURRENT_DATE) AND date_of_birth IS NOT NULL;`
- For each match: insert a row into `notifications` (type = `birthday`) **and** push via Firebase Cloud Messaging (mobile) **and** surface an in-app banner on web home dashboard for that day.
- Idempotency: check a `notifications` row of type `birthday` for that user doesn't already exist today before sending, so a cron retry never double-fires.

### 6.3 Message Copy (Casual + Formal Mix)

**Push notification (short):**
> 🎉 Happy Birthday, {first_name}! Wishing you a great year ahead — Team PSGMX

**In-app notification card (slightly longer):**
> **Happy Birthday, {first_name}! 🎂**
> Hope your day's a good one. On behalf of the whole PSGMX community — faculty, seniors, and juniors — we wish you a wonderful year ahead, both in your placement journey and beyond.
> *— With warm regards, PSG MCA Department*

**Optional batch-leaderboard shoutout (small, non-intrusive):** a "🎂 Today's birthdays" chip on the batch home screen for the day, first-name only, opt-in via a `show_birthday_publicly` profile toggle (default off, respects privacy).

### 6.4 Build Checklist

- [ ] `date_of_birth` column + settings/onboarding field (optional, with a "keep private" toggle)
- [ ] `send-birthday-notifications` Edge Function + `pg_cron` schedule
- [ ] `notifications` type enum includes `birthday`
- [ ] FCM push template wired
- [ ] Web home dashboard renders birthday banner if `notifications` has an unread birthday entry for today
- [ ] Idempotency check to prevent duplicate sends
- [ ] Manual test: seed a test account with today's date, confirm one push + one in-app card, not two

---

## 7. Web Data-Wiring Plan (Kill Every Hardcoded Value)

This is the single biggest blocker (G1, G2). Every row below maps a fake value to its real source.

### 7.1 Student Dashboard (`/student/page.tsx`)

| Hardcoded Today | Real Source |
|---|---|
| `readinessScore = 72` | `SELECT * FROM readiness_scores WHERE user_id = auth.uid()` (server component fetch) |
| `streak = 14` | `daily_five_streaks.current_streak` |
| Exams count / list | `mock_exams` joined with `mock_exam_results` for upcoming + attempted |
| Articles count | `knowledge_brain_articles` count where `status = 'approved'` |
| Senior Lineage "Riya Menon" | `lineage_map` joined to `users` for the matched senior |
| Leaderboard mini | `readiness_scores` ranked within `batch_id`, top 5, anonymized per existing rule |
| Recent company drives | `companies` ordered by `drive_date DESC LIMIT 5` |

### 7.2 Faculty Dashboard (`/faculty/page.tsx`)

| Hardcoded Today | Real Source |
|---|---|
| Stat cards (Mentored, Approvals, AI Queries, Pending) | Live counts from `lineage_map`, `knowledge_brain_articles WHERE status='pending'`, AI query logs, `fyp_projects WHERE status='pending_review'` |
| Review queue (3 fake entries) | `knowledge_brain_articles WHERE status = 'pending' ORDER BY submitted_at` |
| `"May 16, 2025"` static date | `new Date()` rendered server-side, formatted per locale |
| FYP donut (32 fake) | `fyp_projects` grouped by status, real count |
| Mentorship activity feed | `lineage_messages` / mentorship session log, most recent N |
| AI Senior top queries | Aggregate query log table (add if missing — see Section 12) |

### 7.3 Alumni Dashboard (`/alumni/page.tsx`)

| Hardcoded Today | Real Source |
|---|---|
| Stat cards | `readiness_score_history` (frozen at graduation), `knowledge_brain_articles` authored count, mentorship toggle state, `lineage_map` count |
| Impact banner ("87 times") | Count of AI RAG citations referencing this alumni's approved articles (add tracking if not present — flag as v1.1 if the citation-tracking table doesn't exist yet; ship banner hidden until it does, don't ship a fake number) |
| Department activity feed | `announcements` + recent `companies` for their old batch |

**Rule for this whole section:** if a real data source genuinely doesn't exist yet (like alumni impact-citation tracking), the widget is **hidden**, not faked. A missing feature is honest; a fake number is a trust problem.

---

## 8. Placement Rep Web Panel — MVP Spec (New Build)

New route group: `/placement-rep/*`, guarded by `app_role = 'placement_rep'` (same RLS already governing mobile).

| Screen | Route | Scope for v1 |
|---|---|---|
| **Command Center** | `/placement-rep/command-center` | Batch readiness distribution chart, attendance summary, flagged-integrity count (Section 4/5), CSV export button. Read-focused — mirrors mobile screen's analytics, not every mobile feature. |
| **Team Management** | `/placement-rep/teams` | List teams, create team, assign/remove students, set team leader. Full parity with mobile write actions (same RPCs mobile already calls). |
| **Session Scheduling** | `/placement-rep/sessions` | Create/edit a placement session, assign to team(s) or whole batch, view upcoming sessions in a simple calendar/list view. |

**Explicitly NOT in v1 web panel** (stays mobile-only, ship to web in v1.1): Question Bank, Bulk Upload, Member Permissions. These are lower-frequency actions a Rep can still do from their phone without blocking launch.

---

## 9. Alumni Mobile Handling (per D4)

- Flutter `AppRouter.redirect` checks `role == 'alumni'` immediately after auth.
- Route to a new **`/alumni-web-redirect`** screen: department branding, one sentence ("Alumni access is available on the PSGMX web app"), a button/QR linking to the web login.
- No crash path, no accidental landing on the student home screen with broken widgets.

---

## 10. HOD/Faculty Consolidation (per D1)

- Add `is_hod BOOLEAN DEFAULT false` to `users` (or reuse `role = 'hod'` if the distinction needs to persist in the DB for reporting — keep the DB role as-is, just merge the **UI**).
- `/faculty/*` renders extra nav items (Batch Management, Faculty Management, Governance) only when `is_hod = true` or `role = 'hod'`.
- Delete `/super-admin/*` routes, port their functional pages into `/faculty/*` under the HOD-gated section.
- Delete `/hod/page.tsx` (S2, already listed in Section 3).

---

## 11. Sprint Plan

Four sprints, roughly a week each (compress or run partially parallel across web/mobile engineers as your team size allows — call out anything you need to cut further and we'll re-prioritize, but this is the honest order of operations).

### Sprint 0 — Security & Foundations (must finish before demo-ing to anyone)
- All of Section 3 (S1–S6)
- `date_of_birth` column + audit_logs additions from Section 12
- Confirm answer-key stripping on Daily Five API (Section 4.2, must-audit item)

### Sprint 1 — Kill the Fake Data + Rep Web MVP
- Full Section 7 wiring (student, faculty, alumni dashboards → real Supabase queries)
- Section 8: Placement Rep web panel (Command Center, Team Management, Session Scheduling)
- Section 10: HOD/Faculty consolidation, delete super-admin duplication

### Sprint 2 — Anti-Cheat + Integrity + Birthday
- Full Section 4 (exam integrity, Daily Five integrity, LeetCode integrity)
- Full Section 5 (readiness score tamper-proofing, drill-down UI)
- Full Section 6 (birthday notifications end-to-end)
- Section 9: Alumni mobile redirect screen
- Dark mode fix (`ThemeMode` read from provider, not hardcoded) — small but real bug, fits here

### Sprint 3 — Hardening, QA, Launch Prep
- Full test matrix (Section 13)
- Batch graduation dry run in staging
- Load test (60+ concurrent simulated users)
- Fix `/knowledge/` and `/download/` route purpose + auth guards
- Final security pass: re-check every RLS policy with a non-owner test account per role
- Go/no-go checklist (Section 14)

---

## 12. Database Migration Checklist

Run in this order, in staging first, always.

```sql
-- Sprint 0
ALTER TABLE users DROP COLUMN IF EXISTS ecampus_password;
ALTER TABLE users ADD COLUMN date_of_birth DATE;
ALTER TABLE users ADD COLUMN show_birthday_publicly BOOLEAN DEFAULT false;
ALTER TABLE users ADD COLUMN is_hod BOOLEAN DEFAULT false;

-- Sprint 0/2 — integrity support
ALTER TABLE mock_exam_results ADD COLUMN IF NOT EXISTS session_token UUID;
ALTER TABLE mock_exam_results ADD COLUMN IF NOT EXISTS started_at TIMESTAMPTZ;
ALTER TABLE daily_five_streaks ADD COLUMN IF NOT EXISTS last_attempt_duration_seconds INT;

-- Sprint 0/2 — LeetCode rate limit
ALTER TABLE leetcode_stats ADD COLUMN IF NOT EXISTS username_last_changed_at TIMESTAMPTZ;

-- Sprint 1 — AI query logging (for faculty "top queries" widget, if not already present)
CREATE TABLE IF NOT EXISTS ai_query_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id),
  query_text TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- notifications type support
-- confirm 'birthday' is a valid value in whatever CHECK/enum constrains notifications.type
```

**RLS re-verification list (re-test, don't just re-read):**
- `fyp_projects` SELECT policy (S4 fix)
- `readiness_scores` / `readiness_score_history` — confirm zero client INSERT/UPDATE grants
- `daily_five_streaks`, `leetcode_stats`, `mock_exam_results` — same, SELECT own row only
- `placement-rep` scoped tables (`teams`, `placement_sessions`) — confirm batch isolation still holds now that these are reachable from a new web surface, not just mobile

---

## 13. QA Test Matrix

| Area | Test | Pass Criteria |
|---|---|---|
| Data wiring | Load each dashboard (student/faculty/alumni) with a fresh seeded account | Every number matches what's actually in the DB for that account — zero static values |
| Security | Log in as Student A, attempt to read Student B's FYP via direct API call | 403/empty result |
| Security | Hit `/api/maintainer/*` with a normal user JWT | Rejected |
| Anti-cheat | Take a mock exam, switch tabs 3 times | Flag recorded each time; visible on faculty Integrity tab |
| Anti-cheat | Submit Daily Five in under 3 seconds (scripted) | Attempt flagged, not silently counted toward streak |
| Anti-cheat | Attempt to submit an exam after its time window closes | Rejected server-side regardless of client-sent timestamp |
| Readiness score | Manually attempt a client-side `UPDATE readiness_scores` as a student | Denied by RLS |
| Birthday | Seed one account with today's DOB, run the Edge Function manually | Exactly one push + one in-app notification, no duplicates on re-run |
| Rep web panel | Create a team, assign 3 students, schedule a session — all from the browser | Reflected instantly on the mobile app for the same Rep |
| Alumni mobile | Log in to Flutter app as an alumni account | Redirect screen shown, no crash, no student home leakage |
| Batch isolation | Log in as a 25MX student and a 26MX student side by side | Neither sees the other's batch-scoped sessions/leaderboard/tasks |
| Batch graduation | Run `batch-graduation` Edge Function against a staging copy | Senior batch → alumni role correctly, junior batch promotes, new batch created, no data loss |
| Dark mode | Toggle dark mode on mobile | Actually changes theme (currently hardcoded to light — must be fixed by Sprint 2) |
| Load | Simulate 60 concurrent users hitting readiness score + leaderboard endpoints | No timeout, no RLS-induced N+1 collapse |

---

## 14. Production Launch Checklist (Go/No-Go)

- [ ] All Section 3 security fixes shipped and verified by a second person, not the author
- [ ] Zero hardcoded values remain on any dashboard (grep the codebase for obvious tells like fixed numbers in JSX before sign-off)
- [ ] `ecampus_password` column and all related code fully removed
- [ ] Placement Rep can complete Team Management + Session Scheduling + view Command Center from a browser, end to end
- [ ] Anti-cheat flags are visible and reviewable by faculty for at least one real mock exam
- [ ] Readiness score cannot be written by any role other than the server RPC (re-confirmed via RLS test, not assumption)
- [ ] Birthday notification tested with a real seeded date and confirmed to fire once
- [ ] Alumni mobile login shows the redirect screen, not a crash
- [ ] `/hod/` route is gone; HOD flows live inside `/faculty/*`
- [ ] Batch graduation dry-run completed successfully in staging
- [ ] All 4 roles (Student, Faculty, Alumni, Placement Rep) walked end-to-end by someone who didn't build that part
- [ ] Dark mode toggle works on mobile
- [ ] `/knowledge/` and `/download/` routes have a defined purpose and an auth guard, or are removed

**If any box above is unchecked, this does not go to production.** Everything else in the original review (recovery hub polish, full Rep web parity, alumni mobile screens, eCampus) is explicitly allowed to wait.

---

## 15. Deferred to v1.1 / v2 (Deliberately Out of Scope Now)

- eCampus integration, rebuilt properly with Supabase Vault + a separated, consented microservice
- Full alumni mobile app (lineage messaging, marketplace, contribute-from-phone)
- Remaining 3 Placement Rep web screens (Question Bank, Bulk Upload, Member Permissions)
- Webcam/face-detection exam proctoring
- Real-time notification badge via Supabase Realtime subscriptions (nice-to-have, not launch-blocking)
- Alumni "impact" citation tracking (ship the banner only once the underlying tracking table exists)

---

*This plan supersedes the open decisions in the original review report. Sections 1–14 are the build. Section 15 is the "not now" list — keep it visible so nothing on it gets snuck back in under time pressure.*
