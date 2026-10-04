import { useAuthStore } from '../../../store/authStore'
import { ROLES } from '../../../lib/constants'
import PlaceholderPage from '../../../components/shared/PlaceholderPage'
import MyStationsPage from './MyStationsPage'

export default function StationsPage() {
  const role = useAuthStore((s) => s.user?.role)

  if (role === ROLES.STATION_OWNER) {
    return <MyStationsPage />
  }

  if (role === ROLES.ADMIN) {
    return <MyStationsPage isAdmin={true} />
  }

  return (
    <PlaceholderPage
      title="Stations"
      description="Manage charging stations, connectors, and availability."
    />
  )
}
