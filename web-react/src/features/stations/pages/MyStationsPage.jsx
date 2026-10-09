import { useMemo, useState } from 'react'
import StationsHeader from '../components/StationsHeader'
import StationKpiStrip from '../components/StationKpiStrip'
import StationFilterBar from '../components/StationFilterBar'
import StationCardGrid from '../components/StationCardGrid'
import { useNavigate } from 'react-router-dom'
import { ROUTES } from '../../../lib/constants'
import { useMyStations, useStations } from '../hooks/useStations'

export default function MyStationsPage({ isAdmin = false }) {
  const navigate = useNavigate()
  const [activeFilter, setActiveFilter] = useState('all')
  const [searchQuery, setSearchQuery] = useState('')
  const [sortOrder, setSortOrder] = useState('name_asc')

  const myStationsQuery = useMyStations()
  const allStationsQuery = useStations()

  const { data: stationsDto = [], isLoading } = isAdmin ? allStationsQuery : myStationsQuery

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

  const counts = useMemo(() => {
    return {
      all: stations.length,
      active: stations.filter(s => s.status.key === 'active').length,
      pending: stations.filter(s => s.status.key === 'pending').length,
      rejected: stations.filter(s => s.status.key === 'rejected').length,
    }
  }, [stations]);

  const kpis = useMemo(() => {
    const total = stationsDto.length;
    const active = counts.active;
    const pending = counts.pending;
    const rejected = counts.rejected;

    const allChargers = stationsDto.flatMap(s => s.chargers || []);
    const totalPorts = allChargers.length;
    const livePorts = allChargers.filter(c => c.status === 'Available' || c.status === 'Occupied').length;

    return [
      {
        key: 'total',
        label: 'Total Stations',
        icon: 'domain',
        value: total.toString(),
        highlight: `${active} Active`,
        sub: `${pending} Pending · ${rejected} Rejected`,
      },
      {
        key: 'ports',
        label: 'Operational Ports',
        icon: 'power',
        value: `${livePorts} / ${totalPorts}`,
        highlight: totalPorts > 0 ? `${Math.round((livePorts / totalPorts) * 100)}% Live` : '0% Live',
        sub: `${totalPorts - livePorts} bays unavailable`,
      },
      {
        key: 'revenue',
        label: 'Daily Net Revenue',
        icon: 'payments',
        value: 'LKR 0.00',
        highlight: 'Real-time',
        sub: 'Awaiting transactions',
      },
      {
        key: 'utilization',
        label: 'Fleet Utilization',
        icon: 'speed',
        value: totalPorts > 0 ? `${Math.round((livePorts / totalPorts) * 100)}%` : '0%',
        highlight: 'Target: >75%',
        progress: totalPorts > 0 ? Math.round((livePorts / totalPorts) * 100) : 0,
      }
    ];
  }, [stationsDto, counts]);

  const visibleStations = useMemo(() => {
    let filtered = stations;
    if (activeFilter !== 'all') {
      filtered = filtered.filter((s) => s.filterKey === activeFilter);
    }
    if (searchQuery) {
      const q = searchQuery.toLowerCase();
      filtered = filtered.filter(s => s.name?.toLowerCase().includes(q) || s.address?.toLowerCase().includes(q) || s.id?.toLowerCase().includes(q));
    }
    return [...filtered].sort((a, b) => {
      if (sortOrder === 'name_asc') return (a.name || '').localeCompare(b.name || '');
      if (sortOrder === 'name_desc') return (b.name || '').localeCompare(a.name || '');
      if (sortOrder === 'status') return (a.status.key || '').localeCompare(b.status.key || '');
      return 0;
    });
  }, [activeFilter, searchQuery, sortOrder, stations])

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
      <StationsHeader stations={stations} hideAddStation={isAdmin} />
      <StationKpiStrip kpis={kpis} />
      <StationFilterBar
        active={activeFilter}
        onChange={setActiveFilter}
        search={searchQuery}
        onSearchChange={setSearchQuery}
        sort={sortOrder}
        onSortChange={setSortOrder}
        counts={counts}
      />
      <StationCardGrid
        stations={visibleStations}
        onSelect={handleSelectStation}
      />
    </div>
  )
}
