import { Link } from 'react-router-dom'
import { ROUTES } from '../../../lib/constants'

export default function CtaBanner() {
  return (
    <section className="w-full bg-gradient-to-r from-primary via-primary-container to-tertiary py-space-3xl text-white lg:py-24">
      <div className="mx-auto flex max-w-5xl flex-col items-center px-space-lg text-center lg:px-space-xl">
        <h2 className="max-w-3xl font-display-lg text-display-lg font-bold tracking-tight text-white lg:text-[42px] lg:leading-[50px]">
          Ready to Supercharge Your EV Experience?
        </h2>
        <p className="mt-space-md max-w-2xl font-body-lg text-body-lg text-emerald-50">
          Join over 145,000 drivers and 1,200 station hosts on the nation&apos;s smartest charging
          network.
        </p>
        <div className="mt-space-2xl flex w-full flex-wrap items-center justify-center gap-space-md sm:w-auto">
          <Link
            to={ROUTES.LOGIN}
            className="inline-flex items-center justify-center rounded-xl bg-white px-space-xl py-space-md font-headline-sm text-headline-sm font-semibold text-slate-900 shadow-xl transition-all hover:bg-slate-100"
          >
            Get Started Free
          </Link>
          <a
            href="#station-owners"
            className="inline-flex items-center justify-center rounded-xl bg-slate-950/40 px-space-xl py-space-md font-headline-sm text-headline-sm font-semibold text-white shadow-lg transition-all hover:bg-slate-950/60"
          >
            Schedule Host Demo
          </a>
        </div>
      </div>
    </section>
  )
}
