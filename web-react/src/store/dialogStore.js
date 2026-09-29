import { create } from 'zustand'

/**
 * Global dialog store – replaces window.confirm / window.alert
 * 
 * Usage:
 *   const { confirm, alert: showAlert } = useDialogStore.getState()
 *   await confirm({ title: '...', message: '...' }) // returns true/false
 *   await showAlert({ title: '...', message: '...' })
 */
const useDialogStore = create((set, get) => ({
  dialogs: [],

  /** Show a confirm dialog. Returns a Promise<boolean> */
  confirm: ({ title, message, confirmLabel = 'Confirm', cancelLabel = 'Cancel', variant = 'default' }) => {
    return new Promise((resolve) => {
      const id = crypto.randomUUID()
      set((s) => ({
        dialogs: [
          ...s.dialogs,
          { id, type: 'confirm', title, message, confirmLabel, cancelLabel, variant, resolve },
        ],
      }))
    })
  },

  /** Show an alert dialog. Returns a Promise<void> */
  alert: ({ title, message, label = 'OK', variant = 'default' }) => {
    return new Promise((resolve) => {
      const id = crypto.randomUUID()
      set((s) => ({
        dialogs: [
          ...s.dialogs,
          { id, type: 'alert', title, message, label, variant, resolve },
        ],
      }))
    })
  },

  /** Called internally when user clicks a button */
  _resolve: (id, value) => {
    const dialog = get().dialogs.find((d) => d.id === id)
    if (dialog) {
      dialog.resolve(value)
      set((s) => ({ dialogs: s.dialogs.filter((d) => d.id !== id) }))
    }
  },
}))

export default useDialogStore
