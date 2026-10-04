
export default function AiGridQueue() {
  return (
    <div className="flex flex-col gap-space-md rounded-xl bg-surface-container-lowest p-space-lg shadow-sm">
      <div className="flex flex-col justify-between gap-space-sm pb-space-sm sm:flex-row sm:items-center">
        <div className="flex items-center gap-space-sm">
          <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-primary-container/15 text-primary">
            <span className="material-symbols-outlined text-lg">auto_awesome</span>
          </div>
          <div>
            <h2 className="font-headline-sm text-headline-sm text-on-surface">
              AI Dynamic Grid &amp; Rate Adjustments
            </h2>
            <p className="font-label-sm text-label-sm text-on-surface-variant">
              Real-time telemetry inference with automatic guardrail triggers
            </p>
          </div>
        </div>
        <span className="inline-flex items-center gap-1.5 self-start rounded-full bg-tertiary-container/10 px-space-sm py-space-2xs font-label-sm text-label-sm text-tertiary sm:self-auto">
          <span className="h-2 w-2 animate-ping rounded-full bg-tertiary" />
          Auto-Pilot Guardrails Active
        </span>
      </div>

      <div className="flex flex-col gap-space-sm">
        <div className="flex flex-col items-center justify-center p-8 text-center text-on-surface-variant bg-surface-container-low rounded-xl">
           <span className="material-symbols-outlined text-4xl mb-2 opacity-50">check_circle</span>
           <p className="font-headline-sm">No Pending Guardrail Actions</p>
           <p className="font-body-sm mt-1">The system is operating within optimal parameters.</p>
        </div>
      </div>

      <div className="flex items-center justify-between pt-space-sm font-label-md text-label-md">
        <span className="text-on-surface-variant">System confidence baseline requirement: ≥ 85%</span>
        <button
          className="inline-flex items-center gap-1 font-semibold text-primary transition-colors hover:text-primary-container"
        >
          <span>View history</span>
          <span className="material-symbols-outlined text-sm">arrow_forward</span>
        </button>
      </div>
    </div>
  )
}
