import { createClient } from '@supabase/supabase-js'
import dotenv from 'dotenv'
import { dirname, resolve } from 'path'
import { fileURLToPath } from 'url'

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..')
dotenv.config({ path: resolve(root, '.env') })
dotenv.config({ path: resolve(root, '.env.local') })
dotenv.config({ path: resolve(root, '../../.env') })

const STAFF = [
  ['Dr. Chitra A', 'ac.mca@psgtech.ac.in', 'HOD', 'FAC-AC'],
  ['Dr. Umarani V', 'vur.mca@psgtech.ac.in', 'Faculty', 'FAC-VUR'],
  ['Dr. Ilayaraja N', 'nir.mca@psgtech.ac.in', 'HOD', 'FAC-NIR'],
  ['Dr. Geetha N', 'sng.mca@psgtech.ac.in', 'Faculty', 'FAC-SNG'],
  ['Dr. Bhama S', 'sba.mca@psgtech.ac.in', 'Faculty', 'FAC-SBA'],
  ['Dr. Venkatesan V', 'vvn.mca@psgtech.ac.in', 'Faculty', 'FAC-VVN'],
  ['Dr. Bhuvaneswari A', 'abh.mca@psgtech.ac.in', 'Faculty', 'FAC-ABH'],
  ['Dr. Manavalan R', 'vrm.mca@psgtech.ac.in', 'Faculty', 'FAC-VRM'],
  ['Mrs. Gowri Thangam J', 'jgt.mca@psgtech.ac.in', 'Faculty', 'FAC-JGT'],
  ['Dr. Subathra M', 'msa.mca@psgtech.ac.in', 'Faculty', 'FAC-MSA'],
  ['Mrs. Aarthi J', 'jaa.mca@psgtech.ac.in', 'Faculty', 'FAC-JAA'],
  ['Mrs. Aarthi Mai A S', 'asa.mca@psgtech.ac.in', 'Faculty', 'FAC-ASA'],
  ['Mrs. Gayathri Devi T', 'tdg.mca@psgtech.ac.in', 'Faculty', 'FAC-TDG'],
  ['Mrs. Aruna R', 'ran.mca@psgtech.ac.in', 'Faculty', 'FAC-RAN'],
  ['Mrs. Kalyani A', 'akk.mca@psgtech.ac.in', 'Faculty', 'FAC-AKK'],
  ['Mrs. Manoranjitham A', 'amr.mca@psgtech.ac.in', 'Faculty', 'FAC-AMR'],
  ['Mrs. Rajeswari N', 'nrj.mca@psgtech.ac.in', 'Faculty', 'FAC-NRJ'],
  ['Mr. Sundar C', 'csc.mca@psgtech.ac.in', 'Faculty', 'FAC-CSC'],
  ['Mr. Shankar S', 'sss.mca@psgtech.ac.in', 'Faculty', 'FAC-SSS'],
]

const url = process.env.NEXT_PUBLIC_SUPABASE_URL
const key = process.env.SUPABASE_SERVICE_ROLE_KEY
if (!url || !key) {
  console.error('Missing NEXT_PUBLIC_SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY')
  process.exit(1)
}

const supabase = createClient(url, key, { auth: { persistSession: false, autoRefreshToken: false } })
const staffRoles = { isStudent: false, isTeamLeader: false, isCoordinator: false, isPlacementRep: false }

async function findAuthUser(email) {
  let page = 1
  while (page <= 10) {
    const { data, error } = await supabase.auth.admin.listUsers({ page, perPage: 200 })
    if (error) throw error
    const match = data.users.find((user) => user.email?.toLowerCase() === email)
    if (match) return match
    if (data.users.length < 200) return null
    page += 1
  }
  return null
}

async function seedOne(name, email, role, regNo) {
  const whitelistRow = {
    email,
    college_email: email,
    name,
    reg_no: regNo,
    batch: 'G1',
    role_label: role,
    roles: staffRoles,
  }
  let { error: whitelistError } = await supabase.from('whitelist').upsert(whitelistRow, { onConflict: 'email' })
  if (whitelistError && /role_label/i.test(whitelistError.message)) {
    const { role_label, ...withoutRole } = whitelistRow
    const fallback = await supabase.from('whitelist').upsert(withoutRole, { onConflict: 'email' })
    whitelistError = fallback.error
  }
  if (whitelistError) throw whitelistError

  const created = await supabase.auth.admin.createUser({ email, email_confirm: true })
  const authUser = created.data.user ?? await findAuthUser(email)
  if (!authUser) throw created.error ?? new Error(`No auth user for ${email}`)

  const { error: userError } = await supabase.from('users').upsert({
    id: authUser.id,
    email,
    college_email: email,
    name,
    reg_no: regNo,
    batch: 'G1',
    role_label: role,
    roles: staffRoles,
    onboarding_complete: true,
  }, { onConflict: 'id' })
  if (userError) throw userError

  console.log(`OK  ${role.padEnd(7)} ${email}  ${name}`)
}

async function run() {
  const { error: studentError } = await supabase
    .from('users')
    .update({ onboarding_complete: true })
    .eq('onboarding_complete', false)
  if (studentError) console.warn('Could not flip student onboarding_complete:', studentError.message)

  for (const row of STAFF) {
    try {
      await seedOne(...row)
    } catch (error) {
      console.error(`FAIL ${row[1]}:`, error.message || error)
      process.exitCode = 1
    }
  }
}

run()
