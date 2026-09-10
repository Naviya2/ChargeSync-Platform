/**
 * Turns an axios error from the ChargeSync API into a human-readable message.
 *
 * The backend replies with RFC 7807 problem-details:
 *   { title, status, detail?, errors?: { Field: string[] } }
 *
 * @param {unknown} error
 * @param {string} [fallback]
 * @returns {string}
 */
export function extractApiError(error, fallback = 'Something went wrong. Please try again.') {
  const response = error?.response

  if (!response) {
    // No HTTP response — network failure, CORS, server down, timeout.
    return 'Unable to reach the server. Check that the API is running and try again.'
  }

  const data = response.data

  if (data && typeof data === 'object') {
    // Prefer the specific detail, then the first field error, then the title.
    if (typeof data.detail === 'string' && data.detail.trim()) return data.detail

    if (data.errors && typeof data.errors === 'object') {
      const firstList = Object.values(data.errors).find((list) => Array.isArray(list) && list.length)
      if (firstList) return firstList[0]
    }

    if (typeof data.title === 'string' && data.title.trim()) return data.title
  }

  if (typeof data === 'string' && data.trim()) return data

  return fallback
}
