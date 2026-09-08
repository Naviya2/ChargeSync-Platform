import apiClient, { unwrap } from '../client'
import { createResourceApi } from './createResourceApi'

const base = '/vehicles'

export const vehiclesApi = {
  ...createResourceApi(base),
  /** @param {string|number} id */
  chargingHistory: (id) => unwrap(apiClient.get(`${base}/${id}/charging-history`)),
}

export default vehiclesApi
