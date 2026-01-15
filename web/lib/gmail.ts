import { google } from 'googleapis'
import { createServerSupabaseClient } from './supabase'

const SCOPES = ['https://www.googleapis.com/auth/gmail.readonly']

// Create OAuth2 client
export function createOAuth2Client() {
  return new google.auth.OAuth2(
    process.env.GOOGLE_CLIENT_ID,
    process.env.GOOGLE_CLIENT_SECRET,
    `${process.env.NEXT_PUBLIC_APP_URL || 'http://localhost:3000'}/api/auth/google/callback`
  )
}

// Generate authorization URL
export function getAuthUrl(state: string) {
  const oauth2Client = createOAuth2Client()
  return oauth2Client.generateAuthUrl({
    access_type: 'offline',
    scope: SCOPES,
    state,
    prompt: 'consent', // Force to get refresh token
  })
}

// Exchange code for tokens
export async function getTokensFromCode(code: string) {
  const oauth2Client = createOAuth2Client()
  const { tokens } = await oauth2Client.getToken(code)
  return tokens
}

// Get Gmail client for a user
export async function getGmailClient(userId: string) {
  const supabase = createServerSupabaseClient()
  
  // Get stored tokens
  const { data: integration, error } = await supabase
    .from('user_integrations')
    .select('*')
    .eq('user_id', userId)
    .eq('provider', 'gmail')
    .single()

  if (error || !integration) {
    throw new Error('Gmail not connected')
  }

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
      
      // Update stored tokens
      await supabase
        .from('user_integrations')
        .update({
          access_token: credentials.access_token,
          token_expires_at: new Date(credentials.expiry_date || Date.now() + 3600000).toISOString(),
          updated_at: new Date().toISOString(),
        })
        .eq('id', integration.id)

      oauth2Client.setCredentials(credentials)
    } catch (refreshError) {
      console.error('Failed to refresh token:', refreshError)
      throw new Error('Gmail token expired. Please reconnect.')
    }
  }

  return google.gmail({ version: 'v1', auth: oauth2Client })
}

// Email interface
export interface Email {
  id: string
  threadId: string
  from: string
  to: string
  subject: string
  snippet: string
  date: Date
  isUnread: boolean
  labels: string[]
}

// Parse email headers
function parseHeaders(headers: { name: string; value: string }[]) {
  const result: Record<string, string> = {}
  for (const header of headers) {
    result[header.name.toLowerCase()] = header.value
  }
  return result
}

// Get unread email count
export async function getUnreadCount(userId: string): Promise<number> {
  const gmail = await getGmailClient(userId)
  
  const response = await gmail.users.messages.list({
    userId: 'me',
    q: 'is:unread',
    maxResults: 1,
  })

  return response.data.resultSizeEstimate || 0
}

// Get unread emails
export async function getUnreadEmails(userId: string, limit = 10): Promise<Email[]> {
  const gmail = await getGmailClient(userId)
  
  const listResponse = await gmail.users.messages.list({
    userId: 'me',
    q: 'is:unread',
    maxResults: limit,
  })

  if (!listResponse.data.messages) {
    return []
  }

  const emails: Email[] = []
  
  for (const msg of listResponse.data.messages.slice(0, limit)) {
    const detail = await gmail.users.messages.get({
      userId: 'me',
      id: msg.id!,
      format: 'metadata',
      metadataHeaders: ['From', 'To', 'Subject', 'Date'],
    })

    const headers = parseHeaders(detail.data.payload?.headers || [])
    
    emails.push({
      id: msg.id!,
      threadId: msg.threadId!,
      from: headers['from'] || 'Unknown',
      to: headers['to'] || '',
      subject: headers['subject'] || '(no subject)',
      snippet: detail.data.snippet || '',
      date: new Date(headers['date'] || Date.now()),
      isUnread: detail.data.labelIds?.includes('UNREAD') || false,
      labels: detail.data.labelIds || [],
    })
  }

  return emails
}

// Search emails
export async function searchEmails(userId: string, query: string, limit = 10): Promise<Email[]> {
  const gmail = await getGmailClient(userId)
  
  const listResponse = await gmail.users.messages.list({
    userId: 'me',
    q: query,
    maxResults: limit,
  })

  if (!listResponse.data.messages) {
    return []
  }

  const emails: Email[] = []
  
  for (const msg of listResponse.data.messages.slice(0, limit)) {
    const detail = await gmail.users.messages.get({
      userId: 'me',
      id: msg.id!,
      format: 'metadata',
      metadataHeaders: ['From', 'To', 'Subject', 'Date'],
    })

    const headers = parseHeaders(detail.data.payload?.headers || [])
    
    emails.push({
      id: msg.id!,
      threadId: msg.threadId!,
      from: headers['from'] || 'Unknown',
      to: headers['to'] || '',
      subject: headers['subject'] || '(no subject)',
      snippet: detail.data.snippet || '',
      date: new Date(headers['date'] || Date.now()),
      isUnread: detail.data.labelIds?.includes('UNREAD') || false,
      labels: detail.data.labelIds || [],
    })
  }

  return emails
}

// Get emails from a specific sender
export async function getEmailsFrom(userId: string, sender: string, limit = 10): Promise<Email[]> {
  return searchEmails(userId, `from:${sender}`, limit)
}

// Get important/starred emails
export async function getImportantEmails(userId: string, limit = 10): Promise<Email[]> {
  return searchEmails(userId, 'is:important OR is:starred', limit)
}

// Format emails for AI context
export function formatEmailsForContext(emails: Email[]): string {
  if (emails.length === 0) {
    return 'No emails found.'
  }

  return emails.map((email, i) => {
    const dateStr = email.date.toLocaleDateString('en-US', { 
      month: 'short', 
      day: 'numeric',
      hour: 'numeric',
      minute: '2-digit'
    })
    return `${i + 1}. From: ${email.from}\n   Subject: ${email.subject}\n   Date: ${dateStr}\n   Preview: ${email.snippet.slice(0, 100)}...`
  }).join('\n\n')
}

// Check if a query is Gmail-related
export function isGmailQuery(text: string): boolean {
  const keywords = [
    'email', 'emails', 'gmail', 'inbox', 'unread',
    'message from', 'mail from', 'email from',
    'important email', 'priority mail',
    'check my email', 'check my mail',
    'summarize email', 'email summary',
    'any new email', 'new messages',
    'who emailed', 'who sent',
  ]
  
  const lowercased = text.toLowerCase()
  return keywords.some(keyword => lowercased.includes(keyword))
}

// Extract sender name from query
export function extractSenderFromQuery(text: string): string | null {
  const patterns = [
    /(?:email|emails|message|messages|mail) from (\w+(?:\s+\w+)?)/i,
    /(?:from|by) (\w+(?:\s+\w+)?)/i,
    /(\w+(?:\s+\w+)?) (?:email|sent|wrote)/i,
  ]
  
  for (const pattern of patterns) {
    const match = text.match(pattern)
    if (match) {
      return match[1].trim()
    }
  }
  
  return null
}
