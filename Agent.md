# PSGMX — Development Specification (Agent Brief)

**Purpose of this document:** this is the single, consolidated source of truth for building the next version of PSGMX. It replaces and merges everything decided across earlier planning — the existing app's current functionality, the product vision, and every constraint locked in since. Hand this whole file to a coding agent as the project brief; nothing prior to this needs to be re-explained.

**One-line identity:** PSGMX is a free, self-hosted, open-source mobile app built by an MCA student at PSG College of Technology, for the ~120 students in each of two active MCA batches (currently 2025–2027 and 2026–2028), to handle daily attendance, placement-readiness habits, and placement knowledge-sharing. It is not an ERP, not a faculty tool, not a multi-college SaaS product, and not an exam platform — a separate, stricter, desktop-only platform with faculty access already exists for real proctored testing, and PSGMX only ever feeds that platform a readiness number, nothing more.

---

## 1. What Already Exists (Foundation — Keep, Don't Rebuild)

The current production app (v3.1.5) already has a working architecture that the new work builds on top of, not instead of:

- **Stack:** Flutter 3.27+, Provider state management, Go Router, Supabase (Postgres + Auth + Realtime), Firebase Hosting, a Python FastAPI service that scrapes the college eCampus portal.
- **Auth:** OTP-based login restricted to `@psgtech.ac.in` emails.
- **Attendance:** Python scraper pulls official class attendance, CGPA, CA marks, and exam timetables from eCampus; QR-based team attendance marking already exists for in-app team flows.
- **LeetCode:** public-API stats sync, 12-hour cache, auto-refresh every 6 hours, weekly top-performer and 50-problem-milestone announcements.
- **Tasks:** daily LeetCode + core-subject task publishing, student completion marking, team-leader verification.
- **Notifications:** real-time push, birthday notifications, CA exam reminders.
- **Admin:** defaulter detection (attendance < 75% or 3+ consecutive absences), audit log table (exists but currently unused), app version/force-update control.
- **Known issues to fix in parallel** (from the existing audit — not blocking new feature work, but must land before wider rollout): hardcoded Supabase/eCampus secrets need to move to proper env config; RLS policies need rewriting to match the new dynamic permission model in Section 4; OTP requests need rate limiting; the audit log table needs to actually be written to; basic automated test coverage needs to exist before more contributors touch the codebase; HTTP calls need timeout defaults; memory/stream leaks in provider disposal need cleanup.

Everything below is new work layered on this foundation.

---

## 2. Batch System (Replaces the Hardcoded Whitelist)

There is no seed file of names anymore. A `batches` table holds one row per MCA batch — `batch_code` (e.g. `25MX`, `26MX`), `start_year`, `end_year`, and `status` (`active_senior`, `active_junior`, or `graduated`). At any point in time exactly two batches are `active` — the senior batch going through placements and the junior batch a year behind — and every batch before them is `graduated`.

On first sign-in, a student enters their `@psgtech.ac.in` email and roll number. The app parses the batch code embedded in the roll number and auto-assigns the student to the matching `batches` row — no manual whitelist entry, ever. When a batch's `end_year` passes its cutoff date (e.g. results/convocation), a scheduled job flips that batch's status to `graduated` and disables login for every account in it. Their data is not deleted — anything meant to persist (most importantly placement log entries, see Section 8) stays visible to every batch after them. The next batch then becomes `active_senior` automatically, and a newly detected batch becomes `active_junior`. This loop must run correctly with zero manual intervention for at least 3–5 years.

---

## 3. Roles & Dynamic Team Management

### 3.1 Role labels (fixed, familiar — do not genericize)
The four role names stay exactly as the department already knows them: **Placement Rep**, **Placement Coordinator**, **Team Leader**, **Student**. These are UI labels only.

### 3.2 Underlying permission model (dynamic — this is what's actually new)
Under the hood, access is controlled by individual permission flags assigned per user, not a fixed bundle per role label. Example flags: `manage_members`, `configure_teams`, `schedule_placement_sessions`, `mark_placement_attendance` (scoped to own team for a Team Leader, batch-wide for Rep/Coordinator), `publish_tasks`, `manage_company_records`, `moderate_placement_log`, `view_batch_analytics`. The role labels above are just convenient presets that pre-check a sensible default set of flags — a Placement Rep can still hand someone the "Coordinator" label but only grant them, say, `moderate_placement_log`, without `publish_tasks`. This is the "everything should be dynamic hereafter" requirement: role *names* stay familiar, but exact *capability* per person is always configurable by whoever holds `manage_members` for that batch.

### 3.3 Placement Rep
Each active batch has exactly one Placement Rep (so two exist at any given time, one per batch), and the two hold identical permission ceilings — neither outranks the other, each manages only their own batch. The Rep is the only role that starts with every permission flag by default and is the only one who can grant/revoke flags on anyone else in their batch.

### 3.4 Coordinators
A Rep can create any number of Coordinator slots and assign each one whatever permission subset makes sense (e.g. one Coordinator scoped only to task publishing, another scoped only to placement-log moderation). There is no fixed "what a Coordinator can do" — that's entirely Rep-configured per person.

### 3.5 Team Leaders & dynamic team sizing
With ~120 students in a batch, one Rep cannot manage everyone directly, which is why teams exist. The Rep sets a target team size — a plain configurable number, commonly 5, 6, 7, 10, or 12, chosen per batch — and the system auto-distributes the batch's students into teams of roughly that size (`ceil(student_count / team_size)` teams). The Rep can manually rebalance individual students between teams afterward, and assigns one Team Leader per team. A Team Leader's only batch-level permission by default is marking placement-session attendance (Section 5.2) for their own team's members; nothing else is granted unless the Rep explicitly adds it.

---

## 4. Attendance — Two Separate Systems, Do Not Conflate

This is a critical distinction that the previous version of this app did not have: **official class attendance and placement-readiness attendance are two different things, tracked separately, used for different purposes.**

### 4.1 Official Academic Attendance (existing, unchanged in purpose)
Scraped weekly from the college portal via the Python service, refreshed every Thursday. Because the data is a week stale by the time Wednesday rolls around, every screen showing it must carry a visible "as of [last Thursday's date]" freshness label, updating to a "just synced" state from Friday onward. This number reflects the student's actual academic standing (the 75% rule that gates writing semester exams) and is shown for the student's own information. Alongside it, semester CA and end-semester exam dates pulled from the synced timetable should trigger local push notifications — one about a week ahead, a sharper one the day before. **This number is informational only and is never used in the readiness score.**

### 4.2 Placement Class Attendance (new, this is what drives readiness)
The Placement Rep (or a Coordinator granted the flag) schedules placement sessions — extra placement-prep classes, mock sessions, skill workshops — through a `placement_sessions` table: date/time, topic, and target audience (whole batch or specific teams). Team Leaders mark their own team's attendance for each session their team was targeted by, reusing the existing QR/manual marking pattern already built for team attendance. A student's **placement attendance percentage** = sessions they attended ÷ sessions they were eligible for, computed on a rolling basis. **This is the number — not the eCampus one — that feeds the readiness score formula below.** The reasoning: official attendance is already gated and enforced by the college itself; what the readiness score needs to measure is engagement with placement-specific prep, which only this in-app system tracks.

---

## 5. Readiness Score

Five inputs, four of them already rates (and therefore fair to compare across a first-year and a second-year directly), one of them normalized by within-batch percentile so accumulated time-in-program doesn't create an unfair head start:

```
Readiness = (0.30 × PlacementAttendance%)
          + (0.20 × DailyFiveStreakAdherence%)
          + (0.20 × TaskCompletionRate%)
          + (0.15 × DailyFiveAccuracyRate%)
          + (0.15 × LeetCodeMomentumPercentile)
```

- **PlacementAttendance%** — from Section 4.2, *not* the eCampus official attendance.
- **DailyFiveStreakAdherence%** — days the daily-five was fully completed ÷ eligible days, trailing 30 days.
- **TaskCompletionRate%** — verified completed daily tasks ÷ assigned tasks, trailing 30 days or current semester.
- **DailyFiveAccuracyRate%** — correct answers ÷ total answered, computed at scoring time and discarded (Section 6) but the resulting rate is retained.
- **LeetCodeMomentumPercentile** — problems solved in the trailing 30 days, converted to a percentile rank *within the student's own batch*, not a lifetime-total comparison, so a first-year on a hot streak can outrank a second-year coasting on an old total.

All five terms are 0–100, weights sum to 1.00, final score is a clean 0–100. A daily/weekly snapshot of the computed score (not the raw inputs that produced it) should be stored in a `readiness_scores` table so a student can see their own trend line over time.

**External integration:** the latest readiness score is pushed via a small authenticated public API (API-key auth, e.g. nightly batch job) to the separate desktop exam platform, which combines it with its own major-test scores into a faculty-facing combined score. PSGMX only ever pushes this one number out — it never receives or displays anything back from that platform, since faculty are not users of this app.

---

## 6. Daily Five — Test Engine

Five multiple-choice questions, mixed topics, served to every active user once per day.

- **Question pool:** lives centrally (`question_bank` table — question text, options, correct option, topic, difficulty) so it can keep growing. This is the only part of the test engine that's persisted long-term.
- **Per-attempt data:** which five questions a student got today and what they answered is never written to the central database. It exists only long enough to grade and, optionally, let an AI mentor explain a wrong answer in that same in-memory moment (Section 9). Nothing about an individual day's attempt is queryable afterward.
- **What does persist:** a `daily_five_streaks` table per user — `current_streak`, `longest_streak`, `freezes_remaining`, `freezes_reset_month`, `last_completed_date`. *(Assumption to confirm: "attended all 5" is treated as completing all five questions, not necessarily answering all five correctly — flag this if the intent was actually "all five correct.")*
- **Streak logic:** completing all five in a day → streak +1. Missing a day entirely → streak resets to 0, unless a freeze is spent. Every calendar month grants 2 freezes; unused freezes do not roll over.
- **Light proctoring (Android-capable, this app's session only):** screenshots and screen recording blocked for the duration of the five questions; an overlay/draw-over-other-apps attempt ends the attempt; minimizing or switching away from the app mid-question forfeits that day's streak. **Platform caveat to design around honestly:** this app ships natively on Android but as a PWA on iOS (Section 10), and Safari's PWA sandbox has no API to block screenshots the way a native Android app can — so the screenshot block is an Android-only guarantee, not a cross-platform one. This is deliberately lightweight compared to the separate desktop exam platform, which handles real proctoring for anything that actually counts toward a grade.

---

## 7. Placement Log

Two layers, working together:

- **Company record (header):** opened by the Placement Rep or a Coordinator with `manage_company_records`, whenever a company visits — name, visit date, roles offered, package band, eligibility criteria, the rounds it ran. Visible to everyone in both active batches, listed in ascending visit-date order so a batch's placement season reads chronologically.
- **Personal experience entries:** only **second-year students** (the batch actually going through placements that cycle) can attach their own round-by-round account to a company's entry — what the round actually covered, how it went. First-years can read but not write.
- **Lifecycle:** tied directly to the batch system in Section 2 — once a batch graduates and loses login access, their company-record and entry-writing permissions close with it, but everything they wrote stays permanently visible as the oldest layer of history for the next batch, the same way each batch inherits what came before it.

---

## 8. AI Mentor (OpenRouter, with a fallback chain)

Scoped narrowly so it never becomes a dependency the rest of the app waits on:

- Explaining a wrong daily-five answer — must happen in the same brief in-memory window before that day's questions/answers are discarded (fits the ephemeral design in Section 6 rather than fighting it).
- A short weekly note pointing at a student's weakest topic, based on their stored streak/accuracy rates (not raw answer history, since that isn't kept).
- An optional, student-initiated resume-feedback or mock-interview chat.
- **Fallback chain:** a short ordered list of free OpenRouter models; if the first is down or rate-limited, the next takes over automatically; if every model in the chain fails, fall back to a short pre-written tip rather than surfacing an error, so the AI layer is never visibly the reason something breaks.

---

## 9. Local-First Storage & Sync

Because so much of the daily-five flow is intentionally not persisted centrally, the device itself needs to hold real weight:

- **Android:** the local-database role Room would normally play, implemented via Flutter's equivalent local SQLite layer — Drift or sqflite. Holds today's cached question set, the streak/freeze counters (synced up after each completion), cached eCampus and placement-attendance data for offline viewing, and a small action queue for anything performed offline.
- **iOS (PWA):** the browser's IndexedDB plays the same role, giving the same offline-first, instantly-responsive behavior without a native app.

---

## 10. Distribution

- **Android:** APK distributed via GitHub Releases, sideloaded (no Play Store listing — this project has no budget and no intent to publish commercially).
- **iOS:** Progressive Web App only — add-to-home-screen, with push notifications and offline caching via IndexedDB, no App Store listing or developer fee involved.

---

## 11. Easter Eggs (small, low-effort, high-affection)

- Long-press the splash screen logo to reveal a short "how this started" credits screen.
- A confetti burst and a custom leaderboard title (not just a bigger number) on big daily-five streak milestones (e.g. 100 days).
- The offline/no-internet screen becomes a tiny mini-game instead of a dead end while connectivity returns.
- A short, genuine thank-you message shown once to a batch on the day their access closes after graduation.

---

## 12. Data Model Sketch (new + changed tables)

| Table | Purpose | Key fields |
|---|---|---|
| `batches` | One row per MCA batch | `id`, `batch_code`, `start_year`, `end_year`, `status` |
| `users` | Students (all 4 roles are students) | `id`, `email`, `roll_no`, `batch_id`, `role_label`, `team_id` |
| `user_permissions` | Dynamic per-user capability flags | `user_id`, `permission_key` |
| `teams` | Auto-generated, Rep-configurable | `id`, `batch_id`, `team_leader_id`, `target_size` |
| `ecampus_attendance` | Official academic attendance (existing) | unchanged — informational only |
| `placement_sessions` | Rep/Coordinator-scheduled prep sessions | `id`, `batch_id`, `scheduled_by`, `datetime`, `topic`, `target_team_ids[]` |
| `placement_attendance` | Per-session, per-student attendance | `session_id`, `user_id`, `status`, `marked_by` |
| `question_bank` | Central daily-five question pool | `id`, `text`, `options`, `correct_option`, `topic`, `difficulty` |
| `daily_five_streaks` | Persisted streak state only — no answer history | `user_id`, `current_streak`, `longest_streak`, `freezes_remaining`, `freezes_reset_month`, `last_completed_date` |
| `readiness_scores` | Daily/weekly score snapshots | `user_id`, `score`, `computed_at`, `components_json` |
| `companies` | Placement drive header records | `id`, `batch_id`, `name`, `visit_date`, `roles_offered`, `package_band`, `eligibility`, `rounds[]` |
| `placement_log_entries` | Second-year personal experience writeups | `id`, `company_id`, `user_id`, `round_name`, `experience_text`, `created_at` |
| `notifications`, `announcements`, `audit_logs`, `app_config` | Existing tables, kept | audit_logs needs to actually be written to going forward |

---

## 13. Build Order

1. Security/architecture hardening from Section 1, done quietly without changing the day-to-day experience.
2. Batch system (Section 2) and dynamic permission model (Section 3), since every later feature depends on both existing first.
3. Attendance freshness labeling + exam-date reminders, and the new placement-session scheduling + placement attendance marking flow (Section 4) — including the dynamic team-sizing tool the Rep uses to split a batch into manageable teams.
4. Daily Five engine (Section 6) with streak, freezes, and light proctoring.
5. Readiness score computation (Section 5) and the public API handoff to the external exam platform, once enough real placement-attendance and daily-five data exists to make the number meaningful.
6. Placement log (Section 7) and AI mentor (Section 8) last, since both improve with usage rather than needing to launch polished.
7. Verify the batch handover — next Rep gaining access automatically, graduating batch losing login while keeping their placement-log contributions visible — works correctly well before the 2025–2027 batch actually graduates.

---

## 14. Open Assumptions To Confirm Before/While Building

- "Attended all 5" for streak purposes is being treated as *completed all five*, not *answered all five correctly* — confirm or correct.
- Whether a `placement_session` can target a single team, a subset of teams, or only ever the whole batch.
- Whether a streak freeze applies automatically the moment a day is missed, or must be manually activated by the student beforehand.
- The exact graduation cutoff date/trigger that flips a batch from `active_senior` to `graduated` (e.g. results date vs. convocation date vs. a fixed date each year).
- Whether Team Leaders can be reassigned mid-semester by the Rep, and what happens to placement-attendance history already marked by a previous Team Leader if so.