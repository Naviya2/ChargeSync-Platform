import { cn } from '../../../../lib/cn'

const STATE_STYLE = {
  dispensing: { cls: 'bg-secondary/10 text-secondary', dot: 'bg-secondary animate-pulse' },
  available: { cls: 'bg-tertiary/10 text-tertiary', dot: 'bg-tertiary' },
  reserved: { cls: 'bg-surface-container-high text-on-surface', dot: 'bg-secondary' },
}

function ChargerState({ state, label }) {
  const style = STATE_STYLE[state] ?? STATE_STYLE.available
  return (
    <span
      className={cn(
        'inline-flex items-center gap-1.5 rounded-lg px-space-xs py-space-2xs font-label-sm text-label-sm font-semibold',
        style.cls,
      )}
    >
      <span className={cn('h-2 w-2 rounded-full', style.dot)} />
      {label}
    </span>
  )
}

export default function ChargersTab({ chargers }) {
  return (
    <div className="flex flex-col gap-space-md">
      <div className="flex flex-col items-stretch justify-between gap-space-sm sm:flex-row sm:items-center">
        <div className="flex items-center gap-space-sm">
          <h3 className="font-headline-sm text-headline-sm text-on-surface">
            Configured Chargers ({chargers.length} Physical Units)
          </h3>
          <span className="rounded bg-surface-container px-space-xs py-space-2xs font-label-sm text-label-sm text-on-surface-variant">
            OCPP 2.0.1 Compliant
          </span>
        </div>
        <button
          type="button"
          className="inline-flex items-center gap-space-2xs self-start rounded-lg bg-primary px-space-md py-space-2xs font-headline-sm text-headline-sm text-on-primary shadow-sm transition-all hover:bg-primary-container"
        >
          <span className="material-symbols-outlined text-sm">add</span> Add Charger
        </button>
      </div>

      <div className="overflow-x-auto rounded-xl bg-surface-container-lowest">
        <table className="w-full text-left font-body-md text-body-md">
          <thead className="bg-surface-container-low font-label-sm text-label-sm uppercase tracking-wider text-on-surface-variant">
            <tr>
              <th className="px-space-md py-space-sm">Charger ID &amp; Location</th>
              <th className="px-space-md py-space-sm">Connector Type</th>
              <th className="px-space-md py-space-sm">Max Output</th>
              <th className="px-space-md py-space-sm">Tariff Model</th>
              <th className="px-space-md py-space-sm">Current State</th>
              <th className="px-space-md py-space-sm text-right">Actions</th>
            </tr>
          </thead>
          <tbody className="text-on-surface">
            {chargers.map((ch) => (
              <tr key={ch.id} className="transition-colors hover:bg-surface-container-low/70">
                <td className="px-space-md py-space-sm">
                  <div className="flex items-center gap-space-sm">
                    <span className="rounded-lg bg-surface-container p-space-xs text-primary">
                      <span className="material-symbols-outlined text-base">electrical_services</span>
                    </span>
                    <div>
                      <span className="block font-headline-sm text-headline-sm font-semibold text-on-surface">
                        {ch.id}
                      </span>
                      <span className="font-body-sm text-body-sm text-on-surface-variant">{ch.bay}</span>
                    </div>
                  </div>
                </td>
                <td className="px-space-md py-space-sm">
                  <span className="inline-flex items-center rounded bg-surface-container px-space-xs py-space-2xs font-label-md text-label-md font-semibold text-on-surface">
                    {ch.connector}
                  </span>
                </td>
                <td className="px-space-md py-space-sm font-headline-sm text-headline-sm font-semibold">
                  {ch.power}{' '}
                  <span className="font-body-sm text-body-sm font-normal text-on-surface-variant">
                    {ch.voltage}
                  </span>
                </td>
                <td className="px-space-md py-space-sm font-body-sm text-body-sm">
                  <span className="font-semibold text-on-surface">{ch.tariff}</span>
                  <span className={cn('block font-label-sm text-label-sm', ch.tariffTone)}>
                    {ch.tariffType}
                  </span>
                </td>
                <td className="px-space-md py-space-sm">
                  <ChargerState state={ch.state} label={ch.stateLabel} />
                </td>
                <td className="px-space-md py-space-sm text-right">
                  <div className="inline-flex items-center gap-space-2xs">
                    {['settings', 'power_settings_new', 'more_vert'].map((icon) => (
                      <button
                        key={icon}
                        type="button"
                        aria-label={icon}
                        className="rounded p-space-2xs text-on-surface-variant hover:bg-surface-container hover:text-on-surface"
                      >
                        <span className="material-symbols-outlined text-base">{icon}</span>
                      </button>
                    ))}
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}
