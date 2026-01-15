import { NextRequest, NextResponse } from 'next/server'
import { createSupabaseServerClient } from '@/lib/supabase-server'
import { getAuthUrl } from '@/lib/gmail'

// GET /api/integrations/gmail/connect - Redirect to Google OAuth
export async function GET(request: NextRequest) {
  try {
    const supabase = await createSupabaseServerClient()
    
    // Get current user
    const { data: { user }, error: authError } = await supabase.auth.getUser()
    
    if (authError || !user) {
      return NextResponse.redirect(new URL('/login', request.url))
    }

    // Create state with user ID for callback
    const state = Buffer.from(JSON.stringify({
      userId: user.id,
      returnUrl: request.nextUrl.searchParams.get('returnUrl') || '/dashboard/settings'
    })).toString('base64')

    const authUrl = getAuthUrl(state)
    
    console.log('Gmail OAuth URL:', authUrl)
    console.log('User ID:', user.id)
    
    if (!authUrl || !authUrl.startsWith('https://')) {
      console.error('Invalid auth URL generated:', authUrl)
      return NextResponse.redirect(new URL('/dashboard/settings?error=invalid_oauth_url', request.url))
    }
    
    return NextResponse.redirect(authUrl)
  } catch (error) {
    console.error('Gmail connect error:', error)
    return NextResponse.json({ error: 'Failed to start OAuth flow' }, { status: 500 })
  }
}
