import { render, screen } from '@testing-library/react'
import { expect, test, vi } from 'vitest'
import StationFilterBar from '../../../src/features/stations/components/StationFilterBar'
import StationKpiStrip from '../../../src/features/stations/components/StationKpiStrip'
import StationsHeader from '../../../src/features/stations/components/StationsHeader'

import { MemoryRouter } from 'react-router-dom'

vi.mock('react-router-dom', async () => {
  const actual = await vi.importActual('react-router-dom')
  return {
    ...actual,
    useNavigate: () => vi.fn()
  }
})

test('renders StationFilterBar', () => {
  render(<StationFilterBar counts={{ all: 1, active: 1, pending: 0, maintenance: 0 }} />)
  expect(screen.getByText(/All Stations/i)).toBeInTheDocument()
})

test('renders StationKpiStrip', () => {
  const mockKpis = [{ key: 'kpi1', label: 'Test KPI', value: '10' }]
  render(<StationKpiStrip kpis={mockKpis} />)
  expect(screen.getByText('Test KPI')).toBeInTheDocument()
  expect(screen.getByText('10')).toBeInTheDocument()
})

test('renders StationsHeader', () => {
  render(<MemoryRouter><StationsHeader stations={[]} /></MemoryRouter>)
  expect(screen.getByText(/My Charging Stations/i)).toBeInTheDocument()
})
