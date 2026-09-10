import { useState } from 'react'
import { useLocation, useNavigate } from 'react-router-dom'
import { useAuthStore } from '../../../store/authStore'
import { ROLES, ROUTES } from '../../../lib/constants'
import { defaultRouteForRole } from '../../../routes/roleRoutes'
import { extractApiError } from '../../../lib/apiError'
import { useLogin } from '../hooks/useLogin'
import AuthLayout from '../components/AuthLayout'
import LoginForm from '../components/LoginForm'

/** Roles allowed into the web operator portal (drivers use the mobile app). */
const PORTAL_ROLES = [ROLES.STATION_OWNER, ROLES.ADMIN, ROLES.SUPPORT_MANAGER]

export default function LoginPage() {
  const navigate = useNavigate()
  const location = useLocation()
  const setSession = useAuthStore((s) => s.setSession)
  const login = useLogin()
  const [errorMessage, setErrorMessage] = useState('')

  async function handleSubmit({ email, password }) {
    setErrorMessage('')
    try {
      const session = await login.mutateAsync({ email, password })

      if (!PORTAL_ROLES.includes(session.user.role)) {
        setErrorMessage(
          'This portal is for station operators and platform staff. EV drivers should use the ChargeSync mobile app.',
        )
        return
      }

      setSession(session)
      const target =
        location.state?.from?.pathname ??
        defaultRouteForRole(session.user.role) ??
        ROUTES.DASHBOARD
      navigate(target, { replace: true })
    } catch (err) {
      setErrorMessage(extractApiError(err, 'Invalid email or password.'))
    }
  }

  return (
    <AuthLayout panelVariant="signin">
      <LoginForm
        onSubmit={handleSubmit}
        isSubmitting={login.isPending}
        errorMessage={errorMessage}
      />
    </AuthLayout>
  )
}
