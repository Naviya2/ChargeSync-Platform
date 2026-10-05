import { useState } from 'react'
import { useReservationDetail, useReservationHistory, useCancelReservation, useUpdateReservation, useDeleteReservation, useApproveReservation, useRejectReservation } from '../hooks/useReservations'
import { format } from 'date-fns'
import { Button, Spinner } from '../../../components/ui'
import { useAuthStore } from '../../../store/authStore'

const STATUS_COLORS = {
  Pending:   'bg-yellow-100 text-yellow-800',
  Confirmed: 'bg-blue-100 text-blue-800',
  CheckedIn: 'bg-indigo-100 text-indigo-800',
  Completed: 'bg-green-100 text-green-800',
  Cancelled: 'bg-red-100 text-red-800',
}

/** Inline confirmation banner rendered inside the modal */
function InlineConfirmBanner({ action, onConfirm, onCancel, isPending, isDriver }) {
  let isDanger = false;
  let isSuccess = false;
  let title = '';
  let subtitle = '';
  let confirmText = '';
  let icon = '';

  if (action === 'delete') {
    isDanger = true;
    title = 'Permanently delete this reservation?';
    subtitle = 'This action cannot be undone. All associated data will be removed.';
    confirmText = isPending ? 'Deleting…' : 'Yes, Delete';
    icon = 'delete_forever';
  } else if (action === 'cancel') {
    title = 'Cancel this reservation?';
    subtitle = isDriver
      ? 'Your advance deposit will be refunded. Cancelling less than 2 hours before the booked start (including after it) adds a LKR 500 fee to your next booking. Cancelling 2 hours or more before start is free. Previously paid cancellation fees are not refunded.'
      : 'Staff cancellation does not add a late fee. The advance deposit will be refunded to the driver. Previously paid cancellation fees are not refunded.';
    confirmText = isPending ? 'Cancelling…' : 'Yes, Cancel Booking';
    icon = 'warning';
  } else if (action === 'approve') {
    isSuccess = true;
    title = 'Approve this reservation request?';
    subtitle = 'The driver will be charged the advance fee and the slot will be confirmed.';
    confirmText = isPending ? 'Approving…' : 'Yes, Approve';
    icon = 'check_circle';
  } else if (action === 'reject') {
    isDanger = true;
    title = 'Reject this reservation request?';
    subtitle = 'The driver will be notified that the request was declined.';
    confirmText = isPending ? 'Rejecting…' : 'Yes, Reject';
    icon = 'cancel';
  }

  const bgClass = isDanger ? 'border-red-200 bg-red-50' : isSuccess ? 'border-green-200 bg-green-50' : 'border-amber-200 bg-amber-50';
  const textClass = isDanger ? 'text-red-800' : isSuccess ? 'text-green-800' : 'text-amber-800';
  const subTextClass = isDanger ? 'text-red-600' : isSuccess ? 'text-green-600' : 'text-amber-600';
  const iconClass = isDanger ? 'text-red-500' : isSuccess ? 'text-green-500' : 'text-amber-500';
  const btnClass = isDanger ? 'bg-red-600 hover:bg-red-700' : isSuccess ? 'bg-green-600 hover:bg-green-700' : 'bg-amber-500 hover:bg-amber-600';

  return (
    <div className={`mx-6 mb-4 rounded-xl border p-4 flex items-start gap-4 ${bgClass}`}>
      <span className={`material-symbols-outlined text-2xl mt-0.5 ${iconClass}`}>
        {icon}
      </span>
      <div className="flex-1">
        <p className={`text-sm font-semibold ${textClass}`}>
          {title}
        </p>
        <p className={`text-xs mt-0.5 ${subTextClass}`}>
          {subtitle}
        </p>
        <div className="flex gap-2 mt-3">
          <button
            onClick={onConfirm}
            disabled={isPending}
            className={`rounded-lg px-4 py-1.5 text-xs font-semibold text-white shadow-sm transition disabled:opacity-60 ${btnClass}`}
          >
            {confirmText}
          </button>
          <button
            onClick={onCancel}
            disabled={isPending}
            className="rounded-lg border border-gray-200 bg-white px-4 py-1.5 text-xs font-semibold text-gray-600 transition hover:bg-gray-50 disabled:opacity-60"
          >
            Cancel
          </button>
        </div>
      </div>
    </div>
  )
}

export default function ReservationDetailsModal({ reservationId, onClose, readOnly = false }) {
  const isDriver = useAuthStore((state) => state.user?.role === 'Driver')
  const { data: reservation, isLoading } = useReservationDetail(reservationId)
  const { data: history, isLoading: isHistoryLoading } = useReservationHistory(reservationId)
  const { mutate: cancelReservation, isPending: isCancelling } = useCancelReservation()
  const { mutate: updateReservation, isPending: isUpdating } = useUpdateReservation()
  const { mutate: deleteReservation, isPending: isDeleting } = useDeleteReservation()
  const { mutate: approveReservation, isPending: isApproving } = useApproveReservation()
  const { mutate: rejectReservation, isPending: isRejecting } = useRejectReservation()

  const [isEditing, setIsEditing] = useState(false)
  const [editStartTime, setEditStartTime] = useState('')
  const [editEndTime, setEditEndTime] = useState('')

  // 'delete' | 'cancel' | 'approve' | 'reject' | null
  const [confirmAction, setConfirmAction] = useState(null)

  if (!reservationId) return null

  const handleEditClick = () => {
    if (reservation) {
      setEditStartTime(format(new Date(reservation.startTime), "yyyy-MM-dd'T'HH:mm"))
      setEditEndTime(format(new Date(reservation.endTime), "yyyy-MM-dd'T'HH:mm"))
      setIsEditing(true)
    }
  }

  const handleStartTimeChange = (e) => {
    const newStartStr = e.target.value
    setEditStartTime(newStartStr)
    
    if (reservation && newStartStr) {
       const originalStart = new Date(reservation.startTime)
       const originalEnd = new Date(reservation.endTime)
       const durationMs = originalEnd.getTime() - originalStart.getTime()
       
       const newStart = new Date(newStartStr)
       const newEnd = new Date(newStart.getTime() + durationMs)
       setEditEndTime(format(newEnd, "yyyy-MM-dd'T'HH:mm"))
    }
  }

  const handleSaveUpdate = () => {
    updateReservation(
      { id: reservationId, data: { startTime: new Date(editStartTime).toISOString(), endTime: new Date(editEndTime).toISOString() } },
      { 
        onSuccess: () => setIsEditing(false),
        onError: (error) => {
          const msg = error.response?.data?.detail || error.response?.data?.message || error.response?.data?.title || error.message || 'Unknown error occurred.';
          window.alert(`Can't change the reservation time.\n\n${msg}`);
        }
      }
    )
  }

  const handleConfirm = () => {
    if (confirmAction === 'delete') {
      deleteReservation(reservationId, { onSuccess: onClose })
    } else if (confirmAction === 'cancel') {
      cancelReservation(reservationId, { onSuccess: onClose })
    } else if (confirmAction === 'approve') {
      approveReservation(reservationId, { onSuccess: onClose })
    } else if (confirmAction === 'reject') {
      rejectReservation(reservationId, { onSuccess: onClose })
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
              isPending={isCancelling || isDeleting || isApproving || isRejecting}
              isDriver={isDriver}
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
                        onChange={handleStartTimeChange}
                        className="block w-full text-sm rounded-lg border border-gray-200 p-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
                      />
                      <input
                        type="datetime-local"
                        value={editEndTime}
                        readOnly
                        disabled
                        className="block w-full text-sm rounded-lg border border-gray-200 p-2 bg-gray-100 text-gray-500 cursor-not-allowed"
                        title="End time is automatically calculated based on vehicle and charger capacity."
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

              {/* Walk-in Details */}
              {!reservation.driverId && (
                <div className="rounded-xl bg-indigo-50 p-4 border border-indigo-100 flex items-center gap-4">
                  <div className="flex h-10 w-10 items-center justify-center rounded-full bg-indigo-100 text-indigo-600">
                    <span className="material-symbols-outlined">badge</span>
                  </div>
                  <div className="flex-1">
                    <h3 className="text-xs font-semibold text-indigo-700 uppercase tracking-wider">Walk-In Customer Details</h3>
                    <div className="grid grid-cols-3 gap-4 mt-2">
                      <div>
                        <div className="text-xs text-indigo-500 font-medium">Name</div>
                        <div className="text-sm font-bold text-indigo-700">{reservation.walkInCustomerName || 'N/A'}</div>
                      </div>
                      <div>
                        <div className="text-xs text-indigo-500 font-medium">Vehicle No.</div>
                        <div className="text-sm font-bold text-indigo-700">{reservation.walkInVehicleNumber || 'N/A'}</div>
                      </div>
                      <div>
                        <div className="text-xs text-indigo-500 font-medium">Battery Capacity</div>
                        <div className="text-sm font-bold text-indigo-700">{reservation.walkInBatteryCapacity ? `${reservation.walkInBatteryCapacity} kWh` : 'N/A'}</div>
                      </div>
                    </div>
                  </div>
                </div>
              )}

              {/* Deposit */}
              {(reservation.lateCancellationFee > 0 || reservation.cancellationFeesPaid > 0) && (
                <div className="rounded-xl border border-amber-200 bg-amber-50 p-4 text-sm text-amber-900">
                  {reservation.lateCancellationFee > 0 && <p>Late cancellation fee assessed: LKR {reservation.lateCancellationFee.toFixed(2)}. Charged with the driver&apos;s next booking.</p>}
                  {reservation.cancellationFeesPaid > 0 && <p>Previous cancellation fees paid with this booking: LKR {reservation.cancellationFeesPaid.toFixed(2)} (non-refundable; separate from the advance).</p>}
                </div>
              )}
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

              {/* Invoice Details */}
              {reservation.status === 'Completed' && reservation.invoiceNetAmount != null && (
                <div className="rounded-xl bg-blue-50 p-4 border border-blue-100 mt-4 flex items-center gap-4">
                  <div className="flex h-10 w-10 items-center justify-center rounded-full bg-blue-100 text-blue-600">
                    <span className="material-symbols-outlined">receipt_long</span>
                  </div>
                  <div className="flex-1">
                    <h3 className="text-xs font-semibold text-blue-700 uppercase tracking-wider">Final Session Invoice</h3>
                    <div className="grid grid-cols-3 gap-4 mt-2">
                      <div>
                        <div className="text-xs text-blue-500 font-medium">Final Cost</div>
                        <div className="text-sm font-bold text-blue-700">Rs. {reservation.invoiceNetAmount.toFixed(2)}</div>
                      </div>
                      <div>
                        <div className="text-xs text-blue-500 font-medium">Energy</div>
                        <div className="text-sm font-bold text-blue-700">{reservation.finalEnergyDeliveredKwh?.toFixed(2) || 'N/A'} kWh</div>
                      </div>
                      <div>
                        <div className="text-xs text-blue-500 font-medium">Payment Method</div>
                        <div className="text-sm font-bold text-blue-700">{reservation.invoicePaymentMethod || 'N/A'}</div>
                      </div>
                    </div>
                  </div>
                </div>
              )}

              {/* Meter Photo */}
              {reservation.sessionMeterPhotoUrl && (
                <div className="rounded-xl bg-gray-50 p-4 border border-gray-100 mt-4">
                  <h3 className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-2">Meter Photo</h3>
                  <a href={reservation.sessionMeterPhotoUrl} target="_blank" rel="noopener noreferrer" className="block max-w-sm">
                    <img src={reservation.sessionMeterPhotoUrl} alt="Meter Reading" className="max-h-48 rounded-lg object-contain border border-gray-200 bg-white" />
                  </a>
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
            {!readOnly && <Button
              variant="danger"
              onClick={() => setConfirmAction('delete')}
              disabled={isDeleting || !reservation || !!confirmAction}
            >
              <span className="material-symbols-outlined text-sm">delete</span>
              {isDeleting ? 'Deleting...' : 'Delete'}
            </Button>}
          </div>
          <div className="flex gap-2">
            <Button variant="outline" onClick={onClose}>Close</Button>
            {!readOnly && <>
            {reservation?.status === 'Pending' ? (
              <>
                <Button 
                  variant="danger" 
                  onClick={() => setConfirmAction('reject')}
                  disabled={isRejecting || !!confirmAction}
                  className="bg-red-600 hover:bg-red-700 text-white"
                >
                  <span className="material-symbols-outlined text-sm">cancel</span>
                  {isRejecting ? 'Rejecting...' : 'Reject Request'}
                </Button>
                <Button 
                  variant="brand" 
                  onClick={() => setConfirmAction('approve')}
                  disabled={isApproving || !!confirmAction}
                  className="bg-green-600 hover:bg-green-700 text-white"
                >
                  <span className="material-symbols-outlined text-sm">check_circle</span>
                  {isApproving ? 'Approving...' : 'Approve Request'}
                </Button>
              </>
            ) : isEditing ? (
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

            {(reservation?.status === 'Confirmed') && !isEditing ? (
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
            </>}
          </div>
        </div>
      </div>
    </div>
  )
}
