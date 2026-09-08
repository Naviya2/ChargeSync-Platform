import { useMemo, useState } from 'react'
import StationsHeader from '../components/StationsHeader'
import StationKpiStrip from '../components/StationKpiStrip'
import StationFilterBar from '../components/StationFilterBar'
import StationCardGrid from '../components/StationCardGrid'
import StationDetailConsole from '../components/StationDetailConsole'
import { STATIONS } from '../data/stationsData'

/**
 * Station Owner "My Stations" workspace — asset orchestration, live bays,
 * pricing rules, and maintenance windows for the owner's fleet.
 */
export default function MyStationsPage() {
  const [activeFilter, setActiveFilter] = useState('all')
  const [selectedId, setSelectedId] = useState(STATIONS[0].id)

  const visibleStations = useMemo(() => {
    if (activeFilter === 'all') return STATIONS
    return STATIONS.filter((s) => s.filterKey === activeFilter)
  }, [activeFilter])

  const selectedStation =
    STATIONS.find((s) => s.id === selectedId) ?? visibleStations[0] ?? STATIONS[0]

  return (
    <div className="flex w-full flex-col gap-space-xl">
      <StationsHeader />
      <StationKpiStrip />
      <StationFilterBar active={activeFilter} onChange={setActiveFilter} />
      <StationCardGrid
        stations={visibleStations}
        selectedId={selectedStation.id}
        onSelect={setSelectedId}
      />
      <StationDetailConsole station={selectedStation} />
    </div>
  )
}
