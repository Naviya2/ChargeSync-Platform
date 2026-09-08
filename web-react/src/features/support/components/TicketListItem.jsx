import { PRIORITY_TONE, STATUS_TONE } from '../data/supportData'
import { cn } from '../../../lib/cn'

/**
 * @param {{ ticket: object, selected: boolean, onSelect: (id: string) => void }} props
 */
export default function TicketListItem({ ticket, selected, onSelect }) {
  return (
    <button
      type="button"
      onClick={() => onSelect(ticket.id)}
      className={cn(
        'relative w-full border-b border-surface-container px-space-md py-space-md text-left transition-all',
        selected
          ? 'bg-gradient-to-r from-primary/10 via-surface-container-lowest to-surface-container-lowest shadow-md'
          : 'bg-surface-container-lowest hover:bg-surface-container-low/60',
        ticket.dim && !selected && 'opacity-85',
      )}
    >
      {selected && <span className="absolute inset-y-0 left-0 w-1 bg-primary" />}

      <div className="mb-space-xs flex items-center justify-between">
        <div className="flex flex-wrap items-center gap-space-xs">
          <span
            className={cn(
              'font-label-sm text-label-sm font-semibold',
              selected ? 'text-primary' : 'text-on-surface-variant',
            )}
          >
            #{ticket.id}
          </span>
          <span
            className={cn(
              'flex items-center gap-1 rounded px-space-xs py-space-2xs font-label-sm text-label-sm',
              PRIORITY_TONE[ticket.priority],
            )}
          >
            {ticket.priority === 'Urgent' && (
              <span className="h-1.5 w-1.5 animate-ping rounded-full bg-error" />
            )}
            {ticket.priority}
          </span>
          <span
            className={cn(
              'rounded px-space-xs py-space-2xs font-label-sm text-label-sm',
              STATUS_TONE[ticket.status],
            )}
          >
            {ticket.status}
          </span>
        </div>
        <span className="shrink-0 font-label-sm text-label-sm text-on-surface-variant">{ticket.age}</span>
      </div>

      <h3 className="mb-space-2xs line-clamp-1 font-headline-sm text-headline-sm text-on-surface">
        {ticket.title}
      </h3>
      <p className="mb-space-sm line-clamp-2 font-body-sm text-body-sm text-on-surface-variant">
        {ticket.preview}
      </p>

      <div className="flex items-center justify-between">
        <div className="flex min-w-0 items-center gap-space-xs">
          <span className="flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-surface-container-high font-label-sm text-[10px] text-on-surface">
            {ticket.initials}
          </span>
          <span className="truncate font-label-md text-label-md text-on-surface">{ticket.customer}</span>
          {ticket.customerTag && (
            <span className="rounded bg-surface-container px-space-xs py-space-2xs font-label-sm text-label-sm text-on-surface-variant">
              {ticket.customerTag}
            </span>
          )}
        </div>
        <span className={cn('flex items-center gap-1 font-label-sm text-label-sm font-semibold', ticket.slaTone)}>
          {ticket.slaTone === 'text-error' && <span className="material-symbols-outlined text-xs">timer</span>}
          {ticket.sla}
        </span>
      </div>
    </button>
  )
}
