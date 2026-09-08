import { NavLink } from 'react-router-dom'
import { NAV_SECTIONS, ROLE_LABELS } from '../../lib/constants'
import { useAuthStore } from '../../store/authStore'
import { cn } from '../../lib/cn'

const BADGE_TONE = {
  secondary: 'bg-secondary text-on-secondary',
  tertiary: 'bg-tertiary-container text-on-tertiary-container',
  error: 'bg-error-container text-on-error-container',
}

function NavBadge({ badge }) {
  return (
    <span
      className={cn(
        'flex items-center gap-space-xs rounded-full px-space-xs py-space-2xs font-label-sm text-label-sm',
        BADGE_TONE[badge.tone] ?? BADGE_TONE.secondary,
      )}
    >
      {badge.dot && <span className="h-1.5 w-1.5 rounded-full bg-tertiary-fixed" />}
      {badge.text}
    </span>
  )
}

export default function Sidebar() {
  const user = useAuthStore((s) => s.user)
  const role = user?.role
  const roleLabel = role ? (ROLE_LABELS[role] ?? role) : 'Guest'

  const sections = NAV_SECTIONS.map((section) => ({
    ...section,
    items: section.items.filter((item) => !role || item.roles.includes(role)),
  })).filter((section) => section.items.length > 0)

  return (
    <aside className="fixed left-0 top-0 z-50 hidden h-screen w-sidebar-width flex-col justify-between overflow-y-auto bg-inverse-surface text-inverse-on-surface lg:flex">
      <div className="flex flex-col">
        {/* Brand */}
        <div className="flex items-center gap-space-sm p-space-lg">
          <span className="flex h-8 w-8 items-center justify-center rounded-xl bg-gradient-to-br from-primary to-tertiary text-on-primary">
            <span className="material-symbols-outlined text-[20px]">bolt</span>
          </span>
          <div className="flex flex-col">
            <span className="font-headline-sm text-headline-sm tracking-tight text-inverse-on-surface">
              ChargeSync
            </span>
            <span className="font-label-sm text-label-sm text-outline-variant">Powering Tomorrow</span>
          </div>
        </div>

        {/* Active role */}
        <div className="mb-space-md px-space-lg">
          <div className="flex w-full items-center justify-between rounded-xl bg-on-surface/10 px-space-md py-space-sm">
            <div className="flex items-center gap-space-sm">
              <span className="h-2 w-2 rounded-full bg-primary-fixed" />
              <div className="text-left">
                <p className="font-label-sm text-label-sm text-outline-variant">ACTIVE ROLE</p>
                <p className="font-headline-sm text-body-sm text-inverse-on-surface">{roleLabel}</p>
              </div>
            </div>
          </div>
        </div>

        {/* Navigation */}
        <nav className="flex flex-col gap-space-2xs px-space-sm">
          {sections.map((section) => (
            <div key={section.label} className="flex flex-col gap-space-2xs">
              <div className="px-space-md py-space-xs font-label-sm text-label-sm uppercase text-outline-variant">
                {section.labelByRole?.[role] ?? section.label}
              </div>
              {section.items.map((item) => (
                <NavLink
                  key={item.label}
                  to={item.to}
                  className={({ isActive }) =>
                    cn(
                      'flex items-center justify-between rounded-xl px-space-md py-space-sm transition-colors',
                      isActive
                        ? 'bg-primary-container font-semibold text-on-primary-container'
                        : 'text-outline-variant hover:bg-on-surface/10 hover:text-inverse-on-surface',
                    )
                  }
                >
                  <span className="flex items-center gap-space-md">
                    <span className="material-symbols-outlined text-xl">{item.icon}</span>
                    <span className="font-body-md text-body-md">{item.label}</span>
                  </span>
                  {item.badge && <NavBadge badge={item.badge} />}
                </NavLink>
              ))}
            </div>
          ))}
        </nav>
      </div>

      {/* Footer */}
      <div className="flex flex-col gap-space-md p-space-lg">
        <div className="flex items-center gap-space-sm rounded-lg bg-on-surface/5 px-space-md py-space-xs">
          <span className="h-2 w-2 animate-pulse rounded-full bg-tertiary-fixed" />
          <span className="font-label-sm text-label-sm text-outline-variant">API 99.98% Operational</span>
        </div>
        <div className="flex items-center justify-between rounded-xl bg-on-surface/10 p-space-sm">
          <div className="flex items-center gap-space-sm">
            <span className="flex h-8 w-8 items-center justify-center rounded-full bg-primary/30 font-label-sm text-label-sm text-inverse-on-surface">
              {(user?.name ?? 'G')
                .split(' ')
                .map((w) => w[0])
                .slice(0, 2)
                .join('')}
            </span>
            <div className="flex flex-col">
              <span className="font-label-md text-label-md text-inverse-on-surface">
                {user?.name ?? 'Guest'}
              </span>
              <span className="font-label-sm text-label-sm text-outline-variant">{roleLabel}</span>
            </div>
          </div>
        </div>
      </div>
    </aside>
  )
}
