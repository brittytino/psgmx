'use client';

import React, { useState } from 'react';
import { RefreshCw, ArchiveX } from 'lucide-react';

export default function FacultyGovernanceClient({ initialArticles }: { initialArticles: any[] }) {
  const [articles, setArticles] = useState(initialArticles);
  const [loading, setLoading] = useState<string | null>(null);

  const handleRevalidate = async (id: string, action: 'revalidate' | 'archive') => {
    setLoading(id);
    try {
      const res = await fetch('/api/governance/revalidate', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id, action })
      });
      if (res.ok) {
        setArticles(articles.filter(a => a._id !== id));
      } else {
        const data = await res.json();
        alert(data.error);
      }
    } catch {
      alert('Action failed');
    } finally {
      setLoading(null);
    }
  };

  return (
    <div className="bg-black/20 border border-border rounded-xl overflow-hidden">
      <table className="w-full text-left border-collapse">
        <thead>
          <tr className="bg-white/5 border-b border-border">
            <th className="p-4 text-sm font-bold text-text-muted">Article Title</th>
            <th className="p-4 text-sm font-bold text-text-muted">Author</th>
            <th className="p-4 text-sm font-bold text-text-muted">Freshness</th>
            <th className="p-4 text-sm font-bold text-text-muted text-right">Actions</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-border">
          {articles.map(a => (
            <tr key={a._id} className="hover:bg-white/5 transition-colors">
              <td className="p-4 font-bold text-white">{a.title}</td>
              <td className="p-4 text-sm text-text-muted">{a.authorToken}</td>
              <td className="p-4">
                <div className="flex items-center gap-2">
                  <div className="w-full bg-black/40 rounded-full h-2 max-w-[100px]">
                    <div className="bg-red-500 h-2 rounded-full" style={{ width: `${a.freshnessScore}%` }}></div>
                  </div>
                  <span className="text-xs font-bold text-red-400">{a.freshnessScore}%</span>
                </div>
              </td>
              <td className="p-4 text-right space-x-2">
                <button 
                  onClick={() => handleRevalidate(a._id, 'revalidate')} 
                  disabled={loading === a._id}
                  className="inline-flex items-center gap-2 px-3 py-1.5 bg-green-500/20 text-green-400 hover:bg-green-500/30 rounded-lg text-sm font-bold transition-colors disabled:opacity-50"
                >
                  <RefreshCw className="w-4 h-4" /> Revalidate
                </button>
                <button 
                  onClick={() => handleRevalidate(a._id, 'archive')} 
                  disabled={loading === a._id}
                  className="inline-flex items-center gap-2 px-3 py-1.5 bg-red-500/20 text-red-400 hover:bg-red-500/30 rounded-lg text-sm font-bold transition-colors disabled:opacity-50"
                >
                  <ArchiveX className="w-4 h-4" /> Archive
                </button>
              </td>
            </tr>
          ))}
          {articles.length === 0 && (
            <tr><td colSpan={4} className="p-8 text-center text-text-muted">No articles require revalidation. AI Context is fresh.</td></tr>
          )}
        </tbody>
      </table>
    </div>
  );
}
