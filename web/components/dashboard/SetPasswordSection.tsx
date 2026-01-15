'use client'

import { useState } from 'react'

export default function SetPasswordSection() {
    const [password, setPassword] = useState('')
    const [confirmPassword, setConfirmPassword] = useState('')
    const [loading, setLoading] = useState(false)
    const [error, setError] = useState<string | null>(null)
    const [success, setSuccess] = useState(false)

    async function handleSubmit(e: React.FormEvent) {
        e.preventDefault()
        setError(null)
        setSuccess(false)

        if (password.length < 6) {
            setError('Password must be at least 6 characters')
            return
        }

        if (password !== confirmPassword) {
            setError('Passwords do not match')
            return
        }

        setLoading(true)
        try {
            const res = await fetch('/api/auth/set-password', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ password })
            })

            const data = await res.json()

            if (!res.ok) {
                throw new Error(data.error || 'Failed to set password')
            }

            setSuccess(true)
            setPassword('')
            setConfirmPassword('')
        } catch (err) {
            setError(err instanceof Error ? err.message : 'Failed to set password')
        } finally {
            setLoading(false)
        }
    }

    return (
        <section className="mb-8">
            <h2 className="text-xs font-medium text-muted tracking-wide mb-3">DESKTOP APP LOGIN</h2>
            <div className="bg-card border border-card rounded-xl overflow-hidden">
                <div className="px-5 py-4">
                    <p className="text-sm font-medium mb-1">Set Password for Desktop App</p>
                    <p className="text-sm text-muted mb-4">
                        Create a password to log in from the noa desktop app
                    </p>

                    <form onSubmit={handleSubmit} className="space-y-3">
                        <div>
                            <input
                                type="password"
                                placeholder="New password (min 6 characters)"
                                value={password}
                                onChange={(e) => setPassword(e.target.value)}
                                className="w-full px-3 py-2 text-sm bg-background border border-card-border rounded-lg focus:outline-none focus:ring-2 focus:ring-accent"
                            />
                        </div>
                        <div>
                            <input
                                type="password"
                                placeholder="Confirm password"
                                value={confirmPassword}
                                onChange={(e) => setConfirmPassword(e.target.value)}
                                className="w-full px-3 py-2 text-sm bg-background border border-card-border rounded-lg focus:outline-none focus:ring-2 focus:ring-accent"
                            />
                        </div>

                        {error && (
                            <p className="text-sm text-red-500">{error}</p>
                        )}

                        {success && (
                            <p className="text-sm text-green-600">
                                ✓ Password set! You can now log in from the desktop app.
                            </p>
                        )}

                        <button
                            type="submit"
                            disabled={loading || !password || !confirmPassword}
                            className="text-sm font-medium px-4 py-2 bg-foreground text-background rounded-lg hover:opacity-90 transition-opacity disabled:opacity-50"
                        >
                            {loading ? 'Saving...' : 'Set Password'}
                        </button>
                    </form>
                </div>
            </div>
        </section>
    )
}
