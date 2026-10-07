import { Suspense } from 'react'
import lazyPage from './lazyPage'
import BrandLoadingScreen from '../components/shared/BrandLoadingScreen'
import { BrowserRouter, Route, Routes } from 'react-router-dom'
import ProtectedRoute from './ProtectedRoute'
import AppLayout from '../components/layout/AppLayout'
import { ROLES, ROUTES } from '../lib/constants'

const LandingPage = lazyPage(() => import('../features/landing/pages/LandingPage'))
const LoginPage = lazyPage(() => import('../features/auth/pages/LoginPage'))
const SignUpPage = lazyPage(() => import('../features/auth/pages/SignUpPage'))
const DashboardPage = lazyPage(() => import('../features/dashboard/pages/DashboardPage'))
const StationsPage = lazyPage(() => import('../features/stations/pages/StationsPage'))
const RegisterStationPage = lazyPage(() => import('../features/stations/pages/RegisterStationPage'))
const ReservationsPage = lazyPage(() => import('../features/reservations/pages/ReservationsPage'))
const AnalyticsPage = lazyPage(() => import('../features/analytics/pages/AnalyticsPage'))
const ApprovalsPage = lazyPage(() => import('../features/approvals/pages/ApprovalsPage'))
const SupportPage = lazyPage(() => import('../features/support/pages/SupportPage'))
const UsersPage = lazyPage(() => import('../features/users/pages/UsersPage'))
const VehiclesPage = lazyPage(() => import('../features/vehicles/pages/VehiclesPage'))
const StationDetailPage = lazyPage(() => import('../features/stations/pages/StationDetailPage'))
const PendingStationPage = lazyPage(() => import('../features/stations/pages/PendingStationPage'))
const NotFoundPage = lazyPage(() => import('./NotFoundPage'))

export default function AppRouter() {
  return (
    <BrowserRouter>
      <Suspense fallback={<BrandLoadingScreen />}>
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

            <Route
              path={ROUTES.VEHICLES}
              element={
                <ProtectedRoute allowedRoles={[ROLES.ADMIN]}>
                  <VehiclesPage />
                </ProtectedRoute>
              }
            />
          </Route>

          <Route path="*" element={<NotFoundPage />} />
        </Routes>
      </Suspense>
    </BrowserRouter>
  )
}
