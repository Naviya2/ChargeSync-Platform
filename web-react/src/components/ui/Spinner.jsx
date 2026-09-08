import { Loader2 } from 'lucide-react'
import { cn } from '../../lib/cn'

export default function Spinner({ className, size = 20 }) {
  return <Loader2 size={size} className={cn('animate-spin text-brand-500', className)} />
}
