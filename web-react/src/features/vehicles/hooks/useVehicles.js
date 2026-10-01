import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { vehiclesApi } from '../../../api/endpoints'
import { useNotificationStore } from '../../../store/notificationStore'

/** Admin — fetch all vehicles in the system */
export function useVehicles(params = {}, options = {}) {
  return useQuery({
    queryKey: ['vehicles', params],
    queryFn: () => vehiclesApi.listAll(),
    ...options,
  })
}

/** Admin — create a vehicle (assigns to current user; admins use POST with ownerId via service) */
export function useCreateVehicle() {
  const queryClient = useQueryClient()
  const notify = useNotificationStore((s) => s.notify)

  return useMutation({
    mutationFn: (data) => vehiclesApi.create(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['vehicles'] })
      notify({
        title: 'Vehicle added',
        message: 'The vehicle has been successfully registered in the system.',
        type: 'success',
      })
    },
    onError: (err) => {
      notify({
        title: 'Failed to add vehicle',
        message: err.message || 'An unexpected error occurred.',
        type: 'error',
      })
    },
  })
}

/** Admin — update any vehicle regardless of owner */
export function useUpdateVehicle() {
  const queryClient = useQueryClient()
  const notify = useNotificationStore((s) => s.notify)

  return useMutation({
    mutationFn: ({ id, ...data }) => vehiclesApi.adminUpdate(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['vehicles'] })
      notify({
        title: 'Vehicle updated',
        message: 'The vehicle details have been successfully updated.',
        type: 'success',
      })
    },
    onError: (err) => {
      notify({
        title: 'Failed to update vehicle',
        message: err.message || 'An unexpected error occurred.',
        type: 'error',
      })
    },
  })
}

/** Admin — delete any vehicle regardless of owner */
export function useDeleteVehicle() {
  const queryClient = useQueryClient()
  const notify = useNotificationStore((s) => s.notify)

  return useMutation({
    mutationFn: (id) => vehiclesApi.adminRemove(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['vehicles'] })
      notify({
        title: 'Vehicle removed',
        message: 'The vehicle has been permanently removed from the system.',
        type: 'success',
      })
    },
    onError: (err) => {
      notify({
        title: 'Failed to delete vehicle',
        message: err.message || 'An unexpected error occurred.',
        type: 'error',
      })
    },
  })
}
