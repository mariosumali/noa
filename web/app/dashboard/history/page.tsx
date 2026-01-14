import { createSupabaseServerClient } from '@/lib/supabase-server'
import { formatDate } from '@/lib/utils'

export default async function HistoryPage() {
  const supabase = await createSupabaseServerClient()
  const { data: { user } } = await supabase.auth.getUser()

  const { data: prompts } = await supabase
    .from('prompts')
    .select('*')
    .eq('user_id', user?.id)
    .order('created_at', { ascending: false })
    .limit(50)

  return (
    <div className="max-w-4xl">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold mb-2">History</h1>
        <p className="text-muted">
          Your recent prompts and responses
        </p>
      </div>

      {/* Prompts list */}
      {prompts && prompts.length > 0 ? (
        <div className="space-y-4">
          {prompts.map((prompt) => (
            <div
              key={prompt.id}
              className="bg-card border border-card-border rounded-xl p-6"
            >
              {/* Prompt */}
              <div className="flex items-start gap-3 mb-4">
                <div className="w-8 h-8 bg-foreground/10 rounded-full flex items-center justify-center flex-shrink-0">
                  <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                  </svg>
                </div>
                <div className="flex-1">
                  <div className="flex items-center gap-2 mb-1">
                    <span className="font-medium text-sm">You</span>
                    <span className="text-xs text-muted">{formatDate(prompt.created_at)}</span>
                    {prompt.screenshot_url && (
                      <span className="text-xs bg-accent/10 text-accent px-2 py-0.5 rounded-full">
                        Screen capture
                      </span>
                    )}
                  </div>
                  <p className="text-foreground">{prompt.text}</p>
                </div>
              </div>

              {/* Response */}
              {prompt.response && (
                <div className="flex items-start gap-3 pl-11">
                  <div className="w-8 h-8 bg-accent/10 rounded-full flex items-center justify-center flex-shrink-0">
                    <span className="text-accent font-bold text-xs">n</span>
                  </div>
                  <div className="flex-1">
                    <div className="flex items-center gap-2 mb-1">
                      <span className="font-medium text-sm text-accent">noa</span>
                    </div>
                    <p className="text-muted">{prompt.response}</p>
                  </div>
                </div>
              )}
            </div>
          ))}
        </div>
      ) : (
        <div className="bg-card border border-card-border rounded-xl p-12 text-center">
          <div className="w-16 h-16 bg-card-border rounded-full flex items-center justify-center mx-auto mb-4">
            <svg className="w-8 h-8 text-muted" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
            </svg>
          </div>
          <h3 className="font-semibold text-lg mb-2">No prompts yet</h3>
          <p className="text-muted mb-6">
            Start using noa to see your conversation history here
          </p>
        </div>
      )}
    </div>
  )
}
