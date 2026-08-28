import { afterEach, describe, expect, it } from 'vitest'
import {
  dashboardPath,
  isStaffEmail,
  isStaticOtpEnabled,
  isStaticStaffOtp,
  STAFF_ROSTER,
  STATIC_STAFF_OTP,
} from '@/lib/staff-auth'

describe('staff roster', () => {
  it('includes both HODs and 19 staff emails', () => {
    expect(STAFF_ROSTER).toHaveLength(19)
    expect(STAFF_ROSTER.filter((row) => row.role === 'HOD').map((row) => row.email).sort()).toEqual([
      'ac.mca@psgtech.ac.in',
      'nir.mca@psgtech.ac.in',
    ])
  })

  it('recognizes faculty department emails', () => {
    expect(isStaffEmail('NIR.MCA@psgtech.ac.in')).toBe(true)
    expect(isStaffEmail('25mx101@psgtech.ac.in')).toBe(false)
  })
})

describe('dashboardPath', () => {
  it('sends both HOD and faculty to the faculty portal', () => {
    expect(dashboardPath('HOD')).toBe('/faculty')
    expect(dashboardPath('Faculty')).toBe('/faculty')
  })

  it('sends placement reps to their console', () => {
    expect(dashboardPath('Student', { isPlacementRep: true })).toBe('/placement-rep')
    expect(dashboardPath('Student')).toBe('/student')
  })
})

describe('static staff OTP', () => {
  const previous = process.env.ALLOW_STATIC_OTP

  afterEach(() => {
    if (previous === undefined) delete process.env.ALLOW_STATIC_OTP
    else process.env.ALLOW_STATIC_OTP = previous
  })

  it('accepts 098765 for faculty when enabled', () => {
    process.env.ALLOW_STATIC_OTP = 'true'
    expect(isStaticOtpEnabled()).toBe(true)
    expect(isStaticStaffOtp('nir.mca@psgtech.ac.in', STATIC_STAFF_OTP)).toBe(true)
    expect(isStaticStaffOtp('agileshnv2005@gmail.com', STATIC_STAFF_OTP)).toBe(false)
  })

  it('can be disabled even outside production', () => {
    process.env.ALLOW_STATIC_OTP = 'false'
    expect(isStaticOtpEnabled()).toBe(false)
    expect(isStaticStaffOtp('ac.mca@psgtech.ac.in', STATIC_STAFF_OTP)).toBe(false)
  })

  it('is disabled unless explicitly enabled', () => {
    delete process.env.ALLOW_STATIC_OTP
    expect(isStaticOtpEnabled()).toBe(false)
  })
})
