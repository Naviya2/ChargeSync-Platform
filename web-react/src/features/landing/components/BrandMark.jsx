import { cn } from '../../../lib/cn'

/**
 * ChargeSync wordmark used across the landing page.
 * @param {{ dark?: boolean, className?: string }} props
 */
export default function BrandMark({ dark = false, className }) {
  return (
    <div className={cn('flex items-center gap-space-sm', className)}>
      <span className="flex h-8 w-8 items-center justify-center rounded-xl bg-gradient-to-br from-primary to-tertiary text-on-primary">
        <span className="material-symbols-outlined text-[20px]">bolt</span>
      </span>
      <span
        className={cn(
          'font-headline-sm text-headline-sm font-semibold tracking-tight',
          dark ? 'text-inverse-on-surface' : 'text-on-surface',
        )}
      >
        ChargeSync
      </span>
    </div>
  )
}
