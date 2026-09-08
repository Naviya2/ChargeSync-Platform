import { useMutation } from '@tanstack/react-query'
import apiClient, { unwrap } from '../../../api/client'
import { useAuthStore } from '../../../store/authStore'

/**
 * Login mutation. Expects the API to return `{ token, user }`.
 * Wire this to the real `/auth/login` endpoint when the backend is ready.
 */
export function useLogin() {
  const setSession = useAuthStore((s) => s.setSession)

  return useMutation({
    mutationFn: (credentials) => unwrap(apiClient.post('/auth/login', credentials)),
    onSuccess: (data) => {
      if (data?.token) setSession(data)
    },
  })
}
