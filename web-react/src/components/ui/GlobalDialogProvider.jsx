import useDialogStore from '../../store/dialogStore'

const VARIANT_STYLES = {
  default: {
    icon: 'help',
    iconBg: 'bg-blue-50',
    iconColor: 'text-blue-600',
    confirmBtn: 'bg-blue-600 hover:bg-blue-700 text-white',
  },
  danger: {
    icon: 'warning',
    iconBg: 'bg-red-50',
    iconColor: 'text-red-500',
    confirmBtn: 'bg-red-600 hover:bg-red-700 text-white',
  },
  success: {
    icon: 'check_circle',
    iconBg: 'bg-green-50',
    iconColor: 'text-green-600',
    confirmBtn: 'bg-green-600 hover:bg-green-700 text-white',
  },
  warning: {
    icon: 'error_outline',
    iconBg: 'bg-amber-50',
    iconColor: 'text-amber-500',
    confirmBtn: 'bg-amber-500 hover:bg-amber-600 text-white',
  },
}

function DialogItem({ dialog }) {
  const resolve = useDialogStore((s) => s._resolve)
  const styles = VARIANT_STYLES[dialog.variant] ?? VARIANT_STYLES.default

  return (
    <div className="fixed inset-0 z-[200] flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm animate-fade-in">
      <div className="w-full max-w-sm rounded-2xl bg-white shadow-2xl overflow-hidden transform transition-all">
        {/* Header */}
        <div className="px-6 pt-6 pb-4 flex flex-col items-center text-center">
          <div className={`flex h-14 w-14 items-center justify-center rounded-full mb-4 ${styles.iconBg}`}>
            <span className={`material-symbols-outlined text-3xl ${styles.iconColor}`}>{styles.icon}</span>
          </div>
          <h3 className="text-lg font-bold text-gray-900 mb-1">{dialog.title}</h3>
          {dialog.message && (
            <p className="text-sm text-gray-500 leading-relaxed">{dialog.message}</p>
          )}
        </div>

        {/* Actions */}
        <div className={`px-6 pb-6 flex gap-3 ${dialog.type === 'alert' ? 'justify-center' : ''}`}>
          {dialog.type === 'confirm' && (
            <button
              onClick={() => resolve(dialog.id, false)}
              className="flex-1 rounded-xl border border-gray-200 bg-white px-4 py-2.5 text-sm font-semibold text-gray-700 transition hover:bg-gray-50 focus:outline-none"
            >
              {dialog.cancelLabel}
            </button>
          )}
          <button
            onClick={() => resolve(dialog.id, dialog.type === 'alert' ? undefined : true)}
            className={`flex-1 rounded-xl px-4 py-2.5 text-sm font-semibold shadow-sm transition focus:outline-none ${styles.confirmBtn}`}
          >
            {dialog.type === 'alert' ? dialog.label : dialog.confirmLabel}
          </button>
        </div>
      </div>
    </div>
  )
}

export default function GlobalDialogProvider() {
  const dialogs = useDialogStore((s) => s.dialogs)

  if (dialogs.length === 0) return null

  // Render the first dialog (stack-style)
  return <DialogItem key={dialogs[0].id} dialog={dialogs[0]} />
}
