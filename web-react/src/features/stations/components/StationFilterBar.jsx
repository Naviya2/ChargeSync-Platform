import { cn } from '../../../lib/cn'

export default function StationFilterBar({ active, onChange, search, onSearchChange, sort, onSortChange, counts = {} }) {
  const FILTERS = [
    { key: 'all', label: 'All Stations', count: counts.all || 0 },
    { key: 'active', label: 'Active', count: counts.active || 0 },
    { key: 'pending', label: 'Pending Approval', count: counts.pending || 0 },
    { key: 'rejected', label: 'Rejected', count: counts.rejected || 0 },
  ];

  return (
    <div className="flex flex-col items-stretch justify-between gap-space-md rounded-xl bg-surface-container-lowest p-space-md shadow-sm lg:flex-row lg:items-center">
      <div className="flex items-center gap-space-2xs overflow-x-auto pb-space-2xs lg:pb-0">
        {FILTERS.map((f) => (
          <button
            key={f.key}
            type="button"
            onClick={() => onChange(f.key)}
            className={cn(
              'whitespace-nowrap rounded-lg px-space-md py-space-xs font-label-md text-label-md transition-all',
              active === f.key
                ? 'bg-primary-container font-semibold text-on-primary-container'
                : 'bg-surface-container-low text-on-surface-variant hover:text-on-surface',
            )}
          >
            {f.label} ({f.count})
          </button>
        ))}
      </div>

      <div className="flex items-center gap-space-sm">
        <div className="relative flex-1 sm:w-64">
          <span className="material-symbols-outlined absolute left-space-sm top-1/2 -translate-y-1/2 text-base text-on-surface-variant">
            search
          </span>
          <input
            type="text"
            value={search}
            onChange={e => onSearchChange?.(e.target.value)}
            placeholder="Search station name, address, ID..."
            className="w-full rounded-lg bg-surface-container-low py-space-xs pl-8 pr-space-md font-body-sm text-body-sm text-on-surface placeholder:text-on-surface-variant focus:bg-surface-container focus:outline-none"
          />
        </div>
        <div className="flex items-center gap-space-xs rounded-lg bg-surface-container-low px-space-sm py-space-xs">
          <span className="font-label-sm text-label-sm text-on-surface-variant">Sort:</span>
          <select
            value={sort}
            onChange={e => onSortChange?.(e.target.value)}
            className="appearance-none cursor-pointer bg-transparent font-label-md text-label-md font-semibold text-on-surface focus:outline-none"
          >
            <option value="name_asc">Name: A to Z</option>
            <option value="name_desc">Name: Z to A</option>
            <option value="status">Status</option>
          </select>
        </div>
      </div>
    </div>
  )
}
