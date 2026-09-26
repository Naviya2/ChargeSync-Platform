import { BrowserRouter, Route, Routes } from 'react-router-dom'
import ProtectedRoute from './ProtectedRoute'
import AppLayout from '../components/layout/AppLayout'
import { ROLES, ROUTES } from '../lib/constants'

import LandingPage from '../features/landing/pages/LandingPage'
import LoginPage from '../features/auth/pages/LoginPage'
import SignUpPage from '../features/auth/pages/SignUpPage'
import DashboardPage from '../features/dashboard/pages/DashboardPage'
import StationsPage from '../features/stations/pages/StationsPage'
import RegisterStationPage from '../features/stations/pages/RegisterStationPage'
import ReservationsPage from '../features/reservations/pages/ReservationsPage'
import AnalyticsPage from '../features/analytics/pages/AnalyticsPage'
import ApprovalsPage from '../features/approvals/pages/ApprovalsPage'
import SupportPage from '../features/support/pages/SupportPage'
import UsersPage from '../features/users/pages/UsersPage'
import StationDetailPage from '../features/stations/pages/StationDetailPage'
import PendingStationPage from '../features/stations/pages/PendingStationPage'
import NotFoundPage from './NotFoundPage'

export default function AppRouter() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path={ROUTES.LANDING} element={<LandingPage />} />
        <Route path={ROUTES.LOGIN} element={<LoginPage />} />
        <Route path={ROUTES.SIGNUP} element={<SignUpPage />} />

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
          <Route
            path={ROUTES.STATIONS + '/new'}
            element={
              <ProtectedRoute allowedRoles={[ROLES.STATION_OWNER]}>
                <RegisterStationPage />
              </ProtectedRoute>
            }
          />
          <Route
            path={ROUTES.STATIONS + '/:id'}
            element={
              <ProtectedRoute allowedRoles={[ROLES.ADMIN, ROLES.STATION_OWNER]}>
                <StationDetailPage />
              </ProtectedRoute>
            }
          />
          <Route
            path={ROUTES.STATIONS + '/:id/pending'}
            element={
              <ProtectedRoute allowedRoles={[ROLES.ADMIN, ROLES.STATION_OWNER]}>
                <PendingStationPage />
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
