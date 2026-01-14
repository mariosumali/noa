import Link from 'next/link'

export function Footer() {
  return (
    <footer className="border-t border-card-border py-12">
      <div className="max-w-6xl mx-auto px-6">
        <div className="flex flex-col md:flex-row items-center justify-between gap-6">
          {/* Logo */}
          <div className="flex items-center gap-2">
            <div className="w-6 h-6 rounded-full bg-gradient-to-br from-accent to-accent-light flex items-center justify-center">
              <span className="text-background font-bold text-xs">n</span>
            </div>
            <span className="font-medium">noa</span>
          </div>

          {/* Links */}
          <div className="flex items-center gap-6 text-sm text-muted">
            <Link href="/login" className="hover:text-foreground transition-colors">
              Log in
            </Link>
            <Link href="/signup" className="hover:text-foreground transition-colors">
              Sign up
            </Link>
          </div>

          {/* Copyright */}
          <p className="text-sm text-muted">
            Created by Mario Sumali
          </p>
        </div>
      </div>
    </footer>
  )
}
