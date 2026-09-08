const STEPS = [
  {
    n: '01',
    title: 'Register Your Vehicle',
    body: "Add your EV's make, model, trim, and battery specs in seconds. Automatic port standard detection.",
    icon: 'directions_car',
    tag: 'NACS, CCS, CHAdeMO',
  },
  {
    n: '02',
    title: 'Get Matched',
    body: 'AI checks real-time compatibility, voltage curves, and live bay availability with nearby chargers instantly.',
    icon: 'hub',
    tag: 'Instant Protocol Verification',
  },
  {
    n: '03',
    title: 'Get a Smart Plan',
    body: 'AI builds an optimized charging itinerary around your arrival deadline, distance, weather, and dynamic budget.',
    icon: 'route',
    tag: 'Weather & Elevation Tuned',
  },
  {
    n: '04',
    title: 'Reserve & Go',
    body: 'Book your guaranteed slot, scan a QR code upon arrival to check in, and charge with zero surprises.',
    icon: 'qr_code_scanner',
    tag: 'Guaranteed Bay Lock',
  },
]

export default function DriverStepsSection() {
  return (
    <section id="how-it-works" className="w-full bg-surface-container-lowest py-space-3xl lg:py-24">
      <div className="mx-auto max-w-7xl px-space-lg lg:px-space-xl">
        <div className="mx-auto mb-space-3xl max-w-3xl text-center">
          <span className="font-label-sm text-label-sm font-bold uppercase tracking-widest text-primary">
            How It Works For Drivers
          </span>
          <h2 className="mt-space-xs font-display-lg text-display-lg font-bold tracking-tight text-on-surface">
            Effortless EV Travel in 4 Simple Steps
          </h2>
          <p className="mt-space-sm font-body-lg text-body-lg text-on-surface-variant">
            Say goodbye to broken plugs, incompatible connectors, and full charging bays.
          </p>
        </div>

        <div className="grid grid-cols-1 gap-space-lg md:grid-cols-2 lg:grid-cols-4">
          {STEPS.map((step) => (
            <div
              key={step.n}
              className="flex flex-col justify-between rounded-2xl bg-surface-container-low p-space-xl shadow-sm transition-shadow hover:shadow-md"
            >
              <div>
                <div className="mb-space-lg flex h-12 w-12 items-center justify-center rounded-xl bg-primary font-headline-md font-bold text-on-primary shadow-sm">
                  {step.n}
                </div>
                <h3 className="mb-space-xs font-headline-md text-headline-md font-semibold text-on-surface">
                  {step.title}
                </h3>
                <p className="font-body-md text-body-md text-on-surface-variant">{step.body}</p>
              </div>
              <div className="mt-space-lg flex items-center gap-space-xs pt-space-md font-label-md text-label-md text-primary">
                <span className="material-symbols-outlined text-[18px]">{step.icon}</span>
                <span>{step.tag}</span>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
