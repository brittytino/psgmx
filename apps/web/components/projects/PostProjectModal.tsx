import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X } from 'lucide-react';

export function PostProjectModal({ isOpen, onClose, onSuccess }: { isOpen: boolean, onClose: () => void, onSuccess: () => void }) {
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [techStack, setTechStack] = useState('');
  const [guideName, setGuideName] = useState('');
  const [githubLink, setGithubLink] = useState('');
  const [reportLink, setReportLink] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      const res = await fetch('/api/projects', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          title,
          description,
          techStack: techStack.split(',').map(t => t.trim()).filter(Boolean),
          guideName,
          githubLink,
          reportLink
        })
      });
      
      if (!res.ok) throw new Error('Failed to log FYP');
      
      setTitle('');
      setDescription('');
      setTechStack('');
      setGuideName('');
      setGithubLink('');
      setReportLink('');
      onSuccess();
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  if (!isOpen) return null;

  return (
    <AnimatePresence>
      <motion.div 
        initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
        className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm"
      >
        <motion.div 
          initial={{ scale: 0.95, opacity: 0, y: 20 }} animate={{ scale: 1, opacity: 1, y: 0 }}
          className="w-full max-w-2xl bg-page-bg border border-border rounded-2xl shadow-2xl overflow-hidden flex flex-col max-h-[90vh]"
        >
          <div className="flex justify-between items-center p-6 border-b border-border bg-white/5">
            <h2 className="text-xl font-bold text-white">Log FYP Progress</h2>
            <button onClick={onClose} className="p-2 hover:bg-white/10 rounded-lg text-text-muted transition-colors"><X className="w-5 h-5"/></button>
          </div>

          <div className="p-6 overflow-y-auto">
            {error && <div className="p-4 mb-6 bg-red-500/10 border border-red-500/20 text-red-400 rounded-xl text-sm">{error}</div>}
            
            <form id="fyp-form" onSubmit={handleSubmit} className="space-y-5">
              <div>
                <label className="block text-xs font-bold text-text-muted uppercase tracking-wider mb-2">Project Title</label>
                <input required type="text" className="w-full bg-black/40 border border-border rounded-xl px-4 py-3 text-white placeholder-text-muted focus:border-electric-blue outline-none transition-colors" placeholder="e.g. AI-Powered Healthcare Dashboard" value={title} onChange={e => setTitle(e.target.value)} />
              </div>

              <div>
                <label className="block text-xs font-bold text-text-muted uppercase tracking-wider mb-2">Project Description</label>
                <textarea required rows={4} className="w-full bg-black/40 border border-border rounded-xl px-4 py-3 text-white placeholder-text-muted focus:border-electric-blue outline-none transition-colors" placeholder="Briefly describe the architecture and goals..." value={description} onChange={e => setDescription(e.target.value)} />
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
                <div>
                  <label className="block text-xs font-bold text-text-muted uppercase tracking-wider mb-2">Assigned Guide Name</label>
                  <input required type="text" className="w-full bg-black/40 border border-border rounded-xl px-4 py-3 text-white placeholder-text-muted focus:border-electric-blue outline-none transition-colors" placeholder="e.g. Dr. Ramesh" value={guideName} onChange={e => setGuideName(e.target.value)} />
                </div>
                <div>
                  <label className="block text-xs font-bold text-text-muted uppercase tracking-wider mb-2">Tech Stack (comma separated)</label>
                  <input type="text" className="w-full bg-black/40 border border-border rounded-xl px-4 py-3 text-white placeholder-text-muted focus:border-electric-blue outline-none transition-colors" placeholder="React, Node.js, MongoDB" value={techStack} onChange={e => setTechStack(e.target.value)} />
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
                <div>
                  <label className="block text-xs font-bold text-text-muted uppercase tracking-wider mb-2">GitHub Repository Link</label>
                  <input type="url" className="w-full bg-black/40 border border-border rounded-xl px-4 py-3 text-white placeholder-text-muted focus:border-electric-blue outline-none transition-colors" placeholder="https://github.com/..." value={githubLink} onChange={e => setGithubLink(e.target.value)} />
                </div>
                <div>
                  <label className="block text-xs font-bold text-text-muted uppercase tracking-wider mb-2">Report Link (G-Drive / Docs)</label>
                  <input type="url" className="w-full bg-black/40 border border-border rounded-xl px-4 py-3 text-white placeholder-text-muted focus:border-electric-blue outline-none transition-colors" placeholder="https://docs.google.com/..." value={reportLink} onChange={e => setReportLink(e.target.value)} />
                </div>
              </div>
            </form>
          </div>

          <div className="p-6 border-t border-border bg-black/20 flex justify-end gap-3">
            <button onClick={onClose} className="px-5 py-2.5 rounded-xl font-bold text-text-muted hover:text-white transition-colors">Cancel</button>
            <button form="fyp-form" type="submit" disabled={loading} className="px-5 py-2.5 rounded-xl font-bold bg-electric-blue text-white hover:bg-electric-blue/80 transition-colors shadow-[0_0_15px_rgba(45,212,191,0.3)] disabled:opacity-50">
              {loading ? 'Saving...' : 'Log Progress'}
            </button>
          </div>
        </motion.div>
      </motion.div>
    </AnimatePresence>
  );
}
