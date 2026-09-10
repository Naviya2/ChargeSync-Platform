import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuthStore } from '../../../store/authStore'
import { ROUTES } from '../../../lib/constants'
import { defaultRouteForRole } from '../../../routes/roleRoutes'
import { extractApiError } from '../../../lib/apiError'
import { useRegister } from '../hooks/useRegister'
import AuthLayout from '../components/AuthLayout'
import SignUpForm from '../components/SignUpForm'

/**
 * Station-owner sign-up. `POST /api/auth/register` returns a full signed-in
 * session, so a successful sign-up logs the owner straight into their console.
 */
export default function SignUpPage() {
  const navigate = useNavigate()
  const setSession = useAuthStore((s) => s.setSession)
  const register = useRegister()
  const [errorMessage, setErrorMessage] = useState('')

  async function handleSubmit(values) {
    setErrorMessage('')
    try {
      const session = await register.mutateAsync(values)
      setSession(session)
      navigate(defaultRouteForRole(session.user.role) ?? ROUTES.DASHBOARD, { replace: true })
    } catch (err) {
      setErrorMessage(extractApiError(err, 'Could not create your account. Please try again.'))
    }
  }

  return (
    <AuthLayout panelVariant="signup">
      <SignUpForm
        onSubmit={handleSubmit}
        isSubmitting={register.isPending}
        errorMessage={errorMessage}
      />
    </AuthLayout>
  )
}
