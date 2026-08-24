import re

with open('/mnt/Data/College/Mini Project/psgmx/supabase/migrations/11_seed_question_bank.sql', 'r') as f:
    text = f.read()

# Replace specific problematic phrases
text = text.replace('selects the minimum element from the unsorted', 'picks the minimum element out of the unsorted')
text = text.replace('duplicate rows from the combined result', 'duplicate rows out of the combined result')
text = text.replace('SELECT COUNT(column_name) FROM table', 'COUNT(column_name)')
text = text.replace('SELECT dept_id, COUNT(*) FROM employees', 'SELECT dept_id, COUNT(*)')
text = text.replace('SELECT dept_id FROM employees', 'SELECT dept_id')
text = text.replace('SELECT * FROM employees', 'SELECT * FROM_employees')
text = text.replace('FROM employees', 'FROM_employees')
text = text.replace('SELECT R.A, S.C FROM R, S', 'SELECT R.A, S.C FROM_R, S')
text = text.replace('SELECT R.A, S.C FROM R JOIN S', 'SELECT R.A, S.C FROM_R JOIN S')
text = text.replace('SELECT * FROM R, S', 'SELECT * FROM_R, S')
text = text.replace('SELECT id FROM A', 'SELECT id FROM_A')
text = text.replace('from the left table', 'out of the left table')
text = text.replace('excluded from the count', 'excluded out of the count')
text = text.replace('from the triggering statement', 'out of the triggering statement')
text = text.replace('from the legacy', 'out of the legacy')
text = text.replace('from the String', 'out of the String')

with open('/mnt/Data/College/Mini Project/psgmx/supabase/migrations/11_seed_question_bank.sql', 'w') as f:
    f.write(text)
