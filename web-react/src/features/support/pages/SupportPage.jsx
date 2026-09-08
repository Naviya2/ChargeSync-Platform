import { useAuthStore } from '../../../store/authStore'
import { ROLES } from '../../../lib/constants'
import PlaceholderPage from '../../../components/shared/PlaceholderPage'
import SupportInboxPage from './SupportInboxPage'

/**
 * Role-aware /support entry point.
 * Support Managers get the full ticket-queue workspace; other roles get a
 * placeholder until their support view is built.
 */
export default function SupportPage() {
  const role = useAuthStore((s) => s.user?.role)

  if (role === ROLES.SUPPORT_MANAGER) {
    return <SupportInboxPage />
  }

  return (
    <PlaceholderPage
      title="Support"
      description="Customer support tickets and conversation history."
    />
  )
}
