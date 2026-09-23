import { useState } from 'react'
import { useReservationDetail, useReservationHistory, useCancelReservation, useUpdateReservation, useDeleteReservation } from '../hooks/useReservations'
import { format } from 'date-fns'
import { Button, Spinner } from '../../../components/ui'

export default function ReservationDetailsModal({ reservationId, onClose }) {
  const { data: reservation, isLoading } = useReservationDetail(reservationId)
  const { data: history, isLoading: isHistoryLoading } = useReservationHistory(reservationId)
  const { mutate: cancelReservation, isPending: isCancelling } = useCancelReservation()
  const { mutate: updateReservation, isPending: isUpdating } = useUpdateReservation()
  const { mutate: deleteReservation, isPending: isDeleting } = useDeleteReservation()

  const [isEditing, setIsEditing] = useState(false)
  const [editStartTime, setEditStartTime] = useState('')
  const [editEndTime, setEditEndTime] = useState('')

  if (!reservationId) return null

  const handleEditClick = () => {
    if (reservation) {
      // Local time formatting for datetime-local input
      setEditStartTime(format(new Date(reservation.startTime), "yyyy-MM-dd'T'HH:mm"))
      setEditEndTime(format(new Date(reservation.endTime), "yyyy-MM-dd'T'HH:mm"))
      setIsEditing(true)
    }
  }

  const handleSaveUpdate = () => {
    updateReservation(
      { id: reservationId, data: { startTime: new Date(editStartTime).toISOString(), endTime: new Date(editEndTime).toISOString() } },
      {
        onSuccess: () => setIsEditing(false)
      }
    )
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/50 p-4 backdrop-blur-sm">
      <div className="relative w-full max-w-2xl overflow-hidden rounded-2xl bg-white shadow-2xl">
        {/* Header */}
        <div className="border-b px-6 py-4 flex justify-between items-center bg-gray-50">
          <h2 className="text-xl font-semibold text-gray-900">Reservation Details</h2>
          <button 
            onClick={onClose}
            className="text-gray-400 hover:text-gray-600 transition-colors"
          >
            <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        {/* Content */}
        <div className="p-6 overflow-y-auto max-h-[70vh]">
          {isLoading ? (
            <div className="flex justify-center py-12"><Spinner size="lg" /></div>
          ) : !reservation ? (
            <div className="text-red-500 text-center py-12">Failed to load reservation details.</div>
          ) : (
            <div className="space-y-8">
              {/* Info Grid */}
              <div className="grid grid-cols-2 gap-6">
                <div>
                  <h3 className="text-sm font-medium text-gray-500 mb-1">Customer</h3>
                  <div className="text-base text-gray-900 font-medium">
                    {reservation.driverId ? (reservation.driverName || 'Registered Driver') : 'Walk-In Customer'}
                  </div>
                </div>
                <div>
                  <h3 className="text-sm font-medium text-gray-500 mb-1">Status</h3>
                  <div className="text-base font-semibold">
                    <span className="bg-blue-100 text-blue-800 px-2 py-0.5 rounded text-sm">
                      {reservation.status}
                    </span>
                  </div>
                </div>
                <div>
                  <h3 className="text-sm font-medium text-gray-500 mb-1">Schedule</h3>
                  {isEditing ? (
                    <div className="space-y-2">
                      <input 
                        type="datetime-local" 
                        value={editStartTime}
                        onChange={(e) => setEditStartTime(e.target.value)}
                        className="block w-full text-sm border-gray-300 rounded-md"
                      />
                      <input 
                        type="datetime-local" 
                        value={editEndTime}
                        onChange={(e) => setEditEndTime(e.target.value)}
                        className="block w-full text-sm border-gray-300 rounded-md"
                      />
                    </div>
                  ) : (
                    <div className="text-base text-gray-900">
                      {format(new Date(reservation.startTime), 'MMM d, yyyy')} <br/>
                      {format(new Date(reservation.startTime), 'HH:mm')} - {format(new Date(reservation.endTime), 'HH:mm')}
                    </div>
                  )}
                </div>
                <div>
                  <h3 className="text-sm font-medium text-gray-500 mb-1">Station & Charger</h3>
                  <div className="text-base text-gray-900">
                    {reservation.stationName || 'N/A'} <br/>
                    <span className="text-sm text-gray-500">Charger ID: {reservation.chargerId}</span>
                  </div>
                </div>
              </div>

              {/* Deposit Info */}
              {reservation.advanceDepositAmount > 0 && (
                <div className="bg-emerald-50 rounded-lg p-4 border border-emerald-100">
                  <h3 className="text-sm font-medium text-emerald-800">Advance Deposit Paid</h3>
                  <div className="text-2xl font-bold text-emerald-600 mt-1">
                    ${reservation.advanceDepositAmount.toFixed(2)}
                  </div>
                </div>
              )}

              {/* Status Timeline */}
              <div>
                <h3 className="text-lg font-medium text-gray-900 mb-4">Status History</h3>
                {isHistoryLoading ? (
                  <div className="flex justify-center"><Spinner /></div>
                ) : !history || history.length === 0 ? (
                  <div className="text-gray-500 text-sm">No history available.</div>
                ) : (
                  <div className="space-y-4 border-l-2 border-gray-200 ml-3 pl-4">
                    {history.map((h, i) => (
                      <div key={i} className="relative">
                        <div className="absolute -left-[1.35rem] w-3 h-3 bg-blue-500 rounded-full border-2 border-white ring-4 ring-white" />
                        <div className="text-sm font-medium text-gray-900">{h.newStatus}</div>
                        <div className="text-xs text-gray-500">
                          {format(new Date(h.changedAt), 'MMM d, yyyy HH:mm')} 
                          {h.changedByUserId && ` • by User ${h.changedByUserId.substring(0, 8)}`}
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="border-t bg-gray-50 px-6 py-4 flex justify-between gap-3 rounded-b-2xl">
          <div className="flex gap-2">
             <Button 
                variant="danger" 
                onClick={() => {
                  if (confirm('Are you sure you want to completely delete this reservation?')) {
                    deleteReservation(reservationId, { onSuccess: onClose })
                  }
                }}
                disabled={isDeleting || !reservation}
              >
                {isDeleting ? 'Deleting...' : 'Delete'}
             </Button>
          </div>
          <div className="flex gap-2">
            <Button variant="outline" onClick={onClose}>Close</Button>
            {isEditing ? (
              <>
                <Button variant="ghost" onClick={() => setIsEditing(false)}>Cancel Edit</Button>
                <Button variant="brand" onClick={handleSaveUpdate} disabled={isUpdating}>
                  {isUpdating ? 'Saving...' : 'Save Changes'}
                </Button>
              </>
            ) : (
              <Button variant="outline" onClick={handleEditClick} disabled={!reservation}>
                Edit Time
              </Button>
            )}
            
            {(reservation?.status === 'Pending' || reservation?.status === 'Confirmed') && !isEditing ? (
              <Button 
                variant="outline" 
                onClick={() => {
                  if (confirm('Are you sure you want to cancel this reservation?')) {
                    cancelReservation(reservationId, {
                      onSuccess: onClose
                    })
                  }
                }}
                disabled={isCancelling}
              >
                {isCancelling ? 'Cancelling...' : 'Cancel Booking'}
              </Button>
            ) : null}
          </div>
        </div>
      </div>
    </div>
  )
}
