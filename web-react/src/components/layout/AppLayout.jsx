import { Outlet } from 'react-router-dom'
import Sidebar from './Sidebar'
import Topbar from './Topbar'
import NotificationHost from '../shared/NotificationHost'

export default function AppLayout() {
  return (
    <div className="min-h-screen bg-surface-container-low font-sans text-on-surface">
      <Sidebar />
      <div className="flex min-h-screen flex-col lg:pl-sidebar-width">
        <Topbar />
        <main className="flex-1 p-gutter-mobile lg:p-gutter-desktop">
          <div className="mx-auto max-w-7xl">
            <Outlet />
          </div>
        </main>
      </div>
      <NotificationHost />
    </div>
  )
}
