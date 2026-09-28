import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'

export function useWaitlistApprovals() {
  return useQuery({
    queryKey: ['waitlist-approvals'],
    queryFn: async () => {
      // Simulated delay for fetching AI agent override requests
      await new Promise(resolve => setTimeout(resolve, 800))
      return [
        {
          id: 'w-1',
          driverName: 'Emergency Medical Vehicle',
          stationName: 'Downtown FastHub',
          requestedTime: new Date(Date.now() + 1000 * 60 * 30).toISOString(),
          reason: 'Urgent charging needed. High priority waitlist override triggered by AI Agent.',
          status: 'PendingApproval'
        },
        {
          id: 'w-2',
          driverName: 'John Doe (VIP Tier)',
          stationName: 'Suburban Eco Charge',
          requestedTime: new Date(Date.now() + 1000 * 60 * 60).toISOString(),
          reason: 'Loyalty status override attempt for peak hour slot.',
          status: 'PendingApproval'
        }
      ]
    }
  })
}

export function useApproveWaitlistOverride() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (id) => {
      await new Promise(resolve => setTimeout(resolve, 500))
      return { success: true, id }
    },
    onSuccess: (data) => {
      queryClient.setQueryData(['waitlist-approvals'], (old) => {
        return old?.filter(item => item.id !== data.id) || []
      })
    }
  })
}

export function useRejectWaitlistOverride() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async ({ id, reason }) => {
      await new Promise(resolve => setTimeout(resolve, 500))
      return { success: true, id, reason }
    },
    onSuccess: (data) => {
      queryClient.setQueryData(['waitlist-approvals'], (old) => {
        return old?.filter(item => item.id !== data.id) || []
      })
    }
  })
}
