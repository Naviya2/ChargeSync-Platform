import apiClient, { unwrap } from '../client'
import { createResourceApi } from './createResourceApi'

const base = '/reservations'

export const reservationsApi = {
  ...createResourceApi(base),
  /** @param {string|number} id */
  cancel: (id) => unwrap(apiClient.post(`${base}/${id}/cancel`)),
  /** @param {string|number} id */
  checkIn: (id) => unwrap(apiClient.post(`${base}/${id}/check-in`)),
}

export default reservationsApi
