# PSGMX — Project Overview

## What is PSGMX?

PSGMX is the placement preparation ecosystem for the MCA Department at PSG College of Technology, Coimbatore, India. It is named after the batch code format used by the department (e.g., `25MX` for the 2025 intake).

The system tracks student readiness for placement across four measurable dimensions: daily quizzing consistency, LeetCode practice, mock examination performance, and placement session attendance. Every student receives a single **Readiness Score** (0–100) that summarises all four dimensions.

## Two-App Mental Model

PSGMX is intentionally split into two apps with different interaction cadences.

### Mobile App (`app.psgmx.tech`) — Daily Habit
The Flutter app is the student's daily companion. Students open it every morning to:
- Complete the **Daily Five** — five multiple-choice questions from the placement question bank
- Check their **streak** — how many consecutive days they've completed the quiz
- View their **Readiness Score gauge** — updated automatically after each contributing event
- Track their **LeetCode progress** — batch-period problem counts synced every 6 hours
- Attend **placement sessions** (marked by Team Leaders)
- Check **daily tasks** assigned by Coordinators

The mobile app is distributed as:
- **Android**: APK via GitHub Releases (see [deployment.md](deployment.md))
- **iOS/Desktop**: PWA via Safari at `app.psgmx.tech` (Firebase Hosting)

### Web Platform (`psgmx.tech`) — Intentional Action
The Next.js web platform is used when something deliberate needs to happen:
- **Students**: Take mock exams, read the Knowledge Brain, chat with AI Senior
- **Faculty**: Schedule and proctor mock exams, approve Knowledge Brain articles, view mentee rosters
- **Alumni**: Contribute interview experiences, toggle mentorship availability, browse the collaboration marketplace
- **HOD**: Read-only department overview dashboard — all batches, all readiness bands, all placement outcomes

## Who Uses What

| Role | Primary App | Key Actions |
|---|---|---|
| First-Year Student | Mobile (daily) | Daily Five, streak, task completion, readiness score |
| Second-Year Student | Mobile + Web | All of above + placement log entries, mock exams, Knowledge Brain |
| Team Leader | Mobile | Mark attendance for team members |
| Coordinator | Mobile | Schedule sessions, publish daily tasks |
| Placement Rep | Mobile | All coordinator actions + manage company records |
| Faculty | Web | Mock exam creation/proctoring, Knowledge Brain approval, mentee oversight |
| Alumni | Web | Knowledge contributions, mentorship toggle, lineage network |
| HOD | Web | Read-only aggregate view of the entire department |

## GitHub APK Link

The latest Android APK is always available at:
```
https://github.com/brittytino/psgmx/releases/latest
```

## Domains

| Domain | App | Hosting |
|---|---|---|
| `app.psgmx.tech` | Flutter (PWA/web build) | Firebase Hosting |
| `psgmx.tech` | Next.js 15 | Vercel |
