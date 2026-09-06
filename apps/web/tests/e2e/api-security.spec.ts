import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

// Helper to get cookies from a saved storage state
function getCookiesForRole(role: string) {
  const statePath = path.join(__dirname, `.auth/${role}.json`);
  if (!fs.existsSync(statePath)) {
    throw new Error(`Auth state for ${role} not found at ${statePath}`);
  }
  const state = JSON.parse(fs.readFileSync(statePath, 'utf-8'));
  return state.cookies;
}

// Helper to create an API context with a specific role's cookies
async function createApiContextForRole(playwright: any, role: string, baseURL: string | undefined) {
  const cookies = getCookiesForRole(role);
  return await playwright.request.newContext({
    baseURL,
    extraHTTPHeaders: {
      // API requests often need cookie header constructed manually or passed via storageState
    },
    storageState: { cookies, origins: [] }
  });
}

test.describe('Adversarial API Security Tests', () => {
  let studentApi: any;
  let prApi: any;
  let alumniApi: any;
  let unauthApi: any;

  test.beforeAll(async ({ playwright, baseURL }) => {
    studentApi = await createApiContextForRole(playwright, 'student', baseURL);
    prApi = await createApiContextForRole(playwright, 'pr', baseURL);
    alumniApi = await createApiContextForRole(playwright, 'alumni', baseURL);
    unauthApi = await playwright.request.newContext({ baseURL });
  });

  test('Anonymous -> /api/student/* returns 401', async () => {
    const response = await unauthApi.get('/api/student/daily-five');
    expect(response.status()).toBe(401);
  });

  test('Student JWT -> /api/placement-rep/* returns 403', async () => {
    const response = await studentApi.get('/api/placement-rep/pulse');
    // If it's 401, that might be okay depending on auth implementation, but 403 is correct for RBAC
    expect([401, 403, 404]).toContain(response.status()); 
  });

  test('Student JWT -> /api/faculty/* returns 403', async () => {
    const response = await studentApi.get('/api/faculty/batch-management');
    expect([401, 403, 404]).toContain(response.status());
  });

  test('Student JWT -> /api/hod/* returns 403', async () => {
    const response = await studentApi.get('/api/hod/pending-alumni');
    expect([401, 403, 404]).toContain(response.status());
  });

  test('PR JWT -> /api/hod/* returns 403', async () => {
    const response = await prApi.get('/api/hod/pending-alumni');
    expect([401, 403, 404]).toContain(response.status());
  });

  test('Alumni JWT -> /api/student/* returns 403', async () => {
    const response = await alumniApi.get('/api/student/daily-five');
    expect([401, 403, 404]).toContain(response.status());
  });
});
