const steps = [
  {
    number: '01',
    title: 'Hold the key',
    description: 'Press and hold the function key to activate noa. A small overlay appears at the bottom of your screen.',
  },
  {
    number: '02',
    title: 'Speak naturally',
    description: 'Ask anything in plain language. "What\'s on my calendar?" or "What am I looking at?"',
  },
  {
    number: '03',
    title: 'Get your answer',
    description: 'noa processes your request and displays the response instantly. No app switching required.',
  },
]

export function HowItWorks() {
  return (
    <section id="how-it-works" className="py-32 relative">
      <div className="max-w-6xl mx-auto px-6">
        {/* Section header */}
        <div className="text-center mb-16">
          <h2 className="text-3xl md:text-4xl font-bold mb-4">
            Simple by design
          </h2>
          <p className="text-muted text-lg max-w-2xl mx-auto">
            No complex setup. No learning curve. Just speak and get answers.
          </p>
        </div>

        {/* Steps */}
        <div className="grid md:grid-cols-3 gap-8 md:gap-12">
          {steps.map((step, index) => (
            <div key={index} className="relative">
              {/* Connector line */}
              {index < steps.length - 1 && (
                <div className="hidden md:block absolute top-8 left-full w-full h-px bg-gradient-to-r from-card-border to-transparent" />
              )}
              
              <div className="text-accent font-mono text-sm mb-4">{step.number}</div>
              <h3 className="font-semibold text-xl mb-3">{step.title}</h3>
              <p className="text-muted leading-relaxed">{step.description}</p>
            </div>
          ))}
        </div>

        {/* Visual demo */}
        <div className="mt-20">
          <div className="relative bg-card border border-card-border rounded-2xl overflow-hidden">
            {/* Fake window chrome */}
            <div className="flex items-center gap-2 px-4 py-3 border-b border-card-border">
              <div className="w-3 h-3 rounded-full bg-red-500/80" />
              <div className="w-3 h-3 rounded-full bg-yellow-500/80" />
              <div className="w-3 h-3 rounded-full bg-green-500/80" />
            </div>
            
            {/* Content area */}
            <div className="relative h-80 bg-gradient-to-br from-zinc-900 to-zinc-950 flex items-end justify-center p-8">
              {/* Simulated screen content */}
              <div className="absolute inset-4 top-0 opacity-30">
                <div className="h-4 bg-zinc-800 rounded w-3/4 mb-3" />
                <div className="h-4 bg-zinc-800 rounded w-1/2 mb-3" />
                <div className="h-20 bg-zinc-800 rounded mb-3" />
                <div className="h-4 bg-zinc-800 rounded w-2/3" />
              </div>

              {/* noa overlay */}
              <div className="relative w-full max-w-sm">
                <div className="bg-zinc-900/95 backdrop-blur-xl border border-zinc-700 rounded-2xl p-5 shadow-2xl">
                  <div className="flex items-center gap-2 mb-3">
                    <div className="w-2.5 h-2.5 bg-accent rounded-full animate-pulse" />
                    <span className="text-xs text-muted font-medium">noa</span>
                  </div>
                  <p className="text-sm mb-3 text-zinc-300">&ldquo;What&apos;s on my screen?&rdquo;</p>
                  <div className="border-t border-zinc-700 pt-3">
                    <p className="text-xs text-zinc-400 leading-relaxed">
                      You&apos;re looking at a code editor with a React component. 
                      The file appears to be a navigation component with responsive styling.
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
