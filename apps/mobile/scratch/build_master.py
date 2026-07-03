import re
import csv
import sys

def build():
    # 1. Parse gender from new_data.tsv
    genders = {}
    try:
        with open('scratch/new_data.tsv', 'r') as f:
            reader = csv.reader(f, delimiter='\t')
            for row in reader:
                if len(row) >= 4:
                    genders[row[0].strip().lower()] = row[3].strip()
    except Exception as e:
        print("Error reading TSV:", e)
        return

    # 2. Parse pasted_seed.sql and inject gender
    with open('scratch/pasted_seed.sql', 'r') as f:
        seed_content = f.read()

    # Replace the INSERT header to include gender
    seed_content = seed_content.replace(
        'INSERT INTO public.whitelist (email, name, reg_no, batch, team_id, dob, leetcode_username, roles) VALUES',
        'INSERT INTO public.whitelist (email, name, reg_no, gender, batch, team_id, dob, leetcode_username, roles) VALUES'
    )
    
    # We also need to add gender to the ON CONFLICT statement
    seed_content = seed_content.replace(
        'reg_no = EXCLUDED.reg_no,',
        'reg_no = EXCLUDED.reg_no,\n    gender = EXCLUDED.gender,'
    )

    # Now find all tuple lines
    new_seed_lines = []
    for line in seed_content.split('\n'):
        if line.startswith("('") and line.endswith("),") or line.endswith(")"):
            # It's a tuple line. Extract email to find gender.
            match = re.match(r"\('([^']+)'", line)
            if match:
                email = match.group(1).lower()
                gender = genders.get(email, 'Unknown')
                # Inject 'Gender', right after reg_no (which is the 3rd field)
                # The format is: ('email', 'name', 'reg_no', 'batch', ...
                # We want: ('email', 'name', 'reg_no', 'gender', 'batch', ...
                parts = line.split("', '")
                if len(parts) >= 4:
                    # parts[2] ends with the reg_no
                    # But wait, parts is split by "', '". 
                    # Actually, it's safer to use regex to insert after the 3rd string
                    
                    # Instead of parsing SQL with regex strings, let's just do a simple replacement
                    # Find the reg_no part. parts[2] is reg_no.
                    # Ex: line: ('25mx101@psgtech.ac.in', 'BALAJI K', '25MX101', 'G1', 'T20', ...
                    # We can use regex to match the first 3 string fields:
                    # ^\('([^']+)', '([^']+)', '([^']+)', (.*)
                    tuple_match = re.match(r"^\('([^']+)', '([^']+)', '([^']+)', (.*)", line)
                    if tuple_match:
                        new_line = f"('{tuple_match.group(1)}', '{tuple_match.group(2)}', '{tuple_match.group(3)}', '{gender}', {tuple_match.group(4)}"
                        new_seed_lines.append(new_line)
                    else:
                        new_seed_lines.append(line)
                else:
                    new_seed_lines.append(line)
            else:
                new_seed_lines.append(line)
        else:
            new_seed_lines.append(line)

    modified_seed = '\n'.join(new_seed_lines)

    # 3. Read all files 01 through 21
    import os
    db_dir = 'database'
    sql_files = sorted([f for f in os.listdir(db_dir) if f.endswith('.sql') and f.startswith(('0', '1', '20', '21'))])
    
    master_content = []
    
    # Prepend drop schema
    master_content.append("-- ========================================")
    master_content.append("-- PSG MX PLACEMENT APP - FULL REBUILD")
    master_content.append("-- ========================================")
    master_content.append("DROP SCHEMA IF EXISTS public CASCADE;")
    master_content.append("CREATE SCHEMA public;")
    master_content.append("GRANT ALL ON SCHEMA public TO postgres;")
    master_content.append("GRANT ALL ON SCHEMA public TO public;")
    master_content.append("")
    
    for sql_file in sql_files:
        with open(os.path.join(db_dir, sql_file), 'r') as f:
            master_content.append(f"-- ========================================")
            master_content.append(f"-- {sql_file}")
            master_content.append(f"-- ========================================")
            master_content.append(f.read())
            master_content.append("")

    # Append seed
    master_content.append("-- ========================================")
    master_content.append("-- 22_SEED_DATA.sql")
    master_content.append("-- ========================================")
    master_content.append(modified_seed)

    # Write master file
    with open(os.path.join(db_dir, '00_MASTER_DB.sql'), 'w') as f:
        f.write('\n'.join(master_content))

    print(f"Master file created: database/00_MASTER_DB.sql with {len(modified_seed.split())} words in seed.")

if __name__ == '__main__':
    build()
