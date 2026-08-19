import React from 'react';
import { createClient } from '@/lib/supabase/server';
import StudentsClientPage from './StudentsClientPage';

export const dynamic = 'force-dynamic';

export default async function StudentsPage() {
  const supabase = await createClient();
  
  // Explicit column list — never select('*') on `users`. ecampus_password
  // is column-level REVOKEd for the authenticated role, so a wildcard
  // select here would error the whole request.
  //
  // NOTE: this route pre-dates the live schema (it filters on a `role`
  // column and reads `roll_no`/`full_name`/`app_role`, none of which exist
  // on the live `users` table — see 08_security_fixes_sprint0.sql header).
  // It is already non-functional against production independent of this
  // fix, and this whole page is slated for removal when /super-admin/*
  // folds into /faculty/* (plan Section 10) — not re-wired here.
  const { data: studentDocs } = await supabase
    .from('users')
    .select('id, email, name, reg_no, team_id, batch, batch_id, gender, roles, ' +
      'dob, role_label, leetcode_username, ecampus_password_set, created_at, updated_at')
    .eq('role_label', 'Student')
    .order('created_at', { ascending: false })
    .limit(100);

  const students = (studentDocs || []).map((doc: any) => ({
    _id: doc.id,
    token: doc.reg_no || '',
    fullName: doc.name || '',
    email: doc.email || '',
    accountType: doc.role_label || 'student',
    status: 'active',
  }));

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-white tracking-tight">Student Management</h1>
        <p className="text-text-muted mt-2">Manage student records (showing latest 100).</p>
      </div>
      <StudentsClientPage initialStudents={students} />
    </div>
  );
}
