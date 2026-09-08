import { X } from 'lucide-react'
import { useNotificationStore } from '../../store/notificationStore'
import { cn } from '../../lib/cn'

const TONE = {
  info: 'border-slate-200 bg-white text-slate-800',
  success: 'border-brand-200 bg-brand-50 text-brand-800',
  warning: 'border-amber-200 bg-amber-50 text-amber-800',
  error: 'border-red-200 bg-red-50 text-red-800',
}

/**
 * Renders the global notification queue from the Zustand notification store.
 */
export default function NotificationHost() {
  const notifications = useNotificationStore((s) => s.notifications)
  const dismiss = useNotificationStore((s) => s.dismiss)

  if (notifications.length === 0) return null

  return (
    <div className="pointer-events-none fixed bottom-4 right-4 z-50 flex w-80 flex-col gap-2">
      {notifications.map((n) => (
        <div
          key={n.id}
          className={cn(
            'pointer-events-auto flex items-start gap-3 rounded-lg border p-3 shadow-sm',
            TONE[n.type] ?? TONE.info,
          )}
        >
          <div className="min-w-0 flex-1">
            {n.title && <p className="text-sm font-semibold">{n.title}</p>}
            <p className="text-sm">{n.message}</p>
          </div>
          <button type="button" onClick={() => dismiss(n.id)} className="shrink-0 opacity-60 hover:opacity-100">
            <X size={16} />
          </button>
        </div>
      ))}
    </div>
  )
}
