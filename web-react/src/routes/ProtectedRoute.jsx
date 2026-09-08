import { Navigate, Outlet, useLocation } from 'react-router-dom'
import { useAuthStore } from '../store/authStore'
import { isRouteAllowedForRole, defaultRouteForRole } from './roleRoutes'
import { ROUTES } from '../lib/constants'

/**
 * Route guard.
 *
 * - Unauthenticated users are redirected to /login (with `from` state).
 * - Authenticated users lacking access are redirected to their default route.
 *
 * Access is granted if EITHER:
 *   - `allowedRoles` is provided and includes the user's role, OR
 *   - `allowedRoles` is omitted and roleRoutes permits the current pathname.
 *
 * @param {{ allowedRoles?: string[], children?: React.ReactNode }} props
 */
export default function ProtectedRoute({ allowedRoles, children }) {
  const location = useLocation()
  const token = useAuthStore((s) => s.token)
  const role = useAuthStore((s) => s.user?.role)

  if (!token) {
    return <Navigate to={ROUTES.LOGIN} replace state={{ from: location }} />
  }

  const authorized =
    allowedRoles && allowedRoles.length > 0
      ? allowedRoles.includes(role)
      : isRouteAllowedForRole(role, location.pathname)

  if (!authorized) {
    return <Navigate to={defaultRouteForRole(role)} replace />
  }

  return children ?? <Outlet />
}
