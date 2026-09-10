import { useState } from 'react'
import { useLocation, useNavigate } from 'react-router-dom'
import { useAuthStore } from '../../../store/authStore'
import { ALL_ROLES, ROLES, ROUTES } from '../../../lib/constants'
import { defaultRouteForRole } from '../../../routes/roleRoutes'
import Button from '../../../components/ui/Button'

/**
 * Placeholder login. Sets a mock session in the auth store so the rest of the
 * portal is navigable during development. Replace with the real form + useLogin().
 */
export default function LoginPage() {
  const navigate = useNavigate()
  const location = useLocation()
  const setSession = useAuthStore((s) => s.setSession)
  const [role, setRole] = useState(ROLES.ADMIN)

  const handleSignIn = () => {
    setSession({
      token: `dev-token.${role}.${Date.now()}`,
      user: {
        id: 'dev-user',
        name: `Dev ${role}`,
        email: 'dev@chargesync.local',
        role,
      },
    })
    const target = location.state?.from?.pathname ?? defaultRouteForRole(role) ?? ROUTES.DASHBOARD
    navigate(target, { replace: true })
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-slate-50 p-6">
      <div className="w-full max-w-sm rounded-2xl border border-slate-200 bg-white p-8 shadow-sm">
        <div className="mb-6 flex items-center gap-2">
          <div className="h-9 w-9 rounded-lg bg-brand-gradient" />
          <span className="text-xl font-bold text-brand-gradient">ChargeSync</span>
        </div>
        <h1 className="text-lg font-semibold text-slate-900">Sign in to the admin portal</h1>
        <p className="mt-1 text-sm text-slate-500">Development sign-in — pick a role to continue.</p>

        <label className="mt-6 block text-sm font-medium text-slate-700">Role</label>
        <select
          value={role}
          onChange={(e) => setRole(e.target.value)}
          className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-brand-500 focus:outline-none focus:ring-1 focus:ring-brand-500"
        >
          {ALL_ROLES.map((r) => (
            <option key={r} value={r}>
              {r}
            </option>
          ))}
        </select>

        <Button className="mt-6 w-full" onClick={handleSignIn}>
          Continue
        </Button>
      </div>
    </div>
  )
}
