import { cn } from '../../../../lib/cn'

const BAY_STATE_TONE = {
  occupied: 'text-primary',
  available: 'text-tertiary',
  queued: 'text-secondary',
}

function OverviewStat({ stat }) {
  return (
    <div className="flex flex-col justify-between rounded-xl bg-surface-container-low p-space-md">
      <span className="font-label-sm text-label-sm uppercase text-on-surface-variant">{stat.label}</span>
      <div className="mt-space-sm flex items-baseline gap-space-xs">
        <span className={cn('font-metric-num-lg text-metric-num-lg', stat.accent ?? 'text-on-surface')}>
          {stat.value}
        </span>
        {stat.sub && <span className="font-body-md text-body-md text-on-surface-variant">{stat.sub}</span>}
        {stat.delta && (
          <span className="font-label-sm text-label-sm font-semibold text-tertiary">{stat.delta}</span>
        )}
      </div>
      {stat.progress != null ? (
        <div className="mt-space-xs h-1.5 w-full overflow-hidden rounded-full bg-surface-container-high">
          <div className="h-full rounded-full bg-primary" style={{ width: `${stat.progress}%` }} />
        </div>
      ) : (
        stat.note && (
          <span className="mt-space-xs font-body-sm text-body-sm text-on-surface-variant">{stat.note}</span>
        )
      )}
    </div>
  )
}

function BayCard({ bay }) {
  return (
    <div className="flex flex-col justify-between rounded-lg bg-surface-container-lowest p-space-md shadow-sm">
      <div className="flex items-center justify-between">
        <span className="font-headline-sm text-headline-sm text-on-surface">{bay.name}</span>
        <span className={cn('font-label-sm text-label-sm font-semibold', BAY_STATE_TONE[bay.state])}>
          {bay.stateLabel}
        </span>
      </div>
      <p className="mt-space-xs font-label-sm text-label-sm text-on-surface-variant">{bay.spec}</p>
      <div className="mt-space-sm flex items-center justify-between font-label-sm text-label-sm">
        <span className="text-on-surface-variant">{bay.who}</span>
        <span className={cn('font-semibold', bay.metaTone)}>{bay.meta}</span>
      </div>
    </div>
  )
}

export default function OverviewTab({ chargers = [], stationName }) {
  const totalPower = chargers.reduce((sum, ch) => sum + (ch.maxOutputKw || ch.power || 0), 0)
  const availableChargers = chargers.filter(ch => ch.status === 'available' || ch.status === 'Available').length
  
  const stats = [
    {
      label: 'Active Chargers',
      value: availableChargers,
      sub: `/ ${chargers.length}`,
      progress: chargers.length > 0 ? (availableChargers / chargers.length) * 100 : 0
    },
    {
      label: 'Total Power Capacity',
      value: totalPower,
      sub: 'kW',
      note: 'Across all registered bays',
    },
    {
      label: 'Current Energy Draw',
      value: '0',
      sub: 'kW',
      note: 'Real-time telemetry'
    },
    {
      label: 'Total Revenue (Today)',
      value: '$0.00',
      note: 'Updated just now'
    }
  ]

  const bays = chargers.map((ch, idx) => ({
    name: `Bay ${idx + 1}`,
    state: ch.status?.toLowerCase() === 'available' ? 'available' : 'queued',
    stateLabel: ch.status || 'Available',
    spec: `${ch.maxOutputKw || ch.power}kW • ${ch.connectorTypeId || ch.connector}`,
    who: 'No active session',
    meta: ch.id
  }))

  return (
    <div className="flex flex-col gap-space-lg">
      <div className="grid grid-cols-1 gap-space-md sm:grid-cols-2 lg:grid-cols-4">
        {stats.map((stat) => (
          <OverviewStat key={stat.label} stat={stat} />
        ))}
      </div>

      <div className="flex flex-col gap-space-md rounded-xl bg-surface-container-low p-space-lg">
        <div className="flex flex-col justify-between gap-space-sm sm:flex-row sm:items-center">
          <div>
            <h3 className="font-headline-sm text-headline-sm text-on-surface">
              Live Bay Allocation for {stationName}
            </h3>
            <p className="font-body-sm text-body-sm text-on-surface-variant">
              Real-time status across {chargers.length} charging positions.
            </p>
          </div>
          <div className="flex items-center gap-space-md font-label-sm text-label-sm">
            <span className="flex items-center gap-1">
              <span className="h-2 w-2 rounded-full bg-primary" /> In Session
            </span>
            <span className="flex items-center gap-1">
              <span className="h-2 w-2 rounded-full bg-tertiary" /> Available
            </span>
            <span className="flex items-center gap-1">
              <span className="h-2 w-2 rounded-full bg-secondary" /> Queued
            </span>
          </div>
        </div>

        <div className="grid grid-cols-2 gap-space-md md:grid-cols-4">
          {bays.length > 0 ? (
            bays.map((bay) => (
              <BayCard key={bay.name} bay={bay} />
            ))
          ) : (
            <div className="col-span-full text-center text-on-surface-variant py-space-xl">
              No chargers registered yet.
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
