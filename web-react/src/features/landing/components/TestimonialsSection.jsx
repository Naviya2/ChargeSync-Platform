import StarRating from './StarRating'

const ITEMS = [
  {
    quote:
      'No more driving to a station only to find all ports occupied or a broken handle. ChargeSync has saved me countless hours on California road trips.',
    initials: 'MV',
    name: 'Marcus V.',
    role: 'Tesla Model Y Driver • Bay Area',
    avatar: 'bg-primary/10 text-primary',
  },
  {
    quote:
      'Listing our 12 DC fast chargers brought a 38% increase in daily revenue within 60 days. The automated booking calendar eliminates congestion entirely.',
    initials: 'ER',
    name: 'Elena R.',
    role: 'Owner, Bayview Charging Hub',
    avatar: 'bg-tertiary/10 text-tertiary',
  },
  {
    quote:
      "Managing 45 electric delivery vans requires guaranteed charging slots. ChargeSync's commercial waitlist overrides keep our deliveries on schedule.",
    initials: 'DL',
    name: 'David L.',
    role: 'Logistics Fleet Operations Lead',
    avatar: 'bg-secondary/10 text-secondary',
  },
]

export default function TestimonialsSection() {
  return (
    <section id="testimonials" className="w-full bg-surface-container-lowest py-space-3xl lg:py-24">
      <div className="mx-auto max-w-7xl px-space-lg lg:px-space-xl">
        <div className="mx-auto mb-space-3xl max-w-2xl text-center">
          <span className="font-label-sm text-label-sm font-bold uppercase tracking-widest text-primary">
            Community Feedback
          </span>
          <h2 className="mt-space-xs font-display-lg text-display-lg font-bold tracking-tight text-on-surface">
            Trusted by drivers and enterprise hosts across North America
          </h2>
        </div>

        <div className="grid grid-cols-1 gap-space-lg md:grid-cols-3">
          {ITEMS.map((t) => (
            <div
              key={t.name}
              className="flex flex-col justify-between rounded-2xl bg-surface-container-low p-space-xl shadow-sm"
            >
              <div>
                <StarRating className="mb-space-md" />
                <p className="font-body-md text-body-md italic leading-relaxed text-on-surface">
                  &ldquo;{t.quote}&rdquo;
                </p>
              </div>
              <div className="mt-space-xl flex items-center gap-space-md pt-space-md">
                <div className={`flex h-10 w-10 items-center justify-center rounded-full font-bold ${t.avatar}`}>
                  {t.initials}
                </div>
                <div>
                  <div className="font-headline-sm text-headline-sm font-semibold text-on-surface">{t.name}</div>
                  <div className="font-body-sm text-body-sm text-on-surface-variant">{t.role}</div>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
