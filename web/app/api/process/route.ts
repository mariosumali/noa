import { NextRequest, NextResponse } from 'next/server'
import { createServerSupabaseClient } from '@/lib/supabase'
import { processPrompt, processPromptWithScreen, processPromptWithContext } from '@/lib/openai'
import { 
  isGmailQuery, 
  getUnreadEmails, 
  searchEmails, 
  getEmailsFrom, 
  getImportantEmails,
  getUnreadCount,
  formatEmailsForContext,
  extractSenderFromQuery
} from '@/lib/gmail'

// POST /api/process - Process a voice command and return AI response
export async function POST(request: NextRequest) {
  try {
    const supabase = createServerSupabaseClient()
    const body = await request.json()

    const { user_id, device_id, text, screenshot } = body

    if (!text) {
      return NextResponse.json({ error: 'text is required' }, { status: 400 })
    }

    let response: string
    let emailContext: string | null = null

    // Check if this is a Gmail query and user has Gmail connected
    if (user_id && isGmailQuery(text)) {
      console.log('Gmail query detected, fetching email context...')
      
      try {
        // Determine what type of email query this is
        const lowercased = text.toLowerCase()
        let emails = []
        
        // Check for specific sender
        const sender = extractSenderFromQuery(text)
        if (sender) {
          console.log(`Searching emails from: ${sender}`)
          emails = await getEmailsFrom(user_id, sender, 5)
        }
        // Check for unread
        else if (lowercased.includes('unread') || lowercased.includes('new email') || lowercased.includes('new message')) {
          const unreadCount = await getUnreadCount(user_id)
          emails = await getUnreadEmails(user_id, 5)
          emailContext = `You have ${unreadCount} unread emails.\n\nRecent unread:\n${formatEmailsForContext(emails)}`
        }
        // Check for important
        else if (lowercased.includes('important') || lowercased.includes('priority') || lowercased.includes('urgent')) {
          emails = await getImportantEmails(user_id, 5)
        }
        // Check for search terms
        else if (lowercased.includes('search') || lowercased.includes('find')) {
          // Extract search term - everything after "search for" or "find"
          const searchMatch = text.match(/(?:search for|find|about)\s+(.+)/i)
          if (searchMatch) {
            emails = await searchEmails(user_id, searchMatch[1], 5)
          }
        }
        // Default: get recent unread
        else {
          emails = await getUnreadEmails(user_id, 5)
        }

        if (!emailContext && emails.length > 0) {
          emailContext = `Here are the relevant emails:\n\n${formatEmailsForContext(emails)}`
        } else if (!emailContext) {
          emailContext = 'No matching emails found.'
        }
        
        console.log(`Email context prepared: ${emails.length} emails`)
      } catch (gmailError) {
        console.error('Gmail fetch error:', gmailError)
        // Check if it's a "not connected" error
        if ((gmailError as Error).message?.includes('not connected')) {
          emailContext = '[Gmail is not connected. The user needs to connect their Gmail in settings first.]'
        } else {
          emailContext = '[Error fetching emails. Gmail may need to be reconnected.]'
        }
      }
    }

    // Process with appropriate method
    if (screenshot) {
      console.log(`Processing with vision - text: "${text.substring(0, 50)}...", screenshot: ${Math.round(screenshot.length / 1024)}KB`)
      response = await processPromptWithScreen(text, screenshot)
    } else if (emailContext) {
      console.log(`Processing with email context`)
      response = await processPromptWithContext(text, emailContext)
    } else {
      console.log(`Processing text only - "${text.substring(0, 50)}..."`)
      response = await processPrompt(text)
    }

    // Save to database
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
      
      if (device_id) {
        insertData.device_id = device_id
      } else if (!user_id) {
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
