import { useMemo, useState } from 'react'
import StationsHeader from '../components/StationsHeader'
import StationKpiStrip from '../components/StationKpiStrip'
import StationFilterBar from '../components/StationFilterBar'
import StationCardGrid from '../components/StationCardGrid'
import { useNavigate } from 'react-router-dom'
import { ROUTES } from '../../../lib/constants'
import { useMyStations } from '../hooks/useStations'

export default function MyStationsPage() {
  const navigate = useNavigate()
  const [activeFilter, setActiveFilter] = useState('all')
  const { data: stationsDto = [], isLoading } = useMyStations()

  const stations = useMemo(() => {
    return stationsDto.map(dto => ({
      id: dto.id,
      name: dto.name,
      address: dto.address,
      status: {
        key: dto.status?.toLowerCase() ?? 'pending',
        label: dto.status === 'Active' ? 'Active' : (dto.status === 'Pending' ? 'Pending Approval' : dto.status),
        tone: dto.status === 'Active' ? 'tertiary' : 'secondary',
        pulse: dto.status === 'Active'
      },
      filterKey: dto.status?.toLowerCase() ?? 'pending',
      capacity: `${dto.chargers?.length ?? 0} Chargers`,
      bayLabel: 'Live Bay State',
      bayValue: `${dto.chargers?.filter(c => c.status === 'Occupied').length ?? 0} in use`,
      load: 0,
      trendLabel: 'Status',
      trendValue: dto.status,
      footerLabel: 'Coordinates',
      footerValue: `${dto.latitude}, ${dto.longitude}`,
      sparkTone: 'text-primary',
      detailData: dto
    }))
  }, [stationsDto])

  const visibleStations = useMemo(() => {
    if (activeFilter === 'all') return stations
    return stations.filter((s) => s.filterKey === activeFilter)
  }, [activeFilter, stations])

  const handleSelectStation = (id) => {
    const station = stations.find((s) => s.id === id)
    if (station) {
      if (station.status.key === 'active') {
        navigate(`${ROUTES.STATIONS}/${id}`)
      } else {
        navigate(`${ROUTES.STATIONS}/${id}/pending`)
      }
    }
  }

  if (isLoading) {
    return <div className="p-space-xl text-center">Loading stations...</div>
  }

  return (
    <div className="flex w-full flex-col gap-space-xl">
      <StationsHeader />
      <StationKpiStrip />
      <StationFilterBar active={activeFilter} onChange={setActiveFilter} />
      <StationCardGrid
        stations={visibleStations}
        onSelect={handleSelectStation}
      />
    </div>
  )
}
