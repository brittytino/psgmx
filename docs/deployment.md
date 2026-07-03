# PSGMX — Deployment Guide

## Overview

| App | Domain | Hosting | Deployed By |
|---|---|---|---|
| Flutter (mobile/web) | `app.psgmx.tech` | Firebase Hosting | GitHub Actions tag push |
| Next.js (web platform) | `psgmx.tech` | Vercel | Vercel GitHub integration |
| Supabase (database) | Managed by Supabase | Supabase Cloud | Manual `supabase` CLI |

---

## 1. Supabase Project Setup

### 1.1 Create a Supabase Project
1. Go to [supabase.com](https://supabase.com) → New Project
2. Project name: `psgmx`
3. Database password: generate a strong one and store it safely
4. Region: `ap-south-1` (Mumbai — closest to Coimbatore)

### 1.2 Enable Required Extensions
In the Supabase Dashboard → Database → Extensions, enable:
- `uuid-ossp`
- `vector` (pgvector — for semantic search embeddings)
- `pg_net` (for HTTP calls from triggers to Edge Functions)

### 1.3 Apply Database Migrations

Install the Supabase CLI:
```bash
brew install supabase/tap/supabase  # macOS
# or
npm install -g supabase              # npm
```

Link the project:
```bash
cd /path/to/psgmx
supabase login
supabase link --project-ref YOUR_PROJECT_REF
```

Apply all migrations:
```bash
supabase db push
```

Or for local development with a local Supabase instance:
```bash
supabase start         # starts local Supabase
supabase db reset      # applies all migrations fresh
```

### 1.4 Get API Keys
In Supabase Dashboard → Settings → API:
- **Project URL**: `https://YOUR_PROJECT_REF.supabase.co`
- **anon public key**: used in Flutter and Next.js `NEXT_PUBLIC_*` variables
- **service_role key**: server-only, never exposed to clients

---

## 2. Flutter Mobile App (Android APK)

### 2.1 Build the APK Locally
```bash
cd apps/mobile
flutter pub get
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY \
  --dart-define=ECAMPUS_API_URL=https://your-ecampus-api.render.com \
  --dart-define=ECAMPUS_API_SECRET=YOUR_SECRET
```

The APK is output to: `apps/mobile/build/app/outputs/flutter-apk/app-release.apk`

### 2.2 GitHub Actions — Automated APK Release
Push a Git tag matching `v*` to trigger the `mobile-apk-release.yml` workflow:
```bash
git tag v4.1.0
git push origin v4.1.0
```
The workflow builds the APK and uploads it as a GitHub Release asset automatically.

**Required GitHub Secrets** (set in repo Settings → Secrets → Actions):
```
SUPABASE_URL
SUPABASE_ANON_KEY
ECAMPUS_API_URL
ECAMPUS_API_SECRET
```

### 2.3 Firebase Hosting — Flutter Web Build (app.psgmx.tech)
The Flutter app is also built as a PWA and hosted on Firebase Hosting for iOS/Safari users.

```bash
cd apps/mobile
flutter build web --release
firebase deploy --only hosting
```

**Prerequisites**:
- Firebase CLI installed: `npm install -g firebase-tools`
- Logged in: `firebase login`
- Project configured in `apps/mobile/.firebaserc`

The domain `app.psgmx.tech` must be configured in Firebase Console → Hosting → Custom Domains.

---

## 3. Next.js Web Platform (psgmx.tech)

### 3.1 Local Development
```bash
cd apps/web
cp .env.example .env.local
# Fill in all values in .env.local

npm install
npm run dev  # starts at http://localhost:3000
```

### 3.2 Vercel Deployment (Production)
The web app is deployed to Vercel via GitHub integration. Every push to `main` triggers a production deployment automatically.

**Setup (one-time)**:
1. Go to [vercel.com](https://vercel.com) → New Project → Import from GitHub
2. Select the `psgmx` repository
3. Set **Root Directory**: `apps/web`
4. Add all environment variables:

```
NEXT_PUBLIC_SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=YOUR_ANON_KEY
SUPABASE_SERVICE_ROLE_KEY=YOUR_SERVICE_ROLE_KEY
GEMINI_API_KEY=YOUR_GEMINI_KEY
OPENROUTER_API_KEY=YOUR_OPENROUTER_KEY
JWT_SECRET=YOUR_JWT_SECRET
NEXT_PUBLIC_APP_URL=https://psgmx.tech
MOBILE_APP_URL=https://app.psgmx.tech
```

5. The domain `psgmx.tech` must be configured in Vercel Dashboard → Domains.

### 3.3 Build Verification
The `web-deploy.yml` GitHub Actions workflow runs on every push to `main` to verify the build passes before Vercel deploys:
```bash
cd apps/web
npm ci
npm run build
```

---

## 4. Supabase Edge Functions

### 4.1 Deploy All Edge Functions
```bash
cd /path/to/psgmx
supabase functions deploy compute-readiness-score
supabase functions deploy batch-graduation
supabase functions deploy knowledge-ingest
```

### 4.2 Set Edge Function Secrets
```bash
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=YOUR_SERVICE_ROLE_KEY
supabase secrets set GEMINI_API_KEY=YOUR_GEMINI_KEY
supabase secrets set OPENROUTER_API_KEY=YOUR_OPENROUTER_KEY
```

### 4.3 Configure Trigger URLs
The database triggers call Edge Functions via `net.http_post`. After deploying, set the function URLs as Postgres settings:
```sql
ALTER DATABASE postgres SET app.edge_function_url_compute_readiness_score = 'https://YOUR_PROJECT_REF.functions.supabase.co/compute-readiness-score';
ALTER DATABASE postgres SET app.edge_function_url_knowledge_ingest = 'https://YOUR_PROJECT_REF.functions.supabase.co/knowledge-ingest';
```

### 4.4 Verify CRON Schedule
The `batch-graduation` function is configured with CRON `0 0 1 6 *` in `supabase/config.toml`. After deployment, verify in Supabase Dashboard → Edge Functions → batch-graduation → CRON schedules.

---

## 5. Full Deployment Checklist

After making schema or Edge Function changes:

```bash
# 1. Apply new migrations
supabase db push

# 2. Redeploy Edge Functions if changed
supabase functions deploy compute-readiness-score
supabase functions deploy batch-graduation
supabase functions deploy knowledge-ingest

# 3. Deploy web app (automatic via Vercel on push to main)
git push origin main

# 4. Build and release APK (automatic via GitHub Actions on tag push)
git tag v4.x.x && git push origin v4.x.x

# 5. Deploy Flutter web (manual)
cd apps/mobile && flutter build web --release && firebase deploy --only hosting
```
