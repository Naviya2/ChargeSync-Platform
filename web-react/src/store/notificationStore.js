import { create } from 'zustand'
import { persist } from 'zustand/middleware'

/**
 * Lightweight global notification / toast state.
 *
 * @typedef {Object} Notification
 * @property {number} id
 * @property {'info'|'success'|'warning'|'error'} type
 * @property {string} message
 * @property {string} [title]
 */

export const useNotificationStore = create(
  persist(
    (set) => ({
      /** @type {Notification[]} */
      notifications: [],

      /** @param {{ type?: Notification['type'], message: string, title?: string, transient?: boolean }} input */
      notify: ({ type = 'info', message, title, transient = false }) =>
        set((state) => ({
          notifications: [...state.notifications, { id: Date.now() + Math.random(), type, message, title, transient }],
        })),

      /** @param {number} id */
      dismiss: (id) =>
        set((state) => ({ notifications: state.notifications.filter((n) => n.id !== id) })),

      clear: () => set({ notifications: [] }),
    }),
    {
      name: 'chargesync-notifications',
    }
  )
)
