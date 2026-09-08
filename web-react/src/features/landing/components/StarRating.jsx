import { cn } from '../../../lib/cn'

const FILLED = { fontVariationSettings: "'FILL' 1" }

/** Static 5-star rating row. */
export default function StarRating({ className }) {
  return (
    <div className={cn('flex text-amber-400', className)}>
      {Array.from({ length: 5 }).map((_, i) => (
        <span key={i} className="material-symbols-outlined text-[18px]" style={FILLED}>
          star
        </span>
      ))}
    </div>
  )
}
