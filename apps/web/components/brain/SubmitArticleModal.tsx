'use client';

import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X, BrainCircuit, Send, Loader2 } from 'lucide-react';

interface SubmitArticleModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess: () => void;
}

export function SubmitArticleModal({ isOpen, onClose, onSuccess }: SubmitArticleModalProps) {
  const [title, setTitle] = useState('');
  const [content, setContent] = useState('');
  const [tags, setTags] = useState('');
  const [category, setCategory] = useState('survival_guide');
  const [isAnonymous, setIsAnonymous] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      const res = await fetch('/api/brain', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          title,
          content,
          tags: tags.split(',').map(t => t.trim()).filter(Boolean),
          category,
          isAnonymous
        })
      });

      const data = await res.json();
      if (!res.ok) throw new Error(data.error || 'Failed to submit article');

      setTitle('');
      setContent('');
      setTags('');
      setCategory('survival_guide');
      setIsAnonymous(false);
      onSuccess();
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <AnimatePresence>
      <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
        <motion.div 
          initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
          className="absolute inset-0 bg-black/60 backdrop-blur-sm"
          onClick={onClose}
        />
        <motion.div 
          initial={{ opacity: 0, scale: 0.95, y: 20 }} animate={{ opacity: 1, scale: 1, y: 0 }} exit={{ opacity: 0, scale: 0.95, y: 20 }}
          className="psgmx-glass w-full max-w-2xl relative z-10 overflow-hidden"
        >
          {/* Header */}
          <div className="p-6 border-b border-white/10 flex justify-between items-center bg-white/5">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-gradient-to-br from-primary-purple to-neon-pink rounded-xl shadow-[0_0_15px_rgba(108,61,255,0.4)]">
                <BrainCircuit className="w-5 h-5 text-white" />
              </div>
              <h2 className="text-xl font-bold text-white tracking-tight">Contribute to Knowledge Brain</h2>
            </div>
            <button onClick={onClose} className="text-text-muted hover:text-white transition-colors">
              <X className="w-5 h-5" />
            </button>
          </div>

          {/* Form */}
          <form onSubmit={handleSubmit} className="p-6 space-y-5">
            {error && <p className="text-red-400 text-sm font-medium">{error}</p>}
            
            <div className="space-y-1.5">
              <label className="text-xs font-bold text-text-secondary uppercase tracking-wider">Title</label>
              <input 
                required value={title} onChange={e => setTitle(e.target.value)}
                className="w-full bg-black/40 border border-border rounded-xl px-4 py-3 text-white placeholder-text-muted focus:outline-none focus:border-primary-purple transition-colors"
                placeholder="e.g., Zoho Interview Experience 2026"
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-text-secondary uppercase tracking-wider">Category</label>
                <select 
                  value={category} onChange={e => setCategory(e.target.value)}
                  className="w-full bg-black/40 border border-border rounded-xl px-4 py-3 text-white focus:outline-none focus:border-primary-purple transition-colors appearance-none"
                >
                  <option value="survival_guide">Arrear Survival Guide</option>
                  <option value="interview_exp">Interview Experience</option>
                  <option value="project_arch">Project Architecture</option>
                  <option value="general">General Knowledge</option>
                </select>
              </div>
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-text-secondary uppercase tracking-wider">Tags (comma separated)</label>
                <input 
                  value={tags} onChange={e => setTags(e.target.value)}
                  className="w-full bg-black/40 border border-border rounded-xl px-4 py-3 text-white placeholder-text-muted focus:outline-none focus:border-primary-purple transition-colors"
                  placeholder="zoho, c++, pointers"
                />
              </div>
            </div>

            <div className="space-y-1.5">
              <label className="text-xs font-bold text-text-secondary uppercase tracking-wider">Knowledge Content</label>
              <textarea 
                required value={content} onChange={e => setContent(e.target.value)}
                className="w-full h-40 bg-black/40 border border-border rounded-xl px-4 py-3 text-white placeholder-text-muted focus:outline-none focus:border-primary-purple transition-colors resize-none"
                placeholder="Write your experience, guide, or tutorial here..."
              />
            </div>

            <div className="flex items-center gap-3 py-2">
              <input 
                type="checkbox" id="anon" checked={isAnonymous} onChange={e => setIsAnonymous(e.target.checked)}
                className="w-4 h-4 rounded border-border bg-black/40 text-primary-purple focus:ring-primary-purple focus:ring-offset-bg-dark"
              />
              <label htmlFor="anon" className="text-sm text-text-secondary">Submit Anonymously (Token will be hidden)</label>
            </div>

            <div className="pt-4 border-t border-white/10 flex justify-end gap-3">
              <button type="button" onClick={onClose} className="px-5 py-2.5 rounded-xl text-text-muted hover:text-white transition-colors font-medium">
                Cancel
              </button>
              <button disabled={loading} type="submit" className="psgmx-btn-primary flex items-center gap-2">
                {loading ? <Loader2 className="w-4 h-4 animate-spin" /> : <Send className="w-4 h-4" />}
                {loading ? 'Injecting...' : 'Inject into Brain'}
              </button>
            </div>
          </form>
        </motion.div>
      </div>
    </AnimatePresence>
  );
}
