import { NavLink } from 'react-router-dom'
import { ROUTES, NAV_SECTIONS, ROLE_LABELS } from '../../lib/constants'
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

import { usePendingStations } from '../../features/approvals/hooks/useAdminStations'

export default function Sidebar({ isOpen, onClose }) {
  const user = useAuthStore((s) => s.user)
  const role = user?.role
  const roleLabel = role ? (ROLE_LABELS[role] ?? role) : 'Guest'

  const { data: pendingStations = [] } = usePendingStations()

  const sections = NAV_SECTIONS.map((section) => ({
    ...section,
    items: section.items.filter((item) => !role || item.roles.includes(role)).map(item => {
      if (item.to === ROUTES.APPROVALS) {
        return {
          ...item,
          badge: pendingStations.length > 0
            ? { text: `${pendingStations.length} pending`, tone: 'secondary' }
            : null
        }
      }
      return item
    }),
  })).filter((section) => section.items.length > 0)

  return (
    <>
      {/* Mobile Overlay */}
      {isOpen && (
        <div
          className="fixed inset-0 z-40 bg-black/50 lg:hidden"
          onClick={onClose}
          aria-hidden="true"
        />
      )}

      <aside
        className={cn(
          "fixed left-0 top-0 z-50 h-screen w-sidebar-width flex-col justify-between overflow-y-auto bg-inverse-surface text-inverse-on-surface transition-transform duration-300 ease-in-out lg:flex",
          isOpen ? "translate-x-0 flex" : "-translate-x-full lg:translate-x-0 hidden"
        )}
      >
        <div className="flex flex-col">
          {/* Brand */}
          <div className="flex items-center justify-between p-space-lg">
            <div className="flex items-center gap-space-sm">
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

            {/* Close button for mobile */}
            <button
              className="lg:hidden flex h-8 w-8 items-center justify-center rounded-full text-outline-variant hover:bg-on-surface/10 hover:text-inverse-on-surface"
              onClick={onClose}
            >
              <span className="material-symbols-outlined">close</span>
            </button>
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
          <nav className="flex flex-col gap-space-2xs px-space-sm pb-space-lg">
            {sections.map((section) => (
              <div key={section.label} className="flex flex-col gap-space-2xs">
                <div className="px-space-md py-space-xs font-label-sm text-label-sm uppercase text-outline-variant">
                  {section.labelByRole?.[role] ?? section.label}
                </div>
                {section.items.map((item) => (
                  <NavLink
                    key={item.label}
                    to={item.to}
                    onClick={onClose} // close sidebar when a link is clicked on mobile
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
            <span className="h-2 w-2 animate-pulse rounded-full bg-green-500" />
            <span className="font-label-sm text-label-sm text-outline-variant">System Online</span>
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
    </>
  )
}
