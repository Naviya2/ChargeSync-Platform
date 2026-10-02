import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { adminStationsApi } from '../../../api/endpoints'

export const ADMIN_STATIONS_KEYS = {
    pending: ['admin-stations', 'pending'],
    detail: (id) => ['admin-station', id],
}

export const usePendingStations = () => {
    return useQuery({
        queryKey: ADMIN_STATIONS_KEYS.pending,
        queryFn: adminStationsApi.getPending,
    })
}

export const useAdminStationDetail = (id) => {
    return useQuery({
        queryKey: ADMIN_STATIONS_KEYS.detail(id),
        queryFn: () => adminStationsApi.getById(id),
        enabled: !!id,
    })
}

export const useApproveStation = () => {
    const queryClient = useQueryClient()
    return useMutation({
        mutationFn: adminStationsApi.approve,
        onSuccess: (_, id) => {
            queryClient.invalidateQueries({ queryKey: ADMIN_STATIONS_KEYS.pending })
            queryClient.invalidateQueries({ queryKey: ADMIN_STATIONS_KEYS.detail(id) })
        },
    })
}

export const useRejectStation = () => {
    const queryClient = useQueryClient()
    return useMutation({
        mutationFn: ({ id, reason }) => adminStationsApi.reject(id, reason),
        onSuccess: (_, { id }) => {
            queryClient.invalidateQueries({ queryKey: ADMIN_STATIONS_KEYS.pending })
            queryClient.invalidateQueries({ queryKey: ADMIN_STATIONS_KEYS.detail(id) })
        },
    })
}
