import { test, expect } from '@playwright/test';

test.describe('PR Admin Authenticated Flows', () => {
  test('PR can access the placement-rep dashboard', async ({ page }) => {
    await page.goto('/placement-rep');
    
    // Check that we are on the PR dashboard and not redirected to /student
    await expect(page).toHaveURL(/\/placement-rep/);
    
    const heading = page.locator('h1', { hasText: /Dashboard/i });
    await expect(heading).toBeVisible();
  });

  test('PR can navigate to Members & Import', async ({ page }) => {
    await page.goto('/placement-rep/members');
    
    const importHeading = page.locator('h2', { hasText: /Import/i });
    await expect(importHeading).toBeVisible();
    
    // Check if the CSV download button is available
    const downloadBtn = page.locator('button', { hasText: /Template/i });
    await expect(downloadBtn).toBeVisible();
  });
});
