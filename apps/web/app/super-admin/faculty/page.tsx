import React from 'react';
import { createClient } from '@/lib/supabase/server';
import FacultyClientPage from './FacultyClientPage';

export const dynamic = 'force-dynamic';

export default async function FacultyPage() {
  const supabase = await createClient();
  
  // Explicit column list — never select('*') on `users` (see
  // 08_security_fixes_sprint0.sql: ecampus_password is column-level
  // REVOKEd for the authenticated role). Also fixed the pre-existing
  // filter/mapping (`role`/`full_name` don't exist live; the live columns
  // are `role_label`/`name`) since this was already non-functional.
  const { data: facultyDocs } = await supabase
    .from('users')
    .select('id, email, name, role_label, created_at')
    .eq('role_label', 'Faculty')
    .order('created_at', { ascending: false });

  const faculties = (facultyDocs || []).map((doc: any) => ({
    _id: doc.id,
    username: doc.email,
    fullName: doc.name || '',
    email: doc.email || '',
    status: 'active',
    createdAt: doc.created_at
  }));

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-white tracking-tight">Faculty Management</h1>
        <p className="text-text-muted mt-2">View faculty accounts (use Supabase Auth to create new ones).</p>
      </div>
      <FacultyClientPage initialFaculties={faculties} />
    </div>
  );
}
