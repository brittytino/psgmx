export const STATIC_STAFF_OTP = '098765'

export type StaffRole = 'Faculty' | 'HOD'

export interface StaffMember {
  name: string
  email: string
  role: StaffRole
  regNo: string
}

/** Current HOD and previous HOD both keep HOD-gated screens. */
export const STAFF_ROSTER: StaffMember[] = [
  { name: 'Dr. Chitra A', email: 'ac.mca@psgtech.ac.in', role: 'HOD', regNo: 'FAC-AC' },
  { name: 'Dr. Umarani V', email: 'vur.mca@psgtech.ac.in', role: 'Faculty', regNo: 'FAC-VUR' },
  { name: 'Dr. Ilayaraja N', email: 'nir.mca@psgtech.ac.in', role: 'HOD', regNo: 'FAC-NIR' },
  { name: 'Dr. Geetha N', email: 'sng.mca@psgtech.ac.in', role: 'Faculty', regNo: 'FAC-SNG' },
  { name: 'Dr. Bhama S', email: 'sba.mca@psgtech.ac.in', role: 'Faculty', regNo: 'FAC-SBA' },
  { name: 'Dr. Venkatesan V', email: 'vvn.mca@psgtech.ac.in', role: 'Faculty', regNo: 'FAC-VVN' },
  { name: 'Dr. Bhuvaneswari A', email: 'abh.mca@psgtech.ac.in', role: 'Faculty', regNo: 'FAC-ABH' },
  { name: 'Dr. Manavalan R', email: 'vrm.mca@psgtech.ac.in', role: 'Faculty', regNo: 'FAC-VRM' },
  { name: 'Mrs. Gowri Thangam J', email: 'jgt.mca@psgtech.ac.in', role: 'Faculty', regNo: 'FAC-JGT' },
  { name: 'Dr. Subathra M', email: 'msa.mca@psgtech.ac.in', role: 'Faculty', regNo: 'FAC-MSA' },
  { name: 'Mrs. Aarthi J', email: 'jaa.mca@psgtech.ac.in', role: 'Faculty', regNo: 'FAC-JAA' },
  { name: 'Mrs. Aarthi Mai A S', email: 'asa.mca@psgtech.ac.in', role: 'Faculty', regNo: 'FAC-ASA' },
  { name: 'Mrs. Gayathri Devi T', email: 'tdg.mca@psgtech.ac.in', role: 'Faculty', regNo: 'FAC-TDG' },
  { name: 'Mrs. Aruna R', email: 'ran.mca@psgtech.ac.in', role: 'Faculty', regNo: 'FAC-RAN' },
  { name: 'Mrs. Kalyani A', email: 'akk.mca@psgtech.ac.in', role: 'Faculty', regNo: 'FAC-AKK' },
  { name: 'Mrs. Manoranjitham A', email: 'amr.mca@psgtech.ac.in', role: 'Faculty', regNo: 'FAC-AMR' },
  { name: 'Mrs. Rajeswari N', email: 'nrj.mca@psgtech.ac.in', role: 'Faculty', regNo: 'FAC-NRJ' },
  { name: 'Mr. Sundar C', email: 'csc.mca@psgtech.ac.in', role: 'Faculty', regNo: 'FAC-CSC' },
  { name: 'Mr. Shankar S', email: 'sss.mca@psgtech.ac.in', role: 'Faculty', regNo: 'FAC-SSS' },
]

const STAFF_EMAILS = new Set(STAFF_ROSTER.map((member) => member.email))

export function isStaffEmail(email: string | null | undefined): boolean {
  return Boolean(email && STAFF_EMAILS.has(email.trim().toLowerCase()))
}

export function isStaticOtpEnabled(): boolean {
  return process.env.ALLOW_STATIC_OTP === 'true'
}

export function isStaticStaffOtp(email: string, token: string): boolean {
  return isStaticOtpEnabled() && isStaffEmail(email) && token.trim() === STATIC_STAFF_OTP
}

export function dashboardPath(
  roleLabel: string | null | undefined,
  roles?: { isPlacementRep?: boolean } | null,
): string {
  const role = (roleLabel || '').toLowerCase()
  if (role === 'faculty' || role === 'hod') return '/faculty'
  if (role === 'alumni') return '/alumni'
  if (role === 'student' && roles?.isPlacementRep === true) return '/placement-rep'
  return '/student'
}
