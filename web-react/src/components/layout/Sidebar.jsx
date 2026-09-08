import { NavLink } from 'react-router-dom'
import * as Icons from 'lucide-react'
import { NAV_ITEMS } from '../../lib/constants'
import { useAuthStore } from '../../store/authStore'
import { cn } from '../../lib/cn'

export default function Sidebar() {
  const role = useAuthStore((s) => s.user?.role)
  const items = NAV_ITEMS.filter((item) => !role || item.roles.includes(role))

  return (
    <aside className="hidden w-60 shrink-0 flex-col border-r border-slate-200 bg-white md:flex">
      <div className="flex h-16 items-center gap-2 px-5">
        <div className="h-8 w-8 rounded-lg bg-brand-gradient" />
        <span className="text-lg font-bold text-brand-gradient">ChargeSync</span>
      </div>
      <nav className="flex-1 space-y-1 px-3 py-2">
        {items.map((item) => {
          const Icon = Icons[item.icon] ?? Icons.Circle
          return (
            <NavLink
              key={item.to}
              to={item.to}
              className={({ isActive }) =>
                cn(
                  'flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition',
                  isActive
                    ? 'bg-brand-50 text-brand-700'
                    : 'text-slate-600 hover:bg-slate-100 hover:text-slate-900',
                )
              }
            >
              <Icon size={18} />
              {item.label}
            </NavLink>
          )
        })}
      </nav>
    </aside>
  )
}
