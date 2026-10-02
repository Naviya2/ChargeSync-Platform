import { describe, it, expect, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import ReservationDetailsModal from '@/features/reservations/components/ReservationDetailsModal';
import { useUpdateReservation, useCancelReservation, useDeleteReservation } from '@/features/reservations/hooks/useReservations';

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
  }))
}));

describe('ReservationDetailsModal', () => {
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
    currentReservationData = defaultReservation;
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
    currentReservationData = defaultReservation;
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

  it('handles deletion workflow', async () => {
    currentReservationData = defaultReservation;
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
});
