import { useNotificationStore } from '../store/notificationStore'

/**
 * Convenience hook for pushing notifications from anywhere in the tree.
 */
export function useNotify() {
  const notify = useNotificationStore((s) => s.notify)
  return {
    notify,
    info: (message, title) => notify({ type: 'info', message, title }),
    success: (message, title) => notify({ type: 'success', message, title }),
    warning: (message, title) => notify({ type: 'warning', message, title }),
    error: (message, title) => notify({ type: 'error', message, title }),
  }
}
