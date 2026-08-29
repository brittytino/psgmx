'use client';

import React from 'react';
import { Activity, ShieldAlert, TrendingUp, Users, Award, BookOpen, Brain, Code2, MessageSquare } from 'lucide-react';

export default function ReadinessPulsePage() {
  const batchStats = {
    batchCode: '25MX',
    totalStudents: 68,
    activeThisWeekPct: 84,
    avgReadinessScore: 68.4,
    dimensions: [
      { name: 'Aptitude & Reasoning', avg: 72, icon: Brain, status: 'Healthy' },
      { name: 'Coding & Problem Solving', avg: 65, icon: Code2, status: 'Building' },
      { name: 'Core Computer Science', avg: 58, icon: BookOpen, status: 'Needs Focus' },
      { name: 'Communication & Interview', avg: 74, icon: MessageSquare, status: 'Healthy' },
      { name: 'Assessment Performance', avg: 69, icon: Award, status: 'Healthy' },
      { name: 'Portfolio & Project Proof', avg: 73, icon: TrendingUp, status: 'Healthy' },
    ],
    declineSignalCount: 4, // forwarded to faculty automatically
  };

  return (
    <div className="max-w-6xl mx-auto space-y-6 pb-12">
      <div>
        <span className="text-xs font-bold text-brand-600 uppercase tracking-wider block">
          Batch-Level Aggregates · PRD Chapter 6.3 & 16.1
        </span>
        <h1 className="text-2xl font-black text-slate-900 mt-1 flex items-center gap-2">
          <Activity className="w-6 h-6 text-brand-600" />
          Batch Readiness Pulse ({batchStats.batchCode})
        </h1>
        <p className="text-sm text-slate-500">
          Aggregated batch trends only. In strict compliance with the PRD privacy model, individual student scores are never exposed to peer representatives.
        </p>
      </div>

      {/* Summary Stat Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm">
          <span className="text-xs font-bold text-slate-500 uppercase block">Active Students</span>
          <div className="text-2xl font-black text-slate-900 mt-1">{batchStats.totalStudents}</div>
          <span className="text-xs text-emerald-600 font-bold mt-1 block">
            {batchStats.activeThisWeekPct}% active this week
          </span>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm">
          <span className="text-xs font-bold text-slate-500 uppercase block">Batch Average Readiness</span>
          <div className="text-2xl font-black text-brand-600 mt-1">{batchStats.avgReadinessScore}/100</div>
          <span className="text-xs text-slate-400 mt-1 block">Normalized 6-dimension average</span>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm">
          <span className="text-xs font-bold text-slate-500 uppercase block">Strongest Dimension</span>
          <div className="text-2xl font-black text-emerald-600 mt-1">Communication</div>
          <span className="text-xs text-slate-400 mt-1 block">74% average score</span>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm">
          <span className="text-xs font-bold text-slate-500 uppercase block">Priority Focus Area</span>
          <div className="text-2xl font-black text-amber-600 mt-1">Core CS (DBMS)</div>
          <span className="text-xs text-slate-400 mt-1 block">Recommended: Core CS Clinic</span>
        </div>
      </div>

      {/* Dimension Breakdown */}
      <div className="bg-white rounded-2xl border border-slate-200 p-6 shadow-sm space-y-4">
        <h3 className="text-sm font-bold text-slate-900 uppercase tracking-wider border-b border-slate-100 pb-3">
          6-Dimension Aggregate Mastery Distribution
        </h3>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {batchStats.dimensions.map((dim) => {
            const Icon = dim.icon;
            return (
              <div key={dim.name} className="p-4 rounded-xl border border-slate-100 bg-slate-50 space-y-3">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2 text-xs font-bold text-slate-800">
                    <Icon className="w-4 h-4 text-brand-600" />
                    {dim.name}
                  </div>
                  <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${
                    dim.status === 'Healthy' ? 'bg-emerald-100 text-emerald-800' :
                    dim.status === 'Building' ? 'bg-blue-100 text-blue-800' : 'bg-amber-100 text-amber-800'
                  }`}>
                    {dim.status}
                  </span>
                </div>

                <div className="flex items-end justify-between">
                  <span className="text-2xl font-black text-slate-900">{dim.avg}%</span>
                  <span className="text-xs text-slate-400">Batch Avg</span>
                </div>

                <div className="h-1.5 w-full bg-slate-200 rounded-full overflow-hidden">
                  <div className="h-full bg-brand-500 rounded-full" style={{ width: `${dim.avg}%` }} />
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Privacy Guard Notice */}
      <div className="p-4 bg-slate-50 border border-slate-200 rounded-xl flex items-center justify-between text-xs text-slate-600">
        <div className="flex items-center gap-2 font-medium">
          <ShieldAlert className="w-4 h-4 text-slate-400" />
          <span>{batchStats.declineSignalCount} students showing evidence decline signals have been automatically routed to Faculty Recovery Hub.</span>
        </div>
        <span className="font-mono text-slate-400">PRD Privacy Model V1.1</span>
      </div>
    </div>
  );
}
