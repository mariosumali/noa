import { createSupabaseServerClient } from '@/lib/supabase-server'

export default async function SettingsPage() {
  const supabase = await createSupabaseServerClient()
  const { data: { user } } = await supabase.auth.getUser()

  return (
    <div className="max-w-2xl">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold mb-2">Settings</h1>
        <p className="text-muted">
          Manage your account and preferences
        </p>
      </div>

      {/* Account section */}
      <div className="bg-card border border-card-border rounded-xl p-6 mb-6">
        <h2 className="font-semibold text-lg mb-4">Account</h2>
        
        <div className="space-y-4">
          <div>
            <label className="block text-sm text-muted mb-1">Email</label>
            <p className="font-medium">{user?.email}</p>
          </div>
          
          <div>
            <label className="block text-sm text-muted mb-1">Account ID</label>
            <p className="font-mono text-sm text-muted">{user?.id}</p>
          </div>

          <div>
            <label className="block text-sm text-muted mb-1">Created</label>
            <p className="text-sm">
              {user?.created_at 
                ? new Date(user.created_at).toLocaleDateString('en-US', {
                    year: 'numeric',
                    month: 'long',
                    day: 'numeric'
                  })
                : 'Unknown'}
            </p>
          </div>
        </div>
      </div>

      {/* Integrations section */}
      <div className="bg-card border border-card-border rounded-xl p-6 mb-6">
        <h2 className="font-semibold text-lg mb-4">Integrations</h2>
        <p className="text-muted text-sm mb-4">
          Connect your services to unlock more features
        </p>

        <div className="space-y-3">
          {[
            { name: 'Google Calendar', icon: '📅', status: 'coming_soon' },
            { name: 'Gmail', icon: '📧', status: 'coming_soon' },
            { name: 'Slack', icon: '💬', status: 'coming_soon' },
            { name: 'Google Drive', icon: '📁', status: 'coming_soon' },
          ].map((integration) => (
            <div
              key={integration.name}
              className="flex items-center justify-between p-3 bg-background rounded-lg border border-card-border"
            >
              <div className="flex items-center gap-3">
                <span className="text-xl">{integration.icon}</span>
                <span className="font-medium">{integration.name}</span>
              </div>
              <span className="text-xs bg-card-border text-muted px-2 py-1 rounded-full">
                Coming soon
              </span>
            </div>
          ))}
        </div>
      </div>

      {/* Desktop app section */}
      <div className="bg-card border border-card-border rounded-xl p-6">
        <h2 className="font-semibold text-lg mb-4">Desktop App</h2>
        <p className="text-muted text-sm mb-4">
          Download the macOS app to use voice commands
        </p>

        <button
          disabled
          className="inline-flex items-center gap-2 bg-foreground/10 text-muted px-4 py-2 rounded-lg cursor-not-allowed"
        >
          <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
            <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/>
          </svg>
          Download for macOS
          <span className="text-xs bg-card-border px-2 py-0.5 rounded-full ml-2">Soon</span>
        </button>
      </div>
    </div>
  )
}
