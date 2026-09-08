const STATS = [
  { value: '1,248+', label: 'Active Stations Live', accent: 'text-white' },
  { value: '145,000+', label: 'Registered EV Drivers', accent: 'text-white' },
  { value: '96.4%', label: 'AI-Matched First-Time Success', accent: 'text-primary-fixed' },
  { value: '28 min', label: 'Avg. Dwell Time Saved', accent: 'text-tertiary-fixed' },
]

export default function StatsBar() {
  return (
    <section className="w-full bg-inverse-surface py-space-xl text-inverse-on-surface">
      <div className="mx-auto max-w-7xl px-space-lg lg:px-space-xl">
        <div className="grid grid-cols-2 gap-space-lg text-center lg:grid-cols-4">
          {STATS.map((s) => (
            <div key={s.label} className="flex flex-col items-center justify-center p-space-sm">
              <div className={`font-metric-num-lg text-metric-num-lg font-bold tracking-tight ${s.accent}`}>
                {s.value}
              </div>
              <div className="mt-1 font-label-md text-label-md uppercase tracking-wider text-surface-variant">
                {s.label}
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
