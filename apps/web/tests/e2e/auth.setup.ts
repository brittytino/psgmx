import { test as setup } from '@playwright/test';
import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'http://127.0.0.1:54321';
const supabaseServiceRole = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || '';
const baseUrl = process.env.PLAYWRIGHT_BASE_URL || 'http://127.0.0.1:3000';

const supabase = createClient(supabaseUrl, supabaseServiceRole, {
  auth: { persistSession: false },
});

async function ensureTestUser(email: string, regNo: string, roleLabel: string, name: string, isPlacementRep = false) {
  // 1. Create in auth
  const { data: authData, error: authError } = await supabase.auth.admin.createUser({
    email,
    password: 'password123',
    email_confirm: true,
  });

  let authUser = authData?.user;

  if (authError && authError.message.includes('already has an account') || authError?.status === 422) {
    const { data: existingAuth } = await supabase.auth.admin.listUsers();
    authUser = existingAuth.users.find((u: any) => u.email === email);
    if (authUser) {
      await supabase.auth.admin.updateUserById(authUser.id, { password: 'password123' });
    }
  }

  if (!authUser) throw new Error(`Failed to create or find test user ${email}: ${authError?.message}`);

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
      isPlacementRep: isPlacementRep,
    },
    onboarding_complete: true, // skip onboarding wizard for main tests
  });

  if (dbError) {
    throw new Error(`Error inserting user record: ${dbError.message}`);
  }
}

const TEST_USERS = {
  student: { email: 'student_e2e@example.com', regNo: '25MXE2E1', role: 'Student', name: 'Test Student', pr: false },
  pr: { email: 'pr_e2e@example.com', regNo: '25MXE2E2', role: 'Student', name: 'Test PR', pr: true },
  faculty: { email: 'faculty_e2e@psgtech.ac.in', regNo: 'FACE2E1', role: 'Faculty', name: 'Test Faculty', pr: false },
  hod: { email: 'hod_e2e@psgtech.ac.in', regNo: 'FACE2E2', role: 'HOD', name: 'Test HOD', pr: false },
  alumni: { email: 'alumni_e2e@example.com', regNo: '23MXE2E1', role: 'Alumni', name: 'Test Alumni', pr: false },
};

async function loginAndSaveState(page: any, user: typeof TEST_USERS[keyof typeof TEST_USERS], storageStatePath: string) {
  await page.goto(`${baseUrl}/login`);
  await page.fill('input[name="identifier"]', user.email);
  await page.fill('input[name="password"]', 'password123');
  await page.click('button[type="submit"]');
  
  // Wait for redirect to dashboard
  await page.waitForURL((url: URL) => url.pathname !== '/login' && !url.pathname.includes('/auth'), { timeout: 15000 });
  await page.context().storageState({ path: storageStatePath });
}

for (const [role, user] of Object.entries(TEST_USERS)) {
  setup(`authenticate ${role}`, async ({ page }) => {
    await ensureTestUser(user.email, user.regNo, user.role, user.name, user.pr);
    await loginAndSaveState(page, user, `./tests/e2e/.auth/${role}.json`);
  });
}
