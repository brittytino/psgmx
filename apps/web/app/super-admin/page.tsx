import React from 'react';
import { Database, BrainCircuit, Activity, Users } from 'lucide-react';
import connectDB from '@/lib/mongodb';
import UserAccount from '@/models/UserAccount';
import KnowledgeBrainArticle from '@/models/KnowledgeBrainArticle';
import FYPRepository from '@/models/FYPRepository';

export const dynamic = 'force-dynamic';

export default async function SuperAdminDashboard() {
  await connectDB();
  
  const [
    totalFaculty,
    totalStudents,
    totalArticles,
    totalFYPs
  ] = await Promise.all([
    UserAccount.countDocuments({ role: 'faculty' }),
    UserAccount.countDocuments({ role: 'student' }),
    KnowledgeBrainArticle.countDocuments(),
    FYPRepository.countDocuments()
  ]);

  const stats = [
    { label: 'Active Faculty', value: totalFaculty, icon: Users, color: 'text-blue-400', bg: 'bg-blue-400/10' },
    { label: 'Active Students', value: totalStudents, icon: Users, color: 'text-purple-400', bg: 'bg-purple-400/10' },
    { label: 'Knowledge Cores', value: totalArticles, icon: BrainCircuit, color: 'text-green-400', bg: 'bg-green-400/10' },
    { label: 'FYP Repositories', value: totalFYPs, icon: Database, color: 'text-orange-400', bg: 'bg-orange-400/10' },
  ];

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-3xl font-bold text-white tracking-tight">System Overview</h1>
        <p className="text-text-muted mt-2">Real-time status of the PSGMX Department OS.</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {stats.map((stat, i) => {
          const Icon = stat.icon;
          return (
            <div key={i} className="bg-black/20 border border-border rounded-2xl p-6">
              <div className="flex justify-between items-start">
                <div>
                  <p className="text-sm font-medium text-text-muted uppercase tracking-wider">{stat.label}</p>
                  <p className="text-4xl font-bold text-white mt-4">{stat.value}</p>
                </div>
                <div className={`p-3 rounded-xl ${stat.bg} ${stat.color}`}>
                  <Icon className="w-6 h-6" />
                </div>
              </div>
            </div>
          );
        })}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-black/20 border border-border rounded-2xl p-6">
          <div className="flex items-center gap-3 mb-6">
            <Activity className="w-5 h-5 text-electric-blue" />
            <h2 className="text-lg font-bold text-white">Quick Actions</h2>
          </div>
          <div className="space-y-3">
            <p className="text-sm text-text-muted">Use the sidebar to navigate to specific management modules. Faculty creation requires usernames of 3-5 characters.</p>
            {/* We could add quick links here if desired */}
          </div>
        </div>
      </div>
    </div>
  );
}
