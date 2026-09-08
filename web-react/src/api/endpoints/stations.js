import apiClient, { unwrap } from '../client'
import { createResourceApi } from './createResourceApi'

const base = '/stations'

export const stationsApi = {
  ...createResourceApi(base),
  /** @param {string|number} id */
  connectors: (id) => unwrap(apiClient.get(`${base}/${id}/connectors`)),
  /** @param {string|number} id @param {'online'|'offline'|'maintenance'} status */
  setStatus: (id, status) => unwrap(apiClient.patch(`${base}/${id}/status`, { status })),
}

export default stationsApi
