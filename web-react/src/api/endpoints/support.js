import apiClient, { unwrap } from '../client'
import { createResourceApi } from './createResourceApi'

const base = '/support/tickets'

export const supportApi = {
  ...createResourceApi(base),
  /** @param {string|number} id @param {{ body: string }} payload */
  reply: (id, payload) => unwrap(apiClient.post(`${base}/${id}/replies`, payload)),
  /** @param {string|number} id @param {string} assigneeId */
  assign: (id, assigneeId) => unwrap(apiClient.patch(`${base}/${id}/assignee`, { assigneeId })),
  /** @param {string|number} id */
  close: (id) => unwrap(apiClient.post(`${base}/${id}/close`)),
}

export default supportApi
