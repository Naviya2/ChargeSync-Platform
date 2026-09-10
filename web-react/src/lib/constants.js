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
  LANDING: '/',
  LOGIN: '/login',
  SIGNUP: '/signup',
  DASHBOARD: '/dashboard',
  STATIONS: '/stations',
  RESERVATIONS: '/reservations',
  ANALYTICS: '/analytics',
  APPROVALS: '/approvals',
  SUPPORT: '/support',
  USERS: '/users',
}

/**
 * Sidebar navigation, grouped into sections. `roles` gates visibility;
 * route-level access is enforced separately by ProtectedRoute + roleRoutes.
 * `icon` is a Material Symbols name. `badge` is optional.
 */
export const NAV_SECTIONS = [
  {
    label: 'Console',
    labelByRole: {
      [ROLES.ADMIN]: 'Platform Admin',
      [ROLES.STATION_OWNER]: 'Station Owner Console',
      [ROLES.SUPPORT_MANAGER]: 'Support Console',
      [ROLES.DRIVER]: 'Driver',
    },
    items: [
      { label: 'Dashboard', to: ROUTES.DASHBOARD, icon: 'dashboard', roles: ALL_ROLES },
      {
        label: 'Station Approvals',
        to: ROUTES.APPROVALS,
        icon: 'ev_station',
        roles: [ROLES.ADMIN],
        badge: { text: '4 pending', tone: 'secondary' },
      },
      { label: 'User Management', to: ROUTES.USERS, icon: 'manage_accounts', roles: [ROLES.ADMIN] },
      {
        label: 'Analytics',
        to: ROUTES.ANALYTICS,
        icon: 'analytics',
        roles: [ROLES.ADMIN, ROLES.STATION_OWNER],
      },
      {
        label: 'Support Tickets',
        to: ROUTES.SUPPORT,
        icon: 'headset_mic',
        roles: [ROLES.ADMIN, ROLES.SUPPORT_MANAGER, ROLES.STATION_OWNER],
      },
    ],
  },
  {
    label: 'Operations',
    items: [
      {
        label: 'My Stations',
        to: ROUTES.STATIONS,
        icon: 'storefront',
        roles: [ROLES.ADMIN, ROLES.STATION_OWNER],
      },
      { label: 'Reservations', to: ROUTES.RESERVATIONS, icon: 'event_available', roles: ALL_ROLES },
    ],
  },
]

/** Human-readable labels for each role. */
export const ROLE_LABELS = {
  [ROLES.DRIVER]: 'Driver',
  [ROLES.STATION_OWNER]: 'Station Owner',
  [ROLES.ADMIN]: 'Platform Admin',
  [ROLES.SUPPORT_MANAGER]: 'Support Manager',
}
