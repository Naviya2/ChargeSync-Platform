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

export default function OverviewTab({ overview }) {
  return (
    <div className="flex flex-col gap-space-lg">
      <div className="grid grid-cols-1 gap-space-md sm:grid-cols-2 lg:grid-cols-4">
        {overview.stats.map((stat) => (
          <OverviewStat key={stat.label} stat={stat} />
        ))}
      </div>

      <div className="flex flex-col gap-space-md rounded-xl bg-surface-container-low p-space-lg">
        <div className="flex flex-col justify-between gap-space-sm sm:flex-row sm:items-center">
          <div>
            <h3 className="font-headline-sm text-headline-sm text-on-surface">
              Live Bay Allocation &amp; Current Flow
            </h3>
            <p className="font-body-sm text-body-sm text-on-surface-variant">
              Real-time status across {overview.bays.length} charging positions.
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
          {overview.bays.map((bay) => (
            <BayCard key={bay.name} bay={bay} />
          ))}
        </div>
      </div>
    </div>
  )
}
