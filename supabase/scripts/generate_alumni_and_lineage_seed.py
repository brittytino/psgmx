#!/usr/bin/env python3
"""
PSGMX — generate_alumni_and_lineage_seed.py

Extracts student and alumni roster data from Excel spreadsheets and JSON datasets in data/historical/:
 - 19mx to 23mx.xlsx
 - 24mx G1 full list.xlsx
 - 24mx G2 full list.xlsx
 - 23MX.json
 - 24MX.json

Generates migration: supabase/migrations/39_seed_alumni_and_lineage.sql
Uses public schema staging tables (public.seed_temp_alumni) instead of TEMP tables.
"""

import os
import re
import json
import zipfile
import xml.etree.ElementTree as ET

WORKSPACE = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
HISTORICAL_DIR = os.path.join(WORKSPACE, 'data', 'historical')

def find_file(filename):
    p1 = os.path.join(HISTORICAL_DIR, filename)
    if os.path.exists(p1):
        return p1
    p2 = os.path.join(WORKSPACE, filename)
    if os.path.exists(p2):
        return p2
    return None

def get_all_rows(filename):
    filepath = find_file(filename)
    if not filepath:
        print(f"Warning: {filename} not found.")
        return []
    
    rows_out = []
    with zipfile.ZipFile(filepath) as z:
        strings = []
        if 'xl/sharedStrings.xml' in z.namelist():
            tree = ET.fromstring(z.read('xl/sharedStrings.xml'))
            for elem in tree.iter('{http://schemas.openxmlformats.org/spreadsheetml/2006/main}t'):
                strings.append(elem.text or '')
        
        wb_xml = ET.fromstring(z.read('xl/workbook.xml'))
        sheets = wb_xml.find('{http://schemas.openxmlformats.org/spreadsheetml/2006/main}sheets')
        for s in sheets:
            sheet_name = s.attrib['name']
            rId = s.attrib['{http://schemas.openxmlformats.org/officeDocument/2006/relationships}id']
            rel_xml = ET.fromstring(z.read('xl/_rels/workbook.xml.rels'))
            target = None
            for rel in rel_xml:
                if rel.attrib['Id'] == rId:
                    target = rel.attrib['Target']
                    break
            if not target.startswith('xl/'):
                target = 'xl/' + target
            
            stree = ET.fromstring(z.read(target))
            for row in stree.iter('{http://schemas.openxmlformats.org/spreadsheetml/2006/main}row'):
                r_vals = []
                for cell in row.iter('{http://schemas.openxmlformats.org/spreadsheetml/2006/main}c'):
                    val_type = cell.attrib.get('t')
                    val_elem = cell.find('{http://schemas.openxmlformats.org/spreadsheetml/2006/main}v')
                    val = val_elem.text if val_elem is not None else ''
                    if val_type == 's' and val.isdigit():
                        val = strings[int(val)] if int(val) < len(strings) else val
                    r_vals.append(val)
                if any(r_vals):
                    rows_out.append((sheet_name, r_vals))
    return rows_out

students_map = {} # reg_no -> dict

def clean_name(name):
    if not name:
        return None
    name = str(name).strip()
    name = re.sub(r'^\d+[\.\s]+', '', name).strip()
    if len(name) < 2 or name.upper() in ['MALE', 'FEMALE', 'N/A', 'NONE', 'S.NO', 'S.NO.']:
        return None
    return name

def clean_email(email):
    if not email:
        return None
    email = str(email).strip().lower()
    if '@' in email and len(email) > 5 and not email.startswith('0'):
        return email
    return None

def clean_phone(phone):
    if not phone:
        return None
    ps = str(phone).strip()
    try:
        if 'E' in ps.upper():
            pf = float(ps)
            ps = str(int(pf))
        else:
            ps = re.sub(r'\D', '', ps)
    except:
        pass
    if len(ps) == 10 and ps[0] in '6789':
        return ps
    return None

def clean_gender(gender):
    if not gender:
        return None
    gs = str(gender).strip().lower()
    if gs in ['m', 'male']:
        return 'Male'
    if gs in ['f', 'female']:
        return 'Female'
    return None

def clean_company(comp):
    if not comp:
        return None
    cs = str(comp).strip()
    if len(cs) < 3 or cs.upper() in ['N/A', 'NONE', 'NIL', 'NO', 'NOT PLACED', 'UNPLACED', 'OFFER AWAITING']:
        return None
    return cs

def add_student(reg, name=None, email=None, phone=None, company=None, gender=None, source=None):
    reg = reg.strip().upper()
    if reg not in students_map:
        batch_code = reg[:4]
        college_email = f"{reg.lower()}@psgtech.ac.in"
        students_map[reg] = {
            'reg_no': reg,
            'batch_code': batch_code,
            'name': None,
            'college_email': college_email,
            'personal_email': None,
            'phone': None,
            'company': None,
            'gender': None,
            'section': 'G1' if (int(reg[4:]) < 300 if reg[4:].isdigit() else True) else 'G2'
        }
    
    s = students_map[reg]
    cname = clean_name(name)
    if cname and (not s['name'] or len(cname) > len(s['name'])):
        s['name'] = cname
        
    cemail = clean_email(email)
    if cemail and not s['personal_email'] and cemail != s['college_email']:
        s['personal_email'] = cemail
        
    cphone = clean_phone(phone)
    if cphone and not s['phone']:
        s['phone'] = cphone
        
    ccomp = clean_company(company)
    if ccomp and not s['company']:
        s['company'] = ccomp
        
    cgen = clean_gender(gender)
    if cgen and not s['gender']:
        s['gender'] = cgen

def parse_all():
    for fname in ['19mx to 23mx.xlsx', '24mx G1 full list.xlsx', '24mx G2 full list.xlsx']:
        for sheet, r in get_all_rows(fname):
            for idx, cell in enumerate(r):
                m = re.search(r'([0-9]{2}MX[0-9]{3})', str(cell), re.I)
                if m:
                    reg = m.group(1).upper()
                    name, email, phone, company, gender = None, None, None, None, None
                    for c in r:
                        cs = str(c).strip()
                        if '@' in cs and not email: email = cs
                        elif re.search(r'^[6-9]\d{9}', cs) or 'E9' in cs.upper(): phone = cs
                        elif cs.lower() in ['male', 'female', 'm', 'f'] and not gender: gender = cs
                        elif not name and re.search(r'^[A-Za-z\s\.]+$', cs) and len(cs) > 2 and cs.upper() not in ['MALE', 'FEMALE', 'N/A', 'NONE', 'S.NO']:
                            name = cs
                        elif not company and len(cs) > 3 and not re.search(r'^\d', cs) and cs not in [name, email, gender] and cs.upper() not in ['MALE', 'FEMALE', 'N/A']:
                            company = cs
                    add_student(reg, name, email, phone, company, gender, f'{fname}:{sheet}')

    j23_path = find_file('23MX.json')
    if j23_path:
        with open(j23_path) as f:
            d = json.load(f)
            for st in d.get('final_list_students', []):
                reg = st.get('student_id')
                if reg:
                    add_student(reg, st.get('name'), None, None, st.get('intern_company'), None, '23MX.json')

    j24_path = find_file('24MX.json')
    if j24_path:
        with open(j24_path) as f:
            d = json.load(f)
            for comp in d.get('companies', []):
                cname = comp.get('company_name')
                for st in comp.get('placed_students', []):
                    if isinstance(st, dict) and 'roll_no' in st:
                        add_student(st['roll_no'], st.get('name'), None, None, cname, None, '24MX.json')

    # Detect & clean email collisions across students
    college_emails = {s['college_email'].lower(): reg for reg, s in students_map.items()}
    seen_personal = {}
    for reg, s in sorted(students_map.items()):
        pemail = s['personal_email']
        if pemail:
            pe_lower = pemail.lower()
            if pe_lower in college_emails and college_emails[pe_lower] != reg:
                s['personal_email'] = None
            elif pe_lower in seen_personal and seen_personal[pe_lower] != reg:
                s['personal_email'] = None
            else:
                seen_personal[pe_lower] = reg

def escape_sql(val):
    if val is None:
        return 'NULL'
    val_str = str(val).replace("'", "''")
    return f"'{val_str}'"

def generate_migration_sql():
    parse_all()
    
    all_regs = sorted(students_map.keys())
    
    sql_lines = [
        "-- ============================================================",
        "-- PSGMX Migration 39 — 39_seed_alumni_and_lineage.sql",
        "-- ============================================================",
        "-- Imports 6 historical alumni batches (19MX, 20MX, 21MX, 22MX, 23MX, 24MX)",
        "-- Pre-registers them into whitelist & users tables,",
        "-- and establishes automated roll-number suffix lineage links.",
        "-- Uses public staging tables to prevent Supabase session drop errors.",
        "-- ============================================================",
        "",
        "GRANT ALL PRIVILEGES ON TABLE public.whitelist TO postgres, service_role;",
        "GRANT ALL PRIVILEGES ON TABLE public.whitelist_email_aliases TO postgres, service_role;",
        "GRANT ALL PRIVILEGES ON TABLE public.users TO postgres, service_role;",
        "GRANT ALL PRIVILEGES ON TABLE public.lineage_map TO postgres, service_role;",
        "",
        "BEGIN;",
        "",
        "DROP TABLE IF EXISTS public.seed_temp_alumni CASCADE;",
        "DROP TABLE IF EXISTS public.seed_temp_lineage CASCADE;",
        "",
        "-- 1. Ensure graduated batches exist",
        "INSERT INTO public.batches (batch_code, start_year, end_year, status)",
        "VALUES",
        "    ('19MX', 2019, 2021, 'graduated'),",
        "    ('20MX', 2020, 2022, 'graduated'),",
        "    ('21MX', 2021, 2023, 'graduated'),",
        "    ('22MX', 2022, 2024, 'graduated'),",
        "    ('23MX', 2023, 2025, 'graduated'),",
        "    ('24MX', 2024, 2026, 'graduated')",
        "ON CONFLICT (batch_code) DO UPDATE SET",
        "    status = 'graduated',",
        "    updated_at = now();",
        "",
        "-- 2. Staging table for batch alumni import in public schema",
        "CREATE TABLE public.seed_temp_alumni (",
        "    reg_no TEXT PRIMARY KEY,",
        "    batch_code TEXT NOT NULL,",
        "    name TEXT NOT NULL,",
        "    personal_email TEXT,",
        "    college_email TEXT NOT NULL,",
        "    main_email TEXT NOT NULL UNIQUE,",
        "    gender TEXT,",
        "    section TEXT NOT NULL,",
        "    company TEXT",
        ");",
        "",
        "INSERT INTO public.seed_temp_alumni (reg_no, batch_code, name, personal_email, college_email, main_email, gender, section, company) VALUES"
    ]

    val_tuples = []
    for reg in all_regs:
        s = students_map[reg]
        bcode = s['batch_code']
        sname = s['name'] if s['name'] else f"Alumni {reg}"
        pemail = s['personal_email']
        clemail = s['college_email']
        main_email = (pemail if pemail else clemail).lower()
        section = s['section']
        gender = s['gender']
        company = s['company']
        
        t_str = f"({escape_sql(reg)}, {escape_sql(bcode)}, {escape_sql(sname)}, {escape_sql(pemail)}, {escape_sql(clemail)}, {escape_sql(main_email)}, {escape_sql(gender)}, {escape_sql(section)}, {escape_sql(company)})"
        val_tuples.append(t_str)

    sql_lines.append(",\n".join(val_tuples) + ";")
    sql_lines.extend([
        "",
        "-- 3. Bulk insert into public.whitelist",
        "INSERT INTO public.whitelist (email, personal_email, college_email, name, reg_no, batch, batch_id, gender, role_label, roles)",
        "SELECT",
        "    t.main_email, t.personal_email, t.college_email, t.name, t.reg_no, t.section,",
        "    b.id, t.gender, 'Alumni',",
        "    '{\"isStudent\": false, \"isTeamLeader\": false, \"isCoordinator\": false, \"isPlacementRep\": false}'::jsonb",
        "FROM public.seed_temp_alumni t",
        "JOIN public.batches b ON b.batch_code = t.batch_code",
        "ON CONFLICT (email) DO UPDATE SET",
        "    personal_email = COALESCE(EXCLUDED.personal_email, whitelist.personal_email),",
        "    college_email = COALESCE(EXCLUDED.college_email, whitelist.college_email),",
        "    name = EXCLUDED.name, reg_no = EXCLUDED.reg_no, role_label = 'Alumni';",
        "",
        "-- 4. Bulk insert into public.whitelist_email_aliases",
        "INSERT INTO public.whitelist_email_aliases (email, whitelist_email, email_type)",
        "SELECT lower(t.personal_email), t.main_email, 'personal'",
        "FROM public.seed_temp_alumni t WHERE t.personal_email IS NOT NULL",
        "ON CONFLICT (email) DO NOTHING;",
        "",
        "INSERT INTO public.whitelist_email_aliases (email, whitelist_email, email_type)",
        "SELECT lower(t.college_email), t.main_email, 'college'",
        "FROM public.seed_temp_alumni t",
        "ON CONFLICT (email) DO NOTHING;",
        "",
        "-- 5. Bulk pre-provision auth.users for missing identities",
        "INSERT INTO auth.users (id, instance_id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, role, aud)",
        "SELECT",
        "    gen_random_uuid(), '00000000-0000-0000-0000-000000000000', lower(t.main_email), '', now(),",
        "    '{\"provider\":\"email\",\"providers\":[\"email\"]}'::jsonb, '{}'::jsonb, now(), now(), 'authenticated', 'authenticated'",
        "FROM public.seed_temp_alumni t",
        "WHERE NOT EXISTS (SELECT 1 FROM auth.users au WHERE lower(au.email) = lower(t.main_email))",
        "  AND NOT EXISTS (SELECT 1 FROM public.users u WHERE u.reg_no = t.reg_no)",
        "ON CONFLICT (id) DO NOTHING;",
        "",
        "-- 6. Bulk insert into public.users",
        "INSERT INTO public.users (id, email, personal_email, college_email, reg_no, name, batch, batch_id, gender, role_label, current_company, mentorship_open, onboarding_complete)",
        "SELECT",
        "    COALESCE(u_existing.id, au.id), t.main_email, t.personal_email, t.college_email, t.reg_no, t.name, t.section,",
        "    b.id, t.gender, 'Alumni', t.company, TRUE, TRUE",
        "FROM public.seed_temp_alumni t",
        "JOIN public.batches b ON b.batch_code = t.batch_code",
        "LEFT JOIN auth.users au ON lower(au.email) = lower(t.main_email)",
        "LEFT JOIN public.users u_existing ON u_existing.reg_no = t.reg_no",
        "ON CONFLICT (reg_no) DO UPDATE SET",
        "    personal_email = COALESCE(EXCLUDED.personal_email, users.personal_email),",
        "    college_email = COALESCE(EXCLUDED.college_email, users.college_email),",
        "    name = EXCLUDED.name, role_label = 'Alumni',",
        "    current_company = COALESCE(EXCLUDED.current_company, users.current_company),",
        "    mentorship_open = TRUE;",
        "",
        "DROP TABLE public.seed_temp_alumni CASCADE;",
        "",
        "-- 7. Bulk Roll-Number Suffix Lineage Mappings",
    ])

    suffixes_map = {}
    for reg in all_regs:
        suf = reg[4:]
        bcode = reg[:4]
        suffixes_map.setdefault(suf, {})[bcode] = reg

    for prefix in ['25MX', '26MX']:
        for num in list(range(101, 135)) + list(range(201, 235)) + list(range(301, 335)):
            reg = f"{prefix}{num}"
            suf = str(num)
            suffixes_map.setdefault(suf, {})[prefix] = reg

    batch_rank = {'19MX': 1, '20MX': 2, '21MX': 3, '22MX': 4, '23MX': 5, '24MX': 6, '25MX': 7, '26MX': 8}
    
    lineage_tuples = []
    lineage_links_count = 0
    for suf in sorted(suffixes_map.keys(), key=lambda x: int(x) if x.isdigit() else 999):
        bdict = suffixes_map[suf]
        sorted_batches = sorted(bdict.keys(), key=lambda b: batch_rank.get(b, 99))
        for i in range(len(sorted_batches) - 1):
            senior_b = sorted_batches[i]
            junior_b = sorted_batches[i+1]
            senior_reg = bdict[senior_b]
            junior_reg = bdict[junior_b]
            quote = f"Graduate of PSG Tech MCA {senior_b}"
            
            lineage_tuples.append(f"({escape_sql(junior_reg)}, {escape_sql(senior_reg)}, {escape_sql(quote)})")
            lineage_links_count += 1

    sql_lines.append("CREATE TABLE public.seed_temp_lineage (junior_reg TEXT, senior_reg TEXT, quote TEXT);")
    sql_lines.append("INSERT INTO public.seed_temp_lineage (junior_reg, senior_reg, quote) VALUES")
    sql_lines.append(",\n".join(lineage_tuples) + ";")
    sql_lines.extend([
        "",
        "INSERT INTO public.lineage_map (student_id, senior_user_id, senior_quote, assigned_at)",
        "SELECT u_junior.id, u_senior.id, p.quote, now()",
        "FROM public.seed_temp_lineage p",
        "JOIN public.users u_junior ON u_junior.reg_no = p.junior_reg",
        "JOIN public.users u_senior ON u_senior.reg_no = p.senior_reg",
        "ON CONFLICT (student_id) DO UPDATE SET",
        "    senior_user_id = EXCLUDED.senior_user_id,",
        "    senior_quote = EXCLUDED.senior_quote;",
        "",
        "DROP TABLE public.seed_temp_lineage CASCADE;",
        "",
        "COMMIT;",
        "",
        f"-- Verification summary: Seeding completed for {len(all_regs)} historical alumni and {lineage_links_count} lineage links.",
        "DO $$",
        "DECLARE",
        "    alumni_count INT;",
        "    lineage_count INT;",
        "BEGIN",
        "    SELECT count(*) INTO alumni_count FROM public.users WHERE role_label = 'Alumni';",
        "    SELECT count(*) INTO lineage_count FROM public.lineage_map;",
        "    RAISE NOTICE '✅ Migration 39 complete: % Alumni users, % Lineage mappings.', alumni_count, lineage_count;",
        "END $$;",
        ""
    ])

    migration_path = os.path.join(WORKSPACE, 'supabase', 'migrations', '39_seed_alumni_and_lineage.sql')
    with open(migration_path, 'w') as f:
        f.write('\n'.join(sql_lines))

    print(f"Generated public staging migration {migration_path} with {len(all_regs)} alumni records and {lineage_links_count} lineage mappings.")

if __name__ == '__main__':
    generate_migration_sql()
