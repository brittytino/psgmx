import { createClient } from '@/lib/supabase/server';
import BatchManagementClient from './BatchManagementClient';

export const dynamic = 'force-dynamic';

export default async function BatchManagementPage() {
  const supabase = await createClient();

  const [{ data: studentDocs }, { data: batches }] = await Promise.all([
    supabase
      .from('users')
      .select('id, email, name, reg_no, batch_id, created_at')
      .eq('role_label', 'Student')
      .order('created_at', { ascending: false })
      .limit(200),
    supabase.from('batches').select('id, batch_code, status').order('start_year', { ascending: false }),
  ]);

  const batchMap = new Map((batches || []).map((b) => [b.id, b.batch_code]));

  const students = (studentDocs || []).map((doc) => ({
    id: doc.id,
    name: doc.name,
    email: doc.email,
    regNo: doc.reg_no,
    batchCode: doc.batch_id ? batchMap.get(doc.batch_id) || '—' : '—',
    createdAt: doc.created_at,
  }));

  return (
    <div className="max-w-[1400px] mx-auto space-y-8 pb-8">
      <div>
        <h1 className="text-[26px] font-bold text-text-main tracking-tight mb-1">Batch Management</h1>
        <p className="text-[14px] text-text-muted">All student records across batches (showing latest 200). HOD-only.</p>
      </div>
      <BatchManagementClient initialStudents={students} batches={(batches || []).map((b) => ({ id: b.id, code: b.batch_code, status: b.status }))} />
    </div>
  );
}
