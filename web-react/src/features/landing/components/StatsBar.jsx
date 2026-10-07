const STATS = [
  { value: '1,248+', amount: 1248, suffix: '+', label: 'Active Stations Live', accent: 'text-white', live: true },
  { value: '145,000+', amount: 145000, suffix: '+', label: 'Registered EV Drivers', accent: 'text-white' },
  { value: '96.4%', amount: 96.4, decimals: 1, suffix: '%', label: 'AI-Matched First-Time Success', accent: 'text-primary-fixed' },
  { value: '28 min', amount: 28, suffix: ' min', label: 'Avg. Dwell Time Saved', accent: 'text-tertiary-fixed' },
]

export default function StatsBar() {
  return (
    <section className="w-full bg-inverse-surface py-space-xl text-inverse-on-surface">
      <div className="mx-auto max-w-7xl px-space-lg lg:px-space-xl">
        <div data-reveal-group className="grid grid-cols-2 gap-space-lg text-center lg:grid-cols-4">
          {STATS.map((s) => (
            <div data-reveal key={s.label} className="flex flex-col items-center justify-center p-space-sm">
              <div className={`relative font-metric-num-lg text-metric-num-lg font-bold tabular-nums tracking-tight ${s.accent}`}>
                <span className="sr-only">{s.value}</span>
                <span aria-hidden="true" className="invisible">{s.value}</span>
                <span
                  aria-hidden="true"
                  data-stat-count
                  data-amount={s.amount}
                  data-decimals={s.decimals ?? 0}
                  data-suffix={s.suffix}
                  className="absolute inset-0 flex items-center justify-center"
                >
                  {s.value}
                </span>
              </div>
              <div className="mt-1 font-label-md text-label-md uppercase tracking-wider text-surface-variant">
                {s.live && <span aria-hidden="true" className="mr-1.5 inline-block h-1.5 w-1.5 animate-pulse rounded-full bg-teal-300 align-middle" />}
                {s.label}
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
