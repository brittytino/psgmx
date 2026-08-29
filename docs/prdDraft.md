# PSGMX — Frozen Product Requirements Document
### Placement Readiness Companion · MCA Department · PSG Tech
**Version:** 1.1-FREEZE · **Date:** 2026-08-29 · **Status:** ✅ FROZEN — Development starts after this document

> This is the single source of truth. Every screen, backend route, AI call, and database table must trace back to a story in this document. Agent.md files in `apps/mobile` and `apps/web` exist only to point here and add app-specific build instructions; they do not redefine product decisions.

> **Free Tier Constraint (frozen):** Every service used in this product must have a free tier sufficient for fewer than 250 concurrent users. No paid plans, no VPS, no self-hosted servers. If a feature cannot be implemented on free services, it is either redesigned or moved to a future phase.

---

## Preamble — Why This Exists

Picture a first-year MCA student walking into PSG Tech on day one. They carry a laptop, a semester fee receipt, and a vague hope that two years of this programme will get them a decent job. Nobody in that room has told them what gap exists between where they are and where they need to be. They do not know whether to study DBMS first, grind LeetCode, improve their English communication, or polish a project idea. Nobody has the bandwidth to tell each of them individually.

PSGMX is the answer to that silence.

It is not a placement portal. It does not schedule drives, issue hall tickets, or announce packages. PSG Tech's NEO PAT system already does all of that. PSGMX is the daily companion that lives *before* all of that — the system that watches a student's preparation evidence accumulate over two years, tells them what to do next, verifies that they actually did it, escalates when they are stuck, and then remembers their journey forever as an alumni archive that helps the next batch.

The product serves fewer than 250 people at any moment — students of two active batches, faculty, a handful of staff, and a small alumni cohort. This is deliberately small. Small means we can build something genuinely excellent rather than something merely large.

---

## Chapter 0 — Service Stack and Free Tier Limits (Read First)

Every technology decision in this document is constrained to services with a free tier adequate for under 250 users. This chapter is the canonical reference; no chapter below introduces a service not listed here.

### 0.1 Approved Services and Their Free Limits

| Service | Role | Free Tier Limit | What Happens If We Hit It |
|---|---|---|---|
| **Supabase Free** | Database, Auth, Storage, Realtime, Edge Functions | 500MB DB, 1GB Storage, 50K Edge Function invocations/month, 200 Realtime concurrent connections, 2 emails/hour (overridden by Resend) | Upgrade to Pro ($25/mo) — but for <250 users this should never happen |
| **Vercel Hobby** | Next.js web app hosting | 100GB bandwidth/month, 1 Cron job | More than enough for <250 users |
| **Firebase Spark** | Flutter web hosting (`app.psgmx.tech`), FCM push notifications | 1GB hosting storage, 10GB/month bandwidth, FCM free forever | More than enough |
| **GitHub Actions** | Android APK builds, all scheduled jobs (replaces pg_cron) | 2,000 minutes/month (private repo) or unlimited (public repo) | Use public repo or keep workflows efficient |
| **GitHub Releases** | Android APK distribution | Free forever | N/A |
| **OpenRouter (free models only)** | All AI inference | Rate-limited per model, see Section 0.2 | Fallback chain: if first model fails, try next free model, then show pre-written tip |
| **Piston API** | Code execution sandbox for CodeBox | Free public API at `emkc.org/api/v2/piston` — supports 20+ languages | Sufficient for <250 users; rate limits are per-IP not per-user |
| **Resend Free** | OTP email delivery (custom SMTP for Supabase Auth) | 3,000 emails/month, 100/day | More than enough for <250 users doing OTP login |
| **LeetCode Public API** | LeetCode stats sync | Free, no auth required | Respect their rate limits with caching |

### 0.2 Approved Free OpenRouter Models (Fallback Chain Order)

The backend maintains a fallback chain. It tries models in this order and uses the first one that responds:

| Priority | Model ID | Best For |
|---|---|---|
| 1st | `google/gemini-2.0-flash-exp:free` | General purpose: AI Senior Q&A, communication evaluation, moderation |
| 2nd | `meta-llama/llama-3.3-70b-instruct:free` | Strong reasoning fallback |
| 3rd | `deepseek/deepseek-r1:free` | Code evaluation, technical reasoning |
| 4th | `microsoft/phi-4:free` | Lightweight fallback when rate limits hit |
| Final fallback | Pre-written tip from a local tips bank | Shown when all models are unavailable — app never shows an error |

The backend selects the appropriate starting model for each task type:
- **Code evaluation (CodeBox):** Start at `deepseek/deepseek-r1:free`
- **AI Senior Q&A:** Start at `google/gemini-2.0-flash-exp:free`
- **Communication practice evaluation:** Start at `google/gemini-2.0-flash-exp:free`
- **Knowledge moderation pre-screen:** Start at `meta-llama/llama-3.3-70b-instruct:free`
- **FYP explanation coaching:** Start at `deepseek/deepseek-r1:free`

All free models have rate limits. The system queues and retries with exponential backoff. AI evaluation is non-blocking — the student always gets their test results immediately; the AI feedback arrives within seconds asynchronously.

### 0.3 What We Don't Use (and Why)

| Service | Why Not |
|---|---|
| pg_cron | Requires Supabase Pro. Replaced with GitHub Actions scheduled workflows. |
| Docker containers (self-hosted) | Requires a VPS. Replaced with Piston API. |
| Supabase Pro features | Not needed for <250 users on free tier |
| Play Store | No budget, no intent. GitHub Releases + sideloading only. |
| Any paid OpenRouter model | Budget constraint. Free models are sufficient for our scale. |
| Video recording for communication practice | Would exhaust 1GB Supabase Storage quickly. Audio only (MP3, 2-minute max ≈ 2MB per recording). |

### 0.4 Supabase Free Tier: The Inactivity Pause Problem

Supabase Free projects pause after 1 week of inactivity (no database queries). This would be a problem during semester breaks. Solution: a GitHub Actions scheduled workflow runs every Sunday at 10:00 AM IST and makes a lightweight authenticated query to the Supabase database (e.g., `SELECT 1` via Edge Function ping endpoint). This keeps the project active indefinitely without any manual intervention.

---

## Chapter 1 — The World PSGMX Operates In

### 1.1 The Four-Year Loop

PSGMX lifecycle matches a human arc:

```
New Student joins MCA
        |
        v
[PSGMX onboards them — PR bulk import, the only entry point]
        |
        v
Foundation year: calibration -> daily habit -> evidence accumulates
        |
        v
Senior year: proof -> mock readiness -> FYP storytelling -> interview patterns
        |
        v
Graduation: batch is archived, journey is preserved, alumnus role begins
        |
        v
PR of that batch formally hands the baton to the incoming batch PR
        |
        v
Alumni: lightweight contributions, mentoring, knowledge review
        |
        v
Their knowledge helps the next batch -> loop continues
```

No step in this loop requires a student to manually click "I completed this task." The system knows because it has verified the evidence.

### 1.2 What PSGMX Is Not

PSGMX must never become:

- A placement-drive management system. NEO PAT owns drives, shortlists, and packages. PSGMX shows a single deep-link: *"Open NEO PAT for official drive details."*
- A surveillance tool. All readiness data is private by default and shared only with the student and faculty through explicit consent flows.
- A manual-record system. Every preparation claim is verified by the AI engine, a backend automated check, or a faculty-confirmed milestone. Humans do not press "mark complete" buttons; evidence does.

### 1.3 The Two Surfaces

| Surface | URL | Technology | Primary Use |
|---|---|---|---|
| Mobile App | `app.psgmx.tech` | Flutter + Firebase Spark | Daily companion, quick practice, push notifications |
| Landing + Web App | `psgmx.tech` | Next.js + Vercel Hobby | Deep work: exams, FYP, admin console, CodeBox, AI analysis |

Android builds are released as signed APKs through **GitHub Releases** on the project repository. There is no Play Store distribution. The `psgmx.tech/download` page always links to the latest release.

### 1.4 The AI Layer — OpenRouter (Free Models Only)

All AI capabilities in PSGMX route through **OpenRouter** using only free-tier models (see Section 0.2). OpenRouter API keys are stored server-side only — never in the Flutter app or Next.js client bundle.

The system is designed so that AI failure is graceful. If all models are rate-limited, the student still completes their task and sees a pre-written fallback tip. AI is an enhancement layer, not a dependency.

---

## Chapter 2 — Roles and the Power Each One Holds

Every person in PSGMX has one logical identity. Roles are capability layers attached to the same profile. A PR is still a student who has a second workspace. A Team Leader is still a student who sees their squad participation. A faculty member can review knowledge and mentor; they cannot see another student's private score without a consent flow.

### Role Hierarchy (enforced in RLS + RPC + API + UI)

```
governance_admin (HOD / authorised governance holder)
    └── faculty (department mentor, knowledge moderator, assessment author)
            └── placement_readiness_representative (PR — student admin, batch-scoped)
                    └── coordinator (student — scheduling, quest publishing)
                            └── team_leader (student — squad participation marking)
                                    └── student (active junior or senior)
                                            └── alumni (graduated, lightweight)
```

**Rule zero:** hiding a button is never access control. Every capability is enforced at four layers: UI navigation gate, API authorization middleware, Supabase RPC permission check, and PostgreSQL Row-Level Security policy. A curl request with a student JWT must fail on any PR-only endpoint, even if the UI never shows that button.

---

## Chapter 3 — The Onboarding Story (How Students Arrive)

### 3.1 The PR Bulk Import — The Only Entry Point for Students

A new MCA batch does not self-register on PSGMX. There is no public signup form for students. The story begins in late July. The PR opens the PSGMX web console at `psgmx.tech/placement-rep/members`, downloads the **Import Template** CSV:

| Column | Required | Notes |
|---|---|---|
| `register_number` | Yes | Unique identifier, immutable after import |
| `full_name` | Yes | Display name |
| `personal_email` | Yes | OTP delivery until college mail activates |
| `college_email` | Auto-derived | System derives from rollnumber@psgtech.ac.in |
| `batch_year` | Yes | e.g., 2026 |
| `stage` | Auto-set | junior for new batch |
| `phone` | Optional | SMS fallback |
| `github_username` | Optional | Pre-linked GitHub integration |
| `leetcode_username` | Optional | Pre-linked LeetCode integration |

The PR uploads the filled CSV. Before committing a single row, the system:

1. **Parses and validates** every row — register number format, email uniqueness across entire database, name not empty.
2. **Detects conflicts** — highlights any register number or email already in the system with a different name.
3. **Preview screen** — PR sees three columns: Will Create (green), Will Update (amber), Will Reject (red). No row commits without PR reviewing.
4. **PR confirms** — the system commits all valid rows idempotently in a single transaction via a Supabase Edge Function (bypassing RLS with service role, audited).
5. Each new student receives a **welcome email** via Resend — not a generic registered email, but one explaining PSGMX as a preparation companion with the APK download link and a QR code.

> **Critical:** The PR cannot edit a student's register number after import. Only a governance administrator can resolve corrections after an audit-logged identity review.

### 3.2 Student First Login

The student opens `app.psgmx.tech` (installed via the GitHub Release APK link from the welcome email) or `psgmx.tech` on a browser.

**Step 1 — Email entry.** They type their personal email. If not in the roster: *"We couldn't find an account for this email. Check your welcome email or contact your batch PR."* No roster status is exposed to outsiders.

**Step 2 — OTP.** Supabase Auth sends a 6-digit OTP via Resend (custom SMTP). Three wrong attempts lock for 15 minutes with the exact unlock time shown.

**Step 3 — Identity confirmation.** They see name, register number, batch, and stage. They can flag a correction — this creates a support case. They cannot self-edit register numbers.

**Step 4 — The 5-minute calibration.**
- Target role family: Product engineering / Service engineering / Research / I don't know yet
- Confidence rating in Aptitude, Coding, Core CS, Communication (3-point scale)
- LeetCode username (optional, can skip and do later)
- Days available to practice per week and preferred reminder window
- A short 5-question adaptive sample across all dimensions (calibration only, not graded)

**Step 5 — Starting plan reveal.** Low-confidence first plan with one strength, one focus area, and a 7-day starter journey.

**Step 6 — First success in 5 minutes.** One starter mission completed before closing the app. First XP awarded. App opens to Today.

---

## Chapter 4 — The Daily Life of a Student

### 4.1 Today — The Only Screen That Matters Every Morning

A student opens the app and sees a single coherent story — not a dashboard of widgets:

> *"Good morning, Vikram. Your coding consistency is your strongest signal right now — you've solved 12 LeetCode problems this month. But your Core CS evidence is 18 days old and starting to fade. Today's best action: a 7-minute DBMS sprint. It will refresh that dimension and bring you 2/3 of the way through this week's mission."*

One primary card — the recommended action. Below it: urgent items only. No infinite scroll. No feed. No 15 competing cards.

Priority order for Today:
1. Account or safety issue requiring action
2. Timed assessment starting in less than 2 hours
3. In-progress action that can be resumed (saved CodeBox attempt, paused quiz)
4. Personal best-next mission (weakest fresh readiness dimension)
5. Daily Five (the daily habit)
6. Important batch announcement from PR or faculty
7. Optional: squad update, alumni resource, lineage ping

### 4.2 Train — Where Growth Actually Happens

**Daily Five:** Five questions chosen by the question selection engine by mastery gaps, spaced repetition schedules, curriculum coverage, and recent error patterns. The student answers, submits, sees explanations. Streak and XP update from the server — the client never self-reports completion. Opening Daily Five twice awards XP only once (idempotent).

**Adaptive Skill Sprint:** Student picks a domain (or accepts the system recommendation) and a duration (5, 10, or 20 minutes). Questions escalate from recall to application. Session ends with a mastery movement report. Wrong concepts enter a revisit queue automatically.

---

### 4.3 CodeBox — The Verified Coding Environment

When a coding task is assigned, the student does not see a "Submit" button next to a PDF. They see an embedded code editor — a **CodeBox** — built on Monaco Editor (same engine as VS Code), rendered inside the web app at `psgmx.tech` and accessible via deep link from the Flutter app.

**The CodeBox experience:**

1. Problem statement in the left panel — description, input/output format, constraints, examples.
2. Code editor on the right. Language defaults to student preference (Python, Java, C++). Syntax highlighting, auto-indent, Monaco IntelliSense.
3. Student clicks **Run** to test against visible sample cases.

   > **How Run works (free tier):** The Next.js backend calls the **Piston API** at `https://emkc.org/api/v2/piston/execute` with the student's code, language, and sample input. Response arrives in under 3 seconds. The student sees their output vs. expected output for visible cases only. No Docker containers. No VPS. Piston is a free public code execution API.

4. Student clicks **Submit**. The backend (Supabase Edge Function):
   - Captures the code snapshot with timestamp and student identity
   - Calls Piston API with each hidden test case (run sequentially, up to 10 cases)
   - Collects all test results: passed/failed/timeout per case
   - Sends code + problem statement + test results to OpenRouter (starting with `deepseek/deepseek-r1:free`): *"Evaluate this solution for correctness, time complexity, edge case handling, and code quality. Return JSON: { passed_tests, total_tests, time_complexity, space_complexity, issues[], quality_score (0-10), brief_feedback }"*
   - AI response + test results together = verification evidence
5. A task is **Verified Complete** only when: minimum test cases pass (default 7/10, configurable per task) AND AI quality score meets the floor (default 5/10 minimum). Submitting broken code does not mark the task complete.
6. Student sees: *"7/10 test cases passed. Your approach handles the main case correctly but fails on empty input (test case 3). Time complexity: O(n²) — there is a more efficient approach. Hint: think about using a hash map."*
7. Student can fix and resubmit (up to the attempt limit set by the task author).
8. Verification result updates the Coding dimension readiness score automatically.

> **There is no manual completion button for coding tasks.** Piston runs the code, the AI evaluates, and the system records the outcome.

**CodeBox also handles:**
- **SQL tasks:** Piston API supports PostgreSQL queries against a problem-defined schema (passed as setup code before the student's query).
- **System design tasks (text-based):** student writes a design document, AI evaluates against a faculty-authored rubric.
- **Debugging tasks:** student receives broken code and must fix it. Same Piston + AI pipeline.

**Piston API safety notes:**
- Piston runs in an isolated, resource-limited environment by design
- Student code never runs on our servers
- All Piston calls go through the Supabase Edge Function (server-side) — the student never calls Piston directly
- Piston has execution timeouts per language (usually 3 seconds). Tasks with complex algorithms must be designed to complete within this limit.

### 4.4 Communication and Interview Practice

The student records a **2-minute audio clip** (MP3) for a prompt (e.g., *"Tell me about a challenge you faced in a team project"*).

> **Audio only (not video):** Supabase Storage free tier is 1GB. A 2-minute MP3 ≈ 2MB. Even if every student records 100 clips, that is 250 × 100 × 2MB = 50GB — which exceeds free tier. So we enforce: maximum 2-minute clip, MP3 only, maximum 10 saved clips per student (oldest is deleted when the 11th is saved). This keeps storage per student under 20MB, total under 5GB. Faculty-reviewed clips are never deleted until the student deletes them.

The audio is processed by the backend:
1. Upload to Supabase Storage (student's own bucket, RLS-protected)
2. Edge Function downloads the file and sends it to OpenRouter with a transcription prompt: *"This is an audio recording. Please evaluate the spoken response based on: clarity of speech, answer structure (does it have beginning, middle, end), use of filler words (um, uh, like), and relevance to the prompt. Return JSON: { clarity_score (0-10), structure_score (0-10), filler_word_count, relevance_score (0-10), brief_feedback, suggested_improvement }."*

   > **Note:** Free OpenRouter models do not natively process audio files. The workflow uses a speech-to-text step first: the backend sends the MP3 to a free speech-to-text service (OpenAI Whisper via a free Hugging Face inference endpoint) to get a transcript, then sends the transcript to OpenRouter for evaluation. If the free STT endpoint is unavailable, the student is told: *"AI evaluation is temporarily unavailable. Your recording is saved. Try evaluating in a few minutes."*

3. AI returns score and feedback. Student sees it in their communication practice timeline.
4. Human-reviewed responses (by faculty or alumni) receive higher confidence weight in the readiness score than AI-only evaluations.

### 4.5 LeetCode Integration

Student connects LeetCode username (never password). Backend syncs public stats on a schedule (via GitHub Actions — see Section 11.3): problems solved by difficulty, recent submissions, acceptance rate, streak. Results are cached in the database for 6 hours. This feeds the Coding readiness dimension as external, independently verified evidence.

### 4.6 GitHub Contribution Integration (Planned — Phase 5)

> **Designed, not in first release.**

Student generates a GitHub Personal Access Token with `read:user` and `repo` (public only) scopes and pastes it into Settings > Connected Services. Backend stores it encrypted at rest. GitHub Actions scheduled job polls the GitHub API for: commits per week, streak, repository count, language distribution.

This data appears in: Progress > Coding dimension as additional evidence, and a GitHub Contribution heatmap on their profile.

Student can revoke the token at any time from Settings > Connected Services — deleted from the database immediately.

---

## Chapter 5 — The Readiness Engine

### 5.1 What the Score Means

Every student has a Readiness Score from 0 to 100. It never appears without explanation. The student always sees:
- What evidence feeds this number
- How fresh that evidence is
- What one action would move it most meaningfully this week
- "This changed because..." history for the last 3 events

The score is **private by default**. Faculty see it with student awareness. PR sees only batch-level aggregate trends. HOD sees programme-level trends. No peer sees another peer's raw score.

### 5.2 The Six Dimensions

| Dimension | Weight | Primary Evidence Sources |
|---|---|---|
| Aptitude and Reasoning | 15% | Daily Five (aptitude), adaptive sprints, mock assessments |
| Coding and Problem Solving | 20% | CodeBox verified tasks, LeetCode stats, coding mock assessments, GitHub contributions |
| Core Computer Science | 15% | Daily Five (CS topics), adaptive sprints, Core CS assessments |
| Communication and Interview | 15% | Audio practice (AI-evaluated), mock interviews, human-reviewed responses |
| Assessment Performance | 20% | Faculty-published mock exams, normalised across attempts |
| Portfolio and Project Proof | 15% | FYP milestones confirmed by faculty, GitHub repo quality, demo recordings |

### 5.3 How Evidence Ages — The Freshness Job

The Freshness Job runs every Sunday via GitHub Actions (not pg_cron — free tier). For each student, for each dimension:

```
evidence_age < 30 days   -> confidence = high
evidence_age 30-60 days  -> confidence = medium (score penalty: -10%)
evidence_age > 60 days   -> confidence = low   (score penalty: -25%)
```

The GitHub Actions workflow calls a Supabase Edge Function endpoint (`/functions/v1/freshness-daemon`) which runs the computation in the database. This is equivalent to pg_cron but uses free GitHub Actions instead of paid Supabase Pro.

---

## Chapter 6 — The PR World (Placement Readiness Representative)

### 6.1 Who the PR Is

The PR is a student — a trusted, capable, batch-scoped administrator appointed by the HOD or faculty. Their web console at `psgmx.tech/placement-rep` is where 90% of their administration happens. On mobile, a quick-action panel handles urgent items only.

### 6.2 The Batch Handover Ceremony

This is the most important lifecycle event in PSGMX's operational calendar.

**The scenario:** It is late May. The `25MX` batch is graduating. Their PR, Keerthana, has run the programme for two years. The incoming batch `27MX` is about to join. Their PR, Arjun, has been selected.

**Step 1 — HOD initiates the Handover Workflow** from `psgmx.tech/faculty/batch-management`. They nominate outgoing PR, incoming PR, and formal handover date.

**Step 2 — System generates a Handover Checklist** visible to both PRs:
- All open participation records closed
- All pending quest completions reviewed
- Question bank access transferred to incoming PR
- Squad structure archived (preserved for history)
- Active announcements transferred or expired
- Support cases resolved or transferred to faculty
- Final batch health report generated

**Step 3 — Keerthana reviews and signs off** each item. Incomplete items are flagged and routed to faculty resolution before sign-off can proceed.

**Step 4 — System executes the Batch Graduation Transition** (via Supabase Edge Function called by the HOD's confirmation click):
- `25MX` batch lifecycle status: `active_senior` → `graduated`
- All `25MX` students' PR, coordinator, and team_leader capabilities: automatically revoked
- Keerthana's PR capability removed; her student identity remains
- Arjun's PR capability provisioned for `27MX` batch
- Arjun receives PR Activation briefing in his console

**Step 5 — Alumni transition for 25MX:**
- Each `25MX` student gets a personalised graduation email via Resend
- Their Today dashboard becomes Journey Archive — all evidence, streaks, FYP, assessment history preserved
- One prompt: *"Welcome to the PSGMX alumni network. Would you like to receive mentoring requests from your juniors?"*

> **This entire handover is managed by the system.** HOD clicks "Initiate Handover." Checklist tracks progress. Transition runs idempotently on confirmation. No manual database edits.

### 6.3 Day-to-Day PR Operations

**Quest Studio:** PR creates coding, aptitude, core CS, or communication tasks. Every coding task must include:
- Problem statement (Markdown with LaTeX support)
- Input/output specification
- At least 5 hidden test cases (stored in Supabase Storage, never sent to the client)
- Piston execution configuration: language, time limit (max 3 seconds per Piston's constraint)
- Minimum pass rate for verification (default: 7/10 tests + AI score 5/10)
- Allowed languages
- Due date window
- Target batch/squad

**Question Bank:** Multiple-choice and subjective questions for Daily Five and mock exams. Imported via CSV or written inline. Duplicate detection uses pgvector embedding similarity. Faculty must approve before entering the live pool.

**Preparation Calendar:** Coding lab, aptitude sprint, core CS clinic, mock interview, group discussion, FYP review, alumni talk. Each session: facilitator, time slot, location/link, target batch/squad, expected outcome. Students get FCM push notifications.

**Readiness Pulse:** Batch-level aggregate dashboard — no individual student names visible to PR. Flagged students (decline signals) go to faculty for intervention.

### 6.4 PR Cannot Do These Things

- See individual student private readiness scores (only aggregate trends)
- Create faculty or HOD accounts
- Modify NEO PAT placement data
- Override graduation or batch transitions without HOD/faculty approval
- Delete student historical evidence or assessment records

---

## Chapter 7 — The Faculty World

### 7.1 The Faculty Dashboard — A Queue, Not a Report

When a faculty member opens `psgmx.tech/faculty`, they see an **action queue** with every item having an owner and a due date. Metrics without an owner are removed.

### 7.2 The Mock Assessment Studio

Faculty are the sole authors of mock assessments at `psgmx.tech/faculty/assessment-studio`:

1. Faculty selects a domain blueprint, difficulty distribution, total marks.
2. System suggests questions from the approved Question Bank.
3. Faculty configures integrity level: **Relaxed** (open notes), **Proctored** (timed, tab-switching detection via Page Visibility API — web only), or **Structured** (timed, one question at a time, no back-navigation).
4. After the window closes: system auto-grades objective questions. Subjective answers go to OpenRouter (free model fallback chain) with a faculty-authored rubric for first-pass scoring. Faculty reviews flagged borderline answers.
5. **Misconception analysis:** *"42% of students who attempted the transaction isolation question selected Read Uncommitted incorrectly. Recommended: a Core CS clinic on ACID properties."*
6. Faculty publishes a remediation track — a custom adaptive sprint. Appears in affected students' Today.

### 7.3 Knowledge Moderation

Every Knowledge Brain item goes through faculty review before publication or use as AI Senior grounding context.

Review flow:
1. Submission arrives. OpenRouter (free model) pre-screens: offensive content, privacy violations, factual errors.
2. Faculty reviews: source claims, accuracy, privacy, relevance.
3. Three outcomes: **Approve** (optional expiry), **Request Changes**, or **Reject**.
4. Approved content gets a vector embedding via `generate-embedding` Edge Function using the Supabase `gte-small` model (free, built-in) and becomes searchable in Knowledge Brain and AI Senior.
5. Content older than 18 months is flagged for re-review automatically (GitHub Actions weekly job).

### 7.4 The Recovery Hub

When evidence suggests a student is struggling, the system creates a Recovery Case suggestion routed to assigned faculty. Automation suggests; faculty decides.

Faculty sets goal, assigns actions, sets review date. The student's Today shows a support message — not a punishment label. Faculty reviews on the set date, records outcome, closes or extends. All history is preserved privately.

---

## Chapter 8 — The HOD World (Governance)

### 8.1 Governance Dashboard

The HOD's view at `psgmx.tech/faculty/governance` (capability-gated for any `governance_admin` user) shows a health dashboard:
- Batch lifecycle status and next handover date
- Onboarding coverage percentage
- Identity health (unresolved duplicate conflicts)
- Knowledge Brain health (review queue depth)
- System health (GitHub Actions job status, OpenRouter availability, LeetCode sync status)
- Privacy-safe recovery state (open recovery cases by duration — no student names)

### 8.2 Batch Lifecycle Management

Standard transitions — junior to senior at start of second year, active_senior to graduated at graduation — are **automatic and idempotent**, triggered by GitHub Actions on the configured dates. The HOD intervenes only for exceptions.

### 8.3 Faculty and Governance Access Management

The HOD provisions and manages faculty accounts. `governance_admin` capability is separate from the faculty role. Former HODs retain governance access as "Faculty (Governance)." The current HOD is one person.

---

## Chapter 9 — The Alumni World

### 9.1 The Re-Entry Story

Alumni open `psgmx.tech/join-alumni`, enter register number and email, verify via OTP (Resend). System reactivates their profile with the alumni role and shows their Journey Archive — immutable. They add career milestones and set mentoring availability.

### 9.2 What Alumni Actually Do

Alumni see specific, time-bounded prompts — not generic banners:
- A specific junior's question that their contribution answers
- A gap in the Knowledge Brain that matches their experience
- A lineage connection request with specific context

Every contribution goes through the faculty review pipeline before going live.

---

## Chapter 10 — Team Leader and Coordinator

### 10.1 Team Leader

A Team Leader's additional capability is narrow: they can view their squad's session participation status and mark attendance during or after a preparation session. They cannot see readiness scores, CodeBox submissions, or assessment answers.

### 10.2 Coordinator

Broader operational permissions: scheduling preparation sessions, publishing quests (pending PR/faculty review if configured), and sending approved announcement templates. Permissions are defined at grant time — specific permission bits, not just the role label.

---

## Chapter 11 — The Technical Architecture

### 11.1 System Architecture (Free Tier Optimised)

```
psgmx.tech (Next.js, Vercel Hobby)
app.psgmx.tech (Flutter, Firebase Spark Hosting)
        |
        v
Supabase Free Project
  |-- PostgreSQL + pgvector (500MB free)
  |-- Row-Level Security (RLS) on every table
  |-- Supabase Auth (OTP via Resend custom SMTP)
  |-- Edge Functions (Deno, 50K invocations/month free)
  |-- Supabase Storage (1GB free)
  |-- Supabase Realtime (200 concurrent connections free)
        |
        v
External Services (all free)
  |-- Piston API (emkc.org) — code execution for CodeBox
  |-- OpenRouter (free models) — all AI inference
  |-- Resend (free tier) — OTP and notification emails
  |-- Firebase Cloud Messaging — push notifications (free forever)
  |-- LeetCode Public API — stats sync (no auth required)
  |-- GitHub Actions — all scheduled jobs (replaces pg_cron)
  |-- GitHub Releases — Android APK distribution
```

### 11.2 CodeBox Code Execution via Piston API

```
Student submits code (via web app)
        |
        v
Next.js API route receives code + language + questId
        |
        v
Supabase Edge Function (compute-codebox-result):
  |-- Fetch hidden test suite for questId from Supabase Storage
  |       (never sent to client, fetched server-side via service role)
  |
  |-- For each test case (sequential, max 10):
  |     POST https://emkc.org/api/v2/piston/execute
  |     Body: { language, version, files: [{ content: setup + student_code }], stdin: test_input }
  |     Response: { run: { stdout, stderr, code, signal } }
  |     Compare stdout to expected_output
  |
  |-- Compile test results: { passed: N, total: 10, case_results: [...] }
  |
  |-- Call OpenRouter (deepseek/deepseek-r1:free) with:
  |     code + problem + test_results -> evaluation JSON
  |     (fallback chain if rate-limited)
  |
  |-- Compute: is_verified = (passed/total >= min_pass_rate)
  |                      AND (ai_quality_score >= min_quality_floor)
  |
  v
Store in code_submissions:
  student_id, quest_id, attempt, submitted_at,
  code_encrypted (AES-256), test_results_json,
  ai_evaluation_json, is_verified, verification_reason

Update evidence_events -> triggers readiness_score recomputation
```

**Piston API language support for CodeBox tasks:**
- Python 3.10, Java 17, C++ (GCC), JavaScript (Node.js), Go, Rust, C, SQL

**Piston constraints to design tasks around:**
- Max execution time: 3 seconds per test case
- Max memory: 256MB
- Network access: disabled (no internet calls from student code)
- Filesystem: ephemeral, read-only

### 11.3 Scheduled Jobs via GitHub Actions (replaces pg_cron)

| Job Name | Schedule | What It Does |
|---|---|---|
| `freshness-daemon` | Every Sunday 10:00 AM IST | Calls `/functions/v1/freshness-daemon` — applies evidence age penalties to all student readiness scores |
| `leetcode-sync` | Every 6 hours | Calls `/functions/v1/sync-leetcode` — refreshes LeetCode stats for all connected users |
| `knowledge-review-reminder` | Every Monday 9:00 AM IST | Flags knowledge items >18 months old for re-review; notifies faculty |
| `supabase-keepalive` | Every Sunday 8:00 AM IST | `SELECT 1` via Supabase REST API — prevents free tier inactivity pause |
| `batch-lifecycle-check` | Every day at midnight IST | Checks if any batch should transition stage; runs idempotently |
| `apk-build-and-release` | On push to `release/*` | `flutter build apk --release` + sign + GitHub Release |

All scheduled jobs are implemented as GitHub Actions workflows (`.github/workflows/`). Each workflow calls a corresponding Supabase Edge Function endpoint with a secret `CRON_SECRET` header for authentication.

### 11.4 Core Database Tables

```sql
-- Identity
profiles          (id, register_number, full_name, stage, batch_year, created_at)
email_aliases     (profile_id, email, type, is_primary)
role_assignments  (profile_id, role, batch_scope, capabilities[], granted_by, granted_at, revoked_at)

-- Readiness
readiness_scores  (id, profile_id, dimension, score, confidence, evidence_date, algorithm_version)
evidence_events   (id, profile_id, dimension, source_type, source_id, weight, recorded_at)

-- Coding
quests            (id, title, type, problem_md, test_suite_path, min_pass_rate, min_ai_quality,
                   allowed_languages, time_limit_seconds, due_at, target_batch, target_squads)
code_submissions  (id, quest_id, profile_id, attempt, code_encrypted, test_results_json,
                   ai_evaluation_json, is_verified, verification_reason, submitted_at)

-- Assessment
assessments         (id, faculty_id, title, blueprint, integrity_level, window_start, window_end, ...)
assessment_attempts (id, assessment_id, profile_id, started_at, submitted_at, score, ai_analysis, ...)

-- Batch lifecycle
batch_lifecycles  (id, batch_year, stage, transitioned_at, transitioned_by)
batch_handovers   (id, from_pr_id, to_pr_id, from_batch, to_batch, initiated_by, completed_at, checklist_state)

-- Knowledge
knowledge_items   (id, author_id, type, content_md, status, approved_by, embedding vector(384),
                   expires_at, review_due_at, ...)

-- Communication practice
communication_attempts (id, profile_id, prompt_id, audio_path, transcript, ai_scores_json,
                        faculty_reviewed, faculty_score, created_at)
```

Every table has `created_at`, `updated_at`, and an audit trigger writing to an append-only `audit_log` table. The `audit_log` is INSERT-only — no row can ever be deleted.

### 11.5 Deployment Architecture

| Component | Platform | Free Tier Used |
|---|---|---|
| Web App (psgmx.tech) | Vercel Hobby | 100GB bandwidth/month |
| Mobile App (app.psgmx.tech) | Firebase Hosting Spark | 10GB/month bandwidth |
| Android APK | GitHub Releases | Free forever |
| Database | Supabase Free | 500MB PostgreSQL |
| Auth + OTP | Supabase Auth + Resend | Supabase handles auth; Resend sends emails (3K/month free) |
| Storage | Supabase Storage | 1GB free |
| Realtime | Supabase Realtime | 200 concurrent connections free |
| Edge Functions | Supabase Edge Functions | 50K invocations/month free |
| Scheduled Jobs | GitHub Actions | 2,000 min/month (private) or unlimited (public) |
| Code Execution | Piston API (emkc.org) | Free public API |
| AI Inference | OpenRouter (free models) | Rate-limited, fallback chain |
| Push Notifications | Firebase Cloud Messaging | Free forever |
| Vector Embeddings | Supabase gte-small (built-in) | Free on all Supabase plans |
| Monitoring | Supabase Dashboard | Free |

### 11.6 Android Release via GitHub

GitHub Actions workflow (`.github/workflows/android-release.yml`) triggers on push to `release/*` branch:
1. `flutter build apk --release`
2. Sign with project keystore (stored as GitHub Secret: `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`)
3. Create GitHub Release with signed APK as asset and auto-generated changelog
4. `psgmx.tech/download` always links to the latest GitHub Release APK

The app checks for new versions on launch by querying `/api/version` (Next.js API route that reads the latest GitHub Release tag via GitHub API). Mandatory update screen if below minimum version.

---

## Chapter 12 — The AI Senior (Knowledge Q&A)

### 12.1 How AI Senior Works

Student asks: *"What is the best way to prepare for a system design interview as an MCA student?"*

The backend:
1. Embeds the query using Supabase's built-in `gte-small` embedding model (free, no external API needed).
2. Does a pgvector similarity search against all approved Knowledge Brain content (similarity threshold: 0.75, top 5 results).
3. Sends top 5 matching knowledge chunks + student readiness profile summary to OpenRouter (free model fallback chain).
4. System prompt: *"You are AI Senior, a preparation companion for MCA students at PSG Tech. Answer using the provided approved knowledge as your primary source. Always cite which knowledge item you are drawing from. If no approved knowledge directly answers the question, say so and provide general guidance while noting its lower confidence. Never fabricate faculty names, company names as official partners, or official drive details. If the question is about an active drive or placement portal, respond: For official drive details, please check NEO PAT."*
5. Response streams back with citations — each citation links to the Knowledge Brain item.
6. Query patterns stored anonymously for faculty insight.

### 12.2 What AI Senior Cannot Do

- Reveal a student's private readiness score to another student
- Access NEO PAT data
- Confirm eligibility for any official drive
- Mark any task as complete on a student's behalf

---

## Chapter 13 — Notifications and Inbox

### 13.1 Notification Delivery

Push notifications use **Firebase Cloud Messaging (FCM)** — free forever on Firebase Spark plan. The Supabase Edge Function calls the FCM HTTP v1 API with the device token (stored in a `device_tokens` table, one row per user-device pair).

For web (Next.js), browser push notifications use the Web Push API with FCM as the delivery mechanism.

### 13.2 Email Notifications

All transactional emails (OTP, welcome, weekly digest, graduation ceremony message, knowledge review reminders) use **Resend** free tier (3,000/month, 100/day). This is more than enough for <250 users.

### 13.3 Weekly Digest

Every Sunday evening via the GitHub Actions `knowledge-review-reminder` job, a personalised digest email is sent via Resend to each active student: what they completed this week, which skill moved, what evidence is stale, one next focus, one new Knowledge Brain resource.

### 13.4 Delivery Rules

- FCM push notifications respect user-configured quiet hours (default: no pushes 10 PM to 7 AM)
- Low-priority notifications are bundled into a single push per day
- Every notification has an expiry
- Read state syncs across mobile and web via Supabase Realtime
- Lock screen previews never show readiness scores or recovery case details

---

## Chapter 14 — Squads, Lineage, and Community

### 14.1 Preparation Squads

Groups of 6-8 students created by the PR. Automatic balancing by current readiness band creates heterogeneous squads. Each squad has: a Team Leader (optional), a weekly squad objective, and a squad feed (completion updates, not scores). Competition is by completion band, not raw readiness score.

### 14.2 Lineage

Connects current students to alumni whose register suffix matches theirs. Students can send connection requests with a specific topic and question. Alumni can accept, decline, or redirect. Topic-based matching available as opt-in for both sides.

### 14.3 Community Board

Moderated board for: project collaboration, open source opportunities, alumni-hosted learning events, career information sessions (not official drives), mentoring circles. Every post is moderated. Posts resembling official drive announcements are removed.

---

## Chapter 15 — FYP and Portfolio

### 15.1 FYP as Evidence

Student creates their FYP record: title, problem statement, domain, team members, guide faculty, linked GitHub repository (optional), target outcome. System proposes milestones. Each milestone is logged by the student, reviewed by faculty guide, confirmed or sent back. Faculty confirmation creates a verified Portfolio evidence event.

### 15.2 FYP Explanation Practice

Student records a 2-minute audio clip explaining their project (same audio-only constraint as communication practice). AI evaluates: problem clarity, technical explanation, quantified results. Student can re-record; improvement trend is shown.

---

## Chapter 16 — Privacy, Ethics, and Guardrails

### 16.1 Privacy Model

| Data | Who Sees It |
|---|---|
| Raw readiness score | Student + assigned faculty + HOD |
| Readiness dimension breakdown | Student + faculty (requires opening student profile) |
| CodeBox submissions + code | Student + faculty (recovery cases only) |
| Communication audio recordings | Student + faculty (mentoring review only) |
| Recovery case notes | Assigned faculty + HOD only |
| Assessment answers | Student (after release) + faculty |
| Aggregate batch trends | PR (no individual names) + faculty + HOD |
| Alumni career profile | Alumni-controlled |

### 16.2 Ethical Engagement Rules

PSGMX must not:
- Send push notifications after 10 PM or before 7 AM
- Show a student's rank to peers without the student opting in
- Use shame language in any automated message
- Create fake urgency countdowns
- Reward opening the app without doing something meaningful
- Penalise a student for not using the app during exam season

### 16.3 Anti-Gaming

The backend is the source of truth for all XP and evidence:
- Every submission has a server-side timestamp
- Duplicate submissions are rejected (idempotent submission IDs)
- Anomaly detection: a student submitting 50 Daily Five sessions in one day is flagged for review
- XP from contributions requires human approval
- High-impact XP events are audited automatically

---

## Chapter 17 — North Star Metric and Success

### 17.1 The One Number That Matters

**Weekly Prepared Students:** the percentage of active students who complete at least two meaningful preparation actions in different readiness dimensions during a given week.

Target: 60% in the first semester, 75% by end of first year.

### 17.2 Supporting Metrics

| Metric | Target |
|---|---|
| First useful action within 24 hours of onboarding | > 85% |
| 4-week retained preparation habit | > 60% |
| CodeBox verified completion rate | > 50% of assigned tasks |
| Fresh evidence in 4+ dimensions per student | > 50% of active students |
| Recovery case closure within 30 days | > 70% |
| AI Senior answers with 1+ approved citation | > 80% |
| OTP delivery success rate | > 99% |
| Crash-free sessions | > 99.5% |

### 17.3 Guardrails

- Notification complaint rate > 5% in any week: pause non-essential notifications
- Late-night app opens > 15% of daily sessions: investigate streak pressure
- OpenRouter error rate > 5%: verify fallback chain is working
- Piston API unavailable: disable CodeBox task submission; show *"Code evaluation is temporarily offline. Your code is saved. Try again in a few minutes."* — student work is never lost
- Supabase keepalive missed 2 weeks: alert via GitHub Actions failure notification

---

## Chapter 18 — Implementation Phases

### Phase 1 — Foundation (Weeks 1-4)

- Review and update Supabase schema (align existing 21 migrations with this PRD's data model)
- OTP authentication via Supabase Auth + Resend custom SMTP
- PR bulk import (CSV, preview, commit)
- Flutter app: login, OTP, identity confirmation, calibration, Today (initial version)
- Next.js: login, PR console (members, import), faculty dashboard (stub)
- FCM push notification setup
- GitHub Actions: Flutter APK build + release + version endpoint
- GitHub Actions: supabase-keepalive workflow
- `psgmx.tech/download` with latest release link

### Phase 2 — Daily Companion (Weeks 5-10)

- Daily Five (question engine, mastery tracking, XP, streak)
- Adaptive Skill Sprint
- Readiness Engine v1 (6 dimensions, freshness via GitHub Actions)
- LeetCode integration (username link, GitHub Actions sync)
- Unified Inbox (FCM + in-app, read state via Supabase Realtime, expiry)
- Weekly digest via Resend
- Squad creation and Team Leader participation marking

### Phase 3 — CodeBox and Assessment (Weeks 11-18)

- CodeBox editor (Monaco, language support, Run via Piston API for visible cases)
- Quest Studio (PR creates coding tasks with hidden test suites stored in Supabase Storage)
- Quest verification pipeline (Piston API hidden tests + OpenRouter AI = verified/not verified)
- Mock Assessment Studio (faculty authors, structured/proctored modes)
- Assessment attempt pipeline (auto-grade + OpenRouter AI analysis + misconception report)
- Remediation tracks (faculty publishes after assessment)

### Phase 4 — AI Senior, Knowledge Brain, Community (Weeks 19-26)

- Knowledge Brain submission flow (author, OpenRouter pre-screen, faculty review, approved)
- Vector embedding of approved knowledge (Supabase gte-small built-in)
- AI Senior (RAG-based Q&A with OpenRouter free models, citations, streamed response)
- Interview Pattern Library (replaces company-based placement log)
- Communication practice (audio recording + free STT + OpenRouter evaluation)
- FYP module (milestones, faculty confirmation, portfolio evidence)
- Alumni onboarding and contribution flow
- Lineage connections and mentoring requests
- Community Board (moderated)

### Phase 5 — Governance, Handover, and GitHub (Weeks 27-34)

- Batch Handover Workflow (checklist, automated transition, PR provisioning)
- HOD governance dashboard (batch lifecycle, faculty management, identity review)
- Recovery Hub (faculty creates, student sees support, review cycle)
- GitHub contribution integration (personal token, contribution heatmap)
- Full audit log viewer (governance only)
- Feature rollout controls
- Full Readiness Engine v2 (all 6 dimensions, confidence, freshness, history)
- Analytics dashboards (faculty insight, PR readiness pulse, HOD governance)

---

## Chapter 19 — Capability Ownership Reference

| Capability | Student | TL | Coord | PR | Faculty | HOD |
|---|---|---|---|---|---|---|
| Manage own profile (except register number) | Yes | Yes | Yes | Yes | Yes | Yes |
| Connect LeetCode / GitHub | Yes | Yes | Yes | Yes | — | — |
| Submit CodeBox task | Yes | Yes | Yes | Yes | — | — |
| View own readiness score | Yes | Yes | Yes | Yes | — | — |
| View squad participation | — | Own squad | Assigned | Yes | Yes | Yes |
| Create quests / tasks | — | — | Review req. | Yes | Yes | — |
| Create mock assessments | — | — | — | — | Yes | Yes |
| Approve Knowledge Brain content | — | — | — | — | Yes | Yes |
| View student readiness detail | — | — | — | Aggregate only | Assigned | Yes |
| Create / close recovery cases | — | — | — | — | Yes | Yes |
| Import student roster | — | — | — | Yes | — | Yes |
| Grant student-level roles (TL, coord) | — | — | — | Yes | — | Yes |
| Grant faculty / governance access | — | — | — | No | — | Yes |
| Initiate batch handover | — | — | — | — | — | Yes |
| Override batch lifecycle | — | — | — | — | — | Yes |
| View audit log | — | — | — | PR-scope | — | Yes |
| Impersonate for support | — | — | — | — | — | Yes (time-bound) |

---

## Chapter 20 — Route Map

### Web Routes — psgmx.tech

| Route | Purpose | Auth |
|---|---|---|
| / | Public landing | Public |
| /download | Android APK download | Public |
| /login | OTP login for all roles | Public |
| /join-alumni | Alumni first-time registration + OTP | Public |
| /onboarding | First-session calibration wizard | Student (new) |
| /student | Student Overview (Today on web) | Student |
| /student/train | Adaptive sprint, communication practice | Student |
| /student/codebox/:questId | CodeBox task environment (Monaco + Piston) | Student |
| /student/exams | Mock assessments list | Student |
| /student/exam/:id | Assessment attempt | Student |
| /student/progress | Readiness Engine detail | Student |
| /student/ai-senior | AI Senior Q&A | Student |
| /student/knowledge-brain | Knowledge search + save | Student |
| /student/fyp | FYP module | Student |
| /student/lineage | Lineage + mentoring | Student |
| /student/squads | Squad view | Student |
| /student/inbox | Unified inbox | Student |
| /student/settings | Account, connected services, privacy | Student |
| /placement-rep | PR Command Center | PR |
| /placement-rep/members | Roster + import + access management | PR |
| /placement-rep/squads | Squad management | PR |
| /placement-rep/sessions | Preparation Calendar | PR |
| /placement-rep/quest-studio | Quest + CodeBox task authoring | PR/Coordinator |
| /placement-rep/question-bank | Question bank CRUD | PR/Faculty |
| /placement-rep/participation | Session participation + disputes | PR |
| /placement-rep/communication | Announcements | PR |
| /placement-rep/pulse | Readiness Pulse (aggregate only) | PR |
| /placement-rep/reports | Export + audit | PR |
| /faculty | Faculty action queue | Faculty |
| /faculty/assessment-studio | Mock assessment authoring | Faculty |
| /faculty/students | Student Explorer | Faculty |
| /faculty/recovery-hub | Recovery cases | Faculty |
| /faculty/knowledge-brain | Knowledge moderation | Faculty |
| /faculty/fyp-repository | FYP review | Faculty |
| /faculty/mentorship | Mentoring management | Faculty |
| /faculty/ai-insights | AI Senior demand analytics | Faculty |
| /faculty/governance | Governance dashboard | Governance |
| /faculty/batch-management | Batch lifecycle + handover | Governance |
| /faculty/faculty-management | Faculty provisioning | Governance |
| /alumni | Alumni action queue | Alumni |
| /alumni/journey | Journey archive | Alumni |
| /alumni/contribute | Knowledge contribution | Alumni |
| /alumni/lineage | Lineage + mentoring | Alumni |
| /alumni/community | Community Board | Alumni |
| /alumni/settings | Account + availability | Alumni |

### Mobile Routes — Flutter App

| Route | Purpose |
|---|---|
| /splash | Auth + version + lifecycle resolution |
| /login | OTP login |
| /onboarding | Calibration wizard |
| / | Today (daily companion home) |
| /train | Daily Five + sprint selector |
| /train/daily-five | Daily Five session |
| /train/sprint | Adaptive sprint |
| /train/communication | Communication practice (audio) |
| /progress | Readiness dimensions overview |
| /progress/dimension/:dim | Dimension detail |
| /community | Squads + lineage + Knowledge Brain |
| /community/knowledge-brain | Knowledge search |
| /community/lineage | Lineage view |
| /community/squads | Squad view |
| /you | Profile + settings + help + archive |
| /you/settings | Account settings |
| /you/connected-services | LeetCode + GitHub |
| /you/archive | Journey archive |
| /inbox | Unified inbox |
| /admin | PR quick actions (capability-gated) |

---

## Appendix A — Frozen Boundary Decisions

1. **No student self-registration.** Students are created by PR bulk import only.
2. **No manual task completion button for coding tasks.** Piston API + OpenRouter AI pipeline is the only path to verified complete.
3. **No official placement data in PSGMX.** NEO PAT owns drives. A deep link is the only connection.
4. **No readiness score shared between peers.** Private by default.
5. **No password authentication.** OTP only, everywhere.
6. **Android via GitHub Releases.** No Play Store.
7. **All AI via OpenRouter free models.** No paid models. Fallback chain for all calls.
8. **No Docker/VPS for code execution.** Piston API only.
9. **No pg_cron.** GitHub Actions scheduled workflows only.
10. **Batch handover is a workflow, not a manual database edit.** The system handles capability transitions.
11. **PR cannot grant faculty or governance access.** Only governance admin can.
12. **Audit log is append-only and permanent.** No record can be deleted.
13. **Audio only for communication practice (no video).** Supabase Storage 1GB free tier constraint.
14. **Supabase keepalive via GitHub Actions.** Prevents free tier project pause.

---

## Appendix B — Glossary

| Term | Meaning |
|---|---|
| PR | Placement Readiness Representative — student admin, batch-scoped |
| CodeBox | PSGMX embedded code editor (Monaco) + execution (Piston API) + AI evaluation (OpenRouter) |
| Piston API | Free public code execution API at emkc.org — runs student code in isolated environment |
| Daily Five | The 5-question daily adaptive practice set |
| Readiness Engine | Backend system computing the 6-dimension readiness score |
| Freshness Job | GitHub Actions workflow (Sunday) that applies evidence age penalties |
| Keepalive Job | GitHub Actions workflow (Sunday) that prevents Supabase free tier project pause |
| Journey Archive | An alumnus's immutable history of their MCA preparation years |
| Batch Handover | Formal lifecycle event where one PR's batch graduates and the next PR takes over |
| OpenRouter | AI inference gateway — only free models are used in this product |
| Knowledge Brain | Curated, faculty-approved repository of preparation knowledge |
| AI Senior | RAG-powered Q&A system grounded in the Knowledge Brain |
| Interview Pattern Library | Alumni/senior-contributed patterns of real interview structures |
| Lineage | Register-suffix-based connection between current students and batch predecessors |
| Recovery Case | Faculty-managed support plan for a student showing decline signals |
| Governance Admin | HOD or explicitly authorised faculty member with system-wide admin access |
| Resend | Free transactional email service used for OTP and notifications |
| RLS | Row-Level Security — PostgreSQL per-row access control system |
| RPC | Remote Procedure Call — Supabase server-side functions with JWT-aware authorization |

---

*Document frozen at v1.1. Development begins. All future decisions must be captured as amendments, not undocumented implementation choices.*
*Free tier constraint is non-negotiable. Any feature that cannot be built on the services listed in Chapter 0 must be redesigned or deferred.*
