'use client'

import { useState, useEffect } from 'react'
import { useSearchParams, useRouter } from 'next/navigation'

interface GmailStatus {
  connected: boolean
  email?: string
  connectedAt?: string
}

export default function IntegrationsSection() {
  const [gmailStatus, setGmailStatus] = useState<GmailStatus | null>(null)
  const [loading, setLoading] = useState(true)
  const [disconnecting, setDisconnecting] = useState(false)

  const searchParams = useSearchParams()
  const router = useRouter()

  useEffect(() => {
    fetchGmailStatus()

    // Check for success param from redirect
    if (searchParams.get('gmail') === 'connected') {
      // Clear the param without refreshing
      router.replace('/dashboard/settings')
    }
  }, [searchParams, router])

  async function fetchGmailStatus() {
    try {
      const res = await fetch('/api/integrations/gmail/status')
      const data = await res.json()
      setGmailStatus(data)
    } catch (error) {
      console.error('Failed to fetch Gmail status:', error)
      setGmailStatus({ connected: false })
    } finally {
      setLoading(false)
    }
  }

  async function disconnectGmail() {
    if (!confirm('Are you sure you want to disconnect Gmail?')) return

    setDisconnecting(true)
    try {
      await fetch('/api/integrations/gmail/status', { method: 'DELETE' })
      setGmailStatus({ connected: false })
    } catch (error) {
      console.error('Failed to disconnect Gmail:', error)
    } finally {
      setDisconnecting(false)
    }
  }

  return (
    <section className="mb-8">
      <h2 className="text-xs font-medium text-muted tracking-wide mb-3">INTEGRATIONS</h2>
      <div className="bg-card border border-card rounded-xl overflow-hidden divide-y divide-card-border">
        {/* Gmail */}
        <div className="px-5 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-red-100 rounded-lg flex items-center justify-center">
                <svg className="w-6 h-6 text-red-600" viewBox="0 0 24 24" fill="currentColor">
                  <path d="M24 5.457v13.909c0 .904-.732 1.636-1.636 1.636h-3.819V11.73L12 16.64l-6.545-4.91v9.273H1.636A1.636 1.636 0 0 1 0 19.366V5.457c0-2.023 2.309-3.178 3.927-1.964L5.455 4.64 12 9.548l6.545-4.91 1.528-1.145C21.69 2.28 24 3.434 24 5.457z" />
                </svg>
              </div>
              <div>
                <p className="text-sm font-medium">Gmail</p>
                {loading ? (
                  <p className="text-sm text-muted">Checking connection...</p>
                ) : gmailStatus?.connected ? (
                  <div className="flex items-center gap-1.5 text-green-600">
                    <svg className="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                      <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
                    </svg>
                    <p className="text-sm font-medium">
                      Connected as {gmailStatus.email}
                    </p>
                  </div>
                ) : (
                  <p className="text-sm text-muted">
                    Ask noa about your emails
                  </p>
                )}
              </div>
            </div>

            {!loading && (
              gmailStatus?.connected ? (
                <button
                  onClick={disconnectGmail}
                  disabled={disconnecting}
                  className="text-sm font-medium px-4 py-2 border border-card-border text-muted rounded-lg hover:bg-hover transition-colors disabled:opacity-50"
                >
                  {disconnecting ? 'Disconnecting...' : 'Disconnect'}
                </button>
              ) : (
                <a
                  href="/api/integrations/gmail/connect"
                  className="text-sm font-medium px-4 py-2 bg-foreground text-background rounded-lg hover:opacity-90 transition-opacity"
                >
                  Connect
                </a>
              )
            )}
          </div>

          {gmailStatus?.connected && (
            <div className="mt-3 pt-3 border-t border-card-border">
              <p className="text-xs text-muted">
                Try asking: "Do I have any unread emails?" or "Any emails from John?"
              </p>
            </div>
          )}
        </div>

        {/* Google Calendar - Shared with Gmail OAuth */}
        <div className="px-5 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center">
                <svg className="w-6 h-6 text-blue-600" viewBox="0 0 24 24" fill="currentColor">
                  <path d="M19.5 3h-15A1.5 1.5 0 003 4.5v15A1.5 1.5 0 004.5 21h15a1.5 1.5 0 001.5-1.5v-15A1.5 1.5 0 0019.5 3zM8 17H6v-2h2v2zm0-4H6v-2h2v2zm0-4H6V7h2v2zm4 8h-2v-2h2v2zm0-4h-2v-2h2v2zm0-4h-2V7h2v2zm4 8h-2v-2h2v2zm0-4h-2v-2h2v2zm0-4h-2V7h2v2zm3 0h-2V7h2v2z" />
                </svg>
              </div>
              <div>
                <p className="text-sm font-medium">Google Calendar</p>
                {loading ? (
                  <p className="text-sm text-muted">Checking connection...</p>
                ) : gmailStatus?.connected ? (
                  <div className="flex items-center gap-1.5 text-green-600">
                    <svg className="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                      <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
                    </svg>
                    <p className="text-sm font-medium">
                      Connected via Google
                    </p>
                  </div>
                ) : (
                  <p className="text-sm text-muted">
                    Ask noa about your schedule
                  </p>
                )}
              </div>
            </div>

            {!loading && !gmailStatus?.connected && (
              <a
                href="/api/integrations/gmail/connect"
                className="text-sm font-medium px-4 py-2 bg-foreground text-background rounded-lg hover:opacity-90 transition-opacity"
              >
                Connect
              </a>
            )}
          </div>

          {gmailStatus?.connected && (
            <div className="mt-3 pt-3 border-t border-card-border">
              <p className="text-xs text-muted">
                Try asking: "What's on my calendar today?" or "Any upcoming meetings?"
              </p>
            </div>
          )}
        </div>

        {/* Slack - Coming Soon */}
        <div className="px-5 py-4 opacity-60">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-purple-100 rounded-lg flex items-center justify-center">
                <svg className="w-6 h-6 text-purple-600" viewBox="0 0 24 24" fill="currentColor">
                  <path d="M5.042 15.165a2.528 2.528 0 0 1-2.52 2.523A2.528 2.528 0 0 1 0 15.165a2.527 2.527 0 0 1 2.522-2.52h2.52v2.52zM6.313 15.165a2.527 2.527 0 0 1 2.521-2.52 2.527 2.527 0 0 1 2.521 2.52v6.313A2.528 2.528 0 0 1 8.834 24a2.528 2.528 0 0 1-2.521-2.522v-6.313zM8.834 5.042a2.528 2.528 0 0 1-2.521-2.52A2.528 2.528 0 0 1 8.834 0a2.528 2.528 0 0 1 2.521 2.522v2.52H8.834zM8.834 6.313a2.528 2.528 0 0 1 2.521 2.521 2.528 2.528 0 0 1-2.521 2.521H2.522A2.528 2.528 0 0 1 0 8.834a2.528 2.528 0 0 1 2.522-2.521h6.312zM18.956 8.834a2.528 2.528 0 0 1 2.522-2.521A2.528 2.528 0 0 1 24 8.834a2.528 2.528 0 0 1-2.522 2.521h-2.522V8.834zM17.688 8.834a2.528 2.528 0 0 1-2.523 2.521 2.527 2.527 0 0 1-2.52-2.521V2.522A2.527 2.527 0 0 1 15.165 0a2.528 2.528 0 0 1 2.523 2.522v6.312zM15.165 18.956a2.528 2.528 0 0 1 2.523 2.522A2.528 2.528 0 0 1 15.165 24a2.527 2.527 0 0 1-2.52-2.522v-2.522h2.52zM15.165 17.688a2.527 2.527 0 0 1-2.52-2.523 2.526 2.526 0 0 1 2.52-2.52h6.313A2.527 2.527 0 0 1 24 15.165a2.528 2.528 0 0 1-2.522 2.523h-6.313z" />
                </svg>
              </div>
              <div>
                <p className="text-sm font-medium">Slack</p>
                <p className="text-sm text-muted">Coming soon</p>
              </div>
            </div>
            <span className="text-xs font-medium px-3 py-1 bg-accent-light text-muted rounded-full">
              Soon
            </span>
          </div>
        </div>
      </div>
    </section>
  )
}
