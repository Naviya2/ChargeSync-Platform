import { cn } from '../../lib/cn'

const VARIANTS = {
  brand: 'bg-brand-gradient text-white hover:opacity-90 focus:ring-brand',
  outline: 'border border-slate-300 text-slate-700 hover:bg-slate-100 focus:ring-slate-400',
  ghost: 'text-slate-600 hover:bg-slate-100 focus:ring-slate-300',
  danger: 'bg-red-600 text-white hover:bg-red-500 focus:ring-red-500',
}

const SIZES = {
  sm: 'px-2.5 py-1.5 text-xs',
  md: 'px-4 py-2 text-sm',
  lg: 'px-5 py-2.5 text-base',
}

/**
 * @param {{ variant?: keyof typeof VARIANTS, size?: keyof typeof SIZES } & React.ButtonHTMLAttributes<HTMLButtonElement>} props
 */
export default function Button({
  variant = 'brand',
  size = 'md',
  className,
  type = 'button',
  ...props
}) {
  return (
    <button
      type={type}
      className={cn(
        'inline-flex items-center justify-center gap-2 rounded-lg font-semibold shadow-sm transition',
        'focus:outline-none focus:ring-2 focus:ring-offset-2',
        'disabled:cursor-not-allowed disabled:opacity-50',
        VARIANTS[variant],
        SIZES[size],
        className,
      )}
      {...props}
    />
  )
}
