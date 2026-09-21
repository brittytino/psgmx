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
          category
        })
      });

      const data = await res.json();
      if (!res.ok) throw new Error(data.error || 'Failed to submit article');

      setTitle('');
      setContent('');
      setTags('');
      setCategory('survival_guide');
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
          className="absolute inset-0 bg-slate-950/50 backdrop-blur-sm"
          onClick={onClose}
        />
        <motion.div
          initial={{ opacity: 0, scale: 0.95, y: 20 }} animate={{ opacity: 1, scale: 1, y: 0 }} exit={{ opacity: 0, scale: 0.95, y: 20 }}
          className="relative z-10 w-full max-w-2xl overflow-hidden rounded-3xl bg-white shadow-2xl"
        >
          {/* Header */}
          <div className="flex items-center justify-between border-b border-border-light bg-page-bg p-6">
            <div className="flex items-center gap-3">
              <div className="rounded-xl bg-primary-purple p-2">
                <BrainCircuit className="w-5 h-5 text-white" />
              </div>
              <h2 className="text-xl font-black tracking-tight text-text-main">Contribute to Knowledge Brain</h2>
            </div>
            <button onClick={onClose} aria-label="Close" className="text-text-muted transition-colors hover:text-text-main">
              <X className="w-5 h-5" />
            </button>
          </div>

          {/* Form */}
          <form onSubmit={handleSubmit} className="p-6 space-y-5">
            {error && <p className="rounded-xl bg-red-50 p-3 text-sm font-bold text-red-700">{error}</p>}

            <div className="space-y-1.5">
              <label className="text-xs font-bold uppercase tracking-wider text-text-muted">Title</label>
              <input
                required value={title} onChange={e => setTitle(e.target.value)}
                className="w-full rounded-xl border border-border-light bg-white px-4 py-3 text-text-main placeholder-text-muted outline-none transition-colors focus:border-primary-purple"
                placeholder="e.g., Zoho Interview Experience 2026"
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-1.5">
                <label className="text-xs font-bold uppercase tracking-wider text-text-muted">Category</label>
                <select
                  value={category} onChange={e => setCategory(e.target.value)}
                  className="w-full rounded-xl border border-border-light bg-white px-4 py-3 text-text-main outline-none transition-colors focus:border-primary-purple"
                >
                  <option value="survival_guide">Arrear Survival Guide</option>
                  <option value="interview_exp">Interview Experience</option>
                  <option value="project_arch">Project Architecture</option>
                  <option value="general">General Knowledge</option>
                </select>
              </div>
              <div className="space-y-1.5">
                <label className="text-xs font-bold uppercase tracking-wider text-text-muted">Tags (comma separated)</label>
                <input
                  value={tags} onChange={e => setTags(e.target.value)}
                  className="w-full rounded-xl border border-border-light bg-white px-4 py-3 text-text-main placeholder-text-muted outline-none transition-colors focus:border-primary-purple"
                  placeholder="zoho, c++, pointers"
                />
              </div>
            </div>

            <div className="space-y-1.5">
              <label className="text-xs font-bold uppercase tracking-wider text-text-muted">Knowledge Content</label>
              <textarea
                required value={content} onChange={e => setContent(e.target.value)}
                className="h-40 w-full resize-none rounded-xl border border-border-light bg-white px-4 py-3 text-text-main placeholder-text-muted outline-none transition-colors focus:border-primary-purple"
                placeholder="Write your experience, guide, or tutorial here..."
              />
            </div>

            <div className="flex justify-end gap-3 border-t border-border-light pt-4">
              <button type="button" onClick={onClose} className="rounded-xl px-5 py-2.5 font-medium text-text-muted transition-colors hover:text-text-main">
                Cancel
              </button>
              <button disabled={loading} type="submit" className="flex items-center gap-2 rounded-xl bg-primary-purple px-5 py-2.5 text-sm font-bold text-white transition-colors hover:bg-deep-violet disabled:opacity-50">
                {loading ? <Loader2 className="w-4 h-4 animate-spin" /> : <Send className="w-4 h-4" />}
                {loading ? 'Submitting...' : 'Submit article'}
              </button>
            </div>
          </form>
        </motion.div>
      </div>
    </AnimatePresence>
  );
}
