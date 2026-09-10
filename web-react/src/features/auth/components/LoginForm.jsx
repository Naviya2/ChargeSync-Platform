import { useState } from 'react'
import { Link } from 'react-router-dom'
import { AlertCircle, ArrowRight, Eye, EyeOff, Loader2, Lock, Mail, ShieldCheck, Zap } from 'lucide-react'
import { ROUTES } from '../../../lib/constants'
import Button from '../../../components/ui/Button'
import AuthField from './AuthField'

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/

/**
 * Presentational sign-in form. Field-level validation lives here; a server-side
 * failure is passed in via `errorMessage`.
 *
 * @param {{
 *   onSubmit: (values: { email: string, password: string, rememberMe: boolean }) => void,
 *   isSubmitting?: boolean,
 *   errorMessage?: string,
 * }} props
 */
export default function LoginForm({ onSubmit, isSubmitting = false, errorMessage = '' }) {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [rememberMe, setRememberMe] = useState(true)
  const [fieldErrors, setFieldErrors] = useState({})

  const clearFieldError = (name) =>
    setFieldErrors((current) => {
      if (!current[name]) return current
      const next = { ...current }
      delete next[name]
      return next
    })

  function handleSubmit(event) {
    event.preventDefault()

    const errors = {}
    if (!email.trim()) errors.email = 'Enter your work email.'
    else if (!EMAIL_RE.test(email.trim())) errors.email = 'Enter a valid email address.'
    if (!password) errors.password = 'Enter your password.'

    setFieldErrors(errors)
    if (Object.keys(errors).length > 0) return

    onSubmit({ email: email.trim(), password, rememberMe })
  }

  return (
    <div className="flex w-full flex-col justify-between overflow-y-auto bg-slate-50 p-8 sm:p-12 md:w-1/2 lg:w-[48%] lg:p-16">
      {/* Top utility row */}
      <div className="flex items-center justify-between gap-4">
        <div className="flex items-center gap-2.5">
          <span className="flex h-8 w-8 items-center justify-center rounded-lg bg-brand-gradient text-white md:hidden">
            <Zap className="h-4 w-4" />
          </span>
          <span className="rounded-md bg-slate-200/80 px-2.5 py-1 text-[11px] font-semibold uppercase tracking-wide text-slate-700">
            Admin &amp; Operator Portal
          </span>
        </div>
        <span className="hidden text-xs font-medium text-slate-500 lg:block">
          Trouble signing in? Contact your platform administrator.
        </span>
      </div>

      {/* Form */}
      <div className="mx-auto my-auto w-full max-w-md py-10">
        <div className="mb-8">
          <h1 className="text-2xl font-extrabold tracking-tight text-slate-900 sm:text-3xl">
            Sign in to your account
          </h1>
          <p className="mt-2 text-sm text-slate-500">
            Use your ChargeSync work credentials to open your console.
          </p>
        </div>

        {errorMessage ? (
          <div className="mb-6 flex items-start gap-3 rounded-xl border border-red-200 bg-red-50 p-4">
            <AlertCircle className="mt-0.5 h-4 w-4 shrink-0 text-red-600" />
            <div className="text-xs">
              <p className="font-semibold text-red-900">Sign-in failed</p>
              <p className="mt-0.5 text-red-700">{errorMessage}</p>
            </div>
          </div>
        ) : null}

        <form onSubmit={handleSubmit} noValidate className="space-y-5">
          <AuthField
            id="email"
            label="Work email"
            type="email"
            autoComplete="username"
            placeholder="name@company.com"
            icon={<Mail className="h-4 w-4" />}
            value={email}
            onChange={(event) => {
              setEmail(event.target.value)
              clearFieldError('email')
            }}
            error={fieldErrors.email}
            disabled={isSubmitting}
          />

          <AuthField
            id="password"
            label="Password"
            type={showPassword ? 'text' : 'password'}
            autoComplete="current-password"
            placeholder="Enter your password"
            icon={<Lock className="h-4 w-4" />}
            value={password}
            onChange={(event) => {
              setPassword(event.target.value)
              clearFieldError('password')
            }}
            error={fieldErrors.password}
            disabled={isSubmitting}
            trailing={
              <button
                type="button"
                onClick={() => setShowPassword((visible) => !visible)}
                className="text-slate-400 transition-colors hover:text-slate-600 focus:outline-none"
                aria-label={showPassword ? 'Hide password' : 'Show password'}
                tabIndex={-1}
              >
                {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
              </button>
            }
          />

          <label className="flex cursor-pointer select-none items-center gap-2.5">
            <input
              type="checkbox"
              checked={rememberMe}
              onChange={(event) => setRememberMe(event.target.checked)}
              disabled={isSubmitting}
              className="h-4 w-4 rounded border-slate-300 accent-brand-500"
            />
            <span className="text-xs font-medium text-slate-600">Keep me signed in on this device</span>
          </label>

          <Button
            type="submit"
            size="lg"
            disabled={isSubmitting}
            className="w-full rounded-xl py-3.5 text-sm"
          >
            {isSubmitting ? (
              <>
                <Loader2 className="h-4 w-4 animate-spin" />
                Signing in…
              </>
            ) : (
              <>
                Sign in
                <ArrowRight className="h-4 w-4" />
              </>
            )}
          </Button>
        </form>

        <p className="mt-6 text-center text-sm text-slate-500">
          New to ChargeSync?{' '}
          <Link to={ROUTES.SIGNUP} className="font-semibold text-brand-700 hover:text-brand-800 hover:underline">
            Create a station account
          </Link>
        </p>

        {/* Role note */}
        <div className="mt-8 flex items-start gap-3 rounded-xl border border-slate-200/80 bg-white p-3.5">
          <div className="mt-0.5 flex h-7 w-7 shrink-0 items-center justify-center rounded-lg bg-brand-500/10 text-brand-700">
            <ShieldCheck className="h-4 w-4" />
          </div>
          <p className="text-xs leading-relaxed text-slate-600">
            <span className="font-semibold text-slate-800">Access is role-based.</span> Your account
            decides whether you land on the Station Owner, Administrator, or Support console — there is
            nothing to choose here. Drivers use the ChargeSync mobile app.
          </p>
        </div>
      </div>

      {/* Footer */}
      <p className="text-xs text-slate-400">© 2026 ChargeSync Technologies</p>
    </div>
  )
}
