import { cn } from '../../../lib/cn'

/**
 * Labelled text input used across the auth screens. Renders a leading icon,
 * an optional trailing control (e.g. a show/hide toggle) and an error message.
 *
 * @param {{
 *   id: string,
 *   label: string,
 *   icon?: React.ReactNode,
 *   trailing?: React.ReactNode,
 *   error?: string,
 *   hint?: string,
 *   className?: string,
 * } & React.InputHTMLAttributes<HTMLInputElement>} props
 */
export default function AuthField({ id, label, icon, trailing, error, hint, className, ...inputProps }) {
  return (
    <div>
      <label
        htmlFor={id}
        className="mb-1.5 block text-xs font-semibold uppercase tracking-wide text-slate-700"
      >
        {label}
      </label>
      <div className="relative">
        {icon ? (
          <span className="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3.5 text-slate-400">
            {icon}
          </span>
        ) : null}
        <input
          id={id}
          className={cn(
            'w-full rounded-xl border bg-white py-3 text-sm font-medium text-slate-900 shadow-sm transition-all',
            'placeholder-slate-400 focus:outline-none focus:ring-2',
            icon ? 'pl-10' : 'pl-4',
            trailing ? 'pr-11' : 'pr-4',
            error
              ? 'border-red-400 focus:border-red-400 focus:ring-red-400'
              : 'border-slate-300 focus:border-brand-500 focus:ring-brand-500',
            className,
          )}
          {...inputProps}
        />
        {trailing ? (
          <span className="absolute inset-y-0 right-0 flex items-center pr-3.5">{trailing}</span>
        ) : null}
      </div>
      {error ? (
        <p className="mt-1.5 text-xs font-medium text-red-600">{error}</p>
      ) : hint ? (
        <p className="mt-1.5 text-xs text-slate-400">{hint}</p>
      ) : null}
    </div>
  )
}
