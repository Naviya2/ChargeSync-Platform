import apiClient, { unwrap } from '../client'
import { createResourceApi } from './createResourceApi'

const base = '/payments'

export const paymentsApi = {
  ...createResourceApi(base),
  /** @param {string|number} id */
  refund: (id, payload) => unwrap(apiClient.post(`${base}/${id}/refund`, payload)),
  /** @param {Record<string, unknown>} [params] */
  invoices: (params) => unwrap(apiClient.get(`${base}/invoices`, { params })),
}

export default paymentsApi
