import { GoogleGenerativeAI } from '@google/generative-ai'

export interface GeminiResponse {
  text: string
  modelUsed: string
}

export async function executeGeminiPrompt(
  prompt: string,
  systemPrompt?: string,
): Promise<GeminiResponse | null> {
  const apiKey = process.env.GEMINI_API_KEY?.trim()
  if (!apiKey || apiKey.startsWith('your-')) return null

  try {
    const genAI = new GoogleGenerativeAI(apiKey)
    const modelName = process.env.GEMINI_MODEL?.trim() || 'gemini-1.5-flash'
    const model = genAI.getGenerativeModel({
      model: modelName,
      systemInstruction: systemPrompt?.trim() || undefined,
    })

    const result = await model.generateContent(prompt)
    const response = await result.response
    const text = response.text()
    if (typeof text === 'string' && text.trim()) {
      return {
        text: text.trim(),
        modelUsed: modelName,
      }
    }
  } catch (err) {
    console.warn('[Gemini AI] Gemini execution failed, falling back to OpenRouter:', err instanceof Error ? err.message : String(err))
  }

  return null
}
