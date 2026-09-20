/**
 * Normalizes text before it is interpolated into a PostgREST `.or()` filter.
 * Commas, parentheses, percent signs and underscores have meaning in that
 * grammar, so they are converted to spaces instead of becoming predicates or
 * unbounded wildcards.
 */
export function normalizeSearchTerm(value: unknown, maxLength = 80): string {
  if (typeof value !== 'string') return ''
  return value
    .normalize('NFKC')
    .replace(/[,%_()'"\\]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim()
    .slice(0, maxLength)
}
