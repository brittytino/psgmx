import { expect, test } from '@playwright/test'

test('student OTP and staff OTP login modes are reachable', async ({ page }) => {
  await page.goto('/login')
  await expect(page.getByRole('heading', { name: /Sign in to PSGMX/i })).toBeVisible()
  await expect(page.getByRole('button', { name: 'Student OTP' })).toBeVisible()
  await page.getByRole('button', { name: 'Faculty / HOD' }).click()
  await expect(page.getByRole('button', { name: 'Send secure code' })).toBeVisible()
  await expect(page.getByText('Password', { exact: true })).toHaveCount(0)
})

test('alumni onboarding derives the admission batch before OTP enrollment', async ({ page }) => {
  await page.goto('/join-alumni')
  await expect(page.getByRole('heading', { name: /Join the alumni network/i })).toBeVisible()
  await page.getByLabel('MCA register number').fill('21mx114')
  await expect(page.getByText('21MX · 2021–2023')).toBeVisible()
  await expect(page.getByRole('button', { name: 'Continue with secure OTP' })).toBeVisible()
})

test('health endpoint returns a declared platform state', async ({ request }) => {
  const response = await request.get('/api/health')
  expect([200, 503]).toContain(response.status())
  expect(['healthy', 'degraded']).toContain((await response.json()).status)
})
