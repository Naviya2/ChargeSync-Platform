import { Link } from 'react-router-dom'
import BrandMark from './BrandMark'
import { ROUTES } from '../../../lib/constants'

const NAV = [
  { label: 'How It Works', href: '#how-it-works' },
  { label: 'For Station Owners', href: '#station-owners' },
  { label: 'AI Features', href: '#ai-features' },
  { label: 'Testimonials', href: '#testimonials' },
]

export default function LandingNavbar() {
  return (
    <header className="fixed inset-x-0 top-0 z-50 bg-inverse-surface/95 shadow-[0_1px_8px_rgba(0,0,0,0.08)] backdrop-blur-xl">
      <div className="mx-auto flex h-16 w-full max-w-7xl items-center justify-between gap-space-md px-space-lg lg:px-space-xl">
        <BrandMark dark />

        <nav className="hidden items-center gap-space-lg md:flex lg:gap-space-xl">
          {NAV.map((item) => (
            <a
              key={item.href}
              href={item.href}
              className="font-body-md text-body-md text-surface-variant transition-colors hover:text-inverse-on-surface"
            >
              {item.label}
            </a>
          ))}
        </nav>

        <div className="flex shrink-0 items-center gap-space-md">
          <Link
            to={ROUTES.LOGIN}
            className="hidden items-center justify-center rounded-xl px-space-md py-space-xs font-label-md text-label-md text-inverse-on-surface transition-colors hover:bg-white/10 sm:inline-flex"
          >
            Log In
          </Link>
          <Link
            to={ROUTES.LOGIN}
            className="inline-flex items-center justify-center rounded-xl bg-gradient-to-r from-primary to-tertiary px-space-lg py-space-xs font-label-md text-label-md text-on-primary shadow-sm transition-all hover:brightness-105"
          >
            Get Started
          </Link>
        </div>
      </div>
    </header>
  )
}
