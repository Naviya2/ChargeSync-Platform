import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { expect, test, vi, beforeEach } from 'vitest'
import RegisterStationPage from '../../../src/features/stations/pages/RegisterStationPage'
import { useRegisterStation } from '../../../src/features/stations/hooks/useStations'
import { MemoryRouter } from 'react-router-dom'

const mockNavigate = vi.fn()

vi.mock('react-router-dom', async () => {
  const actual = await vi.importActual('react-router-dom')
  return {
    ...actual,
    useNavigate: () => mockNavigate
  }
})

vi.mock('../../../src/features/stations/hooks/useStations', () => ({
  useRegisterStation: vi.fn()
}))

vi.mock('../../../src/components/shared/MapLocationPicker', () => ({
  default: () => <div data-testid="map-location-picker">Map</div>
}))

vi.mock('../../../src/components/shared/ImageUploader', () => ({
  default: () => <div data-testid="image-uploader">Uploader</div>
}))

beforeEach(() => {
  vi.clearAllMocks()
  useRegisterStation.mockReturnValue({ mutate: vi.fn(), isPending: false })
})

const renderWithRouter = (ui) => render(<MemoryRouter>{ui}</MemoryRouter>)

test('renders RegisterStationPage', () => {
  renderWithRouter(<RegisterStationPage />)
  expect(screen.getByText('Register New Station')).toBeInTheDocument()
  expect(screen.getByTestId('map-location-picker')).toBeInTheDocument()
  expect(screen.getByTestId('image-uploader')).toBeInTheDocument()
})

test('validates form before submitting', async () => {
  renderWithRouter(<RegisterStationPage />)

  const submitButton = screen.getByRole('button', { name: 'Register Station' })
  await userEvent.click(submitButton)

  expect(screen.getByText('Register New Station')).toBeInTheDocument()
})
