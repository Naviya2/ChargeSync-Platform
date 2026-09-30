import { useState, useMemo } from 'react'
import DashboardHeader from '../components/DashboardHeader'
import MetricsGrid from '../components/MetricsGrid'
import ReservationsTable from '../components/ReservationsTable'
import { useReservationsList } from '../../reservations/hooks/useReservations'
import { DashboardSkeleton } from '../components/DashboardStates'
import { useStations } from '../../stations/hooks/useStations'
import { useUsers } from '../../users/hooks/useUsers'

/**
 * Platform Admin dashboard — network telemetry, AI recommendation dispatch,
 * and multi-tenant station metrics.
 */
export default function AdminDashboardPage() {
  const [timeframe, setTimeframe] = useState('24 Hours')
  const [customRange, setCustomRange] = useState({ start: '', end: '' })
  
  const { data: stationsDto = [], isLoading: isStationsLoading } = useStations()
  const { data: users = [], isLoading: isUsersLoading } = useUsers()
  const { data: reservationsData } = useReservationsList({}, { refetchInterval: 10000 })

  const filteredReservations = useMemo(() => {
    const allRes = reservationsData?.items || [];
    return allRes.filter(r => {
      const resDate = new Date(r.startTime);
      const now = new Date();
      const diffHours = (now - resDate) / (1000 * 60 * 60);
      
      if (timeframe === '24 Hours' && (diffHours > 24 || diffHours < -24)) return false;
      if (timeframe === '7 Days' && (diffHours > 24 * 7 || diffHours < -24 * 7)) return false;
      if (timeframe === '30 Days' && (diffHours > 24 * 30 || diffHours < -24 * 30)) return false;
      if (timeframe === 'Custom Range') {
         if (customRange?.start) {
           const sDate = new Date(customRange.start);
           if (resDate < sDate) return false;
         }
         if (customRange?.end) {
           const eDate = new Date(customRange.end);
           eDate.setDate(eDate.getDate() + 1);
           if (resDate > eDate) return false;
         }
      }
      return true;
    });
  }, [reservationsData, timeframe, customRange]);

  const dynamicMetrics = useMemo(() => {
    const totalStations = stationsDto.length;
    const totalDrivers = users.filter(u => u.role === 'Driver' || u.role === 0).length;
    const totalOwners = users.filter(u => u.role === 'StationOwner' || u.role === 1).length;
    
    const totalRevenue = filteredReservations.reduce((acc, r) => acc + (r.advanceDepositAmount || 0), 0);
    
    return [
      {
        key: 'stations',
        label: 'Registered Stations',
        value: totalStations.toString(),
        delta: '+12%',
        deltaTone: 'up',
        pill: { text: 'Network', tone: 'tertiary' },
        viz: 'radial',
        radialPercent: totalStations > 0 ? 100 : 0,
      },
      {
        key: 'drivers',
        label: 'Total Drivers',
        value: totalDrivers.toString(),
        delta: '+5%',
        deltaTone: 'up',
        viz: 'sparkline',
      },
      {
        key: 'owners',
        label: 'Station Owners',
        value: totalOwners.toString(),
        delta: '+2%',
        deltaTone: 'neutral',
        viz: 'icon',
      },
      {
        key: 'revenue',
        label: 'Platform Revenue',
        value: `LKR ${totalRevenue.toLocaleString()}`,
        delta: 'N/A',
        deltaTone: 'neutral',
        viz: 'icon',
      }
    ];
  }, [stationsDto, users, filteredReservations]);

  if (isStationsLoading || isUsersLoading) {
    return <DashboardSkeleton />
  }

  return (
    <div className="flex w-full flex-col gap-space-xl">
      <DashboardHeader 
        timeframe={timeframe} 
        setTimeframe={setTimeframe} 
        reservations={filteredReservations}
        customRange={customRange}
        setCustomRange={setCustomRange}
        hideAddStation={true}
      />
      <div className="flex w-full flex-col gap-space-xl">
        <MetricsGrid metrics={dynamicMetrics} />
        <ReservationsTable preFilteredReservations={filteredReservations} />
      </div>
    </div>
  )
}
