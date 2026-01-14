import Link from 'next/link'

export function Hero() {
  return (
    <section className="relative min-h-screen flex items-center justify-center overflow-hidden">
      {/* Background gradient */}
      <div className="absolute inset-0 bg-gradient-to-b from-accent/5 via-transparent to-transparent" />
      
      {/* Animated background orbs */}
      <div className="absolute top-1/4 left-1/4 w-96 h-96 bg-accent/10 rounded-full blur-3xl animate-pulse-glow" />
      <div className="absolute bottom-1/4 right-1/4 w-80 h-80 bg-accent-light/10 rounded-full blur-3xl animate-pulse-glow animation-delay-400" />

      <div className="relative z-10 max-w-4xl mx-auto px-6 text-center">
        {/* Badge */}
        <div className="inline-flex items-center gap-2 bg-card border border-card-border rounded-full px-4 py-1.5 mb-8 animate-fade-in">
          <span className="w-2 h-2 bg-accent rounded-full animate-pulse" />
          <span className="text-sm text-muted">Voice-first AI assistant</span>
        </div>

        {/* Headline */}
        <h1 className="text-5xl md:text-7xl font-bold tracking-tight mb-6 animate-fade-in animation-delay-200">
          Your digital life,
          <br />
          <span className="text-transparent bg-clip-text bg-gradient-to-r from-accent to-accent-light">
            one voice away
          </span>
        </h1>

        {/* Subheadline */}
        <p className="text-lg md:text-xl text-muted max-w-2xl mx-auto mb-10 animate-fade-in animation-delay-400">
          noa connects to your calendar, email, files, and more. 
          Just hold a key and ask. Get answers instantly.
        </p>

        {/* CTA Buttons */}
        <div className="flex flex-col sm:flex-row items-center justify-center gap-4 animate-fade-in animation-delay-600">
          <Link
            href="/signup"
            className="group relative inline-flex items-center gap-2 bg-gradient-to-r from-accent to-accent-light text-background px-8 py-4 rounded-full font-semibold text-lg hover:shadow-lg hover:shadow-accent/25 transition-all"
          >
            Get started free
            <svg
              className="w-5 h-5 group-hover:translate-x-1 transition-transform"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M17 8l4 4m0 0l-4 4m4-4H3"
              />
            </svg>
          </Link>
          <a
            href="#how-it-works"
            className="inline-flex items-center gap-2 text-muted hover:text-foreground px-6 py-4 transition-colors"
          >
            <svg
              className="w-5 h-5"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z"
              />
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
              />
            </svg>
            See how it works
          </a>
        </div>

        {/* Demo visualization */}
        <div className="mt-20 animate-fade-in animation-delay-600">
          <div className="relative mx-auto max-w-md">
            {/* Simulated noa overlay */}
            <div className="bg-card/80 backdrop-blur-xl border border-card-border rounded-2xl p-6 shadow-2xl animate-float">
              <div className="flex items-center gap-3 mb-4">
                <div className="w-3 h-3 bg-accent rounded-full animate-pulse" />
                <span className="text-sm text-muted">Listening...</span>
              </div>
              <p className="text-lg mb-4">&ldquo;What&apos;s on my calendar today?&rdquo;</p>
              <div className="border-t border-card-border pt-4">
                <p className="text-muted text-sm">
                  You have 3 meetings today: Standup at 9am, Design review at 2pm, 
                  and Team sync at 4pm.
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Scroll indicator */}
      <div className="absolute bottom-8 left-1/2 -translate-x-1/2 animate-bounce">
        <svg
          className="w-6 h-6 text-muted"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={2}
            d="M19 14l-7 7m0 0l-7-7m7 7V3"
          />
        </svg>
      </div>
    </section>
  )
}
