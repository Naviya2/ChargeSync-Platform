import { render, screen } from '@testing-library/react'
import { expect, test, vi, beforeEach } from 'vitest'
import MyStationsPage from '../../../src/features/stations/pages/MyStationsPage'
import { useMyStations, useStations } from '../../../src/features/stations/hooks/useStations'

const mockNavigate = vi.fn()
vi.mock('react-router-dom', () => ({
  useNavigate: () => mockNavigate
}))

vi.mock('../../../src/features/stations/hooks/useStations', () => ({
  useMyStations: vi.fn(),
  useStations: vi.fn()
}))

vi.mock('../../../src/features/stations/components/StationsHeader', () => ({
  default: () => <div data-testid="stations-header">Header</div>
}))
vi.mock('../../../src/features/stations/components/StationKpiStrip', () => ({
  default: ({ kpis }) => <div data-testid="station-kpi-strip">KPIs: {kpis.length}</div>
}))
vi.mock('../../../src/features/stations/components/StationFilterBar', () => ({
  default: () => <div data-testid="station-filter-bar">Filter</div>
}))
vi.mock('../../../src/features/stations/components/StationCardGrid', () => ({
  default: ({ stations, onSelect }) => (
    <div data-testid="station-card-grid">
      Grid Items: {stations.length}
      {stations.length > 0 && <button onClick={() => onSelect(stations[0].id)}>Select First</button>}
    </div>
  )
}))

vi.mock('../../../src/features/stations/components/PendingApprovalsCard', () => ({
  default: () => <div data-testid="pending-approvals-card">Pending Approvals</div>
}))

const mockStationsDto = [
  { id: 's1', name: 'Station 1', status: 'Active', chargers: [] },
  { id: 's2', name: 'Station 2', status: 'Pending', chargers: [] }
]

beforeEach(() => {
  vi.clearAllMocks()
  useMyStations.mockReturnValue({ data: mockStationsDto, isLoading: false })
  useStations.mockReturnValue({ data: mockStationsDto, isLoading: false })
})

test('renders loading state when isLoading is true', () => {
  useMyStations.mockReturnValue({ data: [], isLoading: true })
  render(<MyStationsPage />)
  expect(screen.getByText('Loading stations...')).toBeInTheDocument()
})

test('renders MyStationsPage with all subcomponents for normal user', () => {
  render(<MyStationsPage />)
  expect(screen.getByTestId('stations-header')).toBeInTheDocument()
  expect(screen.getByTestId('pending-approvals-card')).toBeInTheDocument()
  expect(screen.getByTestId('station-kpi-strip')).toHaveTextContent('KPIs: 4')
  expect(screen.getByTestId('station-filter-bar')).toBeInTheDocument()
  expect(screen.getByTestId('station-card-grid')).toHaveTextContent('Grid Items: 2')
})

test('renders MyStationsPage with all subcomponents for admin', () => {
  render(<MyStationsPage isAdmin={true} />)
  expect(useStations).toHaveBeenCalled()
  expect(screen.getByTestId('stations-header')).toBeInTheDocument()
  expect(screen.getByTestId('pending-approvals-card')).toBeInTheDocument()
  expect(screen.getByTestId('station-card-grid')).toHaveTextContent('Grid Items: 2')
})
