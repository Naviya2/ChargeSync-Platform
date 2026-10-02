import apiClient, { unwrap } from '../client'
const base = '/support-tickets'

export const supportApi = {
  analyze: (id) => unwrap(apiClient.post(`${base}/${id}/analysis`, null, { timeout: 30_000 })),
  list: (params) => unwrap(apiClient.get(base, { params })),
  get: (id) => unwrap(apiClient.get(`${base}/${id}`)),
  create: (payload) => unwrap(apiClient.post(base, payload)),
  reply: (id, body) => unwrap(apiClient.post(`${base}/${id}/messages`, { body })),
  assign: (id, assigneeId) => unwrap(apiClient.put(`${base}/${id}/assignee`, { assigneeId })),
  status: (id, status) => unwrap(apiClient.put(`${base}/${id}/status`, { status })),
  reviewRefund: (id, approve, note = '') => unwrap(apiClient.post(`${base}/${id}/refund-review`, { approve, note })),
}

export default supportApi
