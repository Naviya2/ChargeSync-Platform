import StationSparkline from './StationSparkline'
import { cn } from '../../../lib/cn'

const STATUS_TONE = {
  tertiary: 'text-tertiary',
  secondary: 'text-secondary',
  error: 'text-error',
}

const BAR_TONE = {
  tertiary: 'bg-primary',
  secondary: 'bg-secondary',
  error: 'bg-error',
}

/**
 * @param {{ station: object, selected: boolean, onSelect: (id: string) => void }} props
 */
export default function StationCard({ station, selected, onSelect }) {
  const tone = station.status.tone

  return (
    <button
      type="button"
      onClick={() => onSelect(station.id)}
      className={cn(
        'group flex flex-col justify-between overflow-hidden rounded-xl bg-surface-container-lowest text-left shadow-sm transition-all hover:shadow-md',
        selected && 'ring-2 ring-primary',
      )}
    >
      <div className="flex flex-col gap-space-md p-space-lg">
        {/* Map / identity header */}
        <div className="relative h-28 w-full overflow-hidden rounded-lg bg-gradient-to-br from-inverse-surface to-primary-fixed-variant">
          <div className="absolute inset-0 flex items-center justify-center text-inverse-on-surface/30">
            <span className="material-symbols-outlined text-5xl">map</span>
          </div>
          <div className="absolute inset-0 bg-gradient-to-t from-inverse-surface/80 via-inverse-surface/20 to-transparent" />
          <div className="absolute right-space-xs top-space-xs">
            <span
              className={cn(
                'inline-flex items-center gap-1 rounded bg-surface-container-lowest/90 px-space-xs py-space-2xs font-label-sm text-label-sm font-semibold backdrop-blur-sm',
                STATUS_TONE[tone],
              )}
            >
              <span
                className={cn(
                  'h-1.5 w-1.5 rounded-full bg-current',
                  station.status.pulse && 'animate-pulse',
                )}
              />
              {station.status.label}
            </span>
          </div>
          <div className="absolute inset-x-space-sm bottom-space-xs flex items-end justify-between">
            <span className="font-label-sm text-label-sm font-semibold text-inverse-on-surface drop-shadow-sm">
              #{station.id}
            </span>
            <span className="font-label-sm text-label-sm text-primary-fixed drop-shadow-sm">
              {station.sector}
            </span>
          </div>
        </div>

        {/* Name & address */}
        <div>
          <div className="flex items-center justify-between gap-space-sm">
            <h3 className="font-headline-sm text-headline-sm text-on-surface transition-colors group-hover:text-primary">
              {station.name}
            </h3>
            <span className="material-symbols-outlined text-sm text-primary">
              {selected ? 'radio_button_checked' : 'radio_button_unchecked'}
            </span>
          </div>
          <p className="mt-space-2xs flex items-center gap-space-2xs font-body-sm text-body-sm text-on-surface-variant">
            <span className="material-symbols-outlined text-xs">location_on</span>
            {station.address}
          </p>
        </div>

        {/* Ports & specs */}
        <div className="flex flex-col gap-space-xs rounded-lg bg-surface-container-low p-space-sm">
          <div className="flex items-center justify-between font-label-md text-label-md">
            <span className="text-on-surface-variant">Charger Capacity</span>
            <span className="font-semibold text-on-surface">{station.capacity}</span>
          </div>
          <div className="flex items-center justify-between font-label-md text-label-md">
            <span className="text-on-surface-variant">{station.bayLabel}</span>
            <span className={cn('font-semibold', STATUS_TONE[tone] ?? 'text-on-surface')}>
              {station.bayValue}
            </span>
          </div>
          <div className="mt-space-2xs h-1.5 w-full overflow-hidden rounded-full bg-surface-container">
            <div
              className={cn('h-full rounded-full', BAR_TONE[tone] ?? 'bg-primary')}
              style={{ width: `${station.load}%` }}
            />
          </div>
        </div>

        {/* Sparkline */}
        <div className="flex flex-col gap-space-2xs">
          <div className="flex items-center justify-between font-label-sm text-label-sm text-on-surface-variant">
            <span>{station.trendLabel}</span>
            <span className="font-semibold text-on-surface">{station.trendValue}</span>
          </div>
          <StationSparkline tone={station.sparkTone} />
        </div>
      </div>

      {/* Footer */}
      <div className="mt-space-xs flex items-center justify-between bg-surface-container-low px-space-lg py-space-sm">
        <div className="flex flex-col">
          <span className="font-label-sm text-label-sm text-on-surface-variant">{station.footerLabel}</span>
          <span className="font-label-md text-label-md font-semibold text-on-surface">
            {station.footerValue}
          </span>
        </div>
        <span
          className={cn(
            'inline-flex items-center gap-space-2xs font-label-md text-label-md font-semibold',
            selected ? 'text-primary' : 'text-on-surface-variant group-hover:text-primary',
          )}
        >
          {selected ? 'Active View' : 'Details'}
          <span className="material-symbols-outlined text-xs">arrow_forward</span>
        </span>
      </div>
    </button>
  )
}
