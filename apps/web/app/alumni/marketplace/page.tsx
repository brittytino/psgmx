"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { Briefcase, Code2, HandHeart, Plus, X } from "lucide-react";

type Post = {
  id: string;
  post_type: "job" | "project" | "mentorship";
  title: string;
  description: string;
  visibility: string;
  is_active: boolean;
  created_at: string;
  posted_by: string;
  poster?: { full_name: string; avatar_url: string | null };
};

const TYPE_CONFIG = {
  job:        { label: "Job Opportunity", color: "blue",   icon: Briefcase },
  project:    { label: "Project",         color: "purple", icon: Code2 },
  mentorship: { label: "Mentorship",      color: "green",  icon: HandHeart },
} as const;

const VISIBILITY_OPTIONS = [
  { value: "lineage_only", label: "Lineage Only (my juniors/seniors)" },
  { value: "batch",        label: "Entire Department" },
  { value: "department",   label: "All Batches" },
];

export default function CollaborationMarketplace() {
  const router = useRouter();
  const supabase = createClient();

  const [userId, setUserId] = useState<string | null>(null);
  const [posts, setPosts] = useState<Post[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);

  // Form state
  const [formType, setFormType] = useState<"job" | "project" | "mentorship">("job");
  const [formTitle, setFormTitle] = useState("");
  const [formDesc, setFormDesc] = useState("");
  const [formVisibility, setFormVisibility] = useState("batch");
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    async function load() {
      const { data: authData } = await supabase.auth.getUser();
      if (!authData.user) { router.push("/login"); return; }

      const { data: profileData } = await supabase
        .from("users")
        .select("role")
        .eq("id", authData.user.id)
        .single();
      const profile: any = profileData;

      if (!profile || (profile.role !== "alumni" && profile.role !== "faculty" && profile.role !== "hod")) {
        router.push("/");
        return;
      }

      setUserId(authData.user.id);

      const { data: postsData } = await supabase
        .from("collaboration_posts")
        .select("*, users!posted_by(full_name, avatar_url)")
        .eq("is_active", true)
        .order("created_at", { ascending: false })
        .limit(50);

      if (postsData) {
        setPosts(postsData.map((p: any) => ({
          ...p,
          poster: Array.isArray(p.users) ? p.users[0] : p.users,
        })));
      }
      setLoading(false);
    }
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const handlePost = async () => {
    if (!userId || !formTitle.trim() || !formDesc.trim()) return;
    setSubmitting(true);

    const { data: insertData, error } = await supabase
      .from("collaboration_posts")
      // @ts-ignore
      .insert({
        posted_by:   userId,
        post_type:   formType,
        title:       formTitle.trim(),
        description: formDesc.trim(),
        visibility:  formVisibility,
        is_active:   true,
      } as any)
      .select("*, users!posted_by(full_name, avatar_url)")
      .single();
    
    const data: any = insertData;

    if (!error && data) {
      setPosts(prev => [{ ...data, poster: Array.isArray(data.users) ? data.users[0] : data.users }, ...prev]);
      setFormTitle("");
      setFormDesc("");
      setShowForm(false);
    }
    setSubmitting(false);
  };

  const handleDeactivate = async (postId: string) => {
    await supabase.from("collaboration_posts")// @ts-ignore
      .update({ is_active: false } as any).eq("id", postId);
    setPosts(prev => prev.filter(p => p.id !== postId));
  };

  if (loading) {
    return <div className="min-h-screen flex items-center justify-center bg-gray-50"><span className="text-gray-400">Loading...</span></div>;
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-4xl mx-auto px-4 py-10">
        {/* Header */}
        <div className="flex items-center justify-between mb-8">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Collaboration Marketplace</h1>
            <p className="text-gray-500 text-sm mt-1">Jobs, projects, and mentorship opportunities from the PSGMX community</p>
          </div>
          <button
            onClick={() => setShowForm(v => !v)}
            className="flex items-center gap-2 px-4 py-2.5 bg-indigo-600 text-white rounded-xl font-medium text-sm hover:bg-indigo-700 transition"
          >
            <Plus size={16} />
            Post Opportunity
          </button>
        </div>

        {/* Post Form */}
        {showForm && (
          <div className="bg-white rounded-2xl border border-gray-200 shadow-sm p-6 mb-8">
            <h2 className="text-base font-semibold text-gray-900 mb-4">New Post</h2>
            <div className="grid grid-cols-3 gap-3 mb-4">
              {(["job", "project", "mentorship"] as const).map(t => {
                const cfg = TYPE_CONFIG[t];
                const Icon = cfg.icon;
                return (
                  <button
                    key={t}
                    onClick={() => setFormType(t)}
                    className={`flex items-center gap-2 px-4 py-3 rounded-xl border text-sm font-medium transition ${
                      formType === t
                        ? "border-indigo-500 bg-indigo-50 text-indigo-700"
                        : "border-gray-200 text-gray-600 hover:border-gray-300"
                    }`}
                  >
                    <Icon size={16} />
                    {cfg.label}
                  </button>
                );
              })}
            </div>

            <input
              type="text"
              placeholder="Title"
              value={formTitle}
              onChange={e => setFormTitle(e.target.value)}
              className="w-full px-4 py-3 border border-gray-200 rounded-xl mb-3 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
            />
            <textarea
              placeholder="Describe the opportunity..."
              value={formDesc}
              onChange={e => setFormDesc(e.target.value)}
              rows={4}
              className="w-full px-4 py-3 border border-gray-200 rounded-xl mb-3 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 resize-none"
            />
            <select
              value={formVisibility}
              onChange={e => setFormVisibility(e.target.value)}
              className="w-full px-4 py-3 border border-gray-200 rounded-xl mb-4 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 bg-white"
            >
              {VISIBILITY_OPTIONS.map(o => (
                <option key={o.value} value={o.value}>{o.label}</option>
              ))}
            </select>

            <div className="flex gap-3">
              <button
                onClick={handlePost}
                disabled={submitting || !formTitle.trim() || !formDesc.trim()}
                className="flex-1 py-3 bg-indigo-600 text-white rounded-xl font-medium text-sm hover:bg-indigo-700 disabled:opacity-50 transition"
              >
                {submitting ? "Posting..." : "Post"}
              </button>
              <button
                onClick={() => setShowForm(false)}
                className="px-4 py-3 border border-gray-200 rounded-xl text-sm text-gray-600 hover:bg-gray-50 transition"
              >
                Cancel
              </button>
            </div>
          </div>
        )}

        {/* Posts List */}
        {posts.length === 0 ? (
          <div className="text-center py-20 bg-white rounded-2xl border border-dashed border-gray-200">
            <HandHeart size={40} className="mx-auto text-gray-300 mb-4" />
            <h3 className="font-semibold text-gray-700 mb-1">No posts yet</h3>
            <p className="text-sm text-gray-400">Be the first to post a job, project, or mentorship opportunity</p>
          </div>
        ) : (
          <div className="space-y-4">
            {posts.map(post => {
              const cfg = TYPE_CONFIG[post.post_type];
              const Icon = cfg.icon;
              const colorMap: Record<string, string> = {
                blue:   "bg-blue-50 text-blue-700",
                purple: "bg-purple-50 text-purple-700",
                green:  "bg-green-50 text-green-700",
              };

              return (
                <div key={post.id} className="bg-white rounded-2xl border border-gray-200 p-5 hover:shadow-sm transition">
                  <div className="flex items-start justify-between gap-4">
                    <div className="flex-1">
                      <div className="flex items-center gap-2 mb-2">
                        <span className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-medium ${colorMap[cfg.color]}`}>
                          <Icon size={12} />
                          {cfg.label}
                        </span>
                        <span className="text-xs text-gray-400">
                          {new Date(post.created_at).toLocaleDateString("en-IN", { day: "numeric", month: "short", year: "numeric" })}
                        </span>
                      </div>
                      <h3 className="font-semibold text-gray-900 mb-1">{post.title}</h3>
                      <p className="text-sm text-gray-500 line-clamp-3">{post.description}</p>
                      {post.poster && (
                        <p className="text-xs text-gray-400 mt-3">
                          Posted by <span className="font-medium text-gray-600">{post.poster.full_name}</span>
                        </p>
                      )}
                    </div>
                    {post.posted_by === userId && (
                      <button
                        onClick={() => handleDeactivate(post.id)}
                        className="p-1.5 text-gray-400 hover:text-red-500 hover:bg-red-50 rounded-lg transition"
                        title="Remove post"
                      >
                        <X size={16} />
                      </button>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
}
