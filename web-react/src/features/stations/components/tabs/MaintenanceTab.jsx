import { useState } from 'react'
import { cn } from '../../../../lib/cn'
import { useAddMaintenanceWindow } from '../../hooks/useStations'

import { useUpdateMaintenanceWindow } from '../../hooks/useStations'

const toLocalDatetimeString = (dateStr) => {
  if (!dateStr) return '';
  const date = new Date(dateStr);
  const offset = date.getTimezoneOffset() * 60000;
  return new Date(date.getTime() - offset).toISOString().slice(0, 16);
};

function MaintenanceItem({ item, stationId }) {
  const [isEditing, setIsEditing] = useState(false)
  const updateMaintenance = useUpdateMaintenanceWindow()
  
  const [form, setForm] = useState({
    reason: item.reason || '',
    startTime: toLocalDatetimeString(item.startTime),
    endTime: toLocalDatetimeString(item.endTime)
  })

  const handleSubmit = (e) => {
    e.preventDefault()
    updateMaintenance.mutate(
      { 
        maintenanceId: item.id,
        stationId,
        data: {
          id: item.id,
          reason: form.reason,
          startTime: new Date(form.startTime).toISOString(),
          endTime: new Date(form.endTime).toISOString()
        }
      },
      {
        onSuccess: () => setIsEditing(false),
        onError: (err) => {
          const msg = err.response?.data?.title || err.response?.data?.message || JSON.stringify(err.response?.data) || err.message;
          alert(`Failed to update maintenance window: ${msg}`);
        }
      }
    )
  }

  if (isEditing) {
    return (
      <form onSubmit={handleSubmit} className="flex flex-col gap-space-md rounded-xl bg-surface-container-low p-space-lg">
        <h4 className="font-headline-sm text-headline-sm text-on-surface">Edit Maintenance Window</h4>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-space-md">

          <div className="flex flex-col gap-space-2xs">
            <label className="font-label-sm text-label-sm text-on-surface">Description / Reason</label>
            <input
              type="text"
              className="rounded border border-outline bg-surface px-space-md py-space-sm text-on-surface"
              value={form.reason}
              onChange={(e) => setForm({ ...form, reason: e.target.value })}
            />
          </div>
          <div className="flex flex-col gap-space-2xs">
            <label className="font-label-sm text-label-sm text-on-surface">Start Time</label>
            <input
              type="datetime-local"
              required
              className="rounded border border-outline bg-surface px-space-md py-space-sm text-on-surface"
              value={form.startTime}
              onChange={(e) => setForm({ ...form, startTime: e.target.value })}
            />
          </div>
          <div className="flex flex-col gap-space-2xs">
            <label className="font-label-sm text-label-sm text-on-surface">End Time</label>
            <input
              type="datetime-local"
              required
              className="rounded border border-outline bg-surface px-space-md py-space-sm text-on-surface"
              value={form.endTime}
              onChange={(e) => setForm({ ...form, endTime: e.target.value })}
            />
          </div>
        </div>
        <div className="flex items-center gap-space-sm self-end mt-space-sm">
          <button
            type="button"
            onClick={() => setIsEditing(false)}
            className="rounded-lg bg-surface-container-highest px-space-md py-space-xs font-label-md text-label-md text-on-surface transition-colors hover:bg-surface-container"
          >
            Cancel
          </button>
          <button
            type="submit"
            disabled={updateMaintenance.isPending}
            className="rounded-lg bg-primary px-space-md py-space-xs font-label-md text-label-md text-on-primary transition-colors hover:bg-primary/90"
          >
            {updateMaintenance.isPending ? 'Saving...' : 'Save'}
          </button>
        </div>
      </form>
    )
  }

  return (
    <div className="flex flex-col justify-between gap-space-md rounded-xl bg-surface-container-low p-space-lg md:flex-row md:items-center">
      <div className="flex items-start gap-space-md">
        <div className={cn('shrink-0 rounded-xl bg-surface-container p-space-sm', item.iconTone || 'text-on-surface-variant')}>
          <span className="material-symbols-outlined text-xl">{item.icon || 'build'}</span>
        </div>
        <div className="flex flex-col">
          <div className="flex flex-wrap items-center gap-space-sm">
            <span className="font-headline-sm text-headline-sm font-semibold text-on-surface">
              {item.chargerIdentifier || `Charger ${item.chargerId}`}
            </span>
            <span
              className={cn(
                'rounded bg-surface-container px-space-xs py-space-2xs font-label-sm text-label-sm font-semibold',
                item.statusTone,
              )}
            >
              {item.status || 'Scheduled'}
            </span>
          </div>
          {item.reason && (
            <p className="mt-space-2xs font-body-sm text-body-sm text-on-surface-variant">{item.reason}</p>
          )}
          <div className="mt-space-xs flex flex-wrap items-center gap-space-md font-label-sm text-label-sm text-on-surface-variant">
            <span className="flex items-center gap-1">
              <span className="material-symbols-outlined text-xs">ev_station</span> Charger ID: {item.chargerId || item.chargers}
            </span>
            <span className="flex items-center gap-1">
              <span className="material-symbols-outlined text-xs">schedule</span> {item.startTime ? new Date(item.startTime).toLocaleString() : item.when}
            </span>
          </div>
        </div>
      </div>

      <div className="flex items-center gap-space-xs self-end md:self-center">
        <button
          type="button"
          onClick={() => setIsEditing(true)}
          className="rounded-lg bg-surface-container-lowest px-space-sm py-space-xs font-label-md text-label-md text-on-surface shadow-sm hover:bg-surface-container"
        >
          Edit
        </button>
        {(item.actions || []).map((action) => (
          <button
            key={action}
            type="button"
            className="rounded-lg bg-surface-container-lowest px-space-sm py-space-xs font-label-md text-label-md text-on-surface shadow-sm hover:bg-surface-container"
          >
            {action}
          </button>
        ))}
      </div>
    </div>
  )
}

export default function MaintenanceTab({ stationId, maintenance = [], chargers = [] }) {
  const [showAddForm, setShowAddForm] = useState(false)
  const addMaintenance = useAddMaintenanceWindow()

  const [form, setForm] = useState({
    chargerId: chargers[0]?.id || '',
    startTime: '',
    endTime: '',
    reason: ''
  })

  const handleSubmit = (e) => {
    e.preventDefault()
    addMaintenance.mutate(
      { chargerId: form.chargerId, stationId, data: { reason: form.reason, startTime: new Date(form.startTime).toISOString(), endTime: new Date(form.endTime).toISOString() } },
      {
        onSuccess: () => {
          setShowAddForm(false)
          setForm({ ...form, reason: '', startTime: '', endTime: '' })
        },
        onError: (err) => {
          console.error(err)
          alert('Failed to schedule maintenance window')
        }
      }
    )
  }

  return (
    <div className="flex flex-col gap-space-md">
      <div className="flex flex-col justify-between gap-space-sm sm:flex-row sm:items-center">
        <div>
          <h3 className="font-headline-sm text-headline-sm text-on-surface">
            Scheduled &amp; Upcoming Maintenance Windows
          </h3>
          <p className="font-body-sm text-body-sm text-on-surface-variant">
            Planned hardware recalibration, liquid coolant purges, and utility substation tests.
          </p>
        </div>
        <button
          type="button"
          onClick={() => setShowAddForm(!showAddForm)}
          className="inline-flex items-center gap-space-2xs rounded-lg bg-primary px-space-md py-space-2xs font-headline-sm text-headline-sm text-on-primary shadow-sm transition-all hover:bg-primary-container"
        >
          <span className="material-symbols-outlined text-sm">{showAddForm ? 'close' : 'calendar_month'}</span> 
          {showAddForm ? 'Cancel' : 'Schedule Maintenance Window'}
        </button>
      </div>

      {showAddForm && (
        <form onSubmit={handleSubmit} className="bg-surface-container-low p-space-lg rounded-xl shadow-sm mb-space-md">
          <h4 className="font-headline-sm text-headline-sm text-on-surface mb-space-md">Schedule New Window</h4>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-space-md">
            <div className="flex flex-col gap-space-2xs">
              <label className="font-label-sm text-label-sm text-on-surface">Target Charger</label>
              <select
                required
                className="rounded border border-outline bg-surface px-space-md py-space-sm text-on-surface"
                value={form.chargerId}
                onChange={(e) => setForm({ ...form, chargerId: e.target.value })}
              >
                <option value="" disabled>Select a charger</option>
                {chargers.map(ch => (
                  <option key={ch.id} value={ch.id}>{ch.id} ({ch.power || ch.maxOutputKw} kW)</option>
                ))}
              </select>
            </div>
            <div className="flex flex-col gap-space-2xs">
              <label className="font-label-sm text-label-sm text-on-surface">Reason</label>
              <input
                type="text"
                required
                placeholder="e.g. Cable replacement"
                className="rounded border border-outline bg-surface px-space-md py-space-sm text-on-surface"
                value={form.reason}
                onChange={(e) => setForm({ ...form, reason: e.target.value })}
              />
            </div>
            <div className="flex flex-col gap-space-2xs">
              <label className="font-label-sm text-label-sm text-on-surface">Start Time</label>
              <input
                type="datetime-local"
                required
                className="rounded border border-outline bg-surface px-space-md py-space-sm text-on-surface"
                value={form.startTime}
                onChange={(e) => setForm({ ...form, startTime: e.target.value })}
              />
            </div>
            <div className="flex flex-col gap-space-2xs">
              <label className="font-label-sm text-label-sm text-on-surface">End Time</label>
              <input
                type="datetime-local"
                required
                className="rounded border border-outline bg-surface px-space-md py-space-sm text-on-surface"
                value={form.endTime}
                onChange={(e) => setForm({ ...form, endTime: e.target.value })}
              />
            </div>
          </div>
          <div className="mt-space-lg flex justify-end">
            <button
              type="submit"
              disabled={addMaintenance.isPending}
              className="rounded-lg bg-primary px-space-lg py-space-sm font-label-md text-label-md text-on-primary transition-colors hover:bg-primary/90"
            >
              {addMaintenance.isPending ? 'Scheduling...' : 'Schedule Window'}
            </button>
          </div>
        </form>
      )}

      <div className="mt-space-2xs flex flex-col gap-space-md">
        {maintenance.length === 0 ? (
          <div className="p-space-xl text-center text-on-surface-variant bg-surface-container-low rounded-xl">
            No maintenance windows scheduled.
          </div>
        ) : (
          maintenance.map((item, idx) => (
            <MaintenanceItem key={item.id || idx} item={item} stationId={stationId} />
          ))
        )}
      </div>
    </div>
  )
}
