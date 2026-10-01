import apiClient, { unwrap } from '../client'
import { createResourceApi } from './createResourceApi'

const base = '/sessions'

export const sessionsApi = {
  ...createResourceApi(base),
  /** Live/active charging sessions. @param {Record<string, unknown>} [params] */
  active: (params) => unwrap(apiClient.get(`${base}/active`, { params })),
  /** @param {string|number} id */
  stop: (id) => unwrap(apiClient.post(`${base}/${id}/stop`)),
  /** 
   * Returns URL for the meter photo. Requires auth header if used via fetch, 
   * or can be passed to an authorized image component. 
   * @param {string|number} id 
   */
  meterPhotoUrl: (id) => `${apiClient.defaults.baseURL}${base}/${id}/meter-photo`,
}

export default sessionsApi
