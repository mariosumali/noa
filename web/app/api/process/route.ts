import { NextRequest, NextResponse } from 'next/server'
import { createServerSupabaseClient } from '@/lib/supabase'
import { processPrompt, processPromptWithScreen } from '@/lib/openai'

// POST /api/process - Process a voice command and return AI response
export async function POST(request: NextRequest) {
  try {
    const supabase = createServerSupabaseClient()
    const body = await request.json()

    const { user_id, text, screenshot } = body

    if (!text) {
      return NextResponse.json({ error: 'text is required' }, { status: 400 })
    }

    // Process with or without screenshot
    let response: string
    if (screenshot) {
      response = await processPromptWithScreen(text, screenshot)
    } else {
      response = await processPrompt(text)
    }

    // Save to database if user_id provided
    let promptId: string | null = null
    if (user_id) {
      const { data: prompt, error } = await supabase
        .from('prompts')
        .insert({
          user_id,
          text,
          response,
          screenshot_url: screenshot ? 'screenshot_included' : null,
        })
        .select('id')
        .single()

      if (!error && prompt) {
        promptId = prompt.id
      }
    }

    return NextResponse.json({ 
      response,
      prompt_id: promptId
    })
  } catch (error) {
    console.error('Process error:', error)
    return NextResponse.json({ error: 'Failed to process request' }, { status: 500 })
  }
}
