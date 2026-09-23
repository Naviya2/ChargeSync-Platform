import { useState } from 'react'
import { format } from 'date-fns'
import { useReservationsList } from '../hooks/useReservations'
import PageHeader from '../../../components/shared/PageHeader'
import { Card, Spinner, Button } from '../../../components/ui'
import ReservationDetailsModal from '../components/ReservationDetailsModal'

const STATUS_COLORS = {
  Pending: 'bg-yellow-100 text-yellow-800',
  Confirmed: 'bg-blue-100 text-blue-800',
  CheckedIn: 'bg-indigo-100 text-indigo-800',
  Completed: 'bg-green-100 text-green-800',
  Cancelled: 'bg-red-100 text-red-800',
}

export default function ReservationsPage() {
  const [selectedId, setSelectedId] = useState(null)
  const { data, isLoading, isError } = useReservationsList()

  const reservations = data?.items || []

  return (
    <div className="space-y-6">
      <PageHeader 
        title="Reservations" 
        description="Manage upcoming and past charging slot reservations." 
      />

      <Card className="p-6">
        {isLoading ? (
          <div className="flex justify-center p-8"><Spinner size="lg" /></div>
        ) : isError ? (
          <div className="text-red-500">Failed to load reservations.</div>
        ) : reservations.length === 0 ? (
          <div className="text-gray-500 text-center py-8">No reservations found.</div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm text-gray-500">
              <thead className="bg-gray-50 text-xs uppercase text-gray-700">
                <tr>
                  <th className="px-6 py-3">Customer</th>
                  <th className="px-6 py-3">Station / Charger</th>
                  <th className="px-6 py-3">Time Window</th>
                  <th className="px-6 py-3">Status</th>
                  <th className="px-6 py-3">Action</th>
                </tr>
              </thead>
              <tbody>
                {reservations.map((res) => (
                  <tr key={res.id} className="border-b bg-white hover:bg-gray-50">
                    <td className="px-6 py-4 font-medium text-gray-900">
                      {res.driverId ? 'Registered Driver' : 'Walk-In'}
                    </td>
                    <td className="px-6 py-4">
                      <div className="text-gray-900">{res.stationName || 'Unknown Station'}</div>
                      <div className="text-xs text-gray-500">Charger: {res.chargerId?.substring(0, 8)}...</div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div>{format(new Date(res.startTime), 'MMM d, yyyy')}</div>
                      <div className="text-gray-900">
                        {format(new Date(res.startTime), 'HH:mm')} - {format(new Date(res.endTime), 'HH:mm')}
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <span className={`rounded-full px-2.5 py-0.5 text-xs font-semibold ${STATUS_COLORS[res.status] || 'bg-gray-100 text-gray-800'}`}>
                        {res.status}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <Button variant="secondary" size="sm" onClick={() => setSelectedId(res.id)}>
                        View Details
                      </Button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>

      {selectedId && (
        <ReservationDetailsModal 
          reservationId={selectedId} 
          onClose={() => setSelectedId(null)} 
        />
      )}
    </div>
  )
}
