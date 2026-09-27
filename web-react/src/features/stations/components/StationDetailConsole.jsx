import { useState } from 'react'
import { DETAIL_TABS } from '../data/stationsData'
import OverviewTab from './tabs/OverviewTab'
import ChargersTab from './tabs/ChargersTab'
import OperatingHoursTab from './tabs/OperatingHoursTab'
import MaintenanceTab from './tabs/MaintenanceTab'
import { cn } from '../../../lib/cn'
import { useUpdateStation } from '../hooks/useStations'
import MapLocationPicker from '../../../components/shared/MapLocationPicker'

export default function StationDetailConsole({ station }) {
  const [activeTab, setActiveTab] = useState('chargers')
  const [showEdit, setShowEdit] = useState(false)
  const updateStation = useUpdateStation()

  const [form, setForm] = useState({
    name: station?.name || '',
    address: station?.address || '',
    latitude: station?.latitude || '',
    longitude: station?.longitude || ''
  })

  if (!station) {
    return (
      <div className="rounded-xl bg-surface-container-lowest p-space-3xl text-center shadow-md">
        <p className="font-headline-sm text-headline-sm text-on-surface">No console data</p>
        <p className="font-body-sm text-body-sm text-on-surface-variant">
          Detail telemetry is not available.
        </p>
      </div>
    )
  }

  const chargers = station.chargers || []
  const operatingHours = station.operatingHours || []
  const maintenance = chargers.flatMap(c => (c.maintenanceWindows || []).map(m => ({ ...m, chargerId: c.id, chargerIdentifier: c.identifier })))

  const tabCount = {
    chargers: chargers.length,
    maintenance: maintenance.length,
  }

  const handleEditSubmit = (e) => {
    e.preventDefault()
    updateStation.mutate(
      { 
        id: station.id, 
        data: {
          ...form,
          latitude: parseFloat(form.latitude),
          longitude: parseFloat(form.longitude)
        } 
      },
      {
        onSuccess: () => {
          setShowEdit(false)
        },
        onError: () => alert('Failed to update station info')
      }
    )
  }

  return (
    <div className="mt-space-md flex flex-col overflow-hidden rounded-xl bg-surface-container-lowest shadow-md">
      {/* Sub-header */}
      <div className="flex flex-col justify-between gap-space-md bg-surface-container-low p-space-lg md:flex-row md:items-center">
        <div className="flex flex-col gap-space-2xs">
          <div className="flex items-center gap-space-xs font-label-sm text-label-sm text-on-surface-variant">
            <span>My Stations</span>
            <span>/</span>
            <span className="font-semibold text-on-surface">{station.name}</span>
            <span className="font-mono text-outline-variant">#{station.id}</span>
          </div>
          <div className="flex flex-wrap items-center gap-space-sm">
            <h2 className="font-headline-lg text-headline-lg text-on-surface">{station.name}</h2>
            <span className="inline-flex items-center gap-1 rounded bg-tertiary-container/20 px-space-xs py-space-2xs font-label-sm text-label-sm font-semibold text-tertiary">
              <span className="h-1.5 w-1.5 rounded-full bg-tertiary" /> {station.status || 'Active'}
            </span>
          </div>
          <p className="font-body-sm text-body-sm text-on-surface-variant">{station.address}</p>
        </div>

        <div className="flex flex-wrap items-center gap-space-xs self-start md:self-center">
          <button
            type="button"
            onClick={() => setShowEdit(!showEdit)}
            className="inline-flex items-center gap-space-2xs rounded-lg bg-surface-container-lowest px-space-md py-space-xs font-label-md text-label-md text-on-surface shadow-sm transition-colors hover:bg-surface-container"
          >
            <span className="material-symbols-outlined text-sm">{showEdit ? 'close' : 'edit'}</span> 
            {showEdit ? 'Cancel Edit' : 'Edit Station Info'}
          </button>
        </div>
      </div>

      {showEdit && (
        <form onSubmit={handleEditSubmit} className="bg-surface-container p-space-lg border-b border-outline">
          <h4 className="font-headline-sm text-headline-sm text-on-surface mb-space-md">Update Station Info</h4>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-space-md">
            <div className="flex flex-col gap-space-2xs">
              <label className="font-label-sm text-label-sm text-on-surface">Station Name</label>
              <input
                type="text"
                required
                className="rounded border border-outline bg-surface px-space-md py-space-sm text-on-surface"
                value={form.name}
                onChange={(e) => setForm({ ...form, name: e.target.value })}
              />
            </div>
            <div className="flex flex-col gap-space-2xs">
              <label className="font-label-sm text-label-sm text-on-surface">Address</label>
              <input
                type="text"
                required
                className="rounded border border-outline bg-surface px-space-md py-space-sm text-on-surface"
                value={form.address}
                onChange={(e) => setForm({ ...form, address: e.target.value })}
              />
            </div>
          </div>
          <div className="mt-space-md">
            <MapLocationPicker
              latitude={form.latitude}
              longitude={form.longitude}
              onLocationChange={(lat, lng) => setForm({ ...form, latitude: lat.toFixed(6), longitude: lng.toFixed(6) })}
              onAddressFetched={(address) => setForm((prev) => ({ ...prev, address }))}
            />
          </div>
          <div className="mt-space-lg flex justify-end">
            <button
              type="submit"
              disabled={updateStation.isPending}
              className="rounded-lg bg-primary px-space-lg py-space-sm font-label-md text-label-md text-on-primary transition-colors hover:bg-primary/90"
            >
              {updateStation.isPending ? 'Saving...' : 'Save Changes'}
            </button>
          </div>
        </form>
      )}

      {/* Tab nav */}
      <div className="flex items-center gap-space-xs overflow-x-auto bg-surface-container-low px-space-lg">
        {DETAIL_TABS.map((tab) => {
          const count = tabCount[tab.key]
          const isActive = activeTab === tab.key
          return (
            <button
              key={tab.key}
              type="button"
              onClick={() => setActiveTab(tab.key)}
              className={cn(
                'whitespace-nowrap px-space-md py-space-sm font-headline-sm text-headline-sm transition-all',
                isActive
                  ? 'font-semibold text-primary shadow-[inset_0_-2px_0_0_currentColor]'
                  : 'text-on-surface-variant hover:text-on-surface',
              )}
            >
              {tab.label}
              {count != null && ` (${count})`}
            </button>
          )
        })}
      </div>

      {/* Panel */}
      <div className="p-space-lg">
        {activeTab === 'overview' && <OverviewTab chargers={chargers} stationName={station.name} />}
        {activeTab === 'chargers' && <ChargersTab stationId={station.id} chargers={chargers} />}
        {activeTab === 'operating-hours' && <OperatingHoursTab stationId={station.id} hours={operatingHours} />}
        {activeTab === 'maintenance' && <MaintenanceTab stationId={station.id} maintenance={maintenance} chargers={chargers} />}
      </div>
    </div>
  )
}
