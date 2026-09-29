import { useState } from 'react'
import { useReservationDetail, useReservationHistory, useCancelReservation, useUpdateReservation, useDeleteReservation } from '../hooks/useReservations'
import { format } from 'date-fns'
import { Button, Spinner } from '../../../components/ui'

const STATUS_COLORS = {
  Pending:   'bg-yellow-100 text-yellow-800',
  Confirmed: 'bg-blue-100 text-blue-800',
  CheckedIn: 'bg-indigo-100 text-indigo-800',
  Completed: 'bg-green-100 text-green-800',
  Cancelled: 'bg-red-100 text-red-800',
}

/** Inline confirmation banner rendered inside the modal */
function InlineConfirmBanner({ action, onConfirm, onCancel, isPending }) {
  const isDanger = action === 'delete'
  return (
    <div className={`mx-6 mb-4 rounded-xl border p-4 flex items-start gap-4 ${
      isDanger
        ? 'border-red-200 bg-red-50'
        : 'border-amber-200 bg-amber-50'
    }`}>
      <span className={`material-symbols-outlined text-2xl mt-0.5 ${isDanger ? 'text-red-500' : 'text-amber-500'}`}>
        {isDanger ? 'delete_forever' : 'warning'}
      </span>
      <div className="flex-1">
        <p className={`text-sm font-semibold ${isDanger ? 'text-red-800' : 'text-amber-800'}`}>
          {isDanger ? 'Permanently delete this reservation?' : 'Cancel this reservation?'}
        </p>
        <p className={`text-xs mt-0.5 ${isDanger ? 'text-red-600' : 'text-amber-600'}`}>
          {isDanger
            ? 'This action cannot be undone. All associated data will be removed.'
            : 'The advance deposit will be refunded to the driver\'s wallet.'}
        </p>
        <div className="flex gap-2 mt-3">
          <button
            onClick={onConfirm}
            disabled={isPending}
            className={`rounded-lg px-4 py-1.5 text-xs font-semibold text-white shadow-sm transition disabled:opacity-60 ${
              isDanger ? 'bg-red-600 hover:bg-red-700' : 'bg-amber-500 hover:bg-amber-600'
            }`}
          >
            {isPending
              ? (isDanger ? 'Deleting…' : 'Cancelling…')
              : (isDanger ? 'Yes, Delete' : 'Yes, Cancel Booking')}
          </button>
          <button
            onClick={onCancel}
            disabled={isPending}
            className="rounded-lg border border-gray-200 bg-white px-4 py-1.5 text-xs font-semibold text-gray-600 transition hover:bg-gray-50 disabled:opacity-60"
          >
            Keep Reservation
          </button>
        </div>
      </div>
    </div>
  )
}

export default function ReservationDetailsModal({ reservationId, onClose }) {
  const { data: reservation, isLoading } = useReservationDetail(reservationId)
  const { data: history, isLoading: isHistoryLoading } = useReservationHistory(reservationId)
  const { mutate: cancelReservation, isPending: isCancelling } = useCancelReservation()
  const { mutate: updateReservation, isPending: isUpdating } = useUpdateReservation()
  const { mutate: deleteReservation, isPending: isDeleting } = useDeleteReservation()

  const [isEditing, setIsEditing] = useState(false)
  const [editStartTime, setEditStartTime] = useState('')
  const [editEndTime, setEditEndTime] = useState('')

  // 'delete' | 'cancel' | null
  const [confirmAction, setConfirmAction] = useState(null)

  if (!reservationId) return null

  const handleEditClick = () => {
    if (reservation) {
      setEditStartTime(format(new Date(reservation.startTime), "yyyy-MM-dd'T'HH:mm"))
      setEditEndTime(format(new Date(reservation.endTime), "yyyy-MM-dd'T'HH:mm"))
      setIsEditing(true)
    }
  }

  const handleSaveUpdate = () => {
    updateReservation(
      { id: reservationId, data: { startTime: new Date(editStartTime).toISOString(), endTime: new Date(editEndTime).toISOString() } },
      { onSuccess: () => setIsEditing(false) }
    )
  }

  const handleConfirm = () => {
    if (confirmAction === 'delete') {
      deleteReservation(reservationId, { onSuccess: onClose })
    } else if (confirmAction === 'cancel') {
      cancelReservation(reservationId, { onSuccess: onClose })
    }
  }

  const statusColor = STATUS_COLORS[reservation?.status] || 'bg-gray-100 text-gray-800'

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 p-4 backdrop-blur-sm">
      <div className="relative w-full max-w-2xl overflow-hidden rounded-2xl bg-white shadow-2xl flex flex-col max-h-[90vh]">

        {/* Header */}
        <div className="border-b px-6 py-4 flex justify-between items-center bg-gray-50 shrink-0">
          <div className="flex items-center gap-3">
            <div className="flex h-9 w-9 items-center justify-center rounded-full bg-blue-50 text-blue-600">
              <span className="material-symbols-outlined text-lg">event_note</span>
            </div>
            <h2 className="text-xl font-bold text-gray-900">Reservation Details</h2>
          </div>
          <button
            onClick={onClose}
            className="flex h-8 w-8 items-center justify-center rounded-full text-gray-400 hover:bg-gray-100 hover:text-gray-600 transition-colors"
          >
            <span className="material-symbols-outlined text-xl">close</span>
          </button>
        </div>

        {/* Inline confirm banner (shown above content, inside modal) */}
        {confirmAction && (
          <div className="pt-4 shrink-0">
            <InlineConfirmBanner
              action={confirmAction}
              onConfirm={handleConfirm}
              onCancel={() => setConfirmAction(null)}
              isPending={isCancelling || isDeleting}
            />
          </div>
        )}

        {/* Content */}
        <div className="p-6 overflow-y-auto flex-1">
          {isLoading ? (
            <div className="flex justify-center py-12"><Spinner size={24} /></div>
          ) : !reservation ? (
            <div className="flex flex-col items-center gap-2 py-12 text-center">
              <span className="material-symbols-outlined text-4xl text-red-400">error_outline</span>
              <p className="text-red-500 font-medium">Failed to load reservation details.</p>
            </div>
          ) : (
            <div className="space-y-6">
              {/* Info Grid */}
              <div className="grid grid-cols-2 gap-4">
                <div className="rounded-xl bg-gray-50 p-4 border border-gray-100">
                  <h3 className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-1">Customer</h3>
                  <div className="flex items-center gap-2 mt-1">
                    <span className="material-symbols-outlined text-gray-400 text-sm">person</span>
                    <span className="text-sm font-medium text-gray-900">
                      {reservation.driverId ? (reservation.driverName || 'Registered Driver') : 'Walk-In Customer'}
                    </span>
                  </div>
                </div>

                <div className="rounded-xl bg-gray-50 p-4 border border-gray-100">
                  <h3 className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-1">Status</h3>
                  <span className={`mt-1 inline-block rounded-full px-2.5 py-0.5 text-xs font-semibold ${statusColor}`}>
                    {reservation.status}
                  </span>
                </div>

                <div className="rounded-xl bg-gray-50 p-4 border border-gray-100">
                  <h3 className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-2">Schedule</h3>
                  {isEditing ? (
                    <div className="space-y-2">
                      <input
                        type="datetime-local"
                        value={editStartTime}
                        onChange={(e) => setEditStartTime(e.target.value)}
                        className="block w-full text-sm rounded-lg border border-gray-200 p-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
                      />
                      <input
                        type="datetime-local"
                        value={editEndTime}
                        onChange={(e) => setEditEndTime(e.target.value)}
                        className="block w-full text-sm rounded-lg border border-gray-200 p-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
                      />
                    </div>
                  ) : (
                    <div className="text-sm text-gray-900">
                      <div className="flex items-center gap-1.5 mb-0.5">
                        <span className="material-symbols-outlined text-gray-400 text-sm">calendar_today</span>
                        {format(new Date(reservation.startTime), 'MMM d, yyyy')}
                      </div>
                      <div className="flex items-center gap-1.5 text-gray-600">
                        <span className="material-symbols-outlined text-gray-400 text-sm">schedule</span>
                        {format(new Date(reservation.startTime), 'HH:mm')} – {format(new Date(reservation.endTime), 'HH:mm')}
                      </div>
                    </div>
                  )}
                </div>

                <div className="rounded-xl bg-gray-50 p-4 border border-gray-100">
                  <h3 className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-1">Station & Charger</h3>
                  <div className="text-sm text-gray-900 font-medium">{reservation.stationName || 'N/A'}</div>
                  <div className="text-xs text-gray-500 mt-0.5">Charger: {reservation.chargerName || reservation.chargerId?.substring(0, 8)}</div>
                </div>
              </div>

              {/* Deposit */}
              {reservation.advanceDepositAmount > 0 && (
                <div className="rounded-xl bg-emerald-50 p-4 border border-emerald-100 flex items-center gap-4">
                  <div className="flex h-10 w-10 items-center justify-center rounded-full bg-emerald-100 text-emerald-600">
                    <span className="material-symbols-outlined">payments</span>
                  </div>
                  <div>
                    <h3 className="text-xs font-semibold text-emerald-700 uppercase tracking-wider">Advance Deposit Paid</h3>
                    <div className="text-xl font-bold text-emerald-600 mt-0.5">Rs. {reservation.advanceDepositAmount.toFixed(2)}</div>
                  </div>
                </div>
              )}

              {/* Status Timeline */}
              <div>
                <h3 className="text-sm font-semibold text-gray-900 uppercase tracking-wider mb-4 flex items-center gap-2">
                  <span className="material-symbols-outlined text-gray-400 text-sm">history</span>
                  Status History
                </h3>
                {isHistoryLoading ? (
                  <div className="flex justify-center"><Spinner size={20} /></div>
                ) : !history || history.length === 0 ? (
                  <div className="text-gray-400 text-sm text-center py-4">No history available.</div>
                ) : (
                  <div className="space-y-3 border-l-2 border-gray-200 ml-3 pl-4">
                    {history.map((h, i) => (
                      <div key={i} className="relative">
                        <div className="absolute -left-[1.35rem] w-3 h-3 bg-blue-500 rounded-full border-2 border-white ring-2 ring-blue-100" />
                        <div className="text-sm font-semibold text-gray-900">{h.newStatus}</div>
                        <div className="text-xs text-gray-400 mt-0.5">
                          {format(new Date(h.changedAt), 'MMM d, yyyy HH:mm')}
                          {h.changedByUserId && ` · User ${h.changedByUserId.substring(0, 8)}`}
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
        <div className="border-t bg-gray-50 px-6 py-4 flex justify-between gap-3 rounded-b-2xl shrink-0">
          <div className="flex gap-2">
            <Button
              variant="danger"
              onClick={() => setConfirmAction('delete')}
              disabled={isDeleting || !reservation || !!confirmAction}
            >
              <span className="material-symbols-outlined text-sm">delete</span>
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
                onClick={() => setConfirmAction('cancel')}
                disabled={isCancelling || !!confirmAction}
                className="border-amber-300 text-amber-700 hover:bg-amber-50"
              >
                <span className="material-symbols-outlined text-sm">cancel</span>
                {isCancelling ? 'Cancelling...' : 'Cancel Booking'}
              </Button>
            ) : null}
          </div>
        </div>
      </div>
    </div>
  )
}
