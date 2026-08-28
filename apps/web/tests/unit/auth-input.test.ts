import { describe, expect, it } from 'vitest'
import {
  collegeEmailForRegisterNumber,
  normalizeEmail,
  normalizeRosterStudent,
  registerNumberFromCollegeEmail,
} from '@/lib/auth-input'

describe('dual-email roster validation', () => {
  it('normalizes personal email without requiring the college domain', () => {
    expect(normalizeEmail(' Student.Personal@Gmail.com ')).toBe('student.personal@gmail.com')
  })

  it('accepts a 26MX student with only personal email', () => {
    expect(normalizeRosterStudent({ name: 'Student One', reg_no: '26mx001', personal_email: 'one@example.com' }))
      .toMatchObject({ name: 'Student One', reg_no: '26MX001', personal_email: 'one@example.com' })
  })

  it('accepts college and personal email on one roster row', () => {
    const row = normalizeRosterStudent({ name: 'Student Two', reg_no: '26MX002', personal_email: 'two@example.com', college_email: '26mx002@psgtech.ac.in' })
    expect(row?.personal_email).toBe('two@example.com')
    expect(row?.college_email).toBe('26mx002@psgtech.ac.in')
  })

  it('keeps an email-pending student on the roster', () => {
    expect(normalizeRosterStudent({ name: 'Student Three', reg_no: '26MX003', section: 'g2' }))
      .toMatchObject({ name: 'Student Three', reg_no: '26MX003', section: 'G2' })
  })

  it('normalizes alternate personal email aliases', () => {
    expect(normalizeRosterStudent({
      name: 'Student Four',
      reg_no: '26MX004',
      personal_email: 'primary@example.com',
      alternate_personal_email: ' Alternate@Example.com / primary@example.com ',
    })?.alternate_personal_emails).toEqual(['alternate@example.com'])
  })
})

describe('MCA college identity', () => {
  it('derives a stable college address from the register number', () => {
    expect(collegeEmailForRegisterNumber('26MX301')).toBe('26mx301@psgtech.ac.in')
    expect(collegeEmailForRegisterNumber(' 26mx331 ')).toBe('26mx331@psgtech.ac.in')
  })

  it('resolves a college address back to its register number', () => {
    expect(registerNumberFromCollegeEmail('26MX301@psgtech.ac.in')).toBe('26MX301')
    expect(registerNumberFromCollegeEmail('person@gmail.com')).toBeNull()
  })
})
