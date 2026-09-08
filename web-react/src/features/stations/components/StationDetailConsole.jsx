import { useState } from 'react'
import { DETAIL_TABS, STATION_DETAILS } from '../data/stationsData'
import OverviewTab from './tabs/OverviewTab'
import ChargersTab from './tabs/ChargersTab'
import OperatingHoursTab from './tabs/OperatingHoursTab'
import MaintenanceTab from './tabs/MaintenanceTab'
import { cn } from '../../../lib/cn'

/**
 * @param {{ station: object }} props
 */
export default function StationDetailConsole({ station }) {
  const [activeTab, setActiveTab] = useState('chargers')
  const detail = STATION_DETAILS[station.id]

  if (!detail) {
    return (
      <div className="rounded-xl bg-surface-container-lowest p-space-3xl text-center shadow-md">
        <p className="font-headline-sm text-headline-sm text-on-surface">No console data</p>
        <p className="font-body-sm text-body-sm text-on-surface-variant">
          Detail telemetry for {station.name} is not available yet.
        </p>
      </div>
    )
  }

  const tabCount = {
    chargers: detail.chargers.length,
    maintenance: detail.maintenance.length,
  }

  return (
    <div className="mt-space-md flex flex-col overflow-hidden rounded-xl bg-surface-container-lowest shadow-md">
      {/* Sub-header */}
      <div className="flex flex-col justify-between gap-space-md bg-surface-container-low p-space-lg md:flex-row md:items-center">
        <div className="flex flex-col gap-space-2xs">
          <div className="flex items-center gap-space-xs font-label-sm text-label-sm text-on-surface-variant">
            <span>My Stations</span>
            <span>/</span>
            <span className="font-semibold text-on-surface">{station.name}</span>
            <span className="font-mono text-outline-variant">#{station.id}</span>
          </div>
          <div className="flex flex-wrap items-center gap-space-sm">
            <h2 className="font-headline-lg text-headline-lg text-on-surface">{station.name}</h2>
            <span className="inline-flex items-center gap-1 rounded bg-tertiary-container/20 px-space-xs py-space-2xs font-label-sm text-label-sm font-semibold text-tertiary">
              <span className="h-1.5 w-1.5 rounded-full bg-tertiary" /> {detail.statusLabel}
            </span>
            {detail.tags.map((tag) => (
              <span
                key={tag}
                className="rounded bg-surface-container px-space-xs py-space-2xs font-label-sm text-label-sm text-on-surface-variant"
              >
                {tag}
              </span>
            ))}
          </div>
          <p className="font-body-sm text-body-sm text-on-surface-variant">{detail.subtitle}</p>
        </div>

        <div className="flex flex-wrap items-center gap-space-xs self-start md:self-center">
          <button
            type="button"
            className="inline-flex items-center gap-space-2xs rounded-lg bg-surface-container-lowest px-space-md py-space-xs font-label-md text-label-md text-on-surface shadow-sm transition-colors hover:bg-surface-container"
          >
            <span className="material-symbols-outlined text-sm">edit</span> Edit Station Info
          </button>
          <button
            type="button"
            className="inline-flex items-center gap-space-2xs rounded-lg bg-surface-container-lowest px-space-md py-space-xs font-label-md text-label-md text-on-surface shadow-sm transition-colors hover:bg-surface-container"
          >
            <span className="material-symbols-outlined text-sm">download</span> Export Station Logs
          </button>
          <button
            type="button"
            className="inline-flex items-center gap-space-2xs rounded-lg bg-error-container px-space-md py-space-xs font-label-md text-label-md text-on-error-container transition-colors hover:bg-error hover:text-on-error"
          >
            <span className="material-symbols-outlined text-sm">restart_alt</span> Remote Reset
          </button>
        </div>
      </div>

      {/* Tab nav */}
      <div className="flex items-center gap-space-xs overflow-x-auto bg-surface-container-low px-space-lg">
        {DETAIL_TABS.map((tab) => {
          const count = tabCount[tab.key]
          const isActive = activeTab === tab.key
          return (
            <button
              key={tab.key}
              type="button"
              onClick={() => setActiveTab(tab.key)}
              className={cn(
                'whitespace-nowrap px-space-md py-space-sm font-headline-sm text-headline-sm transition-all',
                isActive
                  ? 'font-semibold text-primary shadow-[inset_0_-2px_0_0_currentColor]'
                  : 'text-on-surface-variant hover:text-on-surface',
              )}
            >
              {tab.label}
              {count != null && ` (${count})`}
            </button>
          )
        })}
      </div>

      {/* Panel */}
      <div className="p-space-lg">
        {activeTab === 'overview' && <OverviewTab overview={detail.overview} />}
        {activeTab === 'chargers' && <ChargersTab chargers={detail.chargers} />}
        {activeTab === 'operating-hours' && <OperatingHoursTab hours={detail.hours} />}
        {activeTab === 'maintenance' && <MaintenanceTab maintenance={detail.maintenance} />}
      </div>
    </div>
  )
}
