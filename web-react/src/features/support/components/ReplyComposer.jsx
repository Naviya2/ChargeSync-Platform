import { useState } from 'react'
import { cn } from '../../../lib/cn'

const TOOLS = [
  { icon: 'format_bold', label: 'Bold' },
  { icon: 'format_italic', label: 'Italic' },
  { icon: 'code', label: 'Code snippet' },
  { icon: 'attach_file', label: 'Attach file' },
  { icon: 'library_books', label: 'KB link' },
]

/**
 * @param {{ recipient: string, draft: string }} props
 */
export default function ReplyComposer({ recipient, draft }) {
  const [mode, setMode] = useState('public')
  const [value, setValue] = useState(draft)

  return (
    <footer className="flex flex-col gap-space-sm bg-surface-container-lowest p-space-md shadow-md">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-space-2xs rounded-lg bg-surface-container p-space-2xs">
          <button
            type="button"
            onClick={() => setMode('public')}
            className={cn(
              'rounded px-space-md py-space-2xs font-label-md text-label-md',
              mode === 'public' ? 'bg-surface-container-lowest text-on-surface shadow-sm' : 'text-on-surface-variant hover:text-on-surface',
            )}
          >
            Public Reply
          </button>
          <button
            type="button"
            onClick={() => setMode('note')}
            className={cn(
              'rounded px-space-md py-space-2xs font-label-md text-label-md',
              mode === 'note' ? 'bg-surface-container-lowest text-on-surface shadow-sm' : 'text-on-surface-variant hover:text-on-surface',
            )}
          >
            Internal Private Note
          </button>
        </div>
        <div className="flex items-center gap-space-xs font-label-sm text-label-sm text-on-surface-variant">
          <span className="material-symbols-outlined text-sm text-tertiary">bolt</span>
          <span>AI Copilot Active</span>
        </div>
      </div>

      <div className="flex flex-wrap items-center justify-between gap-space-xs py-space-2xs">
        <div className="flex items-center gap-space-2xs">
          {TOOLS.map((t) => (
            <button
              key={t.icon}
              type="button"
              aria-label={t.label}
              title={t.label}
              className="rounded p-space-2xs text-on-surface-variant hover:bg-surface-container"
            >
              <span className="material-symbols-outlined text-sm">{t.icon}</span>
            </button>
          ))}
        </div>
        <div className="flex cursor-pointer items-center gap-space-xs rounded bg-surface-container-low px-space-sm py-space-2xs font-label-sm text-label-sm text-on-surface-variant hover:bg-surface-container">
          <span className="material-symbols-outlined text-xs">auto_awesome</span>
          <span>Quick Macros: Refund Initiated</span>
          <span className="material-symbols-outlined text-xs">expand_more</span>
        </div>
      </div>

      <textarea
        rows={3}
        value={value}
        onChange={(e) => setValue(e.target.value)}
        placeholder={`Type your reply to ${recipient}... (Markdown supported)`}
        className="w-full resize-none rounded-xl bg-surface-container-low p-space-md font-body-md text-body-md text-on-surface placeholder:text-on-surface-variant focus:bg-surface-container-lowest focus:outline-none focus:ring-1 focus:ring-primary"
      />

      <div className="flex items-center justify-between pt-space-xs">
        <div className="flex items-center gap-space-sm">
          <button
            type="button"
            className="flex items-center gap-space-xs rounded-md bg-surface-container px-space-sm py-space-2xs font-label-sm text-label-sm text-primary transition-colors hover:bg-surface-container-high"
          >
            <span className="material-symbols-outlined text-sm">auto_fix</span>
            <span>Insert AI Draft recommendation</span>
          </button>
          <span className="hidden font-label-sm text-label-sm text-on-surface-variant sm:inline">
            ⌘ + Enter to send
          </span>
        </div>
        <button
          type="button"
          className="flex items-center gap-space-xs rounded-lg bg-gradient-to-r from-primary to-tertiary px-space-xl py-space-xs font-label-md text-label-md text-on-primary shadow-sm transition-all hover:brightness-105"
        >
          <span>{mode === 'note' ? 'Save Note' : 'Send Reply'}</span>
          <span className="material-symbols-outlined text-sm">send</span>
        </button>
      </div>
    </footer>
  )
}
