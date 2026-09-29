import { useAuthStore } from '../../../store/authStore'
import { ROLES } from '../../../lib/constants'
import PlaceholderPage from '../../../components/shared/PlaceholderPage'
import AdminDashboardPage from './AdminDashboardPage'
import StationOwnerDashboardPage from './StationOwnerDashboardPage'

/**
 * Role-aware dashboard entry point at /dashboard.
 * Admins get the full platform dashboard; other roles get a placeholder
 * until their role-specific dashboard is built.
 */
export default function DashboardPage() {
  const role = useAuthStore((s) => s.user?.role)

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
