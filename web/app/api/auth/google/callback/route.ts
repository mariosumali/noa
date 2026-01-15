import { NextRequest, NextResponse } from 'next/server'
import { createServerSupabaseClient } from '@/lib/supabase'
import { getTokensFromCode, createOAuth2Client } from '@/lib/gmail'
import { google } from 'googleapis'

// GET /api/auth/google/callback - Handle OAuth callback
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url)
    const code = searchParams.get('code')
    const state = searchParams.get('state')
    const error = searchParams.get('error')

    if (error) {
      console.error('OAuth error:', error)
      return NextResponse.redirect(new URL('/dashboard/settings?error=oauth_denied', request.url))
    }

    if (!code || !state) {
      console.error('Gmail OAuth callback missing params - code:', !!code, 'state:', !!state)
      // This might be a Supabase OAuth callback hitting the wrong URL
      return NextResponse.redirect(new URL('/dashboard/settings?error=missing_params', request.url))
    }

    // Decode state
    let stateData: { userId: string; returnUrl: string }
    try {
      stateData = JSON.parse(Buffer.from(state, 'base64').toString())
    } catch {
      return NextResponse.redirect(new URL('/dashboard/settings?error=invalid_state', request.url))
    }

    // Exchange code for tokens
    const tokens = await getTokensFromCode(code)

    if (!tokens.access_token) {
      return NextResponse.redirect(new URL('/dashboard/settings?error=no_token', request.url))
    }

    // Get user's Gmail address
    const oauth2Client = createOAuth2Client()
    oauth2Client.setCredentials(tokens)
    const gmail = google.gmail({ version: 'v1', auth: oauth2Client })
    const profile = await gmail.users.getProfile({ userId: 'me' })
    const email = profile.data.emailAddress

    // Store tokens in Supabase
    const supabase = createServerSupabaseClient()
    
    const { error: upsertError } = await supabase
      .from('user_integrations')
      .upsert({
        user_id: stateData.userId,
        provider: 'gmail',
        access_token: tokens.access_token,
        refresh_token: tokens.refresh_token,
        token_expires_at: tokens.expiry_date 
          ? new Date(tokens.expiry_date).toISOString() 
          : new Date(Date.now() + 3600000).toISOString(),
        email: email,
        updated_at: new Date().toISOString(),
      }, {
        onConflict: 'user_id,provider'
      })

    if (upsertError) {
      console.error('Failed to store tokens:', upsertError)
      return NextResponse.redirect(new URL('/dashboard/settings?error=storage_failed', request.url))
    }

    // Redirect back to settings with success
    return NextResponse.redirect(new URL(`${stateData.returnUrl}?gmail=connected`, request.url))
  } catch (error) {
    console.error('OAuth callback error:', error)
    return NextResponse.redirect(new URL('/dashboard/settings?error=callback_failed', request.url))
  }
}
