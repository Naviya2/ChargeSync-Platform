import axios from 'axios'
import {
  clearAuthSession,
  getAuthToken,
  getRefreshToken,
  setAuthSession,
} from '../store/authStore'
import { ROUTES } from '../lib/constants'

const BASE_URL = import.meta.env.VITE_API_BASE_URL ?? '/api'

/**
 * Shared Axios instance for the ChargeSync API.
 * - Request interceptor attaches the JWT bearer token from the auth store.
 * - Response interceptor transparently refreshes an expired access token once,
 *   then retries the original request. If refresh fails (or there is no refresh
 *   token) the session is cleared and the user is sent to /login.
 */
export const apiClient = axios.create({
  baseURL: BASE_URL,
  headers: { 'Content-Type': 'application/json' },
  timeout: 20_000,
})

/** Endpoints that must never trigger the refresh/redirect flow. */
const AUTH_PATHS = ['/auth/login', '/auth/register', '/auth/refresh']
const isAuthPath = (url = '') => AUTH_PATHS.some((path) => url.includes(path))

apiClient.interceptors.request.use((config) => {
  const token = getAuthToken()
  if (token) {
    config.headers = config.headers ?? {}
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

/** In-flight refresh, shared so concurrent 401s only refresh once. */
let refreshInFlight = null

async function refreshSession() {
  const refreshToken = getRefreshToken()
  if (!refreshToken) throw new Error('No refresh token')

  // Bare axios call — must not go through this instance's interceptors.
  const { data } = await axios.post(
    `${BASE_URL}/auth/refresh`,
    { refreshToken },
    { headers: { 'Content-Type': 'application/json' }, timeout: 20_000 },
  )

  const session = {
    token: data.accessToken,
    refreshToken: data.refreshToken,
    user: { ...data.user, name: data.user?.fullName ?? data.user?.name },
  }
  setAuthSession(session)
  return session
}

function redirectToLogin() {
  if (typeof window !== 'undefined' && window.location.pathname !== ROUTES.LOGIN) {
    window.location.assign(ROUTES.LOGIN)
  }
}

apiClient.interceptors.response.use(
  (response) => response,
  async (error) => {
    const original = error.config
    const status = error.response?.status

    if (status !== 401 || !original || original._retry || isAuthPath(original.url)) {
      return Promise.reject(error)
    }

    try {
      refreshInFlight = refreshInFlight ?? refreshSession()
      const session = await refreshInFlight
      refreshInFlight = null

      original._retry = true
      original.headers = original.headers ?? {}
      original.headers.Authorization = `Bearer ${session.token}`
      return apiClient(original)
    } catch {
      refreshInFlight = null
      clearAuthSession()
      redirectToLogin()
      return Promise.reject(error)
    }
  },
)

/** Unwraps `response.data` for the common case. */
export const unwrap = (promise) => promise.then((res) => res.data)

export default apiClient
