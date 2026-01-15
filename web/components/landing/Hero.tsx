'use client'

import Link from 'next/link'
import { useState, useEffect } from 'react'

export function Hero() {
  const [toggle, setToggle] = useState(false)
  const [activePlatform, setPlatform] = useState('Mac')

  useEffect(() => {
    const interval = setInterval(() => {
      setToggle(prev => !prev)
    }, 3000)
    return () => clearInterval(interval)
  }, [])

  return (
    <section className="bg-[#FEFDF5] overflow-hidden relative">
      {/* Background Animations */}
      <div className="absolute inset-0 pointer-events-none overflow-hidden">
        {/* Bubbles */}
        <div className="absolute top-[10%] left-[5%] w-64 h-64 bg-[#E9D5FF] rounded-full mix-blend-multiply filter blur-3xl opacity-30 animate-blob"></div>
        <div className="absolute top-[10%] right-[5%] w-64 h-64 bg-[#dcfce7] rounded-full mix-blend-multiply filter blur-3xl opacity-30 animate-blob animation-delay-2000"></div>
        <div className="absolute bottom-[20%] left-[20%] w-64 h-64 bg-[#fce7f3] rounded-full mix-blend-multiply filter blur-3xl opacity-30 animate-blob animation-delay-4000"></div>
      </div>

      <div className="relative flex flex-col items-center pt-24 pb-0">

        <div className="absolute top-10 left-0 right-0 pointer-events-none select-none opacity-50 z-0">
          <div className="flex whitespace-nowrap animate-marquee-slow">
            {[...Array(6)].map((_, i) => (
              <span key={i} className="text-4xl mx-8 font-serif italic text-[#1a1a1a]/10">
                What&apos;s my schedule? • Draft a reply to Sarah • Summarize this PDF •
              </span>
            ))}
          </div>
        </div>

        <div className="relative z-20 max-w-5xl mx-auto px-6 text-center mt-12 mb-12">

          {/* Animated Headline */}
          <div className="h-32 flex items-center justify-center mb-8 relative">
            <h1 className="text-6xl md:text-9xl tracking-tight text-[#1a1a1a] leading-tight font-serif flex items-baseline justify-center">

              {/* Prefix 'k' */}
              <span
                className="overflow-hidden transition-all duration-1000 cubic-bezier(0.4, 0, 0.2, 1) opacity-0 data-[visible=true]:opacity-100 text-right"
                style={{ maxWidth: toggle ? '0.7em' : '0px' }}
                data-visible={toggle}
              >
                k
              </span>

              {/* Core 'no' */}
              <span>no</span>

              {/* Suffix Container */}
              <span className="relative h-[1.1em] flex items-baseline">
                {/* 'a' - visible when toggle is false */}
                <span
                  className="absolute left-0 top-0 transition-all duration-1000 ease-in-out whitespace-nowrap"
                  style={{
                    opacity: toggle ? 0 : 1,
                    transform: toggle ? 'translateY(20px)' : 'translateY(0)',
                    pointerEvents: 'none'
                  }}
                >
                  a
                </span>

                {/* 'ws it all' - visible when toggle is true */}
                {/* We animate the width of this container to make room */}
                <span
                  className="overflow-hidden transition-all duration-1000 cubic-bezier(0.4, 0, 0.2, 1) whitespace-nowrap block"
                  style={{
                    maxWidth: toggle ? '4.5em' : '0.6em', // 0.6em reserved for 'a' width
                    opacity: 1 // Always occupy space, just crossfade content visually if needed
                  }}
                >
                  <span style={{ opacity: toggle ? 1 : 0, transition: 'opacity 0.5s 0.2s' }}>
                    ws it all
                  </span>
                </span>
              </span>
            </h1>
          </div>

          {/* Subheadline */}
          <p className="text-xl md:text-2xl text-[#4a4a4a] max-w-2xl mx-auto mb-10 font-medium leading-relaxed">
            The voice AI that stays in context.<br />
            From <span className="text-[#1a1a1a] font-semibold">notes</span> to <span className="text-[#1a1a1a] font-semibold">notion</span>, just ask.
          </p>

          {/* CTA Button */}
          <div className="flex flex-col items-center gap-4 mb-16">
            <Link
              href="/download"
              className="inline-flex items-center gap-2 bg-[#1a1a1a] text-[#FEFDF5] px-8 py-4 rounded-full text-lg font-semibold hover:scale-105 transition-all shadow-xl"
            >
              <svg className="w-6 h-6" viewBox="0 0 24 24" fill="currentColor">
                <path d="M17.05 20.28c-.98.95-2.05.8-3.08.35-1.09-.46-2.09-.48-3.24 0-1.44.62-2.2.44-3.06-.35C2.79 15.25 3.51 7.59 9.05 7.31c1.35.07 2.29.74 3.08.74s2.57-.9 3.53-.78c5.44.41 7.23 6.96 4.35 11.2-.72 1.05-1.78 2.52-2.96 1.81zM12.03 7.25c-.15-2.23 1.66-4.07 3.74-4.25.29 2.58-2.34 4.5-3.74 4.25z" />
              </svg>
              Download noa
            </Link>
          </div>

          {/* Scrolling Examples */}
          <div className="w-full overflow-hidden mask-gradient-x relative z-10">
            <div className="flex gap-4 animate-marquee hover:[animation-play-state:paused]">
              {[
                "When is my next meeting with Sarah?",
                "Draft an email to Alex about the Q3 report",
                "Find the screenshot of the dashboard error",
                "Add a 1:1 with Mike to my calendar at 2pm",
                "Summarize the last 3 emails from marketing",
                "What did I work on yesterday?"
              ].map((text, i) => (
                <div key={i} className="flex-shrink-0 bg-white border border-[#1a1a1a]/10 px-6 py-3 rounded-full shadow-sm text-[#1a1a1a] text-sm whitespace-nowrap">
                  "{text}"
                </div>
              ))}
              {[
                "When is my next meeting with Sarah?",
                "Draft an email to Alex about the Q3 report",
                "Find the screenshot of the dashboard error",
                "Add a 1:1 with Mike to my calendar at 2pm",
                "Summarize the last 3 emails from marketing",
                "What did I work on yesterday?"
              ].map((text, i) => (
                <div key={`dup-${i}`} className="flex-shrink-0 bg-white border border-[#1a1a1a]/10 px-6 py-3 rounded-full shadow-sm text-[#1a1a1a] text-sm whitespace-nowrap">
                  "{text}"
                </div>
              ))}
            </div>
          </div>

        </div>
      </div>

      {/* Dark Section */}
      <div className="bg-[#1a1a1a] text-white rounded-t-[3rem] pt-24 pb-32 px-6 relative z-30 -mt-24">
        <div className="max-w-6xl mx-auto text-center">
          {/* Platform Tabs */}
          <div className="flex justify-center gap-2 mb-12">
            {['iOS', 'Mac', 'Windows'].map((platform) => (
              <button
                key={platform}
                onClick={() => setPlatform(platform)}
                className={`flex items-center gap-2 px-6 py-2 rounded-full text-sm font-medium transition-all duration-300 ${activePlatform === platform
                  ? 'bg-white text-[#1a1a1a] scale-105'
                  : 'bg-white/5 text-white/60 hover:bg-white/10 hover:text-white'
                  }`}
              >
                {platform === 'Mac' || platform === 'iOS' ? (
                  <svg className="w-4 h-4" viewBox="0 0 24 24" fill="currentColor"><path d="M17.05 20.28c-.98.95-2.05.8-3.08.35-1.09-.46-2.09-.48-3.24 0-1.44.62-2.2.44-3.06-.35C2.79 15.25 3.51 7.59 9.05 7.31c1.35.07 2.29.74 3.08.74s2.57-.9 3.53-.78c5.44.41 7.23 6.96 4.35 11.2-.72 1.05-1.78 2.52-2.96 1.81zM12.03 7.25c-.15-2.23 1.66-4.07 3.74-4.25.29 2.58-2.34 4.5-3.74 4.25z" /></svg>
                ) : (
                  <svg className="w-4 h-4" viewBox="0 0 24 24" fill="currentColor"><path d="M0 3.449L9.75 2.1v9.451H0v-8.102zm10.949-1.605L24 0v11.4h-13.051V1.844zM0 13.053h9.75v8.2L0 19.95v-6.897zm10.949 0H24V24l-13.051-1.843v-9.104z" /></svg>
                )}
                {platform}
              </button>
            ))}
          </div>

          <h2 className="text-5xl md:text-7xl font-serif text-[#FEFDF5] mb-6 leading-tight">
            Connect your digital life<br />
            <span className="text-[#a3a3a3]">with just your voice</span>
          </h2>
          <p className="text-xl text-[#a3a3a3] max-w-2xl mx-auto mb-12 leading-relaxed">
            Noa lives in your background and connects to your Calendar, Email, and Notes.
            Just hold a key and speak to take action instantly.
          </p>

          <button className="bg-[#FEFDF5] text-[#1a1a1a] px-8 py-3 rounded-full font-semibold hover:bg-white hover:scale-105 transition-all shadow-[0_0_20px_rgba(255,255,255,0.3)]">
            See active integrations
          </button>

          {/* App Icons Arc Visualization */}
          <div className="mt-20 relative h-64 overflow-hidden pointer-events-none">
            <div className="absolute top-10 left-1/2 -translate-x-1/2 w-[800px] h-[800px] border border-white/10 rounded-full animate-pulse-slow"></div>
            {/* Icons positioned on arc with float animation */}
            <div className="absolute top-0 left-1/2 -translate-x-1/2 flex items-end justify-center w-full h-full gap-8">
              {['gmail', 'notion', 'linear', 'slack', 'calendar', 'zoom'].map((app, i) => (
                <div
                  key={app}
                  className="w-20 h-20 bg-[#2a2a2a]/80 backdrop-blur-md rounded-2xl flex flex-col gap-2 items-center justify-center border border-white/5 shadow-2xl transition-all duration-500 hover:-translate-y-4 hover:bg-[#333]"
                  style={{
                    transform: `translateY(${Math.abs(i - 2.5) * 30 + 10}px) rotate(${(i - 2.5) * 8}deg)`,
                    animation: `float-slow ${3 + i * 0.5}s infinite ease-in-out`
                  }}
                >
                  <div className={`w-8 h-8 rounded-full opacity-80 ${app === 'gmail' ? 'bg-red-500/20 text-red-400' :
                    app === 'slack' ? 'bg-amber-500/20 text-amber-400' :
                      app === 'calendar' ? 'bg-blue-500/20 text-blue-400' :
                        'bg-gray-500/20 text-gray-400'
                    } flex items-center justify-center`}>
                    <span className="text-[10px] uppercase font-bold">{app[0]}</span>
                  </div>
                  <span className="text-[10px] text-gray-400 capitalize">{app}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* CSS for custom animations if not in globals */}
      <style jsx global>{`
        @keyframes blob {
          0% { transform: translate(0px, 0px) scale(1); }
          33% { transform: translate(30px, -50px) scale(1.1); }
          66% { transform: translate(-20px, 20px) scale(0.9); }
          100% { transform: translate(0px, 0px) scale(1); }
        }
        .animate-blob {
          animation: blob 7s infinite;
        }
        .animation-delay-2000 {
          animation-delay: 2s;
        }
        .animation-delay-4000 {
          animation-delay: 4s;
        }
        @keyframes marquee {
          0% { transform: translateX(0); }
          100% { transform: translateX(-50%); }
        }
        .animate-marquee {
          animation: marquee 30s linear infinite;
        }
        .animate-marquee-slow {
          animation: marquee 60s linear infinite;
        }
        @keyframes float-slow {
           0% { transform: translateY(0px) rotate(0deg); }
           50% { transform: translateY(-10px) rotate(2deg); }
           100% { transform: translateY(0px) rotate(0deg); }
        }

      `}</style>

    </section>
  )
}
