import { SUPPORT_HEALTH } from '../data/supportData'
import { cn } from '../../../lib/cn'

const TONE = {
  primary: 'bg-primary-fixed/30 text-on-primary-fixed-variant',
  tertiary: 'bg-tertiary-container/15 text-tertiary',
  neutral: 'bg-surface-container text-on-surface-variant',
}

export default function SupportHeader() {
  return (
    <header className="flex flex-col justify-between gap-space-md rounded-xl bg-surface-container-lowest p-space-lg shadow-sm xl:flex-row xl:items-center">
      <div className="flex flex-col gap-space-md sm:flex-row sm:items-center">
        <div className="flex items-center gap-space-xs font-label-md text-label-md text-on-surface-variant">
          <span>Support Console</span>
          <span className="material-symbols-outlined text-sm">chevron_right</span>
          <span className="font-headline-sm text-headline-sm text-on-surface">Ticket Queue</span>
        </div>

        <div className="flex flex-wrap items-center gap-space-xs">
          {SUPPORT_HEALTH.map((chip) => (
            <div
              key={chip.key}
              className={cn(
                'flex items-center gap-space-xs rounded-full px-space-md py-space-2xs font-label-sm text-label-sm',
                TONE[chip.tone],
              )}
            >
              {chip.dot && <span className="h-2 w-2 animate-pulse rounded-full bg-primary" />}
              {chip.icon && <span className="material-symbols-outlined text-xs">{chip.icon}</span>}
              <span>{chip.label}</span>
            </div>
          ))}
        </div>
      </div>

      <div className="flex items-center gap-space-sm self-start xl:self-auto">
        <button
          type="button"
          className="flex items-center gap-space-xs rounded-lg bg-surface-container px-space-md py-space-xs font-label-md text-label-md text-on-surface transition-all hover:bg-surface-container-high"
        >
          <span className="material-symbols-outlined text-base">file_download</span>
          <span>Export CSV</span>
        </button>
        <button
          type="button"
          className="flex items-center gap-space-xs rounded-lg bg-gradient-to-r from-primary to-tertiary px-space-lg py-space-xs font-label-md text-label-md text-on-primary shadow-sm transition-all hover:brightness-105"
        >
          <span className="material-symbols-outlined text-base">add</span>
          <span>Create Ticket</span>
        </button>
      </div>
    </header>
  )
}
