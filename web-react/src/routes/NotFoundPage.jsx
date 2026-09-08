import { Link } from 'react-router-dom'
import { ROUTES } from '../lib/constants'

export default function NotFoundPage() {
  return (
    <div className="flex min-h-screen flex-col items-center justify-center gap-4 p-8 text-center">
      <p className="text-5xl font-bold text-brand-gradient">404</p>
      <h1 className="text-xl font-semibold">Page not found</h1>
      <Link to={ROUTES.DASHBOARD} className="btn-brand">
        Back to dashboard
      </Link>
    </div>
  )
}
