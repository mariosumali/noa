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
  parseDateFromQuery,
  quickAddEvent,
  findEventsByTitle,
  deleteEvent
} from '@/lib/calendar'

// Detect calendar action intent
function getCalendarActionIntent(text: string): 'create' | 'delete' | 'query' | null {
  const lowercased = text.toLowerCase()

  // Create patterns
  if (lowercased.match(/\b(create|add|schedule|set up|book|make)\b.*(meeting|event|appointment|reminder|call)/i) ||
    lowercased.match(/\b(meeting|event|appointment|call)\b.*(at|on|for|tomorrow|today)/i)) {
    return 'create'
  }

  // Delete patterns
  if (lowercased.match(/\b(cancel|delete|remove|clear)\b.*(meeting|event|appointment|call)/i)) {
    return 'delete'
  }

  return 'query'
}

// Clean up event text for Google's quickAdd - extract just the event details
function cleanEventText(text: string): string {
  let cleaned = text
    // Remove command prefixes
    .replace(/^(please\s+)?(can you\s+)?(hey\s+)?(noa\s+)?/i, '')
    .replace(/^(create|add|schedule|set up|book|make)\s+(a\s+)?/i, '')
    // Remove "for me" type phrases
    .replace(/\s+for me\b/gi, '')
    // Remove trailing punctuation
    .replace(/[.!?]+$/, '')
    .trim()

  return cleaned
}

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
    const toolsUsed: string[] = []  // Track which tools were used

    // Check if this is a Calendar query and user has Google connected
    if (user_id && isCalendarQuery(text)) {
      console.log('Calendar query detected, fetching calendar context...')

      try {
        const lowercased = text.toLowerCase()
        const actionIntent = getCalendarActionIntent(text)

        // Handle calendar ACTIONS (create, delete)
        if (actionIntent === 'create') {
          console.log('Calendar CREATE action detected')
          try {
            const cleanedText = cleanEventText(text)
            console.log('Cleaned event text:', cleanedText)
            const event = await quickAddEvent(user_id, cleanedText)
            const startTime = event.start?.dateTime || event.start?.date
            const formattedTime = startTime ? new Date(startTime).toLocaleString('en-US', {
              weekday: 'long',
              month: 'short',
              day: 'numeric',
              hour: 'numeric',
              minute: '2-digit'
            }) : 'unknown time'
            calendarContext = `[EVENT CREATED] Successfully created: "${event.summary}" on ${formattedTime}.`
            toolsUsed.push('calendar_create')
          } catch (createError) {
            console.error('Failed to create event:', createError)
            calendarContext = '[Failed to create event. Please try again with a clearer time and description.]'
          }
        }
        else if (actionIntent === 'delete') {
          console.log('Calendar DELETE action detected')
          // Extract event name to search for
          const searchMatch = text.match(/(?:cancel|delete|remove|clear)\s+(?:my\s+)?(?:the\s+)?(.+?)(?:\s+meeting|\s+event|\s+appointment|\s+call)?$/i)
          if (searchMatch) {
            const searchTerm = searchMatch[1].trim()
            const matchingEvents = await findEventsByTitle(user_id, searchTerm, 14)

            if (matchingEvents.length === 0) {
              calendarContext = `[No event found matching "${searchTerm}" in the next 2 weeks.]`
            } else if (matchingEvents.length === 1) {
              const eventToDelete = matchingEvents[0]
              await deleteEvent(user_id, eventToDelete.id!)
              calendarContext = `[EVENT DELETED] Successfully cancelled: "${eventToDelete.summary}".`
              toolsUsed.push('calendar_delete')
            } else {
              // Multiple matches - list them for the user
              const eventList = matchingEvents.slice(0, 5).map(e => `- ${e.summary}`).join('\n')
              calendarContext = `[Multiple events found matching "${searchTerm}". Please be more specific:\n${eventList}]`
            }
          } else {
            calendarContext = '[Could not understand which event to cancel. Please specify the event name.]'
          }
        }
        // Handle calendar QUERIES (reading events)
        else {
          // Try to parse a specific date from the query
          const parsedDate = parseDateFromQuery(text)

          if (parsedDate) {
            // Fetch events for the specific date
            const events = await getEventsForDate(user_id, parsedDate.offset)
            calendarContext = `You have ${events.length} event(s) on ${parsedDate.label}.\n\n${formatEventsForContext(events)}`
            toolsUsed.push('calendar_query')
          }
          // Check for upcoming/this week/schedule (general range queries)
          else if (lowercased.includes('upcoming') || lowercased.includes('week') || lowercased.includes('schedule')) {
            const events = await getUpcomingEvents(user_id, 7)
            calendarContext = `Here are your upcoming events:\n\n${formatEventsForContext(events)}`
            toolsUsed.push('calendar_query')
          }
          // Default: show today's events
          else {
            const events = await getEventsForDate(user_id, 0)
            calendarContext = `Here is your calendar for today:\n\n${formatEventsForContext(events)}`
            toolsUsed.push('calendar_query')
          }
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
          toolsUsed.push('gmail_query')
        }
        // Check for important
        else if (lowercased.includes('important') || lowercased.includes('priority') || lowercased.includes('urgent')) {
          emails = await getImportantEmails(user_id, 5)
          toolsUsed.push('gmail_query')
        }
        // Check for search terms
        else if (lowercased.includes('search') || lowercased.includes('find')) {
          // Extract search term - everything after "search for" or "find"
          const searchMatch = text.match(/(?:search for|find|about)\s+(.+)/i)
          if (searchMatch) {
            emails = await searchEmails(user_id, searchMatch[1], 5)
            toolsUsed.push('gmail_query')
          }
        }
        // Check for specific sender (only if not matching above patterns)
        else {
          const sender = extractSenderFromQuery(text)
          if (sender) {
            console.log(`Searching emails from: ${sender}`)
            emails = await getEmailsFrom(user_id, sender, 5)
            toolsUsed.push('gmail_query')
          } else {
            // Default: get recent unread
            emails = await getUnreadEmails(user_id, 5)
            toolsUsed.push('gmail_query')
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
      console.log(`Processing with vision - text: "${text.substring(0, 50)}...", screenshot: ${Math.round(screenshot.length / 1024)} KB`)
      response = await processPromptWithScreen(text, screenshot)
    } else if (combinedContext) {
      console.log(`Processing with context(calendar: ${!!calendarContext}, email: ${!!emailContext})`)
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
        tools_used?: string[]
      } = {
        text,
        response,
        screenshot_url: screenshot ? 'screenshot_included' : null,
        tools_used: toolsUsed.length > 0 ? toolsUsed : undefined,
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
      prompt_id: promptId,
      tools_used: toolsUsed.length > 0 ? toolsUsed : undefined
    })
  } catch (error) {
    console.error('Process error:', error)
    return NextResponse.json({ error: 'Failed to process request' }, { status: 500 })
  }
}
