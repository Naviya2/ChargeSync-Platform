import { useState } from 'react'
import { useWaitlistApprovals, useApproveWaitlistOverride, useRejectWaitlistOverride } from '../hooks/useWaitlistApprovals'

export default function WaitlistApprovals() {
  const { data: requests = [], isLoading } = useWaitlistApprovals()
  const approveMutation = useApproveWaitlistOverride()
  const rejectMutation = useRejectWaitlistOverride()

  const [rejectId, setRejectId] = useState(null)
  const [rejectReason, setRejectReason] = useState('')

  if (isLoading) {
    return (
      <div className="flex flex-col gap-space-2xs mt-space-2xl">
        <h2 className="font-headline-sm text-on-surface">AI Waitlist Overrides</h2>
        <p className="font-body-md text-on-surface-variant">Loading AI override requests...</p>
      </div>
    )
  }

  if (requests.length === 0) {
    return (
      <div className="flex flex-col gap-space-2xs mb-space-2xl bg-white p-6 rounded-xl border border-gray-100 shadow-sm text-center">
        <span className="material-symbols-outlined text-4xl text-gray-300 mb-2">check_circle</span>
        <h2 className="font-headline-sm text-gray-900">No Waitlist Requests</h2>
        <p className="font-body-md text-gray-500">There are no pending waitlist requests or AI overrides at the moment.</p>
      </div>
    )
  }

  return (
    <div className="flex flex-col gap-space-md mb-space-2xl">
      <div className="flex flex-col gap-space-2xs">
        <h2 className="font-headline-sm text-on-surface flex items-center gap-2">
          <span className="material-symbols-outlined text-warning">warning</span>
          AI Waitlist Overrides (Pending Approval)
        </h2>
        <p className="font-body-md text-on-surface-variant">
          The Agentic AI planner has requested to override the waitlist queue for these bookings. Please review.
        </p>
      </div>

      <div className="grid grid-cols-1 xl:grid-cols-2 gap-space-md">
        {requests.map(request => (
          <div key={request.id} className="rounded-xl bg-surface-container-lowest shadow-sm border border-warning/30 flex flex-col p-space-lg">
            <div className="flex justify-between items-start mb-space-sm">
              <div className="flex flex-col">
                <h3 className="font-label-lg text-on-surface font-bold">{request.driverName}</h3>
                <p className="font-body-sm text-on-surface-variant">Station: {request.stationName}</p>
                <p className="font-body-sm text-on-surface-variant">Time: {new Date(request.requestedTime).toLocaleString()}</p>
              </div>
              <div className="bg-warning/10 text-warning px-space-sm py-1 rounded-full border border-warning/20">
                <span className="font-label-sm font-bold">AI Priority</span>
              </div>
            </div>

            <div className="bg-surface-container rounded-lg p-space-sm mb-space-md border-l-4 border-primary">
              <p className="font-body-sm text-on-surface italic">" {request.reason} "</p>
            </div>

            <div className="mt-auto flex justify-end gap-space-sm">
              {rejectId !== request.id ? (
                <>
                  <button
                    className="rounded-lg bg-error-container px-space-md py-space-xs text-on-error-container font-label-md transition-colors hover:bg-error hover:text-on-error"
                    onClick={() => setRejectId(request.id)}
                  >
                    Reject
                  </button>
                  <button
                    className="rounded-lg bg-primary px-space-md py-space-xs text-on-primary font-label-md transition-colors hover:bg-primary/90"
                    onClick={() => approveMutation.mutate(request.id)}
                  >
                    Approve Override
                  </button>
                </>
              ) : (
                <div className="flex w-full items-center gap-space-sm">
                  <input
                    type="text"
                    className="flex-1 rounded-lg border border-outline bg-surface px-space-sm py-1 text-sm text-on-surface"
                    placeholder="Reason..."
                    value={rejectReason}
                    onChange={(e) => setRejectReason(e.target.value)}
                  />
                  <button
                    className="rounded-lg border border-outline px-3 py-1 text-sm text-on-surface hover:bg-surface-container"
                    onClick={() => setRejectId(null)}
                  >
                    Cancel
                  </button>
                  <button
                    className="rounded-lg bg-error px-3 py-1 text-sm text-on-error hover:bg-error/90"
                    onClick={() => {
                      rejectMutation.mutate({ id: request.id, reason: rejectReason })
                      setRejectId(null)
                      setRejectReason('')
                    }}
                  >
                    Confirm
                  </button>
                </div>
              )}
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
