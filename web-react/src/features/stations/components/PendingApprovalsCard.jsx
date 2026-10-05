import React from 'react'
import { usePendingApprovalsQuery, useApproveReservation, useRejectReservation } from '../../reservations/hooks/useReservations'
import { format } from 'date-fns'

export default function PendingApprovalsCard() {
  const { data: response, isLoading } = usePendingApprovalsQuery()
  const approveMutation = useApproveReservation()
  const rejectMutation = useRejectReservation()

  const pendingApprovals = response?.items || []

  if (isLoading) return null
  if (pendingApprovals.length === 0) return null

  return (
    <div className="bg-surface rounded-lg shadow-sm border border-border p-space-lg mb-space-xl">
      <h3 className="text-xl font-semibold mb-space-md flex items-center text-warning">
        <span className="material-symbols-outlined mr-space-sm">warning</span>
        Action Required: Pending Approvals
      </h3>
      <div className="flex flex-col gap-space-md">
        {pendingApprovals.map((approval) => (
          <div key={approval.id} className="p-space-md border border-border rounded-md bg-background flex flex-col md:flex-row md:items-center justify-between gap-space-md">
            <div>
              <div className="font-medium text-text-primary">
                {approval.driverName} - {approval.vehicleName}
              </div>
              <div className="text-sm text-text-secondary mt-1">
                Target: {approval.stationName} ({approval.chargerName})
              </div>
              <div className="text-sm text-text-secondary">
                Scheduled: {format(new Date(approval.startTime), 'MMM d, h:mm a')} - {format(new Date(approval.endTime), 'h:mm a')}
              </div>
              <div className="mt-space-sm text-sm text-warning font-medium flex items-center bg-warning/10 p-1 rounded">
                <span className="material-symbols-outlined text-[16px] mr-1">timer</span>
                ⚠️ Maintenance Buffer: Finishes near scheduled maintenance or closing time.
              </div>
            </div>
            <div className="flex gap-space-sm shrink-0">
              <button
                className="rounded-lg px-4 py-1.5 text-xs font-semibold border border-red-200 text-red-600 hover:bg-red-50 disabled:opacity-60 transition"
                onClick={() => rejectMutation.mutate(approval.id)}
                disabled={approveMutation.isPending || rejectMutation.isPending}
              >
                Decline & Free Charger
              </button>
              <button
                className="rounded-lg px-4 py-1.5 text-xs font-semibold bg-green-600 text-white hover:bg-green-700 disabled:opacity-60 shadow-sm transition"
                onClick={() => approveMutation.mutate(approval.id)}
                disabled={approveMutation.isPending || rejectMutation.isPending}
              >
                Approve Slot
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
