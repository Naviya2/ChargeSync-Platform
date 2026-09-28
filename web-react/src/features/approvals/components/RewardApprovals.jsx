import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import apiClient from '../../../api/client'

export default function RewardApprovals() {
  const cache = useQueryClient()
  const query = useQuery({ queryKey: ['reward-redemptions'], queryFn: async () => (await apiClient.get('/loyalty/redemptions')).data })
  const review = useMutation({
    mutationFn: ({ id, approve }) => apiClient.post(`/loyalty/redemptions/${id}/review`, { approve }),
    onSuccess: () => cache.invalidateQueries({ queryKey: ['reward-redemptions'] }),
  })
  return (
    <section className="rounded-xl bg-surface-container-lowest p-space-xl text-on-surface">
      <h2 className="text-xl font-bold mb-2">Loyalty reward approvals</h2>
      <p className="text-on-surface-variant mb-4">Approval credits the driver’s wallet. Rejection releases the reserved points.</p>
      {query.isPending && <p>Loading reward requests…</p>}
      {(query.error || review.error) && <p role="alert" className="text-red-500">{(review.error || query.error)?.response?.data?.detail || 'Unable to process rewards. Refresh and try again.'}</p>}
      <button onClick={() => query.refetch()} disabled={review.isPending} className="text-primary mb-4">Refresh rewards</button>
      {query.data?.length === 0 && <p>No reward requests yet.</p>}
      <div className="space-y-4">
        {query.data?.map(row => <article key={row.id} className="border border-outline rounded-lg p-4">
          <div className="flex flex-wrap justify-between gap-2"><strong>{row.rewardDescription}</strong><span>{row.status}</span></div>
          <p className="break-all text-sm text-on-surface-variant">Driver: {row.driverId}</p>
          <p>{row.pointsRedeemed.toLocaleString()} points • LKR {row.walletCredit.toFixed(2)} wallet credit</p>
          <p className="text-sm">Requested {new Date(row.createdAt).toLocaleString()}</p>
          {row.status === 'Pending' && <div className="flex gap-4 mt-3">
            <button className="text-primary" disabled={review.isPending} onClick={() => { if (window.confirm(`Credit LKR ${row.walletCredit.toFixed(2)} to this driver?`)) review.mutate({ id: row.id, approve: true }) }}>Approve credit</button>
            <button className="text-red-500" disabled={review.isPending} onClick={() => { if (window.confirm('Reject this request and return its points?')) review.mutate({ id: row.id, approve: false }) }}>Reject & return points</button>
          </div>}
        </article>)}
      </div>
    </section>
  )
}
