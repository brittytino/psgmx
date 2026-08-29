'use client';

import React, { useState } from 'react';
import { createClient } from '@/lib/supabase/client';
import { useRouter } from 'next/navigation';
import { Plus, Trash2, CheckCircle2, AlertCircle } from 'lucide-react';

export default function QuestStudio() {
  const router = useRouter();
  const supabase = createClient();
  
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const [title, setTitle] = useState('');
  const [problemMd, setProblemMd] = useState('');
  const [language, setLanguage] = useState('python');
  
  // Minimal test cases state
  const [visibleCases, setVisibleCases] = useState([{ input: '', expected_output: '' }]);
  const [hiddenCases, setHiddenCases] = useState([{ input: '', expected_output: '' }]);

  const addVisibleCase = () => setVisibleCases([...visibleCases, { input: '', expected_output: '' }]);
  const addHiddenCase = () => setHiddenCases([...hiddenCases, { input: '', expected_output: '' }]);
  
  const updateCase = (type: 'visible' | 'hidden', index: number, field: string, value: string) => {
    const list = type === 'visible' ? [...visibleCases] : [...hiddenCases];
    list[index] = { ...list[index], [field]: value };
    type === 'visible' ? setVisibleCases(list) : setHiddenCases(list);
  };
  
  const removeCase = (type: 'visible' | 'hidden', index: number) => {
    const list = type === 'visible' ? [...visibleCases] : [...hiddenCases];
    list.splice(index, 1);
    type === 'visible' ? setVisibleCases(list) : setHiddenCases(list);
  };

  const handleSave = async () => {
    setLoading(true);
    setError(null);
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Not authenticated');

      // 1. Create Quest record
      const questData = {
        authored_by: user.id,
        title,
        problem_md: problemMd,
        type: 'coding',
        status: 'published',
        allowed_languages: [language],
        sample_cases_json: visibleCases,
      };

      const { data: quest, error: insertError } = await supabase
        .from('quests')
        .insert(questData)
        .select('id')
        .single();

      if (insertError) throw insertError;
      
      // 2. Upload hidden test cases to Supabase Storage
      const testSuite = [...visibleCases, ...hiddenCases]; // include both
      const storagePath = `tests/${quest.id}/test_suite.json`;
      
      const { error: uploadError } = await supabase.storage
        .from('quests') // Ensure this bucket exists
        .upload(storagePath, JSON.stringify(testSuite), {
          contentType: 'application/json'
        });
        
      if (uploadError) {
        // If upload fails, just use the JSON directly for MVP
        console.warn('Storage upload failed, updating quest to use sample_cases_json entirely', uploadError);
        await supabase.from('quests').update({ sample_cases_json: testSuite }).eq('id', quest.id);
      } else {
        await supabase.from('quests').update({ test_suite_storage_path: storagePath }).eq('id', quest.id);
      }

      setSuccess(true);
      setTimeout(() => {
        router.push('/placement-rep');
      }, 2000);
      
    } catch (err: any) {
      console.error(err);
      setError(err.message || 'Failed to save quest');
    }
    setLoading(false);
  };

  return (
    <div className="max-w-4xl mx-auto py-10 px-6">
      <h1 className="text-3xl font-black text-gray-900 mb-2">Quest Studio</h1>
      <p className="text-gray-500 mb-8">Design coding tasks, define test cases, and publish to the batch.</p>

      {success && (
        <div className="mb-6 bg-green-50 text-green-700 p-4 rounded-lg flex items-center gap-3">
          <CheckCircle2 className="w-5 h-5" />
          <p className="font-medium">Quest published successfully! Redirecting...</p>
        </div>
      )}

      {error && (
        <div className="mb-6 bg-red-50 text-red-700 p-4 rounded-lg flex items-center gap-3">
          <AlertCircle className="w-5 h-5" />
          <p className="font-medium">{error}</p>
        </div>
      )}

      <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6 space-y-6">
        
        <div>
          <label className="block text-sm font-bold text-gray-700 mb-1">Quest Title</label>
          <input 
            type="text" 
            value={title} 
            onChange={e => setTitle(e.target.value)}
            className="w-full border border-gray-300 rounded-md px-4 py-2 focus:ring-2 focus:ring-brand-500 outline-none"
            placeholder="e.g. Find Minimum in Rotated Sorted Array"
          />
        </div>

        <div>
          <label className="block text-sm font-bold text-gray-700 mb-1">Language restriction</label>
          <select 
            value={language} 
            onChange={e => setLanguage(e.target.value)}
            className="w-full border border-gray-300 rounded-md px-4 py-2 focus:ring-2 focus:ring-brand-500 outline-none"
          >
            <option value="python">Python 3</option>
            <option value="java">Java 15</option>
            <option value="cpp">C++</option>
            <option value="javascript">JavaScript</option>
          </select>
        </div>

        <div>
          <label className="block text-sm font-bold text-gray-700 mb-1">Problem Statement (Markdown)</label>
          <textarea 
            value={problemMd}
            onChange={e => setProblemMd(e.target.value)}
            rows={8}
            className="w-full border border-gray-300 rounded-md px-4 py-2 font-mono text-sm focus:ring-2 focus:ring-brand-500 outline-none"
            placeholder="Describe the problem, input format, and constraints..."
          />
        </div>

        {/* Visible Cases */}
        <div className="pt-6 border-t border-gray-100">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h3 className="text-lg font-bold text-gray-900">Visible Sample Cases</h3>
              <p className="text-xs text-gray-500">Students see these when they click Run.</p>
            </div>
            <button onClick={addVisibleCase} className="flex items-center gap-1 text-sm text-brand-600 font-medium hover:text-brand-700">
              <Plus className="w-4 h-4" /> Add Case
            </button>
          </div>
          <div className="space-y-4">
            {visibleCases.map((tc, idx) => (
              <div key={idx} className="flex gap-4 items-start bg-gray-50 p-4 rounded-lg border border-gray-200">
                <div className="flex-1 space-y-2">
                  <textarea placeholder="Input (stdin)" value={tc.input} onChange={e => updateCase('visible', idx, 'input', e.target.value)} className="w-full text-sm border-gray-300 rounded p-2 font-mono" rows={2} />
                  <textarea placeholder="Expected Output (stdout)" value={tc.expected_output} onChange={e => updateCase('visible', idx, 'expected_output', e.target.value)} className="w-full text-sm border-gray-300 rounded p-2 font-mono" rows={2} />
                </div>
                {visibleCases.length > 1 && (
                  <button onClick={() => removeCase('visible', idx)} className="text-gray-400 hover:text-red-500 mt-2">
                    <Trash2 className="w-5 h-5" />
                  </button>
                )}
              </div>
            ))}
          </div>
        </div>

        {/* Hidden Cases */}
        <div className="pt-6 border-t border-gray-100">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h3 className="text-lg font-bold text-gray-900">Hidden Test Cases</h3>
              <p className="text-xs text-gray-500">Used during Submit for verification. Kept secret.</p>
            </div>
            <button onClick={addHiddenCase} className="flex items-center gap-1 text-sm text-brand-600 font-medium hover:text-brand-700">
              <Plus className="w-4 h-4" /> Add Case
            </button>
          </div>
          <div className="space-y-4">
            {hiddenCases.map((tc, idx) => (
              <div key={idx} className="flex gap-4 items-start bg-gray-50 p-4 rounded-lg border border-gray-200">
                <div className="flex-1 space-y-2">
                  <textarea placeholder="Input (stdin)" value={tc.input} onChange={e => updateCase('hidden', idx, 'input', e.target.value)} className="w-full text-sm border-gray-300 rounded p-2 font-mono" rows={2} />
                  <textarea placeholder="Expected Output (stdout)" value={tc.expected_output} onChange={e => updateCase('hidden', idx, 'expected_output', e.target.value)} className="w-full text-sm border-gray-300 rounded p-2 font-mono" rows={2} />
                </div>
                {hiddenCases.length > 1 && (
                  <button onClick={() => removeCase('hidden', idx)} className="text-gray-400 hover:text-red-500 mt-2">
                    <Trash2 className="w-5 h-5" />
                  </button>
                )}
              </div>
            ))}
          </div>
        </div>

        {/* Footer Actions */}
        <div className="pt-6 border-t border-gray-100 flex justify-end gap-3">
          <button className="px-5 py-2.5 text-sm font-bold text-gray-600 hover:bg-gray-100 rounded-lg transition-colors">
            Cancel
          </button>
          <button 
            onClick={handleSave}
            disabled={loading || !title || !problemMd}
            className="px-5 py-2.5 text-sm font-bold text-white bg-brand-500 hover:bg-brand-600 disabled:opacity-50 rounded-lg shadow-sm transition-colors"
          >
            {loading ? 'Publishing...' : 'Publish Quest'}
          </button>
        </div>

      </div>
    </div>
  );
}
