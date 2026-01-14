import Link from 'next/link'

export function CTA() {
  return (
    <section className="py-32 relative overflow-hidden">
      {/* Background gradient */}
      <div className="absolute inset-0 bg-gradient-to-t from-accent/10 via-transparent to-transparent" />
      <div className="absolute bottom-0 left-1/2 -translate-x-1/2 w-[800px] h-[400px] bg-accent/20 rounded-full blur-3xl" />

      <div className="relative z-10 max-w-4xl mx-auto px-6 text-center">
        <h2 className="text-3xl md:text-5xl font-bold mb-6">
          Ready to simplify your digital life?
        </h2>
        <p className="text-muted text-lg mb-10 max-w-2xl mx-auto">
          Join the beta and be among the first to experience a new way of interacting with your tools.
        </p>
        
        <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
          <Link
            href="/signup"
            className="group inline-flex items-center gap-2 bg-gradient-to-r from-accent to-accent-light text-background px-8 py-4 rounded-full font-semibold text-lg hover:shadow-lg hover:shadow-accent/25 transition-all"
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
        </div>

        <p className="text-sm text-muted mt-6">
          No credit card required · Free during beta
        </p>
      </div>
    </section>
  )
}
