# Changelog

All notable changes to PSG MCA Placement Prep App will be documented in this file.

## [4.2.0] - 2026-09-11

### 🚀 Features

- **Screen Security Service**: Android-level screenshot/screen-recording prevention for sensitive app screens, protecting student data during placement sessions.
- **Semantic Version Comparison**: Robust semver parsing and comparison logic for in-app update prompts — correctly handles pre-release and build-metadata suffixes.
- **Journey Archive**: Students can now browse and replay past journey entries; archived journeys are accessible from the profile and community tabs.
- **Expanded Navigation**: Community, Training, and Profile tabs now have fully wired deep-link routes and sub-page navigation flows.
- **Adaptive Sprint System**: Question sprints now adapt difficulty in real time based on answer accuracy. Persistent revisit queues ensure weak topics resurface automatically.
- **Push Notifications**: Device token registration and targeted push-notification dispatch for sprint reminders, placement alerts, and announcements.
- **Squad & Community Expansion**: New squad leaderboard, peer-challenge flows, and community feed improvements.
- **Historical Alumni Migration**: Seeding scripts and data migrations for alumni batches 19MX–24MX, unlocking the full lineage graph.
- **Live Search Spotlight**: Real-time header search with instant autocomplete and URL query-parameter sync across the student portal and Knowledge Brain.
- **Real-time Notifications**: Zero-static-data notification pipeline using Supabase Realtime; alumni and student portals both receive live DB-push events.

### 🏗️ Architecture & Refactoring

- Removed ~47 dead legacy code files with zero live entry points (cleaner build graph, faster analysis).
- Improved robustness of student role detection, lineage lookup, and error handling across exam and lineage views.
- Full dynamic UI conversion — no static/dummy data remains in production screens.
- Robust API integration across all portals with proper loading, error, and empty states.
- Strengthened Supabase RLS: granted missing table-level access for `sprint`, `device_tokens`, and `lineage_requests` tables.

### 🐛 Bug Fixes

- Fixed real UI overflow bugs in multiple screens (replaced dummy data with live DB queries).
- Fixed alumni portal: removed readiness/streaks from alumni view and wired real-time DB queries correctly.
- Fixed batch year handling and toast notifications in alumni portal.
- Fixed CI smoke tests: scoped to `public-smoke` project to avoid auth-dependent flakiness.
- Unblocked web CI, cron automation, and dead UI across all portals.

### 🔒 Security

- Hardened production authentication flow.
- Screen security service prevents data leakage via screenshots on Android.

### 🔧 CI / Infra

- Added comprehensive role-based E2E and security test framework (Playwright).
- Added `APP_API_URL` fallbacks throughout all CI workflows.
- Scoped release workflow analysis to `--fatal-warnings` only (suppresses noisy info-level hints from third-party packages).

---

## [4.0.0] - 2026-06-19

### 🎉 Major Release - The Dynamic Overhaul

#### ✨ New Features
- **Dynamic Batch System**: Replaced the static 123-student whitelist. Students are now automatically assigned to a batch based on their roll numbers. Auto-manages active seniors and junior batches.
- **Dynamic Permissions (RBAC)**: Replaced rigid roles with granular permission flags (`manage_members`, `publish_tasks`, `moderate_placement_log`).
- **Placement Logs**: A collaborative knowledge-sharing hub. Seniors can log company visits, package bands, eligibility criteria, and their personal round-by-round experiences.
- **Daily Five Engine**: A fast, engaging 5-question daily quiz with streaks, freeze tokens, and light anti-cheat mechanisms.
- **AI Mentor**: Integrated OpenRouter AI fallback-chain for providing on-the-fly explanations for wrong Daily Five answers, and simulating mock interviews.
- **Readiness Score Engine**: A comprehensive metric blending Placement Class Attendance, LeetCode Momentum, Daily Five accuracy, and Task completion to calculate real-time readiness.

#### 🏗️ Architecture & Refactoring
- **Separation of Attendance**: "Official Academic Attendance" (eCampus) and "Placement Class Attendance" are now strictly separated systems.
- **Cleaned Up Static Artifacts**: Removed thousands of lines of obsolete mock data, dummy scripts, and legacy SQL onboarding files.
- **Dependency Upgrades**: Upgraded core architecture to handle multiple Providers safely without memory leaks.

#### 🐛 Bug Fixes
- Fixed massive `../../../` relative import path bugs across the entire `ui/` directory.
- Fixed `AppRouter` missing imports that caused compilation failures.
- Fixed PostgreSQL constraint crashes when submitting Placement Log records with missing `batch_id` foreign keys.

---

## [2.2.9] - 2026-03-04

### 🔒 Security
- **CRITICAL FIX**: Resolved 3 Supabase SECURITY DEFINER view vulnerabilities
  - Fixed `v_ecampus_attendance_summary` to respect Row Level Security
  - Fixed `v_ecampus_cgpa_summary` to respect Row Level Security  
  - Fixed `student_attendance_summary` to respect Row Level Security
- All database views now use `SECURITY INVOKER` to enforce proper authorization
- Closed potential unauthorized data access vulnerability flagged by Supabase Security Advisor

### 📁 Database
- **NEW**: `database/15_fix_security_definer_views.sql` — Security patch for database views
- Updated all view definitions to include `WITH (security_invoker = true)`

---

## [2.2.1] - 2026-02-05

### 🔧 Fixes
- Fixed Android keystore compatibility issues ("Tag number over 30 not supported")
- Updated keystore to PKCS12 format with 2048-bit RSA keys for Android build tools compatibility

---

## [2.1.0] - 2026-02-05

### 🎉 Production Release - Open Source Ready

#### ✨ New Features
- **iOS PWA Installation Guide**: Professional step-by-step guide for iOS users to install as Progressive Web App
- **Firebase Hosting Deployment**: Fully automated deployment pipeline with GitHub Actions
- **Android APK Signing**: Production-ready signed APKs for direct distribution

#### 🏗️ Infrastructure
- Cleaned up duplicate GitHub Actions workflows
- Optimized Firebase deployment with proper Flutter setup

#### 🐛 Bug Fixes
- Removed unused imports and dead code
- Fixed null safety issues in update service

---

## [1.0.5] - 2026-01-28

### Production Release - All Critical Issues Fixed

#### ✨ Features
- Complete OTP-based authentication system with password setup
- LeetCode stats integration with real-time leaderboard
- Team-based attendance marking system
- Announcement system with auto-expiry functionality
- Birthday notifications

#### 🔧 Fixed Issues
- OTP flow now requires password before account creation
- Leaderboard UI overflow resolved
- Attendance system fetches from whitelist

---

**For more details, see [README.md](README.md)**
