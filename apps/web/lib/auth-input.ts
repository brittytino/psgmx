export const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/

export function normalizeEmail(value: unknown): string | null {
  if (typeof value !== 'string') return null
  const email = value.trim().toLowerCase()
  if (email.length > 254 || !EMAIL_PATTERN.test(email)) return null
  return email
}

export interface RosterStudentInput {
  name: string
  reg_no: string
  personal_email?: string
  college_email?: string
  alternate_personal_emails?: string[]
  section?: 'G1' | 'G2'
  team_code?: string
  gender?: string
}

function normalizeEmailList(value: unknown): string[] {
  const rawValues = Array.isArray(value)
    ? value
    : typeof value === 'string'
      ? value.split(/\s*(?:\/|;|,)\s*/)
      : []

  return [...new Set(rawValues.map(normalizeEmail).filter((email): email is string => Boolean(email)))]
}

export function normalizeRosterStudent(value: unknown): RosterStudentInput | null {
  if (!value || typeof value !== 'object') return null
  const row = value as Record<string, unknown>
  const name = typeof row.name === 'string' ? row.name.trim() : ''
  const regNo = typeof row.reg_no === 'string' ? row.reg_no.trim().toUpperCase() : ''
  const personal = row.personal_email ? normalizeEmail(row.personal_email) : null
  const college = row.college_email ? normalizeEmail(row.college_email) : null
  const alternateEmails = normalizeEmailList(
    row.alternate_personal_emails
      ?? row.alternate_personal_email
      ?? row.alternate_email
      ?? row.email_aliases,
  ).filter((email) => email !== personal && email !== college)
  const rawSection = typeof row.section === 'string'
    ? row.section.trim().toUpperCase()
    : typeof row.batch === 'string'
      ? row.batch.trim().toUpperCase()
      : ''
  const section = rawSection === 'G1' || rawSection === 'G2' ? rawSection : undefined

  // A roster row may be preloaded before an email is collected. It remains
  // unable to request OTP until a valid personal or college address is added.
  if (!name || !regNo) return null

  return {
    name,
    reg_no: regNo,
    personal_email: personal ?? undefined,
    college_email: college ?? undefined,
    alternate_personal_emails: alternateEmails.length ? alternateEmails : undefined,
    section,
    team_code: typeof row.team_code === 'string' ? row.team_code.trim().toUpperCase() : undefined,
    gender: typeof row.gender === 'string' ? row.gender.trim() : undefined,
  }
}
