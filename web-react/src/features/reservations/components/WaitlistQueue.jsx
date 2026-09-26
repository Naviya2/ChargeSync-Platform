import { useQuery } from '@tanstack/react-query'
import apiClient, { unwrap } from '../../../api/client'
import { Card, Spinner } from '../../../components/ui'
import { format } from 'date-fns'

function useWaitlist(chargerId) {
    return useQuery({
        queryKey: ['waitlist', chargerId],
        queryFn: () => unwrap(apiClient.get(`/waitlist/charger/${chargerId}`)),
        enabled: !!chargerId,
    })
}

export default function WaitlistQueue({ chargerId }) {
    const { data: waitlist, isLoading } = useWaitlist(chargerId)

    if (!chargerId) return null

    return (
        <Card className="p-4 bg-gray-50/50">
            <h3 className="text-sm font-semibold text-gray-700 mb-3 uppercase tracking-wider">
                Waitlist Queue
            </h3>
            
            {isLoading ? (
                <div className="flex justify-center p-4"><Spinner size="sm" /></div>
            ) : !waitlist || waitlist.length === 0 ? (
                <div className="text-sm text-gray-500 italic">Queue is currently empty.</div>
            ) : (
                <div className="space-y-3">
                    {waitlist.map((entry, idx) => (
                        <div key={entry.id} className="flex items-center justify-between text-sm bg-white p-3 rounded border shadow-sm">
                            <div className="flex items-center gap-3">
                                <div className="flex items-center justify-center w-6 h-6 rounded-full bg-indigo-100 text-indigo-700 font-bold text-xs">
                                    {idx + 1}
                                </div>
                                <div>
                                    <div className="font-medium text-gray-900">Driver {entry.driverId.substring(0, 8)}</div>
                                    <div className="text-xs text-gray-500">
                                        Requested: {format(new Date(entry.requestedStartTime), 'HH:mm')}
                                    </div>
                                </div>
                            </div>
                            <div>
                                <span className="bg-orange-100 text-orange-800 text-xs px-2 py-1 rounded font-semibold">
                                    Priority: {entry.priority}
                                </span>
                            </div>
                        </div>
                    ))}
                </div>
            )}
        </Card>
    )
}
