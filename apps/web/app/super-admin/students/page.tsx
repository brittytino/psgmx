import React from 'react';
import connectDB from '@/lib/mongodb';
import UserAccount from '@/models/UserAccount';
import StudentsClientPage from './StudentsClientPage';

export const dynamic = 'force-dynamic';

export default async function StudentsPage() {
  await connectDB();
  
  const studentDocs = await UserAccount.find({ role: 'student' })
    .select('-password')
    .sort({ createdAt: -1 })
    .limit(100) // pagination or limit for performance
    .lean();

  const students = studentDocs.map((doc: any) => ({
    _id: doc._id.toString(),
    token: doc.token || '',
    fullName: doc.fullName || '',
    email: doc.email || '',
    accountType: doc.accountType,
    status: doc.status,
  }));

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-white tracking-tight">Student Management</h1>
        <p className="text-text-muted mt-2">Manage student records and trigger impersonation.</p>
      </div>
      <StudentsClientPage initialStudents={students} />
    </div>
  );
}
