import { useState } from 'react'
import { cn } from '../../../../lib/cn'

const NOTE_TONE = {
  primary: 'text-primary',
  secondary: 'text-secondary',
}

function DayRow({ row }) {
  return (
    <div className="flex flex-col justify-between gap-space-sm rounded-xl bg-surface-container-low p-space-md sm:flex-row sm:items-center">
      <div className="flex w-36 items-center gap-space-md">
        <input type="checkbox" defaultChecked={row.enabled} className="h-4 w-4 rounded accent-primary" />
        <span className="font-headline-sm text-headline-sm font-semibold text-on-surface">{row.day}</span>
      </div>
      <div className="flex max-w-md flex-1 items-center gap-space-sm">
        <label className="flex flex-1 items-center gap-space-2xs">
          <span className="font-label-sm text-label-sm text-on-surface-variant">Open:</span>
          <input
            type="time"
            defaultValue={row.open}
            className="rounded-lg bg-surface-container-lowest px-space-sm py-space-2xs font-body-sm text-body-sm text-on-surface focus:outline-none"
          />
        </label>
        <span className="text-on-surface-variant">to</span>
        <label className="flex flex-1 items-center gap-space-2xs">
          <span className="font-label-sm text-label-sm text-on-surface-variant">Close:</span>
          <input
            type="time"
            defaultValue={row.close}
            className="rounded-lg bg-surface-container-lowest px-space-sm py-space-2xs font-body-sm text-body-sm text-on-surface focus:outline-none"
          />
        </label>
      </div>
      <span
        className={cn(
          'inline-flex items-center gap-1 rounded bg-surface-container px-space-xs py-space-2xs font-label-sm text-label-sm font-semibold',
          NOTE_TONE[row.noteTone] ?? 'text-on-surface',
        )}
      >
        {row.noteTone === 'primary' && <span className="material-symbols-outlined text-xs">bolt</span>}
        {row.note}
      </span>
    </div>
  )
}

export default function OperatingHoursTab({ hours }) {
  const [mode, setMode] = useState('custom')

  return (
    <div className="flex flex-col gap-space-lg">
      <div className="flex flex-col justify-between gap-space-md rounded-xl bg-surface-container-low p-space-md sm:flex-row sm:items-center">
        <div>
          <h3 className="font-headline-sm text-headline-sm text-on-surface">
            Station Operating Hours &amp; Access Policy
          </h3>
          <p className="font-body-sm text-body-sm text-on-surface-variant">
            Configure automated gate lockouts, driver access times, and time-of-use peak tariff shifts.
          </p>
        </div>
        <div className="flex items-center gap-space-xs rounded-xl bg-surface-container-lowest p-space-2xs shadow-sm">
          <button
            type="button"
            onClick={() => setMode('247')}
            className={cn(
              'rounded-lg px-space-md py-space-xs font-label-md text-label-md transition-all',
              mode === '247' ? 'bg-primary font-semibold text-on-primary' : 'text-on-surface-variant',
            )}
          >
            24/7 Unrestricted
          </button>
          <button
            type="button"
            onClick={() => setMode('custom')}
            className={cn(
              'rounded-lg px-space-md py-space-xs font-label-md text-label-md transition-all',
              mode === 'custom' ? 'bg-primary font-semibold text-on-primary' : 'text-on-surface-variant',
            )}
          >
            Custom Weekly Schedule
          </button>
        </div>
      </div>

      {mode === 'custom' && (
        <>
          <div className="flex items-center justify-between">
            <span className="font-label-sm text-label-sm font-semibold uppercase tracking-wider text-on-surface-variant">
              Weekly Timetable
            </span>
            <button
              type="button"
              className="inline-flex items-center gap-1 font-label-md text-label-md font-semibold text-primary hover:underline"
            >
              <span className="material-symbols-outlined text-xs">content_copy</span> Copy Monday to all
              weekdays
            </button>
          </div>

          <div className="flex flex-col gap-space-xs">
            {hours.map((row) => (
              <DayRow key={row.day} row={row} />
            ))}
          </div>

          <div className="flex justify-end gap-space-sm">
            <button
              type="button"
              className="rounded-lg bg-surface-container-low px-space-md py-space-xs font-label-md text-label-md text-on-surface"
            >
              Discard Changes
            </button>
            <button
              type="button"
              className="rounded-lg bg-primary px-space-md py-space-xs font-headline-sm text-headline-sm text-on-primary shadow-sm"
            >
              Save Access Schedule
            </button>
          </div>
        </>
      )}

      {mode === '247' && (
        <div className="rounded-xl bg-surface-container-low p-space-lg font-body-md text-body-md text-on-surface-variant">
          This station is open 24/7 with no gate lockouts. Switch to a custom schedule to set access
          windows and peak tariff shifts.
        </div>
      )}
    </div>
  )
}
