import { usePendingApprovalsQuery, useApproveReservation, useRejectReservation } from '../../reservations/hooks/useReservations'
import { format, isValid } from 'date-fns'
import { Clock3, Check, X, ChevronDown } from 'lucide-react'
import { Button } from '../../../components/ui'

const when = value => isValid(new Date(value)) ? format(new Date(value), 'dd MMM, HH:mm') : 'Time unavailable'

export default function PendingApprovalsCard() {
  const query = usePendingApprovalsQuery({ refetchInterval: 10000 })
  const approveMutation = useApproveReservation()
  const rejectMutation = useRejectReservation()
  const requests = query.data?.items ?? []
  const busy = approveMutation.isPending || rejectMutation.isPending
  const error = approveMutation.error ?? rejectMutation.error

  if (query.isLoading || !requests.length) return null

  return <details className="rv-approvals rounded-xl bg-surface-container-lowest shadow-sm">
    <summary><span className="rv-approval-icon"><Clock3 size={18} /></span><div><h2>Pending booking requests <span>{query.data?.totalCount ?? requests.length}</span></h2><p>Review these requests before confirming a charging slot.</p></div><ChevronDown size={17} /></summary>
    <div className="rv-approval-list">
      {error && <p role="alert" className="rv-approval-error">{error.response?.data?.detail ?? error.response?.data?.message ?? 'The request could not be updated. Try again.'}</p>}
      {requests.map(request => <div className="rv-approval-row" key={request.id}><div><strong>{request.driverName || 'Driver'}<span> · {request.vehicleName || 'Vehicle'}</span></strong><p>{request.stationName} · {request.chargerName}</p><span>{when(request.startTime)} – {when(request.endTime)}</span></div><div className="rv-approval-actions"><Button variant="outline" size="sm" onClick={() => rejectMutation.mutate(request.id)} disabled={busy}><X size={13} /> Decline</Button><Button size="sm" onClick={() => approveMutation.mutate(request.id)} disabled={busy}><Check size={13} /> Approve slot</Button></div></div>)}
      {(query.data?.totalCount ?? requests.length) > requests.length && <p className="rv-approval-more">Showing {requests.length} requests. Further requests appear here as these are reviewed.</p>}
    </div>
  </details>
}
