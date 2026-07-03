"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { Activity, BookOpen, ChevronRight, Link2, MapPin, Search, Shield, User as UserIcon, Users } from "lucide-react";

export default function AlumniDashboard() {
  const router = useRouter();
  const supabase = createClient();

  const [loading, setLoading] = useState(true);
  const [user, setUser] = useState<any>(null);
  const [stats, setStats] = useState<any>({
    readinessScore: 0,
    leetcodeScore: 0,
    longestStreak: 0,
  });
  
  const [mentorshipOpen, setMentorshipOpen] = useState(false);
  const [toggling, setToggling] = useState(false);
  
  const [juniors, setJuniors] = useState<any[]>([]);
  const [seniors, setSeniors] = useState<any[]>([]);

  useEffect(() => {
    async function loadData() {
      const { data: authData } = await supabase.auth.getUser();
      if (!authData.user) {
        router.push("/login");
        return;
      }

      // Check role
      const { data: profile } = await supabase
        .from("users")
        .select("*")
        .eq("id", authData.user.id)
        .maybeSingle();

      if (!profile || profile.role !== "alumni") {
        alert("This dashboard is only available for alumni.");
        router.push("/");
        return;
      }

      setUser(profile);
      setMentorshipOpen(profile.mentorship_open || false);

      // Fetch stats
      const { data: scoreResp } = await supabase
          .from('readiness_scores')
          .select('score')
          .eq('user_id', authData.user.id)
          .order('computed_at', { ascending: false })
          .limit(1)
          .maybeSingle();
      
      const { data: streakResp } = await supabase
          .from('daily_five_streaks')
          .select('longest_streak')
          .eq('user_id', authData.user.id)
          .maybeSingle();
          
      const { data: leetcodeResp } = await supabase
          .from('leetcode_stats')
          .select('batch_weighted_score')
          .eq('user_id', authData.user.id)
          .maybeSingle();

      setStats({
        readinessScore: scoreResp?.score || 0,
        longestStreak: streakResp?.longest_streak || 0,
        leetcodeScore: leetcodeResp?.batch_weighted_score || 0,
      });

      // Fetch Lineage
      const { data: juniorsData } = await supabase
        .from("lineage_map")
        .select("junior_user_id, users!junior_user_id(full_name, avatar_url, current_company, current_role_title, linkedin_url)")
        .eq("senior_user_id", authData.user.id);
        
      const { data: seniorsData } = await supabase
        .from("lineage_map")
        .select("senior_user_id, users!senior_user_id(full_name, avatar_url, current_company, current_role_title, linkedin_url)")
        .eq("junior_user_id", authData.user.id);

      setJuniors(juniorsData?.map((d: any) => d.users) || []);
      setSeniors(seniorsData?.map((d: any) => d.users) || []);

      setLoading(false);
    }
    loadData();
  }, [router, supabase]);

  const toggleMentorship = async () => {
    if (!user) return;
    setToggling(true);
    
    const newValue = !mentorshipOpen;
    const { error } = await supabase
      .from("users")
      .update({ mentorship_open: newValue })
      .eq("id", user.id);
      
    if (!error) {
      setMentorshipOpen(newValue);
    } else {
      alert("Failed to update status");
    }
    setToggling(false);
  };

  if (loading) {
    return <div className="min-h-screen flex items-center justify-center bg-gray-50"><span className="loader text-indigo-600">Loading...</span></div>;
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white border-b border-gray-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-16">
            <div className="flex items-center gap-4">
              <div className="w-10 h-10 rounded-full bg-indigo-100 flex items-center justify-center text-indigo-600 font-bold">
                {user?.full_name?.charAt(0) || "A"}
              </div>
              <div>
                <h1 className="text-xl font-bold text-gray-900">Alumni Dashboard</h1>
                <p className="text-sm text-gray-500">Welcome back, {user?.full_name}</p>
              </div>
            </div>
            <button
              onClick={() => router.push("/")}
              className="text-sm font-medium text-gray-600 hover:text-gray-900"
            >
              Back to Home
            </button>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 space-y-8">
        
        {/* Top Stats & Mentorship */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div className="md:col-span-2 bg-white rounded-2xl shadow-sm border border-gray-200 p-6 flex items-center justify-between">
            <div>
              <h2 className="text-lg font-bold text-gray-900 mb-1">Mentorship Status</h2>
              <p className="text-gray-500 text-sm max-w-md">
                By enabling mentorship, your profile will be visible to your juniors in the "Your Senior" card, and they can reach out to you on LinkedIn.
              </p>
            </div>
            <div className="flex flex-col items-end gap-2">
              <button
                onClick={toggleMentorship}
                disabled={toggling}
                className={`relative inline-flex h-8 w-14 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none focus:ring-2 focus:ring-indigo-600 focus:ring-offset-2 disabled:opacity-50 ${mentorshipOpen ? 'bg-indigo-600' : 'bg-gray-200'}`}
              >
                <span className={`pointer-events-none inline-block h-7 w-7 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out ${mentorshipOpen ? 'translate-x-6' : 'translate-x-0'}`} />
              </button>
              <span className={`text-sm font-medium ${mentorshipOpen ? 'text-indigo-600' : 'text-gray-500'}`}>
                {mentorshipOpen ? 'Open for Mentorship' : 'Closed'}
              </span>
            </div>
          </div>

          <div className="bg-gradient-to-br from-gray-900 to-gray-800 rounded-2xl shadow-sm p-6 text-white flex flex-col justify-center">
            <div className="flex items-center gap-2 mb-4 opacity-80">
              <Activity size={18} />
              <h3 className="font-medium text-sm uppercase tracking-wider">Final Readiness</h3>
            </div>
            <div className="flex items-baseline gap-2">
              <span className="text-4xl font-bold">{Number(stats.readinessScore).toFixed(1)}</span>
              <span className="text-gray-400 font-medium">/ 100</span>
            </div>
          </div>
        </div>

        {/* Lineage Section */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
          {/* Juniors */}
          <div>
            <div className="flex items-center gap-2 mb-6">
              <Users size={20} className="text-indigo-600" />
              <h2 className="text-xl font-bold text-gray-900">Your Juniors</h2>
            </div>
            
            {juniors.length === 0 ? (
              <div className="bg-white border border-gray-200 border-dashed rounded-2xl p-8 text-center">
                <Users size={32} className="mx-auto text-gray-400 mb-3" />
                <h3 className="text-gray-900 font-medium mb-1">No Juniors Assigned</h3>
                <p className="text-sm text-gray-500">When juniors are mapped to your roll number, they will appear here.</p>
              </div>
            ) : (
              <div className="space-y-4">
                {juniors.map((j, i) => (
                  <div key={i} className="bg-white rounded-2xl shadow-sm border border-gray-200 p-5 flex items-center gap-4">
                    <div className="w-12 h-12 rounded-full bg-gray-100 flex items-center justify-center overflow-hidden">
                      {j.avatar_url ? (
                        <img src={j.avatar_url} alt={j.full_name} className="w-full h-full object-cover" />
                      ) : (
                        <span className="text-gray-500 font-bold">{j.full_name?.charAt(0)}</span>
                      )}
                    </div>
                    <div className="flex-1">
                      <h3 className="font-semibold text-gray-900">{j.full_name}</h3>
                      <p className="text-sm text-gray-500">{j.current_role_title || 'Student'} • {j.current_company || 'PSG Tech'}</p>
                    </div>
                    {j.linkedin_url && (
                      <a href={j.linkedin_url} target="_blank" rel="noopener noreferrer" className="p-2 text-indigo-600 hover:bg-indigo-50 rounded-lg transition">
                        <Link2 size={20} />
                      </a>
                    )}
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* Seniors */}
          <div>
            <div className="flex items-center gap-2 mb-6">
              <Shield size={20} className="text-coral-600" />
              <h2 className="text-xl font-bold text-gray-900">Your Seniors</h2>
            </div>
            
            {seniors.length === 0 ? (
              <div className="bg-white border border-gray-200 border-dashed rounded-2xl p-8 text-center">
                <Shield size={32} className="mx-auto text-gray-400 mb-3" />
                <h3 className="text-gray-900 font-medium mb-1">No Seniors Found</h3>
                <p className="text-sm text-gray-500">You don't have any seniors mapped in the lineage system.</p>
              </div>
            ) : (
              <div className="space-y-4">
                {seniors.map((s, i) => (
                  <div key={i} className="bg-white rounded-2xl shadow-sm border border-gray-200 p-5 flex items-center gap-4">
                    <div className="w-12 h-12 rounded-full bg-gray-100 flex items-center justify-center overflow-hidden">
                      {s.avatar_url ? (
                        <img src={s.avatar_url} alt={s.full_name} className="w-full h-full object-cover" />
                      ) : (
                        <span className="text-gray-500 font-bold">{s.full_name?.charAt(0)}</span>
                      )}
                    </div>
                    <div className="flex-1">
                      <h3 className="font-semibold text-gray-900">{s.full_name}</h3>
                      <p className="text-sm text-gray-500">{s.current_role_title || 'Alumni'} • {s.current_company || 'Unknown'}</p>
                    </div>
                    {s.linkedin_url && (
                      <a href={s.linkedin_url} target="_blank" rel="noopener noreferrer" className="p-2 text-indigo-600 hover:bg-indigo-50 rounded-lg transition">
                        <Link2 size={20} />
                      </a>
                    )}
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>

      </main>
    </div>
  );
}
