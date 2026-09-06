/**
 * Test 1: Auth & RBAC — role-based dashboard routing
 *
 * Tests:
 * - dashboardPath routes Staff/Faculty → /faculty
 * - dashboardPath routes Placement Rep → /placement-rep
 * - dashboardPath routes Student → /student
 * - dashboardPath routes Alumni → /alumni
 * - Unauthorized (no role) defaults to /student
 * - isStaffEmail correctly identifies staff vs student emails
 * - isStaticStaffOtp only passes for staff with static OTP enabled
 */

import { describe, it, expect, beforeEach, afterEach } from 'vitest'
import {
  dashboardPath,
  isStaffEmail,
  isStaticStaffOtp,
  STATIC_STAFF_OTP,
} from '@/lib/staff-auth'

describe('RBAC: dashboardPath routing', () => {
  it('routes Faculty → /faculty', () => {
    expect(dashboardPath('Faculty')).toBe('/faculty')
  })

  it('routes HOD → /faculty (HOD treated as faculty)', () => {
    expect(dashboardPath('HOD')).toBe('/faculty')
  })

  it('routes Alumni → /alumni', () => {
    expect(dashboardPath('Alumni')).toBe('/alumni')
  })

  it('routes Student without placement rep flag → /student', () => {
    expect(dashboardPath('Student')).toBe('/student')
    expect(dashboardPath('Student', { isPlacementRep: false })).toBe('/student')
  })

  it('routes Student with placement rep flag → /placement-rep', () => {
    expect(dashboardPath('Student', { isPlacementRep: true })).toBe('/placement-rep')
  })

  it('routes null/undefined role → /student (safe default)', () => {
    expect(dashboardPath(null)).toBe('/student')
    expect(dashboardPath(undefined)).toBe('/student')
    expect(dashboardPath('')).toBe('/student')
  })

  it('is case-insensitive for role matching', () => {
    expect(dashboardPath('faculty')).toBe('/faculty')
    expect(dashboardPath('ALUMNI')).toBe('/alumni')
  })
})

describe('RBAC: Staff email identification', () => {
  it('PASS: recognizes all @psgtech.ac.in faculty emails as staff', () => {
    expect(isStaffEmail('ac.mca@psgtech.ac.in')).toBe(true)
    expect(isStaffEmail('nir.mca@psgtech.ac.in')).toBe(true)
    expect(isStaffEmail('vur.mca@psgtech.ac.in')).toBe(true)
  })

  it('PASS: case-insensitive staff email check', () => {
    expect(isStaffEmail('NIR.MCA@PSGTECH.AC.IN')).toBe(true)
    expect(isStaffEmail('AC.MCA@psgtech.ac.in')).toBe(true)
  })

  it('FAIL: rejects student emails as non-staff', () => {
    expect(isStaffEmail('25mx101@psgtech.ac.in')).toBe(false)
    expect(isStaffEmail('student@gmail.com')).toBe(false)
    expect(isStaffEmail('')).toBe(false)
    expect(isStaffEmail(null)).toBe(false)
    expect(isStaffEmail(undefined)).toBe(false)
  })
})

describe('RBAC: Static OTP gate for staff', () => {
  const saved = process.env.ALLOW_STATIC_OTP

  beforeEach(() => {
    process.env.ALLOW_STATIC_OTP = 'true'
  })

  afterEach(() => {
    if (saved === undefined) delete process.env.ALLOW_STATIC_OTP
    else process.env.ALLOW_STATIC_OTP = saved
  })

  it('PASS: accepts static OTP 098765 for a verified staff email', () => {
    expect(isStaticStaffOtp('ac.mca@psgtech.ac.in', STATIC_STAFF_OTP)).toBe(true)
  })

  it('FAIL: rejects static OTP for a non-staff email', () => {
    expect(isStaticStaffOtp('student@gmail.com', STATIC_STAFF_OTP)).toBe(false)
  })

  it('FAIL: rejects wrong OTP even for staff email', () => {
    expect(isStaticStaffOtp('ac.mca@psgtech.ac.in', '000000')).toBe(false)
  })

  it('FAIL: disabled when ALLOW_STATIC_OTP is false', () => {
    process.env.ALLOW_STATIC_OTP = 'false'
    expect(isStaticStaffOtp('ac.mca@psgtech.ac.in', STATIC_STAFF_OTP)).toBe(false)
  })
})
