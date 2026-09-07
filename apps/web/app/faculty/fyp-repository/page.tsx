'use client';

import React from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Folder, Download, Search, FileCode, CheckCircle, Activity, Archive, Clock, ExternalLink } from 'lucide-react';
import { InitialsAvatar } from '@/components/basic/InitialsAvatar';
import { createClient } from '@/lib/supabase/client';
import { getCurrentProfile } from '@/lib/current-profile';

type Project = {
  id: string;
  title: string;
  description: string | null;
  guide_name: string | null;
  team_members_count: number;
  status: 'proposal' | 'in_progress' | 'completed' | 'archived';
  repository_url: string | null;
  created_at: string;
  users?: { name: string; email: string; reg_no: string } | null;
};

type ProgressUpdate = { id: string; note: string; created_at: string; project_id: string; project_title: string };

const STATUS_META: Record<Project['status'], { label: string; className: string; barClass: string }> = {
  proposal: { label: 'Proposal', className: 'border-illus-gold/30 text-illus-gold bg-white', barClass: 'bg-illus-gold' },
  in_progress: { label: 'In Progress', className: 'border-primary-purple text-primary-purple bg-page-bg', barClass: 'bg-primary-purple' },
  completed: { label: 'Completed', className: 'border-electric-blue/30 text-electric-blue bg-white', barClass: 'bg-electric-blue' },
  archived: { label: 'Archived', className: 'border-deep-violet/30 text-deep-violet bg-page-bg', barClass: 'bg-deep-violet' },
};

const TABS = ['All Projects', 'My Mentored', 'Proposal', 'In Progress', 'Completed', 'Archived'] as const;

function toCsv(rows: Project[]): string {
  const header = ['Title', 'Student', 'Register No', 'Guide', 'Status', 'Members', 'Repository', 'Created'];
  const lines = rows.map(p => [
    p.title, p.users?.name ?? '', p.users?.reg_no ?? '', p.guide_name ?? '',
    STATUS_META[p.status]?.label ?? p.status, String(p.team_members_count),
    p.repository_url ?? '', new Date(p.created_at).toISOString().slice(0, 10),
  ].map(field => `"${String(field).replace(/"/g, '""')}"`).join(','));
  return [header.join(','), ...lines].join('\n');
}

export default function FacultyFYPRepositoryDashboard() {
  const supabase = React.useMemo(() => createClient(), []);
  const [activeTab, setActiveTab] = React.useState<typeof TABS[number]>('All Projects');
  const [projects, setProjects] = React.useState<Project[]>([]);
  const [updates, setUpdates] = React.useState<ProgressUpdate[]>([]);
  const [myName, setMyName] = React.useState('');
  const [loading, setLoading] = React.useState(true);
  const [visibleCount, setVisibleCount] = React.useState(6);
  const [searchQuery, setSearchQuery] = React.useState('');

  React.useEffect(() => {
    (async () => {
      setLoading(true);
      try {
        const me = await getCurrentProfile(supabase);
        setMyName(me?.name ?? '');

        const [projectsRes, updatesRes] = await Promise.all([
          fetch('/api/projects'),
          supabase
            .from('fyp_progress_logs')
            .select('id, note, created_at, project_id, fyp_projects(title)')
            .order('created_at', { ascending: false })
            .limit(6),
        ]);

        if (projectsRes.ok) {
          const data = await projectsRes.json();
          if (data.success) setProjects(data.projects ?? []);
        }

        const updateRows = (updatesRes.data ?? []) as unknown as Array<{ id: string; note: string; created_at: string; project_id: string; fyp_projects: { title: string } | null }>;
        setUpdates(updateRows.map(row => ({ id: row.id, note: row.note, created_at: row.created_at, project_id: row.project_id, project_title: row.fyp_projects?.title ?? 'FYP project' })));
      } catch (err) {
        console.error('Failed to load FYP repository:', err);
      } finally {
        setLoading(false);
      }
    })();
  }, [supabase]);

  const filteredProjects = projects.filter(p => {
    const haystack = `${p.title} ${p.users?.reg_no ?? ''} ${p.guide_name ?? ''}`.toLowerCase();
    if (!haystack.includes(searchQuery.toLowerCase())) return false;
    if (activeTab === 'My Mentored') return !!myName && p.guide_name?.toLowerCase() === myName.toLowerCase();
    if (activeTab === 'Proposal') return p.status === 'proposal';
    if (activeTab === 'In Progress') return p.status === 'in_progress';
    if (activeTab === 'Completed') return p.status === 'completed';
    if (activeTab === 'Archived') return p.status === 'archived';
    return true;
  });

  const displayedProjects = filteredProjects.slice(0, visibleCount);

  const statusCounts = projects.reduce((acc, p) => { acc[p.status] = (acc[p.status] ?? 0) + 1; return acc; }, {} as Record<Project['status'], number>);
  const total = projects.length || 1;

  const guideCounts = React.useMemo(() => {
    const map = new Map<string, number>();
    projects.forEach(p => { const name = p.guide_name?.trim(); if (name) map.set(name, (map.get(name) ?? 0) + 1); });
    return [...map.entries()].sort((a, b) => b[1] - a[1]).slice(0, 6);
  }, [projects]);

  const handleExport = () => {
    const csv = toCsv(filteredProjects);
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `fyp-projects-${new Date().toISOString().slice(0, 10)}.csv`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);
  };

  return (
    <div className="max-w-[1400px] mx-auto space-y-8 pb-8 relative">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div className="flex items-center gap-4">
          <div className="w-12 h-12 rounded-2xl bg-primary-purple flex items-center justify-center shadow-lg shadow-md shadow-primary-purple/10 shrink-0">
            <Folder className="w-6 h-6 text-white" />
          </div>
          <div>
            <h1 className="text-[26px] font-bold text-text-main tracking-tight mb-0.5">FYP Repository</h1>
            <p className="text-[14px] text-text-muted">Track, manage and evaluate Final Year Projects across batches.</p>
          </div>
        </div>
        <div className="flex items-center gap-3 shrink-0">
          <button onClick={handleExport} disabled={!filteredProjects.length} className="flex items-center gap-2 px-6 py-3 bg-white border border-border-light text-text-main rounded-xl text-[14px] font-bold shadow-sm hover:bg-page-bg transition-colors disabled:opacity-50">
            <Download className="w-4 h-4" /> Export CSV
          </button>
        </div>
      </div>

      {/* Stat Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {[
          { title: 'Total Projects', value: projects.length, color: 'var(--primary-purple)', bg: 'bg-page-bg', icon: FileCode },
          { title: 'In Progress', value: statusCounts.in_progress ?? 0, color: 'var(--primary-purple)', bg: 'bg-page-bg', icon: Activity },
          { title: 'Completed', value: statusCounts.completed ?? 0, color: 'var(--electric-blue)', bg: 'bg-white', icon: CheckCircle },
          { title: 'Archived', value: statusCounts.archived ?? 0, color: 'var(--deep-violet)', bg: 'bg-white', icon: Archive },
        ].map((stat, i) => (
          <motion.div key={i} initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.05 * i }} className="bg-white rounded-[20px] p-6 shadow-[0_2px_12px_rgba(0,0,0,0.03)] border border-border-light flex flex-col justify-between h-[120px]">
            <div className="flex items-center gap-3">
              <div className={`w-10 h-10 rounded-full ${stat.bg} flex items-center justify-center`}>
                <stat.icon className="w-5 h-5" style={{ color: stat.color }} />
              </div>
              <p className="text-[12px] font-bold text-text-muted">{stat.title}</p>
            </div>
            <h3 className="text-[32px] font-black text-text-main leading-none">{loading ? '—' : stat.value}</h3>
          </motion.div>
        ))}
      </div>

      {/* Main Content Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">

        {/* Left Column - Projects */}
        <div className="lg:col-span-2 space-y-6">
          <div className="bg-white rounded-[20px] shadow-[0_2px_12px_rgba(0,0,0,0.02)] border border-border-light p-6 flex flex-col h-full">

            {/* Tabs & Controls */}
            <div className="border-b border-border-light flex flex-col md:flex-row md:items-end justify-between gap-4 pb-0 mb-6">
              <div className="flex items-center gap-6 overflow-x-auto custom-scrollbar">
                {TABS.map(tab => (
                  <button
                    key={tab}
                    onClick={() => setActiveTab(tab)}
                    className={`text-[14px] pb-4 px-1 whitespace-nowrap transition-colors ${activeTab === tab ? 'font-bold text-primary-purple border-b-2 border-primary-purple' : 'font-semibold text-text-muted hover:text-text-main border-b-2 border-transparent'}`}
                  >
                    {tab}
                  </button>
                ))}
              </div>
              <div className="relative flex-1 md:w-[220px] pb-4">
                <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-text-muted" />
                <input type="text" value={searchQuery} onChange={(e) => setSearchQuery(e.target.value)} placeholder="Search title, guide, reg no…" className="pl-9 pr-4 py-2 border border-border-light rounded-xl text-[13px] w-full outline-none focus:border-primary-purple transition-colors" />
              </div>
            </div>

            <div className="space-y-4">
              <AnimatePresence mode="popLayout">
                {loading ? (
                  <div className="py-12 text-center text-text-muted text-[13px] font-semibold">Loading projects…</div>
                ) : displayedProjects.length === 0 ? (
                  <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="py-12 text-center text-text-muted text-[13px] font-semibold">
                    No projects found for this tab.
                  </motion.div>
                ) : (
                  displayedProjects.map((project) => {
                    const meta = STATUS_META[project.status];
                    return (
                      <motion.div
                        layout
                        initial={{ opacity: 0, y: 10 }}
                        animate={{ opacity: 1, y: 0 }}
                        exit={{ opacity: 0, scale: 0.95 }}
                        key={project.id}
                        className="p-5 rounded-[16px] border border-border-light hover:shadow-sm transition-all flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white"
                      >
                        <div className="flex items-center gap-4 flex-1 min-w-0">
                          <div className="w-14 h-14 rounded-[16px] bg-page-bg flex items-center justify-center shrink-0">
                            <FileCode className="w-6 h-6 text-primary-purple" />
                          </div>
                          <div className="min-w-0">
                            <h4 className="text-[15px] font-bold text-text-main truncate mb-1">{project.title}</h4>
                            <p className="text-[12px] font-semibold text-text-muted truncate">
                              {project.users?.name ?? 'Unknown student'} • {project.users?.reg_no ?? '—'}
                            </p>
                            <p className="text-[11px] text-text-muted font-bold mt-1">
                              Guide: {project.guide_name || 'Unassigned'} • {project.team_members_count} Member{project.team_members_count === 1 ? '' : 's'}
                            </p>
                          </div>
                        </div>

                        <div className="flex items-center gap-6 shrink-0">
                          <div className={`px-4 py-1.5 rounded-full border text-[11px] font-bold w-28 text-center ${meta.className}`}>
                            {meta.label}
                          </div>
                          <InitialsAvatar name={project.users?.name || '?'} size={32} />
                          {project.repository_url && (
                            <a href={project.repository_url} target="_blank" rel="noreferrer" title="Open repository" className="text-text-muted hover:text-primary-purple">
                              <ExternalLink className="w-5 h-5" />
                            </a>
                          )}
                        </div>
                      </motion.div>
                    );
                  })
                )}
              </AnimatePresence>
            </div>

            {!loading && visibleCount < filteredProjects.length && (
              <button onClick={() => setVisibleCount(prev => prev + 6)} className="mt-6 w-full py-3.5 bg-page-bg text-primary-purple rounded-[12px] text-[13px] font-bold hover:bg-border-light/40 transition-colors">
                Load More Projects
              </button>
            )}
          </div>
        </div>

        {/* Right Column - Status & Guides */}
        <div className="space-y-6">

          {/* Project Status Overview */}
          <div className="bg-white rounded-[20px] shadow-[0_2px_12px_rgba(0,0,0,0.02)] border border-border-light p-6">
            <h3 className="text-[16px] font-bold text-text-main mb-6">Project Status Overview</h3>
            <div className="space-y-2.5">
              {(Object.keys(STATUS_META) as Project['status'][]).map((status) => {
                const count = statusCounts[status] ?? 0;
                const pct = Math.round((count / total) * 100);
                const meta = STATUS_META[status];
                return (
                  <div key={status}>
                    <div className="flex items-center justify-between mb-1">
                      <div className="flex items-center gap-2"><div className={`w-2.5 h-2.5 rounded-full ${meta.barClass}`}></div><span className="text-[12px] font-bold text-text-main">{meta.label}</span></div>
                      <span className="text-[11px] text-text-muted font-semibold">{count} ({pct}%)</span>
                    </div>
                    <div className="w-full h-1.5 bg-page-bg rounded-full overflow-hidden">
                      <div className={`h-full rounded-full ${meta.barClass}`} style={{ width: `${pct}%` }}></div>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

          {/* Guides overview */}
          <div className="bg-white rounded-[20px] shadow-[0_2px_12px_rgba(0,0,0,0.02)] border border-border-light p-6">
            <h3 className="text-[16px] font-bold text-text-main mb-6">Projects by Guide</h3>
            <div className="space-y-4">
              {guideCounts.length === 0 && <p className="text-[12px] text-text-muted font-semibold">No guides assigned yet.</p>}
              {guideCounts.map(([name, count]) => (
                <div key={name}>
                  <div className="flex items-center justify-between mb-1.5">
                    <span className="text-[12px] font-bold text-text-main truncate">{name}</span>
                    <span className="text-[12px] font-bold text-text-muted">{count}</span>
                  </div>
                  <div className="w-full h-1.5 bg-page-bg rounded-full overflow-hidden">
                    <div className="h-full rounded-full bg-primary-purple" style={{ width: `${Math.round((count / (guideCounts[0]?.[1] || 1)) * 100)}%` }}></div>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Recent Project Updates */}
          <div className="bg-white rounded-[20px] shadow-[0_2px_12px_rgba(0,0,0,0.02)] border border-border-light p-6">
            <h3 className="text-[16px] font-bold text-text-main mb-6">Recent Project Updates</h3>
            <div className="space-y-5">
              {updates.length === 0 && <p className="text-[12px] text-text-muted font-semibold">No progress notes logged yet.</p>}
              {updates.map((upd) => (
                <div key={upd.id} className="flex items-start gap-3">
                  <div className="w-8 h-8 rounded-full bg-page-bg flex items-center justify-center shrink-0 border border-white shadow-sm">
                    <Clock className="w-3.5 h-3.5 text-primary-purple" />
                  </div>
                  <div className="min-w-0">
                    <p className="text-[13px] font-bold text-text-main leading-snug truncate">{upd.project_title}</p>
                    <p className="text-[11px] font-semibold text-text-muted mt-0.5 line-clamp-2">{upd.note}</p>
                  </div>
                  <span className="text-[10px] font-bold text-text-muted ml-auto shrink-0">{new Date(upd.created_at).toLocaleDateString('en-IN', { month: 'short', day: 'numeric' })}</span>
                </div>
              ))}
            </div>
          </div>

        </div>

      </div>
    </div>
  );
}
