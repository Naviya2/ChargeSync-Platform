import { useMutation } from '@tanstack/react-query'
import apiClient, { unwrap } from '../../../api/client'
import { toSession } from './useLogin'

/**
 * Calls `POST /api/auth/register` as a Station Owner. The API returns a full
 * signed-in session on success, so a successful sign-up logs the user straight
 * in. Returns the mapped session for the page to persist.
 */
export function useRegister() {
  return useMutation({
    mutationFn: async ({ fullName, email, phoneNumber, password }) => {
      const data = await unwrap(
        apiClient.post('/auth/register', {
          fullName,
          email,
          password,
          phoneNumber: phoneNumber || null,
          role: 'StationOwner',
        }),
      )
      return toSession(data)
    },
  })
}
