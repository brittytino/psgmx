import { defineConfig, devices } from '@playwright/test'
import * as dotenv from 'dotenv'

// Read from default ".env.local" file.
dotenv.config({ path: '.env.local' })

export default defineConfig({
  testDir: './tests/e2e',
  use: { 
    baseURL: process.env.PLAYWRIGHT_BASE_URL || 'http://127.0.0.1:3000', 
    trace: 'retain-on-failure',
  },
  webServer: process.env.PLAYWRIGHT_BASE_URL ? undefined : { 
    command: 'npm run dev', 
    url: 'http://127.0.0.1:3000', 
    reuseExistingServer: true,
    timeout: 120 * 1000,
  },
  projects: [
    { name: 'setup', testMatch: /.*\.setup\.ts/ },
    {
      name: 'student',
      testMatch: /student\.spec\.ts/,
      use: { ...devices['Desktop Chrome'], storageState: 'tests/e2e/.auth/student.json' },
      dependencies: ['setup'],
    },
    {
      name: 'pr',
      testMatch: /pr-admin\.spec\.ts/,
      use: { ...devices['Desktop Chrome'], storageState: 'tests/e2e/.auth/pr.json' },
      dependencies: ['setup'],
    },
    {
      name: 'faculty-hod',
      testMatch: /faculty-hod\.spec\.ts/,
      use: { ...devices['Desktop Chrome'], storageState: 'tests/e2e/.auth/faculty.json' },
      dependencies: ['setup'],
    },
    {
      name: 'api-security',
      testMatch: /api-security\.spec\.ts/,
      use: { ...devices['Desktop Chrome'] }, // We will dynamically load storage states in the test
      dependencies: ['setup'],
    },
    {
      name: 'public-smoke',
      testMatch: /public-smoke\.spec\.ts/,
      use: { ...devices['Desktop Chrome'] },
    }
  ],
})
