import { Navigation, Hero, Features, HowItWorks, CTA, Footer } from '@/components/landing'

export default function Home() {
  return (
    <main className="min-h-screen">
      <Navigation />
      <Hero />
      <Features />
      <HowItWorks />
      <CTA />
      <Footer />
    </main>
  )
}
