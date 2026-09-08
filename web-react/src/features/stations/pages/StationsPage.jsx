import { useAuthStore } from '../../../store/authStore'
import { ROLES } from '../../../lib/constants'
import PlaceholderPage from '../../../components/shared/PlaceholderPage'
import MyStationsPage from './MyStationsPage'

/**
 * Role-aware /stations entry point.
 * Station Owners get the full "My Stations" workspace; other roles get a
 * placeholder until their stations view is built.
 */
export default function StationsPage() {
  const role = useAuthStore((s) => s.user?.role)

  if (role === ROLES.STATION_OWNER) {
    return <MyStationsPage />
  }

  return (
    <PlaceholderPage
      title="Stations"
      description="Manage charging stations, connectors, and availability."
    />
  )
}
