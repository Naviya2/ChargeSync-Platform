import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { stationsApi } from '../../../api/endpoints'

export const STATIONS_KEYS = {
    all: ['my-stations'],
    detail: (id) => ['station', id],
}

export const useMyStations = () => {
    return useQuery({
        queryKey: STATIONS_KEYS.all,
        queryFn: stationsApi.getMyStations,
    })
}

export const useStationDetail = (id) => {
    return useQuery({
        queryKey: STATIONS_KEYS.detail(id),
        queryFn: () => stationsApi.getById(id),
        enabled: !!id,
    })
}

export const useRegisterStation = () => {
    const queryClient = useQueryClient()
    return useMutation({
        mutationFn: stationsApi.register,
        onSuccess: () => queryClient.invalidateQueries({ queryKey: STATIONS_KEYS.all }),
    })
}

export const useUpdateStation = () => {
    const queryClient = useQueryClient()
    return useMutation({
        mutationFn: ({ id, data }) => stationsApi.update(id, data),
        onSuccess: (_, { id }) => {
            queryClient.invalidateQueries({ queryKey: STATIONS_KEYS.detail(id) })
            queryClient.invalidateQueries({ queryKey: STATIONS_KEYS.all })
        },
    })
}

export const useAddCharger = () => {
    const queryClient = useQueryClient()
    return useMutation({
        mutationFn: ({ stationId, data }) => stationsApi.addCharger(stationId, data),
        onSuccess: (_, { stationId }) => {
            queryClient.invalidateQueries({ queryKey: STATIONS_KEYS.detail(stationId) })
            queryClient.invalidateQueries({ queryKey: STATIONS_KEYS.all })
        },
    })
}

export const useUpdateOperatingHours = () => {
    const queryClient = useQueryClient()
    return useMutation({
        mutationFn: ({ stationId, data }) => stationsApi.updateOperatingHours(stationId, data),
        onSuccess: (_, { stationId }) => {
            queryClient.invalidateQueries({ queryKey: STATIONS_KEYS.detail(stationId) })
        },
    })
}

export const useAddMaintenanceWindow = () => {
    const queryClient = useQueryClient()
    return useMutation({
        mutationFn: ({ chargerId, data }) => stationsApi.addMaintenanceWindow(chargerId, data),
        onSuccess: (_, { stationId }) => {
            if (stationId) queryClient.invalidateQueries({ queryKey: STATIONS_KEYS.detail(stationId) })
            queryClient.invalidateQueries({ queryKey: STATIONS_KEYS.all })
        },
    })
}

export const useUpdateMaintenanceWindow = () => {
    const queryClient = useQueryClient()
    return useMutation({
        mutationFn: ({ maintenanceId, data }) => stationsApi.updateMaintenanceWindow(maintenanceId, data),
        onSuccess: (_, { stationId }) => {
            if (stationId) queryClient.invalidateQueries({ queryKey: STATIONS_KEYS.detail(stationId) })
            queryClient.invalidateQueries({ queryKey: STATIONS_KEYS.all })
        },
    })
}
