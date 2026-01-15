import { NextRequest, NextResponse } from 'next/server'
import { createServerSupabaseClient } from '@/lib/supabase'
import { processPrompt, processPromptWithScreen } from '@/lib/openai'

// POST /api/process - Process a voice command and return AI response
export async function POST(request: NextRequest) {
  try {
    const supabase = createServerSupabaseClient()
    const body = await request.json()

    const { user_id, device_id, text, screenshot } = body

    if (!text) {
      return NextResponse.json({ error: 'text is required' }, { status: 400 })
    }

    // Process with or without screenshot
    let response: string
    if (screenshot) {
      console.log(`Processing with vision - text: "${text.substring(0, 50)}...", screenshot: ${Math.round(screenshot.length / 1024)}KB`)
      response = await processPromptWithScreen(text, screenshot)
    } else {
      console.log(`Processing text only - "${text.substring(0, 50)}..."`)
      response = await processPrompt(text)
    }

    // Always save to database (use device_id if no user_id)
    let promptId: string | null = null
    try {
      const insertData: {
        text: string
        response: string
        screenshot_url: string | null
        user_id?: string
        device_id?: string
      } = {
        text,
        response,
        screenshot_url: screenshot ? 'screenshot_included' : null,
      }

      if (user_id) {
        insertData.user_id = user_id
      }
      
      // Use device_id for anonymous tracking, or generate from request
      if (device_id) {
        insertData.device_id = device_id
      } else if (!user_id) {
        // Generate a device ID from request headers as fallback
        const ip = request.headers.get('x-forwarded-for') || 'unknown'
        const userAgent = request.headers.get('user-agent') || 'unknown'
        insertData.device_id = `anon_${Buffer.from(ip + userAgent).toString('base64').slice(0, 20)}`
      }

      const { data: prompt, error } = await supabase
        .from('prompts')
        .insert(insertData)
        .select('id')
        .single()

      if (error) {
        console.error('Database error:', error)
      } else if (prompt) {
        promptId = prompt.id
      }
    } catch (dbError) {
      console.error('Failed to save prompt:', dbError)
      // Continue - don't fail the response just because DB save failed
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
