import { QueryClient } from '@tanstack/react-query'

/**
 * Shared TanStack Query client. All server state flows through this.
 */
export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 1,
      refetchOnWindowFocus: false,
      staleTime: 30_000,
    },
    mutations: {
      retry: 0,
    },
  },
})
