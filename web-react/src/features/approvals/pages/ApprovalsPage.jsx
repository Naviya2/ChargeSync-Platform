import { useState } from 'react'
import { usePendingStations, useApproveStation, useRejectStation } from '../hooks/useAdminStations'
import { cn } from '../../../lib/cn'

export default function ApprovalsPage() {
  const { data: pendingStations = [], isLoading } = usePendingStations()
  const approveMutation = useApproveStation()
  const rejectMutation = useRejectStation()

  const [rejectId, setRejectId] = useState(null)
  const [rejectReason, setRejectReason] = useState('')
  const [viewImage, setViewImage] = useState(null)
  const [expandedId, setExpandedId] = useState(null)

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

  const toggleExpand = (id) => {
    setExpandedId(prev => prev === id ? null : id)
    setRejectId(null) 
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
            <div key={station.id} className="rounded-xl bg-surface-container-lowest shadow-sm border border-outline flex flex-col overflow-hidden transition-all duration-300">
              
              {/* Header (Always Visible) */}
              <div 
                className="p-space-lg flex justify-between items-center cursor-pointer hover:bg-surface-container-low transition-colors"
                onClick={() => toggleExpand(station.id)}
              >
                <div className="flex flex-col gap-1">
                  <h3 className="font-headline-md text-on-surface">{station.name}</h3>
                  <p className="font-body-md text-on-surface-variant truncate max-w-2xl">{station.address}</p>
                </div>
                <div className="flex items-center gap-space-md pl-4">
                  <span className={cn("material-symbols-outlined text-on-surface-variant transition-transform duration-300", expandedId === station.id && "rotate-180")}>
                    expand_more
                  </span>
                </div>
              </div>

              {/* Expanded Content */}
              {expandedId === station.id && (
                <div className="border-t border-outline bg-surface p-space-lg flex flex-col gap-space-xl animate-in fade-in slide-in-from-top-4 duration-300">
                  
                  {/* Grid of Details */}
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-space-xl">
                    {/* Station Details */}
                    <div className="flex flex-col gap-space-xs">
                      <h4 className="font-label-lg text-on-surface mb-2 flex items-center gap-2">
                        <span className="material-symbols-outlined text-primary text-xl">ev_station</span>
                        Station Information
                      </h4>
                      <p className="font-body-sm text-on-surface-variant"><strong className="text-on-surface font-medium">Address:</strong> {station.address}</p>
                    </div>
                    
                    {/* Owner Details */}
                    <div className="flex flex-col gap-space-xs">
                      <h4 className="font-label-lg text-on-surface mb-2 flex items-center gap-2">
                        <span className="material-symbols-outlined text-primary text-xl">person</span>
                        Owner Details
                      </h4>
                      {station.owner ? (
                        <>
                          <p className="font-body-sm text-on-surface-variant"><strong className="text-on-surface font-medium">Name:</strong> {station.owner.name || 'N/A'}</p>
                          <p className="font-body-sm text-on-surface-variant"><strong className="text-on-surface font-medium">Email:</strong> {station.owner.email || 'N/A'}</p>
                          <p className="font-body-sm text-on-surface-variant"><strong className="text-on-surface font-medium">Phone:</strong> {station.owner.phone || 'N/A'}</p>
                        </>
                      ) : (
                        <p className="font-body-sm text-on-surface-variant italic">Owner details not provided</p>
                      )}
                    </div>
                  </div>

                  {/* Business Documents */}
                  {station.documentUrls && station.documentUrls.length > 0 && (
                    <div className="flex flex-col gap-space-xs border-t border-outline pt-space-lg">
                      <h4 className="font-label-lg text-on-surface mb-2 flex items-center gap-2">
                        <span className="material-symbols-outlined text-primary text-xl">folder_shared</span>
                        Business Documents
                      </h4>
                      <div className="flex flex-wrap gap-space-sm">
                        {station.documentUrls.map((url, idx) => (
                          <button
                            key={idx}
                            type="button"
                            className="flex items-center gap-2 rounded-lg border border-outline bg-surface px-space-md py-space-sm text-on-surface hover:bg-surface-container transition-colors shadow-sm hover:border-primary/50"
                            onClick={(e) => { e.stopPropagation(); setViewImage(url); }}
                          >
                            <span className="material-symbols-outlined text-primary">description</span>
                            <span className="font-label-md">View Document {station.documentUrls.length > 1 ? idx + 1 : ''}</span>
                          </button>
                        ))}
                      </div>
                    </div>
                  )}

                  {/* Action Buttons */}
                  <div className="flex justify-end gap-space-sm border-t border-outline pt-space-lg mt-space-sm">
                    {rejectId !== station.id ? (
                      <>
                        <button
                          className="rounded-lg bg-error-container px-space-xl py-space-sm text-on-error-container font-label-md transition-colors hover:bg-error hover:text-on-error"
                          onClick={(e) => { e.stopPropagation(); setRejectId(station.id); }}
                        >
                          Reject
                        </button>
                        <button
                          className="rounded-lg bg-primary px-space-xl py-space-sm text-on-primary font-label-md transition-colors hover:bg-primary/90 shadow-sm"
                          onClick={(e) => { e.stopPropagation(); handleApprove(station.id); }}
                        >
                          Approve Station
                        </button>
                      </>
                    ) : (
                      <div className="w-full bg-error-container/30 rounded-lg p-space-md flex flex-col gap-space-sm border-l-4 border-error">
                        <p className="font-label-md text-on-surface">Provide a rejection reason:</p>
                        <input
                          type="text"
                          className="rounded-lg border border-outline bg-surface p-space-sm text-on-surface w-full focus:outline-error"
                          placeholder="e.g. Missing required ownership documents"
                          value={rejectReason}
                          onChange={(e) => setRejectReason(e.target.value)}
                        />
                        <div className="flex justify-end gap-space-sm mt-space-2xs">
                          <button
                            className="rounded-lg border border-outline px-space-md py-space-xs text-on-surface font-label-md hover:bg-surface-container transition-colors"
                            onClick={(e) => {
                              e.stopPropagation()
                              setRejectId(null)
                              setRejectReason('')
                            }}
                          >
                            Cancel
                          </button>
                          <button
                            className="rounded-lg bg-error px-space-md py-space-xs text-on-error font-label-md hover:bg-error/90 transition-colors"
                            onClick={(e) => { e.stopPropagation(); handleReject(station.id); }}
                          >
                            Confirm Rejection
                          </button>
                        </div>
                      </div>
                    )}
                  </div>
                </div>
              )}
            </div>
          ))}
        </div>
      )}

      {/* Lightbox / Modal */}
      {viewImage && (
        <div 
          className="fixed inset-0 z-[100] flex items-center justify-center bg-black/90 p-space-xl cursor-pointer backdrop-blur-sm animate-in fade-in duration-200" 
          onClick={() => setViewImage(null)}
        >
          <img src={viewImage} alt="Document View" className="max-h-full max-w-full rounded-lg shadow-2xl animate-in zoom-in-95 duration-200" />
          <button className="absolute top-space-lg right-space-lg text-white flex items-center justify-center hover:bg-white/20 p-2 rounded-full transition-colors">
            <span className="material-symbols-outlined text-[32px]">close</span>
          </button>
        </div>
      )}
    </div>
  )
}
