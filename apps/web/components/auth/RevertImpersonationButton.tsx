'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';

export default function RevertImpersonationButton() {
  const [loading, setLoading] = useState(false);
  const router = useRouter();

  const handleRevert = async () => {
    setLoading(true);
    try {
      const res = await fetch('/api/super-admin/revert', { method: 'POST' });
      if (res.ok) {
        router.push('/super-admin');
        router.refresh();
      } else {
        alert('Failed to revert impersonation.');
      }
    } catch (e) {
      console.error(e);
      alert('Error reverting impersonation.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <button 
      onClick={handleRevert} 
      disabled={loading}
      className="px-4 py-1.5 bg-black/20 hover:bg-black/40 text-black border border-black/30 rounded-lg font-bold transition-colors disabled:opacity-50"
    >
      {loading ? 'Ending...' : 'End Impersonation'}
    </button>
  );
}
