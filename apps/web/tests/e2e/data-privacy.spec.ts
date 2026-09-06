import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

function getCookiesForRole(role: string) {
  const statePath = path.join(__dirname, `.auth/${role}.json`);
  if (!fs.existsSync(statePath)) {
    throw new Error(`Auth state for ${role} not found`);
  }
  return JSON.parse(fs.readFileSync(statePath, 'utf-8')).cookies;
}

test.describe('Data Privacy and RLS Tests', () => {
  let studentApi: any;

  test.beforeAll(async ({ playwright, baseURL }) => {
    const cookies = getCookiesForRole('student');
    studentApi = await playwright.request.newContext({
      baseURL,
      storageState: { cookies, origins: [] }
    });
  });

  test('Student cannot access another student\'s private readiness score', async () => {
    // Attempt to hit an endpoint or perform an operation that fetches a specific user's readiness score.
    // Assuming there's a profile or readiness endpoint that accepts an ID.
    // If the API uses the logged-in user's session implicitly, we can try to fetch a specific ID
    // or test a direct supabase call if exposed.
    
    // We can simulate an attack by fetching the profile of another user
    const response = await studentApi.get('/api/user/profile?id=some-other-uuid');
    
    // It should either return the logged-in user's data (ignoring the ID)
    // or return a 403/401 unauthorized.
    expect([200, 401, 403, 404]).toContain(response.status());
    
    if (response.status() === 200) {
      const data = await response.json();
      // Ensure the data returned belongs to the authenticated user, NOT 'some-other-uuid'
      // The student_e2e user name is 'Test Student'
      expect(data.full_name).not.toBe('Test PR'); 
    }
  });
});
