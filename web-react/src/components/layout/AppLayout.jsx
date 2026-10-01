import { Outlet } from 'react-router-dom'
import { useEffect, useRef } from 'react'
import Sidebar from './Sidebar'
import Topbar from './Topbar'
import NotificationHost from '../shared/NotificationHost'
import { useReservationsList } from '../../features/reservations/hooks/useReservations'
import { useNotificationStore } from '../../store/notificationStore'

function GlobalReservationWatcher() {
  const notify = useNotificationStore((s) => s.notify)
  const prevCountRef = useRef(0)
  const prevStatusRef = useRef({})

  const { data } = useReservationsList({}, { refetchInterval: 10000 })
  const reservations = data?.items || []

  useEffect(() => {
    if (reservations.length > 0) {
      if (prevCountRef.current > 0 && reservations.length > prevCountRef.current) {
        notify({ title: 'New Reservation', message: 'A driver just booked a new slot.', type: 'info' })
      }
      prevCountRef.current = reservations.length
      
      const prevStatuses = prevStatusRef.current;
      reservations.forEach(res => {
        const prevStatus = prevStatuses[res.id];
        if (prevStatus && prevStatus !== 'Cancelled' && res.status === 'Cancelled') {
          notify({ 
            title: 'Reservation Cancelled', 
            message: `Reservation at ${res.stationName} for ${res.driverName || 'driver'} was cancelled.`, 
            type: 'warning' 
          });
        }
        prevStatuses[res.id] = res.status;
      });
    }
  }, [reservations, notify])

  return null
}
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
      <GlobalReservationWatcher />
    </div>
  )
}
