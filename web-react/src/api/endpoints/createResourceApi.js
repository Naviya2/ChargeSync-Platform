import apiClient, { unwrap } from '../client'

/**
 * Builds a standard REST resource API for a given base path.
 * Each endpoint module extends the returned object with resource-specific calls.
 *
 * @param {string} resourcePath - e.g. '/stations'
 */
export function createResourceApi(resourcePath) {
  return {
    /** @param {Record<string, unknown>} [params] */
    list: (params) => unwrap(apiClient.get(resourcePath, { params })),
    /** @param {string|number} id */
    get: (id) => unwrap(apiClient.get(`${resourcePath}/${id}`)),
    /** @param {unknown} payload */
    create: (payload) => unwrap(apiClient.post(resourcePath, payload)),
    /** @param {string|number} id @param {unknown} payload */
    update: (id, payload) => unwrap(apiClient.put(`${resourcePath}/${id}`, payload)),
    /** @param {string|number} id @param {unknown} payload */
    patch: (id, payload) => unwrap(apiClient.patch(`${resourcePath}/${id}`, payload)),
    /** @param {string|number} id */
    remove: (id) => unwrap(apiClient.delete(`${resourcePath}/${id}`)),
  }
}
