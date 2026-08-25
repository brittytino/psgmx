# PSGMX Ecosystem — Complete Flow, Readiness Score & Project Abstract

---

# PART 1 — THE READINESS SCORE

## What the Score Measures and Why

The readiness score is a single number between 0 and 100 that tells a student, honestly and in real time, how prepared they are for placements — not based on their grade sheet or what they claim, but based on what they have actually done consistently over their batch period. It is calculated from four inputs, each of which measures a different dimension of placement readiness: habit consistency, knowledge depth, problem-solving momentum, and performance under real test conditions. eCampus academic marks are not part of this score — the score is about placement preparation, not classroom performance, and those are two genuinely different things.

---

## The Four Inputs

### Input 1 — Daily Five Engagement (30 points maximum)

Every day the Flutter app offers five multiple-choice questions. The Daily Five engagement score tracks two things together: how often a student shows up (their adherence rate) and how well they perform when they do (their accuracy rate). These are split 20 points for showing up and 10 points for performing.

The **adherence rate** is calculated as the number of days the student completed all five questions divided by the total number of eligible days since their batch started, expressed as a percentage. A student who has completed 180 out of 200 eligible days has an adherence rate of 90%. The streak the student maintains matters on top of this — a streak multiplier applies a small bonus of up to 5 percentage points for students who are currently on a continuous streak of 30 days or more, rewarding sustained habit rather than burst activity. This combined figure, mapped to the 20-point maximum, forms the first part of the input.

The **accuracy rate** is simply the proportion of questions answered correctly across their entire batch history, expressed as a percentage. This is stored as a running rate — not individual answers, which are never persisted — so over time it reflects true comprehension rather than a lucky good day. This rate, mapped to the 10-point maximum, forms the second part.

**Daily Five Engagement Score = (Adherence Rate × 0.20 × 100) + (Accuracy Rate × 0.10 × 100)**
Maximum contribution to Readiness Score: **30 points**

---

### Input 2 — LeetCode Progress (25 points maximum)

LeetCode measures how much a student has genuinely grown their problem-solving ability during their time in the program — not their lifetime total before joining, but the problems they solved between their batch start date and today. Problems are weighted by difficulty because the distribution of difficulty genuinely predicts placement performance: easy problems demonstrate familiarity with patterns, medium problems are what most placement tests actually ask, and hard problems demonstrate depth.

A student earns a weighted LeetCode score equal to the number of Easy problems they solved during their batch period multiplied by one, plus Medium problems multiplied by two, plus Hard problems multiplied by three. This raw weighted count is then converted into a percentile rank within their own batch — so a first-year who has been grinding hard this month can sit at the 90th percentile of their first-year batch even if a second-year has a larger absolute total, because the comparison is always within-batch. This percentile, mapped to the 25-point maximum, is the input.

**LeetCode Score = Batch-Period Weighted Problems Percentile (within own batch) mapped to 25 points**
Maximum contribution to Readiness Score: **25 points**

---

### Input 3 — Mock Exam Performance (35 points maximum)

This is the most heavily weighted input because a mock exam conducted under real proctoring conditions on the Next.js platform is the closest approximation of an actual placement test that the ecosystem can produce. When a student sits a mock exam on Next.js — which may combine MCQ sections, coding problems, and verbal aptitude sections depending on what the exam is designed to test — their score is recorded in the shared Supabase database and immediately reflected in their readiness score.

A student's mock exam input is the weighted average of all mock exams they have taken during their batch period. Recent exams are weighted slightly more than older ones to reflect current capability rather than historical performance — an exam taken in the last 30 days counts at full weight, an exam taken three months ago counts at 70% weight, and anything beyond six months counts at 40% weight. This decaying average is mapped to the 35-point maximum.

A student who has not yet taken any mock exam has a 0 in this input, which is intentional — it creates a visible, meaningful incentive to engage with the Next.js platform and sit at least one exam early in the batch period. Once the first exam is taken, the score is no longer 0, and subsequent exams either improve or reflect the current level honestly.

**Mock Exam Score = Weighted Average of All Batch-Period Mock Exams mapped to 35 points**
Maximum contribution to Readiness Score: **35 points**

---

### Input 4 — Placement Session Attendance (10 points maximum)

The Placement Rep and Coordinators schedule placement-specific preparation sessions through the Flutter app — extra classes, industry talks, mock group discussions. A student's attendance across these sessions, expressed as a percentage of sessions they were eligible for, maps to the final 10 points. This input is intentionally the smallest of the four because attendance alone, without the cognitive engagement the other three inputs measure, does not reflect readiness — but it matters enough to be worth including, and its small weight means a student who attends every session but does nothing else will not score well, while a student who engages fully in all other areas but misses sessions will not be penalized enough to feel unfair.

**Placement Session Score = (Sessions Attended / Sessions Eligible) × 10**
Maximum contribution to Readiness Score: **10 points**

---

## The Final Formula

```
Readiness Score = Daily Five Engagement (max 30)
                + LeetCode Progress (max 25)
                + Mock Exam Performance (max 35)
                + Placement Session Attendance (max 10)
```

The result is always between 0 and 100. Score bands give the number meaning at a glance:

| Band | Score | Interpretation |
|---|---|---|
| Strong | 80–100 | Consistently active across all four dimensions, sitting exams, maintaining streaks, solving problems regularly — genuinely ready |
| Building | 60–79 | Active in most areas but likely missing one input, usually the mock exam or LeetCode depth — on track if they keep going |
| Needs Attention | 40–59 | Present but inconsistent — showing up for some things but not building a real habit across all four |
| At Risk | 0–39 | Low engagement across multiple inputs, or no mock exams taken yet — needs a check-in |

---

## Who Can See the Score and In What Form

A student sees their own score in the Flutter app at all times — it is the first thing on the home screen. They can also see the breakdown of all four inputs so they know exactly which dimension is pulling their score down. On the Next.js platform, the student sees the same score on their profile.

Faculty see every student's score on the Next.js platform in their mentee roster, with the four-component breakdown visible when they tap into an individual student. They see the trend over the last 90 days as a simple line so they can tell whether a student is improving, stagnating, or declining.

The HOD sees batch-level averages — not individual scores — on the Next.js platform's department overview.

Alumni do not see other students' scores. They see only their own historical score from when they were in the batch, which lives in the database permanently as part of their profile.

---

# PART 2 — THE BATCH LIFECYCLE (Automatic, No Manual Steps)

## How a Batch Is Born

When the MCA department admits a new class — say, June 2025 — a new batch record is created in the Supabase database with a `batch_code` of `25MX`, a `start_date` of June 2025, and an `end_date` of June 2027. The moment that batch record exists, any student who signs up with an `@psgtech.ac.in` email and a roll number beginning with `25MX` is automatically assigned to it. No whitelist, no manual enrollment, no seed file — the roll number does all the identification work.

## The Two Years of Active Life

From June 2025 to June 2026, the 25MX batch is the junior batch. From June 2026 to June 2027, they are the senior batch, with the 26MX batch now joining as juniors alongside them. During both years, every student in the batch has full access to the Flutter app and full access to the Next.js platform as a student.

## The Graduation Transition (Automatic, Happens Once)

When June 2027 arrives, a scheduled database job — running on the first day of the graduation month, configurable per batch — does exactly three things in sequence with no human intervention required:

First, it flips the 25MX batch record's status from `active` to `graduated`. This single status change cascades through every feature in both apps simultaneously: the Flutter app shows a graduation screen to any 25MX student who opens it that day, the Next.js platform updates their role from `student` to `alumni`, and the leaderboards and batch comparisons in the Flutter app stop including 25MX students from that moment forward.

Second, it makes the Flutter app read-only for 25MX accounts. They can still open the app. They can still see their full history — every streak they maintained, every LeetCode problem they solved, their final readiness score, their mock exam results. They cannot mark attendance, submit daily five answers, or add new placement log entries. Their placement log entries that they wrote as second-years remain permanently visible to all future batches.

Third, it opens their Next.js alumni profile. Their `UserAccount` role field is updated to `alumni`, which unlocks the alumni-specific features — the ability to write Knowledge Brain articles, post to the Collaboration Marketplace, and toggle their mentorship availability so junior students can see them in the "Your Senior" card. Their readiness score history, mock exam records, and placement log contributions all carry over into their alumni profile as a permanent record of their batch journey.

## What a Graduated Student Experiences

The graduation screen in the Flutter app is not a lock-out screen — it's the Credits Easter Egg moment made real. It greets the student by name, shows their final readiness score, their total streak days over two years, their total LeetCode problems solved during the batch period, and their mock exam improvement from first to last. It thanks them for being part of the batch, invites them to the Next.js alumni network, and then settles into the read-only archive mode. The whole experience takes thirty seconds and feels like a handshake, not a door closing.

On the Next.js platform, the transition is even simpler — their dashboard just reorganizes from a student view to an alumni view. The articles and mentorship features that were grayed out when they were a student become available. Nothing breaks, nothing is lost.

---

# PART 3 — CORRECTED USER FLOWS (Both Apps, All Users, Plain Language)

## The Golden Rule

The Flutter app is the daily habit tool — students open it every morning. The Next.js platform is the knowledge and examination tool — students and faculty go there with intention, not by routine. They share data through one Supabase database. They do not share features. A student never needs to open the Next.js platform to keep their Flutter streak alive, and a faculty member never needs to touch the Flutter app to see a student's readiness score.

---

## First-Year Student (June 2026 entry, batch 26MX)

This student has heard about the app through their senior batch or the Placement Rep who welcomed their batch during orientation. They download the Flutter APK from the GitHub link (Android) or open the PWA link on Safari and add it to their home screen (iOS). They enter their `@psgtech.ac.in` email and their roll number `26MX___`, receive an OTP, and the app identifies them as batch 26MX with no further steps. Before showing them the home screen, the app asks three quick calibration questions — roughly how many DSA problems they've solved so far, their rough study frequency, and their overall placement confidence — and uses those answers to generate their starting readiness score, which appears on screen as a real number. They are not handed a blank dashboard.

From the next morning, the Flutter app is the first thing they open after waking up. They answer their five daily questions, which takes about ninety seconds, and their streak ticks up by one. They look at their home screen: their readiness score, their streak, their rank in the first-year leaderboard, and today's task assigned by the Placement Rep. They complete what they can and get on with their day. Three times a week, on average, they also open the LeetCode problem linked in the Quests tab and solve it, which feeds into their LeetCode momentum score.

About three months in, someone in their batch mentions the Next.js platform and shares the link. They open it on a laptop, log in with their roll number, and see the same readiness score they saw this morning in the Flutter app — because it's the same database. They also see their "Your Senior" card: the 25MX student whose roll number matches theirs, who has opted into mentorship, with a link to connect. They explore the Knowledge Brain, find articles written by alumni and seniors, and use the AI Senior to get a tailored answer about which companies typically visit the MCA department and what preparation looks like. They bookmark a few articles and go back to their routine. The Next.js platform is useful, but it's not daily — they come back when they have a real question or when a mock exam is scheduled.

The first mock exam on the Next.js platform arrives two months into the semester. Their Placement Rep announces it through the Flutter app's notification system. They open the Next.js platform on a laptop, sit the exam under the proctoring system — camera active, no tab switching, randomized question order — and submit their score. Within seconds, their readiness score in the Flutter app updates to reflect this first mock exam result, and they watch their score jump. That moment, seeing two weeks of daily-five and LeetCode work combine with their first real exam score into a single number moving upward, is the moment the ecosystem makes sense to them.

---

## Second-Year Student (batch 25MX, final year)

This student has been using the Flutter app for over a year. Their readiness score has a genuine history behind it — they've maintained streaks, solved problems, taken mock exams — and the number on their home screen is a real reflection of the work they've put in, not a placeholder. They know which input is their weakest (usually LeetCode depth or mock exam consistency) because the Flutter app shows the breakdown.

The placement season starts in September. Companies begin to visit, and the Placement Rep logs each company in the Flutter app as they arrive — date, roles, package band, rounds. This student can read those logs the same morning they're posted. After each drive they sat for, they open the Placement Log in the Flutter app and add their experience writeup: what the online test tested, how the technical interview was structured, what the HR interviewer asked. It takes them ten minutes on their phone. That entry flows automatically into the Next.js Knowledge Brain within the hour, where it will be readable by first-years who search for that company and usable by the AI Senior when it answers future students' questions about that company's process.

On the Next.js platform, this student uses the AI Senior differently from a first-year — they're not exploring the ecosystem, they're extracting specific value. They ask targeted questions: "What is the typical DSA difficulty for Zoho rounds?" and get an answer grounded in writeups from students two batches ahead of them. They sit mock exams regularly, knowing that the 35-point weight of mock exams in their readiness score makes this the highest-leverage thing they can do in the weeks before a real drive. Their mock exam improvement trend is visible to their faculty mentor, who scheduled a check-in session with them after noticing the score stagnating for three weeks.

When June 2027 arrives and the graduation transition runs, they open the Flutter app to a handshake screen. Their two-year journey is summarized. Their placement log entries stay visible to all future batches. Their Next.js account becomes an alumni account, and they fill in their mentorship availability and update their current role so the batch below them can find them.

---

## Team Leader

The Team Leader's Flutter experience is identical to any other student's daily-habit experience, with one additional job that takes under two minutes per placement session. When their Placement Rep marks a session as complete, the Team Leader opens the Sessions tab, finds their team's session entry, and taps through their ten or twelve team members to mark present or absent. They can add a brief note for anyone who was absent for a valid reason. That's the full extent of the Team Leader role — no admin panel, no separate interface, no complexity. Everything else they do in the app is as a regular student.

---

## Placement Coordinator

A Coordinator's Flutter experience adds two lightweight responsibilities on top of being a student. First, they can schedule placement sessions — they open the Sessions tab, tap "Schedule New," and fill in a date, time, topic, and which teams the session is for. Notifications go out to those students automatically. Second, they can publish daily tasks — they open the Quests tab, select a date, and enter the LeetCode problem link and the core-subject topic for that day. Both of these tasks take under three minutes. The Coordinator's role in the ecosystem is operational rather than strategic — keeping the daily flow running so the Placement Rep doesn't have to manage every individual session and task themselves.

---

## Placement Representative

The Rep's Flutter app is the same app every student uses, with a Reports tab and team-management tools unlocked. Their morning starts the same way — daily five, streak check, readiness score — and then, a few days a week, they spend ten to fifteen minutes on the administrative side. They check the Reports view: who has dropped below 60% readiness this week, who has broken a streak longer than a week, which teams have low placement-session attendance. They send announcements through the Flutter notification system to flag important updates. When a company is confirmed to visit, they log it in the Placement Log, publish the relevant task in Quests for students to prepare, and the whole batch gets notified.

When the semester exam window approaches, the Rep coordinates with faculty through the Next.js platform — not the Flutter app — to schedule mock exams. The exam scheduling, the proctoring setup, and the results processing all happen on the Next.js side, because that's where the exam infrastructure lives. The Rep just needs to announce the exam date through the Flutter app so students know to open the web platform on that day.

---

## Faculty Member

A faculty member never opens the Flutter app. Their entire relationship with the PSGMX ecosystem happens through the Next.js web platform, and the platform is designed to make their time there valuable and brief.

When they log in, the first thing they see is their mentee roster with each student's current readiness score, the four-component breakdown, and a 90-day trend line. This data was generated entirely by students using the Flutter app and sitting exams on Next.js — the faculty member did nothing to produce it. If a student's readiness score has been declining for three weeks, a small "Needs Attention" flag appears on that student's row, and the faculty member can schedule a mentorship session through the platform's calendar tool.

When a mock exam is scheduled, the faculty member uses the Next.js exam builder to create it — selecting question types, setting the duration, configuring the proctoring level, and assigning it to a specific batch or specific students. The platform's proctoring system handles the exam administration: it requires camera access, detects tab switching, randomizes question order per student, and flags any suspicious events for the faculty member's review after the exam. Results write to the shared Supabase database immediately, so a student's readiness score updates with the new mock exam contribution within minutes of submitting.

Faculty also moderate the Knowledge Brain. When a student or alumnus submits an article — or when a placement experience writeup flows in from the Flutter app — it enters a review queue on the Next.js platform. The faculty member reads it, approves it or suggests revisions, and approved articles are immediately indexed and available to the AI Senior for grounding. This moderation step is what separates the PSGMX Knowledge Brain from a generic forum — everything in it has been read by someone with domain expertise before it becomes part of what the AI tells students.

---

## Alumni

After graduating, an alumnus's Flutter app becomes a read-only archive. They can open it, see their full history, and feel proud of the number — but they cannot add new data to it. The active side of their PSGMX life moves entirely to the Next.js platform.

On the Next.js platform, alumni have two main contributions. First, they can write Knowledge Brain articles — detailed, first-person accounts of how they prepared, what their placement process looked like, what the first year of working in their role felt like. These articles are read by the AI Senior and surfaced to current students who ask relevant questions. An alumnus who writes three good articles in their first year after graduating has materially improved the quality of guidance available to every student in the department from that point forward.

Second, they can toggle their mentorship availability on their profile. When they do, a current student whose roll number matches theirs by pattern (the student whose roll ends in the same three digits) sees a "Your Senior" card appear in their Flutter profile and on their Next.js dashboard. The connection is not a full messaging system — it's a link to the alumnus's chosen contact method (email, LinkedIn, or the platform's own lineage messaging), so the relationship can develop naturally rather than being forced through a proprietary chat feature neither of them might want to use.

---

## HOD

The Head of Department opens the Next.js platform on a laptop when they want a department-level view, which in practice means once a week or once before a meeting. They see batch-level averages — average readiness score per batch, placement-session attendance trend, number of mock exams conducted this semester, number of company drives logged, and the proportion of students in each readiness band. They do not see individual student scores unless they navigate into a specific batch and then into a specific student, and that level of access is rarely necessary. The dashboard is designed to answer "is the department's placement preparation on track?" in one glance, and to surface "these three students across the two batches might need faculty intervention" as a short, actionable list.

---

---

# PART 4 — PROJECT ABSTRACT

---

## Title

**PSGMX: A Two-Platform Placement Readiness Ecosystem for MCA Students — Integrating Daily Habit Tracking, Knowledge Management, and Proctored Examination through a Unified Student Identity**

---

## Overview of the Project

PSGMX is a dual-platform academic ecosystem developed entirely by students of the Department of Computer Applications at PSG College of Technology, Coimbatore. It consists of two complementary applications: **PSGMX App**, a Flutter-based cross-platform mobile application designed for daily use, and **PSGMX Readiness**, a Next.js-based web platform designed for knowledge management, faculty oversight, and proctored examination. Both platforms share a single Supabase PostgreSQL database, ensuring that data produced on one surface is immediately visible and actionable on the other without synchronization overhead or data duplication.

The ecosystem serves every stakeholder in the MCA department's placement lifecycle — students (both first-year and second-year), placement representatives, coordinators, team leaders, faculty mentors, alumni, and the Head of Department — each through a dedicated, role-appropriate interface. The two platforms are designed on the principle that daily habits are best built on mobile and deep knowledge work is best done on the web, with the shared database ensuring that neither surface operates in ignorance of what the other has captured.

The central output of the ecosystem is a **Readiness Score** — a 0-to-100 index computed from four inputs: Daily Five quiz engagement, LeetCode problem-solving momentum, mock examination performance, and placement-session attendance. This score gives every student an honest, real-time signal of their placement preparedness that updates with every action they take, and gives faculty a single number per student to prioritize mentorship effort without requiring access to raw activity logs.

---

## Existing System

The existing placement preparation infrastructure at most engineering departments, including MCA departments, relies on a fragmented combination of manual tools: WhatsApp groups for announcements, Google Sheets or Excel files for attendance tracking, Google Forms for task submissions, separate portals for college academic data (such as eCampus), and commercial platforms like LeetCode or HackerRank for coding practice — none of which are connected to each other, and none of which give a student or a faculty member a unified view of where a student actually stands.

Placement representatives spend significant time on manual data aggregation — collating attendance from multiple team leaders' sheets, calculating percentages by hand, and compiling reports for faculty. Students have no reliable way to know how prepared they are for an upcoming placement drive relative to their batchmates. Faculty receive no real-time signal of student engagement and must wait for periodic, manually prepared reports to identify students who need intervention. Alumni knowledge is locked in personal memories and informal conversations rather than captured and searchable by future students. Placement drive experiences are shared sporadically in WhatsApp messages and are lost within weeks.

There is no existing tool that connects daily habit maintenance to placement performance prediction, surfaces that connection to faculty in real time, and simultaneously builds an institutional knowledge base that outlasts any single batch.

---

## Objectives of the Proposed Application

The primary objective is to build a sustainable, student-maintained placement preparation ecosystem that remains useful and accurate across multiple consecutive MCA batches without requiring institutional investment, faculty administration, or commercial licensing.

Specifically, the system aims to replace manual attendance aggregation with a role-based, team-scoped digital marking system that produces correct percentages automatically; to provide every student with a continuously updated Readiness Score derived from verifiable activity rather than self-reported progress; to create a searchable, AI-augmented knowledge base of real placement experiences that grows with every batch and outlives the batch that created it; to conduct and proctor mock examinations at a level of rigor appropriate for placement preparation without requiring specialized external software; to automate the batch lifecycle so that graduating students transition to alumni automatically and incoming students join their batch without administrative overhead; and to give faculty a real-time, zero-overhead view of student readiness across both active batches.

---

## Scope and Use

The system is scoped exclusively to the MCA Department at PSG College of Technology. It serves two active student batches at any given time (approximately 240 students total), one set of faculty mentors, alumni from all previous batches who choose to remain connected, and the Head of Department. The system is not designed for extension to other departments, other colleges, or non-MCA programs. It is not a learning management system, not an ERP, and not a replacement for institutional academic infrastructure — it is a placement-readiness layer built on top of the existing academic environment, accessible entirely outside institutional servers and institutional IT budgets.

The Flutter app targets Android (via GitHub APK distribution) and iOS (via Progressive Web App), requiring no App Store or Play Store publishing. The Next.js platform targets modern web browsers on desktop or laptop devices, where exam-taking and knowledge-reading work best. Neither application requires payment, subscription, or institutional IT approval to operate.

---

## Technology to Be Used

**Flutter App (PSGMX App):**
The mobile application is built with Flutter 3.27+ targeting Android natively and iOS as a Progressive Web App. State management uses the Provider pattern. Local persistence for offline-first data (streak counts, cached questions, queue) is implemented via Drift (SQLite) on Android and IndexedDB via the browser API on iOS PWA. Illustrations and mascot animations are built with Rive, exported as `.riv` files and played natively via the `rive` Flutter package. All UI icons use the Lucide Icons package. Typography uses Sora and Inter from Google Fonts. The AI Mentor feature uses OpenRouter's free-tier model chain with a fallback mechanism. Data from the eCampus portal (official college academic records) is scraped via a Python FastAPI service deployed on Render and stored separately in Supabase for display only, with no connection to the readiness score.

**Next.js Platform (PSGMX Readiness):**
The web platform is built with Next.js 16 using the App Router and TypeScript throughout. Styling uses Tailwind CSS v4 with Framer Motion for animated transitions. Data visualization uses Recharts. Authentication uses JWT issued by Next.js API routes, with bcrypt password hashing. The examination proctoring system uses the browser's native MediaDevices API for camera access, Visibility API for tab-switch detection, and server-side randomization for question ordering. The AI Senior uses a RAG pipeline where student questions are matched against vector-indexed Knowledge Brain articles using pgvector (Supabase's native vector extension) and the retrieved context is passed to the AI SDK of choice (Gemini 2.5 as primary, Claude and GPT-4 via OpenRouter as fallback). The Knowledge Brain ingestion pipeline indexes new articles using pgvector embeddings within Supabase, keeping the entire vector store inside the same database that the Flutter app already uses.

**Shared Infrastructure:**
Supabase (PostgreSQL with pgvector extension, Auth, Realtime, Storage, and Edge Functions) is the single database layer for both applications. Row Level Security policies enforce role-based access at the database level so neither application can read or write data outside its permitted scope. The readiness score is computed by a Supabase Edge Function triggered on activity events (daily-five completion, mock exam submission, LeetCode sync) and written to a `readiness_scores` table immediately — no nightly job, no delay, always current. Firebase Hosting serves the Flutter web build globally. GitHub Actions handles CI/CD for both platforms.

---

## Functional Requirements

**Authentication and Identity:**
The system shall authenticate students using OTP sent to their `@psgtech.ac.in` email address. The system shall automatically assign students to the correct batch by parsing the batch code embedded in their roll number. The system shall enforce that no student can log into another batch's data. The system shall automatically transition graduating batch accounts to alumni status on the configured graduation date without any manual intervention.

**Readiness Score:**
The system shall compute and display a readiness score between 0 and 100 for every active student. The score shall update within 60 seconds of any contributing activity (daily-five completion, mock exam submission, LeetCode sync, session attendance marking). The system shall display the four-component breakdown to the student and to their faculty mentor. The system shall store a daily snapshot of each student's score for trend analysis.

**Daily Five Quiz:**
The system shall deliver exactly five multiple-choice questions per student per day from the shared question bank. The system shall not persist individual question responses to the central database — only the completion status and running accuracy rate. The system shall maintain a streak counter that increments on full completion and resets on any missed day. The system shall grant two freeze tokens per student per calendar month.

**Placement Sessions:**
The system shall allow authorized Coordinators and Placement Representatives to create placement sessions with a date, time, topic, and target team scope. The system shall allow Team Leaders to mark attendance for their team members for any session targeting their team. The system shall compute each student's placement-session attendance percentage and include it in the readiness score calculation.

**Placement Log:**
The system shall allow Placement Representatives to create company visit records. The system shall allow second-year students to attach personal experience writeups to company visit records. The system shall automatically ingest approved experience writeups into the Next.js Knowledge Brain for vector indexing. All placement log entries shall remain permanently readable by future batches after the contributing batch graduates.

**Mock Examinations:**
The system shall allow faculty members to create mock examinations with configurable question types, duration, and proctoring settings. The system shall administer exams with camera monitoring, tab-switch detection, and per-student question randomization. The system shall write examination results to Supabase immediately on submission and update the student's readiness score within 60 seconds.

**Knowledge Brain:**
The system shall allow students and alumni to submit articles and guides. The system shall require faculty approval before any submitted article is indexed and searchable. The system shall use pgvector embeddings to enable semantic search across all approved articles. The AI Senior shall use retrieved article snippets as grounding context when answering student questions.

**Alumni and Lineage:**
The system shall maintain a lineage mapping between students across batches based on the shared numeric suffix of their roll numbers. The system shall display a "Your Senior" card to any student whose lineage includes an alumni who has opted into mentorship. The system shall allow alumni to write Knowledge Brain articles, post collaboration opportunities, and toggle mentorship availability.

---

## Non-Functional Requirements

**Performance:**
The Flutter app's home screen shall load within 2 seconds on a standard 4G connection. The readiness score shall update within 60 seconds of any contributing event. The Next.js platform's Knowledge Brain search shall return results within 1 second. Mock exam pages shall load within 3 seconds even under concurrent student load during a scheduled exam.

**Reliability:**
The shared Supabase database shall maintain 99.9% uptime in line with Supabase's service guarantees. The AI Mentor fallback chain shall ensure that AI unavailability in one model transparently routes to the next without displaying an error to the student. The Daily Five quiz shall function fully offline on Android using the local Drift cache and sync streak state when connectivity resumes.

**Security:**
Row Level Security policies on all Supabase tables shall ensure that no student can read another student's raw activity data. The mock examination proctoring system shall flag and log any detected integrity violation (tab switch, camera loss) without terminating the exam, preserving faculty's ability to make case-by-case judgments on flagged sessions. eCampus passwords stored for the scraper service shall be encrypted at rest.

**Scalability:**
The batch-based architecture shall accommodate new batches joining the ecosystem each year without schema changes, backfills, or data migrations. The system shall support up to 240 concurrent active students across two batches and up to 500 concurrent alumni without degradation.

**Maintainability:**
The ecosystem shall be maintainable by a single student Placement Representative with basic technical familiarity — no DevOps expertise required for day-to-day operations. Configuration changes (graduation dates, team sizes, permission flags) shall be achievable through in-app UI without database access.

**Privacy:**
Individual daily-five question responses shall never be stored in the central database. Individual readiness score components shall be visible only to the student and their assigned faculty mentor. Alumni shall not be able to view individual student scores.

---

## Flow Diagram of the Application

```
┌─────────────────────────────────────────────────────────────────────┐
│                        STUDENT ENTRY FLOW                           │
│                                                                     │
│  Opens App → Enter Email + Roll No → OTP Verification              │
│       │                                                             │
│       ▼                                                             │
│  Roll No parsed → Batch auto-assigned (25MX / 26MX)               │
│       │                                                             │
│       ▼                                                             │
│  3 Calibration Questions → Starting Readiness Score Generated      │
│       │                                                             │
│       ▼                                                             │
│  HOME SCREEN (Flutter App) ─────────────────────────────────────── │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │  Readiness Score (0-100) — Live from Supabase             │    │
│  │  Daily Five Widget — Tap to Start Quiz                    │    │
│  │  Today's Task (LeetCode + Core)                           │    │
│  │  Leaderboards (Readiness / LeetCode) — Within Batch Only  │    │
│  │  Announcements Strip                                       │    │
│  └────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                    READINESS SCORE CALCULATION                      │
│                                                                     │
│  Daily 5 Quiz Activity ──────────────────────► 30 pts max         │
│  (Adherence Rate × 20) + (Accuracy Rate × 10)                     │
│                                                                     │
│  LeetCode Progress (batch period) ───────────► 25 pts max         │
│  Weighted by difficulty → Batch Percentile                         │
│                                                                     │
│  Mock Exam Score (Next.js, proctored) ───────► 35 pts max         │
│  Decaying weighted average of all exams taken                      │
│                                                                     │
│  Placement Session Attendance ────────────────► 10 pts max        │
│  (Sessions Attended / Sessions Eligible) × 10                     │
│                                                                     │
│  TOTAL = 0 to 100 ── Stored in Supabase ── Visible Both Apps     │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                       BATCH LIFECYCLE                               │
│                                                                     │
│  June 2025 ─────► BATCH 25MX JOINS ─────► Active Junior Year      │
│                                                                     │
│  June 2026 ──► BATCH 26MX JOINS ──► 25MX becomes Senior Year     │
│                Both active simultaneously                           │
│                                                                     │
│  June 2027 ──► GRADUATION TRIGGER (Scheduled Supabase Function)   │
│              │                                                      │
│              ├─► 25MX Flutter → Read-Only Archive                 │
│              ├─► 25MX Next.js Role → Alumni                       │
│              ├─► Placement Logs remain visible to future batches  │
│              └─► 26MX becomes new Senior batch                    │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│              CROSS-PLATFORM DATA SHARING (Single Supabase DB)      │
│                                                                     │
│  FLUTTER APP writes:                 NEXT.JS reads & writes:       │
│  • Daily 5 completion/accuracy       • Mock exam results           │
│  • Streak state                      • Faculty mentorship records  │
│  • Placement session attendance      • Knowledge Brain articles    │
│  • LeetCode stats (synced)          • Alumni lineage profiles     │
│  • Placement Log entries                                           │
│                                                                     │
│  Both apps read:                                                    │
│  • Readiness Score (computed live from all above)                 │
│  • Batch and user identity                                         │
│  • Placement Log (student entries + company records)              │
│  • Alumni lineage mappings                                         │
└─────────────────────────────────────────────────────────────────────┘
```

---

## System Architecture Diagram

```
                            ┌───────────────────────────────────┐
                            │         STUDENT DEVICE             │
                            │                                   │
                            │  ┌─────────────────────────────┐  │
                            │  │   PSGMX Flutter App         │  │
                            │  │  (Android APK / iOS PWA)    │  │
                            │  │                             │  │
                            │  │  Local Cache (Drift/IDB)   │  │
                            │  │  • Daily 5 question cache  │  │
                            │  │  • Offline streak buffer   │  │
                            │  │  • Action sync queue       │  │
                            │  └──────────────┬──────────────┘  │
                            └─────────────────┼─────────────────┘
                                              │ HTTPS
                                              │
                            ┌─────────────────▼─────────────────┐
                            │                                   │
                            │         SUPABASE                  │
                            │    (Single Shared Database)       │
                            │                                   │
                            │  PostgreSQL + pgvector            │
                            │  ┌─────────────────────────────┐  │
                            │  │  Core Tables                │  │
                            │  │  users, batches, teams      │  │
                            │  │  user_permissions           │  │
                            │  ├─────────────────────────────┤  │
                            │  │  Flutter-Written Tables     │  │
                            │  │  daily_five_streaks         │  │
                            │  │  placement_sessions         │  │
                            │  │  placement_attendance       │  │
                            │  │  placement_log_entries      │  │
                            │  │  leetcode_stats             │  │
                            │  │  daily_tasks                │  │
                            │  ├─────────────────────────────┤  │
                            │  │  Computed Tables            │  │
                            │  │  readiness_scores           │  │
                            │  │  readiness_score_history    │  │
                            │  ├─────────────────────────────┤  │
                            │  │  Next.js-Written Tables     │  │
                            │  │  knowledge_brain_articles   │  │
                            │  │  knowledge_embeddings       │  │
                            │  │  mock_exams                 │  │
                            │  │  mock_exam_results          │  │
                            │  │  alumni_profiles            │  │
                            │  │  lineage_map                │  │
                            │  │  faculty_mentorships        │  │
                            │  └─────────────────────────────┘  │
                            │                                   │
                            │  Edge Functions                   │
                            │  • Readiness score computation   │
                            │  • Batch graduation trigger      │
                            │  • Knowledge Brain ingestion     │
                            └──────────┬──────────┬────────────┘
                                       │          │
                         ┌─────────────▼──┐  ┌───▼──────────────────┐
                         │  FACULTY /     │  │  STUDENT LAPTOP /    │
                         │  HOD DEVICE   │  │  DESKTOP             │
                         │               │  │                      │
                         │ ┌───────────┐ │  │ ┌──────────────────┐ │
                         │ │ PSGMX     │ │  │ │  PSGMX Readiness │ │
                         │ │ Readiness │ │  │ │  Next.js Web App │ │
                         │ │ Next.js   │ │  │ │                  │ │
                         │ │           │ │  │ │ • Knowledge Brain│ │
                         │ │ • Mentee  │ │  │ │ • AI Senior Chat │ │
                         │ │   roster  │ │  │ │ • Mock Exams     │ │
                         │ │ • Exam    │ │  │ │   (proctored)    │ │
                         │ │   builder │ │  │ │ • Lineage / Your │ │
                         │ │ • KB      │ │  │ │   Senior card    │ │
                         │ │   review  │ │  │ │ • Alumni profile │ │
                         │ │ • Dept    │ │  │ │   (post-grad)    │ │
                         │ │   overview│ │  │ └──────────────────┘ │
                         │ └───────────┘ │  └──────────────────────┘
                         └───────────────┘
                                       │
                              ┌────────▼────────┐
                              │  EXTERNAL APIS  │
                              │                 │
                              │ • LeetCode API  │
                              │   (stats sync)  │
                              │ • OpenRouter    │
                              │   (AI Mentor    │
                              │    fallback)    │
                              │ • Gemini / AI   │
                              │   (AI Senior    │
                              │    RAG primary) │
                              │ • eCampus API   │
                              │   (Python       │
                              │    scraper -    │
                              │    academic     │
                              │    data only)   │
                              └─────────────────┘
```

---

## Interface / Prototype of the Proposed Application

**PSGMX Flutter App (Mobile)**

The application opens to a splash screen featuring the PSGMX wordmark and Spark, the app's companion mascot — a small, rounded teardrop-shaped character in the brand's coral accent color. First-time users are taken through a four-screen illustrated story before reaching authentication, so they understand the product's purpose before they type a single character. The authentication screen uses a clean single-input email field followed by a six-box OTP entry, and the batch confirmation screen celebrates their enrollment with a confetti moment and the batch name.

The home screen (tab: Pulse) leads with a large circular readiness gauge in coral showing the student's current 0-to-100 score, followed by the Daily Five streak card and a three-chip status row. Below these, two separate horizontally scrollable leaderboard strips — one for LeetCode problems solved this week and one for overall readiness rank — keep the competitive element visible without making it the dominant element of the screen.

The bottom navigation contains five tabs: Pulse (home), Quests (daily tasks), Sessions (placement attendance), Campus (official eCampus data), and You (profile and settings). The Sessions tab shows a GitHub-style contribution heatmap for the student's placement-session attendance, clearly labeled so it is never confused with the eCampus academic attendance shown in the Campus tab.

The Daily Five quiz runs in a full-screen immersive mode with a linear progress bar, no navigation chrome, and a small Spark icon watching from a corner — keeping the quiz feeling focused. The AI Mentor chat uses Spark as its avatar, grounding the AI in the same character the student already associates with the app.

**PSGMX Readiness (Web Platform)**

The web platform's primary navigation differentiates student, alumni, and faculty views through role-based sidebar layouts rather than completely different applications. Students see: Dashboard (readiness score history, upcoming exams, "Your Senior" card), Knowledge Brain (searchable articles, AI Senior chat), Exams (upcoming and past mock exams), and Profile (lineage, alumni status after graduation).

Faculty see: Mentee Roster (readiness scores and trend lines for their assigned students), Exam Builder (create and schedule mock exams with proctoring settings), Knowledge Review (approve or revise submitted articles), and Department Overview (batch-level aggregate statistics).

The mock exam interface is intentionally spartan — white background, no distractions, a visible countdown timer, and a small camera feed thumbnail in one corner confirming that the proctoring is active. After submission, the result is shown immediately and the readiness score update is visible within the next minute when the student next looks at their Flutter app.

---

## BPMN Diagram of the Proposed Application

```
STUDENT DAILY FLOW (PSGMX App)
═══════════════════════════════════════════════════════════════════════

[START] ──► (Student opens Flutter App each morning)
                    │
                    ▼
         [Home screen loads] ──► {Streak active?}
                                      │YES          │NO
                                      ▼             ▼
                              [Show current    [Show "Start your
                               streak count]   streak again" nudge]
                    │
                    ▼
         (Student taps Daily Five)
                    │
                    ▼
         [Quiz Mode screen opens — immersive, no nav bar]
                    │
             ┌──────▼──────┐
             │ Q1 of 5     │──► [Answer selected] ──► [Feedback shown in-memory]
             └──────┬──────┘
                    │ × 5 questions
                    ▼
         {All 5 completed?}
              │YES          │NO (app backgrounded)
              ▼             ▼
    [Streak +1]         [Streak reset to 0]
    [Accuracy rate      [Freeze used if available?]
     updated in DB]          │YES → Streak preserved
                             │NO  → Streak lost
              │
              ▼
    [Readiness score recomputed by Supabase Edge Function]
              │
              ▼
    [Student checks Quests tab → sees today's task]
              │
              ▼
    [Student solves LeetCode problem → LeetCode API syncs within 6 hours]
              │
              ▼
    [Readiness score updates again — LeetCode component refreshed]
              │
              ▼
         [END of daily Flutter loop]

───────────────────────────────────────────────────────────────────────

MOCK EXAM FLOW (Next.js Platform)
═══════════════════════════════════════════════════════════════════════

[Faculty creates exam in Next.js Exam Builder]
              │
              ▼
[Faculty sets: question pool, duration, proctoring level, target batch]
              │
              ▼
[Exam scheduled → Flutter App sends push notification to target students]
              │
              ▼
[Exam day: Student opens Next.js platform on laptop/desktop]
              │
              ▼
[System requests camera access → {Camera granted?}]
    │YES                          │NO
    ▼                             ▼
[Exam starts]            [Warned: exam requires camera. Cannot proceed without.]
    │
    ▼
[Questions served — randomized order per student]
    │
    │── [Tab switch detected?] ──► [Flag logged, student warned, exam continues]
    │── [Camera loss detected?] ─► [Flag logged, student prompted to restore]
    │
    ▼
[Student submits / timer expires]
    │
    ▼
[Score computed and written to Supabase mock_exam_results]
    │
    ▼
[Supabase Edge Function triggers readiness score recomputation]
    │
    ▼
[Student's Flutter home screen shows updated readiness score within 60s]
    │
    ▼
[Faculty sees updated mentee roster score on Next.js within 60s]
    │
    ▼
[END of mock exam flow]

───────────────────────────────────────────────────────────────────────

PLACEMENT LOG → KNOWLEDGE BRAIN FLOW
═══════════════════════════════════════════════════════════════════════

[Placement Rep logs company visit in Flutter Placement Log]
              │
              ▼
[Company record visible to all students in both batches immediately]
              │
              ▼
[Second-year student sits placement drive]
              │
              ▼
[Student opens Flutter → taps company record → adds experience writeup]
              │
              ▼
[Writeup saved to Supabase placement_log_entries]
              │
              ▼
[Supabase trigger → Knowledge Brain ingestion Edge Function fires]
              │
              ▼
[Article created in knowledge_brain_articles with source: "flutter"]
              │
              ▼
[Faculty review queue in Next.js shows new pending article]
              │
              ▼
[Faculty reads, approves]
              │
              ▼
[pgvector embedding generated → article indexed for semantic search]
              │
              ▼
[AI Senior can now use this article to ground answers about that company]
              │
              ▼
[First-year student asks AI Senior "What is TCS Digital's process like?"]
              │
              ▼
[AI Senior retrieves this article as context → answers with real data]
              │
              ▼
[END of placement knowledge flow — cycle continues with each new drive]

───────────────────────────────────────────────────────────────────────

BATCH GRADUATION FLOW
═══════════════════════════════════════════════════════════════════════

[Scheduled Supabase Edge Function fires on batch graduation date]
              │
              ▼
[Batch status updated: active_senior → graduated]
              │
              ├──► [Flutter accounts → read_only mode]
              │         │
              │         ▼
              │    [Students open app → see graduation screen
              │     with 2-year journey summary, then archive view]
              │
              ├──► [Next.js UserAccount role → alumni]
              │         │
              │         ▼
              │    [Alumni features unlocked: KB articles,
              │     collaboration posts, mentorship toggle]
              │
              ├──► [Placement log entries → permanent, visible to all future batches]
              │
              └──► [Leaderboards → 25MX students removed from active rankings]
                        │
                        ▼
              [Next junior batch (26MX) automatically becomes senior batch]
                        │
                        ▼
              [System ready for next intake batch without manual steps]
                        │
                        ▼
              [END of graduation flow]
```

---

*Document prepared for the MCA Department, PSG College of Technology, Coimbatore. Both applications — PSGMX App (Flutter) and PSGMX Readiness (Next.js) — are student-built, freely distributed, and open for contribution by future batch members.*