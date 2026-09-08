import { ROLES, ROUTES } from '../lib/constants'

/**
 * Maps each role to the set of top-level routes it may access.
 * ProtectedRoute uses this (and/or an explicit `allowedRoles` prop) to gate access.
 */
export const roleRoutes = {
  [ROLES.DRIVER]: [ROUTES.DASHBOARD, ROUTES.RESERVATIONS, ROUTES.SUPPORT],
  [ROLES.STATION_OWNER]: [
    ROUTES.DASHBOARD,
    ROUTES.STATIONS,
    ROUTES.RESERVATIONS,
    ROUTES.ANALYTICS,
  ],
  [ROLES.SUPPORT_MANAGER]: [ROUTES.DASHBOARD, ROUTES.SUPPORT, ROUTES.RESERVATIONS],
  [ROLES.ADMIN]: [
    ROUTES.DASHBOARD,
    ROUTES.STATIONS,
    ROUTES.RESERVATIONS,
    ROUTES.ANALYTICS,
    ROUTES.APPROVALS,
    ROUTES.SUPPORT,
    ROUTES.USERS,
  ],
}

/**
 * @param {string|null|undefined} role
 * @param {string} pathname
 * @returns {boolean}
 */
export function isRouteAllowedForRole(role, pathname) {
  if (!role) return false
  const allowed = roleRoutes[role] ?? []
  return allowed.some((route) => pathname === route || pathname.startsWith(`${route}/`))
}

/**
 * Landing route per role after login. Each role goes to its primary workspace:
 * Admin -> platform dashboard, StationOwner -> My Stations, etc.
 */
const DEFAULT_ROUTE = {
  [ROLES.ADMIN]: ROUTES.DASHBOARD,
  [ROLES.STATION_OWNER]: ROUTES.STATIONS,
  [ROLES.SUPPORT_MANAGER]: ROUTES.SUPPORT,
  [ROLES.DRIVER]: ROUTES.RESERVATIONS,
}

/** First route a role should land on after login. */
export function defaultRouteForRole(role) {
  return DEFAULT_ROUTE[role] ?? roleRoutes[role]?.[0] ?? ROUTES.LOGIN
}
