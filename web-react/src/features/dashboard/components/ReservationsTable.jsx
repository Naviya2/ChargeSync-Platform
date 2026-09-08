import { useState } from 'react'
import { RESERVATION_FILTERS, RESERVATIONS } from '../data/dashboardData'
import { cn } from '../../../lib/cn'

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

export default function ReservationsTable() {
  const [activeFilter, setActiveFilter] = useState('all')

  return (
    <div className="flex flex-col gap-space-md rounded-xl bg-surface-container-lowest p-space-lg shadow-sm">
      {/* Header controls */}
      <div className="flex flex-col justify-between gap-space-md lg:flex-row lg:items-center">
        <div className="flex flex-wrap items-center gap-space-xs">
          {RESERVATION_FILTERS.map((f) => (
            <button
              key={f.key}
              type="button"
              onClick={() => setActiveFilter(f.key)}
              className={cn(
                'rounded-lg px-space-md py-space-xs font-label-md text-label-md transition-colors',
                activeFilter === f.key
                  ? 'bg-on-surface text-surface-container-lowest shadow-sm'
                  : 'bg-surface-container-low text-on-surface-variant hover:bg-surface-container hover:text-on-surface',
              )}
            >
              {f.label} ({f.count.toLocaleString()})
            </button>
          ))}
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
            {RESERVATIONS.map((row) => (
              <tr key={row.id} className="transition-colors hover:bg-surface-container-low/70">
                <td className="px-space-md py-space-md">
                  <div className="flex items-center gap-space-sm">
                    <span
                      className={cn(
                        'flex h-8 w-8 items-center justify-center rounded-full text-xs font-bold',
                        row.avatarTone,
                      )}
                    >
                      {row.initials}
                    </span>
                    <div>
                      <p className="font-headline-sm text-body-sm font-semibold text-on-surface">
                        #{row.id}
                      </p>
                      <p className="font-label-sm text-label-sm text-on-surface-variant">{row.user}</p>
                    </div>
                  </div>
                </td>
                <td className="px-space-md py-space-md">
                  <p className="font-medium text-on-surface">{row.station}</p>
                  <p className="font-label-sm text-label-sm text-on-surface-variant">{row.stationMeta}</p>
                </td>
                <td className="px-space-md py-space-md">
                  <p className="text-on-surface">{row.window}</p>
                  <p className="font-label-sm text-label-sm text-on-surface-variant">{row.windowMeta}</p>
                </td>
                <td className="px-space-md py-space-md">
                  <p className="font-semibold text-on-surface">{row.energy}</p>
                  <p className="font-label-sm text-label-sm text-on-surface-variant">{row.cost}</p>
                </td>
                <td className="px-space-md py-space-md">
                  <span className={cn('inline-flex items-center gap-1 font-label-md text-label-md', row.verification.tone)}>
                    <span className="material-symbols-outlined text-sm">{row.verification.icon}</span>
                    {row.verification.text}
                  </span>
                </td>
                <td className="px-space-md py-space-md">
                  <StatusPill status={row.status} />
                </td>
                <td className="px-space-md py-space-md text-right">
                  <div className="inline-flex items-center gap-space-xs">
                    <button
                      type="button"
                      className={cn(
                        'rounded px-space-sm py-1 font-label-sm text-label-sm transition-colors',
                        row.action === 'Intervene'
                          ? 'bg-error-container text-on-error-container hover:brightness-95'
                          : 'bg-surface-container-high text-on-surface hover:bg-surface-container-highest',
                      )}
                    >
                      {row.action}
                    </button>
                    <button
                      type="button"
                      aria-label="View telemetry"
                      className="rounded p-1 text-on-surface-variant transition-colors hover:text-primary"
                    >
                      <span className="material-symbols-outlined text-base">monitoring</span>
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Pagination */}
      <div className="flex flex-col items-center justify-between gap-space-sm pt-space-sm font-label-md text-label-md text-on-surface-variant sm:flex-row">
        <span>
          Showing <strong className="text-on-surface">1–4</strong> of{' '}
          <strong className="text-on-surface">2,410</strong> live bookings
        </span>
        <div className="flex items-center gap-space-xs">
          <button
            type="button"
            disabled
            className="rounded-lg bg-surface-container-low px-space-sm py-1 text-on-surface opacity-40"
          >
            Previous
          </button>
          <button type="button" className="rounded-lg bg-primary px-space-sm py-1 font-semibold text-on-primary">
            1
          </button>
          <button type="button" className="rounded-lg px-space-sm py-1 text-on-surface transition-colors hover:bg-surface-container">
            2
          </button>
          <button type="button" className="rounded-lg px-space-sm py-1 text-on-surface transition-colors hover:bg-surface-container">
            3
          </button>
          <span className="px-1 text-on-surface-variant">…</span>
          <button type="button" className="rounded-lg px-space-sm py-1 text-on-surface transition-colors hover:bg-surface-container">
            241
          </button>
          <button
            type="button"
            className="rounded-lg bg-surface-container-low px-space-sm py-1 text-on-surface transition-colors hover:bg-surface-container"
          >
            Next
          </button>
        </div>
      </div>
    </div>
  )
}
