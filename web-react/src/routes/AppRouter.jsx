import { BrowserRouter, Route, Routes } from 'react-router-dom'
import ProtectedRoute from './ProtectedRoute'
import AppLayout from '../components/layout/AppLayout'
import { ROLES, ROUTES } from '../lib/constants'

import LandingPage from '../features/landing/pages/LandingPage'
import LoginPage from '../features/auth/pages/LoginPage'
import DashboardPage from '../features/dashboard/pages/DashboardPage'
import StationsPage from '../features/stations/pages/StationsPage'
import ReservationsPage from '../features/reservations/pages/ReservationsPage'
import AnalyticsPage from '../features/analytics/pages/AnalyticsPage'
import ApprovalsPage from '../features/approvals/pages/ApprovalsPage'
import SupportPage from '../features/support/pages/SupportPage'
import UsersPage from '../features/users/pages/UsersPage'
import NotFoundPage from './NotFoundPage'

export default function AppRouter() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path={ROUTES.LANDING} element={<LandingPage />} />
        <Route path={ROUTES.LOGIN} element={<LoginPage />} />

        {/* Authenticated shell */}
        <Route
          element={
            <ProtectedRoute>
              <AppLayout />
            </ProtectedRoute>
          }
        >
          <Route path={ROUTES.DASHBOARD} element={<DashboardPage />} />

          <Route
            path={ROUTES.STATIONS}
            element={
              <ProtectedRoute allowedRoles={[ROLES.ADMIN, ROLES.STATION_OWNER]}>
                <StationsPage />
              </ProtectedRoute>
            }
          />

          <Route path={ROUTES.RESERVATIONS} element={<ReservationsPage />} />

          <Route
            path={ROUTES.ANALYTICS}
            element={
              <ProtectedRoute allowedRoles={[ROLES.ADMIN, ROLES.STATION_OWNER]}>
                <AnalyticsPage />
              </ProtectedRoute>
            }
          />

          <Route
            path={ROUTES.APPROVALS}
            element={
              <ProtectedRoute allowedRoles={[ROLES.ADMIN]}>
                <ApprovalsPage />
              </ProtectedRoute>
            }
          />

          <Route
            path={ROUTES.SUPPORT}
            element={
              <ProtectedRoute allowedRoles={[ROLES.ADMIN, ROLES.SUPPORT_MANAGER, ROLES.DRIVER]}>
                <SupportPage />
              </ProtectedRoute>
            }
          />

          <Route
            path={ROUTES.USERS}
            element={
              <ProtectedRoute allowedRoles={[ROLES.ADMIN]}>
                <UsersPage />
              </ProtectedRoute>
            }
          />
        </Route>

        <Route path="*" element={<NotFoundPage />} />
      </Routes>
    </BrowserRouter>
  )
}
