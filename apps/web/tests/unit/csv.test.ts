import { describe, expect, it } from 'vitest'
import { parseCsv } from '@/lib/csv'

describe('roster CSV parsing', () => {
  it('supports quoted commas and escaped quotes', () => {
    const rows = parseCsv('name,reg_no,personal_email\n"Student, One",26MX001,"student""one@example.com"')
    expect(rows).toEqual([{
      name: 'Student, One',
      reg_no: '26MX001',
      personal_email: 'student"one@example.com',
    }])
  })

  it('accepts a UTF-8 BOM and CRLF rows', () => {
    expect(parseCsv('\uFEFFsection,name,reg_no\r\nG2,Student Two,26MX302\r\n')[0])
      .toMatchObject({ section: 'G2', reg_no: '26MX302' })
  })
})
