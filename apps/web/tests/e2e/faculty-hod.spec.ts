import { test, expect } from '@playwright/test';

test.describe('Faculty and HOD Authenticated Flows', () => {
  test('Faculty can access the faculty dashboard', async ({ page }) => {
    // Navigate to faculty dashboard. In playwright config, this uses faculty state.
    await page.goto('/faculty');
    
    // Check that we are on the faculty dashboard
    await expect(page).toHaveURL(/\/faculty/);
    
    // Check for some faculty specific element
    const heading = page.locator('h1');
    await expect(heading).toBeVisible();
  });

  test('Faculty can navigate to Assessment Studio', async ({ page }) => {
    await page.goto('/faculty/assessment-studio');
    
    // Wait for the assessment studio to load
    await expect(page).toHaveURL(/\/faculty\/assessment-studio/);
  });
  
  // Note: HOD tests will require the HOD state. We can add a separate describe block for HOD
  // if we set up a separate project for HOD in playwright.config.ts, or we can use test.use() 
  // to override the storage state for specific tests.
});

test.describe('HOD Authenticated Flows', () => {
  // Override storage state for HOD
  test.use({ storageState: 'tests/e2e/.auth/hod.json' });

  test('HOD can access the governance dashboard', async ({ page }) => {
    await page.goto('/faculty/governance');
    
    // Check that we are on the governance dashboard
    await expect(page).toHaveURL(/\/faculty\/governance/);
  });
});
