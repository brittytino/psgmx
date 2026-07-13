require('dotenv').config({ path: '.env' });
const { createClient } = require('@supabase/supabase-js');

// Mutate the last character of the service role key to invalidate signature
const invalidKey = process.env.SUPABASE_SERVICE_ROLE_KEY.slice(0, -1) + 'a';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL,
  invalidKey,
  { auth: { persistSession: false } }
);

async function test() {
  const { data, error } = await supabase.from('batches').select('*').limit(1);
  console.log('Invalid Key Error:', error);
}

test();
