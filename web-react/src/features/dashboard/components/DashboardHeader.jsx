import { useState } from 'react'
import { TIMEFRAMES } from '../data/dashboardData'
import { cn } from '../../../lib/cn'

export default function DashboardHeader() {
  const [timeframe, setTimeframe] = useState(TIMEFRAMES[0])

  return (
    <div className="flex flex-col justify-between gap-space-lg lg:flex-row lg:items-center">
      <div className="flex flex-col">
        <div className="flex items-center gap-space-sm">
          <h1 className="font-headline-lg text-headline-lg text-on-surface">Platform Overview</h1>
          <span className="inline-flex items-center gap-1 rounded-full bg-tertiary-container/15 px-space-xs py-space-2xs font-label-sm text-label-sm text-tertiary">
            <span className="h-1.5 w-1.5 animate-pulse rounded-full bg-tertiary" />
            Live Ingestion
          </span>
        </div>
        <p className="font-body-md text-body-md text-on-surface-variant">
          Live network telemetry, AI recommendation dispatch, and multi-tenant station metrics
        </p>
      </div>

      <div className="flex flex-wrap items-center gap-space-md">
        <div className="inline-flex rounded-xl bg-surface-container p-space-2xs shadow-sm">
          {TIMEFRAMES.map((tf) => (
            <button
              key={tf}
              type="button"
              onClick={() => setTimeframe(tf)}
              className={cn(
                'rounded-lg px-space-md py-space-xs font-label-md text-label-md transition-all',
                timeframe === tf
                  ? 'bg-primary text-on-primary shadow-sm'
                  : 'text-on-surface-variant hover:text-on-surface',
              )}
            >
              {tf}
            </button>
          ))}
        </div>

        <div className="flex items-center gap-space-sm">
          <button
            type="button"
            className="inline-flex items-center gap-space-xs rounded-xl bg-surface-container-lowest px-space-md py-space-xs font-label-md text-label-md text-on-surface shadow-sm transition-all hover:bg-surface-container"
          >
            <span className="material-symbols-outlined text-base">download</span>
            <span>Export Audit Log</span>
          </button>
          <button
            type="button"
            className="inline-flex items-center gap-space-xs rounded-xl bg-gradient-to-r from-primary to-tertiary px-space-lg py-space-xs font-label-md text-label-md text-on-primary shadow-md transition-all hover:brightness-105"
          >
            <span className="material-symbols-outlined text-base">add_circle</span>
            <span>New Station Onboarding</span>
          </button>
        </div>
      </div>
    </div>
  )
}
