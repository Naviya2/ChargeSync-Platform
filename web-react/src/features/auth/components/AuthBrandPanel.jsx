import { CheckCircle2, Clock, Lock, ShieldCheck, Zap } from 'lucide-react'

const COPY = {
  signin: {
    heading: 'Intelligent EV charging, orchestrated',
    body: 'Reservations, station operations, and human-approved AI planning — one console for owners, administrators, and support.',
  },
  signup: {
    heading: 'Power your charging network with ChargeSync',
    body: 'List your chargers, manage availability, and let AI route drivers your way — with every high-impact action gated behind your approval.',
  },
}

/**
 * Left-hand atmosphere panel for the auth screens.
 * Purely decorative — communicates what the platform does, no live data.
 *
 * @param {{ variant?: 'signin' | 'signup' }} props
 */
export default function AuthBrandPanel({ variant = 'signin' }) {
  const copy = COPY[variant] ?? COPY.signin

  return (
    <div className="relative hidden w-full overflow-hidden border-r border-ink-600 bg-ink-950 p-10 md:flex md:w-1/2 md:flex-col md:justify-between lg:w-[52%] lg:p-16">
      {/* Ambient glows */}
      <div className="pointer-events-none absolute -left-32 -top-32 h-96 w-96 animate-glow rounded-full bg-gradient-to-br from-brand-500/25 to-brand-to/15 blur-[100px]" />
      <div className="pointer-events-none absolute -right-24 top-1/2 h-[480px] w-[480px] animate-pulse-slow rounded-full bg-gradient-to-tr from-brand-500/20 via-blue-500/10 to-brand-to/20 blur-[120px]" />

      {/* Blueprint grid */}
      <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(#262C38_1px,transparent_1px)] opacity-25 [background-size:28px_28px]" />

      {/* Logo */}
      <div className="relative z-10 flex items-center gap-3">
        <div className="relative flex h-11 w-11 items-center justify-center rounded-xl border border-ink-400 bg-ink-700 shadow-lg shadow-black/40">
          <div className="absolute inset-0 rounded-xl bg-gradient-to-tr from-brand-500/20 to-brand-to/10" />
          <svg className="relative z-10 h-6 w-6" viewBox="0 0 24 24" fill="none">
            <circle cx="12" cy="12" r="9" stroke="#262C38" strokeWidth="1.8" strokeDasharray="45 15" />
            <circle
              cx="12"
              cy="12"
              r="9"
              stroke="url(#cs-bolt-grad)"
              strokeWidth="1.8"
              strokeDasharray="32 32"
              strokeLinecap="round"
            />
            <path d="M12.5 5.5L8.5 12.5H12L11 18.5L16 11.5H12.5L12.5 5.5Z" fill="url(#cs-bolt-grad)" />
            <defs>
              <linearGradient id="cs-bolt-grad" x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" stopColor="#0EA5A0" />
                <stop offset="100%" stopColor="#22C55E" />
              </linearGradient>
            </defs>
          </svg>
        </div>
        <div>
          <span className="flex items-center text-2xl font-extrabold tracking-tight text-white">
            <span className="text-blue-500">Charge</span>
            <span>Sync</span>
          </span>
          <p className="text-[9.5px] font-semibold uppercase tracking-[0.22em] text-slate-400">
            Powering Tomorrow
          </p>
        </div>
      </div>

      {/* Hero illustration */}
      <div className="relative z-10 my-auto flex flex-col items-center py-10">
        <div className="relative flex aspect-square w-full max-w-[420px] items-center justify-center">
          <div className="absolute inset-0 animate-spin-slow rounded-full border border-brand-500/15" />
          <div className="absolute inset-8 rounded-full border border-dashed border-brand-to/20" />
          <div className="absolute inset-16 rounded-full border border-ink-500/60" />
          <div className="absolute h-56 w-56 animate-pulse-slow rounded-full bg-gradient-to-tr from-brand-500/35 via-brand-to/25 to-blue-500/20 blur-3xl" />

          {/* Agentic workflow card */}
          <div className="relative z-10 flex h-72 w-72 animate-float-slow flex-col justify-between rounded-3xl border border-ink-500/70 bg-ink-800/80 p-6 shadow-2xl shadow-black/70 backdrop-blur-xl">
            <div className="flex items-center justify-between border-b border-ink-500/80 pb-3">
              <div className="flex items-center gap-2">
                <span className="relative flex h-2 w-2">
                  <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-emerald-400 opacity-75" />
                  <span className="relative inline-flex h-2 w-2 rounded-full bg-emerald-500" />
                </span>
                <span className="text-[11px] font-semibold uppercase tracking-wide text-slate-300">
                  Agentic workflow
                </span>
              </div>
              <span className="rounded-full border border-brand-700/50 bg-brand-900/60 px-2 py-0.5 text-[10px] font-medium text-brand-200">
                Human-in-the-loop
              </span>
            </div>

            <ul className="my-auto space-y-2 py-2 text-[12px] text-slate-300">
              <WorkflowRow done label="Vehicle compatibility checked" />
              <WorkflowRow done label="Station availability scored" />
              <WorkflowRow done label="Charging plan ranked" />
              <WorkflowRow label="Awaiting operator approval" pending />
            </ul>

            <div className="grid grid-cols-3 gap-2 border-t border-ink-500/80 pt-3 text-center">
              <MiniStat label="Agents" value="4" />
              <MiniStat label="Approval gate" value="1" tone="emerald" />
              <MiniStat label="Double-books" value="0" tone="brand" />
            </div>
          </div>

          {/* Satellite chips */}
          <SatelliteChip
            className="-bottom-4 -left-4"
            icon={<ShieldCheck className="h-4 w-4" />}
            title="Conflict-free booking"
            subtitle="DB-level slot locking"
          />
          <SatelliteChip
            className="-right-4 -top-3"
            icon={<Zap className="h-4 w-4" />}
            title="AI compatibility score"
            subtitle="Before the driver sets off"
            tone="emerald"
          />
        </div>

        <div className="mt-8 max-w-sm text-center">
          <h2 className="text-xl font-bold tracking-tight text-white">{copy.heading}</h2>
          <p className="mt-2 text-sm leading-relaxed text-slate-400">{copy.body}</p>
        </div>
      </div>

      {/* Footer */}
      <div className="relative z-10 flex items-center justify-between border-t border-ink-600 pt-6 text-xs text-slate-500">
        <span className="flex items-center gap-2 font-medium">
          <Lock className="h-3.5 w-3.5" />
          Encrypted session
        </span>
        <span>ChargeSync Platform · SE3090</span>
      </div>
    </div>
  )
}

function WorkflowRow({ label, done, pending }) {
  return (
    <li className="flex items-center gap-2">
      {done ? (
        <CheckCircle2 className="h-3.5 w-3.5 shrink-0 text-emerald-400" />
      ) : (
        <Clock className={`h-3.5 w-3.5 shrink-0 ${pending ? 'text-amber-400' : 'text-slate-500'}`} />
      )}
      <span className={pending ? 'text-slate-400' : ''}>{label}</span>
    </li>
  )
}

function MiniStat({ label, value, tone }) {
  const valueTone =
    tone === 'emerald' ? 'text-emerald-400' : tone === 'brand' ? 'text-brand-300' : 'text-slate-200'
  return (
    <div className="rounded-lg border border-ink-500 bg-ink-950/60 p-1.5">
      <span className="block text-[10px] text-slate-400">{label}</span>
      <span className={`text-xs font-bold ${valueTone}`}>{value}</span>
    </div>
  )
}

function SatelliteChip({ className = '', icon, title, subtitle, tone }) {
  const iconTone =
    tone === 'emerald' ? 'bg-emerald-500/15 text-emerald-400' : 'bg-brand-500/15 text-brand-300'
  return (
    <div
      className={`absolute hidden items-center gap-3 rounded-xl border border-ink-500/70 bg-ink-700/90 px-3.5 py-2.5 shadow-xl backdrop-blur-md sm:flex ${className}`}
    >
      <div className={`flex h-8 w-8 items-center justify-center rounded-lg ${iconTone}`}>{icon}</div>
      <div>
        <p className="text-[10px] font-semibold uppercase tracking-wider text-slate-400">{title}</p>
        <p className="text-xs font-bold text-white">{subtitle}</p>
      </div>
    </div>
  )
}
