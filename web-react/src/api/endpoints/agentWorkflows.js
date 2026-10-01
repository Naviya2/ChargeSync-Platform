import apiClient, { unwrap } from '../client'
import { createResourceApi } from './createResourceApi'

const base = '/agent-workflows'

export const agentWorkflowsApi = {
  ...createResourceApi(base),
  forTicket: (ticketId) => unwrap(apiClient.get(`${base}/support-ticket/${ticketId}`)),
  startSupport: (ticketId) => unwrap(apiClient.post(`${base}/support-ticket/${ticketId}`)),
  reviewSupport: (id, decision, version, note) => {
    if (!['approve', 'reject', 'revise'].includes(decision)) throw new Error('Invalid workflow decision')
    return unwrap(apiClient.post(`${base}/${id}/${decision}`, { version, note }))
  },
  /** @param {string|number} id @param {Record<string, unknown>} [input] */
  trigger: (id, input) => unwrap(apiClient.post(`${base}/${id}/trigger`, input)),
  /** @param {string|number} id */
  runs: (id) => unwrap(apiClient.get(`${base}/${id}/runs`)),
  /** @param {string|number} runId */
  runStatus: (runId) => unwrap(apiClient.get(`${base}/runs/${runId}`)),
}

export default agentWorkflowsApi
