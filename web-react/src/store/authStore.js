import { create } from 'zustand'
import { persist } from 'zustand/middleware'

/**
 * Global auth session state.
 *
 * @typedef {Object} AuthUser
 * @property {string} id
 * @property {string} name
 * @property {string} email
 * @property {'Driver'|'StationOwner'|'Admin'|'SupportManager'} role
 *
 * @typedef {Object} AuthSession
 * @property {string} token           Short-lived JWT access token.
 * @property {string|null} [refreshToken] Long-lived refresh token (rotated on use).
 * @property {AuthUser} user
 */

export const useAuthStore = create(
  persist(
    (set) => ({
      /** @type {string|null} */
      token: null,
      /** @type {string|null} */
      refreshToken: null,
      /** @type {AuthUser|null} */
      user: null,

      /** @param {AuthSession} session */
      setSession: ({ token, refreshToken = null, user }) => set({ token, refreshToken, user }),

      /** @param {Partial<AuthUser>} patch */
      updateUser: (patch) =>
        set((state) => ({ user: state.user ? { ...state.user, ...patch } : state.user })),

      clearSession: () => set({ token: null, refreshToken: null, user: null }),
    }),
    {
      name: 'chargesync.auth',
      partialize: (state) => ({
        token: state.token,
        refreshToken: state.refreshToken,
        user: state.user,
      }),
    },
  ),
)

/** Non-hook accessors for use outside React (e.g. the axios interceptors). */
export const getAuthToken = () => useAuthStore.getState().token
export const getRefreshToken = () => useAuthStore.getState().refreshToken
export const getAuthRole = () => useAuthStore.getState().user?.role ?? null
export const setAuthSession = (session) => useAuthStore.getState().setSession(session)
export const clearAuthSession = () => useAuthStore.getState().clearSession()
