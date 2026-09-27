import apiClient, { unwrap } from '../client'
import { createResourceApi } from './createResourceApi'

const base = '/stations'

export const stationsApi = {
  ...createResourceApi(base),

  getMyStations: () => unwrap(apiClient.get(base)),
  getById: (id) => unwrap(apiClient.get(`${base}/${id}`)),
  register: (data) => unwrap(apiClient.post(base, data)),
  addCharger: (stationId, data) => unwrap(apiClient.post(`${base}/${stationId}/chargers`, data)),
  updateCharger: (stationId, chargerId, data) => unwrap(apiClient.put(`${base}/${stationId}/chargers/${chargerId}`, data)),
  deleteCharger: (stationId, chargerId) => unwrap(apiClient.delete(`${base}/${stationId}/chargers/${chargerId}`)),
  updateOperatingHours: (stationId, data) => unwrap(apiClient.put(`${base}/${stationId}/operating-hours`, data)),
  addMaintenanceWindow: (chargerId, data) => unwrap(apiClient.post(`${base}/chargers/${chargerId}/maintenance`, data)),
  updateMaintenanceWindow: (maintenanceId, data) => unwrap(apiClient.put(`${base}/maintenance/${maintenanceId}`, data)),
  deleteMaintenanceWindow: (maintenanceId) => unwrap(apiClient.delete(`${base}/maintenance/${maintenanceId}`)),
}

export default stationsApi
