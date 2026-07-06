import React from 'react';
import { createClient } from '@/lib/supabase/server';
import StudentsClientPage from './StudentsClientPage';

export const dynamic = 'force-dynamic';

export default async function StudentsPage() {
  const supabase = await createClient();
  
  const { data: studentDocs } = await supabase
    .from('users')
    .select('*')
    .eq('role', 'student')
    .order('created_at', { ascending: false })
    .limit(100);

  const students = (studentDocs || []).map((doc: any) => ({
    _id: doc.id,
    token: doc.roll_no || '',
    fullName: doc.full_name || '',
    email: doc.email || '',
    accountType: doc.app_role || 'student',
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
