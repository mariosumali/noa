import { createSupabaseServerClient } from '@/lib/supabase-server'
import IntegrationsSection from '@/components/dashboard/IntegrationsSection'

export default async function SettingsPage() {
  const supabase = await createSupabaseServerClient()
  const { data: { user } } = await supabase.auth.getUser()

  return (
    <div className="max-w-2xl mx-auto px-8 py-8">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-2xl font-semibold mb-1">Settings</h1>
        <p className="text-sm text-muted">
          Manage your account and preferences
        </p>
      </div>

      {/* Integrations Section */}
      <IntegrationsSection />

      {/* Account Section */}
      <section className="mb-8">
        <h2 className="text-xs font-medium text-muted tracking-wide mb-3">ACCOUNT</h2>
        <div className="bg-card border border-card rounded-xl overflow-hidden divide-y divide-card-border">
          <div className="px-5 py-4 flex items-center justify-between">
            <div>
              <p className="text-sm font-medium">Email</p>
              <p className="text-sm text-muted">{user?.email}</p>
            </div>
          </div>
          
          <div className="px-5 py-4 flex items-center justify-between">
            <div>
              <p className="text-sm font-medium">Account ID</p>
              <p className="text-xs text-muted font-mono">{user?.id}</p>
            </div>
          </div>
          
          <div className="px-5 py-4 flex items-center justify-between">
            <div>
              <p className="text-sm font-medium">Member since</p>
              <p className="text-sm text-muted">
                {user?.created_at ? new Date(user.created_at).toLocaleDateString('en-US', {
                  month: 'long',
                  day: 'numeric',
                  year: 'numeric'
                }) : 'Unknown'}
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Desktop App Section */}
      <section className="mb-8">
        <h2 className="text-xs font-medium text-muted tracking-wide mb-3">DESKTOP APP</h2>
        <div className="bg-card border border-card rounded-xl overflow-hidden divide-y divide-card-border">
          <div className="px-5 py-4">
            <div className="flex items-center justify-between mb-3">
              <div>
                <p className="text-sm font-medium">Download noa for Mac</p>
                <p className="text-sm text-muted">Voice assistant for your desktop</p>
              </div>
              <a 
                href="https://github.com/mariosumali/noa/releases" 
                target="_blank"
                className="text-sm font-medium px-4 py-2 bg-foreground text-background rounded-lg hover:opacity-90 transition-opacity"
              >
                Download
              </a>
            </div>
          </div>
          
          <div className="px-5 py-4">
            <p className="text-sm font-medium mb-1">Hotkey</p>
            <p className="text-sm text-muted">
              Hold <kbd className="px-1.5 py-0.5 bg-accent-light rounded text-xs font-mono">⌥ Option</kbd> to activate voice input
            </p>
          </div>
        </div>
      </section>

      {/* Danger Zone */}
      <section>
        <h2 className="text-xs font-medium text-muted tracking-wide mb-3">DANGER ZONE</h2>
        <div className="bg-card border border-red-200 rounded-xl overflow-hidden">
          <div className="px-5 py-4 flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-red-600">Delete Account</p>
              <p className="text-sm text-muted">Permanently delete your account and all data</p>
            </div>
            <button className="text-sm font-medium px-4 py-2 border border-red-300 text-red-600 rounded-lg hover:bg-red-50 transition-colors">
              Delete
            </button>
          </div>
        </div>
      </section>
    </div>
  )
}
