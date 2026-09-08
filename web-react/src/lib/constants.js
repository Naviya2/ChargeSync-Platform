/**
 * Application-wide constants.
 */

export const ROLES = {
  DRIVER: 'Driver',
  STATION_OWNER: 'StationOwner',
  ADMIN: 'Admin',
  SUPPORT_MANAGER: 'SupportManager',
}

export const ALL_ROLES = Object.values(ROLES)

export const ROUTES = {
  LOGIN: '/login',
  DASHBOARD: '/dashboard',
  STATIONS: '/stations',
  RESERVATIONS: '/reservations',
  ANALYTICS: '/analytics',
  APPROVALS: '/approvals',
  SUPPORT: '/support',
  USERS: '/users',
}

/**
 * Sidebar navigation. `roles` gates visibility; route-level access is
 * enforced separately by ProtectedRoute + roleRoutes.
 */
export const NAV_ITEMS = [
  { label: 'Dashboard', to: ROUTES.DASHBOARD, icon: 'LayoutDashboard', roles: ALL_ROLES },
  { label: 'Stations', to: ROUTES.STATIONS, icon: 'PlugZap', roles: [ROLES.ADMIN, ROLES.STATION_OWNER] },
  { label: 'Reservations', to: ROUTES.RESERVATIONS, icon: 'CalendarClock', roles: ALL_ROLES },
  { label: 'Analytics', to: ROUTES.ANALYTICS, icon: 'BarChart3', roles: [ROLES.ADMIN, ROLES.STATION_OWNER] },
  { label: 'Approvals', to: ROUTES.APPROVALS, icon: 'BadgeCheck', roles: [ROLES.ADMIN] },
  { label: 'Support', to: ROUTES.SUPPORT, icon: 'LifeBuoy', roles: [ROLES.ADMIN, ROLES.SUPPORT_MANAGER, ROLES.DRIVER] },
  { label: 'Users', to: ROUTES.USERS, icon: 'Users', roles: [ROLES.ADMIN] },
]
