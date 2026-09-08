import { cn } from '../../lib/cn'

export default function Card({ className, children, ...props }) {
  return (
    <div
      className={cn('rounded-xl border border-slate-200 bg-white p-5 shadow-sm', className)}
      {...props}
    >
      {children}
    </div>
  )
}
