import { cn } from '../../lib/cn'

const SIZES = {
  default: { icon: 'h-9 w-9 sm:h-11 sm:w-11', name: 'text-[18px] sm:text-[22px]', tagline: 'text-[7px] sm:text-[8px]' },
  compact: { icon: 'h-9 w-9', name: 'text-[18px]', tagline: 'text-[7px]' },
  large: { icon: 'h-14 w-14', name: 'text-[28px]', tagline: 'text-[9px]' },
}

/** Transparent brand emblem paired with a crisp, accessible text wordmark. */
export default function BrandLogo({ className, tone = 'dark', size = 'default' }) {
  const sizing = SIZES[size] ?? SIZES.default

  return (
    <span
      className={cn('inline-flex shrink-0 items-center gap-2.5', className)}
    >
      <img
        src={`${import.meta.env.BASE_URL}brand/chargesync-icon.png`}
        alt=""
        aria-hidden="true"
        width="1280"
        height="1280"
        decoding="async"
        className={cn('shrink-0 object-contain', sizing.icon)}
      />
      <span className="flex flex-col gap-1">
        <span className={cn('whitespace-nowrap font-bold uppercase leading-none tracking-[0.035em]', sizing.name, tone === 'light' ? 'text-slate-900' : 'text-white')}>
          Charge<span className={tone === 'light' ? 'text-teal-600' : 'text-teal-300'}>Sync</span>
        </span>
        <span className={cn('whitespace-nowrap font-medium uppercase leading-none tracking-[0.24em]', sizing.tagline, tone === 'light' ? 'text-slate-500' : 'text-slate-400')}>
          Powering Tomorrow
        </span>
      </span>
    </span>
  )
}
