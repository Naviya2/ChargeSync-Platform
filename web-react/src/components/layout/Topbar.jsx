import { useNavigate } from 'react-router-dom'
import { useAuthStore } from '../../store/authStore'
import { ROUTES } from '../../lib/constants'

export default function Topbar() {
  const navigate = useNavigate()
  const user = useAuthStore((s) => s.user)
  const clearSession = useAuthStore((s) => s.clearSession)

  const handleLogout = () => {
    clearSession()
    navigate(ROUTES.LOGIN, { replace: true })
  }

  const initials = (user?.name ?? 'G')
    .split(' ')
    .map((w) => w[0])
    .slice(0, 2)
    .join('')

  return (
    <header className="sticky top-0 z-30 h-topbar-height bg-surface-container-lowest/90 shadow-[0_1px_8px_rgba(0,0,0,0.04)] backdrop-blur-md">
      <div className="flex h-topbar-height w-full items-center justify-between gap-space-lg px-gutter-desktop">
        {/* Search */}
        <div className="flex max-w-xl flex-1 items-center">
          <div className="relative w-full max-w-md">
            <span className="material-symbols-outlined absolute left-space-md top-1/2 -translate-y-1/2 text-lg text-on-surface-variant">
              search
            </span>
            <input
              type="text"
              placeholder="Search stations, reservations, users..."
              className="w-full rounded-xl bg-surface-container-low py-space-xs pl-10 pr-12 font-body-sm text-body-sm text-on-surface placeholder:text-on-surface-variant focus:outline-none focus:ring-2 focus:ring-primary"
            />
            <kbd className="absolute right-space-sm top-1/2 -translate-y-1/2 rounded bg-surface-container-high px-space-xs py-space-2xs font-label-sm text-label-sm text-on-surface-variant">
              ⌘K
            </kbd>
          </div>
        </div>

        {/* Right controls */}
        <div className="flex items-center gap-space-md">
          <div className="hidden items-center gap-space-xs rounded-full bg-surface-container-low px-space-md py-space-xs font-label-md text-label-md text-on-surface lg:flex">
            <span className="h-2 w-2 rounded-full bg-tertiary" />
            <span>3,420 Active Chargers</span>
          </div>

          <div className="flex cursor-pointer items-center gap-space-xs rounded-lg bg-surface-container-low px-space-sm py-space-xs font-label-md text-label-md text-on-surface-variant transition-colors hover:bg-surface-container hover:text-on-surface">
            <span className="material-symbols-outlined text-base">cloud_done</span>
            <span className="hidden sm:inline">Production · US West</span>
          </div>

          <button
            type="button"
            className="relative flex items-center justify-center p-space-xs text-on-surface-variant hover:text-on-surface"
            aria-label="Notifications"
          >
            <span className="material-symbols-outlined text-xl">notifications</span>
            <span className="absolute right-1 top-1 h-2 w-2 rounded-full bg-error" />
          </button>

          <button
            type="button"
            onClick={handleLogout}
            className="flex items-center gap-space-xs rounded-lg px-space-sm py-space-xs font-label-md text-label-md text-on-surface-variant transition-colors hover:bg-surface-container hover:text-on-surface"
          >
            <span className="material-symbols-outlined text-lg">logout</span>
            <span className="hidden md:inline">Sign out</span>
          </button>

          <span className="flex h-8 w-8 items-center justify-center rounded-full bg-primary/10 font-label-sm text-label-sm text-primary">
            {initials}
          </span>
        </div>
      </div>
    </header>
  )
}
