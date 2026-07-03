import { NextRequest, NextResponse } from 'next/server';
import { getUserFromRequest } from '@/lib/auth';
import connectDB from '@/lib/mongodb';
import KnowledgeBrainArticle from '@/models/KnowledgeBrainArticle';
import AiMemory from '@/models/AiMemory';
import { orchestrateAI } from '@/lib/ai/orchestrator';

export async function POST(req: NextRequest) {
  try {
    const session = await getUserFromRequest(req);
    if (!session || !session.id) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

    await connectDB();

    // Fetch the user's last highly rated conversation
    const lastMemory = await AiMemory.findOne({ userToken: session.token }).sort({ createdAt: -1 });
    
    if (!lastMemory) {
      return NextResponse.json({ error: 'No recent conversation found to extract.' }, { status: 404 });
    }

    // Use AI Orchestrator to summarize the Q&A into a formal article draft
    const extractionPrompt = `Convert the following Q&A into a formal, highly technical 'survival guide' article for the MCA department. Do not include chat artifacts like "Here is your article".
    
    Question: ${lastMemory.query}
    Answer: ${lastMemory.response}
    
    Format as Markdown.`;

    const result = await orchestrateAI({
      prompt: extractionPrompt,
      userToken: session.token || 'unknown',
      role: session.role,
      retrievedSources: []
    });

    const newArticle = await KnowledgeBrainArticle.create({
      departmentId: session.departmentId,
      title: `AI Extracted Guide: ${lastMemory.query.substring(0, 50)}...`,
      content: result.answer,
      authorToken: session.token || 'unknown',
      category: 'survival_guide',
      status: 'draft',
      origin: 'ai_extracted',
      sourceConversationId: lastMemory._id.toString()
    });

    return NextResponse.json({ success: true, articleId: newArticle._id });
  } catch (error: any) {
    console.error('Auto Extract Error:', error);
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}
