import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useMyStations } from '../../stations/hooks/useStations'
import { useReservationsList } from '../../reservations/hooks/useReservations'
import DashboardHeader from '../components/DashboardHeader'
import { Card, Spinner } from '../../../components/ui'
import { format } from 'date-fns'
import { TIMEFRAMES } from '../data/dashboardData'
import AddReservationModal from '../../reservations/components/AddReservationModal'

export default function StationOwnerDashboardPage() {
  const [timeframe, setTimeframe] = useState(TIMEFRAMES[0])
  const [customRange, setCustomRange] = useState({ start: '', end: '' })
  const [isAddModalOpen, setIsAddModalOpen] = useState(false)
  const navigate = useNavigate()
  const { data: stations, isLoading: isStationsLoading } = useMyStations()
  const { data: reservationsData, isLoading: isReservationsLoading } = useReservationsList({}, { refetchInterval: 10000 })

  const allReservations = reservationsData?.items || []
  
  if (isStationsLoading || isReservationsLoading) {
    return <div className="flex justify-center p-12"><Spinner size={24} /></div>
  }

  const myStation = stations?.[0]
  
  // Filter reservations based on timeframe
  const reservations = allReservations.filter(r => {
    if (!r.startTime) return false;
    const resDate = new Date(r.startTime);
    const now = new Date();
    const diffHours = (now - resDate) / (1000 * 60 * 60);
    
    if (timeframe === '24 Hours') return diffHours <= 24 && diffHours >= -24;
    if (timeframe === '7 Days') return diffHours <= 24 * 7 && diffHours >= -24 * 7;
    if (timeframe === '30 Days') return diffHours <= 24 * 30 && diffHours >= -24 * 30;
    if (timeframe === 'Custom Range') {
       if (!customRange.start && !customRange.end) return true;
       const sDate = customRange.start ? new Date(customRange.start) : new Date(0);
       const eDate = customRange.end ? new Date(customRange.end) : new Date(8640000000000000);
       if (customRange.end) eDate.setDate(eDate.getDate() + 1); // inclusive end
       return resDate >= sDate && resDate <= eDate;
    }
    return true;
  });

  const completed = reservations.filter(r => r.status === 'Completed').length
  const ongoing = reservations.filter(r => r.status === 'CheckedIn').length
  const cancelled = reservations.filter(r => r.status === 'Cancelled').length
  const pending = reservations.filter(r => r.status === 'Pending').length
  const total = reservations.length

  const activeReservations = reservations.filter(r => r.status === 'Confirmed' || r.status === 'CheckedIn' || r.status === 'Pending')

  return (
    <div className="flex w-full flex-col gap-6">
      <DashboardHeader 
        timeframe={timeframe} 
        setTimeframe={setTimeframe} 
        reservations={reservations} 
        customRange={customRange}
        setCustomRange={setCustomRange}
      />
      
      <div className="grid grid-cols-1 md:grid-cols-5 gap-6">
        <Card className="p-6 bg-white border-l-4 border-amber-500 shadow-sm hover:shadow-md transition-shadow cursor-pointer" onClick={() => navigate('/reservations')}>
          <h3 className="text-sm font-medium text-gray-500 uppercase tracking-wider">Pending Approvals</h3>
          <div className="mt-2 text-3xl font-bold text-gray-900">{pending}</div>
        </Card>
        <Card className="p-6 bg-white border-l-4 border-blue-500 shadow-sm hover:shadow-md transition-shadow">
          <h3 className="text-sm font-medium text-gray-500 uppercase tracking-wider">Total</h3>
          <div className="mt-2 text-3xl font-bold text-gray-900">{total}</div>
        </Card>
        <Card className="p-6 bg-white border-l-4 border-emerald-500 shadow-sm hover:shadow-md transition-shadow">
          <h3 className="text-sm font-medium text-gray-500 uppercase tracking-wider">Completed</h3>
          <div className="mt-2 text-3xl font-bold text-gray-900">{completed}</div>
        </Card>
        <Card className="p-6 bg-white border-l-4 border-indigo-500 shadow-sm hover:shadow-md transition-shadow">
          <h3 className="text-sm font-medium text-gray-500 uppercase tracking-wider">Ongoing</h3>
          <div className="mt-2 text-3xl font-bold text-gray-900">{ongoing}</div>
        </Card>
        <Card className="p-6 bg-white border-l-4 border-red-500 shadow-sm hover:shadow-md transition-shadow">
          <h3 className="text-sm font-medium text-gray-500 uppercase tracking-wider">Cancelled</h3>
          <div className="mt-2 text-3xl font-bold text-gray-900">{cancelled}</div>
        </Card>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-1">
          <Card className="p-6 h-full shadow-sm">
            <h2 className="text-lg font-semibold text-gray-900 mb-4">My Station Details</h2>
            {myStation ? (
              <div className="space-y-4">
                <div>
                  <div className="text-sm text-gray-500">Name</div>
                  <div className="text-base font-medium text-gray-900">{myStation.name}</div>
                </div>
                <div>
                  <div className="text-sm text-gray-500">Address</div>
                  <div className="text-base font-medium text-gray-900">{myStation.address}</div>
                </div>
                <div>
                  <div className="text-sm text-gray-500">Status</div>
                  <div className="inline-block px-2 py-1 mt-1 text-xs font-medium rounded-full bg-blue-100 text-blue-800">
                    {myStation.status}
                  </div>
                </div>
                <div>
                  <div className="text-sm text-gray-500">Chargers</div>
                  <div className="text-base font-medium text-gray-900">{myStation.chargers?.length || 0}</div>
                </div>
              </div>
            ) : (
              <div className="text-gray-500 text-sm">No station registered yet.</div>
            )}
          </Card>
        </div>

        <div className="lg:col-span-2">
          <Card className="p-6 h-full shadow-sm">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-lg font-semibold text-gray-900">Ongoing / Upcoming Reservations</h2>
              <button
                onClick={() => setIsAddModalOpen(true)}
                className="inline-flex items-center gap-1 rounded-lg bg-primary px-space-md py-1.5 font-label-md text-label-md text-on-primary transition-colors hover:bg-primary/90"
              >
                <span className="material-symbols-outlined text-[18px]">add</span>
                Add Reservation
              </button>
            </div>
            {activeReservations.length === 0 ? (
              <div className="text-center text-gray-500 py-12 bg-gray-50 rounded-lg">No active reservations at the moment.</div>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full text-left text-sm text-gray-500">
                  <thead className="bg-gray-50 text-xs uppercase text-gray-700">
                    <tr>
                      <th className="px-4 py-3">Customer</th>
                      <th className="px-4 py-3">Charger</th>
                      <th className="px-4 py-3">Time</th>
                      <th className="px-4 py-3">Status</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-200">
                    {activeReservations.map(res => (
                      <tr key={res.id} className="bg-white hover:bg-gray-50">
                        <td className="px-4 py-3 font-medium text-gray-900">{res.driverName || 'Walk-In'}</td>
                        <td className="px-4 py-3">{res.chargerName || res.chargerId?.substring(0, 8)}</td>
                        <td className="px-4 py-3 whitespace-nowrap">
                          {format(new Date(res.startTime), 'MMM d, HH:mm')}
                        </td>
                        <td className="px-4 py-3">
                          <span className="inline-block px-2 py-1 text-xs font-medium rounded-full bg-gray-100 text-gray-800">
                            {res.status}
                          </span>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </Card>
        </div>
      </div>
      
      {isAddModalOpen && (
        <AddReservationModal
          onClose={() => setIsAddModalOpen(false)}
        />
      )}
    </div>
  )
}
