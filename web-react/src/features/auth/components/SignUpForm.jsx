import { useState } from 'react'
import { Link } from 'react-router-dom'
import {
  AlertCircle,
  ArrowRight,
  Eye,
  EyeOff,
  Loader2,
  Lock,
  Mail,
  Phone,
  Smartphone,
  Store,
  User,
  Zap,
} from 'lucide-react'
import { ROUTES } from '../../../lib/constants'
import Button from '../../../components/ui/Button'
import AuthField from './AuthField'

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
const PHONE_RE = /^[+()\d][\d\s()-]{5,}$/
const MIN_PASSWORD = 8
const MAX_PASSWORD = 72

/**
 * Presentational station-owner sign-up form. Field-level validation lives here;
 * a server-side failure is passed in via `errorMessage`.
 *
 * @param {{
 *   onSubmit: (values: {
 *     fullName: string, email: string, phoneNumber: string | null, password: string,
 *   }) => void,
 *   isSubmitting?: boolean,
 *   errorMessage?: string,
 * }} props
 */
export default function SignUpForm({ onSubmit, isSubmitting = false, errorMessage = '' }) {
  const [values, setValues] = useState({
    fullName: '',
    email: '',
    phoneNumber: '',
    password: '',
    confirmPassword: '',
  })
  const [acceptedTerms, setAcceptedTerms] = useState(false)
  const [showPassword, setShowPassword] = useState(false)
  const [fieldErrors, setFieldErrors] = useState({})

  const setField = (name) => (event) => {
    const { value } = event.target
    setValues((current) => ({ ...current, [name]: value }))
    setFieldErrors((current) => {
      if (!current[name]) return current
      const next = { ...current }
      delete next[name]
      return next
    })
  }

  function validate() {
    const errors = {}
    const { fullName, email, phoneNumber, password, confirmPassword } = values

    if (!fullName.trim()) errors.fullName = 'Enter your full name.'
    else if (fullName.trim().length > 150) errors.fullName = 'Keep this under 150 characters.'

    if (!email.trim()) errors.email = 'Enter your work email.'
    else if (!EMAIL_RE.test(email.trim())) errors.email = 'Enter a valid email address.'

    if (phoneNumber.trim() && !PHONE_RE.test(phoneNumber.trim())) {
      errors.phoneNumber = 'Enter a valid phone number, or leave it blank.'
    }

    if (!password) errors.password = 'Choose a password.'
    else if (password.length < MIN_PASSWORD) errors.password = `Use at least ${MIN_PASSWORD} characters.`
    else if (password.length > MAX_PASSWORD) errors.password = `Use at most ${MAX_PASSWORD} characters.`

    if (!confirmPassword) errors.confirmPassword = 'Re-enter your password.'
    else if (confirmPassword !== password) errors.confirmPassword = 'Passwords do not match.'

    if (!acceptedTerms) errors.acceptedTerms = 'Please accept the terms to continue.'

    return errors
  }

  function handleSubmit(event) {
    event.preventDefault()

    const errors = validate()
    setFieldErrors(errors)
    if (Object.keys(errors).length > 0) return

    onSubmit({
      fullName: values.fullName.trim(),
      email: values.email.trim(),
      phoneNumber: values.phoneNumber.trim() || null,
      password: values.password,
    })
  }

  const passwordToggle = (
    <button
      type="button"
      onClick={() => setShowPassword((visible) => !visible)}
      className="text-slate-400 transition-colors hover:text-slate-600 focus:outline-none"
      aria-label={showPassword ? 'Hide password' : 'Show password'}
      tabIndex={-1}
    >
      {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
    </button>
  )

  return (
    <div className="flex w-full flex-col justify-between overflow-y-auto bg-slate-50 p-8 sm:p-12 md:w-1/2 lg:w-[48%] lg:p-16">
      {/* Top utility row */}
      <div className="flex items-center justify-between gap-4">
        <div className="flex items-center gap-2.5">
          <span className="flex h-8 w-8 items-center justify-center rounded-lg bg-brand-gradient text-white md:hidden">
            <Zap className="h-4 w-4" />
          </span>
          <span className="rounded-md bg-slate-200/80 px-2.5 py-1 text-[11px] font-semibold uppercase tracking-wide text-slate-700">
            Station Owner Sign-up
          </span>
        </div>
        <span className="hidden text-xs font-medium text-slate-500 lg:block">
          Administrators &amp; support staff are added by your platform admin.
        </span>
      </div>

      {/* Form */}
      <div className="mx-auto my-auto w-full max-w-md py-10">
        <div className="mb-7">
          <h1 className="text-2xl font-extrabold tracking-tight text-slate-900 sm:text-3xl">
            Create your station account
          </h1>
          <p className="mt-2 text-sm text-slate-500">
            Register as a Station Owner to list chargers and manage bookings. Your stations go live
            once a platform administrator approves them.
          </p>
        </div>

        {errorMessage ? (
          <div className="mb-6 flex items-start gap-3 rounded-xl border border-red-200 bg-red-50 p-4">
            <AlertCircle className="mt-0.5 h-4 w-4 shrink-0 text-red-600" />
            <div className="text-xs">
              <p className="font-semibold text-red-900">Could not create your account</p>
              <p className="mt-0.5 text-red-700">{errorMessage}</p>
            </div>
          </div>
        ) : null}

        <form onSubmit={handleSubmit} noValidate className="space-y-4">
          <AuthField
            id="fullName"
            label="Full name"
            autoComplete="name"
            placeholder="Jordan Perera"
            icon={<User className="h-4 w-4" />}
            value={values.fullName}
            onChange={setField('fullName')}
            error={fieldErrors.fullName}
            disabled={isSubmitting}
          />

          <AuthField
            id="email"
            label="Work email"
            type="email"
            autoComplete="email"
            placeholder="you@yourcompany.com"
            icon={<Mail className="h-4 w-4" />}
            value={values.email}
            onChange={setField('email')}
            error={fieldErrors.email}
            disabled={isSubmitting}
          />

          <AuthField
            id="phoneNumber"
            label="Phone number (optional)"
            type="tel"
            autoComplete="tel"
            placeholder="+94 71 234 5678"
            icon={<Phone className="h-4 w-4" />}
            value={values.phoneNumber}
            onChange={setField('phoneNumber')}
            error={fieldErrors.phoneNumber}
            disabled={isSubmitting}
          />

          <AuthField
            id="password"
            label="Password"
            type={showPassword ? 'text' : 'password'}
            autoComplete="new-password"
            placeholder="At least 8 characters"
            icon={<Lock className="h-4 w-4" />}
            value={values.password}
            onChange={setField('password')}
            error={fieldErrors.password}
            hint={!fieldErrors.password ? 'Use 8–72 characters.' : undefined}
            disabled={isSubmitting}
            trailing={passwordToggle}
          />

          <AuthField
            id="confirmPassword"
            label="Confirm password"
            type={showPassword ? 'text' : 'password'}
            autoComplete="new-password"
            placeholder="Re-enter your password"
            icon={<Lock className="h-4 w-4" />}
            value={values.confirmPassword}
            onChange={setField('confirmPassword')}
            error={fieldErrors.confirmPassword}
            disabled={isSubmitting}
          />

          <div>
            <label className="flex cursor-pointer select-none items-start gap-2.5">
              <input
                type="checkbox"
                checked={acceptedTerms}
                onChange={(event) => {
                  setAcceptedTerms(event.target.checked)
                  setFieldErrors((current) => {
                    if (!current.acceptedTerms) return current
                    const next = { ...current }
                    delete next.acceptedTerms
                    return next
                  })
                }}
                disabled={isSubmitting}
                className="mt-0.5 h-4 w-4 rounded border-slate-300 accent-brand-500"
              />
              <span className="text-xs leading-relaxed text-slate-600">
                I agree to the ChargeSync{' '}
                <a href="#" className="font-semibold text-brand-700 hover:underline">
                  Terms of Service
                </a>{' '}
                and{' '}
                <a href="#" className="font-semibold text-brand-700 hover:underline">
                  Privacy Policy
                </a>
                .
              </span>
            </label>
            {fieldErrors.acceptedTerms ? (
              <p className="mt-1.5 text-xs font-medium text-red-600">{fieldErrors.acceptedTerms}</p>
            ) : null}
          </div>

          <Button
            type="submit"
            size="lg"
            disabled={isSubmitting}
            className="w-full rounded-xl py-3.5 text-sm"
          >
            {isSubmitting ? (
              <>
                <Loader2 className="h-4 w-4 animate-spin" />
                Creating account…
              </>
            ) : (
              <>
                Create account
                <ArrowRight className="h-4 w-4" />
              </>
            )}
          </Button>
        </form>

        <p className="mt-6 text-center text-sm text-slate-500">
          Already have an account?{' '}
          <Link to={ROUTES.LOGIN} className="font-semibold text-brand-700 hover:text-brand-800 hover:underline">
            Sign in
          </Link>
        </p>

        {/* Audience notes */}
        <div className="mt-8 space-y-2.5">
          <div className="flex items-start gap-3 rounded-xl border border-slate-200/80 bg-white p-3.5">
            <div className="mt-0.5 flex h-7 w-7 shrink-0 items-center justify-center rounded-lg bg-brand-500/10 text-brand-700">
              <Store className="h-4 w-4" />
            </div>
            <p className="text-xs leading-relaxed text-slate-600">
              <span className="font-semibold text-slate-800">This portal is for station operators.</span>{' '}
              Platform Administrator and Customer Support accounts are provisioned internally.
            </p>
          </div>
          <div className="flex items-start gap-3 rounded-xl border border-slate-200/80 bg-white p-3.5">
            <div className="mt-0.5 flex h-7 w-7 shrink-0 items-center justify-center rounded-lg bg-slate-100 text-slate-500">
              <Smartphone className="h-4 w-4" />
            </div>
            <p className="text-xs leading-relaxed text-slate-600">
              <span className="font-semibold text-slate-800">Driving an EV?</span> Reservations and
              charging plans live in the ChargeSync mobile app, not here.
            </p>
          </div>
        </div>
      </div>

      {/* Footer */}
      <p className="text-xs text-slate-400">© 2026 ChargeSync Technologies</p>
    </div>
  )
}
