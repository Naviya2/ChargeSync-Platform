/** Decorative sparkline used on the metric cards. */
export default function StatSparkline({ className = 'h-10 w-20 text-primary' }) {
  return (
    <svg className={className} viewBox="0 0 100 40" fill="none" preserveAspectRatio="none">
      <path
        d="M0 32 Q 25 35, 35 22 T 70 14 T 100 6"
        fill="none"
        stroke="currentColor"
        strokeWidth="2.5"
        strokeLinecap="round"
      />
      <path
        d="M0 32 Q 25 35, 35 22 T 70 14 T 100 6 L 100 40 L 0 40 Z"
        fill="currentColor"
        fillOpacity="0.12"
      />
    </svg>
  )
}
