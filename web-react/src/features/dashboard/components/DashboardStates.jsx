/** Loading skeleton for the admin dashboard. */
export function DashboardSkeleton() {
  return (
    <div className="flex w-full animate-pulse flex-col gap-space-xl">
      <div className="grid grid-cols-1 gap-space-lg sm:grid-cols-2 lg:grid-cols-4">
        {Array.from({ length: 4 }).map((_, i) => (
          <div key={i} className="h-32 rounded-xl bg-surface-container-high" />
        ))}
      </div>
      <div className="grid grid-cols-1 gap-space-lg lg:grid-cols-12">
        <div className="h-80 rounded-xl bg-surface-container-high lg:col-span-8" />
        <div className="h-80 rounded-xl bg-surface-container-high lg:col-span-4" />
      </div>
      <div className="h-96 rounded-xl bg-surface-container-high" />
    </div>
  )
}

/** Empty state — no telemetry matches the current filters. */
export function DashboardEmpty({ onReset }) {
  return (
    <div className="flex flex-col items-center justify-center rounded-xl bg-surface-container-lowest p-space-3xl text-center shadow-sm">
      <div className="mb-space-md flex h-16 w-16 items-center justify-center rounded-full bg-surface-container text-outline">
        <span className="material-symbols-outlined text-3xl">ev_station</span>
      </div>
      <h3 className="font-headline-md text-headline-md text-on-surface">
        No Reservations or Stations Found
      </h3>
      <p className="mb-space-lg mt-space-2xs max-w-md font-body-md text-body-md text-on-surface-variant">
        There are currently no active telemetry feeds matching your filter criteria. Adjust your
        timeframe or onboard a new charging station location.
      </p>
      <button
        type="button"
        onClick={onReset}
        className="rounded-xl bg-primary px-space-lg py-space-xs font-label-md text-label-md text-on-primary shadow-md transition-all hover:bg-primary-container"
      >
        Reset Filter Views
      </button>
    </div>
  )
}

/** Error state — telemetry gateway unreachable. */
export function DashboardError({ onRetry }) {
  return (
    <div className="flex flex-col items-center justify-center rounded-xl border border-error/30 bg-error-container/20 p-space-3xl text-center">
      <div className="mb-space-md flex h-16 w-16 items-center justify-center rounded-full bg-error-container text-error">
        <span className="material-symbols-outlined text-3xl">error_outline</span>
      </div>
      <h3 className="font-headline-md text-headline-md text-on-error-container">
        Telemetry Gateway Connection Timeout
      </h3>
      <p className="mb-space-lg mt-space-2xs max-w-md font-body-md text-body-md text-on-surface-variant">
        Failed to establish a secure WebSocket handshake with the OCPP Central Relay (Code 504:
        Gateway Timeout). Automated reconnect in progress.
      </p>
      <div className="flex items-center gap-space-sm">
        <button
          type="button"
          onClick={onRetry}
          className="rounded-xl bg-error px-space-lg py-space-xs font-label-md text-label-md text-on-error transition-all hover:brightness-110"
        >
          Retry Ingestion Now
        </button>
        <button
          type="button"
          className="rounded-xl bg-surface-container-lowest px-space-lg py-space-xs font-label-md text-label-md text-on-surface transition-colors hover:bg-surface-container"
        >
          View Relay Logs
        </button>
      </div>
    </div>
  )
}
