import { NextRequest, NextResponse } from 'next/server'
import { createServerSupabaseClient } from '@/lib/supabase'
import { getUnreadEmails, getUnreadCount, formatEmailsForContext } from '@/lib/gmail'

// GET /api/integrations/gmail/test - Test Gmail integration
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url)
    const userId = searchParams.get('user_id')

    if (!userId) {
      return NextResponse.json({ error: 'user_id required' }, { status: 400 })
    }

    // Check if Gmail is connected
    const supabase = createServerSupabaseClient()
    const { data: integration, error } = await supabase
      .from('user_integrations')
      .select('*')
      .eq('user_id', userId)
      .eq('provider', 'gmail')
      .single()

    if (error || !integration) {
      return NextResponse.json({ 
        connected: false, 
        error: 'Gmail not connected',
        message: 'Go to /dashboard/settings and click Connect next to Gmail'
      })
    }

    // Try to fetch emails
    try {
      const unreadCount = await getUnreadCount(userId)
      const emails = await getUnreadEmails(userId, 3)
      
      return NextResponse.json({
        connected: true,
        email: integration.email,
        unreadCount,
        recentEmails: emails.map(e => ({
          from: e.from,
          subject: e.subject,
          snippet: e.snippet.slice(0, 100) + '...'
        })),
        formatted: formatEmailsForContext(emails)
      })
    } catch (gmailError) {
      return NextResponse.json({
        connected: true,
        email: integration.email,
        error: 'Failed to fetch emails',
        details: (gmailError as Error).message
      })
    }
  } catch (error) {
    console.error('Gmail test error:', error)
    return NextResponse.json({ error: 'Test failed', details: (error as Error).message }, { status: 500 })
  }
}
