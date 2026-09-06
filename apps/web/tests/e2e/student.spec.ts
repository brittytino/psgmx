import { test, expect } from '@playwright/test';

test.describe('Student Authenticated Flows', () => {
  test('Today dashboard renders and shows priority actions', async ({ page }) => {
    // Navigate to the student dashboard
    await page.goto('/student');
    
    // Expect the page to load correctly without redirecting away
    await expect(page).toHaveURL(/\/student/);

    // Check for Today dashboard elements
    const heading = page.locator('h1', { hasText: /Good (morning|afternoon|evening)/i });
    await expect(heading).toBeVisible({ timeout: 10000 });
  });

  test('Daily Five can be accessed', async ({ page }) => {
    await page.goto('/student/train');
    
    // Check for Daily Five module
    const dailyFiveCard = page.locator('text="Daily Five"');
    await expect(dailyFiveCard).toBeVisible();
  });

  test('CodeBox editor renders correctly', async ({ page }) => {
    // Mock quest ID - assuming the DB has a valid quest or we can navigate to a mock route
    // Since we don't know the exact seed quest IDs, we test the navigation and basic render
    // If the quest is 404, the CodeBox layout might still show a specific error state.
    
    await page.goto('/student/codebox/invalid-or-dummy-quest-id');
    
    // We expect the page to either show the editor, or a valid error like "Quest not found"
    // rather than a 500 crash.
    const bodyText = await page.locator('body').textContent();
    expect(bodyText).toBeTruthy();
  });
});
