import { describe, expect, it } from 'vitest'
import {
  collegeEmailForRegisterNumber,
  normalizeEmail,
  normalizeRosterStudent,
  parseBatchFromRegisterNumber,
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
    expect(collegeEmailForRegisterNumber('29MX407')).toBe('29mx407@psgtech.ac.in')
  })

  it('resolves a college address back to its register number', () => {
    expect(registerNumberFromCollegeEmail('26MX301@psgtech.ac.in')).toBe('26MX301')
    expect(registerNumberFromCollegeEmail('31mx112@psgtech.ac.in')).toBe('31MX112')
    expect(registerNumberFromCollegeEmail('person@gmail.com')).toBeNull()
  })
})

describe('MCA batch derivation for alumni and students', () => {
  it('correctly derives 1990s batches as 1900s and 3-year program', () => {
    const batch96 = parseBatchFromRegisterNumber('96MX101')
    expect(batch96).toEqual({
      code: '96MX',
      startYear: 1996,
      endYear: 1999,
      isGraduated: true,
    })

    const batch84 = parseBatchFromRegisterNumber('84MX001')
    expect(batch84).toEqual({
      code: '84MX',
      startYear: 1984,
      endYear: 1987,
      isGraduated: true,
    })
  })

  it('correctly derives 2000s and 2010s batches', () => {
    const batch05 = parseBatchFromRegisterNumber('05MX105')
    expect(batch05).toEqual({
      code: '05MX',
      startYear: 2005,
      endYear: 2008,
      isGraduated: true,
    })
  })

  it('correctly handles the 2019 (3-year) vs 2020 (2-year) curriculum transition', () => {
    // Upto 19MX (2019): 3-year MCA (2019 - 2022)
    const batch19 = parseBatchFromRegisterNumber('19MX101')
    expect(batch19).toEqual({
      code: '19MX',
      startYear: 2019,
      endYear: 2022,
      isGraduated: true,
    })

    // From 20MX (2020) onwards: 2-year MCA (2020 - 2022)
    const batch20 = parseBatchFromRegisterNumber('20MX101')
    expect(batch20).toEqual({
      code: '20MX',
      startYear: 2020,
      endYear: 2022,
      isGraduated: true,
    })

    const batch21 = parseBatchFromRegisterNumber('21MX114')
    expect(batch21).toEqual({
      code: '21MX',
      startYear: 2021,
      endYear: 2023,
      isGraduated: true,
    })

    const batch24 = parseBatchFromRegisterNumber('24MX101')
    expect(batch24).toEqual({
      code: '24MX',
      startYear: 2024,
      endYear: 2026,
      isGraduated: true,
    })
  })

  it('identifies active batches that are not yet graduated', () => {
    const batch25 = parseBatchFromRegisterNumber('25MX354')
    expect(batch25?.startYear).toBe(2025)
    expect(batch25?.endYear).toBe(2027)
    expect(batch25?.isGraduated).toBe(false)

    const batch26 = parseBatchFromRegisterNumber('26MX101')
    expect(batch26?.startYear).toBe(2026)
    expect(batch26?.endYear).toBe(2028)
    expect(batch26?.isGraduated).toBe(false)
  })
})
