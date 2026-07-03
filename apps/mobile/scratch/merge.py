import json
import re
import csv
from datetime import datetime

# 1. Parse the TSV new data
new_data = {}
with open('new_data.tsv', 'r') as f:
    for line in f:
        parts = line.strip().split('\t')
        if len(parts) == 5:
            email, regno, name, gender, dob = parts
            # Convert DOB format '10/22/2005' to 'YYYY-MM-DD'
            try:
                dt = datetime.strptime(dob, '%m/%d/%Y')
                formatted_dob = dt.strftime('%Y-%m-%d')
            except:
                formatted_dob = 'NULL'
            
            new_data[email.lower()] = {
                'email': email.lower(),
                'reg_no': regno.upper(),
                'name': name,
                'gender': gender,
                'dob': formatted_dob
            }

# 2. Extract old SQL from transcript
transcript_path = '/home/brittytino/.gemini/antigravity-ide/brain/9eb1052f-0de9-46b6-8f1e-3d9a4b8d5777/.system_generated/logs/transcript.jsonl'
old_data = {}

# Parse backwards to find the user prompt containing the INSERT statement
with open(transcript_path, 'r') as f:
    lines = f.readlines()
    for line in reversed(lines):
        step = json.loads(line)
        if step.get('type') == 'USER_INPUT' and 'INSERT INTO public.whitelist' in step.get('content', ''):
            content = step['content']
            # Find all tuples: ('email', 'name', 'reg_no', 'batch', 'team_id', 'dob', 'leetcode_username', 'roles')
            # Using a regex to extract the contents of the tuples
            matches = re.findall(r"\(\s*'([^']+)'\s*,\s*'([^']+)'\s*,\s*'([^']+)'\s*,\s*'([^']+)'\s*,\s*'([^']+)'\s*,\s*(NULL|'[^']+?')\s*,\s*(NULL|'[^']+?')\s*,\s*'(\{[^}]+\})'\s*\)", content)
            
            for m in matches:
                email = m[0].lower()
                lc_user = m[6].strip("'") if m[6] != 'NULL' else 'NULL'
                old_data[email] = {
                    'email': email,
                    'batch': m[3],
                    'team_id': m[4],
                    'leetcode_username': lc_user,
                    'roles': m[7]
                }
            break

# 3. Merge and Generate SQL
# We will use all users in new_data. If they existed in old_data, we keep their team, batch, leetcode, roles.
# If they didn't, we assign defaults.
merged = []
for email, d in new_data.items():
    o = old_data.get(email, {})
    batch = o.get('batch', 'G1')
    team_id = o.get('team_id', 'T00')
    lc_user = o.get('leetcode_username', 'NULL')
    roles = o.get('roles', '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}')
    
    # We will add 'gender' to whitelist if possible, or just keep it standard.
    # The user asked to "give me that fully include all these data and give me correct along with this include their leetcode"
    
    # Let's generate the whitelist tuple. We also add Gender column dynamically in the script if needed, or just insert it.
    # The schema doesn't have gender, but we can ALtER TABLE in the SQL script.
    
    lc_str = f"'{lc_user}'" if lc_user != 'NULL' else "NULL"
    dob_str = f"'{d['dob']}'" if d['dob'] != 'NULL' else "NULL"
    
    merged.append(f"('{d['email']}', '{d['name']}', '{d['reg_no']}', '{d['gender']}', '{batch}', '{team_id}', {dob_str}, {lc_str}, '{roles}')")

sql = f"""-- ========================================
-- PSG MX PLACEMENT APP - FRESH FLUSH & SEED
-- ========================================

-- 1) FLUSH ALL EXISTING DATA
TRUNCATE TABLE public.audit_logs CASCADE;
TRUNCATE TABLE public.task_completions CASCADE;
TRUNCATE TABLE public.attendance_records CASCADE;
TRUNCATE TABLE public.leetcode_stats CASCADE;
TRUNCATE TABLE public.whitelist CASCADE;
TRUNCATE TABLE public.users CASCADE;

-- Also clear auth.users for these emails (run with care!)
-- We will delete auth.users that correspond to public.users or whitelist.
DELETE FROM auth.users 
WHERE email IN (SELECT email FROM public.whitelist) 
   OR email IN (SELECT email FROM public.users)
   OR email LIKE '%@psgtech.ac.in%';

-- 2) ADD GENDER COLUMN TO WHITELIST (if missing)
ALTER TABLE public.whitelist ADD COLUMN IF NOT EXISTS gender TEXT;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS gender TEXT;

-- 3) INSERT NEW MERGED WHITELIST
INSERT INTO public.whitelist (email, name, reg_no, gender, batch, team_id, dob, leetcode_username, roles) VALUES
{",\n".join(merged)}
ON CONFLICT (email) DO UPDATE SET
    name = EXCLUDED.name,
    reg_no = EXCLUDED.reg_no,
    gender = EXCLUDED.gender,
    batch = EXCLUDED.batch,
    team_id = EXCLUDED.team_id,
    dob = EXCLUDED.dob,
    leetcode_username = EXCLUDED.leetcode_username,
    roles = EXCLUDED.roles;

-- 4) SEED LEETCODE STATS
INSERT INTO public.leetcode_stats (username, total_solved, easy_solved, medium_solved, hard_solved, ranking)
SELECT 
    leetcode_username,
    0, 0, 0, 0, 0
FROM public.whitelist
WHERE leetcode_username IS NOT NULL AND leetcode_username != ''
ON CONFLICT (username) DO NOTHING;

-- 5) BULK CREATE AUTH.USERS
INSERT INTO auth.users (
    id, instance_id, email, encrypted_password, email_confirmed_at, 
    created_at, updated_at, aud, role, raw_app_meta_data, raw_user_meta_data, 
    is_super_admin, confirmation_token, email_change, email_change_token_new, recovery_token
)
SELECT
    gen_random_uuid(),
    '00000000-0000-0000-0000-000000000000'::uuid,
    w.email,
    crypt(gen_random_uuid()::text, gen_salt('bf')),
    NOW(), NOW(), NOW(),
    'authenticated', 'authenticated',
    '{{"provider": "email", "providers": ["email"]}}'::jsonb,
    jsonb_build_object('name', w.name, 'reg_no', w.reg_no),
    false, '', '', '', ''
FROM public.whitelist w
WHERE NOT EXISTS (
    SELECT 1 FROM auth.users au WHERE lower(au.email) = lower(w.email)
);

-- 6) BULK CREATE PUBLIC.USERS
WITH wl_auth AS (
    SELECT
        au.id AS auth_id, w.email, w.reg_no, w.name, w.gender, w.team_id,
        COALESCE(w.batch, 'G1') AS batch,
        COALESCE(w.roles, '{{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}}'::jsonb) AS roles,
        w.leetcode_username, w.dob
    FROM public.whitelist w
    JOIN auth.users au ON lower(au.email) = lower(w.email)
)
INSERT INTO public.users (
    id, email, reg_no, name, gender, team_id, batch, roles, 
    leetcode_username, dob, birthday_notifications_enabled, 
    leetcode_notifications_enabled, task_reminders_enabled, 
    attendance_alerts_enabled, announcements_enabled, created_at, updated_at
)
SELECT
    wa.auth_id, wa.email, wa.reg_no, wa.name, wa.gender, wa.team_id, wa.batch, wa.roles,
    wa.leetcode_username, wa.dob, TRUE, TRUE, TRUE, TRUE, TRUE, NOW(), NOW()
FROM wl_auth wa
WHERE NOT EXISTS (
    SELECT 1 FROM public.users u WHERE u.id = wa.auth_id
);

"""

with open('../database/22_fresh_seed_data.sql', 'w') as f:
    f.write(sql)

print(f"Generated 22_fresh_seed_data.sql with {len(merged)} users!")
