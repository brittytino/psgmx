'use client';

import React, { useState } from 'react';
import { BrainCircuit, Send, Loader2 } from 'lucide-react';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';

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
    <Dialog open={isOpen} onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="sm:max-w-2xl rounded-3xl p-0 overflow-hidden bg-white border-border-light">
        <DialogHeader className="flex flex-row items-center gap-3 border-b border-border-light bg-page-bg p-6 m-0 space-y-0">
          <div className="rounded-xl bg-primary-purple p-2">
            <BrainCircuit className="w-5 h-5 text-white" />
          </div>
          <DialogTitle className="text-xl font-black tracking-tight text-text-main">
            Contribute to Knowledge Brain
          </DialogTitle>
          <DialogDescription className="hidden">Submit a new article to the knowledge brain.</DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="p-6 space-y-5">
          {error && <p className="rounded-xl bg-red-50 p-3 text-sm font-bold text-red-700">{error}</p>}

          <div className="space-y-1.5">
            <label className="text-xs font-bold uppercase tracking-wider text-text-muted">Title</label>
            <Input
              required value={title} onChange={e => setTitle(e.target.value)}
              className="w-full rounded-xl border-border-light bg-white px-4 py-6 text-sm outline-none focus-visible:ring-primary-purple"
              placeholder="e.g., Zoho Interview Experience 2026"
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-1.5">
              <label className="text-xs font-bold uppercase tracking-wider text-text-muted">Category</label>
              <select
                value={category} onChange={e => setCategory(e.target.value)}
                className="w-full rounded-xl border border-border-light bg-white px-4 py-3 text-sm text-text-main outline-none focus:border-primary-purple shadow-sm transition-colors"
              >
                <option value="survival_guide">Arrear Survival Guide</option>
                <option value="interview_exp">Interview Experience</option>
                <option value="project_arch">Project Architecture</option>
                <option value="general">General Knowledge</option>
              </select>
            </div>
            <div className="space-y-1.5">
              <label className="text-xs font-bold uppercase tracking-wider text-text-muted">Tags (comma separated)</label>
              <Input
                value={tags} onChange={e => setTags(e.target.value)}
                className="w-full rounded-xl border-border-light bg-white px-4 py-6 text-sm outline-none focus-visible:ring-primary-purple"
                placeholder="zoho, c++, pointers"
              />
            </div>
          </div>

          <div className="space-y-1.5">
            <label className="text-xs font-bold uppercase tracking-wider text-text-muted">Knowledge Content</label>
            <textarea
              required value={content} onChange={e => setContent(e.target.value)}
              className="h-40 w-full resize-none rounded-xl border border-border-light bg-white px-4 py-3 text-sm text-text-main placeholder-text-muted outline-none transition-colors focus:border-primary-purple shadow-sm"
              placeholder="Write your experience, guide, or tutorial here..."
            />
          </div>

          <div className="flex justify-end gap-3 border-t border-border-light pt-4">
            <Button type="button" variant="ghost" onClick={onClose} className="rounded-xl font-bold">
              Cancel
            </Button>
            <Button disabled={loading} type="submit" className="rounded-xl bg-primary-purple px-5 py-2 text-sm font-bold text-white hover:bg-deep-violet">
              {loading ? <Loader2 className="w-4 h-4 animate-spin mr-2" /> : <Send className="w-4 h-4 mr-2" />}
              {loading ? 'Submitting...' : 'Submit article'}
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
}
