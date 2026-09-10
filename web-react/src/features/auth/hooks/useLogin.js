import { useMutation } from '@tanstack/react-query'
import apiClient, { unwrap } from '../../../api/client'

/**
 * Maps the API's auth response to the shape the auth store expects.
 * API: { accessToken, accessTokenExpiresAtUtc, refreshToken, refreshTokenExpiresAtUtc, user: { id, fullName, email, role } }
 */
export function toSession(data) {
  return {
    token: data.accessToken,
    refreshToken: data.refreshToken,
    user: {
      id: data.user.id,
      name: data.user.fullName,
      email: data.user.email,
      role: data.user.role,
    },
  }
}

/**
 * Calls `POST /api/auth/login`. Returns the mapped session; the caller decides
 * whether to accept it (role gate) and persists it via the auth store.
 */
export function useLogin() {
  return useMutation({
    mutationFn: async ({ email, password }) => {
      const data = await unwrap(apiClient.post('/auth/login', { email, password }))
      return toSession(data)
    },
  })
}
