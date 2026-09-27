# PSGMX Supabase Architecture & Database Guide

Welcome to the backend architecture documentation for the **PSGMX Platform** (Master of Computer Applications, PSG College of Technology).

---

## 🏛 Directory Structure

```text
supabase/
├── migrations/                     # Canonical, consolidated public migrations (01 to 11)
│   ├── 01_schema.sql               # Core relational schema, tables, foreign keys, indexes
│   ├── 02_views.sql                # Analytical & aggregated views (current_readiness_scores)
│   ├── 03_functions_and_rpcs.sql   # Canonical business logic, Daily Five & Squad RPCs
│   ├── 04_triggers.sql             # Real-time event automation & live readiness calculations
│   ├── 05_rls_policies.sql         # Row Level Security & strict batch boundary policies
│   ├── 06_grants_security.sql      # Role permissions (authenticated, anon, service_role)
│   ├── 07_default_configuration.sql# Default batches (23MX-26MX), 21 Squads, App Config
│   ├── 08_seed_question_bank.sql   # Curated placement aptitude & coding question bank
│   ├── 09_seed_daily_content.sql   # 365-day DSA & aptitude practice sets
│   ├── 10_seed_codebox_bank.sql    # CodeBox technical problem bank
│   └── 11_seed_senior_articles.sql # Curated placement strategy articles
│
├── private_seeds/                  # [GIT-IGNORED] Institutional student rosters & history
│   ├── 13_seed_students_25mx.private.sql
│   ├── 14_seed_placement_23mx_24mx.private.sql
│   ├── 16_seed_students_26mx.private.sql
│   ├── 18_seed_faculty.private.sql
│   ├── 38_update_26mxg2_profiles.private.sql
│   ├── 39_seed_alumni_and_lineage.private.sql
│   ├── 59_seed_26mx_placement_teams.private.sql
│   └── apply_all_seeds.sql         # Master runner to seed private DB instances
│
└── migrations_archive/             # [GIT-IGNORED] Historical patch archive (00 to 59)
```

---

## 🚀 Getting Started for Future Contributors

### 1. Local Development Setup
Ensure you have the [Supabase CLI](https://supabase.com/docs/guides/cli) installed.

```bash
# Start local Supabase emulation (Docker required)
supabase start

# Apply all canonical migrations from 01 to 11
supabase db reset
```

### 2. Migration Order & Organization
All migrations are strictly numbered and ordered to execute sequentially:
1. **`01_schema.sql`**: All 32 normalized tables with proper foreign key cascades and indexes.
2. **`02_views.sql`**: Consolidated views like `current_readiness_scores`.
3. **`03_functions_and_rpcs.sql`**: Fault-tolerant RPCs (`get_daily_five_questions`, `submit_daily_five_answers`, `get_batch_placement_teams`, `get_my_squad`).
4. **`04_triggers.sql`**: Event-driven automation including live readiness dimension recalculation.
5. **`05_rls_policies.sql`**: Security boundaries ensuring student privacy and role governance.
6. **`06_grants_security.sql`**: Table and sequence permissions for backend roles.
7. **`07_default_configuration.sql`**: Seed data for batches, placement squads, tier targets, and remote config.
8. **`08`-`11_seed_*.sql`**: Curated, open educational content (questions, CodeBox challenges, guides).

---

## 🔒 Security & Institutional Privacy Guardrails

- **Zero Student PII in Git**: Real student roll numbers, placement CTCs, phone numbers, and faculty contacts are strictly restricted to `private_seeds/` and suffixed with `.private.sql`.
- **Git Ignore Protection**: `.gitignore` is configured to prevent accidental commits of private records:
  ```gitignore
  *.private.sql
  supabase/private_seeds/
  supabase/migrations_archive/
  ```
- **Dynamic Frontend Architecture**: The mobile application (`apps/mobile/lib/data/placement_teams_repository.dart`) contains zero hardcoded student rosters. All squad directories, team leaders, and stats are fetched dynamically from the database.
