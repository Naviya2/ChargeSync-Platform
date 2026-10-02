import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import * as endpoints from '../../../api/endpoints'
import { useNotificationStore } from '../../../store/notificationStore'

export function useUsers(query = {}, options = {}) {
  return useQuery({
    queryKey: ['users', query],
    queryFn: () => endpoints.users.list(),
    ...options,
  })
}

export function useCreateUser() {
  const queryClient = useQueryClient()
  const notify = useNotificationStore((s) => s.notify)

  return useMutation({
    mutationFn: (data) => endpoints.users.create(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['users'] })
      notify({
        title: 'User created',
        message: 'The new user account has been successfully created.',
        type: 'success',
      })
    },
    onError: (err) => {
      notify({
        title: 'Failed to create user',
        message: err.message || 'An unexpected error occurred.',
        type: 'error',
      })
    },
  })
}

export function useUpdateUser() {
  const queryClient = useQueryClient()
  const notify = useNotificationStore((s) => s.notify)

  return useMutation({
    mutationFn: ({ id, ...data }) => endpoints.users.update(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['users'] })
      notify({
        title: 'User updated',
        message: 'The user account has been successfully updated.',
        type: 'success',
      })
    },
    onError: (err) => {
      notify({
        title: 'Failed to update user',
        message: err.message || 'An unexpected error occurred.',
        type: 'error',
      })
    },
  })
}

export function useDeleteUser() {
  const queryClient = useQueryClient()
  const notify = useNotificationStore((s) => s.notify)

  return useMutation({
    mutationFn: (id) => endpoints.users.remove(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['users'] })
      notify({
        title: 'User deleted',
        message: 'The user account has been permanently removed.',
        type: 'success',
      })
    },
    onError: (err) => {
      notify({
        title: 'Failed to delete user',
        message: err.message || 'An unexpected error occurred.',
        type: 'error',
      })
    },
  })
}
