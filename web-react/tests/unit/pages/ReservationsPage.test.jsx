import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import ReservationsPage from '@/features/reservations/pages/ReservationsPage';
import { useReservationsList } from '@/features/reservations/hooks/useReservations';

vi.mock('@/features/reservations/hooks/useReservations', () => ({
  useReservationsList: vi.fn()
}));

vi.mock('@/features/reservations/components/ReservationDetailsModal', () => ({
  default: ({ reservationId, onClose }) => (
    <div data-testid="details-modal">
      Modal {reservationId}
      <button onClick={onClose}>Close Details</button>
    </div>
  )
}));

vi.mock('@/features/reservations/components/AddReservationModal', () => ({
  default: ({ onClose }) => (
    <div data-testid="add-modal">
      Add Modal
      <button onClick={onClose}>Close Add</button>
    </div>
  )
}));

vi.mock('@/store/notificationStore', () => ({
  useNotificationStore: vi.fn(() => vi.fn())
}));

describe('ReservationsPage', () => {
  const mockReservations = [
    { id: 'res-1', driverId: 'drv-1', driverName: 'Alice', stationName: 'Station A', startTime: '2026-10-01T10:00:00Z', status: 'Pending', endTime: '2026-10-01T11:00:00Z' },
    { id: 'res-2', driverId: 'drv-2', driverName: 'Bob', stationName: 'Station B', startTime: '2026-10-02T10:00:00Z', status: 'Confirmed', endTime: '2026-10-02T11:00:00Z' },
  ];

  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('renders loading state', () => {
    useReservationsList.mockReturnValue({ data: null, isLoading: true, isError: false });
    render(<ReservationsPage />);
    expect(screen.getByText(/Loading reservations/i)).toBeInTheDocument();
  });

  it('renders error state', () => {
    useReservationsList.mockReturnValue({ data: null, isLoading: false, isError: true });
    render(<ReservationsPage />);
    expect(screen.getByText(/Failed to load reservations/i)).toBeInTheDocument();
  });

  it('renders empty state', () => {
    useReservationsList.mockReturnValue({ data: { items: [] }, isLoading: false, isError: false });
    render(<ReservationsPage />);
    expect(screen.getByText(/No reservations yet/i)).toBeInTheDocument();
  });

  it('renders reservations and allows search', async () => {
    useReservationsList.mockReturnValue({ data: { items: mockReservations }, isLoading: false, isError: false });
    const user = userEvent.setup();
    render(<ReservationsPage />);

    expect(screen.getByText('Alice')).toBeInTheDocument();
    expect(screen.getByText('Bob')).toBeInTheDocument();

    const searchInput = screen.getByPlaceholderText(/search/i);
    await user.type(searchInput, 'Alice');

    expect(screen.getByText('Alice')).toBeInTheDocument();
    expect(screen.queryByText('Bob')).not.toBeInTheDocument();
  });

  it('opens and closes Add Modal', async () => {
    useReservationsList.mockReturnValue({ data: { items: [] }, isLoading: false, isError: false });
    const user = userEvent.setup();
    render(<ReservationsPage />);

    const addBtn = screen.getByRole('button', { name: /Add Reservation/i });
    await user.click(addBtn);

    expect(screen.getByTestId('add-modal')).toBeInTheDocument();

    const closeBtn = screen.getByRole('button', { name: /Close Add/i });
    await user.click(closeBtn);

    expect(screen.queryByTestId('add-modal')).not.toBeInTheDocument();
  });

  it('opens and closes Details Modal', async () => {
    useReservationsList.mockReturnValue({ data: { items: mockReservations }, isLoading: false, isError: false });
    const user = userEvent.setup();
    render(<ReservationsPage />);

    const viewBtns = screen.getAllByRole('button', { name: /View Details/i });
    await user.click(viewBtns[0]);

    expect(screen.getByTestId('details-modal')).toBeInTheDocument();
    expect(screen.getByText('Modal res-2')).toBeInTheDocument();

    const closeBtn = screen.getByRole('button', { name: /Close Details/i });
    await user.click(closeBtn);

    expect(screen.queryByTestId('details-modal')).not.toBeInTheDocument();
  });
});
