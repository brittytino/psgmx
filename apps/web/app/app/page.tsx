import { redirect } from 'next/navigation'
import { createClient } from '@/lib/supabase/server'
import { supabaseAdmin } from '@/lib/supabase/admin'

export default async function AppPage() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()

  if (!user) {
    redirect('/login')
  }

  // Get user role
  const { data: profile } = await supabaseAdmin
    .from('users')
    .select('role_label')
    .eq('id', user.id)
    .single()

  const roleLabel = profile?.role_label?.toLowerCase() || 'student'
  
  if (roleLabel === 'faculty' || roleLabel === 'hod') redirect('/faculty')
  if (roleLabel === 'alumni') redirect('/alumni')
  
  redirect('/student')
}
