import { NextRequest, NextResponse } from 'next/server'
import { createServerSupabaseClient } from '@/lib/supabase'

// GET /api/prompts - Get prompt history for a user or device
// GET /api/prompts - Get prompt history for a user or device
export async function GET(request: NextRequest) {
  try {
    const supabase = createServerSupabaseClient()
    const { searchParams } = new URL(request.url)

    const requestedUserId = searchParams.get('user_id')
    const deviceId = searchParams.get('device_id')
    const limit = parseInt(searchParams.get('limit') || '50')
    const offset = parseInt(searchParams.get('offset') || '0')

    if (!requestedUserId && !deviceId) {
      return NextResponse.json({ error: 'user_id or device_id is required' }, { status: 400 })
    }

    // Verify authentication
    let authenticatedUserId: string | null = null
    const authHeader = request.headers.get('Authorization')
    if (authHeader) {
      const token = authHeader.replace('Bearer ', '')
      const { data: { user }, error } = await supabase.auth.getUser(token)
      if (!error && user) {
        authenticatedUserId = user.id
      }
    }

    // Security Checks
    if (requestedUserId) {
      // If requesting a specific user_id, must be authenticated as that user
      if (requestedUserId !== authenticatedUserId) {
        return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
      }
    }

    let query = supabase
      .from('prompts')
      .select('id, text, response, created_at, screenshot_url, tools_used', { count: 'exact' })
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1)

    // Filter Logic
    if (requestedUserId) {
      // Authenticated User History
      query = query.eq('user_id', requestedUserId)
    } else if (deviceId) {
      // Anonymous Device History
      // CRITICAL: Only show prompts that have NO user_id. 
      // This prevents logged-out users from seeing history of logged-in users on the same device.
      query = query
        .eq('device_id', deviceId)
        .is('user_id', null)
    }

    const { data: prompts, error, count } = await query

    if (error) {
      console.error('Prompts fetch error:', error)
      return NextResponse.json({ error: error.message }, { status: 500 })
    }

    return NextResponse.json(prompts || [])
  } catch (error) {
    console.error('Prompts API error:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}

// POST /api/prompts - Save a new prompt
export async function POST(request: NextRequest) {
  try {
    const supabase = createServerSupabaseClient()
    const body = await request.json()

    const { user_id, device_id, text, response, screenshot_url } = body

    if (!text) {
      return NextResponse.json({ error: 'text is required' }, { status: 400 })
    }

    const insertData: {
      text: string
      response?: string
      screenshot_url?: string
      user_id?: string
      device_id?: string
    } = { text }

    if (user_id) insertData.user_id = user_id
    if (device_id) insertData.device_id = device_id
    if (response) insertData.response = response
    if (screenshot_url) insertData.screenshot_url = screenshot_url

    const { data: prompt, error } = await supabase
      .from('prompts')
      .insert(insertData)
      .select()
      .single()

    if (error) {
      console.error('Prompt insert error:', error)
      return NextResponse.json({ error: error.message }, { status: 500 })
    }

    return NextResponse.json({ prompt })
  } catch (error) {
    console.error('Prompts POST error:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
