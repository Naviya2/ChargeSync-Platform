import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { reservationsApi } from '../../../api/endpoints/reservations'

export const RESERVATION_KEYS = {
    all: ['reservations'],
    list: (filters) => ['reservations', { filters }],
    detail: (id) => ['reservation', id],
    history: (id) => ['reservation', id, 'history'],
}

export const useReservationsList = (filters = {}) => {
    return useQuery({
        queryKey: RESERVATION_KEYS.list(filters),
        queryFn: () => reservationsApi.list(filters),
    })
}

export const useReservationDetail = (id) => {
    return useQuery({
        queryKey: RESERVATION_KEYS.detail(id),
        queryFn: () => reservationsApi.get(id),
        enabled: !!id,
    })
}

export const useReservationHistory = (id) => {
    return useQuery({
        queryKey: RESERVATION_KEYS.history(id),
        queryFn: () => reservationsApi.getHistory(id),
        enabled: !!id,
    })
}

export const useCancelReservation = () => {
    const queryClient = useQueryClient()
    return useMutation({
        mutationFn: (id) => reservationsApi.cancel(id),
        onSuccess: (_, id) => {
            queryClient.invalidateQueries({ queryKey: RESERVATION_KEYS.detail(id) })
            queryClient.invalidateQueries({ queryKey: RESERVATION_KEYS.history(id) })
            queryClient.invalidateQueries({ queryKey: RESERVATION_KEYS.all })
        },
    })
}

export const useUpdateReservation = () => {
    const queryClient = useQueryClient()
    return useMutation({
        mutationFn: ({ id, data }) => reservationsApi.update(id, data),
        onSuccess: (_, { id }) => {
            queryClient.invalidateQueries({ queryKey: RESERVATION_KEYS.detail(id) })
            queryClient.invalidateQueries({ queryKey: RESERVATION_KEYS.all })
        },
    })
}

export const useDeleteReservation = () => {
    const queryClient = useQueryClient()
    return useMutation({
        mutationFn: (id) => reservationsApi.remove(id),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: RESERVATION_KEYS.all })
        },
    })
}
