import React from 'react';
import connectDB from '@/lib/mongodb';
import UserAccount from '@/models/UserAccount';
import FacultyClientPage from './FacultyClientPage';

export const dynamic = 'force-dynamic';

export default async function FacultyPage() {
  await connectDB();
  
  const facultyDocs = await UserAccount.find({ role: 'faculty' })
    .select('-password')
    .sort({ createdAt: -1 })
    .lean();

  const faculties = facultyDocs.map((doc: any) => ({
    _id: doc._id.toString(),
    username: doc.username,
    fullName: doc.fullName || '',
    email: doc.email || '',
    status: doc.status,
    createdAt: doc.createdAt.toISOString()
  }));

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-white tracking-tight">Faculty Management</h1>
        <p className="text-text-muted mt-2">Create and manage faculty accounts.</p>
      </div>
      <FacultyClientPage initialFaculties={faculties} />
    </div>
  );
}
