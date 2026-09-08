import { cn } from '../../../lib/cn'

const STATES = [
  { key: 'normal', label: 'Normal' },
  { key: 'loading', label: 'Loading' },
  { key: 'empty', label: 'Empty' },
  { key: 'error', label: 'Error' },
]

/**
 * Dev-only dock to preview the dashboard's loading / empty / error states.
 * Remove once the page is wired to real query states.
 *
 * @param {{ value: string, onChange: (state: string) => void }} props
 */
export default function DemoStateDock({ value, onChange }) {
  return (
    <div className="fixed bottom-6 right-6 z-40 flex items-center gap-1 rounded-2xl border border-on-surface/10 bg-inverse-surface/95 p-1.5 text-inverse-on-surface shadow-2xl backdrop-blur-md">
      <div className="flex items-center gap-1.5 px-space-sm py-1 font-label-sm text-label-sm text-outline-variant">
        <span className="material-symbols-outlined text-sm text-primary-fixed">tune</span>
        <span className="hidden sm:inline">DEMO VIEW:</span>
      </div>
      {STATES.map((s) => (
        <button
          key={s.key}
          type="button"
          onClick={() => onChange(s.key)}
          className={cn(
            'rounded-xl px-space-sm py-1 font-label-sm text-label-sm transition-all',
            value === s.key
              ? 'bg-primary text-on-primary'
              : 'text-inverse-on-surface hover:bg-on-surface/20',
          )}
        >
          {s.label}
        </button>
      ))}
    </div>
  )
}
