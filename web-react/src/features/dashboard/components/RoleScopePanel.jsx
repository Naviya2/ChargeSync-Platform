import { ROLE_SCOPES } from '../data/dashboardData'
import { cn } from '../../../lib/cn'

export default function RoleScopePanel() {
  return (
    <div className="flex flex-col gap-space-md rounded-xl bg-surface-container-lowest p-space-lg shadow-sm">
      <div className="flex items-center justify-between">
        <span className="font-label-sm text-label-sm uppercase tracking-wider text-on-surface-variant">
          Quick Switch Role Scope
        </span>
        <span className="material-symbols-outlined text-base text-on-surface-variant">
          switch_access_shortcut
        </span>
      </div>

      <div className="flex flex-col gap-space-xs">
        {ROLE_SCOPES.map((scope) => (
          <button
            key={scope.key}
            type="button"
            className={cn(
              'flex w-full items-center justify-between rounded-lg p-space-sm text-left transition-all',
              scope.active
                ? 'bg-primary-container text-on-primary-container'
                : 'bg-surface-container-low text-on-surface hover:bg-surface-container',
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
              {scope.active ? 'check' : 'chevron_right'}
            </span>
          </button>
        ))}
      </div>
    </div>
  )
}
