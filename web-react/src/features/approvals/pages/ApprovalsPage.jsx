import { useState } from 'react'
import { usePendingStations, useApproveStation, useRejectStation } from '../hooks/useAdminStations'
import { cn } from '../../../lib/cn'

export default function ApprovalsPage() {
  const { data: pendingStations = [], isLoading } = usePendingStations()
  const approveMutation = useApproveStation()
  const rejectMutation = useRejectStation()

  const [rejectId, setRejectId] = useState(null)
  const [rejectReason, setRejectReason] = useState('')

  if (isLoading) {
    return (
      <div className="flex w-full items-center justify-center pt-space-3xl">
        <p className="font-body-md text-on-surface-variant">Loading pending stations...</p>
      </div>
    )
  }

  const handleApprove = (id) => {
    approveMutation.mutate(id)
  }

  const handleReject = (id) => {
    if (!rejectReason) return
    rejectMutation.mutate({ id, reason: rejectReason }, {
      onSuccess: () => {
        setRejectId(null)
        setRejectReason('')
      }
    })
  }

  return (
    <div className="flex w-full flex-col gap-space-xl p-space-xl">
      <div className="flex flex-col gap-space-2xs">
        <h1 className="font-headline-lg text-headline-lg text-on-surface">Station Approvals</h1>
        <p className="font-body-md text-body-md text-on-surface-variant">
          Review pending station registrations and either approve or reject them.
        </p>
      </div>

      {pendingStations.length === 0 ? (
        <div className="rounded-xl bg-surface-container-lowest p-space-xl shadow-sm text-center">
          <p className="font-body-lg text-on-surface">No pending stations requiring approval.</p>
        </div>
      ) : (
        <div className="flex flex-col gap-space-md">
          {pendingStations.map(station => (
            <div key={station.id} className="rounded-xl bg-surface-container-lowest p-space-lg shadow-sm border border-outline flex flex-col gap-space-md">
              <div className="flex justify-between items-start">
                <div>
                  <h3 className="font-headline-md text-on-surface">{station.name}</h3>
                  <p className="font-body-md text-on-surface-variant">{station.address}</p>
                  <p className="font-body-sm text-on-surface-variant mt-2 text-xs">Lat: {station.latitude} | Lng: {station.longitude}</p>
                </div>
                <div className="flex gap-space-sm">
                  {rejectId !== station.id && (
                    <>
                      <button
                        className="rounded bg-error-container px-space-md py-space-xs text-on-error-container font-label-md transition-colors hover:bg-error hover:text-on-error"
                        onClick={() => setRejectId(station.id)}
                      >
                        Reject
                      </button>
                      <button
                        className="rounded bg-primary px-space-md py-space-xs text-on-primary font-label-md transition-colors hover:bg-primary/90"
                        onClick={() => handleApprove(station.id)}
                      >
                        Approve
                      </button>
                    </>
                  )}
                </div>
              </div>

              {rejectId === station.id && (
                <div className="mt-space-sm bg-surface-container-high rounded p-space-md flex flex-col gap-space-sm border-l-4 border-error">
                  <p className="font-label-md text-on-surface">Provide a rejection reason:</p>
                  <input
                    type="text"
                    className="rounded border border-outline bg-surface p-space-xs text-on-surface"
                    placeholder="e.g. Missing required ownership documents"
                    value={rejectReason}
                    onChange={(e) => setRejectReason(e.target.value)}
                  />
                  <div className="flex gap-space-sm mt-space-2xs">
                    <button
                      className="rounded border border-outline px-space-md py-space-xs text-on-surface font-label-md hover:bg-surface-container"
                      onClick={() => {
                        setRejectId(null)
                        setRejectReason('')
                      }}
                    >
                      Cancel
                    </button>
                    <button
                      className="rounded bg-error px-space-md py-space-xs text-on-error font-label-md hover:bg-error/90"
                      onClick={() => handleReject(station.id)}
                    >
                      Confirm Rejection
                    </button>
                  </div>
                </div>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
