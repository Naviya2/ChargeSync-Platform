import { Link } from 'react-router-dom'
import { ROUTES } from '../../../lib/constants'

const FILLED = { fontVariationSettings: "'FILL' 1" }

const BULLETS = [
  'Automatic driver matching fills off-peak lulls without marketing spend.',
  'Full integration with OCPP 1.6J / 2.0.1 and standalone hardware.',
  'Guaranteed direct weekly bank deposits with transparent fee transparency.',
]

const TIMELINE = [
  {
    n: 1,
    title: 'Sign Up',
    body: 'Create your Station Owner account in under 2 minutes. Add basic contact details and ownership verification.',
  },
  {
    n: 2,
    title: 'Add Your Station',
    body: 'Enter location, physical address, electrical specs, parking bay access rules, and photos.',
  },
  {
    n: 3,
    title: 'List Your Chargers',
    body: 'Configure connector types (CCS, NACS, J1772), max kW rating, pricing per kWh, and operating hours.',
  },
  {
    n: 4,
    title: 'Go Live',
    body: 'Your station appears instantly in driver search once approved. Track bookings, payouts, and revenue from your dashboard.',
  },
]

const BENEFITS = [
  {
    icon: 'payments',
    title: 'Set Your Own Pricing',
    body: 'Full control over custom rate tariffs, peak surge rules, and flat off-peak models that maximize net profit margins.',
  },
  {
    icon: 'calendar_month',
    title: 'Real-Time Booking Calendar',
    body: 'Live slot reservation schedules eliminate lot congestion and queue disputes with automated 15-minute grace cushions.',
  },
  {
    icon: 'monitoring',
    title: 'Utilization & Revenue Analytics',
    body: 'Track gross revenue, MWh delivered, peak operating hours, and customer return rates with downloadable financial logs.',
  },
]

export default function StationOwnerSection() {
  return (
    <section id="station-owners" className="w-full bg-surface-container-low py-space-3xl lg:py-24">
      <div className="mx-auto max-w-7xl px-space-lg lg:px-space-xl">
        <div className="grid grid-cols-1 items-start gap-space-2xl lg:grid-cols-12">
          {/* Left: copy, bullets, CTA */}
          <div className="flex flex-col items-start gap-space-lg lg:col-span-6">
            <span className="font-label-sm text-label-sm font-bold uppercase tracking-widest text-primary">
              For Station Operators &amp; Hosts
            </span>
            <h2 className="font-display-lg text-display-lg font-bold tracking-tight text-on-surface">
              Turn Your Charger Into a Revenue Stream
            </h2>
            <p className="font-body-lg text-body-lg leading-relaxed text-on-surface-variant">
              Monetize idle charging ports, reach high-intent EV drivers actively searching nearby,
              and leverage AI-optimized dynamic pricing insights with real-time utilization analytics
              and zero upfront setup fees.
            </p>

            <div className="w-full space-y-space-sm pt-space-xs">
              {BULLETS.map((text) => (
                <div key={text} className="flex items-start gap-space-sm">
                  <span
                    className="material-symbols-outlined mt-0.5 shrink-0 text-[20px] text-tertiary"
                    style={FILLED}
                  >
                    check_circle
                  </span>
                  <span className="font-body-md text-body-md font-medium text-on-surface">{text}</span>
                </div>
              ))}
            </div>

            <Link
              to={ROUTES.LOGIN}
              className="mt-space-sm inline-flex items-center gap-space-xs rounded-xl bg-gradient-to-r from-primary to-tertiary px-space-xl py-space-md font-headline-sm text-headline-sm font-semibold text-on-primary shadow-md shadow-primary/20 transition-all hover:brightness-105"
            >
              <span>Register Your Station</span>
              <span className="material-symbols-outlined text-[20px]">arrow_forward</span>
            </Link>
          </div>

          {/* Right: registration timeline */}
          <div className="rounded-2xl bg-surface-container-lowest p-space-xl shadow-sm lg:col-span-6 lg:p-space-2xl">
            <h3 className="mb-space-lg font-headline-md text-headline-md font-bold text-on-surface">
              How to Register in Minutes
            </h3>
            <div className="space-y-space-lg">
              {TIMELINE.map((item) => (
                <div key={item.n} className="flex items-start gap-space-md">
                  <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-primary font-headline-sm text-headline-sm text-on-primary">
                    {item.n}
                  </div>
                  <div>
                    <h4 className="font-headline-sm text-headline-sm font-semibold text-on-surface">
                      {item.title}
                    </h4>
                    <p className="mt-0.5 font-body-sm text-body-sm text-on-surface-variant">{item.body}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Host benefit cards */}
        <div className="mt-space-2xl grid grid-cols-1 gap-space-lg md:grid-cols-3">
          {BENEFITS.map((b) => (
            <div key={b.title} className="rounded-xl bg-surface-container-lowest p-space-xl shadow-sm">
              <div className="mb-space-md flex h-10 w-10 items-center justify-center rounded-lg bg-surface-container-high text-primary">
                <span className="material-symbols-outlined text-[24px]">{b.icon}</span>
              </div>
              <h4 className="mb-space-2xs font-headline-sm text-headline-sm font-semibold text-on-surface">
                {b.title}
              </h4>
              <p className="font-body-sm text-body-sm text-on-surface-variant">{b.body}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
