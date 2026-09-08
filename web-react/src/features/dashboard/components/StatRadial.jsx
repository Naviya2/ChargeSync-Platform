const ARC = 'M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831'

/** Small radial progress meter used on the energy metric card. */
export default function StatRadial({ percent = 0 }) {
  return (
    <div className="relative flex h-10 w-10 items-center justify-center">
      <svg className="h-10 w-10 -rotate-90" viewBox="0 0 36 36">
        <path className="text-surface-container" d={ARC} fill="none" stroke="currentColor" strokeWidth="3.5" />
        <path
          className="text-tertiary"
          d={ARC}
          fill="none"
          stroke="currentColor"
          strokeWidth="3.5"
          strokeLinecap="round"
          strokeDasharray={`${percent}, 100`}
        />
      </svg>
      <span className="absolute font-label-sm text-label-sm text-on-surface">{percent}%</span>
    </div>
  )
}
