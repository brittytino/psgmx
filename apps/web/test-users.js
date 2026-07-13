require('dotenv').config({ path: '.env' });
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY,
  { auth: { persistSession: false } }
);

async function test() {
  const { data, error } = await supabase.from('users').select('id, email, roll_no, role').limit(5);
  console.log('Users in DB:', data, error);
  
  // also check auth.users if possible
  const { data: authUsers, error: authError } = await supabase.auth.admin.listUsers();
  console.log('Auth Users:', authUsers?.users?.length, authError);
}

test();
