import { render, screen, fireEvent } from '@testing-library/react'
import { expect, test, vi, beforeEach } from 'vitest'
import VehiclesPage from '../../../src/features/vehicles/pages/VehiclesPage'
import {
  useVehicles,
  useCreateVehicle,
  useUpdateVehicle,
  useDeleteVehicle,
} from '../../../src/features/vehicles/hooks/useVehicles'
import { useUsers } from '../../../src/features/users/hooks/useUsers'

vi.mock('../../../src/features/vehicles/hooks/useVehicles', () => ({
  useVehicles: vi.fn(),
  useCreateVehicle: vi.fn(),
  useUpdateVehicle: vi.fn(),
  useDeleteVehicle: vi.fn(),
}))

vi.mock('../../../src/features/users/hooks/useUsers', () => ({
  useUsers: vi.fn(),
}))

const mockVehicles = [
  {
    id: 'veh-1',
    ownerId: 'u-1',
    make: 'Tesla',
    model: 'Model 3',
    licensePlate: 'CAB-4921',
    connector: 3,
    batteryCapacityKwh: 75,
    maxChargeRateKw: 170,
  },
  {
    id: 'veh-2',
    ownerId: 'u-2',
    make: 'Hyundai',
    model: 'Ioniq 5',
    licensePlate: 'CAB-8821',
    connector: 0,
    batteryCapacityKwh: 77.4,
    maxChargeRateKw: 233,
  },
]

const mockUsers = [
  { id: 'u-1', fullName: 'Kasun Perera', email: 'kasun@test.com' },
  { id: 'u-2', fullName: 'Amal Silva', email: 'amal@test.com' },
]

const mockCreateMutate = vi.fn()
const mockDeleteMutate = vi.fn()
const mockUpdateMutate = vi.fn()

beforeEach(() => {
  vi.clearAllMocks()
  useVehicles.mockReturnValue({ data: mockVehicles, isLoading: false })
  useUsers.mockReturnValue({ data: mockUsers, isLoading: false })
  useCreateVehicle.mockReturnValue({ mutate: mockCreateMutate, isPending: false })
  useUpdateVehicle.mockReturnValue({ mutate: mockUpdateMutate, isPending: false })
  useDeleteVehicle.mockReturnValue({ mutate: mockDeleteMutate, isPending: false })
})

test('VEH-WEB-01: renders loading spinner when data is loading', () => {
  useVehicles.mockReturnValue({ data: [], isLoading: true })
  render(<VehiclesPage />)
  expect(screen.getByText('Vehicle Management')).toBeInTheDocument()
})

test('VEH-WEB-02: renders page header and Add Vehicle button', () => {
  render(<VehiclesPage />)
  expect(screen.getByText('Vehicle Management')).toBeInTheDocument()
  expect(screen.getByText('Manage all registered driver vehicles in the platform.')).toBeInTheDocument()
  expect(screen.getByRole('button', { name: /Add Vehicle/i })).toBeInTheDocument()
})

test('VEH-WEB-03: renders vehicle cards with make, model, and license plate', () => {
  render(<VehiclesPage />)
  expect(screen.getByText('Tesla Model 3')).toBeInTheDocument()
  expect(screen.getByText('CAB-4921')).toBeInTheDocument()
  expect(screen.getByText('Hyundai Ioniq 5')).toBeInTheDocument()
  expect(screen.getByText('CAB-8821')).toBeInTheDocument()
})

test('VEH-WEB-04: renders empty state message when no vehicles match', () => {
  useVehicles.mockReturnValue({ data: [], isLoading: false })
  render(<VehiclesPage />)
  expect(screen.getByText('No vehicles found')).toBeInTheDocument()
})

test('VEH-WEB-05: opens registration modal when clicking Add Vehicle', () => {
  render(<VehiclesPage />)
  const addBtn = screen.getByRole('button', { name: /Add Vehicle/i })
  fireEvent.click(addBtn)

  expect(screen.getByText('Add New Vehicle')).toBeInTheDocument()
  expect(screen.getByPlaceholderText('e.g. Tesla')).toBeInTheDocument()
  expect(screen.getByPlaceholderText('e.g. Model 3')).toBeInTheDocument()
})

test('VEH-WEB-06: opens delete confirmation dialog when delete button clicked', () => {
  render(<VehiclesPage />)
  const deleteButtons = screen.getAllByTitle('Delete vehicle')
  expect(deleteButtons.length).toBeGreaterThan(0)
  fireEvent.click(deleteButtons[0])

  expect(screen.getByText('Remove Vehicle?')).toBeInTheDocument()
})
