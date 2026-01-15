import { NextRequest, NextResponse } from 'next/server'
import { createSupabaseServerClient } from '@/lib/supabase-server'

// GET /api/integrations/gmail/status - Check if Gmail is connected
export async function GET(request: NextRequest) {
  try {
    const supabase = await createSupabaseServerClient()
    
    // Get current user
    const { data: { user }, error: authError } = await supabase.auth.getUser()
    
    if (authError || !user) {
      return NextResponse.json({ connected: false, error: 'Not authenticated' }, { status: 401 })
    }

    // Check for Gmail integration
    const { data: integration, error } = await supabase
      .from('user_integrations')
      .select('email, created_at, updated_at')
      .eq('user_id', user.id)
      .eq('provider', 'gmail')
      .single()

    if (error || !integration) {
      return NextResponse.json({ connected: false })
    }

    return NextResponse.json({
      connected: true,
      email: integration.email,
      connectedAt: integration.created_at,
    })
  } catch (error) {
    console.error('Gmail status error:', error)
    return NextResponse.json({ error: 'Failed to check status' }, { status: 500 })
  }
}

// DELETE /api/integrations/gmail/status - Disconnect Gmail
export async function DELETE(request: NextRequest) {
  try {
    const supabase = await createSupabaseServerClient()
    
    // Get current user
    const { data: { user }, error: authError } = await supabase.auth.getUser()
    
    if (authError || !user) {
      return NextResponse.json({ error: 'Not authenticated' }, { status: 401 })
    }

    // Delete Gmail integration
    const { error } = await supabase
      .from('user_integrations')
      .delete()
      .eq('user_id', user.id)
      .eq('provider', 'gmail')

    if (error) {
      console.error('Failed to disconnect Gmail:', error)
      return NextResponse.json({ error: 'Failed to disconnect' }, { status: 500 })
    }

    return NextResponse.json({ success: true })
  } catch (error) {
    console.error('Gmail disconnect error:', error)
    return NextResponse.json({ error: 'Failed to disconnect' }, { status: 500 })
  }
}
