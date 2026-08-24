#!/usr/bin/env python3
"""
Generates SQL seed files for PSGMX placement data from 23MX.json and 24MX.json.
Run: python3 generate_placement_seeds.py
"""
import json, re

def esc(s):
    if not isinstance(s, str):
        s = str(s)
    return s.replace("'", "''")

def create_seed(file_name, batch_id, output_file, is_24_mx=False):
    with open(f"../{file_name}", 'r') as f:
        data = json.load(f)

    companies = data.get("companies", [])
    if is_24_mx and not companies:
        # Fallback if structure is different
        companies = data.get("company_wise_statistics", [])
        
    lines = [
        f"-- ============================================================",
        f"-- PSGMX SQL — FILE: {output_file}",
        f"-- Seed Placement Logs for batch {batch_id}",
        f"-- ============================================================",
        "",
        "DO $$",
        "DECLARE",
        "  new_company_id UUID;",
        "  admin_user_id UUID;",
        "BEGIN",
        "  -- Use the first superadmin or placement_rep as creator",
        "  SELECT id INTO admin_user_id FROM users WHERE role = 'hod' OR app_role = 'placement_rep' LIMIT 1;",
        "  IF admin_user_id IS NULL THEN",
        "    -- Fallback to any user if none found",
        "    SELECT id INTO admin_user_id FROM users LIMIT 1;",
        "  END IF;",
        ""
    ]

    for c in companies:
        name = c.get("company_name", c.get("company", "Unknown Company"))
        
        # Package band parsing
        package = str(c.get("salary_package", c.get("ctc_details", "Not Disclosed")))
        if "LPA" in package or "lpa" in package.lower():
            package = package.strip()
        else:
            package = "Not Disclosed"
            
        roles = "['Software Engineer']" # Default
        if "job_description" in c:
            roles = f"ARRAY['{esc(c.get('job_description'))}']"
        elif "role" in c:
            roles = f"ARRAY['{esc(c.get('role'))}']"
        else:
            roles = "ARRAY['Software Engineer', 'Analyst']"
            
        visit_date = "CURRENT_DATE" # Default fallback
        if "date_of_interview" in c:
            date_str = str(c.get("date_of_interview"))
            # very naive date extraction, fallback to CURRENT_DATE if complex
            if re.match(r'\d{1,2}/\d{1,2}/\d{2,4}', date_str):
                parts = date_str.split()[0].split('/')
                if len(parts) == 3:
                    try:
                        day, month, year = parts
                        if len(year) == 2: year = "20" + year
                        visit_date = f"'{year}-{month.zfill(2)}-{day.zfill(2)}'::DATE"
                    except: pass
            elif re.match(r'\d{4}-\d{2}-\d{2}', date_str):
                 visit_date = f"'{date_str}'::DATE"
                 
        eligibility = esc(str(c.get("criteria", c.get("eligibility_criteria", "No strict criteria"))))
        
        rounds = "[]"
        if "number_of_rounds" in c:
            val = str(c.get("number_of_rounds"))
            # Just create one descriptive round for now
            rounds = f"'[{{\"name\": \"Selection Process\", \"description\": \"{esc(val)}\"}}]'::JSONB"

        lines.extend([
            f"  -- Insert {name}",
            f"  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)",
            f"  VALUES (",
            f"    (SELECT id FROM batches WHERE batch_code = '{batch_id}' LIMIT 1),",
            f"    '{esc(name)}',",
            f"    {visit_date},",
            f"    {roles},",
            f"    '{esc(package)}',",
            f"    '{eligibility}',",
            f"    {rounds},",
            f"    admin_user_id",
            f"  ) RETURNING id INTO new_company_id;",
            ""
        ])

    lines.extend([
        "END $$;",
        f"SELECT 'FILE COMPLETE: {batch_id} companies seeded.' AS status;"
    ])

    with open(output_file, "w") as f:
        f.write("\n".join(lines))
    print(f"Generated {output_file} with {len(companies)} companies")

create_seed("24MX.json", "24MX", "05_seed_24MX_companies.sql", True)
create_seed("23MX.json", "23MX", "06_seed_23MX_companies.sql", False)

