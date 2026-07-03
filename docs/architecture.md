# PSGMX — System Architecture

## Overview

PSGMX uses a **single-database, dual-app** architecture. There is exactly one Supabase PostgreSQL project. Both the Flutter mobile app and the Next.js web app connect directly to this database using Supabase client libraries. There is no API bridge, no sync job, and no message queue between them.

```
┌─────────────────────────────────────────────────────────────────┐
│                        PSGMX Ecosystem                          │
│                                                                  │
│  ┌─────────────────────┐     ┌─────────────────────────────┐   │
│  │   Flutter App       │     │    Next.js Web App           │   │
│  │   app.psgmx.tech    │     │    psgmx.tech                │   │
│  │   (Firebase Hosting)│     │    (Vercel)                  │   │
│  │                     │     │                              │   │
│  │  supabase_flutter   │     │  @supabase/ssr               │   │
│  │  (anon key + RLS)   │     │  (anon key + RLS)            │   │
│  └──────────┬──────────┘     └──────────────┬───────────────┘   │
│             │                               │                   │
│             └──────────────┬────────────────┘                   │
│                            │                                    │
│             ┌──────────────▼────────────────┐                   │
│             │        Supabase Project        │                   │
│             │                                │                   │
│             │  ┌─────────────────────────┐  │                   │
│             │  │  PostgreSQL + pgvector   │  │                   │
│             │  │  Row Level Security      │  │                   │
│             │  │  27 tables               │  │                   │
│             │  └─────────────────────────┘  │                   │
│             │                                │                   │
│             │  ┌─────────────────────────┐  │                   │
│             │  │  Supabase Auth           │  │                   │
│             │  │  OTP email (students)    │  │                   │
│             │  │  Invite (faculty/HOD)    │  │                   │
│             │  └─────────────────────────┘  │                   │
│             │                                │                   │
│             │  ┌─────────────────────────┐  │                   │
│             │  │  Edge Functions (Deno)   │  │                   │
│             │  │  compute-readiness-score │  │                   │
│             │  │  batch-graduation (CRON) │  │                   │
│             │  │  knowledge-ingest        │  │                   │
│             │  └─────────────────────────┘  │                   │
│             └────────────────────────────────┘                   │
└─────────────────────────────────────────────────────────────────┘
```

## Database Tables (27 total)

### Core Identity
| Table | Purpose |
|---|---|
| `batches` | One row per MCA intake year (e.g., 25MX) |
| `users` | All users — students, alumni, faculty, HOD |
| `teams` | Student teams within a batch |
| `user_permissions` | Granular capability flags per user |
| `lineage_map` | Junior ↔ Senior roll number matching |

### Mobile App (Placement Prep)
| Table | Purpose |
|---|---|
| `placement_sessions` | Sessions scheduled by Coordinators/Reps |
| `placement_session_teams` | Which teams a session targets |
| `placement_attendance` | Per-student attendance per session |
| `question_bank` | MCQ pool for Daily Five quiz |
| `daily_five_streaks` | Streak state per student (no individual answers stored) |
| `leetcode_stats` | LeetCode problem counts, batch percentile |
| `daily_tasks` | Published tasks (LeetCode or core subject) |
| `task_completions` | Student task completion records |
| `companies` | Company visit records |
| `placement_log_entries` | Student interview experience writeups |

### Readiness Engine
| Table | Purpose |
|---|---|
| `readiness_scores` | Current score per student (pre-computed) |
| `readiness_score_history` | Daily snapshots for trend charts |

### Web Platform
| Table | Purpose |
|---|---|
| `knowledge_brain_articles` | Faculty-approved articles and interview experiences |
| `knowledge_embeddings` | pgvector embeddings for semantic search |
| `mock_exams` | Exam definitions by faculty |
| `mock_exam_questions` | Individual questions within an exam |
| `mock_exam_results` | Per-student exam scores + proctoring flags |

### Both Apps
| Table | Purpose |
|---|---|
| `announcements` | Batch or department-wide announcements |
| `notifications` | Per-user notification records |
| `collaboration_posts` | Alumni/student collaboration marketplace |
| `lineage_messages` | 1:1 messaging between alumni and matched juniors |
| `audit_logs` | Immutable log of sensitive actions |

## Three Edge Functions

### `compute-readiness-score`
- **Trigger**: Database trigger after any change to `daily_five_streaks`, `leetcode_stats`, `mock_exam_results`, or `placement_attendance`
- **Action**: Computes the four-component readiness score, upserts `readiness_scores`, writes daily snapshot to `readiness_score_history`
- **Latency**: ≤60 seconds from triggering event to score update

### `batch-graduation`
- **Trigger**: CRON — runs on `0 0 1 6 *` (midnight on June 1st each year)
- **Action**: Transitions graduated batches, converts students to alumni, sends graduation notifications, promotes the youngest junior batch to senior

### `knowledge-ingest`
- **Trigger**: Database trigger after a `placement_log_entry` is approved by faculty
- **Action**: Creates a `knowledge_brain_articles` row, chunks the experience text at sentence boundaries, generates embeddings using Supabase's native `gte-small` model, stores in `knowledge_embeddings`

## Row Level Security

Every table has RLS enabled. The key principle: **users can only see and modify data within their own scope**. Scope is defined by:
- `role` (student, alumni, faculty, hod)
- `app_role` (student, team_leader, coordinator, placement_rep)
- `batch_id` — all batch-scoped data is filtered to a user's own batch

Service-role bypasses RLS for Edge Functions that need to write across user boundaries (e.g., computing readiness scores for other users).

## Domain Setup

| Domain | Points To | Managed By |
|---|---|---|
| `app.psgmx.tech` | Firebase Hosting (Flutter web build) | Firebase Console |
| `psgmx.tech` | Vercel (Next.js deployment) | Vercel Dashboard |

Both domains use HTTPS enforced at the hosting layer. The Supabase project is separate and does not handle web traffic.

## Data Flow — Key Scenarios

### Student completes Daily Five
1. Flutter app → updates `daily_five_streaks` via Supabase client (anon key, RLS allows own row)
2. DB trigger fires → calls `compute-readiness-score` Edge Function with `user_id`
3. Edge Function reads `daily_five_streaks`, `leetcode_stats`, `mock_exam_results`, `placement_attendance`
4. Edge Function upserts `readiness_scores` — score updated within 60 seconds
5. Flutter app has a Realtime subscription on `readiness_scores` → gauge updates live

### Faculty approves a placement log entry
1. Faculty approves on Next.js web platform → updates `placement_log_entries.approval_status = 'approved'`
2. DB trigger fires → calls `knowledge-ingest` Edge Function
3. Edge Function creates `knowledge_brain_articles` row, chunks text, generates embeddings
4. Student's experience is now searchable in the Knowledge Brain
