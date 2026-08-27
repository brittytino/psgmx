import { expect, test } from '@playwright/test'

test('student OTP and staff OTP login modes are reachable', async ({ page }) => {
  await page.goto('/login')
  await expect(page.getByRole('heading', { name: /Sign in to PSGMX/i })).toBeVisible()
  await expect(page.getByRole('button', { name: 'Student OTP' })).toBeVisible()
  await page.getByRole('button', { name: 'Faculty / HOD' }).click()
  await expect(page.getByRole('button', { name: 'Send secure code' })).toBeVisible()
  await expect(page.getByText('Password', { exact: true })).toHaveCount(0)
})

test('health endpoint returns a declared platform state', async ({ request }) => {
  const response = await request.get('/api/health')
  expect([200, 503]).toContain(response.status())
  expect(['healthy', 'degraded']).toContain((await response.json()).status)
})
