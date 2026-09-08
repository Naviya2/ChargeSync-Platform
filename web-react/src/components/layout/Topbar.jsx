import { useNavigate } from 'react-router-dom'
import { LogOut } from 'lucide-react'
import { useAuthStore } from '../../store/authStore'
import { ROUTES } from '../../lib/constants'

export default function Topbar() {
  const navigate = useNavigate()
  const user = useAuthStore((s) => s.user)
  const clearSession = useAuthStore((s) => s.clearSession)

  const handleLogout = () => {
    clearSession()
    navigate(ROUTES.LOGIN, { replace: true })
  }

  return (
    <header className="flex h-16 items-center justify-between border-b border-slate-200 bg-white px-6">
      <div className="text-sm text-slate-500">EV Charging Platform · Admin Portal</div>
      <div className="flex items-center gap-4">
        <div className="text-right">
          <p className="text-sm font-medium text-slate-900">{user?.name ?? 'Guest'}</p>
          <p className="text-xs text-slate-500">{user?.role ?? '—'}</p>
        </div>
        <button
          type="button"
          onClick={handleLogout}
          className="inline-flex items-center gap-2 rounded-lg border border-slate-200 px-3 py-1.5 text-sm text-slate-600 hover:bg-slate-100"
        >
          <LogOut size={16} />
          Sign out
        </button>
      </div>
    </header>
  )
}
