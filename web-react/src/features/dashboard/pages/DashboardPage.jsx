import { useAuthStore } from '../../../store/authStore'
import { ROLES } from '../../../lib/constants'
import PlaceholderPage from '../../../components/shared/PlaceholderPage'
import AdminDashboardPage from './AdminDashboardPage'
import StationOwnerDashboardPage from './StationOwnerDashboardPage'
import SupportManagerDashboardPage from './SupportManagerDashboardPage'

/**
 * Role-aware dashboard entry point at /dashboard.
 * Admins, station owners and support managers get their own dashboards.
 */
export default function DashboardPage() {
  const role = useAuthStore((s) => s.user?.role)

  if (role === ROLES.SUPPORT_MANAGER) {
    return <SupportManagerDashboardPage />
  }

  if (role === ROLES.ADMIN) {
    return <AdminDashboardPage />
  }

  if (role === ROLES.STATION_OWNER) {
    return <StationOwnerDashboardPage />
  }

  return (
    <PlaceholderPage
      title="Dashboard"
      description="Your role-specific dashboard is coming soon."
    />
  )
}
