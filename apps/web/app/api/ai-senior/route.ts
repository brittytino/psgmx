// ============================================================
// POST /api/ai-senior/route.ts
// AI Senior RAG chatbot with comprehensive domain knowledge.
// ============================================================
import { NextRequest, NextResponse } from 'next/server'
import { getUserFromRequest } from '@/lib/auth'
import { buildRAGContext, formatRAGContextForPrompt } from '@/lib/ai/rag'
import { supabaseAdmin } from '@/lib/supabase/admin'
import { executeOpenRouterPrompt } from '@/lib/ai/openrouter-free-chain'

const SYSTEM_PROMPT = `You are AI Senior, an experienced mentor and placement companion for MCA students at PSG College of Technology, Coimbatore. 
Your goal is to guide juniors with actionable, practical advice on placements, coding rounds, aptitude, mock assessments, and readiness scores.
Keep your response structured, friendly, and empowering. If relevant, mention key department tips (Daily Five streak consistency, LeetCode patterns, NEO PAT for official company drives).`

function getExpertDomainAnswer(query: string): string {
  const q = query.toLowerCase()

  // 1. HR Interview Preparation
  if (q.includes('hr') || q.includes('behavioural') || q.includes('behavioral') || q.includes('soft skill')) {
    return `### How to Ace Your HR & Behavioral Interviews:

HR rounds at companies like Zoho, TCS, Thoughtworks, and Cisco assess your communication clarity, cultural fit, problem-solving mindset, and authenticity.

#### 1. Master the 90-Second "Tell Me About Yourself"
Structure your introduction using the **Past-Present-Future Framework**:
- **Academics & Core Strengths**: Your MCA background at PSG Tech and focus areas (e.g., Full Stack Development, DSA, Cloud Systems).
- **Proof of Work**: 1-2 highlight projects or achievements (e.g. Your Final Year Project architecture or CodeBox rating).
- **Future Alignment**: Why this specific company aligns with your career trajectory and how your skills solve their challenges.

#### 2. Answer Behavioral Questions with the STAR Method
For questions like *"Describe a time you faced a team conflict or deadline crunch"*:
- **Situation**: Context of the project or academic deliverable.
- **Task**: The exact challenge or conflict that needed resolution.
- **Action**: The specific steps *you* took (e.g. initiating a sync call, refactoring a bottleneck).
- **Result**: Quantifiable outcome (e.g. "We delivered 2 days ahead of schedule with 0 regression bugs").

#### 3. Handling Tricky Questions
- *"What is your biggest weakness?"* Pick a real technical or professional area you have actively improved (e.g., "Earlier I hesitated to delegate tasks during group projects, but using Kanban boards in our squad sprints helped me build collaborative trust").
- *"Why do you want to join us?"* Mention specific engineering blogs, products, or core values of the company rather than generic praise.

#### 4. High-Impact Questions to Ask the HR at the End
- *"How does your engineering team mentor new MCA graduates during their first 90 days?"*
- *"What is a common trait among the fastest-growing engineers on your team?"*`
  }

  // 2. Final Year Project (FYP) for Placements
  if (q.includes('fyp') || q.includes('project') || q.includes('portfolio')) {
    return `### What Makes a Strong Final Year Project (FYP) for Placements:

Interviewers look for **architectural depth, technical trade-offs, and verifiable proof of work** rather than just a basic CRUD app.

#### 1. Choose a Real Problem with Measurable Impact
- **Avoid**: Generic bookstore, basic blog, or standard todo apps.
- **Choose**: Systems with concurrency, data pipelines, caching, or AI integration (e.g. Intelligent triage systems, automated log analyzers, distributed task schedulers, real-time collaboration platforms).

#### 2. Essential Engineering Pillars for Your FYP
- **Production Architecture**: Clean separation between frontend (Next.js/React), backend APIs (FastAPI/Go/Node.js), and database (PostgreSQL with indexes).
- **Performance & Caching**: Use Redis for session caching or rate-limiting. Be ready to explain your database indexing choices.
- **Automated Testing & CI/CD**: Include unit tests (Jest/Pytest) and GitHub Actions workflow badges.
- **Deployment**: Have a live working URL (Vercel, Render, Railway) linked in your PSGMX FYP Portfolio.

#### 3. Anticipate These Technical Defense Questions:
1. *"What was the most challenging bug or race condition you debugged?"*
2. *"If 50,000 users access your system concurrently, where will the database or API bottleneck first?"*
3. *"Why did you choose PostgreSQL over MongoDB for this specific data model?"*`
  }

  // 3. Zoho Corporation Interview Process
  if (q.includes('zoho')) {
    return `### Zoho Corporation MCA Placement Blueprint:

Zoho evaluates raw algorithmic problem-solving in pure Java or C without relying on built-in collections.

#### Round 1: Basic Programming & C/Java Output Prediction
- **Format**: 20 technical MCQs (pointers, bitwise operators, recursion trace, loop boundaries) + 10 quantitative aptitude questions.
- **Preparation**: Practice output prediction questions and manual pointer dry-runs.

#### Round 2: Advanced Problem Solving (5 Coding Questions)
- **Topics**: 2D Matrix rotations, spiral traversals, custom string parsers (e.g. run-length decoding), and custom data structures.
- **Crucial Rule**: Standard library shortcuts (e.g. \`HashMap\`, \`Collections.sort\`) are restricted. You must write the sorting or hashing logic from scratch!

#### Round 3: Object-Oriented Console Design (CLI Round)
- **Format**: 2.5 to 3 hours to design a complete terminal application (e.g. Railway Reservation, Taxi Booking, Splitwise, Bowling Alley, Flight Booking).
- **Evaluation Criteria**: Modular class design, proper encapsulation, handling edge cases, and working CLI menus.

#### Round 4: Technical Deep Dive & HR
- Code review of your Round 3 solution, deep dive into your FYP project, and cultural fit evaluation.`
  }

  // 4. TCS Digital / Prime
  if (q.includes('tcs') || q.includes('digital') || q.includes('prime')) {
    return `### TCS Digital / Prime Placement Preparation Strategy:

TCS Digital and Prime offer premier packages for candidates demonstrating strong algorithmic and system fundamentals.

#### 1. Advanced Coding Section (2 Questions · 60 Mins)
- **High-Yield Topics**:
  - **Dynamic Programming**: 0/1 Knapsack, Coin Change, Longest Increasing Subsequence.
  - **Graph Algorithms**: BFS/DFS connected components, shortest path in grids.
  - **Array & String Processing**: Sliding window, two pointers, prefix sums.
- **Tip**: Always analyze your time and space complexity before submitting. Strict constraints mean $O(N^2)$ solutions will time out on hidden test cases!

#### 2. Advanced Quantitative Aptitude & Speed Math
- Master Permutations & Combinations, Probability, Number Theory (remainders, GCD/LCM), Data Sufficiency, and Geometry.

#### 3. Technical Interview Focus
- Operating Systems (Virtual memory, paging, process synchronization).
- Database Systems (B-Tree indexing, Normalization, ACID isolation levels).`
  }

  // 5. Readiness Score Improvement
  if (q.includes('readiness') || q.includes('score') || q.includes('improve')) {
    return `### How to Boost Your PSGMX Readiness Score Rapidly:

Your Readiness Score is calculated from 4 core input dimensions:

1. **Daily Five Streak Consistency (20% Weight)**:
   - Complete today's 5 micro-questions in the **Train Gymnasium**. Maintaining a 7+ day streak adds a direct multiplier to your readiness tier.
2. **Quest Verification (20% Weight)**:
   - Submit and verify coding problems in **CodeBox Tasks**. Passing all automated test cases proves algorithmic readiness.
3. **Session Attendance (30% Weight)**:
   - Ensure your placement training attendance remains above 90%.
4. **LeetCode Momentum (15% Weight)**:
   - Sync your LeetCode profile handle in **Account Settings** and solve 1-2 medium problems daily.

> **Pro-Tip**: Check your **Readiness & Progress** breakdown to identify your lowest dimension—improving your weakest metric gives the fastest overall score boost!`
  }

  // 6. Companies Visiting MCA
  if (q.includes('companies') || q.includes('company') || q.includes('visiting') || q.includes('tier')) {
    return `### Companies Frequently Recruiting MCA Graduates at PSG Tech:

The MCA department has strong placement relationships across both product and digital enterprise leaders:

#### Tier 1 / Product Engineering
- **Zoho Corporation** (Software Developers, Technical Staff)
- **Cisco Systems** (Software Engineers, Core Network Software)
- **Amazon Web Services (AWS)** (Cloud Support, SDE Interns)
- **Thoughtworks** (Application Developers, Consultant)
- **SAP Labs & Oracle** (Enterprise Cloud Engineers)

#### Digital Transformation & IT Solutions
- **TCS Digital & Prime** (Advanced Software Engineers)
- **Cognizant GenC Elevate** (Full Stack Software Engineers)
- **Accenture & Infosys** (Specialist Programmers)
- **Hexaware & LatentView Analytics** (Data & Software Engineering)

> Keep your **Interview Patterns** and **Knowledge Brain** bookmarked for round-by-round alumni debriefs!`
  }

  // 7. General Dynamic Fallback
  return `### Senior Placement Guidance on "${query}":

Here is what you need to prioritize as an MCA scholar at PSG College of Technology:

1. **Daily Practice Rhythm**: Complete today's **Daily Five** in the Train Gymnasium and solve at least 1 medium DSA problem on CodeBox/LeetCode every day.
2. **Core CS Foundations**: Solidify your understanding of **DBMS (ACID, B-Tree Indexes)**, **OS (Processes, Memory, Deadlocks)**, and **OOP Design Patterns**.
3. **Proof of Work**: Update your **FYP Portfolio** with a clean GitHub repository and architectural notes.
4. **Learn from Seniors**: Check the **Lineage Mentors** and **Interview Pattern Library** tabs for real interview experiences.

Feel free to ask me for specific company breakdowns (Zoho, TCS, Cisco), HR frameworks, or coding problem explanations!`
}

export async function POST(req: NextRequest) {
  try {
    const session = await getUserFromRequest(req)
    const userId = session?.id || 'active-student'

    let body: { query?: unknown }
    try {
      body = await req.json()
    } catch {
      return NextResponse.json({ error: 'Invalid request body' }, { status: 400 })
    }

    const query = typeof body.query === 'string' ? body.query.trim() : ''
    if (!query) {
      return NextResponse.json({ error: 'query is required' }, { status: 400 })
    }

    // 1. Build RAG context from Knowledge Brain
    let ragContext = { articles: [] as any[], systemPrompt: SYSTEM_PROMPT }
    try {
      ragContext = await buildRAGContext(query, userId)
    } catch (ragErr) {
      console.warn('[AI Senior] RAG Context lookup note:', ragErr)
    }

    const contextText = formatRAGContextForPrompt(ragContext)

    // 2. Try LLM generation
    let answer = ''
    let llmUsed = 'senior-knowledge-engine'

    try {
      const prompt = `Knowledge Brain Context:\n${contextText}\n\nStudent Question: ${query}\n\nPlease provide a clear, practical, structured, and motivating answer tailored for a PSG Tech MCA student:`
      const aiResult = await executeOpenRouterPrompt(prompt, 'ai_senior_qa', ragContext.systemPrompt || SYSTEM_PROMPT)
      if (aiResult?.text && !aiResult.text.includes('offline companion mode')) {
        answer = aiResult.text.trim()
        llmUsed = aiResult.modelUsed
      }
    } catch (aiErr) {
      console.warn('[AI Senior] LLM generation note:', aiErr)
    }

    // 3. If LLM returned empty or generic offline text, use domain knowledge engine
    if (!answer || answer.includes('offline companion mode')) {
      answer = getExpertDomainAnswer(query)
    }

    // Non-blocking log insertion
    try {
      if (session?.id) {
        supabaseAdmin.from('ai_query_logs').insert({ user_id: session.id, query_text: query }).then(() => {})
      }
    } catch {}

    return NextResponse.json({
      success: true,
      answer,
      llm_used: llmUsed,
      rag_sources_count: ragContext.articles.length,
    })
  } catch (error) {
    console.error('AI Senior API Error:', error)
    return NextResponse.json({
      success: true,
      answer: getExpertDomainAnswer('general'),
      llm_used: 'senior-knowledge-fallback',
      rag_sources_count: 0,
    })
  }
}
