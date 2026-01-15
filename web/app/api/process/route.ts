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
import {
  isCalendarQuery,
  getEventsForDate,
  getUpcomingEvents,
  formatEventsForContext,
  parseDateFromQuery
} from '@/lib/calendar'

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
    let calendarContext: string | null = null

    // Check if this is a Calendar query and user has Google connected
    if (user_id && isCalendarQuery(text)) {
      console.log('Calendar query detected, fetching calendar context...')

      try {
        const lowercased = text.toLowerCase()

        // Try to parse a specific date from the query
        const parsedDate = parseDateFromQuery(text)

        if (parsedDate) {
          // Fetch events for the specific date
          const events = await getEventsForDate(user_id, parsedDate.offset)
          calendarContext = `You have ${events.length} event(s) on ${parsedDate.label}.\n\n${formatEventsForContext(events)}`
        }
        // Check for upcoming/this week/schedule (general range queries)
        else if (lowercased.includes('upcoming') || lowercased.includes('week') || lowercased.includes('schedule')) {
          const events = await getUpcomingEvents(user_id, 7)
          calendarContext = `Here are your upcoming events:\n\n${formatEventsForContext(events)}`
        }
        // Default: show today's events
        else {
          const events = await getEventsForDate(user_id, 0)
          calendarContext = `Here is your calendar for today:\n\n${formatEventsForContext(events)}`
        }

        console.log(`Calendar context prepared`)
      } catch (calendarError) {
        console.error('Calendar fetch error:', calendarError)
        if ((calendarError as Error).message?.includes('not connected')) {
          calendarContext = '[Google Calendar is not connected. The user needs to connect their Google account in settings first.]'
        } else {
          calendarContext = '[Error fetching calendar. Google may need to be reconnected.]'
        }
      }
    }

    // Check if this is a Gmail query and user has Gmail connected
    if (user_id && isGmailQuery(text)) {
      console.log('Gmail query detected, fetching email context...')

      try {
        // Determine what type of email query this is
        const lowercased = text.toLowerCase()
        let emails: Awaited<ReturnType<typeof getUnreadEmails>> = []

        // Check for unread first (most common query)
        if (lowercased.includes('unread') || lowercased.includes('new email') || lowercased.includes('new message') || lowercased.includes('how many')) {
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
        // Check for specific sender (only if not matching above patterns)
        else {
          const sender = extractSenderFromQuery(text)
          if (sender) {
            console.log(`Searching emails from: ${sender}`)
            emails = await getEmailsFrom(user_id, sender, 5)
          } else {
            // Default: get recent unread
            emails = await getUnreadEmails(user_id, 5)
          }
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
    // Combine contexts if multiple are available
    const combinedContext = [calendarContext, emailContext].filter(Boolean).join('\n\n---\n\n')

    if (screenshot) {
      console.log(`Processing with vision - text: "${text.substring(0, 50)}...", screenshot: ${Math.round(screenshot.length / 1024)}KB`)
      response = await processPromptWithScreen(text, screenshot)
    } else if (combinedContext) {
      console.log(`Processing with context (calendar: ${!!calendarContext}, email: ${!!emailContext})`)
      response = await processPromptWithContext(text, combinedContext)
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
