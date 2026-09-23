import apiClient, { unwrap } from '../client'
import { createResourceApi } from './createResourceApi'

const base = '/reservations'

export const reservationsApi = {
  ...createResourceApi(base),
  /** @param {string|number} id */
  cancel: (id) => unwrap(apiClient.put(`${base}/${id}/cancel`)),
  /** @param {object} payload - { reservationId, ... } */
  staffCheckin: (payload) => unwrap(apiClient.post(`${base}/staff-checkin`, payload)),
  /** @param {string|number} id */
  getHistory: (id) => unwrap(apiClient.get(`${base}/${id}/history`)),
}

export default reservationsApi
