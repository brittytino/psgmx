require('dotenv').config({ path: '.env' });
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY,
  { auth: { persistSession: false } }
);

async function test() {
  const { data, error } = await supabase.from('users').select('*').ilike('reg_no', '25MX354').single();
  console.log('User 25MX354:', data, error);
  
  if (data) {
    // Set their password to 'password123' so the user can test
    const { data: authData, error: authError } = await supabase.auth.admin.updateUserById(
      data.id,
      { password: 'password123' }
    );
    console.log('Updated Auth User Password to password123:', authError ? authError.message : 'Success');
  }
}

test();
