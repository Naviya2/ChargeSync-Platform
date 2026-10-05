import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import AddReservationModal from '@/features/reservations/components/AddReservationModal';
import { apiClient } from '@/api/client';
import { useNotificationStore } from '@/store/notificationStore';
import { useAuthStore } from '@/store/authStore';

// Mock dependencies
vi.mock('@/api/client', () => ({
  apiClient: {
    get: vi.fn(),
    post: vi.fn(),
  }
}));

vi.mock('@/store/notificationStore', () => ({
  useNotificationStore: vi.fn()
}));

vi.mock('@/store/authStore', () => ({
  useAuthStore: vi.fn()
}));

const queryClient = new QueryClient({
  defaultOptions: {
    queries: { retry: false },
  },
});

describe('AddReservationModal Integration', () => {
  const mockOnClose = vi.fn();
  const mockAddNotification = vi.fn();

  beforeEach(() => {
    vi.clearAllMocks();
    queryClient.clear();
    
    useNotificationStore.mockImplementation(() => {
      // Returns mockAddNotification when component accesses addNotification
      return mockAddNotification;
    });
    
    useAuthStore.mockImplementation(() => ({ role: 'Admin' }));

    // Setup default API responses for queries
    apiClient.get.mockImplementation((url) => {
      if (url === '/users') {
        return Promise.resolve({ data: [{ id: 'driver-1', fullName: 'John Doe', email: 'john@example.com', role: 'Driver' }] });
      }
      if (url.startsWith('/vehicles/user/')) {
        return Promise.resolve({ data: [{ id: 'veh-1', make: 'Tesla', model: 'Model 3', licensePlate: 'TES-123', batteryCapacityKwh: 50, maxChargeRateKw: 50 }] });
      }
      if (url === '/stations/all' || url === '/stations') {
        return Promise.resolve({ data: [{ id: 'station-1', name: 'Main Station', chargers: [{ id: 'charger-1', bayLabel: 'Bay 1', powerKw: 50 }] }] });
      }
      if (url === '/reservations/availability') {
        return Promise.resolve({ data: [{ startTime: '2026-10-01T10:00:00Z', endTime: '2026-10-01T11:00:00Z' }] });
      }
      return Promise.resolve({ data: [] });
    });
  });

  it('renders correctly and loads data', async () => {
    render(
      <QueryClientProvider client={queryClient}>
        <AddReservationModal onClose={mockOnClose} />
      </QueryClientProvider>
    );

    expect(screen.getByText('Add Reservation')).toBeInTheDocument();
    
    // Wait for the driver to be loaded
    await waitFor(() => {
      expect(screen.getByText('John Doe (john@example.com)')).toBeInTheDocument();
    });
    
    // Wait for the station to be loaded
    await waitFor(() => {
      expect(screen.getByText('Main Station')).toBeInTheDocument();
    });
  });

  it('allows selection and successful form submission', async () => {
    apiClient.post.mockResolvedValueOnce({ data: { id: 'new-res-1' } });
    const user = userEvent.setup();

    const { container } = render(
      <QueryClientProvider client={queryClient}>
        <AddReservationModal onClose={mockOnClose} />
      </QueryClientProvider>
    );

    await screen.findByText('John Doe (john@example.com)');
    await screen.findByText('Main Station');

    const combos = screen.getAllByRole('combobox');
    const driverSelect = combos[0];
    await user.selectOptions(driverSelect, 'driver-1');

    await screen.findByText('Tesla Model 3 (TES-123)');
    const vehicleSelect = combos[1];
    await user.selectOptions(vehicleSelect, 'veh-1');

    const stationSelect = combos[2];
    await user.selectOptions(stationSelect, 'station-1');

    const chargerSelect = combos[3];
    await user.selectOptions(chargerSelect, 'charger-1');

    const dateInput = container.querySelector('input[type="date"]');
    await user.type(dateInput, '2026-10-01');

    await waitFor(() => expect(screen.getAllByRole('combobox').length).toBe(5));
    const timeSelect = screen.getAllByRole('combobox')[4];
    await user.selectOptions(timeSelect, '2026-10-01T10:00:00Z');

    const submitBtn = screen.getByRole('button', { name: /create reservation/i });
    await user.click(submitBtn);

    await waitFor(() => {
      expect(apiClient.post).toHaveBeenCalledWith('/reservations/admin', {
        driverId: 'driver-1',
        vehicleId: 'veh-1',
        chargerId: 'charger-1',
        startTime: expect.any(String),
        endTime: expect.any(String)
      });
      expect(mockAddNotification).toHaveBeenCalledWith('success', 'Reservation Created Successfully', expect.any(String));
      expect(mockOnClose).toHaveBeenCalled();
    });
  });

  it('displays error on failed submission', async () => {
    apiClient.post.mockRejectedValueOnce({ response: { data: { message: 'Slot already taken' } } });
    const user = userEvent.setup();

    const { container } = render(
      <QueryClientProvider client={queryClient}>
        <AddReservationModal onClose={mockOnClose} />
      </QueryClientProvider>
    );

    await screen.findByText('John Doe (john@example.com)');
    const combos = screen.getAllByRole('combobox');
    await user.selectOptions(combos[0], 'driver-1');
    await screen.findByText('Main Station');
    await user.selectOptions(combos[2], 'station-1');
    await user.selectOptions(combos[3], 'charger-1');
    await user.type(container.querySelector('input[type="date"]'), '2026-10-01');
    
    await waitFor(() => expect(screen.getAllByRole('combobox').length).toBe(5));
    const timeSelect = screen.getAllByRole('combobox')[4];
    await user.selectOptions(timeSelect, '2026-10-01T10:00:00Z');

    await user.click(screen.getByRole('button', { name: /create reservation/i }));

    await waitFor(() => {
      expect(mockAddNotification).toHaveBeenCalledWith('error', 'Creation Failed', 'Slot already taken');
      expect(mockOnClose).not.toHaveBeenCalled();
    });
  });
});
