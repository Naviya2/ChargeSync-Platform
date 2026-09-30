import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useReservationsList } from '../../reservations/hooks/useReservations'
import { cn } from '../../../lib/cn'
import AddReservationModal from '../../reservations/components/AddReservationModal'

const STATUS_TONE = {
  tertiary: 'bg-tertiary-container/15 text-tertiary',
  secondary: 'bg-secondary-container/20 text-secondary',
  error: 'bg-error-container text-on-error-container',
  neutral: 'bg-surface-container text-on-surface',
}

const STATUS_DOT = {
  tertiary: 'bg-tertiary',
  secondary: 'bg-secondary',
  error: 'bg-error',
  neutral: 'bg-outline',
}

function StatusPill({ status }) {
  return (
    <span
      className={cn(
        'inline-flex items-center gap-1.5 rounded px-space-xs py-0.5 font-label-sm text-label-sm font-semibold',
        STATUS_TONE[status.tone],
      )}
    >
      <span
        className={cn(
          'h-1.5 w-1.5 rounded-full',
          STATUS_DOT[status.tone],
          status.pulse && 'animate-pulse',
        )}
      />
      {status.label}
    </span>
  )
}

export default function ReservationsTable({ timeframe, customRange, preFilteredReservations }) {
  const [activeFilter, setActiveFilter] = useState('all')
  const [isAddModalOpen, setIsAddModalOpen] = useState(false)
  const navigate = useNavigate()
  const { data, isLoading } = useReservationsList()
  const reservations = preFilteredReservations || data?.items || []

  const filteredReservations = reservations.filter(r => {
    // Time filter (skip if preFiltered)
    if (!preFilteredReservations && timeframe) {
      const resDate = new Date(r.startTime);
      const now = new Date();
      const diffHours = (now - resDate) / (1000 * 60 * 60);
      
      if (timeframe === '24 Hours' && (diffHours > 24 || diffHours < -24)) return false;
      if (timeframe === '7 Days' && (diffHours > 24 * 7 || diffHours < -24 * 7)) return false;
      if (timeframe === '30 Days' && (diffHours > 24 * 30 || diffHours < -24 * 30)) return false;
      if (timeframe === 'Custom Range') {
         if (customRange?.start) {
           const sDate = new Date(customRange.start);
           if (resDate < sDate) return false;
         }
         if (customRange?.end) {
           const eDate = new Date(customRange.end);
           eDate.setDate(eDate.getDate() + 1);
           if (resDate > eDate) return false;
         }
      }
    }

    // Status filter
    if (activeFilter === 'all') return true
    return r.status === activeFilter
  })

  return (
    <div className="flex flex-col gap-space-md rounded-xl bg-surface-container-lowest p-space-lg shadow-sm">
      {/* Header controls */}
      <div className="flex flex-col justify-between gap-space-md lg:flex-row lg:items-center">
        <div className="flex flex-wrap items-center gap-space-xs">
          <button
            type="button"
            onClick={() => setActiveFilter('all')}
            className={cn(
              'rounded-lg px-space-md py-space-xs font-label-md text-label-md transition-colors',
              activeFilter === 'all'
                ? 'bg-on-surface text-surface-container-lowest shadow-sm'
                : 'bg-surface-container-low text-on-surface-variant hover:bg-surface-container hover:text-on-surface',
            )}
          >
            All ({reservations.length})
          </button>
          <button
            type="button"
            onClick={() => setActiveFilter('Confirmed')}
            className={cn(
              'rounded-lg px-space-md py-space-xs font-label-md text-label-md transition-colors',
              activeFilter === 'Confirmed'
                ? 'bg-on-surface text-surface-container-lowest shadow-sm'
                : 'bg-surface-container-low text-on-surface-variant hover:bg-surface-container hover:text-on-surface',
            )}
          >
            Confirmed ({reservations.filter(r => r.status === 'Confirmed').length})
          </button>
          <button
            type="button"
            onClick={() => setActiveFilter('CheckedIn')}
            className={cn(
              'rounded-lg px-space-md py-space-xs font-label-md text-label-md transition-colors',
              activeFilter === 'CheckedIn'
                ? 'bg-on-surface text-surface-container-lowest shadow-sm'
                : 'bg-surface-container-low text-on-surface-variant hover:bg-surface-container hover:text-on-surface',
            )}
          >
            In-Progress ({reservations.filter(r => r.status === 'CheckedIn').length})
          </button>
          <button
            type="button"
            onClick={() => setActiveFilter('Pending')}
            className={cn(
              'rounded-lg px-space-md py-space-xs font-label-md text-label-md transition-colors',
              activeFilter === 'Pending'
                ? 'bg-on-surface text-surface-container-lowest shadow-sm'
                : 'bg-surface-container-low text-on-surface-variant hover:bg-surface-container hover:text-on-surface',
            )}
          >
            Pending Review ({reservations.filter(r => r.status === 'Pending').length})
          </button>
        </div>

        <div className="flex items-center gap-space-sm">
          <div className="relative w-full sm:w-64">
            <span className="material-symbols-outlined absolute left-space-sm top-1/2 -translate-y-1/2 text-base text-on-surface-variant">
              filter_list
            </span>
            <input
              type="text"
              placeholder="Filter reservations..."
              className="w-full rounded-lg bg-surface-container-low py-1.5 pl-8 pr-space-sm font-body-sm text-body-sm text-on-surface focus:outline-none focus:ring-2 focus:ring-primary"
            />
          </div>
          <button
            type="button"
            className="inline-flex items-center gap-1 rounded-lg bg-surface-container-low px-space-md py-1.5 font-label-md text-label-md text-on-surface transition-colors hover:bg-surface-container"
          >
            <span className="material-symbols-outlined text-base">sort</span>
            <span>Sort: Recent</span>
          </button>
          <button
            type="button"
            onClick={() => setIsAddModalOpen(true)}
            className="inline-flex items-center gap-1 rounded-lg bg-primary px-space-md py-1.5 font-label-md text-label-md text-on-primary transition-colors hover:bg-primary/90"
          >
            <span className="material-symbols-outlined text-base">add</span>
            <span>Add Reservation</span>
          </button>
        </div>
      </div>

      {/* Table */}
      <div className="overflow-x-auto">
        <table className="w-full border-collapse text-left">
          <thead>
            <tr className="bg-surface-container-low font-label-sm text-label-sm uppercase tracking-wider text-on-surface-variant">
              <th className="rounded-l-lg px-space-md py-space-sm">Reservation &amp; User</th>
              <th className="px-space-md py-space-sm">Station &amp; Bay</th>
              <th className="px-space-md py-space-sm">Scheduled Window</th>
              <th className="px-space-md py-space-sm">Energy / Cost</th>
              <th className="px-space-md py-space-sm">Role Verification</th>
              <th className="px-space-md py-space-sm">Status</th>
              <th className="rounded-r-lg px-space-md py-space-sm text-right">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-surface-container font-body-sm text-body-sm text-on-surface">
            {isLoading ? (
              <tr><td colSpan="7" className="p-8 text-center text-on-surface-variant">Loading reservations...</td></tr>
            ) : filteredReservations.map((row) => {
              const statusPill = { 
                label: row.status, 
                tone: row.status === 'CheckedIn' ? 'tertiary' : row.status === 'Confirmed' ? 'secondary' : row.status === 'Cancelled' ? 'error' : 'neutral', 
                pulse: row.status === 'CheckedIn' 
              }
              return (
              <tr key={row.id} className="transition-colors hover:bg-surface-container-low/70">
                <td className="px-space-md py-space-md">
                  <div className="flex items-center gap-space-sm">
                    <span
                      className="flex h-8 w-8 items-center justify-center rounded-full text-xs font-bold bg-primary-container text-on-primary-container"
                    >
                      {row.driverName ? row.driverName.substring(0, 2).toUpperCase() : 'U'}
                    </span>
                    <div>
                      <p className="font-headline-sm text-body-sm font-semibold text-on-surface">
                        #{row.id.substring(0, 8)}
                      </p>
                      <p className="font-label-sm text-label-sm text-on-surface-variant">{row.driverName || 'Unknown User'}</p>
                    </div>
                  </div>
                </td>
                <td className="px-space-md py-space-md">
                  <p className="font-headline-sm text-body-sm font-semibold text-on-surface">
                    {row.stationName}
                  </p>
                  <p className="font-label-sm text-label-sm text-on-surface-variant">
                    Charger ID: {row.chargerId}
                  </p>
                </td>
                <td className="px-space-md py-space-md">
                  <p className="font-headline-sm text-body-sm text-on-surface">{new Date(row.startTime).toLocaleString()}</p>
                  <p className="font-label-sm text-label-sm text-on-surface-variant">
                    to {new Date(row.endTime).toLocaleTimeString()}
                  </p>
                </td>
                <td className="px-space-md py-space-md">
                  <p className="font-headline-sm text-body-sm font-semibold text-on-surface">
                    LKR {row.advanceDepositAmount}
                  </p>
                  <p className="font-label-sm text-label-sm text-on-surface-variant">Deposit</p>
                </td>
                <td className="px-space-md py-space-md">
                  <div className="flex items-center gap-1 text-tertiary">
                    <span className="material-symbols-outlined text-sm">verified_user</span>
                    <span className="font-label-sm text-label-sm">Verified</span>
                  </div>
                </td>
                <td className="px-space-md py-space-md">
                  <StatusPill status={statusPill} />
                </td>
                <td className="px-space-md py-space-md text-right">
                  <div className="flex items-center justify-end gap-space-sm">
                    <button 
                      onClick={() => navigate('/reservations')}
                      className="rounded-lg bg-surface-container px-space-sm py-1 font-label-sm text-label-sm font-semibold text-on-surface transition-colors hover:bg-surface-container-high"
                    >
                      Manage
                    </button>
                  </div>
                </td>
              </tr>
            )})}
            {!isLoading && filteredReservations.length === 0 && (
              <tr>
                 <td colSpan="7" className="p-8 text-center text-on-surface-variant">No reservations found.</td>
              </tr>
            )}
          </tbody>
        </table>
    </div>
      {isAddModalOpen && (
        <AddReservationModal
          onClose={() => setIsAddModalOpen(false)}
        />
      )}
    </div>
  )
}
