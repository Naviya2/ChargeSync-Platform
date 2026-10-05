import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import ReservationsPage from '@/features/reservations/pages/ReservationsPage';
import { useReservationsList } from '@/features/reservations/hooks/useReservations';
import { useAuthStore } from '@/store/authStore';

vi.mock('@/features/reservations/hooks/useReservations', () => ({
  useReservationsList: vi.fn(),
  usePendingApprovalsQuery: vi.fn(() => ({ data: { items: [] }, isLoading: false })),
  useApproveReservation: vi.fn(() => ({ mutate: vi.fn(), isPending: false })),
  useRejectReservation: vi.fn(() => ({ mutate: vi.fn(), isPending: false }))
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

vi.mock('@/features/stations/components/PendingApprovalsCard', () => ({
  default: () => <div data-testid="pending-approvals-card">Pending Approvals</div>
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
    useAuthStore.setState({ user: { id: 'admin-1', role: 'Admin' } });
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

  it('filters by booking status and can clear an empty filter result', async () => {
    useReservationsList.mockReturnValue({ data: { items: mockReservations }, isLoading: false, isError: false });
    const user = userEvent.setup();
    render(<ReservationsPage />);
    const filters = screen.getByRole('group', { name: 'Reservation status filters' });
    await user.click(within(filters).getByRole('button', { name: 'Pending' }));
    expect(screen.getByText('Alice')).toBeInTheDocument();
    expect(screen.queryByText('Bob')).not.toBeInTheDocument();
    await user.click(within(filters).getByRole('button', { name: 'Completed' }));
    expect(screen.getByText('No matching reservations found.')).toBeInTheDocument();
    await user.click(screen.getByRole('button', { name: 'Clear filters' }));
    expect(screen.getByText('Bob')).toBeInTheDocument();
  });

  it('requests the next API page and preserves sorting controls', async () => {
    useReservationsList.mockReturnValue({ data: { items: mockReservations, totalCount: 21, totalPages: 2 }, isLoading: false, isError: false });
    const user = userEvent.setup();
    render(<ReservationsPage />);
    expect(screen.getByRole('button', { name: 'Previous reservations page' })).toBeDisabled();
    await user.click(screen.getByRole('button', { name: 'Next reservations page' }));
    expect(useReservationsList).toHaveBeenLastCalledWith({ page: 2, pageSize: 20 }, { refetchInterval: 10000 });
    expect(screen.getByRole('button', { name: 'Next reservations page' })).toBeDisabled();
    await user.selectOptions(screen.getByRole('combobox', { name: 'Sort reservations' }), 'time_asc');
    const rows = screen.getAllByRole('row');
    expect(within(rows[1]).getByText('Alice')).toBeInTheDocument();
  });

  it('keeps support managers out of staff-only creation and approval controls', () => {
    useAuthStore.setState({ user: { id: 'support-1', role: 'SupportManager' } });
    useReservationsList.mockReturnValue({ data: { items: mockReservations }, isLoading: false, isError: false });
    render(<ReservationsPage />);
    expect(screen.queryByRole('button', { name: /Add Reservation/i })).not.toBeInTheDocument();
    expect(screen.queryByTestId('pending-approvals-card')).not.toBeInTheDocument();
    expect(screen.getAllByRole('button', { name: /View Details/i })).toHaveLength(2);
  });
});
