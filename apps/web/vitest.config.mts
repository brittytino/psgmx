import { defineConfig } from 'vitest/config'
import path from 'node:path'

export default defineConfig({
  test: {
    environment: 'node',
    include: ['tests/unit/**/*.test.ts'],
    coverage: { reporter: ['text', 'json-summary'] },
  },
  resolve: { alias: { '@': path.resolve(import.meta.dirname, '.') } },
})
