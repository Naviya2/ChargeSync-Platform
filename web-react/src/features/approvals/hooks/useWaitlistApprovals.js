import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'

export function useWaitlistApprovals() {
  return useQuery({
    queryKey: ['waitlist-approvals'],
    queryFn: async () => {
      // Return real data here once API is ready, for now empty as no real requests exist for this user.
      return []
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
