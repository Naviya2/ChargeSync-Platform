import { afterEach, describe, it, expect, vi } from 'vitest';
import { fireEvent, render, screen } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import ReservationDetailsModal from '@/features/reservations/components/ReservationDetailsModal';
import { useUpdateReservation, useCancelReservation, useDeleteReservation } from '@/features/reservations/hooks/useReservations';
import { useAuthStore } from '@/store/authStore';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: { retry: false },
  },
});

let currentReservationData = null;

vi.mock('@/features/reservations/hooks/useReservations', () => ({
  useReservationDetail: vi.fn(() => ({
    data: currentReservationData,
    isLoading: false
  })),
  useReservationHistory: vi.fn(() => ({
    data: [],
    isLoading: false
  })),
  useCancelReservation: vi.fn(() => ({
    mutate: vi.fn(),
    isPending: false
  })),
  useUpdateReservation: vi.fn(() => ({
    mutate: vi.fn(),
    isPending: false
  })),
  useDeleteReservation: vi.fn(() => ({
    mutate: vi.fn(),
    isPending: false
  })),
  useApproveReservation: vi.fn(() => ({
    mutate: vi.fn(),
    isPending: false
  })),
  useRejectReservation: vi.fn(() => ({
    mutate: vi.fn(),
    isPending: false
  }))
}));

describe('ReservationDetailsModal', () => {
  afterEach(() => useAuthStore.setState({ user: null }));
  const defaultReservation = {
    id: 'res-123',
    driverId: 'drv-456',
    chargerId: 'chr-789',
    startTime: '2026-10-01T10:00:00Z',
    endTime: '2026-10-01T11:00:00Z',
    reservationQRCode: 'token-abc',
    advanceDepositAmount: 0,
    status: 'Pending',
    createdAt: '2026-10-01T09:00:00Z',
    stationName: 'Test Station',
    chargerName: 'Charger 1',
    vehicleName: 'Test Vehicle',
    driverName: 'John Doe',
  };

  it('renders reservation details correctly', () => {
    currentReservationData = defaultReservation;
    render(
      <QueryClientProvider client={queryClient}>
        <ReservationDetailsModal reservationId={defaultReservation.id} onClose={vi.fn()} />
      </QueryClientProvider>
    );
    
    expect(screen.getByText('Reservation Details')).toBeInTheDocument();
    expect(screen.getByText('John Doe')).toBeInTheDocument();
    expect(screen.getByText('Test Station')).toBeInTheDocument();
  });

  it('renders walk-in reservation details correctly', () => {
    const walkInReservation = {
      ...defaultReservation,
      driverId: null,
      walkInCustomerName: 'Jane Smith',
      walkInVehicleNumber: 'AB-1234',
      walkInBatteryCapacity: 50,
    };
    
    currentReservationData = walkInReservation;
    render(
      <QueryClientProvider client={queryClient}>
        <ReservationDetailsModal reservationId={walkInReservation.id} onClose={vi.fn()} />
      </QueryClientProvider>
    );
    
    expect(screen.getByText('Jane Smith')).toBeInTheDocument();
    expect(screen.getByText('AB-1234')).toBeInTheDocument();
    expect(screen.getByText('50 kWh')).toBeInTheDocument();
  });

  it('displays meter photo if available', () => {
    const completedReservation = {
      ...defaultReservation,
      status: 'Completed',
      sessionMeterPhotoUrl: 'https://cloudinary.com/test-photo.png',
      invoiceNetAmount: 500,
    };
    
    currentReservationData = completedReservation;
    render(
      <QueryClientProvider client={queryClient}>
        <ReservationDetailsModal reservationId={completedReservation.id} onClose={vi.fn()} />
      </QueryClientProvider>
    );
    
    const image = screen.getByAltText('Meter Reading');
    expect(image).toBeInTheDocument();
    expect(image).toHaveAttribute('src', 'https://cloudinary.com/test-photo.png');
  });

  it('allows editing reservation time', async () => {
    currentReservationData = { ...defaultReservation, status: 'Confirmed' };
    const mockUpdate = vi.fn((payload, { onSuccess }) => {
      onSuccess();
    });
    vi.mocked(useUpdateReservation).mockReturnValue({ mutate: mockUpdate, isPending: false });

    render(
      <QueryClientProvider client={queryClient}>
        <ReservationDetailsModal reservationId={defaultReservation.id} onClose={vi.fn()} />
      </QueryClientProvider>
    );
    
    const editBtn = screen.getByRole('button', { name: /edit time/i });
    editBtn.click();
    
    const saveBtn = await screen.findByRole('button', { name: /save changes/i });
    expect(saveBtn).toBeInTheDocument();
    
    saveBtn.click();
    expect(mockUpdate).toHaveBeenCalledWith(
      expect.objectContaining({ id: 'res-123' }),
      expect.any(Object)
    );
  });

  it('handles cancellation workflow', async () => {
    currentReservationData = { ...defaultReservation, status: 'Confirmed' };
    const mockCancel = vi.fn((id, { onSuccess }) => {
      onSuccess();
    });
    const mockOnClose = vi.fn();
    vi.mocked(useCancelReservation).mockReturnValue({ mutate: mockCancel, isPending: false });

    render(
      <QueryClientProvider client={queryClient}>
        <ReservationDetailsModal reservationId={defaultReservation.id} onClose={mockOnClose} />
      </QueryClientProvider>
    );
    
    const cancelBtn = screen.getByRole('button', { name: /cancel booking/i });
    cancelBtn.click();
    
    const confirmBtn = await screen.findByRole('button', { name: /yes, cancel booking/i });
    confirmBtn.click();
    
    expect(mockCancel).toHaveBeenCalledWith('res-123', expect.any(Object));
    expect(mockOnClose).toHaveBeenCalled();
  });

  it('warns a driver about the late fee and shows the advance separately', async () => {
    useAuthStore.setState({ user: { id: 'drv-456', role: 'Driver' } });
    currentReservationData = { ...defaultReservation, status: 'Confirmed', advanceDepositAmount: 500 };
    render(
      <QueryClientProvider client={queryClient}>
        <ReservationDetailsModal reservationId={defaultReservation.id} onClose={vi.fn()} />
      </QueryClientProvider>
    );

    fireEvent.click(screen.getByRole('button', { name: /cancel booking/i }));
    expect(screen.getByText(/Cancelling less than 2 hours before the booked start/)).toBeInTheDocument();
    expect(screen.getByText(/Cancelling 2 hours or more before start is free/)).toBeInTheDocument();
    expect(screen.getByText('Advance Deposit Paid')).toBeInTheDocument();
  });

  it('offers approval and rejection for pending requests instead of cancellation', () => {
    useAuthStore.setState({ user: { id: 'owner-1', role: 'StationOwner' } });
    currentReservationData = defaultReservation;
    render(
      <QueryClientProvider client={queryClient}>
        <ReservationDetailsModal reservationId={defaultReservation.id} onClose={vi.fn()} />
      </QueryClientProvider>
    );

    expect(screen.getByRole('button', { name: /approve request/i })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /reject request/i })).toBeInTheDocument();
    expect(screen.queryByRole('button', { name: /cancel booking/i })).not.toBeInTheDocument();
  });

  it('shows staff cancellation and both fee records without claiming a new fee', () => {
    useAuthStore.setState({ user: { id: 'owner-1', role: 'StationOwner' } });
    currentReservationData = {
      ...defaultReservation,
      status: 'Confirmed',
      lateCancellationFee: 500,
      cancellationFeesPaid: 1000,
    };
    render(
      <QueryClientProvider client={queryClient}>
        <ReservationDetailsModal reservationId={defaultReservation.id} onClose={vi.fn()} />
      </QueryClientProvider>
    );

    fireEvent.click(screen.getByRole('button', { name: /cancel booking/i }));
    expect(screen.getByText(/Staff cancellation does not add a late fee/)).toBeInTheDocument();
    expect(screen.getByText(/Late cancellation fee assessed: LKR 500.00/)).toBeInTheDocument();
    expect(screen.getByText(/Previous cancellation fees paid with this booking: LKR 1000.00/)).toBeInTheDocument();
  });

  it('handles deletion workflow', async () => {
    currentReservationData = { ...defaultReservation, status: 'Cancelled' };
    const mockDelete = vi.fn((id, { onSuccess }) => {
      onSuccess();
    });
    const mockOnClose = vi.fn();
    vi.mocked(useDeleteReservation).mockReturnValue({ mutate: mockDelete, isPending: false });

    render(
      <QueryClientProvider client={queryClient}>
        <ReservationDetailsModal reservationId={defaultReservation.id} onClose={mockOnClose} />
      </QueryClientProvider>
    );
    
    const deleteBtn = screen.getByRole('button', { name: /delete/i });
    deleteBtn.click();
    
    const confirmBtn = await screen.findByRole('button', { name: /yes, delete/i });
    confirmBtn.click();
    
    expect(mockDelete).toHaveBeenCalledWith('res-123', expect.any(Object));
    expect(mockOnClose).toHaveBeenCalled();
  });

  it('lets a support viewer inspect a booking without mutation controls', () => {
    currentReservationData = { ...defaultReservation, status: 'Confirmed' };
    render(
      <QueryClientProvider client={queryClient}>
        <ReservationDetailsModal reservationId={defaultReservation.id} readOnly onClose={vi.fn()} />
      </QueryClientProvider>
    );
    expect(screen.getByText('Reservation Details')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Close' })).toBeInTheDocument();
    expect(screen.queryByRole('button', { name: /delete|edit time|cancel booking|approve request|reject request/i })).not.toBeInTheDocument();
  });
});
