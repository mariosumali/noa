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

export default async function HistoryPage() {
  const supabaseAuth = await createSupabaseServerClient()
  const supabaseAdmin = createServerSupabaseClient()
  
  const { data: { user } } = await supabaseAuth.auth.getUser()

  // Fetch all prompts
  const { data: allPrompts } = await supabaseAdmin
    .from('prompts')
    .select('*')
    .order('created_at', { ascending: false })
    .limit(200)

  const prompts = allPrompts || []
  const groupedPrompts = groupPromptsByDate(prompts)

  return (
    <div className="max-w-4xl mx-auto px-8 py-8">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-2xl font-semibold mb-1">History</h1>
        <p className="text-sm text-muted">
          All your prompts and responses
        </p>
      </div>

      {/* Search (placeholder) */}
      <div className="mb-6">
        <div className="relative">
          <svg className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
          </svg>
          <input 
            type="text" 
            placeholder="Search prompts..." 
            className="w-full pl-10 pr-4 py-2.5 bg-card border border-card-border rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-foreground/10"
          />
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
                  <div key={prompt.id} className="px-5 py-4 hover:bg-hover transition-colors">
                    <div className="flex gap-6">
                      <span className="text-sm text-muted w-20 flex-shrink-0">
                        {formatTime(prompt.created_at)}
                      </span>
                      <div className="flex-1 min-w-0">
                        <p className="text-sm text-foreground">
                          {prompt.text}
                        </p>
                      </div>
                      <div className="flex items-center gap-2 flex-shrink-0">
                        {prompt.screenshot_url && (
                          <span className="text-muted text-sm" title="Screen capture included">
                            📷
                          </span>
                        )}
                        {prompt.device_id && !prompt.user_id && (
                          <span className="text-xs bg-accent-light text-muted px-2 py-0.5 rounded-full">
                            Desktop
                          </span>
                        )}
                      </div>
                    </div>
                    
                    {prompt.response && (
                      <div className="mt-3 ml-26 pl-4 border-l-2 border-card-border">
                        <p className="text-sm text-muted">
                          {prompt.response}
                        </p>
                      </div>
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
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M12 6v6h4.5m4.5 0a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
          <h3 className="font-medium text-lg mb-2">No history yet</h3>
          <p className="text-muted text-sm">
            Your prompts will appear here
          </p>
        </div>
      )}
    </div>
  )
}
