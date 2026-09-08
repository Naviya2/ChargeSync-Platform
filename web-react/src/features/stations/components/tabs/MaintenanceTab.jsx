import { cn } from '../../../../lib/cn'

function MaintenanceItem({ item }) {
  return (
    <div className="flex flex-col justify-between gap-space-md rounded-xl bg-surface-container-low p-space-lg md:flex-row md:items-center">
      <div className="flex items-start gap-space-md">
        <div className={cn('shrink-0 rounded-xl bg-surface-container p-space-sm', item.iconTone)}>
          <span className="material-symbols-outlined text-xl">{item.icon}</span>
        </div>
        <div className="flex flex-col">
          <div className="flex flex-wrap items-center gap-space-sm">
            <span className="font-headline-sm text-headline-sm font-semibold text-on-surface">
              {item.title}
            </span>
            <span
              className={cn(
                'rounded bg-surface-container px-space-xs py-space-2xs font-label-sm text-label-sm font-semibold',
                item.statusTone,
              )}
            >
              {item.status}
            </span>
          </div>
          <p className="mt-space-2xs font-body-sm text-body-sm text-on-surface-variant">{item.body}</p>
          <div className="mt-space-xs flex flex-wrap items-center gap-space-md font-label-sm text-label-sm text-on-surface-variant">
            <span className="flex items-center gap-1">
              <span className="material-symbols-outlined text-xs">ev_station</span> Chargers: {item.chargers}
            </span>
            <span className="flex items-center gap-1">
              <span className="material-symbols-outlined text-xs">schedule</span> {item.when}
            </span>
          </div>
        </div>
      </div>

      <div className="flex items-center gap-space-xs self-end md:self-center">
        {item.actions.map((action) => (
          <button
            key={action}
            type="button"
            className="rounded-lg bg-surface-container-lowest px-space-sm py-space-xs font-label-md text-label-md text-on-surface shadow-sm hover:bg-surface-container"
          >
            {action}
          </button>
        ))}
      </div>
    </div>
  )
}

export default function MaintenanceTab({ maintenance }) {
  return (
    <div className="flex flex-col gap-space-md">
      <div className="flex flex-col justify-between gap-space-sm sm:flex-row sm:items-center">
        <div>
          <h3 className="font-headline-sm text-headline-sm text-on-surface">
            Scheduled &amp; Upcoming Maintenance Windows
          </h3>
          <p className="font-body-sm text-body-sm text-on-surface-variant">
            Planned hardware recalibration, liquid coolant purges, and utility substation tests.
          </p>
        </div>
        <button
          type="button"
          className="inline-flex items-center gap-space-2xs rounded-lg bg-primary px-space-md py-space-2xs font-headline-sm text-headline-sm text-on-primary shadow-sm transition-all hover:bg-primary-container"
        >
          <span className="material-symbols-outlined text-sm">calendar_month</span> Schedule Maintenance
          Window
        </button>
      </div>

      <div className="mt-space-2xs flex flex-col gap-space-md">
        {maintenance.map((item) => (
          <MaintenanceItem key={item.title} item={item} />
        ))}
      </div>
    </div>
  )
}
