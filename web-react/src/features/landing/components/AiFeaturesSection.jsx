const CARDS = [
  {
    icon: 'electric_car',
    iconWrap: 'bg-primary/20 text-primary-fixed',
    title: 'AI Compatibility Check',
    body: 'Analyzes vehicle onboard OBC, battery thermal curves, and station hardware specs before you ever depart so you never face plug refusal.',
    stat: 'Thermal Match: 99.2%',
    status: 'PASSED',
    statusColor: 'text-emerald-400',
  },
  {
    icon: 'auto_graph',
    iconWrap: 'bg-tertiary/20 text-tertiary-fixed',
    title: 'AI Charging Planner',
    body: 'Dynamically ranks itineraries by cost, time-of-use tariffs, weather degradation, and charger reliability scores for optimal efficiency.',
    stat: 'TOU Tariff Saved: $14.20',
    status: 'OPTIMIZED',
    statusColor: 'text-primary-fixed',
  },
]

export default function AiFeaturesSection() {
  return (
    <section
      id="ai-features"
      className="relative w-full overflow-hidden bg-inverse-surface py-space-3xl text-inverse-on-surface lg:py-24"
    >
      <div className="pointer-events-none absolute right-1/3 top-0 h-80 w-80 rounded-full bg-primary/15 blur-3xl" />
      <div className="relative mx-auto max-w-7xl px-space-lg lg:px-space-xl">
        <div className="mx-auto mb-space-3xl max-w-3xl text-center">
          <span className="font-label-sm text-label-sm font-bold uppercase tracking-widest text-primary-fixed">
            Autonomous Grid Intelligence
          </span>
          <h2 className="mt-space-xs font-display-lg text-display-lg font-bold tracking-tight text-white">
            Smart Recommendations. Human-Approved Decisions.
          </h2>
          <p className="mt-space-sm font-body-lg text-body-lg text-surface-variant">
            State-of-the-art machine learning keeps queues moving, while strict human governance
            ensures safety and financial accuracy.
          </p>
        </div>

        <div className="grid grid-cols-1 gap-space-lg lg:grid-cols-3">
          {CARDS.map((c) => (
            <div
              key={c.title}
              className="flex flex-col justify-between rounded-2xl bg-slate-900/60 p-space-xl shadow-xl backdrop-blur-md"
            >
              <div>
                <div className={`mb-space-lg flex h-12 w-12 items-center justify-center rounded-xl ${c.iconWrap}`}>
                  <span className="material-symbols-outlined text-[28px]">{c.icon}</span>
                </div>
                <h3 className="mb-space-xs font-headline-md text-headline-md font-semibold text-white">
                  {c.title}
                </h3>
                <p className="font-body-md text-body-md leading-relaxed text-surface-variant">{c.body}</p>
              </div>
              <div className="mt-space-xl flex items-center justify-between rounded-lg bg-slate-950/80 p-space-sm font-mono text-[12px] text-slate-300">
                <span>{c.stat}</span>
                <span className={c.statusColor}>{c.status}</span>
              </div>
            </div>
          ))}

          {/* Human-in-the-loop safety card */}
          <div className="flex flex-col justify-between rounded-2xl bg-slate-900/60 p-space-xl shadow-xl backdrop-blur-md">
            <div>
              <div className="mb-space-lg flex h-12 w-12 items-center justify-center rounded-xl bg-amber-500/20 text-amber-300">
                <span className="material-symbols-outlined text-[28px]">verified_user</span>
              </div>
              <h3 className="mb-space-xs font-headline-md text-headline-md font-semibold text-white">
                Human-in-the-Loop Safety
              </h3>
              <p className="font-body-md text-body-md leading-relaxed text-surface-variant">
                Every high-impact action (disputes, refunds, abnormal surge spikes, waitlist
                overrides) is routed to human platform admins for review before release.
              </p>
            </div>
            <div className="mt-space-xl flex flex-col gap-1 rounded-lg bg-emerald-950/70 p-space-sm shadow-sm">
              <div className="flex items-center gap-space-xs font-label-sm text-label-sm font-semibold text-emerald-300">
                <span className="material-symbols-outlined text-[16px]">shield</span>
                <span>Reviewed by Human Supervisor</span>
              </div>
              <div className="font-mono text-[11px] text-slate-400">Audit ID: #CS-8921 • 14:02:11 PST</div>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
