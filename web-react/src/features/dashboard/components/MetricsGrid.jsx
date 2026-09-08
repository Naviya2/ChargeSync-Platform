import { METRICS } from '../data/dashboardData'
import StatSparkline from './StatSparkline'
import StatRadial from './StatRadial'
import { cn } from '../../../lib/cn'

const PILL_TONE = {
  tertiary: 'bg-tertiary-container/10 text-tertiary',
  secondary: 'bg-secondary-container/20 text-secondary',
  error: 'bg-error-container text-on-error-container',
}

const DELTA_TONE = {
  up: 'text-tertiary',
  down: 'text-error',
  neutral: 'text-on-surface-variant',
}

function DeltaIcon({ tone }) {
  if (tone === 'up') return <span className="material-symbols-outlined text-sm">trending_up</span>
  if (tone === 'down') return <span className="material-symbols-outlined text-sm">trending_down</span>
  return <span className="material-symbols-outlined text-sm text-primary">auto_awesome</span>
}

function MetricViz({ metric }) {
  switch (metric.viz) {
    case 'sparkline':
      return <StatSparkline />
    case 'radial':
      return <StatRadial percent={metric.radialPercent} />
    case 'stack':
      return (
        <div className="flex w-20 flex-col gap-1">
          <div className="flex h-2 w-full overflow-hidden rounded-full bg-surface-container">
            <div className="h-full bg-primary" style={{ width: '72%' }} />
            <div className="h-full bg-secondary" style={{ width: '20%' }} />
          </div>
          <span className="text-right font-label-sm text-label-sm text-on-surface-variant">32 bays open</span>
        </div>
      )
    default:
      return (
        <div className="rounded-xl bg-primary-container/10 p-space-sm text-primary">
          <span className="material-symbols-outlined text-xl">psychology</span>
        </div>
      )
  }
}

function MetricCard({ metric }) {
  return (
    <div className="flex flex-col justify-between gap-space-md overflow-hidden rounded-xl bg-surface-container-lowest p-space-lg shadow-sm">
      <div className="flex items-center justify-between">
        <span className="font-label-sm text-label-sm uppercase tracking-wider text-on-surface-variant">
          {metric.label}
        </span>
        {metric.pill ? (
          <span
            className={cn(
              'inline-flex items-center gap-1 rounded-full px-space-xs py-space-2xs font-label-sm text-label-sm',
              PILL_TONE[metric.pill.tone] ?? PILL_TONE.tertiary,
            )}
          >
            {metric.pill.tone !== 'error' && (
              <span className="h-1.5 w-1.5 rounded-full bg-current opacity-70" />
            )}
            {metric.pill.text}
          </span>
        ) : (
          <span className="rounded-lg bg-surface-container p-space-2xs text-primary">
            <span className="material-symbols-outlined text-base">bolt</span>
          </span>
        )}
      </div>

      <div className="flex items-baseline justify-between gap-space-sm">
        <div>
          <p className="font-metric-num-lg text-metric-num-lg text-on-surface">
            {metric.value}
            {metric.unit && (
              <span className="font-headline-sm text-headline-sm font-normal text-on-surface-variant">
                {' '}
                {metric.unit}
              </span>
            )}
          </p>
          <div
            className={cn(
              'mt-space-2xs flex items-center gap-1 font-label-md text-label-md',
              DELTA_TONE[metric.deltaTone],
            )}
          >
            <DeltaIcon tone={metric.deltaTone} />
            <span>{metric.delta}</span>
          </div>
        </div>
        <MetricViz metric={metric} />
      </div>
    </div>
  )
}

export default function MetricsGrid() {
  return (
    <div className="grid grid-cols-1 gap-space-lg sm:grid-cols-2 lg:grid-cols-4">
      {METRICS.map((metric) => (
        <MetricCard key={metric.key} metric={metric} />
      ))}
    </div>
  )
}
