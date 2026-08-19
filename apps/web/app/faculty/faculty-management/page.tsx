import { createClient } from '@/lib/supabase/server';
import FacultyManagementClient from './FacultyManagementClient';

export const dynamic = 'force-dynamic';

export default async function FacultyManagementPage() {
  const supabase = await createClient();

  const { data: facultyDocs } = await supabase
    .from('users')
    .select('id, email, name, role_label, created_at')
    .in('role_label', ['Faculty', 'HOD'])
    .order('created_at', { ascending: false });

  const faculties = (facultyDocs || []).map((doc) => ({
    id: doc.id,
    name: doc.name,
    email: doc.email,
    roleLabel: doc.role_label,
    createdAt: doc.created_at,
  }));

  return (
    <div className="max-w-[1400px] mx-auto space-y-8 pb-8">
      <div>
        <h1 className="text-[26px] font-bold text-text-main tracking-tight mb-1">Faculty Management</h1>
        <p className="text-[14px] text-text-muted">View faculty accounts. HOD-only — new accounts are created via Supabase Auth invites.</p>
      </div>
      <FacultyManagementClient initialFaculties={faculties} />
    </div>
  );
}
