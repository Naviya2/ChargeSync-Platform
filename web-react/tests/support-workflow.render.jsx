import assert from 'node:assert/strict'
import { renderToStaticMarkup } from 'react-dom/server'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import SupportWorkflow from '../src/features/support/components/SupportWorkflow'
import { useAuthStore } from '../src/store/authStore'
import apiClient from '../src/api/client'
import workflows from '../src/api/endpoints/agentWorkflows'

export async function verifySupportWorkflow() {
  const ticket = { id: 'ticket-1', status: 'Open', updatedAt: '2026-10-01T08:00:00Z' }
  const workflow = {
    id: 'run-1', status: 'PendingApproval', revision: 1, approvalRequired: true,
    updatedAt: '2026-10-01T09:00:00Z', action: 'Refund', amount: 20,
    validationResults: [{ code: 'INVOICE_TOTALS', outcome: 'Pass', message: 'Invoice totals verified.' }],
    analysis: {
      suggestion: { category: 'Payment', priority: 'High', explanation: 'Staff review needed.', draftReply: 'We will review your invoice.' },
      plan: [{ agent: 'ValidationSupportAgent', tool: 'get_invoice' }],
      completedSteps: [{ agent: 'ValidationSupportAgent', step: 'Load invoice', tool: 'get_invoice', outcome: 'Authorized record loaded.', startedAt: '2026-10-01T08:01:00Z', completedAt: '2026-10-01T08:01:01Z' }],
      toolResults: [{ tool: 'get_invoice', outcome: 'Paid invoice found.' }],
    },
    audit: [{ at: '2026-10-01T09:00:00Z', revision: 1, event: 'AnalysisCompleted', detail: 'Awaiting staff approval.' }],
  }
  const initialSnapshot = useAuthStore.getInitialState()
  const previousInitialUser = initialSnapshot.user
  const previousUser = useAuthStore.getState().user
  const previousAdapter = apiClient.defaults.adapter
  // React server rendering reads the store's initial snapshot.
  function render(role, record = workflow) {
    initialSnapshot.user = { id: 'staff-1', role }
    useAuthStore.setState({ user: { id: 'staff-1', role } })
    const client = new QueryClient({ defaultOptions: { queries: { retry: false, staleTime: Infinity } } })
    if (record) client.setQueryData(['support-workflow', ticket.id], { workflow: record, version: 'version-1' })
    try {
      return renderToStaticMarkup(<QueryClientProvider client={client}><SupportWorkflow ticket={ticket} onUseDraft={() => {}} /></QueryClientProvider>)
    } finally { client.clear() }
  }
  try {
    assert.ok(render('Admin', null).includes('Loading analysis status'))
    const manager = render('SupportManager')
    for (const text of ['Pending Approval', 'run-1', 'Validation summary', 'Invoice totals verified.', 'Tools and execution summary', 'Paid invoice found.', 'Execution history', 'Approve', 'Reject', 'Request Revision']) assert.ok(manager.includes(text), text)
    assert.match(manager, /<textarea[^>]*>We will review your invoice\.<\/textarea>/)
    assert.doesNotMatch(render('Driver'), />Approve<|>Reject<|>Request Revision</)
    const flagged = { ...workflow, validationResults: [{ code: 'METER_DISCREPANCY', outcome: 'Review', message: 'Meter difference exceeds 15%.' }] }
    assert.match(render('SupportManager', flagged), /<button[^>]*disabled=""[^>]*>Approve<\/button>/)
    assert.doesNotMatch(render('Admin', flagged), /<button[^>]*disabled=""[^>]*>Approve<\/button>/)
    assert.match(render('Admin', { ...workflow, status: 'Completed', decision: null }), /Analysis complete/)
    const failed = render('Admin', { ...workflow, status: 'Failed', analysis: null, error: 'Analysis unavailable.' })
    assert.ok(failed.includes('Request Revision') && failed.includes('Analysis unavailable.'))
    const retrying = render('Admin', { ...workflow, status: 'Running', revision: 2, analysis: null, error: 'Agent unavailable.' })
    assert.ok(retrying.includes('Retrying automatically'))
    assert.ok(retrying.includes('Revision 1') && retrying.includes('Analysis Completed'))
    const requests = []
    apiClient.defaults.adapter = async (config) => {
      requests.push({ url: config.url, method: config.method, data: config.data })
      return { status: 200, statusText: 'OK', headers: {}, config, data: { workflow, version: 'version-1' } }
    }
    await workflows.forTicket(ticket.id)
    for (const action of ['approve', 'reject', 'revise']) await workflows.reviewSupport('run-1', action, 'version-1', 'Checked records')
    assert.equal(requests[0].url, '/agent-workflows/support-ticket/ticket-1')
    for (const [index, action] of ['approve', 'reject', 'revise'].entries()) {
      assert.equal(requests[index + 1].url, `/agent-workflows/run-1/${action}`)
      assert.deepEqual(JSON.parse(requests[index + 1].data), { version: 'version-1', note: 'Checked records' })
    }
    assert.throws(() => workflows.reviewSupport('run-1', 'credit-wallet', 'version-1', null))
    console.log('PASS: workflow rendering, roles, administrator gate, failure recovery, editable draft and ASP.NET review request contracts')
  } finally {
    apiClient.defaults.adapter = previousAdapter
    initialSnapshot.user = previousInitialUser
    useAuthStore.setState({ user: previousUser })
  }
}
