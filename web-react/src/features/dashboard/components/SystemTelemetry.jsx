import { cn } from '../../../lib/cn'

const BAR_TONE = { tertiary: 'bg-tertiary', primary: 'bg-primary' }
const DOT_TONE = { tertiary: 'bg-tertiary', primary: 'bg-primary' }
const VALUE_TONE = { tertiary: 'text-on-surface', primary: 'text-primary' }

export default function SystemTelemetry() {
  return (
    <div className="flex flex-1 flex-col justify-between gap-space-md rounded-xl bg-surface-container-lowest p-space-lg shadow-sm">
      <div className="flex items-center justify-between">
        <span className="font-label-sm text-label-sm uppercase tracking-wider text-on-surface-variant">
          Gateway Infrastructure
        </span>
        <span className="font-label-sm text-label-sm text-tertiary">All Systems Nominal</span>
      </div>

      <div className="flex flex-col gap-space-sm">
        <div className="flex flex-col gap-1">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-space-xs">
              <span className={cn('h-2 w-2 rounded-full', DOT_TONE.tertiary)} />
              <span className="font-body-sm text-body-sm text-on-surface">Backend API Status</span>
            </div>
            <span className={cn('font-label-md text-label-md font-semibold', VALUE_TONE.tertiary)}>
              100.0% Uptime
            </span>
          </div>
          <div className="h-1.5 w-full overflow-hidden rounded-full bg-surface-container">
            <div
              className={cn('h-1.5 rounded-full', BAR_TONE.tertiary)}
              style={{ width: `100%` }}
            />
          </div>
        </div>

        <div className="flex flex-col gap-1">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-space-xs">
              <span className={cn('h-2 w-2 rounded-full', DOT_TONE.tertiary)} />
              <span className="font-body-sm text-body-sm text-on-surface">Payment Gateway (Stripe)</span>
            </div>
            <span className={cn('font-label-md text-label-md font-semibold', VALUE_TONE.tertiary)}>
              Healthy (99.9%)
            </span>
          </div>
          <div className="h-1.5 w-full overflow-hidden rounded-full bg-surface-container">
            <div
              className={cn('h-1.5 rounded-full', BAR_TONE.tertiary)}
              style={{ width: `99%` }}
            />
          </div>
        </div>

        <div className="flex flex-col gap-1">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-space-xs">
              <span className={cn('h-2 w-2 rounded-full', DOT_TONE.primary)} />
              <span className="font-body-sm text-body-sm text-on-surface">DB Connection</span>
            </div>
            <span className={cn('font-label-md text-label-md font-semibold', VALUE_TONE.primary)}>
              4ms Latency
            </span>
          </div>
          <div className="h-1.5 w-full overflow-hidden rounded-full bg-surface-container">
            <div
              className={cn('h-1.5 rounded-full', BAR_TONE.primary)}
              style={{ width: `95%` }}
            />
          </div>
        </div>
      </div>

      <div className="flex items-center justify-between pt-space-xs font-label-sm text-label-sm text-on-surface-variant">
        <span>Cluster: us-west-2 (Oregon)</span>
        <span className="flex items-center gap-1">
          <span className="material-symbols-outlined text-xs text-tertiary">sync</span>
          Synced 3s ago
        </span>
      </div>
    </div>
  )
}
