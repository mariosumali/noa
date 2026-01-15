'use client'

import Link from 'next/link'
import { useState, useEffect } from 'react'

export function Navigation() {
  const [scrolled, setScrolled] = useState(false)

  useEffect(() => {
    const handleScroll = () => {
      setScrolled(window.scrollY > 20)
    }
    window.addEventListener('scroll', handleScroll)
    return () => window.removeEventListener('scroll', handleScroll)
  }, [])

  return (
    <nav
      className={`sticky top-0 left-0 right-0 z-40 transition-all duration-300 ${'bg-[#FEFDF5] border-b border-transparent'
        }`}
    >
      <div className="max-w-7xl mx-auto px-6 h-20 flex items-center justify-between">
        {/* Logo */}
        <Link href="/" className="flex items-center gap-3 group">
          <span className="font-semibold text-2xl tracking-tight text-[#1a1a1a]">noa</span>
        </Link>

        {/* Nav Links */}
        <div className="hidden lg:flex items-center gap-8">
          {['Product', 'About'].map((item) => (
            <a
              key={item}
              href={`#${item.toLowerCase()}`}
              className="text-sm font-medium text-[#1a1a1a] hover:text-gray-600 transition-colors"
            >
              {item}
            </a>
          ))}
        </div>

        {/* CTA Buttons */}
        <div className="flex items-center gap-4">
          <Link
            href="/login"
            className="hidden sm:inline-block px-5 py-2.5 rounded-lg border border-gray-200 text-sm font-medium text-[#1a1a1a] hover:bg-gray-50 transition-colors"
          >
            Log in
          </Link>
          <Link
            href="/download"
            className="hidden sm:inline-flex items-center gap-2 bg-[#E9D5FF] text-[#1a1a1a] px-5 py-2.5 rounded-lg text-sm font-semibold hover:bg-[#d8b4fe] transition-colors border border-[#1a1a1a]"
          >
            <svg className="w-4 h-4" viewBox="0 0 24 24" fill="currentColor">
              <path d="M17.05 20.28c-.98.95-2.05.8-3.08.35-1.09-.46-2.09-.48-3.24 0-1.44.62-2.2.44-3.06-.35C2.79 15.25 3.51 7.59 9.05 7.31c1.35.07 2.29.74 3.08.74s2.57-.9 3.53-.78c5.44.41 7.23 6.96 4.35 11.2-.72 1.05-1.78 2.52-2.96 1.81zM12.03 7.25c-.15-2.23 1.66-4.07 3.74-4.25.29 2.58-2.34 4.5-3.74 4.25z" />
            </svg>
            Download for macOS
          </Link>
        </div>
      </div>
    </nav>
  )
}
