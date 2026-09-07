# PSGMX — Higher-Ed Academic & Placement Ecosystem

<p align="center">
  <img src="apps/web/public/logo.png" alt="PSGMX Logo" width="120" onerror="this.style.display='none'" />
</p>

<p align="center">
  <strong>Production-Grade Educational Platform & Alumni Lineage Ecosystem</strong><br />
  Department of Computer Applications · PSG College of Technology, Coimbatore
</p>

<p align="center">
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.24+-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" /></a>
  <a href="https://nextjs.org"><img src="https://img.shields.io/badge/Next.js-15-000000?style=for-the-badge&logo=next.js&logoColor=white" alt="Next.js 15" /></a>
  <a href="https://supabase.com"><img src="https://img.shields.io/badge/Supabase-PostgreSQL-3FCF8E?style=for-the-badge&logo=supabase&logoColor=white" alt="Supabase" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge" alt="License" /></a>
</p>

---

## 📌 About PSGMX

**PSGMX** is an enterprise-grade academic preparation, placement tracking, and alumni lineage platform custom-built for the MCA Department at PSG College of Technology. It connects active MCA cohorts with historical alumni across past graduating batches (19MX through 24MX and beyond), offering automated lineage mentorship, readiness analytics, and placement preparation tools.

The platform is structured as a unified monorepo consisting of:
- **Mobile Companion (`apps/mobile`)**: Cross-platform Flutter application tailored for daily student readiness check-ins, mock tests, placement company updates, and attendance alerts.
- **Web Platform (`apps/web`)**: Next.js 15 App Router web application providing student dashboards, alumni guidance networks, faculty batch management, HOD analytics, and placement rep controls.
- **Backend & Database (`supabase`)**: PostgreSQL relational database with Row-Level Security (RLS), automated batch rotation, RAG-powered Knowledge Brain embeddings, and OTP authentication.

---

## 📁 Repository Structure

```
psgmx/
├── apps/
│   ├── mobile/             # Flutter mobile application (iOS & Android)
│   │   ├── lib/            # Clean architecture (UI, BLoC/providers, services, core)
│   │   └── pubspec.yaml    # Flutter dependencies & assets
│   └── web/                # Next.js 15 Web application (App Router)
│       ├── app/            # Routes (student, alumni, faculty, placement, onboarding)
│       ├── components/     # Reusable UI components & design system
│       └── lib/            # Supabase clients, utilities, & RAG helpers
├── supabase/
│   ├── migrations/         # Modular PostgreSQL SQL migrations (00..39)
│   └── scripts/            # Python seed generators & maintenance utilities
├── data/
│   └── historical/         # Curated student & alumni rosters (19MX to 24MX)
├── docs/                   # Comprehensive architecture, batch lifecycle, & PRD docs
├── CONTRIBUTING.md         # Open source contribution guidelines
├── LICENSE                 # MIT License
└── render.yaml             # Web deployment configuration
```

---

## 🚀 Quick Start Guide

### Prerequisites
- **Flutter SDK**: `^3.24.0`
- **Node.js**: `^20.0.0` or `^22.0.0` (pnpm or npm)
- **Python**: `^3.10` (for seed generator scripts)
- **Supabase CLI**: Optional, for local database development

### 1. Web Platform Setup

```bash
cd apps/web

# Copy environment variables
cp .env.example .env

# Install dependencies
npm install

# Start local development server
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

### 2. Mobile App Setup

```bash
cd apps/mobile

# Copy environment variables
cp .env.flutter.example .env.flutter

# Fetch Dart dependencies
flutter pub get

# Run application on emulator/device
flutter run --dart-define-from-file=.env.flutter
```

### 3. Database & Migrations Setup

Supabase migrations are located in `supabase/migrations/`. To apply migrations to your local or hosted Supabase project:

```bash
# Using Supabase CLI
supabase db push

# Or run migration scripts in order 00_reset.sql -> 39_seed_alumni_and_lineage.sql
```

---

## 🎓 Alumni & Register-Number Lineage Engine

PSGMX features an automated **Alumni Lineage Engine** that connects each active student with their exact register-number senior across historical batches:

$$
\text{Junior Student } (\text{26MX101}) \xrightarrow{\text{Lineage}} \text{Senior } (\text{25MX101}) \xrightarrow{\text{Alumni}} \text{Graduate } (\text{24MX101} \dots \text{19MX101})
$$

- **Covered Batches**: `19MX`, `20MX`, `21MX`, `22MX`, `23MX`, `24MX` (Graduated Alumni) and `25MX`, `26MX` (Active Students).
- **Roster Datasets**: Stored securely in `data/historical/` and pre-provisioned into `public.whitelist` and `public.users`.
- **Lineage Maps**: Idempotently maintained in `public.lineage_map`.

---

## 🛡️ Security & Authentication

- **Row-Level Security (RLS)**: Enforced across all PostgreSQL tables.
- **Identity Isolation**: Student profiles, faculty tools, and alumni portals operate under strict RLS policies driven by `auth.uid()`.
- **OTP Pre-Registration**: Whitelisted college (`@psgtech.ac.in`) and personal emails pre-authenticate student and alumni OTP logins.

---

## 🤝 Open Source Contribution

We welcome contributions from students, alumni, and community developers!

Please review our **[Contribution Guide](CONTRIBUTING.md)** and **[Docs Directory](docs/README.md)** before submitting a Pull Request.

### Workflow Summary
1. Fork the repo and create a topic branch (`feat/web/lineage-graph` or `fix/mobile/auth`).
2. Ensure `npx tsc --noEmit` and `flutter analyze` pass cleanly.
3. Open a Pull Request referencing the related issue.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).  
Developed with ❤️ by the students and faculty of the MCA Department at PSG College of Technology.
