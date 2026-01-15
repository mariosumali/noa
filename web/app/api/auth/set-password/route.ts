import { NextRequest, NextResponse } from 'next/server'
import { createSupabaseServerClient } from '@/lib/supabase-server'

// POST /api/auth/set-password - Set password for Google users
export async function POST(request: NextRequest) {
    try {
        const supabase = await createSupabaseServerClient()

        // Get current user
        const { data: { user }, error: authError } = await supabase.auth.getUser()

        if (authError || !user) {
            return NextResponse.json(
                { error: 'Not authenticated' },
                { status: 401 }
            )
        }

        const { password } = await request.json()

        if (!password || password.length < 6) {
            return NextResponse.json(
                { error: 'Password must be at least 6 characters' },
                { status: 400 }
            )
        }

        // Update user password
        const { error: updateError } = await supabase.auth.updateUser({
            password: password
        })

        if (updateError) {
            console.error('Set password error:', updateError)
            return NextResponse.json(
                { error: updateError.message },
                { status: 400 }
            )
        }

        return NextResponse.json({ success: true })
    } catch (error) {
        console.error('Set password error:', error)
        return NextResponse.json(
            { error: 'Failed to set password' },
            { status: 500 }
        )
    }
}
