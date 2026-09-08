import { useAuthStore } from '../store/authStore'

/**
 * Convenience hook exposing the current auth session and helpers.
 */
export function useAuth() {
  const token = useAuthStore((s) => s.token)
  const user = useAuthStore((s) => s.user)
  const setSession = useAuthStore((s) => s.setSession)
  const clearSession = useAuthStore((s) => s.clearSession)

  return {
    token,
    user,
    role: user?.role ?? null,
    isAuthenticated: Boolean(token),
    setSession,
    clearSession,
  }
}
