export default function StationsHeader() {
  return (
    <div className="flex flex-col justify-between gap-space-md md:flex-row md:items-center">
      <div className="flex flex-col">
        <div className="flex items-center gap-space-xs text-primary">
          <span className="material-symbols-outlined text-base">ev_station</span>
          <span className="font-label-sm text-label-sm font-semibold uppercase tracking-wider">
            Asset Orchestration
          </span>
        </div>
        <h1 className="mt-space-2xs font-display-lg text-headline-lg tracking-tight text-on-surface md:text-display-lg">
          My Charging Stations
        </h1>
        <p className="max-w-2xl font-body-md text-body-md text-on-surface-variant">
          Manage physical charging assets, live bays, dynamic pricing rules, and scheduled
          maintenance windows across your fleet network.
        </p>
      </div>

      <div className="flex items-center gap-space-sm self-start md:self-auto">
        <button
          type="button"
          className="inline-flex items-center gap-space-xs rounded-xl bg-surface-container-lowest px-space-md py-space-xs font-label-md text-label-md text-on-surface shadow-sm transition-colors hover:bg-surface-container"
        >
          <span className="material-symbols-outlined text-base">file_download</span>
          Export Network Data
        </button>
        <button
          type="button"
          className="inline-flex items-center gap-space-xs rounded-xl bg-primary px-space-lg py-space-xs font-headline-sm text-headline-sm text-on-primary shadow-sm transition-all hover:bg-primary-container"
        >
          <span className="material-symbols-outlined text-base">add_circle</span>
          Add Station
        </button>
      </div>
    </div>
  )
}
