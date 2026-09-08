import BrandMark from './BrandMark'

const COLUMNS = [
  {
    title: 'Product',
    links: ['Find a Station', 'Register a Station', 'Pricing', 'AI Planner', 'Mobile App', 'API Access'],
  },
  {
    title: 'Company',
    links: ['About Us', 'Careers', 'Press', 'Blog', 'Sustainability Report'],
  },
  {
    title: 'Support',
    links: ['Help Center', 'Station Status', 'Contact Operations', 'Report a Charger'],
  },
  {
    title: 'Legal',
    links: ['Privacy Policy', 'Terms of Service', 'SOC2 Compliance', 'Grid Security'],
  },
]

const SOCIAL = [
  { icon: 'terminal', label: 'X / Twitter' },
  { icon: 'share', label: 'LinkedIn' },
  { icon: 'code', label: 'GitHub' },
  { icon: 'smart_display', label: 'YouTube' },
]

export default function LandingFooter() {
  return (
    <footer className="w-full bg-inverse-surface pb-space-2xl pt-space-3xl text-inverse-on-surface">
      <div className="mx-auto max-w-7xl px-space-lg lg:px-space-xl">
        <div className="flex flex-col items-start justify-between gap-space-xl pb-space-2xl lg:flex-row lg:items-center">
          <div className="max-w-md">
            <BrandMark dark className="mb-space-xs" />
            <p className="mt-space-xs font-body-sm text-body-sm text-surface-variant">
              Powering Tomorrow. Autonomous, interoperable EV reservation intelligence connecting
              drivers, hosts, and regional energy grids seamlessly.
            </p>
          </div>
          <div className="flex items-center gap-space-md text-surface-variant">
            {SOCIAL.map((s) => (
              <a
                key={s.icon}
                href="#"
                aria-label={s.label}
                className="transition-colors hover:text-primary-fixed"
              >
                <span className="material-symbols-outlined text-[20px]">{s.icon}</span>
              </a>
            ))}
          </div>
        </div>

        <div className="grid grid-cols-2 gap-space-2xl py-space-2xl md:grid-cols-4">
          {COLUMNS.map((col) => (
            <div key={col.title}>
              <h4 className="mb-space-md font-label-sm text-label-sm font-semibold uppercase tracking-wider text-white">
                {col.title}
              </h4>
              <ul className="space-y-space-xs font-body-sm text-body-sm text-surface-variant">
                {col.links.map((link) => (
                  <li key={link}>
                    <a href="#" className="transition-colors hover:text-white">
                      {link}
                    </a>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>

        <div className="flex flex-col items-center justify-between gap-space-md pt-space-xl font-body-sm text-body-sm text-surface-variant md:flex-row">
          <p>© 2025 ChargeSync Technologies Inc. All rights reserved.</p>
          <div className="flex items-center gap-space-xs text-tertiary-fixed-dim">
            <span className="h-2 w-2 animate-pulse rounded-full bg-tertiary" />
            <span className="font-medium">All Systems Operational</span>
          </div>
        </div>
      </div>
    </footer>
  )
}
