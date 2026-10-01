import { useState } from 'react'
import { useMutation } from '@tanstack/react-query'
import supportApi from '../../../api/endpoints/support'

export default function TicketAnalysis({ ticket, onUseDraft }) {
  const [draft, setDraft] = useState('')
  const analysis = useMutation({
    mutationFn: () => supportApi.analyze(ticket.id),
    onSuccess: (result) => setDraft(result.suggestion.draftReply),
  })
  const result = analysis.data
  return <section className="rounded-xl bg-surface-container-lowest p-5">
    <h3 className="font-semibold">Validation &amp; Support Agent</h3>
    <button type="button" disabled={analysis.isPending} onClick={() => analysis.mutate()} className="mt-3 rounded-lg bg-primary p-2 text-on-primary disabled:opacity-50">{analysis.isPending ? 'Analyzing…' : 'Analyze ticket'}</button>
    {analysis.error && <p role="alert">Analysis unavailable. You can continue replying and managing this ticket.</p>}
    {result && <div className="mt-3 space-y-3 text-sm">
      {!result.aiAvailable && <p role="status">AI unavailable — showing backend findings and a standard draft.</p>}
      <p>Suggested category: {result.suggestion.category} · Priority: {result.suggestion.priority}</p>
      <p>{result.suggestion.explanation}</p>
      <ul className="list-disc pl-4">{result.findings.map((finding, index) => <li key={index}>{finding}</li>)}</ul>
      <p className="font-semibold">{result.approvalStatus}</p>
      <label className="block">Suggested reply — review before sending<textarea aria-label="Suggested reply" className="mt-1 w-full rounded bg-surface-container p-2" rows={6} maxLength={4000} value={draft} onChange={(event) => setDraft(event.target.value)} /></label>
      <button type="button" disabled={!draft.trim() || ['Closed', 'Withdrawn'].includes(ticket.status)} onClick={() => onUseDraft(draft)} className="rounded bg-surface-container p-2 disabled:opacity-50">Use reviewed draft in reply</button>
      <p>Suggestions do not change records or send messages. Reanalyze after records change.</p>
    </div>}
  </section>
}
