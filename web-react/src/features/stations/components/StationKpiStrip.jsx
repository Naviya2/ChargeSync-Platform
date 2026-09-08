import { STATION_KPIS } from '../data/stationsData'

export default function StationKpiStrip() {
  return (
    <div className="grid grid-cols-2 gap-space-md lg:grid-cols-4">
      {STATION_KPIS.map((kpi) => (
        <div
          key={kpi.key}
          className="flex flex-col justify-between rounded-xl bg-surface-container-lowest p-space-lg shadow-sm"
        >
          <div className="flex items-center justify-between">
            <span className="font-label-sm text-label-sm uppercase tracking-wider text-on-surface-variant">
              {kpi.label}
            </span>
            <span className="rounded-lg bg-surface-container-low p-space-2xs text-primary">
              <span className="material-symbols-outlined text-base">{kpi.icon}</span>
            </span>
          </div>

          <div className="mt-space-md flex items-baseline gap-space-xs">
            <span className="font-metric-num-lg text-metric-num-lg text-on-surface">{kpi.value}</span>
            {kpi.highlight && (
              <span className="font-label-sm text-label-sm font-semibold text-tertiary">
                {kpi.highlight}
              </span>
            )}
          </div>

          {kpi.progress != null ? (
            <div className="mt-space-xs h-1.5 w-full overflow-hidden rounded-full bg-surface-container">
              <div className="h-full rounded-full bg-primary" style={{ width: `${kpi.progress}%` }} />
            </div>
          ) : (
            <div className="mt-space-xs font-body-sm text-body-sm text-on-surface-variant">{kpi.sub}</div>
          )}
        </div>
      ))}
    </div>
  )
}
