#!/usr/bin/env python3
"""
Fixed regeneration of the 23MX/24MX companies seed, sourced from
23MX.json / 24MX.json. Fixes vs. the old sql/generate_placement_seeds.py:
  - admin lookup uses role_label (HOD/Faculty), not the dead role/app_role
    columns, and falls back to NULL (companies.created_by is nullable)
    instead of erroring when zero users exist yet on a fresh install.
  - also tries date_of_actual_process (24MX's field name) in addition to
    date_of_interview (23MX's field name) for visit_date parsing.
"""
import json, re

def esc(s):
    if not isinstance(s, str):
        s = str(s)
    return s.replace("'", "''")

def parse_date(date_str):
    if not date_str:
        return None
    date_str = str(date_str).split()[0]
    m = re.match(r'(\d{1,2})/(\d{1,2})/(\d{2,4})', date_str)
    if m:
        day, month, year = m.groups()
        if len(year) == 2:
            year = "20" + year
        try:
            return f"'{year}-{int(month):02d}-{int(day):02d}'::DATE"
        except ValueError:
            return None
    m = re.match(r'(\d{4})-(\d{2})-(\d{2})', date_str)
    if m:
        return f"'{date_str}'::DATE"
    return None

def build(file_name, batch_code):
    with open(file_name, 'r') as f:
        data = json.load(f)
    companies = data.get("companies", [])

    lines = []
    lines.append(f"  -- ── {batch_code}: {len(companies)} companies ──")
    lines.append("  admin_user_id := (SELECT id FROM users WHERE role_label IN ('HOD', 'Faculty') LIMIT 1);")
    lines.append(f"  batch_uuid := (SELECT id FROM batches WHERE batch_code = '{batch_code}' LIMIT 1);")
    lines.append("")

    for c in companies:
        name = c.get("company_name", c.get("company", "Unknown Company"))

        package = str(c.get("salary_package", c.get("ctc_details", "Not Disclosed")))
        package = package.strip() if package else "Not Disclosed"

        if "job_description" in c and c.get("job_description"):
            roles = f"ARRAY['{esc(c.get('job_description'))}']"
        elif "role" in c and c.get("role"):
            roles = f"ARRAY['{esc(c.get('role'))}']"
        else:
            roles = "ARRAY['Software Engineer']"

        visit_date = parse_date(c.get("date_of_interview")) or parse_date(c.get("date_of_actual_process")) or parse_date(c.get("date_announced")) or "CURRENT_DATE"

        eligibility = esc(str(c.get("criteria", c.get("eligibility_criteria", "No strict criteria"))))

        rounds = "'[]'::JSONB"
        if c.get("number_of_rounds"):
            val = str(c.get("number_of_rounds"))
            rounds = f"'[{{\"name\": \"Selection Process\", \"description\": \"{esc(val)}\"}}]'::JSONB"

        lines.append(f"  -- {name}")
        lines.append("  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)")
        lines.append("  VALUES (")
        lines.append("    batch_uuid,")
        lines.append(f"    '{esc(name)}',")
        lines.append(f"    {visit_date},")
        lines.append(f"    {roles},")
        lines.append(f"    '{esc(package)}',")
        lines.append(f"    '{eligibility}',")
        lines.append(f"    {rounds},")
        lines.append("    admin_user_id")
        lines.append("  );")
        lines.append("")

    return "\n".join(lines), len(companies)

body_24, n24 = build("24MX.json", "24MX")
body_23, n23 = build("23MX.json", "23MX")

out = f"""-- ============================================================
-- PSGMX — 14_seed_placement_23mx_24mx.sql
-- ============================================================
-- Historical placement-drive company records for the 23MX and 24MX
-- (graduated) batches, sourced from 23MX.json / 24MX.json.
--
-- Regenerated from scratch via a fixed version of the old
-- sql/generate_placement_seeds.py (see sql/generate_placement_seeds.py,
-- also fixed in this same change). Original bug: looked up an admin user
-- via `WHERE role = 'hod' OR app_role = 'placement_rep'` — those columns
-- never existed on the live schema (the exact error this whole rebuild
-- was triggered by). Fixed to use role_label, and created_by falls back to
-- NULL (companies.created_by is nullable) rather than erroring, since this
-- seed runs before any real HOD/placement-rep has ever logged in.
--
-- Run AFTER 13_seed_students_25mx.sql.
-- ============================================================

DO $$
DECLARE
  admin_user_id UUID;
  batch_uuid    UUID;
BEGIN
{body_24}
{body_23}
END $$;

DO $$
BEGIN
    RAISE NOTICE '✅ 14_seed_placement_23mx_24mx.sql complete — {n24} (24MX) + {n23} (23MX) companies seeded.';
    RAISE NOTICE 'Full rebuild sequence complete.';
END $$;
"""

with open("/mnt/Data/College/Mini Project/psgmx/supabase/migrations/14_seed_placement_23mx_24mx.sql", "w") as f:
    f.write(out)

print(f"Wrote 14_seed_placement_23mx_24mx.sql: {n24} + {n23} companies")
