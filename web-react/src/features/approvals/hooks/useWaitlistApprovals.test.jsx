import { renderHook, waitFor } from '@testing-library/react'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { useWaitlistApprovals, useApproveWaitlistOverride, useRejectWaitlistOverride } from './useWaitlistApprovals'
import React from 'react'
import { describe, it, expect, beforeEach } from 'vitest'

const queryClient = new QueryClient()
const wrapper = ({ children }) => (
  <QueryClientProvider client={queryClient}>
    {children}
  </QueryClientProvider>
)

describe('useWaitlistApprovals Hooks', () => {
  beforeEach(() => {
    queryClient.clear()
  })

  it('fetches waitlist approvals', async () => {
    const { result } = renderHook(() => useWaitlistApprovals(), { wrapper })
    
    await waitFor(() => expect(result.current.isSuccess).toBe(true))
    
    expect(result.current.data.length).toBe(2)
    expect(result.current.data[0].id).toBe('w-1')
  })

  it('approves a waitlist override', async () => {
    const { result } = renderHook(() => useApproveWaitlistOverride(), { wrapper })
    
    result.current.mutate('w-1')
    
    await waitFor(() => expect(result.current.isSuccess).toBe(true))
    expect(result.current.data.success).toBe(true)
    expect(result.current.data.id).toBe('w-1')
  })

  it('rejects a waitlist override', async () => {
    const { result } = renderHook(() => useRejectWaitlistOverride(), { wrapper })
    
    result.current.mutate({ id: 'w-2', reason: 'Not priority' })
    
    await waitFor(() => expect(result.current.isSuccess).toBe(true))
    expect(result.current.data.success).toBe(true)
    expect(result.current.data.id).toBe('w-2')
    expect(result.current.data.reason).toBe('Not priority')
  })
})
