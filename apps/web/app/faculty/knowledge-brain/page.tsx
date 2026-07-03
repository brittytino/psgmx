'use client';

import React from 'react';
import { motion } from 'framer-motion';
import { BookOpen, Plus, FileText, Database, Code, Share2, Box, Eye, Bookmark, MoreVertical, Search, Filter, ChevronDown, CheckCircle, Clock, AlertCircle, Target } from 'lucide-react';
import Link from 'next/link';

import { AnimatePresence } from 'framer-motion';

export default function FacultyKnowledgeBrainDashboard() {
  const [activeTab, setActiveTab] = React.useState('All Articles');
  
  const [articles, setArticles] = React.useState([
    { id: 1, title: 'Dynamic Programming – Problem Solving Guide', desc: 'Comprehensive guide to dynamic programming concepts with solved examples and practice problems.', icon: FileText, color: '#6C3DFF', bg: 'bg-[#F5F3FF]', badge: 'Approved', badgeColor: 'bg-[#ECFDF5] text-[#059669]', author: '25MX301', date: 'May 14, 2025', ai: true, reviewer: 'Dr. Arunkumar', reviewDate: 'May 14, 2025', views: 342, state: 'Approved', bookmarked: false },
    { id: 2, title: 'Database Normalization – Quick Notes', desc: 'Quick reference for normalization forms with examples and use cases.', icon: Database, color: '#06B6D4', bg: 'bg-[#ECFEFF]', badge: 'Approved', badgeColor: 'bg-[#ECFDF5] text-[#059669]', author: '25MX205', date: 'May 12, 2025', ai: false, reviewer: 'Dr. Pavithra', reviewDate: 'May 12, 2025', views: 275, state: 'Approved', bookmarked: true },
    { id: 3, title: 'React useEffect Hook – Complete Guide', desc: 'Deep dive into useEffect hook with cleanup, dependencies and real-world examples.', icon: Code, color: '#F43F5E', bg: 'bg-[#FFF1F2]', badge: 'Approved', badgeColor: 'bg-[#ECFDF5] text-[#059669]', author: '25MX114', date: 'May 10, 2025', ai: false, reviewer: 'Dr. Karthikeyan', reviewDate: 'May 10, 2025', views: 198, state: 'Approved', bookmarked: false },
    { id: 4, title: 'Operating Systems – Process Scheduling', desc: 'Overview of CPU scheduling algorithms with time complexity analysis.', icon: Share2, color: '#F59E0B', bg: 'bg-[#FFFBEB]', badge: 'Pending Review', badgeColor: 'bg-[#FFFBEB] text-[#D97706]', author: '25MX402', date: 'May 15, 2025', ai: false, reviewer: 'Dr. Pavithra', reviewDate: 'May 15, 2025', views: 96, state: 'Submitted', bookmarked: false },
    { id: 5, title: 'Machine Learning – Overfitting Explained', desc: 'Understanding overfitting in ML models with visualization and code samples.', icon: Box, color: '#8B5CF6', bg: 'bg-[#F5F3FF]', badge: 'Needs Changes', badgeColor: 'bg-[#FEF2F2] text-[#DC2626]', author: '25MX301', date: 'May 13, 2025', ai: false, reviewer: 'Dr. Arunkumar', reviewDate: 'May 14, 2025', views: 112, state: 'Needs changes', bookmarked: false },
  ]);

  const [isLoadingMore, setIsLoadingMore] = React.useState(false);
  const [visibleCount, setVisibleCount] = React.useState(3);
  const [searchQuery, setSearchQuery] = React.useState('');
  const [toastMessage, setToastMessage] = React.useState('');

  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(''), 3000);
  };

  const toggleBookmark = (id: number) => {
    setArticles(prev => prev.map(a => a.id === id ? { ...a, bookmarked: !a.bookmarked } : a));
  };

  const filteredArticles = articles.filter(a => {
    const matchesSearch = a.title.toLowerCase().includes(searchQuery.toLowerCase()) || a.desc.toLowerCase().includes(searchQuery.toLowerCase());
    if (!matchesSearch) return false;

    if (activeTab === 'Pending Review') return a.badge === 'Pending Review' || a.badge === 'Needs Changes';
    if (activeTab === 'Published') return a.badge === 'Approved';
    if (activeTab === 'Archived') return false; // simulated empty
    return true;
  });

  const displayedArticles = filteredArticles.slice(0, visibleCount);

  const handleLoadMore = () => {
    setIsLoadingMore(true);
    setTimeout(() => {
      setIsLoadingMore(false);
    }, 1000);
  };

  return (
    <div className="max-w-[1400px] mx-auto space-y-8 pb-8 relative">
      <AnimatePresence>
        {toastMessage && (
          <motion.div initial={{ opacity: 0, y: 50 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: 50 }} className="fixed bottom-8 left-1/2 -translate-x-1/2 z-50 bg-[#1E293B] text-white px-6 py-3 rounded-xl shadow-xl flex items-center gap-3">
            <div className="w-2 h-2 rounded-full bg-[#10B981]"></div>
            <span className="text-[13px] font-bold">{toastMessage}</span>
          </motion.div>
        )}
      </AnimatePresence>
      
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div className="flex items-center gap-4">
          <div className="w-12 h-12 rounded-2xl bg-[#6C3DFF] flex items-center justify-center shadow-lg shadow-[#6C3DFF]/20 shrink-0">
            <BookOpen className="w-6 h-6 text-white" />
          </div>
          <div>
            <motion.h1 
              initial={{ opacity: 0, y: -10 }}
              animate={{ opacity: 1, y: 0 }}
              className="text-[26px] font-bold text-[#1E293B] tracking-tight mb-0.5"
            >
              Knowledge Brain
            </motion.h1>
            <motion.p 
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 0.1 }}
              className="text-[14px] text-[#64748B]"
            >
              Curated knowledge. Verified by mentors. Accessible for all.
            </motion.p>
          </div>
        </div>
        <button onClick={() => showToast('Opening Article Editor...')} className="flex items-center gap-2 px-6 py-3 bg-[#6C3DFF] text-white rounded-xl text-[14px] font-bold shadow-md shadow-[#6C3DFF]/20 hover:bg-[#5B21B6] transition-colors shrink-0">
          <Plus className="w-4 h-4" /> Create Article
        </button>
      </div>

      {/* 4 Stat Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {[
          { title: 'Total Articles', value: '128', trend: '↑ 14 this month', color: '#6C3DFF', bg: 'bg-[#F5F3FF]' },
          { title: 'Approved Articles', value: '112', trend: '↑ 10 this month', color: '#06B6D4', bg: 'bg-[#ECFEFF]' },
          { title: 'Pending Review', value: '8', trend: '↓ 2 this week', color: '#F59E0B', bg: 'bg-[#FFFBEB]' },
          { title: 'Total Views', value: '4.2K', trend: '↑ 22% this month', color: '#F43F5E', bg: 'bg-[#FFF1F2]' },
        ].map((stat, i) => (
          <motion.div key={i} initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.1 * i }} className="bg-white rounded-[20px] p-6 shadow-[0_2px_12px_rgba(0,0,0,0.03)] border border-[#F1F5F9] relative overflow-hidden flex flex-col justify-between h-[140px]">
            <div className="flex justify-between items-start">
              <div className="flex items-center gap-3">
                <div className={`w-10 h-10 rounded-full ${stat.bg} flex items-center justify-center`}>
                  <BookOpen className="w-5 h-5" style={{ color: stat.color }} />
                </div>
                <p className="text-[12px] font-bold text-[#64748B]">{stat.title}</p>
              </div>
            </div>
            <div className="flex items-end justify-between mt-auto">
              <div>
                <h3 className="text-[32px] font-black text-[#1E293B] leading-none mb-2">{stat.value}</h3>
                <p className={`text-[11px] font-bold ${stat.trend.includes('↓') ? 'text-[#F59E0B]' : 'text-[#10B981]'}`}>{stat.trend}</p>
              </div>
              <div className="w-24 h-8">
                <svg viewBox="0 0 100 30" className="w-full h-full fill-none" style={{ stroke: stat.color }} strokeWidth="3" strokeLinecap="round" strokeLinejoin="round">
                  <path d={i === 0 ? "M0,25 C20,25 30,15 50,15 C70,15 80,5 100,5" : i === 1 ? "M0,20 C20,25 40,5 60,15 C80,25 90,10 100,5" : i === 2 ? "M0,5 C10,5 30,20 50,10 C70,0 80,25 100,25" : "M0,20 C20,10 40,25 60,15 C80,5 90,20 100,10"} />
                </svg>
              </div>
            </div>
          </motion.div>
        ))}
      </div>

      {/* Main Content Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        
        {/* Left Column - Articles */}
        <div className="lg:col-span-2 space-y-6">
          <div className="bg-white rounded-[20px] shadow-[0_2px_12px_rgba(0,0,0,0.02)] border border-[#F1F5F9] p-6 flex flex-col h-full">
            
            {/* Tabs & Controls */}
            <div className="border-b border-[#E2E8F0] flex flex-col md:flex-row md:items-end justify-between gap-4 pb-0 mb-6">
              <div className="flex items-center gap-6 overflow-x-auto custom-scrollbar pb-[-1px]">
                {['All Articles', 'Pending Review', 'Published', 'Archived'].map(tab => (
                  <button 
                    key={tab}
                    onClick={() => setActiveTab(tab)}
                    className={`text-[14px] pb-4 px-1 whitespace-nowrap transition-colors ${activeTab === tab ? 'font-bold text-[#6C3DFF] border-b-2 border-[#6C3DFF]' : 'font-semibold text-[#64748B] hover:text-[#1E293B] border-b-2 border-transparent'}`}
                  >
                    {tab}
                  </button>
                ))}
              </div>
              <div className="flex flex-col sm:flex-row sm:items-center gap-3 pb-4 w-full md:w-auto">
                <div className="relative flex-1 md:w-[200px]">
                  <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-[#94A3B8]" />
                  <input type="text" value={searchQuery} onChange={(e) => setSearchQuery(e.target.value)} placeholder="Search articles..." className="pl-9 pr-4 py-2 border border-[#E2E8F0] rounded-xl text-[13px] w-full outline-none focus:border-[#6C3DFF] transition-colors" />
                </div>
                <div className="flex items-center gap-1 border border-[#E2E8F0] rounded-xl px-3 py-2 text-[13px] font-bold text-[#1E293B] cursor-pointer hover:bg-[#F8F9FC] shrink-0">
                  Latest First <ChevronDown className="w-4 h-4 ml-1" />
                </div>
                <button className="flex items-center gap-2 px-3 py-2 border border-[#E2E8F0] rounded-xl text-[13px] font-bold text-[#1E293B] hover:bg-[#F8F9FC] transition-colors shrink-0">
                  <Filter className="w-4 h-4" /> Filters
                </button>
              </div>
            </div>

            <div className="space-y-4">
              <AnimatePresence mode="popLayout">
                {displayedArticles.length === 0 ? (
                  <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="py-12 text-center text-[#94A3B8] text-[13px] font-semibold">
                    No articles found for this tab.
                  </motion.div>
                ) : (
                  displayedArticles.map((article) => (
                    <motion.div 
                      layout
                      initial={{ opacity: 0, y: 10 }}
                      animate={{ opacity: 1, y: 0 }}
                      exit={{ opacity: 0, scale: 0.95 }}
                      key={article.id} 
                      className="p-5 rounded-[16px] border border-[#F1F5F9] hover:border-[#E2E8F0] hover:shadow-sm transition-all flex flex-col sm:flex-row sm:items-start gap-4 bg-white"
                    >
                      <div className={`w-14 h-14 rounded-[12px] ${article.bg} flex flex-col items-center justify-center shrink-0 relative`}>
                        <article.icon className="w-6 h-6" style={{ color: article.color }} />
                        {article.ai && <span className="absolute -bottom-2 -right-2 bg-white text-[9px] font-black px-1.5 py-0.5 rounded-md border border-[#F1F5F9] shadow-sm" style={{ color: article.color }}>AI</span>}
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2 mb-1 flex-wrap">
                          <h4 className="text-[15px] font-bold text-[#1E293B] truncate">{article.title}</h4>
                          <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold border border-transparent ${article.badgeColor}`}>{article.badge}</span>
                        </div>
                        <p className="text-[12px] font-semibold text-[#94A3B8] mb-2">
                          {article.ai ? 'AI Generated • ' : ''}By <span className="text-[#64748B]">{article.author}</span> • {article.date}
                        </p>
                        <p className="text-[13px] text-[#64748B] leading-relaxed line-clamp-2 max-w-xl">{article.desc}</p>
                      </div>
                      <div className="flex flex-col items-end gap-3 shrink-0 mt-2 sm:mt-0">
                        <div className="flex items-center gap-3 text-[#94A3B8]">
                          <div className="flex items-center gap-1"><Eye className="w-4 h-4" /><span className="text-[12px] font-bold">{article.views}</span></div>
                          <Bookmark 
                            onClick={() => toggleBookmark(article.id)} 
                            className={`w-4 h-4 cursor-pointer transition-colors ${article.bookmarked ? 'text-[#6C3DFF] fill-[#6C3DFF]' : 'hover:text-[#6C3DFF]'}`} 
                          />
                          <MoreVertical className="w-4 h-4 cursor-pointer hover:text-[#1E293B]" />
                        </div>
                        <div className="flex items-center gap-2 mt-auto">
                          <img src={`https://ui-avatars.com/api/?name=${encodeURIComponent(article.reviewer)}&background=random`} alt="" className="w-7 h-7 rounded-full" />
                          <div className="text-right">
                            <p className="text-[12px] font-bold text-[#1E293B]">{article.reviewer}</p>
                            <p className="text-[10px] font-semibold text-[#94A3B8]">{article.state ? article.state : 'Reviewed'} {article.reviewDate}</p>
                          </div>
                        </div>
                      </div>
                    </motion.div>
                  ))
                )}
              </AnimatePresence>
            </div>

            <AnimatePresence>
              {visibleCount < filteredArticles.length && (
                <motion.button layout initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} onClick={() => setVisibleCount(prev => prev + 3)} className="mt-6 w-full py-3.5 bg-[#F8F9FC] text-[#6C3DFF] rounded-[12px] text-[13px] font-bold flex items-center justify-center gap-2 hover:bg-[#F1F5F9] transition-colors">
                  Load More Articles <ChevronDown className="w-4 h-4" />
                </motion.button>
              )}
            </AnimatePresence>
          </div>
        </div>

        {/* Right Column - Top Contributors & Categories */}
        <div className="space-y-6">
          
          {/* Top Contributors */}
          <div className="bg-white rounded-[20px] shadow-[0_2px_12px_rgba(0,0,0,0.02)] border border-[#F1F5F9] p-6">
            <div className="flex justify-between items-center mb-6">
              <h3 className="text-[16px] font-bold text-[#1E293B]">Top Contributors</h3>
              <Link href="#" className="text-[12px] font-bold text-[#6C3DFF]">View All</Link>
            </div>
            <div className="space-y-4">
              {[
                { name: 'Dr. Arunkumar', count: '32 articles', crown: 'text-yellow-500' },
                { name: 'Dr. Pavithra', count: '28 articles', crown: 'text-gray-400' },
                { name: 'Dr. Karthikeyan', count: '18 articles', crown: 'text-amber-600' },
              ].map((prof, i) => (
                <div key={i} className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <img src={`https://ui-avatars.com/api/?name=${encodeURIComponent(prof.name)}&background=random`} alt="" className="w-10 h-10 rounded-full" />
                    <div>
                      <p className="text-[14px] font-bold text-[#1E293B]">{prof.name}</p>
                      <p className="text-[12px] text-[#64748B]">{prof.count}</p>
                    </div>
                  </div>
                  <div className={`w-6 h-6 rounded-full bg-white border border-[#F1F5F9] shadow-sm flex items-center justify-center ${prof.crown}`}>
                    <span className="text-[10px] font-black">♚</span>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Categories */}
          <div className="bg-white rounded-[20px] shadow-[0_2px_12px_rgba(0,0,0,0.02)] border border-[#F1F5F9] p-6">
            <div className="flex justify-between items-center mb-6">
              <h3 className="text-[16px] font-bold text-[#1E293B]">Categories</h3>
              <Link href="#" className="text-[12px] font-bold text-[#6C3DFF]">View All</Link>
            </div>
            <div className="space-y-3">
              {[
                { name: 'Programming', count: 45, icon: Code, color: 'text-[#6C3DFF]', bg: 'bg-[#F5F3FF]' },
                { name: 'Database', count: 22, icon: Database, color: 'text-[#3B82F6]', bg: 'bg-[#EFF6FF]' },
                { name: 'Web Development', count: 18, icon: BookOpen, color: 'text-[#10B981]', bg: 'bg-[#ECFDF5]' },
                { name: 'Operating Systems', count: 16, icon: Share2, color: 'text-[#06B6D4]', bg: 'bg-[#ECFEFF]' },
                { name: 'Computer Networks', count: 12, icon: Target, color: 'text-[#F59E0B]', bg: 'bg-[#FFFBEB]' },
                { name: 'Others', count: 15, icon: FileText, color: 'text-[#F43F5E]', bg: 'bg-[#FFF1F2]' },
              ].map((cat, i) => (
                <div key={i} className="flex items-center justify-between group cursor-pointer p-2 -mx-2 rounded-xl hover:bg-[#F8F9FC] transition-colors">
                  <div className="flex items-center gap-3">
                    <div className={`w-8 h-8 rounded-lg ${cat.bg} flex items-center justify-center`}>
                      <cat.icon className={`w-4 h-4 ${cat.color}`} />
                    </div>
                    <p className="text-[13px] font-bold text-[#1E293B]">{cat.name}</p>
                  </div>
                  <span className="text-[12px] font-bold text-[#94A3B8] group-hover:text-[#64748B]">{cat.count}</span>
                </div>
              ))}
            </div>
          </div>

          {/* Popular Tags */}
          <div className="bg-white rounded-[20px] shadow-[0_2px_12px_rgba(0,0,0,0.02)] border border-[#F1F5F9] p-6">
            <div className="flex justify-between items-center mb-6">
              <h3 className="text-[16px] font-bold text-[#1E293B]">Popular Tags</h3>
              <Link href="#" className="text-[12px] font-bold text-[#6C3DFF]">View All</Link>
            </div>
            <div className="flex flex-wrap gap-2">
              {['JavaScript', 'Python', 'DBMS', 'React', 'DSA', 'OS', 'SQL', 'Machine Learning', 'OOP', 'Algorithms'].map((tag, i) => (
                <span key={i} className="px-3 py-1.5 bg-[#F8F9FC] text-[#475569] rounded-lg text-[12px] font-semibold cursor-pointer hover:bg-[#E2E8F0] transition-colors">
                  {tag}
                </span>
              ))}
            </div>
          </div>

        </div>

      </div>
    </div>
  );
}
