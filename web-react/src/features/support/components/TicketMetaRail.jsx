import { useState } from 'react'
import { TICKET_STATUSES } from '../data/supportData'
import { cn } from '../../../lib/cn'

function Panel({ children }) {
  return (
    <div className="flex flex-col gap-space-md rounded-xl bg-surface-container-lowest p-space-lg shadow-sm">
      {children}
    </div>
  )
}

function SectionLabel({ children }) {
  return (
    <span className="font-label-sm text-label-sm uppercase tracking-wider text-on-surface-variant">
      {children}
    </span>
  )
}

/**
 * @param {{ ticket: object, detail: object }} props
 */
export default function TicketMetaRail({ ticket, detail }) {
  const [status, setStatus] = useState(ticket.status)

  const { driver, telemetry, sla, tags } = detail

  return (
    <aside className="flex flex-col gap-space-md lg:col-span-3">
      {/* Assignee + status */}
      <Panel>
        <div className="flex flex-col gap-space-2xs">
          <SectionLabel>Assignee</SectionLabel>
          <div className="flex items-center justify-between rounded-lg bg-surface-container-low p-space-sm">
            <div className="flex items-center gap-space-sm">
              <span className="flex h-6 w-6 items-center justify-center rounded-full bg-primary/10 font-label-sm text-[10px] text-primary">
                AC
              </span>
              <div className="flex flex-col">
                <span className="font-label-md text-label-md text-on-surface">Alex Chen (You)</span>
                <span className="font-label-sm text-label-sm text-on-surface-variant">Support Lead</span>
              </div>
            </div>
            <span className="material-symbols-outlined text-sm text-on-surface-variant">unfold_more</span>
          </div>
        </div>

        <div className="flex flex-col gap-space-2xs">
          <SectionLabel>Ticket Status</SectionLabel>
          <div className="grid grid-cols-2 gap-space-2xs rounded-lg bg-surface-container p-space-2xs">
            {TICKET_STATUSES.map((s) => (
              <button
                key={s}
                type="button"
                onClick={() => setStatus(s)}
                className={cn(
                  'rounded py-space-xs text-center font-label-sm text-label-sm transition-colors',
                  status === s
                    ? 'bg-surface-container-lowest font-semibold text-primary shadow-sm'
                    : 'text-on-surface-variant hover:text-on-surface',
                )}
              >
                {s}
              </button>
            ))}
          </div>
        </div>
      </Panel>

      {/* Driver profile */}
      <Panel>
        <div className="flex items-center justify-between">
          <SectionLabel>Driver Profile</SectionLabel>
          <a href="#lookup" className="font-label-sm text-label-sm text-primary hover:underline">
            Lookup Details
          </a>
        </div>
        <div className="flex items-center gap-space-md">
          <span className="flex h-12 w-12 items-center justify-center rounded-full bg-surface-container-high font-headline-sm text-headline-sm text-on-surface">
            {(driver.name ?? '?')
              .split(' ')
              .map((w) => w[0])
              .slice(0, 2)
              .join('')}
          </span>
          <div className="flex flex-col">
            <h4 className="font-headline-sm text-headline-sm text-on-surface">{driver.name}</h4>
            {driver.email && (
              <span className="font-body-sm text-body-sm text-on-surface-variant">{driver.email}</span>
            )}
            {driver.phone && (
              <span className="font-label-sm text-label-sm text-on-surface-variant">{driver.phone}</span>
            )}
          </div>
        </div>

        {driver.tier && (
          <div className="flex flex-col gap-space-xs rounded-lg bg-surface-container-low p-space-sm">
            <div className="flex items-center justify-between">
              <span className="font-label-sm text-label-sm text-on-surface-variant">Driver Tier</span>
              <span className="font-label-sm text-label-sm font-semibold text-primary">{driver.tier}</span>
            </div>
            <div className="flex items-center justify-between">
              <span className="font-label-sm text-label-sm text-on-surface-variant">Lifetime Charges</span>
              <span className="font-label-sm text-label-sm font-semibold text-on-surface">
                {driver.lifetime}
              </span>
            </div>
          </div>
        )}

        {driver.vehicle && (
          <div className="flex flex-col gap-space-2xs">
            <SectionLabel>Registered EV</SectionLabel>
            <div className="flex items-center gap-space-sm rounded-lg bg-surface-container-low p-space-sm">
              <span className="material-symbols-outlined text-xl text-primary">directions_car</span>
              <div className="flex min-w-0 flex-col">
                <span className="truncate font-label-md text-label-md text-on-surface">{driver.vehicle}</span>
                <span className="font-label-sm text-label-sm text-on-surface-variant">VIN: {driver.vin}</span>
                <span className="font-label-sm text-label-sm text-tertiary">Port: {driver.port}</span>
              </div>
            </div>
          </div>
        )}
      </Panel>

      {/* Telemetry */}
      {telemetry && (
        <Panel>
          <div className="flex items-center justify-between">
            <SectionLabel>Charging Telemetry</SectionLabel>
            <span className="rounded bg-surface-container px-space-xs py-space-2xs font-label-sm text-label-sm font-semibold text-on-surface">
              #{telemetry.sessionId}
            </span>
          </div>
          <div className="flex flex-col font-body-sm text-body-sm">
            {telemetry.rows.map((row) => (
              <div key={row.label} className="flex justify-between py-space-2xs">
                <span className={cn('text-on-surface-variant', row.tone && 'font-semibold', row.tone)}>
                  {row.label}
                </span>
                <span className={cn('text-on-surface', row.tone && 'font-semibold', row.tone)}>
                  {row.value}
                </span>
              </div>
            ))}
          </div>

          {telemetry.aiCase && (
            <div className="flex flex-col gap-space-xs rounded-xl bg-primary-fixed/20 p-space-md">
              <div className="flex items-center justify-between">
                <span className="flex items-center gap-space-xs font-label-md text-label-md font-semibold text-primary">
                  <span className="material-symbols-outlined text-sm">bolt</span> Linked AI Case
                </span>
                <span className="rounded bg-secondary-fixed px-space-xs py-space-2xs font-label-sm text-label-sm text-on-secondary-fixed">
                  #{telemetry.aiCase.id}
                </span>
              </div>
              <p className="font-label-sm text-label-sm text-on-surface-variant">{telemetry.aiCase.note}</p>
              <a
                href="#ai-queue"
                className="flex items-center gap-1 font-label-sm text-label-sm font-semibold text-primary hover:underline"
              >
                <span>View in AI Approval Queue</span>
                <span className="material-symbols-outlined text-xs">arrow_forward</span>
              </a>
            </div>
          )}
        </Panel>
      )}

      {/* SLA + tags */}
      <Panel>
        <SectionLabel>SLA Health &amp; Tags</SectionLabel>
        <div className="flex flex-col gap-space-xs">
          <div className="flex justify-between font-label-sm text-label-sm">
            <span className="text-on-surface-variant">Resolution Target</span>
            <span className="font-semibold text-primary">{sla.remaining}</span>
          </div>
          <div className="h-2 w-full overflow-hidden rounded-full bg-surface-container-high">
            <div className="h-full rounded-full bg-primary" style={{ width: `${sla.percent}%` }} />
          </div>
          <div className="flex justify-between pt-space-2xs font-label-sm text-label-sm text-on-surface-variant">
            <span>{sla.firstResponse}</span>
            <span>{sla.target}</span>
          </div>
        </div>

        <div className="flex flex-wrap items-center gap-space-xs pt-space-xs">
          {tags.map((tag) => (
            <span
              key={tag}
              className="flex items-center gap-1 rounded-full bg-surface-container px-space-sm py-space-2xs font-label-sm text-label-sm text-on-surface"
            >
              <span>{tag}</span>
              <span className="material-symbols-outlined cursor-pointer text-xs">close</span>
            </span>
          ))}
          <button
            type="button"
            className="flex items-center gap-1 rounded-full bg-surface-container-high px-space-sm py-space-2xs font-label-sm text-label-sm text-on-surface-variant hover:bg-surface-container"
          >
            <span className="material-symbols-outlined text-xs">add</span> Add Tag
          </button>
        </div>
      </Panel>
    </aside>
  )
}
