import { Link } from 'react-router-dom'
import { ROUTES } from '../../../lib/constants'

const FILLED = { fontVariationSettings: "'FILL' 1" }

export default function HeroSection() {
  return (
    <section className="relative w-full overflow-hidden bg-inverse-surface py-space-3xl text-inverse-on-surface lg:py-24">
      {/* Ambient radial glows */}
      <div className="pointer-events-none absolute -top-32 left-1/4 h-96 w-96 rounded-full bg-primary/20 blur-3xl" />
      <div className="pointer-events-none absolute -right-24 top-1/2 h-[30rem] w-[30rem] rounded-full bg-tertiary/15 blur-3xl" />

      <div className="relative mx-auto max-w-7xl px-space-lg lg:px-space-xl">
        <div className="grid grid-cols-1 items-center gap-space-2xl lg:grid-cols-12">
          {/* Left: copy & CTAs */}
          <div className="flex flex-col items-start gap-space-lg lg:col-span-7">
            <div className="inline-flex items-center gap-space-xs rounded-full bg-white/10 px-space-md py-space-2xs shadow-[0_0_16px_rgba(14,165,160,0.3)]">
              <span className="text-[13px] font-semibold tracking-wide text-primary-fixed">
                ✦ ChargeSync 2.0 with Agentic Grid Intelligence
              </span>
            </div>

            <h1 className="max-w-2xl font-display-lg text-display-lg font-bold tracking-tight text-white lg:text-[44px] lg:leading-[52px]">
              Never Guess If You&apos;ll Fit a Charger Again.
            </h1>

            <p className="max-w-xl font-body-lg text-body-lg leading-relaxed text-surface-variant">
              ChargeSync uses AI to match your EV to the right charger, plan your route, and reserve
              your slot — before you ever leave home.
            </p>

            <div className="flex w-full flex-wrap items-center gap-space-md pt-space-xs sm:w-auto">
              <Link
                to={ROUTES.LOGIN}
                className="inline-flex items-center justify-center gap-space-xs rounded-xl bg-gradient-to-r from-primary to-tertiary px-space-xl py-space-md font-headline-sm text-headline-sm font-semibold text-on-primary shadow-lg shadow-primary/25 transition-all hover:brightness-110"
              >
                <span>Find a Charging Station</span>
                <span className="material-symbols-outlined text-[20px]">bolt</span>
              </Link>
              <a
                href="#station-owners"
                className="inline-flex items-center justify-center rounded-xl bg-white/10 px-space-xl py-space-md font-headline-sm text-headline-sm font-medium text-white transition-colors hover:bg-white/20"
              >
                Register Your Station
              </a>
            </div>

            <div className="flex items-center gap-space-sm pt-space-sm">
              <div className="flex text-amber-400">
                {Array.from({ length: 5 }).map((_, i) => (
                  <span key={i} className="material-symbols-outlined text-[18px]" style={FILLED}>
                    star
                  </span>
                ))}
              </div>
              <span className="font-body-sm text-body-sm font-medium text-surface-variant">
                4.9/5 from 42,000+ EV drivers &amp; 1,200+ station hosts
              </span>
            </div>
          </div>

          {/* Right: device mockup */}
          <div className="relative flex items-center justify-center lg:col-span-5">
            <div className="relative w-[340px] rounded-[2.5rem] bg-slate-900 p-4 shadow-2xl shadow-black/80 sm:w-[380px]">
              <div className="relative flex flex-col gap-space-md overflow-hidden rounded-[2rem] bg-slate-950 p-space-md text-white">
                <div className="flex items-center justify-between px-space-xs pt-space-xs">
                  <div className="flex items-center gap-space-xs">
                    <span className="h-2.5 w-2.5 animate-pulse rounded-full bg-tertiary" />
                    <span className="font-label-sm text-label-sm uppercase tracking-wider text-slate-400">
                      Live Grid Sync
                    </span>
                  </div>
                  <div className="rounded-full bg-slate-800 px-space-xs py-0.5 font-mono text-[11px] text-slate-300">
                    350 kW Active
                  </div>
                </div>

                <div className="relative flex h-64 w-full items-center justify-center overflow-hidden rounded-xl bg-slate-900 p-space-sm">
                  <svg
                    className="h-full w-full text-slate-800"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 300 220"
                  >
                    <path d="M-10 110 Q 140 80, 310 120" stroke="#1e293b" strokeWidth="14" />
                    <path d="M70 -10 Q 90 120, 110 230" stroke="#1e293b" strokeWidth="10" />
                    <path d="M220 -10 Q 200 100, 240 230" stroke="#1e293b" strokeWidth="12" />
                    <path d="M0 40 H300 M0 80 H300 M0 140 H300 M0 180 H300" stroke="#0f172a" strokeWidth="1" />
                    <path d="M50 0 V220 M150 0 V220 M250 0 V220" stroke="#0f172a" strokeWidth="1" />
                  </svg>

                  <div className="absolute left-12 top-10 flex flex-col items-center">
                    <div className="rounded-md bg-emerald-500 px-2 py-0.5 font-label-sm text-[10px] font-bold text-slate-950 shadow-md">
                      Bay 3B • 350kW
                    </div>
                    <div className="h-3.5 w-3.5 rounded-full border-2 border-slate-950 bg-emerald-500 shadow-lg" />
                  </div>

                  <div className="absolute bottom-16 right-12 flex flex-col items-center">
                    <div className="rounded-md bg-primary-fixed px-2 py-0.5 font-label-sm text-[10px] font-bold text-primary-fixed-variant shadow-md">
                      98% Match
                    </div>
                    <div className="h-3.5 w-3.5 rounded-full border-2 border-slate-950 bg-primary" />
                  </div>

                  <div className="absolute right-8 top-20 flex flex-col items-center">
                    <div className="rounded-md bg-amber-500 px-1.5 py-0.5 font-label-sm text-[9px] font-bold text-slate-950">
                      60kW Busy
                    </div>
                    <div className="h-2.5 w-2.5 rounded-full border-2 border-slate-950 bg-amber-500" />
                  </div>

                  <div className="absolute bottom-10 left-24 h-4 w-4 animate-ping rounded-full border-2 border-white bg-sky-400 opacity-75" />
                  <div className="absolute bottom-10 left-24 h-4 w-4 rounded-full border-2 border-white bg-sky-500 shadow-md" />
                </div>

                <div className="flex items-center justify-between rounded-xl bg-slate-900 p-space-sm">
                  <div className="flex items-center gap-space-xs">
                    <span className="material-symbols-outlined text-[20px] text-primary">ev_station</span>
                    <div>
                      <div className="font-label-md text-label-md text-slate-200">Presidio HyperCharger</div>
                      <div className="font-body-sm text-[11px] text-slate-400">Bay 04 • Level 3 DC Fast</div>
                    </div>
                  </div>
                  <span className="rounded bg-emerald-950 px-2 py-1 font-mono text-[11px] font-medium text-emerald-300">
                    Reserved
                  </span>
                </div>
              </div>

              <div className="absolute -left-8 -top-6 max-w-[240px] rounded-xl bg-slate-900/90 p-space-md shadow-2xl backdrop-blur-md sm:-left-12">
                <div className="flex items-center gap-space-xs font-label-sm text-label-sm text-emerald-400">
                  <span className="material-symbols-outlined text-[16px]" style={FILLED}>
                    check_circle
                  </span>
                  <span>Verified Match: 98%</span>
                </div>
                <p className="mt-1 font-body-sm text-[12px] font-medium leading-snug text-slate-300">
                  Tesla Model Y ↔ CCS2/NACS Ultra Compatible
                </p>
              </div>

              <div className="absolute -bottom-6 -right-6 max-w-[220px] rounded-xl bg-slate-900/95 p-space-md shadow-2xl backdrop-blur-md sm:-right-8">
                <div className="flex items-center gap-space-2xs font-label-sm text-[11px] text-primary-fixed">
                  <span className="material-symbols-outlined text-[14px]">alt_route</span>
                  <span className="uppercase tracking-wider">Smart Route</span>
                </div>
                <p className="mt-0.5 font-headline-sm text-[13px] font-semibold text-slate-200">
                  SF → Silicon Valley
                </p>
                <div className="mt-1 flex items-center justify-between text-[11px] text-slate-400">
                  <span>1 stop locked</span>
                  <span className="font-medium text-emerald-400">22 min charge</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
