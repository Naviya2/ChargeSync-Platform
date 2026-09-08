import { create } from 'zustand'

let nextId = 0

/**
 * Lightweight global notification / toast state.
 *
 * @typedef {Object} Notification
 * @property {number} id
 * @property {'info'|'success'|'warning'|'error'} type
 * @property {string} message
 * @property {string} [title]
 */

export const useNotificationStore = create((set) => ({
  /** @type {Notification[]} */
  notifications: [],

  /** @param {{ type?: Notification['type'], message: string, title?: string }} input */
  notify: ({ type = 'info', message, title }) =>
    set((state) => ({
      notifications: [...state.notifications, { id: ++nextId, type, message, title }],
    })),

  /** @param {number} id */
  dismiss: (id) =>
    set((state) => ({ notifications: state.notifications.filter((n) => n.id !== id) })),

  clear: () => set({ notifications: [] }),
}))
