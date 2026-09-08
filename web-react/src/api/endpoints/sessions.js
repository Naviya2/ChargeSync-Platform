import apiClient, { unwrap } from '../client'
import { createResourceApi } from './createResourceApi'

const base = '/sessions'

export const sessionsApi = {
  ...createResourceApi(base),
  /** Live/active charging sessions. @param {Record<string, unknown>} [params] */
  active: (params) => unwrap(apiClient.get(`${base}/active`, { params })),
  /** @param {string|number} id */
  stop: (id) => unwrap(apiClient.post(`${base}/${id}/stop`)),
}

export default sessionsApi
