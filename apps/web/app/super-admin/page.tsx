import React from 'react';
import { Database, BrainCircuit, Activity, Users } from 'lucide-react';
import { createClient } from '@/lib/supabase/server';

export const dynamic = 'force-dynamic';

export default async function SuperAdminDashboard() {
  const supabase = await createClient();

  const [
    { count: totalFaculty },
    { count: totalStudents },
    { count: totalArticles },
    { count: totalAlumni },
  ] = await Promise.all([
    supabase.from('users').select('id', { count: 'exact', head: true }).eq('role', 'faculty'),
    supabase.from('users').select('id', { count: 'exact', head: true }).eq('role', 'student'),
    supabase.from('knowledge_brain_articles').select('id', { count: 'exact', head: true }).eq('approval_status', 'approved'),
    supabase.from('users').select('id', { count: 'exact', head: true }).eq('role', 'alumni'),
  ]);

  const stats = [
    { label: 'Active Faculty', value: totalFaculty ?? 0, icon: Users, color: 'text-blue-400', bg: 'bg-blue-400/10' },
    { label: 'Active Students', value: totalStudents ?? 0, icon: Users, color: 'text-purple-400', bg: 'bg-purple-400/10' },
    { label: 'Knowledge Articles', value: totalArticles ?? 0, icon: BrainCircuit, color: 'text-green-400', bg: 'bg-green-400/10' },
    { label: 'Alumni', value: totalAlumni ?? 0, icon: Database, color: 'text-orange-400', bg: 'bg-orange-400/10' },
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
            <p className="text-sm text-text-muted">Use the sidebar to navigate to specific management modules. All data is now powered by Supabase.</p>
          </div>
        </div>
      </div>
    </div>
  );
}
