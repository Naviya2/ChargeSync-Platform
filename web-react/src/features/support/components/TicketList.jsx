import TicketListItem from './TicketListItem'

/**
 * @param {{ tickets: object[], selectedId: string, onSelect: (id: string) => void }} props
 */
export default function TicketList({ tickets, selectedId, onSelect }) {
  return (
    <section className="flex flex-col overflow-hidden rounded-xl bg-surface-container-lowest shadow-sm lg:col-span-4">
      <div className="flex items-center justify-between bg-surface-container-low p-space-md">
        <div className="flex items-center gap-space-sm">
          <input type="checkbox" className="h-4 w-4 rounded accent-primary" />
          <span className="font-label-sm text-label-sm uppercase tracking-wider text-on-surface-variant">
            Queue feed ({tickets.length})
          </span>
        </div>
        <div className="flex items-center gap-space-xs">
          <button
            type="button"
            aria-label="Refresh feed"
            className="rounded p-space-2xs text-on-surface-variant hover:bg-surface-container"
          >
            <span className="material-symbols-outlined text-base">refresh</span>
          </button>
          <button
            type="button"
            aria-label="Batch mark done"
            className="rounded p-space-2xs text-on-surface-variant hover:bg-surface-container"
          >
            <span className="material-symbols-outlined text-base">done_all</span>
          </button>
        </div>
      </div>

      <div className="flex max-h-[820px] flex-col overflow-y-auto">
        {tickets.length === 0 ? (
          <div className="p-space-3xl text-center font-body-sm text-body-sm text-on-surface-variant">
            No tickets match this filter.
          </div>
        ) : (
          tickets.map((ticket) => (
            <TicketListItem
              key={ticket.id}
              ticket={ticket}
              selected={ticket.id === selectedId}
              onSelect={onSelect}
            />
          ))
        )}
      </div>
    </section>
  )
}
