import { useAuthStore } from '../../../store/authStore'
import { ROLES } from '../../../lib/constants'
import { cn } from '../../../lib/cn'

export default function RoleScopePanel() {
  const user = useAuthStore((s) => s.user)
  const currentRole = user?.role

  const activeScopes = [
    {
      key: 'admin',
      icon: 'admin_panel_settings',
      title: 'Platform Administrator',
      subtitle: 'Full global tenant controls',
      active: currentRole === ROLES.ADMIN,
      visible: currentRole === ROLES.ADMIN
    },
    {
      key: 'owner',
      icon: 'storefront',
      title: 'Station Owner Portal',
      subtitle: 'Host payout & bay management',
      active: currentRole === ROLES.STATION_OWNER,
      visible: true
    }
  ].filter(s => s.visible)

  return (
    <div className="flex flex-col gap-space-md rounded-xl bg-surface-container-lowest p-space-lg shadow-sm">
      <div className="flex items-center justify-between">
        <span className="font-label-sm text-label-sm uppercase tracking-wider text-on-surface-variant">
          Active Role Scope
        </span>
        <span className="material-symbols-outlined text-base text-on-surface-variant">
          admin_panel_settings
        </span>
      </div>

      <div className="flex flex-col gap-space-xs">
        {activeScopes.map((scope) => (
          <div
            key={scope.key}
            className={cn(
              'flex w-full items-center justify-between rounded-lg p-space-sm text-left transition-all',
              scope.active
                ? 'bg-primary-container text-on-primary-container'
                : 'bg-surface-container-low text-on-surface',
            )}
          >
            <span className="flex items-center gap-space-sm">
              <span
                className={cn(
                  'material-symbols-outlined text-lg',
                  scope.active ? '' : 'text-on-surface-variant',
                )}
              >
                {scope.icon}
              </span>
              <span>
                <span className="block font-label-md text-label-md font-semibold">{scope.title}</span>
                <span
                  className={cn(
                    'block font-label-sm text-label-sm',
                    scope.active ? 'opacity-80' : 'text-on-surface-variant',
                  )}
                >
                  {scope.subtitle}
                </span>
              </span>
            </span>
            <span className="material-symbols-outlined text-sm">
              {scope.active ? 'check' : ''}
            </span>
          </div>
        ))}
      </div>
    </div>
  )
}
