import { renderHook } from '@testing-library/react'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { useStations, useMyStations } from '../../../src/features/stations/hooks/useStations'
import { describe, it, expect, beforeEach } from 'vitest'

const queryClient = new QueryClient({
  defaultOptions: { queries: { retry: false } },
})

const wrapper = ({ children }) => (
  <QueryClientProvider client={queryClient}>
    {children}
  </QueryClientProvider>
)

describe('useStations Hooks', () => {
  beforeEach(() => {
    queryClient.clear()
  })

  it('fetches stations', async () => {
    const { result } = renderHook(() => useStations(), { wrapper })
    expect(result.current.isLoading).toBe(true)
  })

  it('fetches my stations', async () => {
    const { result } = renderHook(() => useMyStations(), { wrapper })
    expect(result.current.isLoading).toBe(true)
  })
})
