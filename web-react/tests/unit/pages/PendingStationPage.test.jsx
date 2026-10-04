import { render, screen } from '@testing-library/react'
import { expect, test, vi } from 'vitest'
import PendingStationPage from '../../../src/features/stations/pages/PendingStationPage'
import { useParams } from 'react-router-dom'
import { useStationDetail } from '../../../src/features/stations/hooks/useStations'
import { MemoryRouter } from 'react-router-dom'

vi.mock('react-router-dom', async () => {
  const actual = await vi.importActual('react-router-dom')
  return {
    ...actual,
    useParams: vi.fn(),
  }
})

vi.mock('../../../src/features/stations/hooks/useStations', () => ({
  useStationDetail: vi.fn()
}))

const renderWithRouter = (ui) => render(<MemoryRouter>{ui}</MemoryRouter>)

test('renders loading state', () => {
  useParams.mockReturnValue({ id: 's1' })
  useStationDetail.mockReturnValue({ data: null, isLoading: true })
  renderWithRouter(<PendingStationPage />)
  expect(screen.getByText('Loading station data...')).toBeInTheDocument()
})

test('renders not found state', () => {
  useParams.mockReturnValue({ id: 's1' })
  useStationDetail.mockReturnValue({ data: null, isLoading: false })
  renderWithRouter(<PendingStationPage />)
  expect(screen.getByText('Station not found.')).toBeInTheDocument()
})

test('renders pending station details', () => {
  useParams.mockReturnValue({ id: 's1' })
  useStationDetail.mockReturnValue({ data: { name: 'My Pending Station' }, isLoading: false })
  renderWithRouter(<PendingStationPage />)
  expect(screen.getByText('Station Approval Pending')).toBeInTheDocument()
  expect(screen.getByText('My Pending Station')).toBeInTheDocument()
})
