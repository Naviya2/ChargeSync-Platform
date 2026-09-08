import apiClient, { unwrap } from '../client'
import { createResourceApi } from './createResourceApi'

const base = '/loyalty'

export const loyaltyApi = {
  ...createResourceApi(base),
  /** @param {string|number} userId */
  balance: (userId) => unwrap(apiClient.get(`${base}/balance/${userId}`)),
  /** @param {{ userId: string|number, points: number, reason?: string }} payload */
  adjust: (payload) => unwrap(apiClient.post(`${base}/adjust`, payload)),
  rewards: () => unwrap(apiClient.get(`${base}/rewards`)),
}

export default loyaltyApi
