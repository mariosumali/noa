import { google, calendar_v3 } from 'googleapis'
import { createServerSupabaseClient } from './supabase'

// Create OAuth2 client for Calendar
export function createOAuth2Client() {
    return new google.auth.OAuth2(
        process.env.GOOGLE_CLIENT_ID,
        process.env.GOOGLE_CLIENT_SECRET,
        `${process.env.NEXT_PUBLIC_APP_URL || 'http://localhost:3000'}/api/auth/google/callback`
    )
}

// Get Calendar client for a user
export async function getCalendarClient(userId: string) {
    const supabase = createServerSupabaseClient()

    // Get stored tokens from Gmail integration (shared OAuth)
    const { data: integration, error } = await supabase
        .from('user_integrations')
        .select('*')
        .eq('user_id', userId)
        .eq('provider', 'google')
        .single()

    // Fallback to gmail provider for backwards compatibility
    if (error || !integration) {
        const { data: gmailIntegration, error: gmailError } = await supabase
            .from('user_integrations')
            .select('*')
            .eq('user_id', userId)
            .eq('provider', 'gmail')
            .single()

        if (gmailError || !gmailIntegration) {
            throw new Error('Google not connected')
        }

        return setupCalendarClient(gmailIntegration)
    }

    return setupCalendarClient(integration)
}

async function setupCalendarClient(integration: {
    access_token: string
    refresh_token: string
    token_expires_at: string
    user_id: string
}) {
    const oauth2Client = createOAuth2Client()
    oauth2Client.setCredentials({
        access_token: integration.access_token,
        refresh_token: integration.refresh_token,
    })

    // Check if token needs refresh
    const now = new Date()
    const expiresAt = new Date(integration.token_expires_at)

    if (now >= expiresAt && integration.refresh_token) {
        try {
            const { credentials } = await oauth2Client.refreshAccessToken()
            oauth2Client.setCredentials(credentials)

            // Update tokens in database
            const supabase = createServerSupabaseClient()
            await supabase
                .from('user_integrations')
                .update({
                    access_token: credentials.access_token,
                    token_expires_at: credentials.expiry_date
                        ? new Date(credentials.expiry_date).toISOString()
                        : new Date(Date.now() + 3600000).toISOString(),
                    updated_at: new Date().toISOString(),
                })
                .eq('user_id', integration.user_id)
                .eq('provider', 'google')
        } catch (refreshError) {
            console.error('Failed to refresh token:', refreshError)
            throw new Error('Failed to refresh Google token')
        }
    }

    return google.calendar({ version: 'v3', auth: oauth2Client })
}

// Get upcoming events for the next N days
export async function getUpcomingEvents(userId: string, days: number = 7): Promise<calendar_v3.Schema$Event[]> {
    const calendar = await getCalendarClient(userId)

    const now = new Date()
    const future = new Date()
    future.setDate(future.getDate() + days)

    const response = await calendar.events.list({
        calendarId: 'primary',
        timeMin: now.toISOString(),
        timeMax: future.toISOString(),
        maxResults: 20,
        singleEvents: true,
        orderBy: 'startTime',
    })

    return response.data.items || []
}

// Get today's events
export async function getTodaysEvents(userId: string): Promise<calendar_v3.Schema$Event[]> {
    return getEventsForDate(userId, 0)
}

// Get tomorrow's events
export async function getTomorrowsEvents(userId: string): Promise<calendar_v3.Schema$Event[]> {
    return getEventsForDate(userId, 1)
}

// Get events for a specific day offset (0 = today, 1 = tomorrow, etc.)
export async function getEventsForDate(userId: string, dayOffset: number = 0): Promise<calendar_v3.Schema$Event[]> {
    const calendar = await getCalendarClient(userId)

    const now = new Date()
    const targetDate = new Date(now.getFullYear(), now.getMonth(), now.getDate() + dayOffset)
    const endDate = new Date(now.getFullYear(), now.getMonth(), now.getDate() + dayOffset + 1)

    const response = await calendar.events.list({
        calendarId: 'primary',
        timeMin: targetDate.toISOString(),
        timeMax: endDate.toISOString(),
        maxResults: 50,
        singleEvents: true,
        orderBy: 'startTime',
    })

    return response.data.items || []
}

// Create a new event
export async function createEvent(
    userId: string,
    event: {
        summary: string
        description?: string
        startTime: Date
        endTime: Date
        location?: string
    }
): Promise<calendar_v3.Schema$Event> {
    const calendar = await getCalendarClient(userId)

    const response = await calendar.events.insert({
        calendarId: 'primary',
        requestBody: {
            summary: event.summary,
            description: event.description,
            location: event.location,
            start: {
                dateTime: event.startTime.toISOString(),
                timeZone: Intl.DateTimeFormat().resolvedOptions().timeZone,
            },
            end: {
                dateTime: event.endTime.toISOString(),
                timeZone: Intl.DateTimeFormat().resolvedOptions().timeZone,
            },
        },
    })

    return response.data
}

// Update an existing event
export async function updateEvent(
    userId: string,
    eventId: string,
    updates: {
        summary?: string
        description?: string
        startTime?: Date
        endTime?: Date
        location?: string
    }
): Promise<calendar_v3.Schema$Event> {
    const calendar = await getCalendarClient(userId)

    // First get the existing event
    const existing = await calendar.events.get({
        calendarId: 'primary',
        eventId: eventId,
    })

    const updatedEvent: calendar_v3.Schema$Event = {
        ...existing.data,
        summary: updates.summary ?? existing.data.summary,
        description: updates.description ?? existing.data.description,
        location: updates.location ?? existing.data.location,
    }

    if (updates.startTime) {
        updatedEvent.start = {
            dateTime: updates.startTime.toISOString(),
            timeZone: Intl.DateTimeFormat().resolvedOptions().timeZone,
        }
    }

    if (updates.endTime) {
        updatedEvent.end = {
            dateTime: updates.endTime.toISOString(),
            timeZone: Intl.DateTimeFormat().resolvedOptions().timeZone,
        }
    }

    const response = await calendar.events.update({
        calendarId: 'primary',
        eventId: eventId,
        requestBody: updatedEvent,
    })

    return response.data
}

// Delete an event
export async function deleteEvent(
    userId: string,
    eventId: string
): Promise<void> {
    const calendar = await getCalendarClient(userId)

    await calendar.events.delete({
        calendarId: 'primary',
        eventId: eventId,
    })
}

// Move an event to a new time
export async function moveEvent(
    userId: string,
    eventId: string,
    newStartTime: Date,
    newEndTime: Date
): Promise<calendar_v3.Schema$Event> {
    return updateEvent(userId, eventId, {
        startTime: newStartTime,
        endTime: newEndTime,
    })
}

// Find events by title/summary
export async function findEventsByTitle(
    userId: string,
    searchQuery: string,
    days: number = 30
): Promise<calendar_v3.Schema$Event[]> {
    const calendar = await getCalendarClient(userId)

    const now = new Date()
    const future = new Date()
    future.setDate(future.getDate() + days)

    const response = await calendar.events.list({
        calendarId: 'primary',
        timeMin: now.toISOString(),
        timeMax: future.toISOString(),
        q: searchQuery,
        maxResults: 20,
        singleEvents: true,
        orderBy: 'startTime',
    })

    return response.data.items || []
}

// Quick add event using natural language (Google's quick add feature)
export async function quickAddEvent(
    userId: string,
    text: string
): Promise<calendar_v3.Schema$Event> {
    const calendar = await getCalendarClient(userId)

    const response = await calendar.events.quickAdd({
        calendarId: 'primary',
        text: text, // e.g., "Meeting with John tomorrow at 3pm"
    })

    return response.data
}

// Get a single event by ID
export async function getEvent(
    userId: string,
    eventId: string
): Promise<calendar_v3.Schema$Event> {
    const calendar = await getCalendarClient(userId)

    const response = await calendar.events.get({
        calendarId: 'primary',
        eventId: eventId,
    })

    return response.data
}


// Parse natural language date from query
// Returns date offset from today (0 = today, 1 = tomorrow, -1 = yesterday, etc.)
export function parseDateFromQuery(text: string): { offset: number; label: string } | null {
    const lowercased = text.toLowerCase()
    const today = new Date()
    const currentDay = today.getDay() // 0 = Sunday, 1 = Monday, etc.

    // Map day names to day numbers
    const dayMap: { [key: string]: number } = {
        'sunday': 0, 'sun': 0,
        'monday': 1, 'mon': 1,
        'tuesday': 2, 'tue': 2, 'tues': 2,
        'wednesday': 3, 'wed': 3,
        'thursday': 4, 'thu': 4, 'thur': 4, 'thurs': 4,
        'friday': 5, 'fri': 5,
        'saturday': 6, 'sat': 6
    }

    // Check for "today"
    if (lowercased.includes('today')) {
        return { offset: 0, label: 'today' }
    }

    // Check for "tomorrow"
    if (lowercased.includes('tomorrow')) {
        return { offset: 1, label: 'tomorrow' }
    }

    // Check for "yesterday"
    if (lowercased.includes('yesterday')) {
        return { offset: -1, label: 'yesterday' }
    }

    // Check for "next [day]" or "this [day]"
    const nextDayMatch = lowercased.match(/(?:next|this)\s+(sunday|sun|monday|mon|tuesday|tue|tues|wednesday|wed|thursday|thu|thur|thurs|friday|fri|saturday|sat)/i)
    if (nextDayMatch) {
        const targetDay = dayMap[nextDayMatch[1].toLowerCase()]
        if (targetDay !== undefined) {
            let daysUntil = targetDay - currentDay
            if (daysUntil <= 0) daysUntil += 7 // Next week if today or before
            return { offset: daysUntil, label: `next ${nextDayMatch[1]}` }
        }
    }

    // Check for "last [day]"
    const lastDayMatch = lowercased.match(/last\s+(sunday|sun|monday|mon|tuesday|tue|tues|wednesday|wed|thursday|thu|thur|thurs|friday|fri|saturday|sat)/i)
    if (lastDayMatch) {
        const targetDay = dayMap[lastDayMatch[1].toLowerCase()]
        if (targetDay !== undefined) {
            let daysSince = currentDay - targetDay
            if (daysSince <= 0) daysSince += 7 // Previous week if today or after
            return { offset: -daysSince, label: `last ${lastDayMatch[1]}` }
        }
    }

    // Check for just a day name (assume upcoming)
    for (const [dayName, dayNum] of Object.entries(dayMap)) {
        if (lowercased.includes(dayName)) {
            let daysUntil = dayNum - currentDay
            if (daysUntil < 0) daysUntil += 7 // Next week if already passed
            if (daysUntil === 0) daysUntil = 7 // If today, assume next week
            return { offset: daysUntil, label: dayName }
        }
    }

    // Check for specific date patterns like "January 20" or "Jan 20"
    const monthMap: { [key: string]: number } = {
        'january': 0, 'jan': 0, 'february': 1, 'feb': 1, 'march': 2, 'mar': 2,
        'april': 3, 'apr': 3, 'may': 4, 'june': 5, 'jun': 5,
        'july': 6, 'jul': 6, 'august': 7, 'aug': 7, 'september': 8, 'sep': 8, 'sept': 8,
        'october': 9, 'oct': 9, 'november': 10, 'nov': 10, 'december': 11, 'dec': 11
    }

    const dateMatch = lowercased.match(/(january|jan|february|feb|march|mar|april|apr|may|june|jun|july|jul|august|aug|september|sep|sept|october|oct|november|nov|december|dec)\s+(\d{1,2})(?:st|nd|rd|th)?/i)
    if (dateMatch) {
        const month = monthMap[dateMatch[1].toLowerCase()]
        const day = parseInt(dateMatch[2])
        if (month !== undefined && day >= 1 && day <= 31) {
            const targetDate = new Date(today.getFullYear(), month, day)
            // If date is in the past, assume next year
            if (targetDate < today) {
                targetDate.setFullYear(targetDate.getFullYear() + 1)
            }
            const diffTime = targetDate.getTime() - new Date(today.getFullYear(), today.getMonth(), today.getDate()).getTime()
            const diffDays = Math.round(diffTime / (1000 * 60 * 60 * 24))
            return { offset: diffDays, label: `${dateMatch[1]} ${day}` }
        }
    }

    // Check for ordinal date patterns like "the 16th", "on the 20th" (day of current month)
    const ordinalMatch = lowercased.match(/(?:the\s+)?(\d{1,2})(?:st|nd|rd|th)\b/)
    if (ordinalMatch) {
        const day = parseInt(ordinalMatch[1])
        if (day >= 1 && day <= 31) {
            // Determine if it's this month or next month
            const currentMonth = today.getMonth()
            const currentDay = today.getDate()

            let targetMonth = currentMonth
            let targetYear = today.getFullYear()

            // If the day has already passed this month, assume next month
            if (day < currentDay) {
                targetMonth = currentMonth + 1
                if (targetMonth > 11) {
                    targetMonth = 0
                    targetYear++
                }
            }

            const targetDate = new Date(targetYear, targetMonth, day)
            const diffTime = targetDate.getTime() - new Date(today.getFullYear(), today.getMonth(), today.getDate()).getTime()
            const diffDays = Math.round(diffTime / (1000 * 60 * 60 * 24))

            const monthNames = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December']
            return { offset: diffDays, label: `${monthNames[targetMonth]} ${day}` }
        }
    }

    return null
}

// Check if a query is calendar-related
export function isCalendarQuery(text: string): boolean {
    const lowercased = text.toLowerCase()
    const keywords = [
        'calendar', 'schedule', 'meeting', 'event', 'agenda',
        'appointment', 'busy', 'free', 'available', 'book',
        'tomorrow', 'this week', 'next week', 'today', 'yesterday',
        'what do i have', 'what\'s coming up', 'upcoming',
        'remind me', 'set a reminder',
        'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday',
        'anything on', 'anything scheduled', 'plans for', 'plans on'
    ]

    // Check for ordinal date patterns like "the 16th", "on the 20th"
    const hasOrdinalDate = /\b(?:the\s+)?(\d{1,2})(?:st|nd|rd|th)\b/i.test(text)

    // Check for month + day patterns
    const hasMonthDay = /\b(january|jan|february|feb|march|mar|april|apr|may|june|jun|july|jul|august|aug|september|sep|october|oct|november|nov|december|dec)\s+\d{1,2}/i.test(text)

    return keywords.some(keyword => lowercased.includes(keyword)) || hasOrdinalDate || hasMonthDay
}

// Format events for AI context
export function formatEventsForContext(events: calendar_v3.Schema$Event[]): string {
    if (events.length === 0) {
        return 'No events found.'
    }

    return events.map(event => {
        const start = event.start?.dateTime || event.start?.date
        const startDate = start ? new Date(start) : null
        const timeStr = startDate
            ? startDate.toLocaleString('en-US', {
                weekday: 'short',
                month: 'short',
                day: 'numeric',
                hour: 'numeric',
                minute: '2-digit'
            })
            : 'Unknown time'

        let eventStr = `- ${event.summary || 'Untitled'} (${timeStr})`
        if (event.location) {
            eventStr += ` at ${event.location}`
        }
        return eventStr
    }).join('\n')
}

// Get event count for today
export async function getTodaysEventCount(userId: string): Promise<number> {
    const events = await getTodaysEvents(userId)
    return events.length
}
