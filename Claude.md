# PSGMX Monorepo — AI Agent Development Prompt

**Hand this entire file to your AI coding agent (Claude Code, Cursor, Windsurf, or similar) as the project brief. Do not summarize it. The agent must read every section before writing a single line of code.**

---

## 0. Agent Ground Rules

Before doing anything else, read this section fully.

You are building a production-grade educational ecosystem called **PSGMX** for the MCA Department at PSG College of Technology, Coimbatore, India. It consists of two applications inside one monorepo:

- `apps/mobile` — a Flutter application, served at `app.psgmx.tech`, used by students daily on Android (APK via GitHub Releases) and iOS (PWA via Safari)
- `apps/web` — a Next.js 15 application, served at `psgmx.tech`, used by students (knowledge + exams), faculty (mentorship + exam proctoring), alumni (knowledge contribution), and the HOD (department overview)

Both applications share **one single Supabase project** as their only database. There is no MongoDB. There is no second database. There is no bridge API, no sync job, no message queue between the two apps. They both read from and write to the same Supabase PostgreSQL database, with Row Level Security policies enforcing what each role is allowed to touch.

**Do not hallucinate APIs, packages, or features that are not specified in this document.** If something is ambiguous, add a `TODO:` comment in the code and continue. Do not invent a solution to fill a gap.

**Work phase by phase.** Do not start Phase 2 until Phase 1 is fully complete and verifiable. At the end of each phase, output a checklist of what was done and what the verifiable state of the repository is.

**Never break what already works.** Both repos have existing working code. The goal is to restructure, migrate, and extend — not rewrite everything from scratch unless a specific section says to.

---

## 1. Current State of the Repository

The repository is at the root of a folder called `psgmx`. Inside it are two sub-folders, each being its own Git repository. Their current names are unknown — refer to them by what they contain:

- **Flutter sub-folder**: contains `pubspec.yaml`, `lib/`, `android/`, `ios/`, `database/` (SQL migrations), `ecampus_api.py`
- **Next.js sub-folder**: contains `package.json` with Next.js as a dependency, `src/` or `app/` directory, Mongoose model files in a `models/` folder, MongoDB connection logic

Your first task in Phase 1 is to identify these two folders by scanning the root of the repository, then rename and restructure them as specified below.

---

## 2. Target Monorepo Structure

After Phase 1, the repository must look exactly like this. Create every folder and file listed. Do not create anything not listed here (with the exception of auto-generated files like `node_modules`, `.dart_tool`, build outputs).

```
psgmx/
├── apps/
│   ├── mobile/                    ← renamed from the Flutter sub-folder
│   │   ├── lib/                   ← unchanged from current Flutter source
│   │   ├── android/               ← unchanged
│   │   ├── ios/                   ← unchanged
│   │   ├── web/                   ← unchanged
│   │   ├── assets/                ← unchanged
│   │   ├── pubspec.yaml           ← update name field only
│   │   └── .env.example           ← create this (see Phase 1)
│   │
│   └── web/                       ← renamed from the Next.js sub-folder
│       ├── app/                   ← unchanged from current Next.js source
│       ├── components/            ← unchanged
│       ├── lib/                   ← unchanged
│       ├── public/                ← unchanged
│       ├── package.json           ← update name field only
│       └── .env.example           ← create this (see Phase 1)
│
├── supabase/
│   ├── migrations/                ← ALL SQL migration files go here
│   │   ├── 00_initial_schema.sql
│   │   ├── 01_rls_policies.sql
│   │   ├── 02_functions.sql
│   │   ├── 03_triggers.sql
│   │   └── 04_seed_question_bank.sql
│   ├── functions/                 ← Supabase Edge Functions
│   │   ├── compute-readiness-score/
│   │   │   └── index.ts
│   │   ├── batch-graduation/
│   │   │   └── index.ts
│   │   └── knowledge-ingest/
│   │       └── index.ts
│   ├── types/
│   │   └── database.types.ts      ← generated Supabase types, used by both apps
│   └── config.toml                ← Supabase local dev config
│
├── docs/
│   ├── README.md                  ← project overview (see Phase 1)
│   ├── architecture.md            ← system architecture (see Phase 1)
│   ├── user-flow.md               ← user flows per role (see Phase 1)
│   ├── readiness-score.md         ← formula and explanation (see Phase 1)
│   ├── batch-lifecycle.md         ← batch creation to graduation (see Phase 1)
│   ├── deployment.md              ← how to deploy both apps (see Phase 1)
│   └── contributing.md            ← how to contribute as a student maintainer
│
├── .github/
│   └── workflows/
│       ├── mobile-apk-release.yml  ← builds APK on tag push
│       └── web-deploy.yml          ← deploys Next.js to Vercel on main push
│
├── .gitignore                      ← root-level, covers both apps
└── README.md                       ← root readme, links to docs/
```

---

## 3. Domain & Hosting Configuration

- `app.psgmx.tech` → Flutter web build, hosted on Firebase Hosting (already configured in the Flutter repo's Firebase setup — preserve this)
- `psgmx.tech` → Next.js app, deployed to Vercel

Do not change any Firebase or Vercel configuration in the app code itself during Phase 1. This section is documentation only. Add both domain mappings to `docs/deployment.md`.

---

## 4. The Single Supabase Database — Complete Schema

This is the authoritative schema. In Phase 2, you will write SQL migration files that produce exactly this schema. **Do not deviate from this schema without adding a `TODO:` comment explaining why.**

Every table has Row Level Security enabled. Policies are written in `01_rls_policies.sql` and described for each table below.

### 4.1 Core Identity Tables

```sql
-- Batch records. One row per MCA intake year.
CREATE TABLE batches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_code TEXT NOT NULL UNIQUE,       -- e.g. '25MX', '26MX'
  start_date DATE NOT NULL,              -- e.g. 2025-06-01
  end_date DATE NOT NULL,                -- e.g. 2027-06-30
  status TEXT NOT NULL DEFAULT 'active_junior'
    CHECK (status IN ('active_junior', 'active_senior', 'graduated')),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- All users: students, alumni, faculty, HOD.
-- Students and alumni are identified by roll_no.
-- Faculty and HOD have NULL roll_no.
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL UNIQUE,
  full_name TEXT NOT NULL,
  roll_no TEXT UNIQUE,                   -- NULL for faculty/HOD/alumni without roll
  batch_id UUID REFERENCES batches(id),  -- NULL for faculty/HOD
  role TEXT NOT NULL DEFAULT 'student'
    CHECK (role IN ('student', 'alumni', 'faculty', 'hod')),
  app_role TEXT NOT NULL DEFAULT 'student'
    CHECK (app_role IN ('student', 'team_leader', 'coordinator', 'placement_rep')),
    -- app_role is only meaningful when role = 'student' or 'alumni'
  team_id UUID,                          -- FK added after teams table is created
  avatar_url TEXT,
  linkedin_url TEXT,
  current_company TEXT,                  -- filled in after graduation
  current_role_title TEXT,              -- filled in after graduation
  mentorship_open BOOLEAN DEFAULT false, -- alumni toggle
  onboarding_complete BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- RLS: users can read their own row. Faculty/HOD can read all rows in their scope.
-- Placement Reps can read all rows in their batch.
-- Alumni can read their own row only.

-- Teams within a batch. Created and managed by the Placement Rep.
CREATE TABLE teams (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id UUID NOT NULL REFERENCES batches(id),
  team_name TEXT NOT NULL,               -- e.g. 'Team Alpha', 'Team 1'
  target_size INTEGER NOT NULL DEFAULT 10,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Add FK back to users for team_id
ALTER TABLE users ADD CONSTRAINT users_team_id_fkey
  FOREIGN KEY (team_id) REFERENCES teams(id);

-- Granular permission flags per user.
-- Used to customize what a Coordinator or Team Leader can do beyond their base app_role.
CREATE TABLE user_permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  permission TEXT NOT NULL,
  -- Valid permissions:
  -- 'manage_members', 'configure_teams', 'schedule_sessions',
  -- 'publish_tasks', 'manage_company_records', 'moderate_placement_log',
  -- 'view_batch_analytics', 'mark_attendance_batch'
  granted_by UUID REFERENCES users(id),
  granted_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, permission)
);

-- Lineage map: auto-populated on user creation from roll_no suffix.
-- Links 25MX223 → 24MX223 → 23MX223 etc.
CREATE TABLE lineage_map (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  junior_user_id UUID NOT NULL REFERENCES users(id),
  senior_user_id UUID NOT NULL REFERENCES users(id),
  roll_suffix TEXT NOT NULL,             -- the shared numeric suffix e.g. '223'
  UNIQUE(junior_user_id, senior_user_id)
);
```

### 4.2 Placement Session Attendance (Mobile App)

```sql
-- Sessions scheduled by Placement Rep or Coordinators via Flutter app.
CREATE TABLE placement_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id UUID NOT NULL REFERENCES batches(id),
  scheduled_by UUID NOT NULL REFERENCES users(id),
  session_date DATE NOT NULL,
  session_time TIME NOT NULL,
  topic TEXT NOT NULL,
  target_scope TEXT NOT NULL DEFAULT 'batch'
    CHECK (target_scope IN ('batch', 'teams')),
    -- if 'teams', see placement_session_teams join table
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Which teams a session targets when target_scope = 'teams'
CREATE TABLE placement_session_teams (
  session_id UUID NOT NULL REFERENCES placement_sessions(id) ON DELETE CASCADE,
  team_id UUID NOT NULL REFERENCES teams(id),
  PRIMARY KEY (session_id, team_id)
);

-- Per-student attendance per session. Written by Team Leaders via Flutter app.
CREATE TABLE placement_attendance (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES placement_sessions(id),
  student_id UUID NOT NULL REFERENCES users(id),
  status TEXT NOT NULL DEFAULT 'absent'
    CHECK (status IN ('present', 'absent', 'excused')),
  marked_by UUID NOT NULL REFERENCES users(id), -- the Team Leader
  note TEXT,
  marked_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(session_id, student_id)
);
```

### 4.3 Daily Five Quiz (Mobile App)

```sql
-- Central question bank. Written by admins/coordinators, read by Flutter app.
CREATE TABLE question_bank (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  question_text TEXT NOT NULL,
  option_a TEXT NOT NULL,
  option_b TEXT NOT NULL,
  option_c TEXT NOT NULL,
  option_d TEXT NOT NULL,
  correct_option TEXT NOT NULL CHECK (correct_option IN ('a','b','c','d')),
  topic TEXT NOT NULL,
  -- Topics: 'aptitude', 'verbal', 'dsa', 'dbms', 'os', 'networks',
  --         'oop', 'python', 'java', 'hr_behavioral'
  difficulty TEXT NOT NULL DEFAULT 'medium'
    CHECK (difficulty IN ('easy', 'medium', 'hard')),
  is_active BOOLEAN DEFAULT true,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Per-student streak state. This is the ONLY daily-five data that persists.
-- Individual question responses are NEVER stored in this database.
CREATE TABLE daily_five_streaks (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  current_streak INTEGER NOT NULL DEFAULT 0,
  longest_streak INTEGER NOT NULL DEFAULT 0,
  freezes_remaining INTEGER NOT NULL DEFAULT 2,
  freezes_reset_month INTEGER,           -- month number (1-12) of last freeze reset
  last_completed_date DATE,
  total_days_completed INTEGER NOT NULL DEFAULT 0,
  running_accuracy_rate NUMERIC(5,2) NOT NULL DEFAULT 0.00,
  -- running_accuracy_rate = (total correct / total answered) * 100
  -- Updated as a running calculation each time a session completes.
  total_questions_answered INTEGER NOT NULL DEFAULT 0,
  total_questions_correct INTEGER NOT NULL DEFAULT 0,
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- RLS: users can only read and update their own row.
```

### 4.4 LeetCode Stats (Mobile App)

```sql
-- Synced from LeetCode public API by the Flutter app every 6 hours.
CREATE TABLE leetcode_stats (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  username TEXT,
  total_solved INTEGER NOT NULL DEFAULT 0,
  easy_solved INTEGER NOT NULL DEFAULT 0,
  medium_solved INTEGER NOT NULL DEFAULT 0,
  hard_solved INTEGER NOT NULL DEFAULT 0,
  -- Batch-period solved counts (from batch start_date to now)
  batch_easy_solved INTEGER NOT NULL DEFAULT 0,
  batch_medium_solved INTEGER NOT NULL DEFAULT 0,
  batch_hard_solved INTEGER NOT NULL DEFAULT 0,
  -- Batch-period weighted score = easy*1 + medium*2 + hard*3
  batch_weighted_score INTEGER NOT NULL DEFAULT 0,
  -- Percentile within own batch (0-100), recomputed by Edge Function
  batch_percentile NUMERIC(5,2) NOT NULL DEFAULT 0.00,
  weekly_solved INTEGER NOT NULL DEFAULT 0, -- problems solved in last 7 days
  ranking INTEGER,
  synced_at TIMESTAMPTZ DEFAULT now()
);
```

### 4.5 Tasks (Mobile App)

```sql
-- Daily tasks published by Placement Rep or Coordinators.
CREATE TABLE daily_tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id UUID NOT NULL REFERENCES batches(id),
  task_date DATE NOT NULL,
  task_type TEXT NOT NULL CHECK (task_type IN ('leetcode', 'core_subject')),
  title TEXT NOT NULL,
  description TEXT,
  reference_url TEXT,
  subject TEXT,                          -- for core_subject type
  published_by UUID NOT NULL REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(batch_id, task_date, task_type)
);

-- Student task completion records.
CREATE TABLE task_completions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id UUID NOT NULL REFERENCES daily_tasks(id),
  student_id UUID NOT NULL REFERENCES users(id),
  completed BOOLEAN NOT NULL DEFAULT false,
  completed_at TIMESTAMPTZ,
  verified_by UUID REFERENCES users(id), -- Team Leader who verified
  verified_at TIMESTAMPTZ,
  UNIQUE(task_id, student_id)
);
```

### 4.6 Placement Log (Mobile App writes, Web reads)

```sql
-- Company visit records. Created by Placement Rep via Flutter app.
CREATE TABLE companies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id UUID NOT NULL REFERENCES batches(id),
  company_name TEXT NOT NULL,
  visit_date DATE NOT NULL,
  roles_offered TEXT[],                  -- array of role names
  package_band_min NUMERIC(10,2),        -- in LPA
  package_band_max NUMERIC(10,2),        -- in LPA
  eligibility_criteria TEXT,
  rounds TEXT[],                         -- e.g. ['Online Test', 'Technical', 'HR']
  logged_by UUID NOT NULL REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Personal experience writeups by second-year students.
-- Flows into Knowledge Brain on Next.js after faculty approval.
CREATE TABLE placement_log_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  student_id UUID NOT NULL REFERENCES users(id),
  round_name TEXT NOT NULL,
  experience_text TEXT NOT NULL,
  is_anonymous BOOLEAN DEFAULT false,
  approval_status TEXT NOT NULL DEFAULT 'pending'
    CHECK (approval_status IN ('pending', 'approved', 'rejected')),
  approved_by UUID REFERENCES users(id), -- faculty member
  approved_at TIMESTAMPTZ,
  kb_article_id UUID,                    -- FK to knowledge_brain_articles once ingested
  created_at TIMESTAMPTZ DEFAULT now()
);
```

### 4.7 Readiness Score (Computed by Supabase Edge Function)

```sql
-- Current score per student. Updated within 60 seconds of any contributing event.
CREATE TABLE readiness_scores (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  score NUMERIC(5,2) NOT NULL DEFAULT 0.00,   -- 0 to 100
  -- Component scores (each 0 to their max)
  daily_five_score NUMERIC(5,2) DEFAULT 0.00, -- max 30
  leetcode_score NUMERIC(5,2) DEFAULT 0.00,   -- max 25
  mock_exam_score NUMERIC(5,2) DEFAULT 0.00,  -- max 35
  session_score NUMERIC(5,2) DEFAULT 0.00,    -- max 10
  -- Band for quick filtering
  band TEXT GENERATED ALWAYS AS (
    CASE
      WHEN score >= 80 THEN 'strong'
      WHEN score >= 60 THEN 'building'
      WHEN score >= 40 THEN 'needs_attention'
      ELSE 'at_risk'
    END
  ) STORED,
  computed_at TIMESTAMPTZ DEFAULT now()
);

-- Daily snapshots for trend analysis.
CREATE TABLE readiness_score_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  score NUMERIC(5,2) NOT NULL,
  daily_five_score NUMERIC(5,2),
  leetcode_score NUMERIC(5,2),
  mock_exam_score NUMERIC(5,2),
  session_score NUMERIC(5,2),
  snapshot_date DATE NOT NULL DEFAULT CURRENT_DATE,
  UNIQUE(user_id, snapshot_date)
);
```

### 4.8 Knowledge Brain (Web App writes, shared)

```sql
-- Faculty-approved articles, guides, and interview experiences.
-- Some rows originate from placement_log_entries (source='flutter').
-- Some are written directly on the web platform (source='web').
CREATE TABLE knowledge_brain_articles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  summary TEXT,                          -- 2-3 sentence summary for AI context
  author_id UUID REFERENCES users(id),
  source TEXT NOT NULL DEFAULT 'web'
    CHECK (source IN ('web', 'flutter_placement_log')),
  placement_log_entry_id UUID REFERENCES placement_log_entries(id),
  tags TEXT[],
  company_name TEXT,                     -- if interview-experience article
  batch_year TEXT,                       -- e.g. '25MX' for batch context
  approval_status TEXT NOT NULL DEFAULT 'pending'
    CHECK (approval_status IN ('pending', 'approved', 'rejected')),
  approved_by UUID REFERENCES users(id),
  approved_at TIMESTAMPTZ,
  view_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- pgvector embeddings for semantic search.
-- Requires: CREATE EXTENSION vector; in Supabase (enable via dashboard).
CREATE TABLE knowledge_embeddings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  article_id UUID NOT NULL REFERENCES knowledge_brain_articles(id) ON DELETE CASCADE,
  chunk_index INTEGER NOT NULL DEFAULT 0, -- for multi-chunk articles
  chunk_text TEXT NOT NULL,
  embedding vector(1536),                 -- OpenAI text-embedding-3-small dimension
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(article_id, chunk_index)
);

CREATE INDEX knowledge_embeddings_vector_idx
  ON knowledge_embeddings
  USING ivfflat (embedding vector_cosine_ops)
  WITH (lists = 100);
```

### 4.9 Mock Examinations (Web App)

```sql
-- Exam definitions created by faculty on the web platform.
CREATE TABLE mock_exams (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT,
  target_batch_id UUID REFERENCES batches(id), -- NULL = all active batches
  created_by UUID NOT NULL REFERENCES users(id),
  scheduled_at TIMESTAMPTZ NOT NULL,
  duration_minutes INTEGER NOT NULL DEFAULT 60,
  total_marks INTEGER NOT NULL DEFAULT 100,
  proctoring_level TEXT NOT NULL DEFAULT 'standard'
    CHECK (proctoring_level IN ('standard', 'strict')),
    -- standard: camera + tab detection
    -- strict: camera + tab detection + fullscreen enforcement
  status TEXT NOT NULL DEFAULT 'draft'
    CHECK (status IN ('draft', 'published', 'active', 'completed')),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Individual questions within a mock exam.
CREATE TABLE mock_exam_questions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  exam_id UUID NOT NULL REFERENCES mock_exams(id) ON DELETE CASCADE,
  question_text TEXT NOT NULL,
  question_type TEXT NOT NULL DEFAULT 'mcq'
    CHECK (question_type IN ('mcq', 'coding', 'short_answer')),
  option_a TEXT,
  option_b TEXT,
  option_c TEXT,
  option_d TEXT,
  correct_option TEXT,                   -- for mcq
  marks INTEGER NOT NULL DEFAULT 1,
  order_index INTEGER NOT NULL,
  UNIQUE(exam_id, order_index)
);

-- Per-student results for each exam.
CREATE TABLE mock_exam_results (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  exam_id UUID NOT NULL REFERENCES mock_exams(id),
  student_id UUID NOT NULL REFERENCES users(id),
  score NUMERIC(5,2) NOT NULL DEFAULT 0.00, -- 0 to 100 (normalized percentage)
  raw_marks INTEGER NOT NULL DEFAULT 0,
  submitted_at TIMESTAMPTZ DEFAULT now(),
  time_taken_seconds INTEGER,
  proctoring_flags JSONB DEFAULT '[]',   -- array of detected violations
  -- e.g. [{"type":"tab_switch","timestamp":"..."},{"type":"camera_loss","timestamp":"..."}]
  UNIQUE(exam_id, student_id)
);

-- RLS: students can only read their own results. Faculty can read all.
```

### 4.10 Notifications and Announcements (Both Apps)

```sql
CREATE TABLE announcements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id UUID REFERENCES batches(id),  -- NULL = all batches
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  posted_by UUID NOT NULL REFERENCES users(id),
  is_pinned BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  -- Types: 'exam_scheduled', 'streak_nudge', 'announcement',
  --        'session_reminder', 'session_marked', 'graduation',
  --        'lineage_senior_active', 'article_approved'
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  is_read BOOLEAN DEFAULT false,
  reference_id UUID,                     -- optional FK to related record
  reference_type TEXT,                   -- e.g. 'mock_exam', 'placement_session'
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX notifications_user_unread_idx
  ON notifications(user_id, is_read, created_at DESC)
  WHERE is_read = false;
```

### 4.11 Alumni and HOD (Web App)

```sql
-- Collaboration marketplace posts by alumni or students.
CREATE TABLE collaboration_posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  posted_by UUID NOT NULL REFERENCES users(id),
  post_type TEXT NOT NULL CHECK (post_type IN ('job', 'project', 'mentorship')),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  visibility TEXT NOT NULL DEFAULT 'batch'
    CHECK (visibility IN ('lineage_only', 'batch', 'department')),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Lineage messages between alumni and their matched junior students.
CREATE TABLE lineage_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id UUID NOT NULL REFERENCES users(id),
  receiver_id UUID NOT NULL REFERENCES users(id),
  message_text TEXT NOT NULL,
  is_read BOOLEAN DEFAULT false,
  sent_at TIMESTAMPTZ DEFAULT now()
);

-- Audit log for all sensitive actions.
CREATE TABLE audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id UUID REFERENCES users(id),
  action TEXT NOT NULL,
  target_table TEXT,
  target_id UUID,
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT now()
);
```

---

## 5. Supabase Edge Functions

Write these three Edge Functions in `supabase/functions/`. Use Deno (Supabase's runtime). Do not use Node.js.

### 5.1 `compute-readiness-score/index.ts`

This function is called by a database trigger whenever any of these tables change: `daily_five_streaks`, `leetcode_stats`, `mock_exam_results`, `placement_attendance`. It receives a `user_id` in the request body, computes the readiness score for that user, and upserts the result into `readiness_scores`. It also writes a daily snapshot to `readiness_score_history` (upsert on `user_id` + `snapshot_date`).

**The formula, implemented exactly as follows:**

```
daily_five_score = clamp(
  (streak.running_accuracy_rate * 0.10 * 100) +
  (adherence_rate_last_90_days * 0.20 * 100),
  0, 30
)
-- adherence_rate_last_90_days = total_days_completed in last 90 eligible days / 90

leetcode_score = clamp(
  batch_percentile * 0.25,
  0, 25
)
-- batch_percentile comes from leetcode_stats.batch_percentile
-- batch_percentile is recomputed separately (see below)

mock_exam_score = clamp(
  weighted_avg_exam_score * 0.35,
  0, 35
)
-- weighted_avg_exam_score: for each exam result, weight = 1.0 if submitted within 30 days,
-- 0.7 if 30-90 days ago, 0.4 if older. Compute weighted average of score across all results.
-- If no exams taken, mock_exam_score = 0.

session_score = clamp(
  (sessions_attended / max(sessions_eligible, 1)) * 10,
  0, 10
)
-- sessions_attended: count of placement_attendance rows WHERE student_id=user_id
--   AND status IN ('present','excused')
-- sessions_eligible: count of placement_sessions the student was targeted for

total_score = daily_five_score + leetcode_score + mock_exam_score + session_score
```

After computing, also recompute `batch_percentile` for ALL students in the same batch whenever `leetcode_stats` changes for any student in that batch. Batch percentile = rank of this student's `batch_weighted_score` among all students in the same batch, expressed as 0-100.

### 5.2 `batch-graduation/index.ts`

This function runs on a CRON schedule (configure in `config.toml` as `0 0 1 6 *` — midnight on June 1st). It does the following in one database transaction:

1. Query `batches` where `status != 'graduated'` and `end_date <= CURRENT_DATE`.
2. For each such batch: set `status = 'graduated'`.
3. For each user in that batch: set `role = 'alumni'` and `app_role = 'student'` (alumni have no placement app_role).
4. Insert a notification of type `'graduation'` for every user in that batch.
5. Set the most junior `active_junior` batch to `active_senior` if it exists.
6. Log the action in `audit_logs`.

Write this as a transaction — if any step fails, roll back all changes.

### 5.3 `knowledge-ingest/index.ts`

This function is called by a database trigger on `placement_log_entries` when `approval_status` changes to `'approved'`. It:

1. Reads the approved placement log entry.
2. Creates a `knowledge_brain_articles` row with `source = 'flutter_placement_log'`, `approval_status = 'approved'`, and `approved_at = now()`.
3. Chunks the `experience_text` into segments of max 500 characters (splitting at sentence boundaries).
4. For each chunk, calls the Supabase AI embedding API (`Supabase.ai.Session` with `gte-small` model, which is available natively in Edge Functions without an external API key) and inserts the resulting embedding into `knowledge_embeddings`.
5. Updates `placement_log_entries.kb_article_id` with the new article's ID.

Use the native Supabase AI embedding: `const model = new Supabase.ai.Session('gte-small')` — this does not require an OpenAI key.

---

## 6. Database Triggers

Write these in `supabase/migrations/03_triggers.sql`:

```sql
-- Trigger 1: After insert/update on daily_five_streaks, invoke compute-readiness-score
-- Trigger 2: After insert/update on leetcode_stats, invoke compute-readiness-score
-- Trigger 3: After insert on mock_exam_results, invoke compute-readiness-score
-- Trigger 4: After insert/update on placement_attendance, invoke compute-readiness-score
-- Trigger 5: After update on placement_log_entries WHERE approval_status='approved',
--            invoke knowledge-ingest
-- Trigger 6: After insert on users, auto-build lineage_map rows by matching roll_no suffix:
--            e.g. '25MX223' → find user with roll_no ending in 'MX223' in prior batches
--            Insert lineage_map(junior_user_id=new.id, senior_user_id=senior.id,
--            roll_suffix=<shared suffix>)
-- Trigger 7: After update on users WHERE role changes to 'alumni',
--            set mentorship_open=false (default off, alumni must actively opt in)
```

---

## 7. Row Level Security Policies — Key Rules

Write the full SQL in `supabase/migrations/01_rls_policies.sql`. These are the rules, not the SQL itself — you write the SQL:

- Any authenticated user can read `batches`, `question_bank` (active only), `announcements`, `companies`, `knowledge_brain_articles` (approved only).
- A student can read and write their own rows in: `daily_five_streaks`, `leetcode_stats`, `task_completions`, `placement_attendance` (read only), `readiness_scores` (read only), `notifications`, `placement_log_entries` (own rows only).
- A Team Leader additionally can write `placement_attendance` for students in their team only.
- A Coordinator additionally can write `placement_sessions`, `daily_tasks` for their batch.
- A Placement Rep can read and write everything within their batch.
- Faculty can read all student data. Faculty cannot write student data. Faculty can write `mock_exams`, `mock_exam_questions`, approve `knowledge_brain_articles`, approve `placement_log_entries`.
- HOD can read all data in a read-only aggregate view. HOD cannot write anything except their own profile.
- Alumni can read `knowledge_brain_articles`, `companies`, `placement_log_entries`. Alumni can write their own `knowledge_brain_articles` (pending approval). Alumni can write `lineage_messages` where they are the sender. Alumni can read `lineage_messages` where they are sender or receiver.
- No user can read another user's `mock_exam_results` except faculty and HOD.
- No user can read another user's `daily_five_streaks` component breakdown except faculty and HOD (students see only their own).

---

## 8. Phase-by-Phase Execution Plan

---

### PHASE 1 — Repository Restructure & Documentation

**Do this first. Do not touch any application code yet.**

**Step 1.1 — Identify and rename the two sub-folders**
Scan the root of the `psgmx/` directory. Find the Flutter project (has `pubspec.yaml`) and the Next.js project (has `package.json` with a Next.js dependency). Rename the Flutter folder to `apps/mobile` and the Next.js folder to `apps/web`. Preserve all file contents and Git history if possible (use `git mv` if Git is initialized at the root, otherwise a standard rename is fine).

**Step 1.2 — Create the monorepo scaffold**
Create every folder in the target structure from Section 2 that does not already exist. Create empty placeholder files with a `# TODO: fill this in` comment for: `supabase/migrations/`, `supabase/functions/`, `supabase/types/database.types.ts`, `supabase/config.toml`.

**Step 1.3 — Create `.env.example` files**

For `apps/mobile/.env.example`:
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
ECAMPUS_API_URL=https://your-ecampus-api.render.com
ECAMPUS_API_SECRET=your-secret
OPENROUTER_API_KEY=your-openrouter-key
LEETCODE_API_URL=https://leetcode.com/graphql
```

For `apps/web/.env.example`:
```
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
GEMINI_API_KEY=your-gemini-key
OPENROUTER_API_KEY=your-openrouter-key
JWT_SECRET=your-jwt-secret
NEXT_PUBLIC_APP_URL=https://psgmx.tech
MOBILE_APP_URL=https://app.psgmx.tech
```

**Step 1.4 — Update `package.json` and `pubspec.yaml` names only**
In `apps/web/package.json`, set `"name": "psgmx-web"`. In `apps/mobile/pubspec.yaml`, set `name: psgmx_mobile`. Do not change any other fields.

**Step 1.5 — Write all documentation files**

Write `docs/README.md` with: what PSGMX is, the two-app mental model (daily mobile app / intentional web platform), who uses each, the GitHub APK link placeholder, the two domain names.

Write `docs/architecture.md` with: the single-Supabase architecture, the two apps, the three Edge Functions, the domain setup, a simple ASCII diagram of the data flow.

Write `docs/user-flow.md` with: plain-language paragraphs for each user type (First-Year Student, Second-Year Student, Team Leader, Coordinator, Placement Rep, Faculty, Alumni, HOD) based on the flow described in this document.

Write `docs/readiness-score.md` with: the four inputs, the exact formula from Section 4.7 / Edge Function 5.1, the score bands, who can see what.

Write `docs/batch-lifecycle.md` with: how a batch is created, the two active years, the graduation trigger, what happens to each user type on graduation.

Write `docs/deployment.md` with: Flutter APK build and GitHub Release process, Firebase Hosting setup for `app.psgmx.tech`, Vercel deployment for `psgmx.tech`, Supabase project setup steps, Edge Function deployment commands.

Write `docs/contributing.md` with: how a future student maintainer can contribute, the PR process, where to find the Supabase schema, how to add questions to the question bank.

Write the root `README.md` with: a one-paragraph description and links to `docs/`.

**Step 1.6 — Write root `.gitignore`**
Cover: `node_modules/`, `.dart_tool/`, `build/`, `.env`, `.env.local`, `*.g.dart`, `.supabase/`, `supabase/.branches/`, `supabase/.temp/`, `.vercel/`.

**Step 1.7 — Write GitHub Actions workflows**

`mobile-apk-release.yml`: triggers on `push` to tags matching `v*`. Checks out the repo, sets up Flutter, runs `flutter build apk --release` in `apps/mobile/`, uploads the APK as a GitHub Release asset.

`web-deploy.yml`: triggers on `push` to `main`. Sets up Node.js 20, runs `npm ci` and `npm run build` in `apps/web/`. No actual Vercel deploy step needed — Vercel's GitHub integration handles this automatically. This workflow just verifies the build passes.

**Phase 1 Completion Checklist:**
- [ ] `apps/mobile/` exists and contains the Flutter project
- [ ] `apps/web/` exists and contains the Next.js project
- [ ] `supabase/` folder exists with correct sub-structure
- [ ] All 6 docs files exist and have real content
- [ ] Root README exists
- [ ] Both `.env.example` files exist
- [ ] Both GitHub Actions workflow files exist
- [ ] No application code has been changed

---

### PHASE 2 — Supabase Schema (Single Database)

**Do not touch Flutter or Next.js app code yet. Only write SQL.**

**Step 2.1 — Enable extensions**
At the top of `00_initial_schema.sql`:
```sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "vector";
```

**Step 2.2 — Write `00_initial_schema.sql`**
Write the complete CREATE TABLE statements from Section 4, in dependency order (parent tables before child tables). Every table must have `created_at TIMESTAMPTZ DEFAULT now()`. Every table must have a `UUID PRIMARY KEY DEFAULT gen_random_uuid()` unless the spec says otherwise. Add all indexes listed.

**Step 2.3 — Write `01_rls_policies.sql`**
Enable RLS on every table: `ALTER TABLE <name> ENABLE ROW LEVEL SECURITY;`. Write one policy per operation (SELECT, INSERT, UPDATE, DELETE) per role scenario. Follow the rules in Section 7.

**Step 2.4 — Write `02_functions.sql`**
Write two helper SQL functions:
- `get_user_role(user_id UUID)`: returns the `role` and `app_role` for a user, used in RLS policies
- `get_batch_for_user(user_id UUID)`: returns the `batch_id` for a student user

**Step 2.5 — Write `03_triggers.sql`**
Write all 7 triggers listed in Section 6. Each trigger that calls an Edge Function must use `net.http_post` (Supabase's built-in HTTP extension) to call the function URL. Store the function URLs as Supabase secrets, referenced via `current_setting('app.edge_function_url_' || function_name)`.

**Step 2.6 — Write `04_seed_question_bank.sql`**
Insert 50 seed questions across all topics listed in the `question_bank` schema. Distribute them: 10 aptitude, 10 verbal, 10 DSA, 5 DBMS, 5 OS, 5 networks, 5 OOP/Python/Java mixed. All 50 questions must be real, correct questions with four plausible options and one clearly correct answer. Do not generate placeholder questions like "Question 1 goes here". If you are unsure about a question's correctness, mark it with a `TODO:` SQL comment.

**Step 2.7 — Write `supabase/config.toml`**
Standard Supabase local development config. Set the project ID field to a placeholder `"psgmx-local"`. Configure the `batch-graduation` Edge Function with the CRON schedule `"0 0 1 6 *"`.

**Step 2.8 — Generate `supabase/types/database.types.ts`**
Write this file manually based on the schema (the `supabase gen types` command would normally produce it, but write it by hand for now with correct TypeScript interfaces for every table). This file is imported by both `apps/mobile` (if building Flutter web) and `apps/web`.

**Phase 2 Completion Checklist:**
- [ ] All 5 migration files exist and have correct SQL
- [ ] Every table from Section 4 is created
- [ ] Every table has RLS enabled
- [ ] All 7 triggers are written
- [ ] 50 seed questions exist
- [ ] `database.types.ts` has interfaces for every table
- [ ] Running `supabase db reset` locally produces no errors

---

### PHASE 3 — Next.js Web App: Remove MongoDB, Connect Supabase

**This is the most significant migration. Work through it carefully.**

**Step 3.1 — Remove MongoDB dependencies**
In `apps/web/package.json`, remove: `mongoose`, `mongodb`, any `@types/mongoose`. Run `npm uninstall mongoose mongodb` in `apps/web/`. Do not delete these from `package.json` manually — use the uninstall command so `package-lock.json` stays correct.

**Step 3.2 — Remove all Mongoose model files**
Delete every file in `apps/web/models/` (or wherever Mongoose schemas are defined). Before deleting, read each file and create a mapping note in a temporary file `apps/web/MIGRATION_NOTES.md` that maps each old Mongoose collection to the corresponding Supabase table from Section 4. This mapping is for your own reference during Step 3.3.

The mappings are:
- `UserAccount` → `users` + `user_permissions`
- `Department` → `batches` (department is implicit, always MCA)
- `FYPRepository` → not in scope for this phase, mark as TODO
- `KnowledgeBrainArticle` → `knowledge_brain_articles` + `knowledge_embeddings`
- `KnowledgeGraphEdge` → not in scope, mark as TODO
- `AiInteractionLog` → not in scope (faculty analytics), mark as TODO
- `AiMemory` → not in scope, mark as TODO
- `PromptRegistry` → not in scope, mark as TODO
- `LineageMessage` → `lineage_messages`
- `UserEvent` → `audit_logs`
- `UserFeedback` → not in scope, mark as TODO
- `TokenAuditLog` → `audit_logs`

**Step 3.3 — Remove MongoDB connection code**
Find and delete the MongoDB connection file (usually `lib/db.ts`, `lib/mongodb.ts`, or `utils/dbConnect.ts`). Find every file in `apps/web/` that imports from this connection file or from `mongoose` and rewrite the data access layer for that file to use Supabase instead. Use the `@supabase/supabase-js` client.

**Step 3.4 — Install Supabase client**
```
cd apps/web && npm install @supabase/supabase-js @supabase/ssr
```

**Step 3.5 — Create Supabase client utilities**

Create `apps/web/lib/supabase/client.ts` — the browser-side Supabase client:
```typescript
import { createBrowserClient } from '@supabase/ssr'
export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  )
}
```

Create `apps/web/lib/supabase/server.ts` — the server-side Supabase client (uses cookies for session):
```typescript
import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'
export async function createClient() {
  const cookieStore = await cookies()
  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    { cookies: { getAll() { return cookieStore.getAll() }, setAll(c) { ... } } }
  )
}
```

Create `apps/web/lib/supabase/admin.ts` — the service-role client for server-only operations (never exposed to browser):
```typescript
import { createClient } from '@supabase/supabase-js'
export const supabaseAdmin = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
)
```

**Step 3.6 — Replace authentication**
The current Next.js app uses custom JWT with bcrypt. Replace this with Supabase Auth entirely. Supabase Auth handles OTP email delivery, session management, and JWT validation. Remove the `bcryptjs` dependency and the custom JWT middleware. Replace with Supabase's `middleware.ts` pattern using `@supabase/ssr`.

The authentication flow for the web platform: user enters their email → Supabase sends OTP → user enters OTP → session created. Faculty and HOD accounts are invited via Supabase's `inviteUserByEmail` admin function (not self-signup — only `@psgtech.ac.in` emails are allowed, enforced by a `CHECK` constraint and a Supabase Auth hook).

**Step 3.7 — Rewrite data access layer**
For each API route or server action that previously queried MongoDB, rewrite it to query Supabase. Follow the naming conventions:
- Use the server-side Supabase client in Server Components and API routes
- Use the browser-side client in Client Components
- Use the admin client only when bypassing RLS is required (e.g., computing readiness scores, graduation trigger)

**Step 3.8 — Preserve all existing UI components**
Do not change any React component that doesn't need to change for the database migration. Only change files that directly interact with the data layer. The visual UI, animations, and layouts all stay as they are.

**Step 3.9 — Update authentication middleware**
Replace `apps/web/middleware.ts` with the standard Supabase SSR middleware that refreshes sessions. Preserve existing route protection logic (which routes require which roles) — just replace the JWT verification with Supabase session verification.

**Step 3.10 — Remove `MIGRATION_NOTES.md`**
Once Phase 3 is complete and verified, delete this temporary file.

**Phase 3 Completion Checklist:**
- [ ] `mongoose` and `mongodb` are not in `package.json`
- [ ] No file in `apps/web/` imports from `mongoose`
- [ ] `apps/web/lib/supabase/client.ts`, `server.ts`, `admin.ts` exist
- [ ] Authentication uses Supabase OTP, not bcrypt/JWT
- [ ] `middleware.ts` uses Supabase session, not custom JWT
- [ ] `npm run build` in `apps/web/` completes with no errors
- [ ] The web app can log in and display data from Supabase

---

### PHASE 4 — Flutter App: Align to New Schema

**The Flutter app already uses Supabase. This phase updates it to match the new schema from Phase 2.**

**Step 4.1 — Audit existing Supabase queries**
Read every file in `apps/mobile/lib/services/` and `apps/mobile/lib/providers/`. List every Supabase table name referenced. Compare against the Phase 2 schema. For each mismatch (a table that was renamed, a column that was added or renamed), note the change needed.

**Step 4.2 — Update table and column references**
Make the minimal changes needed to align the Flutter app's queries to the Phase 2 schema. Common changes expected:
- `attendance_records` likely becomes `placement_attendance` + `placement_sessions`
- The `users` table gains new columns (`app_role`, `batch_id`, `team_id`)
- `daily_tasks` gains `batch_id`
- `leetcode_stats` gains `batch_easy_solved`, `batch_medium_solved`, `batch_hard_solved`, `batch_weighted_score`, `batch_percentile`
- `daily_five_streaks` is a new table that replaces whatever streak tracking currently exists

**Step 4.3 — Remove the ecampus eCampus-to-readiness connection**
The existing Flutter app may include eCampus CA marks or academic attendance in readiness-adjacent features. Confirm that eCampus data (academic attendance, CGPA, CA marks) is displayed only in the Campus tab and is never used as an input to `readiness_scores`. Add a code comment wherever eCampus data is displayed confirming it is informational only.

**Step 4.4 — Implement Daily Five streak sync**
The Flutter app manages streak state locally (Drift/SQLite). On app open, it must:
1. Read `daily_five_streaks` from Supabase for the current user.
2. Check if `last_completed_date = CURRENT_DATE`. If yes, streak already done today, show locked state.
3. If the student completes the daily five, call the readiness score Edge Function immediately after updating `daily_five_streaks`.
4. On month change, reset `freezes_remaining` to 2 (check `freezes_reset_month` vs current month).

**Step 4.5 — Implement the readiness score home screen gauge**
The home screen reads `readiness_scores` for the current user from Supabase (no computation — just read the pre-computed value). Subscribe to real-time changes on this row so the gauge updates without a page refresh when a mock exam result is written by the web platform.

**Step 4.6 — Implement the leaderboard queries**
Two leaderboard queries, both scoped to the student's own `batch_id`:
- Readiness leaderboard: `SELECT users.full_name, readiness_scores.score FROM readiness_scores JOIN users ON users.id = readiness_scores.user_id WHERE users.batch_id = $batchId ORDER BY score DESC LIMIT 20`
- LeetCode leaderboard: `SELECT users.full_name, leetcode_stats.batch_weighted_score, leetcode_stats.batch_percentile FROM leetcode_stats JOIN users ON users.id = leetcode_stats.user_id WHERE users.batch_id = $batchId ORDER BY batch_weighted_score DESC LIMIT 20`

**Step 4.7 — Implement the lineage card on the Profile screen**
On profile screen load, query `lineage_map` where `junior_user_id = currentUser.id`. If a row exists, query `users` for the `senior_user_id`. If that user has `mentorship_open = true`, display the "Your Senior" card with their name, current_company, current_role_title, and linkedin_url. If no match or mentorship not open, display nothing (no "no senior found" message — just absent).

**Phase 4 Completion Checklist:**
- [ ] All Supabase table references in Flutter match Phase 2 schema
- [ ] eCampus data is confirmed informational-only (no readiness input)
- [ ] Daily Five streak syncs correctly to `daily_five_streaks`
- [ ] Readiness gauge reads from `readiness_scores` with real-time subscription
- [ ] Both leaderboards are batch-scoped
- [ ] Lineage card shows when a senior exists with mentorship open
- [ ] Flutter app builds for Android and Web with no errors

---

### PHASE 5 — Edge Functions

**Write the three Edge Functions from Section 5.**

**Step 5.1 — `compute-readiness-score`**
Implement the exact formula from Section 5.1. Handle the case where a user has zero sessions eligible (session_score = 0, not a division error). Handle the case where no mock exams have been taken (mock_exam_score = 0). Handle the case where `daily_five_streaks` row doesn't exist yet for a new user (all daily_five inputs = 0). Test with a manually inserted user before wiring up the trigger.

**Step 5.2 — `batch-graduation`**
Implement the graduation transaction from Section 5.2. Add comprehensive logging to `audit_logs` for every batch transitioned. Test by creating a test batch with an `end_date` of yesterday and invoking the function manually.

**Step 5.3 — `knowledge-ingest`**
Implement the ingestion flow from Section 5.3 using Supabase's native AI embedding (`Supabase.ai.Session('gte-small')`). Chunk text at sentence boundaries (split on `. `, `! `, `? `) with max 500 characters per chunk. Test by approving a test placement_log_entry and confirming an embedding is written to `knowledge_embeddings`.

**Step 5.4 — AI Senior RAG query (web platform API route)**
In `apps/web/app/api/ai-senior/query/route.ts`, implement the RAG pipeline:
1. Receive user question in request body.
2. Generate embedding for the question using the same `gte-small` model (call Supabase's embedding endpoint from server side).
3. Run a vector similarity query against `knowledge_embeddings` using `<=>` cosine distance operator. Return top 3 chunks where similarity < 0.3 (closer = more similar in cosine distance).
4. Assemble a prompt: system context = "You are the AI Senior for PSG Tech MCA students. Answer using only the provided knowledge base excerpts. If the excerpts don't cover the question, say so." + the 3 chunks as context.
5. Call Gemini 2.5 Flash as primary (via `@google/generative-ai`). If it fails or times out at 8 seconds, fall back to OpenRouter with `claude-3-haiku` model. If that also fails, return a plain text fallback: "I couldn't find a specific answer in the knowledge base right now. Try searching the Knowledge Brain directly."
6. Return the AI response.

**Phase 5 Completion Checklist:**
- [ ] `compute-readiness-score` deploys without error and returns correct scores for test users
- [ ] `batch-graduation` transitions a test batch correctly and inserts notifications
- [ ] `knowledge-ingest` creates articles and embeddings correctly
- [ ] AI Senior query returns grounded responses when matching articles exist
- [ ] AI Senior returns the fallback message gracefully when the AI call fails

---

### PHASE 6 — New Features: Build What's Missing

These features exist in the spec but may not be fully built yet in either existing codebase. Build them after Phases 1–5 are stable.

**Step 6.1 — Batch onboarding calibration (Flutter)**
After OTP verification, if `users.onboarding_complete = false`, show the 3-question calibration flow (Section 2, Screen 7 in the design doc). Store answers locally, compute starting readiness score inputs, upsert into `daily_five_streaks` (with zeroed running_accuracy_rate), `leetcode_stats` (with user-estimated batch counts), and call `compute-readiness-score`. Set `onboarding_complete = true`. This runs once per user.

**Step 6.2 — Graduation screen (Flutter)**
On app open, if the current user's batch has `status = 'graduated'` and `users.role = 'alumni'`, show the graduation screen (not the home screen). The graduation screen reads: `readiness_score_history` for the final score, `daily_five_streaks.longest_streak`, `leetcode_stats.batch_weighted_score`, count of `mock_exam_results` for the user. After the student taps through the screen, set a local flag so it shows only once, then show the read-only archive home screen.

**Step 6.3 — Mock exam proctoring (Next.js)**
Build the exam-taking UI at `apps/web/app/exam/[examId]/page.tsx`. Requirements:
- Request `getUserMedia({ video: true })` on exam start. If denied, block entry with a clear message.
- Use `document.addEventListener('visibilitychange')` to detect tab switching. On each switch, insert a proctoring flag into `mock_exam_results.proctoring_flags`.
- Randomize question order: fetch all `mock_exam_questions` for the exam, shuffle using the student's `user_id` as a seed (deterministic shuffle per student, so refreshing doesn't re-shuffle).
- Auto-submit when the countdown timer reaches zero.
- On submit, write to `mock_exam_results`. The database trigger fires `compute-readiness-score` automatically.

**Step 6.4 — Knowledge Brain search (Next.js)**
Build search at `apps/web/app/knowledge/search/route.ts`. Accept a query string. Generate embedding → cosine similarity query on `knowledge_embeddings` → return matching `knowledge_brain_articles`. Also support plain-text keyword search using PostgreSQL's `tsvector` (add a generated `tsvector` column to `knowledge_brain_articles` in a new migration `05_search_index.sql`).

**Step 6.5 — Alumni features (Next.js)**
Build the alumni dashboard at `apps/web/app/alumni/`. It should show: their historical readiness score, their contribution count to the Knowledge Brain, their lineage connections (which current students they're linked to), and the Collaboration Marketplace. Mentorship toggle writes to `users.mentorship_open`.

**Phase 6 Completion Checklist:**
- [ ] Onboarding calibration runs on first Flutter login and sets initial readiness score
- [ ] Graduation screen appears correctly for graduated batch users
- [ ] Mock exam blocks entry without camera, detects tab switches, auto-submits on timer
- [ ] Knowledge Brain semantic search returns relevant results
- [ ] Alumni dashboard shows history and lineage connections
- [ ] Alumni mentorship toggle causes "Your Senior" card to appear in Flutter for matched juniors

---

### PHASE 7 — Final Verification & Documentation Update

**Step 7.1 — End-to-end test scenario**
Execute this test scenario manually:
1. Create a test batch `99MX` with `start_date = today - 730 days` and `end_date = today - 1 day`.
2. Create two test student users in `99MX` with roll numbers `99MX001` and `99MX002`.
3. Create a junior test batch `00MX` with a student `00MX001`.
4. Verify that lineage_map correctly links `00MX001` → `99MX001`.
5. Manually invoke `batch-graduation`. Verify: `99MX.status = 'graduated'`, both users `role = 'alumni'`, both received a graduation notification.
6. Open Flutter as `00MX001`. Verify "Your Senior" card appears if `99MX001.mentorship_open = true`.
7. Submit a mock exam for `00MX001`. Verify readiness score updates within 60 seconds.
8. Submit a placement log entry, approve it as faculty. Verify Knowledge Brain article is created with embeddings.
9. Query AI Senior with a question about the logged company. Verify the grounded response uses the article content.
10. Delete all test data.

**Step 7.2 — Update `docs/deployment.md`**
Add the exact commands needed to deploy after Phase 7: `supabase db push`, `supabase functions deploy`, Vercel deploy commands, Firebase deploy command for Flutter web.

**Step 7.3 — Tag the first monorepo release**
Create and push the Git tag `v4.0.0-monorepo` with a release note summarizing: what was restructured, what was migrated, what is new.

**Phase 7 Completion Checklist:**
- [ ] All 10 end-to-end test steps pass
- [ ] `docs/deployment.md` has accurate commands
- [ ] Git tag `v4.0.0-monorepo` exists
- [ ] Both apps build and run in production configuration
- [ ] No `TODO:` comments remain that represent blocking issues (non-blocking TODOs are acceptable)

---

## 9. Things You Must Never Do

- Never generate placeholder or lorem ipsum content in seed data, documentation, or question bank entries. If you cannot write real content, add a `TODO:` comment.
- Never use MongoDB or Mongoose in any file anywhere in this repository after Phase 3.
- Never store individual daily-five question responses in any database table. The spec explicitly prohibits this.
- Never expose `SUPABASE_SERVICE_ROLE_KEY` or any other secret in client-side code, environment variable names starting with `NEXT_PUBLIC_`, or Flutter Dart source files.
- Never create a new database for any purpose. There is one Supabase project, one database.
- Never call the `compute-readiness-score` Edge Function from the Flutter app directly. The trigger system invokes it automatically.
- Never add a feature to one app that is specified as belonging exclusively to the other. Refer to the "Both apps share data, not features" rule throughout.
- Never rename a Supabase table from the schema in Section 4 without updating every reference across both apps and all migration files simultaneously.

---

## 10. Quick Reference: Who Uses What

| Feature | Flutter App (`app.psgmx.tech`) | Next.js Web (`psgmx.tech`) |
|---|---|---|
| Daily Five quiz | ✅ Students only | ❌ |
| Streak tracking | ✅ | ❌ |
| Readiness score display | ✅ Students see own | ✅ Faculty see all, students see own |
| Placement session scheduling | ✅ Coordinators/Reps | ❌ |
| Placement attendance marking | ✅ Team Leaders | ❌ |
| Task publishing | ✅ Coordinators/Reps | ❌ |
| Placement log entry | ✅ 2nd-year students | ❌ |
| Company visit records | ✅ Reps | ✅ Read-only for all |
| LeetCode leaderboard | ✅ Batch-scoped | ❌ |
| Mock exam administration | ❌ | ✅ Faculty |
| Mock exam taking | ❌ | ✅ Students (on desktop) |
| Knowledge Brain reading | ❌ | ✅ All users |
| Knowledge Brain writing | ❌ | ✅ Students/Alumni (pending approval) |
| AI Senior RAG chat | ❌ | ✅ Students/Alumni |
| AI Mentor chat | ✅ Students (OpenRouter) | ❌ |
| Alumni lineage network | ✅ "Your Senior" card read-only | ✅ Full alumni management |
| Faculty mentee roster | ❌ | ✅ Faculty |
| HOD department overview | ❌ | ✅ HOD |
| eCampus academic data | ✅ Campus tab, informational | ❌ |
| Announcements | ✅ Push notifications | ✅ Notification center |