require('dotenv').config({ path: '.env' });
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY,
  { auth: { persistSession: false } }
);

async function createTestUser(regNo, email, roleLabel, name) {
  // 1. Create in auth
  const { data: authData, error: authError } = await supabase.auth.admin.createUser({
    email,
    password: 'password123',
    email_confirm: true,
  });
  
  // Get auth user id
  const { data: existingAuth } = await supabase.auth.admin.listUsers();
  const authUser = existingAuth.users.find(u => u.email === email);
  
  if (!authUser) return;

  // Set password to make sure
  await supabase.auth.admin.updateUserById(authUser.id, { password: 'password123' });

  // 2. Insert into users table
  const { error: dbError } = await supabase.from('users').upsert({
    id: authUser.id,
    email,
    reg_no: regNo,
    name,
    batch: 'G1',
    role_label: roleLabel,
    roles: {
      isStudent: roleLabel === 'Student',
      isTeamLeader: false,
      isCoordinator: false,
      isPlacementRep: false
    }
  });
  
  if (dbError) {
    console.error('Error inserting user record:', email, dbError.message);
  } else {
    console.log('Successfully created/updated:', name, `(${roleLabel})`);
  }
}

async function run() {
  await createTestUser('FAC001', 'faculty@psgtech.ac.in', 'Faculty', 'Test Faculty');
  await createTestUser('21MX101', 'alumni@psgtech.ac.in', 'Alumni', 'Test Alumni');
}

run();
