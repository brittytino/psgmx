'use client';

import React from 'react';
import { motion } from 'framer-motion';
import { Plus, CalendarClock, MapPin, Lock, Unlock, X } from 'lucide-react';
import { createClient } from '@/lib/supabase/client';

interface SessionRow {
  id: string;
  topic: string;
  session_type: string | null;
  session_mode: string | null;
  location: string | null;
  session_datetime: string;
  duration_minutes: number | null;
  is_locked: boolean | null;
}

export default function SessionSchedulingPage() {
  const supabase = createClient();
  const [batchId, setBatchId] = React.useState<string | null>(null);
  const [sessions, setSessions] = React.useState<SessionRow[]>([]);
  const [loading, setLoading] = React.useState(true);
  const [showForm, setShowForm] = React.useState(false);
  const [saving, setSaving] = React.useState(false);

  const [form, setForm] = React.useState({
    topic: '', session_type: 'Placement Drive', session_mode: 'Offline',
    location: '', date: '', time: '', duration_minutes: 60,
  });

  const load = React.useCallback(async () => {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return;
    const { data: me } = await supabase.from('users').select('batch_id, id').eq('id', user.id).single();
    if (!me?.batch_id) { setLoading(false); return; }
    setBatchId(me.batch_id);

    const { data } = await supabase
      .from('placement_sessions')
      .select('id, topic, session_type, session_mode, location, session_datetime, duration_minutes, is_locked')
      .eq('batch_id', me.batch_id)
      .order('session_datetime', { ascending: true });

    setSessions(data || []);
    setLoading(false);
  }, [supabase]);

  React.useEffect(() => { load(); }, [load]);

  const handleCreate = async () => {
    if (!form.topic.trim() || !form.date || !form.time || !batchId) return;
    setSaving(true);
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;
      await supabase.from('placement_sessions').insert({
        batch_id: batchId,
        topic: form.topic.trim(),
        session_type: form.session_type,
        session_mode: form.session_mode,
        location: form.location.trim() || null,
        session_datetime: new Date(`${form.date}T${form.time}`).toISOString(),
        duration_minutes: form.duration_minutes,
        scheduled_by: user.id,
      });
      setForm({ topic: '', session_type: 'Placement Drive', session_mode: 'Offline', location: '', date: '', time: '', duration_minutes: 60 });
      setShowForm(false);
      await load();
    } finally {
      setSaving(false);
    }
  };

  const toggleLock = async (session: SessionRow) => {
    await supabase.from('placement_sessions').update({ is_locked: !session.is_locked }).eq('id', session.id);
    setSessions((prev) => prev.map((s) => (s.id === session.id ? { ...s, is_locked: !s.is_locked } : s)));
  };

  if (loading) {
    return <div className="space-y-4 animate-pulse">{[0, 1, 2].map((i) => <div key={i} className="h-20 bg-white border border-border-light rounded-2xl" />)}</div>;
  }

  const now = Date.now();
  const upcoming = sessions.filter((s) => new Date(s.session_datetime).getTime() >= now);
  const past = sessions.filter((s) => new Date(s.session_datetime).getTime() < now);

  return (
    <div className="space-y-8 max-w-4xl">
      <div className="flex items-center justify-between">
        <h1 className="text-[24px] font-black text-text-main">Session Scheduling</h1>
        <button onClick={() => setShowForm(true)} className="flex items-center gap-2 px-5 py-2.5 bg-primary-purple text-white rounded-xl text-[13px] font-bold hover:bg-deep-violet transition-colors">
          <Plus className="w-4 h-4" /> Schedule Session
        </button>
      </div>

      {showForm && (
        <motion.div initial={{ opacity: 0, y: -10 }} animate={{ opacity: 1, y: 0 }} className="bg-white rounded-2xl border border-border-light p-6 space-y-4">
          <div className="flex justify-between items-start">
            <h3 className="text-[15px] font-bold">New Session</h3>
            <button onClick={() => setShowForm(false)} className="text-text-muted hover:text-deep-violet"><X className="w-4 h-4" /></button>
          </div>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div className="sm:col-span-2">
              <label className="text-[12px] font-bold text-text-muted block mb-1.5">Topic</label>
              <input value={form.topic} onChange={(e) => setForm({ ...form, topic: e.target.value })} placeholder="e.g. Mock GD Round 2" className="w-full border border-border-light rounded-lg px-3 py-2 text-[14px] outline-none focus:border-primary-purple" />
            </div>
            <div>
              <label className="text-[12px] font-bold text-text-muted block mb-1.5">Type</label>
              <select value={form.session_type} onChange={(e) => setForm({ ...form, session_type: e.target.value })} className="w-full border border-border-light rounded-lg px-3 py-2 text-[14px] outline-none">
                {/* Matches apps/mobile/lib/ui/admin/schedule_placement_session_screen.dart _types exactly, so sessions created here read correctly on mobile. */}
                <option value="Placement Drive">Placement Drive</option>
                <option value="Mock Test">Mock Test</option>
                <option value="Workshop">Workshop</option>
                <option value="Webinar">Webinar</option>
                <option value="Other">Other</option>
              </select>
            </div>
            <div>
              <label className="text-[12px] font-bold text-text-muted block mb-1.5">Mode</label>
              <select value={form.session_mode} onChange={(e) => setForm({ ...form, session_mode: e.target.value })} className="w-full border border-border-light rounded-lg px-3 py-2 text-[14px] outline-none">
                <option value="Offline">Offline</option>
                <option value="Online">Online</option>
              </select>
            </div>
            <div>
              <label className="text-[12px] font-bold text-text-muted block mb-1.5">Date</label>
              <input type="date" value={form.date} onChange={(e) => setForm({ ...form, date: e.target.value })} className="w-full border border-border-light rounded-lg px-3 py-2 text-[14px] outline-none" />
            </div>
            <div>
              <label className="text-[12px] font-bold text-text-muted block mb-1.5">Time</label>
              <input type="time" value={form.time} onChange={(e) => setForm({ ...form, time: e.target.value })} className="w-full border border-border-light rounded-lg px-3 py-2 text-[14px] outline-none" />
            </div>
            <div>
              <label className="text-[12px] font-bold text-text-muted block mb-1.5">Duration (min)</label>
              <input type="number" min={15} value={form.duration_minutes} onChange={(e) => setForm({ ...form, duration_minutes: Number(e.target.value) })} className="w-full border border-border-light rounded-lg px-3 py-2 text-[14px] outline-none" />
            </div>
            <div>
              <label className="text-[12px] font-bold text-text-muted block mb-1.5">Location / Link</label>
              <input value={form.location} onChange={(e) => setForm({ ...form, location: e.target.value })} placeholder="Room 204 / Meet link" className="w-full border border-border-light rounded-lg px-3 py-2 text-[14px] outline-none" />
            </div>
          </div>
          <button onClick={handleCreate} disabled={saving} className="px-5 py-2 bg-primary-purple text-white rounded-lg text-[13px] font-bold disabled:opacity-50">
            {saving ? 'Scheduling…' : 'Schedule Session'}
          </button>
        </motion.div>
      )}

      <div>
        <h3 className="text-[14px] font-bold text-text-muted uppercase tracking-wider mb-3">Upcoming</h3>
        <div className="space-y-3">
          {upcoming.length === 0 && <p className="text-[13px] text-text-muted">No upcoming sessions scheduled.</p>}
          {upcoming.map((s) => (
            <div key={s.id} className="bg-white rounded-2xl border border-border-light p-5 flex items-center justify-between">
              <div className="flex items-center gap-4">
                <div className="w-11 h-11 rounded-xl bg-page-bg flex items-center justify-center shrink-0"><CalendarClock className="w-5 h-5 text-primary-purple" /></div>
                <div>
                  <h4 className="text-[14px] font-bold text-text-main">{s.topic}</h4>
                  <p className="text-[12px] text-text-muted mt-0.5 flex items-center gap-1.5">
                    {new Date(s.session_datetime).toLocaleString('en-IN', { dateStyle: 'medium', timeStyle: 'short' })} · {s.duration_minutes} min
                    {s.location && <><MapPin className="w-3 h-3" /> {s.location}</>}
                  </p>
                </div>
              </div>
              <button onClick={() => toggleLock(s)} className="flex items-center gap-1.5 text-[11px] font-bold text-text-muted hover:text-primary-purple">
                {s.is_locked ? <><Lock className="w-3.5 h-3.5" /> Locked</> : <><Unlock className="w-3.5 h-3.5" /> Open</>}
              </button>
            </div>
          ))}
        </div>
      </div>

      {past.length > 0 && (
        <div>
          <h3 className="text-[14px] font-bold text-text-muted uppercase tracking-wider mb-3">Past</h3>
          <div className="space-y-2">
            {past.map((s) => (
              <div key={s.id} className="bg-white/60 rounded-xl border border-border-light p-4 flex items-center justify-between opacity-70">
                <span className="text-[13px] font-semibold text-text-main">{s.topic}</span>
                <span className="text-[11px] text-text-muted">{new Date(s.session_datetime).toLocaleDateString('en-IN')}</span>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
