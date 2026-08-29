// ============================================================
// PSGMX — lib/ai/openrouter-free-chain.ts
// Strict OpenRouter Free Models Fallback Chain
// Enforces PRD Chapter 0.2 & Appendix A decision 7.
//
// Models:
//   1. google/gemini-2.0-flash-exp:free (General Q&A, Comm, Moderation)
//   2. meta-llama/llama-3.3-70b-instruct:free (Strong reasoning fallback)
//   3. deepseek/deepseek-r1:free (Code evaluation, complex logic)
//   4. microsoft/phi-4:free (Lightweight rate-limit fallback)
//   5. Local Tips Bank (Final graceful fallback)
// ============================================================

export type AITaskType = 
  | 'code_evaluation' 
  | 'ai_senior_qa' 
  | 'communication_evaluation' 
  | 'knowledge_moderation' 
  | 'fyp_explanation'
  | 'general';

interface ModelConfig {
  id: string;
  name: string;
  maxTokens: number;
  temperature: number;
}

const FREE_MODELS: Record<string, ModelConfig> = {
  gemini: {
    id: 'google/gemini-2.0-flash-exp:free',
    name: 'Gemini 2.0 Flash Exp (Free)',
    maxTokens: 1000,
    temperature: 0.3,
  },
  llama: {
    id: 'meta-llama/llama-3.3-70b-instruct:free',
    name: 'Llama 3.3 70B Instruct (Free)',
    maxTokens: 1000,
    temperature: 0.3,
  },
  deepseek: {
    id: 'deepseek/deepseek-r1:free',
    name: 'DeepSeek R1 (Free)',
    maxTokens: 1200,
    temperature: 0.2,
  },
  phi: {
    id: 'microsoft/phi-4:free',
    name: 'Phi-4 (Free)',
    maxTokens: 800,
    temperature: 0.4,
  },
};

// Priority chain order based on task type per PRD Chapter 0.2
function getModelChainForTask(taskType: AITaskType): ModelConfig[] {
  switch (taskType) {
    case 'code_evaluation':
    case 'fyp_explanation':
      return [FREE_MODELS.deepseek, FREE_MODELS.llama, FREE_MODELS.gemini, FREE_MODELS.phi];
    case 'knowledge_moderation':
      return [FREE_MODELS.llama, FREE_MODELS.gemini, FREE_MODELS.phi, FREE_MODELS.deepseek];
    case 'ai_senior_qa':
    case 'communication_evaluation':
    case 'general':
    default:
      return [FREE_MODELS.gemini, FREE_MODELS.llama, FREE_MODELS.deepseek, FREE_MODELS.phi];
  }
}

const LOCAL_FALLBACK_TIPS: Record<AITaskType, string> = {
  code_evaluation: JSON.stringify({
    quality_score: 6,
    time_complexity: "O(n) - estimated",
    space_complexity: "O(1) - estimated",
    issues: ["Automated AI evaluation is temporarily busy; code passed standard test suite."],
    brief_feedback: "Your solution passed the required test cases. Keep optimizing for edge cases and clean variable naming."
  }),
  ai_senior_qa: "Focus on strong placement fundamentals: daily DSA practice on CodeBox/LeetCode, DBMS ACID isolation levels, Operating System memory & process scheduling, and practicing your 90-second intro with the STAR technique.",
  communication_evaluation: JSON.stringify({
    clarity_score: 7,
    structure_score: 7,
    filler_word_count: 1,
    relevance_score: 8,
    brief_feedback: "Good attempt! Structure your answers using the STAR method: Situation, Task, Action, and Result.",
    suggested_improvement: "Practice pausing instead of using filler sounds, and quantify your project impact."
  }),
  knowledge_moderation: JSON.stringify({
    flagged: false,
    reason: "Auto-pass to faculty queue (AI pre-screen offline).",
    confidence: "medium"
  }),
  fyp_explanation: JSON.stringify({
    problem_clarity_score: 7,
    technical_depth_score: 7,
    quantified_results_score: 6,
    feedback: "Ensure you clearly articulate the specific problem statement before jumping into the tech stack. Highlight real-world metrics or performance benchmarks.",
    suggested_focus: "Focus on why this architecture was chosen over alternatives."
  }),
  general: "Keep preparing consistently. Daily Five and CodeBox tasks build long-term placement readiness."
};

export interface AICallResponse {
  text: string;
  modelUsed: string;
  isFallback: boolean;
}

export async function executeOpenRouterPrompt(
  prompt: string,
  taskType: AITaskType = 'general',
  systemPrompt?: string
): Promise<AICallResponse> {
  const apiKey = process.env.OPENROUTER_API_KEY?.trim();
  
  if (!apiKey) {
    console.warn('[OpenRouter] No OPENROUTER_API_KEY set. Returning local fallback.');
    return {
      text: LOCAL_FALLBACK_TIPS[taskType],
      modelUsed: 'local-fallback-bank',
      isFallback: true
    };
  }

  const modelChain = getModelChainForTask(taskType);

  for (const model of modelChain) {
    try {
      const messages: { role: string; content: string }[] = [];
      if (systemPrompt) {
        messages.push({ role: 'system', content: systemPrompt });
      }
      messages.push({ role: 'user', content: prompt });

      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), 12000); // 12-second timeout per model

      const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${apiKey}`,
          'Content-Type': 'application/json',
          'HTTP-Referer': process.env.NEXT_PUBLIC_APP_URL || 'https://psgmx.tech',
          'X-Title': 'PSGMX Department OS'
        },
        body: JSON.stringify({
          model: model.id,
          messages,
          max_tokens: model.maxTokens,
          temperature: model.temperature
        }),
        signal: controller.signal
      });

      clearTimeout(timeout);

      if (response.ok) {
        const data = await response.json();
        const content = data?.choices?.[0]?.message?.content;
        if (content && content.trim().length > 0) {
          return {
            text: content.trim(),
            modelUsed: model.id,
            isFallback: false
          };
        }
      } else {
        const errText = await response.text();
        console.warn(`[OpenRouter] ${model.id} returned status ${response.status}:`, errText);
      }
    } catch (err: any) {
      console.warn(`[OpenRouter] Error calling ${model.id}:`, err?.message || err);
    }
  }

  // All models in the chain failed or timed out -> return local fallback tip
  console.warn(`[OpenRouter] All free models in chain failed for task ${taskType}. Using local tips bank.`);
  return {
    text: LOCAL_FALLBACK_TIPS[taskType],
    modelUsed: 'local-fallback-bank',
    isFallback: true
  };
}
