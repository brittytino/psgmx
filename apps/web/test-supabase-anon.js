require('dotenv').config({ path: '.env' });
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY,
  { auth: { persistSession: false } }
);

async function test() {
  const { data, error } = await supabase.from('batches').select('*').limit(1);
  console.log('Anon Data:', data);
  console.log('Anon Error:', error);
}

test();
