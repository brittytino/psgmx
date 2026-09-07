# PSGMX — Open Source Contributing Guide

Welcome, contributor! This repository contains the source code for **PSGMX**, the official MCA educational ecosystem for PSG College of Technology.

For detailed architecture documentation, contribution requirements, and coding guidelines, please refer to:
👉 **[docs/contributing.md](docs/contributing.md)**

---

## Quick Contribution Overview

### 1. Monorepo Architecture

```
psgmx/
├── apps/
│   ├── mobile/          ← Flutter app (Dart) — Android & iOS student companion
│   └── web/             ← Next.js 15 app (TypeScript) — Web platform & dashboards
├── supabase/            ← PostgreSQL migrations, edge functions, and seed scripts
├── data/
│   └── historical/      ← Batch student & alumni rosters and placement datasets
└── docs/                ← Architecture, batch lifecycle, & API documentation
```

### 2. Development Setup

```bash
# Clone the repository
git clone https://github.com/psgmx/psgmx.git
cd psgmx

# 📱 Mobile App (Flutter)
cd apps/mobile
cp .env.flutter.example .env.flutter
flutter pub get
flutter run

# 🌐 Web Platform (Next.js 15)
cd apps/web
cp .env.example .env
npm install
npm run dev
```

### 3. Submitting Pull Requests

1. Open a GitHub issue outlining your proposed change.
2. Follow the branch naming convention:
   - `feat/mobile/<description>` — Flutter feature
   - `feat/web/<description>` — Next.js feature
   - `fix/mobile/<description>` — Flutter fix
   - `fix/web/<description>` — Next.js fix
   - `db/<description>` — Database migration
3. Run verification before creating a PR:
   - Web: `npx tsc --noEmit && npm run build` (inside `apps/web`)
   - Mobile: `flutter analyze` (inside `apps/mobile`)

Thank you for contributing to PSGMX! 🚀
