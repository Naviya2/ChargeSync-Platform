import apiClient, { unwrap } from '../client'

const base = '/admin/stations'

export const adminStationsApi = {
    getPending: () => unwrap(apiClient.get(`${base}/pending`)),
    getById: (id) => unwrap(apiClient.get(`${base}/${id}`)),
    approve: (id) => unwrap(apiClient.put(`${base}/${id}/approve`)),
    reject: (id, reason) => unwrap(apiClient.put(`${base}/${id}/reject`, { reason })),
}

export default adminStationsApi
