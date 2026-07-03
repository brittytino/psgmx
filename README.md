# PSGMX — Root README

**PSGMX** is a production-grade educational ecosystem for the MCA Department at PSG College of Technology, Coimbatore, India.

It consists of two applications sharing a single Supabase backend:
- **Mobile app** (`app.psgmx.tech`) — Flutter, used by students daily for placement prep, streaks, and attendance
- **Web platform** (`psgmx.tech`) — Next.js 15, used by students, faculty, alumni, and the HOD

## Documentation

| Document | Description |
|---|---|
| [docs/README.md](docs/README.md) | Project overview and mental model |
| [docs/architecture.md](docs/architecture.md) | System architecture and data flow |
| [docs/user-flow.md](docs/user-flow.md) | User flows per role |
| [docs/readiness-score.md](docs/readiness-score.md) | Readiness score formula |
| [docs/batch-lifecycle.md](docs/batch-lifecycle.md) | Batch creation to graduation |
| [docs/deployment.md](docs/deployment.md) | How to deploy both apps |
| [docs/contributing.md](docs/contributing.md) | How to contribute as a student maintainer |

## Quick Start

```bash
# Mobile app
cd apps/mobile
cp .env.example .env  # fill in values
flutter run

# Web platform
cd apps/web
cp .env.example .env.local  # fill in values
npm install
npm run dev

# Supabase (local dev)
supabase start
supabase db reset
```

## Monorepo Structure

```
psgmx/
├── apps/
│   ├── mobile/   ← Flutter app (app.psgmx.tech)
│   └── web/      ← Next.js app (psgmx.tech)
├── supabase/
│   ├── migrations/
│   ├── functions/
│   └── types/
├── docs/
└── .github/workflows/
```
