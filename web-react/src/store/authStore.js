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
 */

export const useAuthStore = create(
  persist(
    (set) => ({
      /** @type {string|null} */
      token: null,
      /** @type {AuthUser|null} */
      user: null,

      /** @param {{ token: string, user: AuthUser }} session */
      setSession: ({ token, user }) => set({ token, user }),

      /** @param {Partial<AuthUser>} patch */
      updateUser: (patch) =>
        set((state) => ({ user: state.user ? { ...state.user, ...patch } : state.user })),

      clearSession: () => set({ token: null, user: null }),
    }),
    {
      name: 'chargesync.auth',
      partialize: (state) => ({ token: state.token, user: state.user }),
    },
  ),
)

/** Non-hook accessors for use outside React (e.g. the axios interceptor). */
export const getAuthToken = () => useAuthStore.getState().token
export const getAuthRole = () => useAuthStore.getState().user?.role ?? null
export const clearAuthSession = () => useAuthStore.getState().clearSession()
