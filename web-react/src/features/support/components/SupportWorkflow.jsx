import { useState } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import agentWorkflowsApi from '../../../api/endpoints/agentWorkflows'
import { useAuthStore } from '../../../store/authStore'

const readable = (value) => value?.replace(/([a-z])([A-Z])/g, '$1 $2') ?? ''
const when = (value) => value ? new Date(value).toLocaleString() : '—'

export default function SupportWorkflow({ ticket, onUseDraft }) {
  const client = useQueryClient()
  const role = useAuthStore((state) => state.user?.role)
  const canReview = ['SupportManager', 'Admin'].includes(role)
  const [note, setNote] = useState('')
  const [editedDraft, setEditedDraft] = useState(null)
  const key = ['support-workflow', ticket.id]
  const query = useQuery({
    queryKey: key,
    queryFn: () => agentWorkflowsApi.forTicket(ticket.id),
    retry: false,
    refetchInterval: (query) => ['Running', 'PendingApproval'].includes(query.state.data?.workflow?.status) ? 5000 : false,
  })
  const run = query.data?.workflow
  const suggestion = run?.analysis?.suggestion
  const draft = editedDraft && editedDraft.revision === run?.revision ? editedDraft.text : suggestion?.draftReply ?? ''
  const mutation = useMutation({
    mutationFn: (decision) => decision === 'start'
      ? agentWorkflowsApi.startSupport(ticket.id)
      : agentWorkflowsApi.reviewSupport(run.id, decision, query.data.version, note.trim() || null),
    onSuccess: (result) => {
      client.setQueryData(key, result)
      client.invalidateQueries({ queryKey: ['support-tickets'] })
      setNote('')
      setEditedDraft(null)
    },
    onError: () => query.refetch(),
  })
  const pending = run?.status === 'PendingApproval'
  const canRevise = ['PendingApproval', 'Failed', 'RevisionRequested'].includes(run?.status)
  const adminRequired = run?.validationResults?.some((f) => f.code === 'METER_DISCREPANCY' && f.outcome === 'Review')
  const stale = run && new Date(ticket.updatedAt) > new Date(run.updatedAt)
  const closed = ['Closed', 'Withdrawn'].includes(ticket.status)
  return <section className="rounded-xl bg-surface-container-lowest p-5">
    <div className="flex items-center justify-between gap-2"><h3 className="font-semibold">Agent workflow</h3><button type="button" onClick={() => query.refetch()} className="rounded bg-surface-container p-2">Refresh</button></div>
    {query.isPending && <p role="status">Loading analysis status…</p>}
    {query.error && query.error.response?.status !== 404 && <p role="alert">Workflow unavailable. Ordinary support actions remain available.</p>}
    {!run && query.error?.response?.status === 404 && canReview && <button type="button" disabled={mutation.isPending || closed} onClick={() => mutation.mutate('start')} className="mt-3 rounded bg-primary p-2 text-on-primary">Analyze ticket</button>}
    {mutation.error && <p role="alert" className="mt-2 text-error">{mutation.error.response?.data?.detail ?? 'The action failed. Refresh and review the current records.'}</p>}
    {run && <div className="mt-3 space-y-3 text-sm">
      <p role="status" className={`rounded-lg p-2 font-semibold ${pending ? 'bg-orange-900/30 text-orange-200' : 'bg-surface-container'}`}>{run.status === 'PendingApproval' ? 'Pending Approval' : readable(run.status)} · Revision {run.revision}</p>
      <dl className="space-y-1 text-xs text-on-surface-variant">
        <div><dt className="inline font-semibold">Run: </dt><dd className="inline break-all">{run.id}</dd></div>
        <div><dt className="inline font-semibold">Last updated: </dt><dd className="inline">{when(run.updatedAt)}</dd></div>
        <div><dt className="inline font-semibold">Approval required: </dt><dd className="inline">{run.approvalRequired ? 'Yes' : 'No'}</dd></div>
        {run.decision && <div><dt className="inline font-semibold">Staff decision: </dt><dd className="inline">{run.decision}</dd></div>}
      </dl>
      {run.status === 'Running' && <p>{run.error
        ? 'The last analysis attempt failed. Retrying automatically; status refreshes every five seconds.'
        : 'Processing the ticket and linked records. Status refreshes automatically.'}</p>}
      {run.status === 'Completed' && !run.decision && <p>Analysis complete. Any requested refund still needs staff review.</p>}
      {run.action === 'Refund' && <p>Requested refund: LKR {Number(run.amount).toFixed(2)}</p>}
      {run.error && <p role="alert">{run.error}</p>}
      {stale && <p>The ticket changed after analysis. Request revision before approving.</p>}
      {!!run.validationResults?.length && <div><h4 className="font-semibold">Validation summary</h4><ul className="mt-1 list-disc space-y-1 pl-4">{run.validationResults.map((f) => <li key={f.code}><span className={f.outcome === 'Error' ? 'text-error' : 'font-medium'}>{f.outcome}:</span> {f.message}</li>)}</ul></div>}
      {suggestion && <>
        <p>{suggestion.category} · {suggestion.priority}</p><p>{suggestion.explanation}</p>
        <label className="block">Suggested reply — review before sending<textarea aria-label="Workflow suggested reply" rows={5} maxLength={4000} value={draft} onChange={(event) => setEditedDraft({ revision: run.revision, text: event.target.value })} className="mt-1 w-full rounded bg-surface-container p-2" /></label>
        <button type="button" disabled={!draft.trim() || closed} onClick={() => onUseDraft(draft)} className="rounded bg-surface-container p-2 disabled:opacity-50">Use reviewed draft in reply</button>
      </>}
      {adminRequired && pending && <p>Administrator approval required for this meter discrepancy.</p>}
      {canReview && canRevise && !closed && <>
        <label className="block">Review or revision note<textarea aria-label="Workflow review note" rows={2} maxLength={1000} value={note} onChange={(event) => setNote(event.target.value)} className="mt-1 w-full rounded bg-surface-container p-2" /></label>
        <div className="flex flex-wrap gap-2">
          {pending && <>
            <button type="button" disabled={mutation.isPending || query.isError || stale || (adminRequired && role !== 'Admin')} onClick={() => window.confirm(run.action === 'Refund' ? 'Approve this LKR refund and apply wallet, invoice and loyalty changes?' : 'Approve the reviewed findings?') && mutation.mutate('approve')} className="rounded bg-primary p-2 text-on-primary disabled:opacity-50">Approve</button>
            <button type="button" disabled={mutation.isPending || query.isError || stale} onClick={() => mutation.mutate('reject')} className="rounded bg-error-container p-2 text-on-error-container disabled:opacity-50">Reject</button>
          </>}
          <button type="button" disabled={mutation.isPending || query.isError || !note.trim()} onClick={() => mutation.mutate('revise')} className="rounded bg-surface-container p-2 disabled:opacity-50">Request Revision</button>
        </div>
      </>}
      {!!run.analysis?.completedSteps?.length && <details>
        <summary className="cursor-pointer font-semibold">Tools and execution summary</summary>
        {!!run.analysis.plan?.length && <><h4 className="mt-2 font-medium">Planned checks</h4><ul className="list-disc pl-4">{run.analysis.plan.map((step, index) => <li key={index}>{step.agent}: {step.tool.replaceAll('_', ' ')}</li>)}</ul></>}
        <h4 className="mt-2 font-medium">Completed steps</h4>
        <ol className="list-decimal space-y-2 pl-4">{run.analysis.completedSteps.map((step, index) => <li key={index}><p>{step.agent} · {step.step}{step.tool && ` · ${step.tool.replaceAll('_', ' ')}`}</p><p>{step.outcome}</p><p className="text-xs text-on-surface-variant">{when(step.startedAt)} → {when(step.completedAt)}</p></li>)}</ol>
        {!!run.analysis.toolResults?.length && <><h4 className="mt-2 font-medium">Tool findings</h4><ul className="space-y-1">{run.analysis.toolResults.map((result, index) => <li key={index}>{result.tool.replaceAll('_', ' ')}: {result.outcome}</li>)}</ul></>}
      </details>}
      {!!run.audit?.length && <details><summary>Execution history</summary><ul className="mt-2 space-y-1">{run.audit.map((entry, index) => <li key={index}>{new Date(entry.at).toLocaleString()} · Revision {entry.revision} · {readable(entry.event)}: {entry.detail}</li>)}</ul></details>}
    </div>}
  </section>
}
