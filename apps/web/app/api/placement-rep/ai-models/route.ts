import { NextRequest, NextResponse } from 'next/server'
export const maxDuration = 60;
import { getUserFromRequest } from '@/lib/auth'
import {
  FREE_MODELS_CATALOG,
  getAIModelConfig,
  updateAIModelConfig,
  executeOpenRouterPrompt,
} from '@/lib/ai/openrouter-free-chain'

export async function GET(req: NextRequest) {
  const user = await getUserFromRequest(req)
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  const config = getAIModelConfig()
  return NextResponse.json({
    config,
    availableFreeModels: FREE_MODELS_CATALOG,
    hasApiKey: Boolean(process.env.OPENROUTER_API_KEY?.trim()),
  })
}

export async function POST(req: NextRequest) {
  const user = await getUserFromRequest(req)
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  try {
    const body = await req.json()

    // Test model connection action
    if (body.action === 'test') {
      const testModel = body.model || getAIModelConfig().mainModel
      const res = await executeOpenRouterPrompt(
        'Respond with "OK" if you can hear me.',
        'general',
        'System ping check. Reply with "OK".',
        50,
        testModel
      )
      return NextResponse.json({ success: true, message: `Model responded: ${res.text}`, modelUsed: res.modelUsed })
    }

    // Save model configuration
    const mainModel = typeof body.mainModel === 'string' ? body.mainModel.trim() : undefined
    const fallbackModels = Array.isArray(body.fallbackModels)
      ? body.fallbackModels.map((m: any) => String(m).trim()).filter(Boolean)
      : undefined

    const updated = updateAIModelConfig({
      mainModel,
      fallbackModels,
    })

    return NextResponse.json({
      success: true,
      config: updated,
      message: 'AI Model routing chain updated successfully.',
    })
  } catch (err) {
    return NextResponse.json(
      { error: err instanceof Error ? err.message : 'Failed to update AI model config' },
      { status: 500 }
    )
  }
}
