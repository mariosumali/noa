import { createSupabaseServerClient } from '@/lib/supabase-server'

export default async function DashboardPage() {
  const supabase = await createSupabaseServerClient()
  const { data: { user } } = await supabase.auth.getUser()

  // Get recent prompts count
  const { count: promptCount } = await supabase
    .from('prompts')
    .select('*', { count: 'exact', head: true })
    .eq('user_id', user?.id)

  // Get prompts from today
  const today = new Date()
  today.setHours(0, 0, 0, 0)
  
  const { count: todayCount } = await supabase
    .from('prompts')
    .select('*', { count: 'exact', head: true })
    .eq('user_id', user?.id)
    .gte('created_at', today.toISOString())

  return (
    <div className="max-w-4xl">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold mb-2">Welcome back</h1>
        <p className="text-muted">
          {user?.email}
        </p>
      </div>

      {/* Stats */}
      <div className="grid md:grid-cols-3 gap-6 mb-8">
        <div className="bg-card border border-card-border rounded-xl p-6">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 bg-accent/10 rounded-lg flex items-center justify-center">
              <svg className="w-6 h-6 text-accent" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
              </svg>
            </div>
            <div>
              <p className="text-2xl font-bold">{promptCount || 0}</p>
              <p className="text-sm text-muted">Total prompts</p>
            </div>
          </div>
        </div>

        <div className="bg-card border border-card-border rounded-xl p-6">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 bg-green-500/10 rounded-lg flex items-center justify-center">
              <svg className="w-6 h-6 text-green-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
            <div>
              <p className="text-2xl font-bold">{todayCount || 0}</p>
              <p className="text-sm text-muted">Today</p>
            </div>
          </div>
        </div>

        <div className="bg-card border border-card-border rounded-xl p-6">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 bg-blue-500/10 rounded-lg flex items-center justify-center">
              <svg className="w-6 h-6 text-blue-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M13 10V3L4 14h7v7l9-11h-7z" />
              </svg>
            </div>
            <div>
              <p className="text-2xl font-bold">Active</p>
              <p className="text-sm text-muted">Status</p>
            </div>
          </div>
        </div>
      </div>

      {/* Quick start */}
      <div className="bg-card border border-card-border rounded-xl p-6">
        <h2 className="font-semibold text-lg mb-4">Get started with noa</h2>
        <div className="space-y-4">
          <div className="flex items-start gap-4">
            <div className="w-8 h-8 bg-accent/10 rounded-full flex items-center justify-center flex-shrink-0 mt-0.5">
              <span className="text-accent font-semibold text-sm">1</span>
            </div>
            <div>
              <p className="font-medium">Download the desktop app</p>
              <p className="text-sm text-muted">Get the macOS app to use voice commands</p>
            </div>
          </div>
          <div className="flex items-start gap-4">
            <div className="w-8 h-8 bg-accent/10 rounded-full flex items-center justify-center flex-shrink-0 mt-0.5">
              <span className="text-accent font-semibold text-sm">2</span>
            </div>
            <div>
              <p className="font-medium">Hold the function key and speak</p>
              <p className="text-sm text-muted">Ask anything: &quot;What&apos;s on my screen?&quot;</p>
            </div>
          </div>
          <div className="flex items-start gap-4">
            <div className="w-8 h-8 bg-accent/10 rounded-full flex items-center justify-center flex-shrink-0 mt-0.5">
              <span className="text-accent font-semibold text-sm">3</span>
            </div>
            <div>
              <p className="font-medium">View your history here</p>
              <p className="text-sm text-muted">All your prompts and responses are saved</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
