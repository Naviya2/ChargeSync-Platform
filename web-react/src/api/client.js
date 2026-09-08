import axios from 'axios'
import { getAuthToken, clearAuthSession } from '../store/authStore'
import { ROUTES } from '../lib/constants'

/**
 * Shared Axios instance for the ChargeSync API.
 * - Request interceptor attaches the JWT bearer token from the auth store.
 * - Response interceptor clears the session and redirects to /login on 401.
 */
export const apiClient = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL ?? '/api',
  headers: {
    'Content-Type': 'application/json',
  },
  timeout: 20_000,
})

apiClient.interceptors.request.use((config) => {
  const token = getAuthToken()
  if (token) {
    config.headers = config.headers ?? {}
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      clearAuthSession()
      if (typeof window !== 'undefined' && window.location.pathname !== ROUTES.LOGIN) {
        window.location.assign(ROUTES.LOGIN)
      }
    }
    return Promise.reject(error)
  },
)

/** Unwraps `response.data` for the common case. */
export const unwrap = (promise) => promise.then((res) => res.data)

export default apiClient
