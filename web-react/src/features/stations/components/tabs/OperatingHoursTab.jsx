import { useState, useEffect } from 'react'
import { useUpdateOperatingHours } from '../../hooks/useStations'

const DAYS = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']

const DAY_TO_INT = {
  'Sunday': 0,
  'Monday': 1,
  'Tuesday': 2,
  'Wednesday': 3,
  'Thursday': 4,
  'Friday': 5,
  'Saturday': 6
}

function DayRow({ row, onChange }) {
  return (
    <div className="flex flex-col justify-between gap-space-sm rounded-xl bg-surface-container-low p-space-md sm:flex-row sm:items-center">
      <div className="flex w-36 items-center gap-space-md">
        <input 
          type="checkbox" 
          checked={row.enabled} 
          onChange={(e) => onChange(row.day, 'enabled', e.target.checked)}
          className="h-4 w-4 rounded accent-primary" 
        />
        <span className="font-headline-sm text-headline-sm font-semibold text-on-surface">{row.day}</span>
      </div>
      <div className="flex max-w-md flex-1 items-center gap-space-sm">
        <label className="flex flex-1 items-center gap-space-2xs">
          <span className="font-label-sm text-label-sm text-on-surface-variant">Open:</span>
          <input
            type="time"
            value={row.open}
            onChange={(e) => onChange(row.day, 'open', e.target.value)}
            disabled={!row.enabled}
            className="rounded-lg bg-surface-container-lowest px-space-sm py-space-2xs font-body-sm text-body-sm text-on-surface focus:outline-none disabled:opacity-50"
          />
        </label>
        <span className="text-on-surface-variant">to</span>
        <label className="flex flex-1 items-center gap-space-2xs">
          <span className="font-label-sm text-label-sm text-on-surface-variant">Close:</span>
          <input
            type="time"
            value={row.close}
            onChange={(e) => onChange(row.day, 'close', e.target.value)}
            disabled={!row.enabled}
            className="rounded-lg bg-surface-container-lowest px-space-sm py-space-2xs font-body-sm text-body-sm text-on-surface focus:outline-none disabled:opacity-50"
          />
        </label>
      </div>
    </div>
  )
}

export default function OperatingHoursTab({ stationId, hours = [] }) {
  const [schedule, setSchedule] = useState([])
  const updateHoursMutation = useUpdateOperatingHours()

  useEffect(() => {
    // Initialize schedule from API data or defaults
    const initialSchedule = DAYS.map(day => {
      const dayInt = DAY_TO_INT[day]
      const existing = hours.find(h => h.dayOfWeek === dayInt || h.dayOfWeek === day || h.day === day)
      return {
        day,
        enabled: existing ? existing.isEnabled !== false && existing.enabled !== false : true,
        open: (existing?.openTime || existing?.open || '06:00:00').substring(0, 5),
        close: (existing?.closeTime || existing?.close || '22:00:00').substring(0, 5),
      }
    })
    setSchedule(initialSchedule)
  }, [hours])

  const handleChange = (day, field, value) => {
    setSchedule(prev => prev.map(row => 
      row.day === day ? { ...row, [field]: value } : row
    ))
  }

  const handleCopyMonday = () => {
    const monday = schedule.find(r => r.day === 'Monday')
    if (!monday) return
    setSchedule(prev => prev.map(row => 
      ['Tuesday', 'Wednesday', 'Thursday', 'Friday'].includes(row.day)
        ? { ...row, enabled: monday.enabled, open: monday.open, close: monday.close }
        : row
    ))
  }

  const handleSave = () => {
    // Format to match requested backend structure
    const data = schedule.map(row => ({
      stationId,
      dayOfWeek: DAY_TO_INT[row.day],
      openTime: row.open.length === 5 ? `${row.open}:00` : row.open,
      closeTime: row.close.length === 5 ? `${row.close}:00` : row.close,
      isEnabled: row.enabled
    }))
    
    updateHoursMutation.mutate({ stationId, data }, {
      onSuccess: () => alert('Schedule saved successfully'),
      onError: () => alert('Failed to save schedule')
    })
  }

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
      </div>

      <div className="flex items-center justify-between">
        <span className="font-label-sm text-label-sm font-semibold uppercase tracking-wider text-on-surface-variant">
          Weekly Timetable
        </span>
        <button
          type="button"
          onClick={handleCopyMonday}
          className="inline-flex items-center gap-1 font-label-md text-label-md font-semibold text-primary hover:underline"
        >
          <span className="material-symbols-outlined text-xs">content_copy</span> Copy Monday to all
          weekdays
        </button>
      </div>

      <div className="flex flex-col gap-space-xs">
        {schedule.map((row) => (
          <DayRow key={row.day} row={row} onChange={handleChange} />
        ))}
      </div>

      <div className="flex justify-end gap-space-sm">
        <button
          type="button"
          className="rounded-lg bg-surface-container-low px-space-md py-space-xs font-label-md text-label-md text-on-surface hover:bg-surface-container"
        >
          Discard Changes
        </button>
        <button
          type="button"
          onClick={handleSave}
          disabled={updateHoursMutation.isPending}
          className="rounded-lg bg-primary px-space-md py-space-xs font-headline-sm text-headline-sm text-on-primary shadow-sm hover:bg-primary/90 disabled:opacity-50"
        >
          {updateHoursMutation.isPending ? 'Saving...' : 'Save Access Schedule'}
        </button>
      </div>
    </div>
  )
}

