import React from 'react';
import { createClient } from '@/lib/supabase/server';
import FacultyClientPage from './FacultyClientPage';

export const dynamic = 'force-dynamic';

export default async function FacultyPage() {
  const supabase = await createClient();
  
  const { data: facultyDocs } = await supabase
    .from('users')
    .select('*')
    .eq('role', 'faculty')
    .order('created_at', { ascending: false });

  const faculties = (facultyDocs || []).map((doc: any) => ({
    _id: doc.id,
    username: doc.email,
    fullName: doc.full_name || '',
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
