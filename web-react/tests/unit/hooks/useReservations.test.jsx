import { describe, it, expect, vi, beforeEach } from 'vitest';
import { renderHook, waitFor } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { 
  useReservationsList, 
  useReservationDetail, 
  useReservationHistory,
  useCancelReservation,
  useUpdateReservation,
  useDeleteReservation
} from '@/features/reservations/hooks/useReservations';
import { reservationsApi } from '@/api/endpoints/reservations';

vi.mock('@/api/endpoints/reservations', () => ({
  reservationsApi: {
    list: vi.fn(),
    get: vi.fn(),
    getHistory: vi.fn(),
    cancel: vi.fn(),
    update: vi.fn(),
    remove: vi.fn(),
  }
}));

const createWrapper = () => {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  });
  return ({ children }) => (
    <QueryClientProvider client={queryClient}>
      {children}
    </QueryClientProvider>
  );
};

describe('useReservations hooks', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('useReservationsList calls api.list', async () => {
    reservationsApi.list.mockResolvedValueOnce({ items: [] });
    const { result } = renderHook(() => useReservationsList(), { wrapper: createWrapper() });
    await waitFor(() => expect(result.current.isSuccess).toBe(true));
    expect(reservationsApi.list).toHaveBeenCalled();
  });

  it('useReservationDetail calls api.get', async () => {
    reservationsApi.get.mockResolvedValueOnce({ id: 'res-1' });
    const { result } = renderHook(() => useReservationDetail('res-1'), { wrapper: createWrapper() });
    await waitFor(() => expect(result.current.isSuccess).toBe(true));
    expect(reservationsApi.get).toHaveBeenCalledWith('res-1');
  });

  it('useReservationHistory calls api.getHistory', async () => {
    reservationsApi.getHistory.mockResolvedValueOnce([]);
    const { result } = renderHook(() => useReservationHistory('res-1'), { wrapper: createWrapper() });
    await waitFor(() => expect(result.current.isSuccess).toBe(true));
    expect(reservationsApi.getHistory).toHaveBeenCalledWith('res-1');
  });

  it('useCancelReservation calls api.cancel', async () => {
    reservationsApi.cancel.mockResolvedValueOnce({});
    const { result } = renderHook(() => useCancelReservation(), { wrapper: createWrapper() });
    result.current.mutate('res-1');
    await waitFor(() => expect(result.current.isSuccess).toBe(true));
    expect(reservationsApi.cancel).toHaveBeenCalledWith('res-1');
  });

  it('useUpdateReservation calls api.update', async () => {
    reservationsApi.update.mockResolvedValueOnce({});
    const { result } = renderHook(() => useUpdateReservation(), { wrapper: createWrapper() });
    result.current.mutate({ id: 'res-1', data: { startTime: 'now' } });
    await waitFor(() => expect(result.current.isSuccess).toBe(true));
    expect(reservationsApi.update).toHaveBeenCalledWith('res-1', { startTime: 'now' });
  });

  it('useDeleteReservation calls api.remove', async () => {
    reservationsApi.remove.mockResolvedValueOnce({});
    const { result } = renderHook(() => useDeleteReservation(), { wrapper: createWrapper() });
    result.current.mutate('res-1');
    await waitFor(() => expect(result.current.isSuccess).toBe(true));
    expect(reservationsApi.remove).toHaveBeenCalledWith('res-1');
  });
});
