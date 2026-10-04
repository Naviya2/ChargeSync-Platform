import { render, screen } from '@testing-library/react'
import { expect, test, vi } from 'vitest'
import StationDetailPage from '../../../src/features/stations/pages/StationDetailPage'
import { useParams } from 'react-router-dom'
import { useStationDetail } from '../../../src/features/stations/hooks/useStations'

vi.mock('react-router-dom', () => ({
  useParams: vi.fn(),
  useNavigate: () => vi.fn()
}))

vi.mock('../../../src/features/stations/hooks/useStations', () => ({
  useStationDetail: vi.fn()
}))

vi.mock('../../../src/features/stations/components/StationDetailConsole', () => ({
  default: () => <div data-testid="station-detail-console">Console</div>
}))

test('renders loading state for StationDetailPage', () => {
  useParams.mockReturnValue({ id: 's1' })
  useStationDetail.mockReturnValue({ data: null, isLoading: true, error: null })
  render(<StationDetailPage />)
  expect(screen.getByText(/Loading station details.../i)).toBeInTheDocument()
})

test('renders StationDetailPage with details', () => {
  useParams.mockReturnValue({ id: 's1' })
  useStationDetail.mockReturnValue({ 
    data: { id: 's1', name: 'My Station' }, 
    isLoading: false, 
    error: null 
  })
  render(<StationDetailPage />)
  expect(screen.getByTestId('station-detail-console')).toBeInTheDocument()
})
