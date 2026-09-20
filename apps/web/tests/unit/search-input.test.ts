import { describe, expect, it } from 'vitest'
import { normalizeSearchTerm } from '@/lib/search-input'

describe('normalizeSearchTerm', () => {
  it('keeps useful human search text', () => {
    expect(normalizeSearchTerm('  DBMS ACID + Java  ')).toBe('DBMS ACID + Java')
  })

  it('removes PostgREST filter grammar characters', () => {
    expect(normalizeSearchTerm('foo),id.eq.secret%_')).toBe('foo id.eq.secret')
  })

  it('limits oversized searches', () => {
    expect(normalizeSearchTerm('a'.repeat(200))).toHaveLength(80)
  })
})
