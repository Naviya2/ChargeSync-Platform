import { useState, useEffect, useRef, useMemo } from 'react'
import { format } from 'date-fns'
import { useReservationsList } from '../hooks/useReservations'
import PageHeader from '../../../components/shared/PageHeader'
import { Card, Spinner } from '../../../components/ui'
import ReservationDetailsModal from '../components/ReservationDetailsModal'
import AddReservationModal from '../components/AddReservationModal'
import { useNotificationStore } from '../../../store/notificationStore'
import PendingApprovalsCard from '../../stations/components/PendingApprovalsCard'

// Consistent status badge colors (light & dark mode aware via CSS overrides)
const STATUS_STYLES = {
  Pending:   { bg: 'bg-yellow-100 text-yellow-800', dot: 'bg-yellow-400' },
  Confirmed: { bg: 'bg-blue-100 text-blue-800',     dot: 'bg-blue-500'   },
  CheckedIn: { bg: 'bg-indigo-100 text-indigo-800', dot: 'bg-indigo-500' },
  Completed: { bg: 'bg-green-100 text-green-800',   dot: 'bg-green-500'  },
  Cancelled: { bg: 'bg-red-100 text-red-800',       dot: 'bg-red-400'    },
}

export default function ReservationsPage() {
  const [selectedId, setSelectedId] = useState(null)
  const [search, setSearch] = useState('')
  const [sortOrder, setSortOrder] = useState('time_desc')
  const [showPendingOnly, setShowPendingOnly] = useState(false)
  const notify = useNotificationStore((s) => s.notify)
  const prevCountRef = useRef(0)
  const prevStatusRef = useRef({})
  const [isAddModalOpen, setIsAddModalOpen] = useState(false)

  const { data, isLoading, isError } = useReservationsList({}, { refetchInterval: 10000 })
  const reservations = data?.items || []

  const filtered = reservations.filter((r) => {
    if (showPendingOnly && r.status !== 'Pending') return false
    
    const q = search.toLowerCase()
    return (
      !q ||
      (r.driverName || '').toLowerCase().includes(q) ||
      (r.stationName || '').toLowerCase().includes(q) ||
      r.id?.toLowerCase().includes(q)
    )
  })

  const sortedAndFiltered = useMemo(() => {
    return [...filtered].sort((a, b) => {
      if (sortOrder === 'time_desc') return new Date(b.startTime) - new Date(a.startTime);
      if (sortOrder === 'time_asc') return new Date(a.startTime) - new Date(b.startTime);
      if (sortOrder === 'status') return (a.status || '').localeCompare(b.status || '');
      if (sortOrder === 'customer') return (a.driverName || '').localeCompare(b.driverName || '');
      return 0;
    });
  }, [filtered, sortOrder]);

  useEffect(() => {
    // Notifications are now handled globally in AppLayout.jsx via GlobalReservationWatcher
  }, [])

  return (
    <div className="space-y-6">
      <PageHeader
        title="Reservations"
        description="Manage upcoming and past charging slot reservations."
      />
      
      <PendingApprovalsCard />

      {/* Search and Sort bar */}
      <div className="flex w-full flex-col sm:flex-row items-center gap-4">
        <div className="relative w-full sm:max-w-md">
          <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-lg text-gray-400">
            search
          </span>
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search by customer, station, or ID..."
            className="w-full rounded-xl border border-gray-200 bg-white py-2.5 pl-10 pr-10 text-sm text-gray-900 placeholder:text-gray-400 shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 transition"
          />
          {search && (
            <button
              onClick={() => setSearch('')}
              className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
            >
              <span className="material-symbols-outlined text-base">close</span>
            </button>
          )}
        </div>
        
        <div className="flex items-center gap-space-xs rounded-xl border border-gray-200 bg-white px-space-sm py-2 shadow-sm w-full sm:w-auto">
          <span className="material-symbols-outlined text-base text-gray-400 pl-1">sort</span>
          <select
            value={sortOrder}
            onChange={e => setSortOrder(e.target.value)}
            className="appearance-none cursor-pointer bg-transparent text-sm text-gray-700 focus:outline-none w-full pr-6"
          >
            <option value="time_desc">Newest First</option>
            <option value="time_asc">Oldest First</option>
            <option value="status">Status</option>
            <option value="customer">Customer Name</option>
          </select>
        </div>

        <button
          onClick={() => setShowPendingOnly(!showPendingOnly)}
          className={`flex items-center gap-2 rounded-xl border px-3 py-2 text-sm font-medium transition shadow-sm w-full sm:w-auto ${
            showPendingOnly 
              ? 'border-amber-300 bg-amber-50 text-amber-700' 
              : 'border-gray-200 bg-white text-gray-700 hover:bg-gray-50'
          }`}
        >
          <span className="material-symbols-outlined text-base">pending_actions</span>
          Pending Approvals
        </button>
        
        <button
          onClick={() => setIsAddModalOpen(true)}
          className="ml-auto inline-flex items-center gap-2 rounded-lg bg-primary px-space-md py-1.5 font-label-md text-label-md text-on-primary shadow-sm hover:bg-primary/90 transition-colors"
        >
          <span className="material-symbols-outlined text-[18px]">add</span>
          Add Reservation
        </button>
      </div>

      <Card className="overflow-hidden p-0">
        {isLoading ? (
          <div className="flex flex-col items-center gap-2 py-16">
            <Spinner size={28} />
            <p className="text-sm text-gray-400">Loading reservations…</p>
          </div>
        ) : isError ? (
          <div className="flex flex-col items-center gap-2 py-16 text-center">
            <span className="material-symbols-outlined text-4xl text-red-400">error_outline</span>
            <p className="text-red-500 font-medium">Failed to load reservations.</p>
          </div>
        ) : sortedAndFiltered.length === 0 ? (
          <div className="flex flex-col items-center gap-2 py-16 text-center">
            <span className="material-symbols-outlined text-4xl text-gray-300">event_busy</span>
            <p className="text-gray-400 text-sm">{search ? 'No matching reservations found.' : 'No reservations yet.'}</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead>
                <tr className="bg-gray-50 border-b border-gray-100">
                  <th className="px-6 py-3.5 text-xs font-semibold uppercase tracking-wider text-gray-500">Customer</th>
                  <th className="px-6 py-3.5 text-xs font-semibold uppercase tracking-wider text-gray-500">Station / Charger</th>
                  <th className="px-6 py-3.5 text-xs font-semibold uppercase tracking-wider text-gray-500">Time Window</th>
                  <th className="px-6 py-3.5 text-xs font-semibold uppercase tracking-wider text-gray-500">Status</th>
                  <th className="px-6 py-3.5 text-xs font-semibold uppercase tracking-wider text-gray-500">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-50">
                {sortedAndFiltered.map((res) => {
                  const statusStyle = STATUS_STYLES[res.status] || { bg: 'bg-gray-100 text-gray-600', dot: 'bg-gray-400' }
                  return (
                    <tr key={res.id} className="bg-white hover:bg-gray-50 transition-colors">
                      {/* Customer */}
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-2.5">
                          <div className="flex h-8 w-8 items-center justify-center rounded-full bg-blue-50 text-blue-600 shrink-0 text-xs font-bold">
                            {(res.driverName || 'W').charAt(0).toUpperCase()}
                          </div>
                          <span className="font-medium text-gray-900">
                            {res.driverId ? (res.driverName || 'Registered Driver') : 'Walk-In'}
                          </span>
                        </div>
                      </td>

                      {/* Station */}
                      <td className="px-6 py-4">
                        <div className="font-medium text-gray-900">{res.stationName || 'Unknown Station'}</div>
                        <div className="text-xs text-gray-400 mt-0.5">
                          {res.chargerName || `Charger: ${res.chargerId?.substring(0, 8)}…`}
                        </div>
                      </td>

                      {/* Time */}
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-gray-900 font-medium">{format(new Date(res.startTime), 'MMM d, yyyy')}</div>
                        <div className="text-xs text-gray-400 mt-0.5">
                          {format(new Date(res.startTime), 'HH:mm')} – {format(new Date(res.endTime), 'HH:mm')}
                        </div>
                      </td>

                      {/* Status */}
                      <td className="px-6 py-4">
                        <span className={`inline-flex items-center gap-1.5 rounded-full px-2.5 py-0.5 text-xs font-semibold ${statusStyle.bg}`}>
                          <span className={`h-1.5 w-1.5 rounded-full ${statusStyle.dot}`} />
                          {res.status}
                        </span>
                      </td>

                      {/* Action */}
                      <td className="px-6 py-4">
                        <button
                          onClick={() => setSelectedId(res.id)}
                          className="inline-flex items-center gap-1.5 rounded-lg border border-gray-200 bg-white px-3 py-1.5 text-xs font-semibold text-gray-700 shadow-sm transition hover:bg-gray-50 hover:border-gray-300 hover:text-gray-900 focus:outline-none"
                        >
                          <span className="material-symbols-outlined text-sm">open_in_new</span>
                          View Details
                        </button>
                      </td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          </div>
        )}
      </Card>

      {selectedId && (
        <ReservationDetailsModal
          reservationId={selectedId}
          onClose={() => setSelectedId(null)}
        />
      )}

      {isAddModalOpen && (
        <AddReservationModal
          onClose={() => setIsAddModalOpen(false)}
        />
      )}
    </div>
  )
}
