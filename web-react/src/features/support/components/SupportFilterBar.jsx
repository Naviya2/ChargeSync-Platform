import { TICKET_FILTERS } from '../data/supportData'
import { cn } from '../../../lib/cn'

/**
 * @param {{ active: string, onChange: (key: string) => void }} props
 */
export default function SupportFilterBar({ active, onChange }) {
  return (
    <section className="flex flex-col items-stretch justify-between gap-space-md rounded-xl bg-surface-container-lowest p-space-md shadow-sm lg:flex-row lg:items-center">
      <div className="flex min-w-0 flex-1 items-center gap-space-md">
        <div className="relative w-full max-w-lg">
          <span className="material-symbols-outlined absolute left-space-md top-1/2 -translate-y-1/2 text-base text-on-surface-variant">
            search
          </span>
          <input
            type="text"
            placeholder="Search tickets by ID, driver name, vehicle VIN, or keyword..."
            className="w-full rounded-lg bg-surface-container-low py-space-xs pl-9 pr-8 font-body-sm text-body-sm text-on-surface placeholder:text-on-surface-variant focus:bg-surface-container-lowest focus:outline-none focus:ring-1 focus:ring-primary"
          />
          <span className="material-symbols-outlined absolute right-space-sm top-1/2 -translate-y-1/2 cursor-pointer text-sm text-on-surface-variant">
            tune
          </span>
        </div>

        <div className="hidden items-center gap-space-2xs 2xl:flex">
          {TICKET_FILTERS.map((f) => (
            <button
              key={f.key}
              type="button"
              onClick={() => onChange(f.key)}
              className={cn(
                'whitespace-nowrap rounded-lg px-space-md py-space-2xs font-label-sm text-label-sm transition-colors',
                active === f.key
                  ? 'bg-primary-container text-on-primary shadow-sm'
                  : f.tone === 'error'
                    ? 'bg-error-container text-on-error-container'
                    : 'bg-surface-container text-on-surface-variant hover:bg-surface-container-high',
              )}
            >
              {f.label} <span className="ml-space-2xs opacity-80">{f.count}</span>
            </button>
          ))}
        </div>
      </div>

      <div className="flex items-center gap-space-sm self-end lg:self-auto">
        <div className="flex cursor-pointer items-center gap-space-xs rounded-lg bg-surface-container-low px-space-md py-space-xs font-label-md text-label-md text-on-surface-variant hover:bg-surface-container">
          <span className="material-symbols-outlined text-sm">flag</span>
          <span>Priority: All</span>
          <span className="material-symbols-outlined text-sm">expand_more</span>
        </div>
        <div className="flex cursor-pointer items-center gap-space-xs rounded-lg bg-surface-container-low px-space-md py-space-xs font-label-md text-label-md text-on-surface-variant hover:bg-surface-container">
          <span className="material-symbols-outlined text-sm">swap_vert</span>
          <span>Sort: Urgency / Newest</span>
          <span className="material-symbols-outlined text-sm">expand_more</span>
        </div>
      </div>
    </section>
  )
}
