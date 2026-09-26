import apiClient, { unwrap } from '../client'
import { createResourceApi } from './createResourceApi'

const base = '/stations'

export const stationsApi = {
  ...createResourceApi(base),

  // station owner operations
  getMyStations: () => unwrap(apiClient.get(base)),
  getById: (id) => unwrap(apiClient.get(`${base}/${id}`)),
  register: (data) => unwrap(apiClient.post(base, data)),
  addCharger: (stationId, data) => unwrap(apiClient.post(`${base}/${stationId}/chargers`, data)),
  updateOperatingHours: (stationId, data) => unwrap(apiClient.put(`${base}/${stationId}/operating-hours`, data)),
  addMaintenanceWindow: (chargerId, data) => unwrap(apiClient.post(`${base}/chargers/${chargerId}/maintenance`, data)),
  updateMaintenanceWindow: (maintenanceId, data) => unwrap(apiClient.put(`${base}/maintenance/${maintenanceId}`, data)),
}

export default stationsApi
