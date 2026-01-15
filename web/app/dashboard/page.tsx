import { createSupabaseServerClient } from '@/lib/supabase-server'
import { createServerSupabaseClient } from '@/lib/supabase'

function formatTime(dateString: string) {
  const date = new Date(dateString)
  return date.toLocaleTimeString('en-US', {
    hour: '2-digit',
    minute: '2-digit',
    hour12: true
  })
}

function formatDateHeader(dateString: string) {
  const date = new Date(dateString)
  const today = new Date()
  const yesterday = new Date(today)
  yesterday.setDate(yesterday.getDate() - 1)

  if (date.toDateString() === today.toDateString()) {
    return 'TODAY'
  } else if (date.toDateString() === yesterday.toDateString()) {
    return 'YESTERDAY'
  } else {
    return date.toLocaleDateString('en-US', {
      month: 'long',
      day: 'numeric',
      year: 'numeric'
    }).toUpperCase()
  }
}

function groupPromptsByDate(prompts: any[]) {
  const groups: { [key: string]: any[] } = {}

  prompts.forEach(prompt => {
    const dateKey = new Date(prompt.created_at).toDateString()
    if (!groups[dateKey]) {
      groups[dateKey] = []
    }
    groups[dateKey].push(prompt)
  })

  return Object.entries(groups).map(([dateKey, prompts]) => ({
    dateKey,
    label: formatDateHeader(prompts[0].created_at),
    prompts
  }))
}

export default async function DashboardPage() {
  const supabaseAuth = await createSupabaseServerClient()
  const supabaseAdmin = createServerSupabaseClient()

  const { data: { user } } = await supabaseAuth.auth.getUser()
  const firstName = user?.email?.split('@')[0] || 'there'

  // Fetch prompts
  const { data: allPrompts } = await supabaseAdmin
    .from('prompts')
    .select('*')
    .order('created_at', { ascending: false })
    .limit(100)

  const prompts = allPrompts || []
  const groupedPrompts = groupPromptsByDate(prompts)

  // Stats
  const totalPrompts = prompts.length
  const todayPrompts = prompts.filter(p =>
    new Date(p.created_at).toDateString() === new Date().toDateString()
  ).length

  return (
    <div className="max-w-4xl mx-auto px-8 py-8">
      {/* Header */}
      <div className="flex items-center justify-between mb-8">
        <h1 className="text-2xl font-semibold">
          Welcome back, {firstName.charAt(0).toUpperCase() + firstName.slice(1)}
        </h1>

        <div className="flex items-center gap-4 text-sm text-muted">
          <div className="flex items-center gap-1.5">
            <span>🔥</span>
            <span>{todayPrompts} today</span>
          </div>
          <div className="flex items-center gap-1.5">
            <span>💬</span>
            <span>{totalPrompts} total</span>
          </div>
        </div>
      </div>

      {/* Prompt History */}
      {groupedPrompts.length > 0 ? (
        <div className="space-y-8">
          {groupedPrompts.map((group) => (
            <div key={group.dateKey}>
              <h2 className="text-xs font-medium text-muted tracking-wide mb-3">
                {group.label}
              </h2>

              <div className="bg-card border border-card rounded-xl overflow-hidden divide-y divide-card-border">
                {group.prompts.map((prompt: any) => (
                  <div key={prompt.id} className="flex gap-6 px-5 py-4 hover:bg-hover transition-colors">
                    <span className="text-sm text-muted w-20 flex-shrink-0">
                      {formatTime(prompt.created_at)}
                    </span>
                    <div className="flex-1 min-w-0">
                      <p className="text-sm text-foreground">
                        {prompt.text}
                      </p>
                      {prompt.response && (
                        <p className="text-sm text-muted mt-2 pl-4 border-l-2 border-card-border">
                          {prompt.response}
                        </p>
                      )}
                      <div className="flex items-center gap-2 mt-2">
                        {prompt.tools_used && prompt.tools_used.length > 0 && (
                          prompt.tools_used.map((tool: string) => (
                            <span
                              key={tool}
                              className={`text-xs px-2 py-0.5 rounded-full ${tool.startsWith('calendar')
                                ? 'bg-blue-500/10 text-blue-400'
                                : tool.startsWith('gmail')
                                  ? 'bg-red-500/10 text-red-400'
                                  : (tool === 'transcription_log' || tool === 'transcription')
                                    ? 'bg-purple-500/10 text-purple-400'
                                    : 'bg-gray-500/10 text-gray-400'
                                }`}
                            >
                              {tool === 'calendar_create' && '📅 Created'}
                              {tool === 'calendar_delete' && '📅 Deleted'}
                              {tool === 'calendar_query' && '📅 Calendar'}
                              {tool === 'gmail_query' && '📧 Email'}
                              {(tool === 'transcription_log' || tool === 'transcription') && '📝 Transcription'}
                            </span>
                          ))
                        )}
                      </div>
                    </div>
                    {prompt.screenshot_url && (
                      <span className="text-muted text-sm" title="Screen capture included">
                        📷
                      </span>
                    )}
                  </div>
                ))}
              </div>
            </div>
          ))}
        </div>
      ) : (
        <div className="bg-card border border-card rounded-xl p-12 text-center">
          <div className="w-16 h-16 bg-accent-light rounded-full flex items-center justify-center mx-auto mb-4">
            <svg className="w-8 h-8 text-muted" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
            </svg>
          </div>
          <h3 className="font-medium text-lg mb-2">No prompts yet</h3>
          <p className="text-muted text-sm mb-4">
            Start using noa on your Mac to see your history here
          </p>
          <p className="text-xs text-muted">
            Hold <kbd className="px-1.5 py-0.5 bg-accent-light rounded text-xs font-mono">⌥ Option</kbd> to speak
          </p>
        </div>
      )}
    </div>
  )
}
