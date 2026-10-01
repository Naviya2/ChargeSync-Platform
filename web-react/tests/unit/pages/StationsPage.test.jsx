import { render, screen } from '@testing-library/react'
import { expect, test, vi } from 'vitest'
import StationsPage from '../../../src/features/stations/pages/StationsPage'
import { useAuthStore } from '../../../src/store/authStore'
import { ROLES } from '../../../src/lib/constants'

vi.mock('../../../src/store/authStore', () => ({
  useAuthStore: vi.fn()
}))

vi.mock('../../../src/features/stations/pages/MyStationsPage', () => ({
  default: ({ isAdmin }) => <div data-testid="my-stations-page">{isAdmin ? 'Admin' : 'Owner'}</div>
}))

vi.mock('../../../src/components/shared/PlaceholderPage', () => ({
  default: ({ title }) => <div data-testid="placeholder-page">{title}</div>
}))

test('renders MyStationsPage for STATION_OWNER', () => {
  useAuthStore.mockImplementation((selector) => selector({ user: { role: ROLES.STATION_OWNER } }))
  render(<StationsPage />)
  expect(screen.getByTestId('my-stations-page')).toHaveTextContent('Owner')
})

test('renders MyStationsPage as admin for ADMIN', () => {
  useAuthStore.mockImplementation((selector) => selector({ user: { role: ROLES.ADMIN } }))
  render(<StationsPage />)
  expect(screen.getByTestId('my-stations-page')).toHaveTextContent('Admin')
})

test('renders PlaceholderPage for other roles', () => {
  useAuthStore.mockImplementation((selector) => selector({ user: { role: 'DRIVER' } }))
  render(<StationsPage />)
  expect(screen.getByTestId('placeholder-page')).toHaveTextContent('Stations')
})
