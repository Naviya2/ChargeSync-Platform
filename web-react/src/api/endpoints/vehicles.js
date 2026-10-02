import apiClient, { unwrap } from '../client'
import { createResourceApi } from './createResourceApi'

const base = '/vehicles'

export const vehiclesApi = {
  // Driver endpoints
  ...createResourceApi(base),
  chargingHistory: (id) => unwrap(apiClient.get(`${base}/${id}/charging-history`)),

  // Admin-only endpoints
  listAll: () => unwrap(apiClient.get(`${base}/all`)),
  adminUpdate: (id, payload) => unwrap(apiClient.put(`${base}/admin/${id}`, payload)),
  adminRemove: (id) => unwrap(apiClient.delete(`${base}/admin/${id}`)),
}

export default vehiclesApi
