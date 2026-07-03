import { NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const q = searchParams.get('q');
    
    if (!q || q.trim().length === 0) {
      return NextResponse.json({ articles: [] });
    }
    
    const supabase = await createClient();
    
    // We use a basic text search fallback using ilike and array operators 
    // since pgvector embeddings are not populated yet for local development.
    const { data, error } = await supabase
      .from('knowledge_brain_articles')
      .select(`
        id, 
        title, 
        summary, 
        tags, 
        source,
        created_at,
        users!author_id(full_name, avatar_url, role)
      `)
      .eq('approval_status', 'approved')
      .or(`title.ilike.%${q}%,summary.ilike.%${q}%`)
      .order('created_at', { ascending: false })
      .limit(20);
      
    if (error) {
      console.error("Supabase search error:", error);
      return NextResponse.json({ error: error.message }, { status: 500 });
    }
    
    // Format the response
    const formattedData = data.map((item: any) => ({
      id: item.id,
      title: item.title,
      summary: item.summary,
      tags: item.tags || [],
      source: item.source,
      createdAt: item.created_at,
      author: item.users ? {
        name: item.users.full_name,
        avatar: item.users.avatar_url,
        role: item.users.role,
      } : null
    }));
    
    return NextResponse.json({ articles: formattedData });
  } catch (error: any) {
    console.error("Search API exception:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
