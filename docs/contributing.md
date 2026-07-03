# PSGMX — Contributing Guide

Welcome, student maintainer! This guide explains how to contribute to the PSGMX codebase, which is maintained by students of the MCA Department at PSG College of Technology.

## Who Can Contribute

- **Active students** in the current batch can contribute to the mobile app (`apps/mobile`)
- **Alumni** with prior web development experience can contribute to the web platform (`apps/web`)
- **Designated maintainers** (typically one Coordinator or Placement Rep per batch) have merge access

## Monorepo Structure

```
psgmx/
├── apps/mobile/    ← Flutter (Dart) — student daily companion
├── apps/web/       ← Next.js (TypeScript) — web platform
├── supabase/       ← SQL migrations and Edge Functions
└── docs/           ← Documentation (you are here)
```

## Development Setup

### Prerequisites
- Flutter SDK ≥ 3.2.0
- Node.js ≥ 20
- Supabase CLI (for local database work)

### Getting Started

```bash
git clone https://github.com/brittytino/psgmx.git
cd psgmx

# Mobile app
cd apps/mobile
cp .env.example .env   # get values from the current Placement Rep/maintainer
flutter pub get
flutter run

# Web platform
cd apps/web
cp .env.example .env.local   # get values from maintainer
npm install
npm run dev
```

## Contribution Workflow

### 1. Open an Issue First
Before writing any code, open a GitHub Issue describing:
- What you're trying to fix or add
- Which app it affects (mobile, web, or both)
- Any database schema changes required

This prevents duplicate work and ensures your contribution fits the spec.

### 2. Branch Naming
```
feat/mobile/<description>   ← Flutter feature
feat/web/<description>      ← Next.js feature
fix/mobile/<description>    ← Flutter bug fix
fix/web/<description>       ← Next.js bug fix
db/<migration-description>  ← Database schema changes
```

### 3. Pull Request Requirements

Before opening a PR, verify:
- `flutter build apk --release` passes (for mobile changes)
- `npm run build` passes (for web changes)
- No `console.log` or `debugPrint` statements left in production code
- No new environment variables added without updating the relevant `.env.example`
- No new Supabase tables added without a corresponding SQL migration file in `supabase/migrations/`

### 4. PR Review Process
1. Open a PR against `main`
2. A designated maintainer reviews within 3 days
3. CI checks (GitHub Actions) must pass before merging
4. Squash merge into `main`

## Adding Questions to the Question Bank

The question bank (`question_bank` table) is the source for the Daily Five quiz. To add questions:

1. Write a SQL `INSERT` statement:
```sql
INSERT INTO question_bank (question_text, option_a, option_b, option_c, option_d, correct_option, topic, difficulty)
VALUES (
  'What is the time complexity of binary search?',
  'O(n)', 'O(log n)', 'O(n²)', 'O(1)',
  'b',
  'dsa',
  'easy'
);
```

2. Valid `topic` values: `aptitude`, `verbal`, `dsa`, `dbms`, `os`, `networks`, `oop`, `python`, `java`, `hr_behavioral`
3. Valid `difficulty` values: `easy`, `medium`, `hard`
4. Submit questions as a PR that adds a new SQL file to `supabase/migrations/` (e.g., `06_question_bank_batch26.sql`)

**Important**: Questions must have one clearly correct answer. If you're unsure, add a `-- TODO: verify correctness` comment in the SQL file.

## Finding the Supabase Schema

The authoritative schema is in:
- `supabase/migrations/00_initial_schema.sql` — all table definitions
- `supabase/migrations/01_rls_policies.sql` — Row Level Security policies
- `supabase/types/database.types.ts` — TypeScript types (used in the web app)

If you need to understand what data a screen or API uses, trace it: UI → API route → Supabase query → migration file.

## What NOT to Do

- **Never store individual Daily Five answers** in any table. The spec explicitly prohibits this. Only the streak state in `daily_five_streaks` persists.
- **Never use MongoDB or Mongoose** in any file in this repo.
- **Never expose `SUPABASE_SERVICE_ROLE_KEY`** in client-side code or Flutter Dart source files.
- **Never create a second database**. There is exactly one Supabase project.
- **Never rename a table** without updating every reference in both apps and all migration files simultaneously. Open an issue first.

## Getting Help

- **Slack/Discord**: Contact the current batch Coordinator for the maintainer channel invite
- **Issues**: Open a GitHub Issue tagged `question`
- **Architecture questions**: Read `docs/architecture.md`
- **Deployment questions**: Read `docs/deployment.md`
