import { useMemo, useState } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { Link, useSearchParams } from 'react-router-dom'
import { ArrowLeft, RefreshCw, Search, Inbox, MessageSquare, Send, UserRound, Wallet, ChevronRight, AlertCircle, Check } from 'lucide-react'
import TicketAnalysis from '../components/TicketAnalysis'
import SupportWorkflow from '../components/SupportWorkflow'
import PageHeader from '../../../components/shared/PageHeader'
import { Button } from '../../../components/ui'
import supportApi from '../../../api/endpoints/support'
import { useAuthStore } from '../../../store/authStore'
import useDialogStore from '../../../store/dialogStore'
import './support-inbox.css'

const statuses = ['Open', 'InProgress', 'Resolved', 'Closed', 'Withdrawn']
const readable = value => value?.replace(/([a-z])([A-Z])/g, '$1 $2') ?? ''
const when = value => new Date(value).toLocaleString([], { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' })
const money = value => new Intl.NumberFormat('en-LK', { style: 'currency', currency: 'LKR' }).format(Number(value) || 0)
const initials = name => (name || 'Driver').split(' ').filter(Boolean).slice(0, 2).map(part => part[0]).join('').toUpperCase()

function StatusBadge({ status }) {
  return <span className={`si-status si-status-${status?.toLowerCase()}`}><span />{readable(status)}</span>
}

export default function SupportInboxPage() {
  const [searchParams] = useSearchParams()
  const client = useQueryClient()
  const user = useAuthStore(state => state.user)
  const [selectedId, setSelectedId] = useState(searchParams.get('ticket'))
  const [filter, setFilter] = useState('All')
  const [search, setSearch] = useState('')
  const [drafts, setDrafts] = useState({})
  const query = useQuery({ queryKey: ['support-tickets'], queryFn: () => supportApi.list(), refetchInterval: 10000 })
  const tickets = useMemo(() => query.data ?? [], [query.data])
  const visible = useMemo(() => tickets.filter(ticket => {
    const text = `${ticket.id} ${ticket.subject} ${ticket.driverName} ${ticket.category}`.toLowerCase()
    return (filter === 'All' || ticket.status === filter || (filter === 'Refunds' && ticket.refundStatus === 'PendingReview')) && text.includes(search.toLowerCase())
  }), [tickets, filter, search])
  const selected = visible.find(ticket => ticket.id === selectedId) ?? visible[0]
  const reply = drafts[selected?.id] ?? ''
  const setReply = value => setDrafts(old => ({ ...old, [selected.id]: value }))
  const mutation = useMutation({
    mutationFn: ({ run }) => run(),
    onMutate: async ({ ticketId, optimistic, clearReply, draft }) => {
      await client.cancelQueries({ queryKey: ['support-tickets'] })
      const previous = client.getQueryData(['support-tickets'])
      if (optimistic) client.setQueryData(['support-tickets'], (old = []) => old.map(item => item.id === ticketId ? optimistic(item) : item))
      if (clearReply) setDrafts(old => ({ ...old, [ticketId]: '' }))
      return { previous, draft, ticketId, clearReply }
    },
    onSuccess: ticket => {
      client.setQueryData(['support-tickets'], (old = []) => old.map(item => item.id === ticket.id ? ticket : item))
      client.invalidateQueries({ queryKey: ['support-workflow', ticket.id] })
    },
    onError: (_error, _variables, context) => {
      if (context?.previous) client.setQueryData(['support-tickets'], context.previous)
      if (context?.clearReply) setDrafts(old => ({ ...old, [context.ticketId]: context.draft }))
    },
  })
  const act = (run, optimistic, clearReply = false) => mutation.mutate({ ticketId: selected.id, run, optimistic, clearReply, draft: reply })
  const error = query.error ?? mutation.error
  const readOnly = selected && ['Closed', 'Withdrawn'].includes(selected.status)
  const counts = {
    All: tickets.length,
    Open: tickets.filter(ticket => ticket.status === 'Open').length,
    InProgress: tickets.filter(ticket => ticket.status === 'InProgress').length,
    Refunds: tickets.filter(ticket => ticket.refundStatus === 'PendingReview').length,
  }
  const reviewRefund = async approve => {
    const ticketId = selected.id
    const ok = await useDialogStore.getState().confirm({
      title: approve ? 'Approve refund' : 'Reject refund',
      message: approve ? `Approve and credit ${money(selected.requestedRefundAmount)} to this driver?` : 'Reject this refund request?',
      confirmLabel: approve ? 'Approve refund' : 'Reject refund', variant: approve ? 'success' : 'danger',
    })
    if (ok) mutation.mutate({ ticketId, run: () => supportApi.reviewRefund(ticketId, approve) })
  }

  return <div className="si-workspace">
    <PageHeader title="Support tickets" description="Manage driver conversations, review requests, and keep track of resolutions." actions={
      <><Link to="/dashboard" className="si-back"><ArrowLeft size={15} /> Dashboard</Link><Button variant="outline" onClick={() => query.refetch()} disabled={query.isFetching}><RefreshCw size={15} className={query.isFetching ? 'si-spin' : ''} /> Refresh</Button></>
    } />
    <div className="si-toolbar">
      <div className="si-tabs" role="group" aria-label="Ticket filters">
        {['All', 'Open', 'InProgress', 'Refunds'].map(value => <button key={value} type="button" aria-pressed={filter === value} onClick={() => setFilter(value)}>{value === 'All' ? 'All tickets' : value === 'Refunds' ? 'Refund reviews' : readable(value)}<span>{query.isLoading || !query.data ? '—' : counts[value]}</span></button>)}
      </div>
      <div className="si-tools"><label className="si-search"><Search size={16} /><input aria-label="Search tickets" placeholder="Search name, subject, or ID" value={search} onChange={event => setSearch(event.target.value)} /></label><select aria-label="Filter ticket status" value={filter} onChange={event => setFilter(event.target.value)}><option value="All">All statuses</option>{statuses.map(status => <option key={status} value={status}>{readable(status)}</option>)}<option value="Refunds">Refund reviews</option></select></div>
    </div>
    {error && <div role="alert" className="si-error"><AlertCircle size={17} /><span>{error.response?.data?.detail ?? (mutation.error ? 'Your change could not be saved. Please try again.' : 'Tickets could not be refreshed. Please try again.')}</span><button onClick={() => query.refetch()}>Retry</button></div>}
    {query.isLoading ? <div className="si-loading" role="status"><div /><div /><div /><p>Loading support tickets…</p></div> : query.data && <div className="si-grid">
      <section className="si-queue rounded-xl bg-surface-container-lowest shadow-sm" aria-label="Ticket queue">
        <div className="si-queue-heading"><h2>Inbox <span>{visible.length}</span></h2><span>Latest requests</span></div>
        <div className="si-queue-list">
          {!visible.length && <div className="si-empty"><Inbox size={28} /><h3>{search || filter !== 'All' ? 'No matching tickets' : 'No tickets yet'}</h3><p>{search || filter !== 'All' ? 'Try another search or change your filters.' : 'New driver requests will appear here.'}</p>{(search || filter !== 'All') && <button onClick={() => { setSearch(''); setFilter('All') }}>Clear filters</button>}</div>}
          {visible.map(ticket => <button key={ticket.id} type="button" disabled={mutation.isPending} onClick={() => setSelectedId(ticket.id)} aria-pressed={ticket.id === selected?.id} className="si-ticket">
            <div className="si-ticket-top"><span className="si-ticket-number">#{ticket.id.slice(0, 8)}</span><span className={`si-priority si-priority-${ticket.priority?.toLowerCase()}`}>{ticket.priority}</span></div>
            <h3>{ticket.subject}</h3><p className="si-preview">{ticket.messages?.at(-1)?.body || ticket.description}</p>
            <div className="si-ticket-bottom"><span className="si-person"><span className="si-small-avatar">{initials(ticket.driverName)}</span>{ticket.driverName}</span><span>{new Date(ticket.updatedAt || ticket.createdAt).toLocaleDateString([], { day: 'numeric', month: 'short' })}</span></div>
            <div className="si-ticket-tags"><StatusBadge status={ticket.status} /><span>{readable(ticket.category)}</span></div>
          </button>)}
        </div><div className="si-queue-footer">Updates automatically every 10 seconds</div>
      </section>

      {!selected ? <section className="si-conversation si-empty rounded-xl bg-surface-container-lowest shadow-sm"><MessageSquare size={32} /><h2>Select a conversation</h2><p>Choose a ticket from the inbox to view its messages and details.</p></section> : <>
        <section className="si-conversation rounded-xl bg-surface-container-lowest shadow-sm" aria-label="Ticket conversation">
          <div className="si-conversation-heading"><div className="si-conversation-meta"><span>#{selected.id.slice(0, 8)}</span><span>{readable(selected.category)}</span><StatusBadge status={selected.status} /></div><h2>{selected.subject}</h2><p><UserRound size={13} /> {selected.driverName}<span>·</span>Opened {when(selected.createdAt)}</p></div>
          <div className="si-thread">
            <details className="si-original" open={!selected.messages?.length}><summary>Original request <ChevronRight size={14} /></summary><p>{selected.description}</p></details>
            {!selected.messages?.length && <p className="si-thread-empty">No replies yet. The original request is shown above.</p>}
            {(selected.messages ?? []).map(message => message.isSystem ? <div key={message.id} className="si-system-message"><span>{message.body}</span><time dateTime={message.createdAt}>{when(message.createdAt)}</time></div> : <article key={message.id} className={`si-message ${message.authorRole === 'Driver' ? '' : 'si-message-staff'}`}><div className="si-message-meta"><span className="si-small-avatar">{initials(message.authorName)}</span><strong>{message.authorName}</strong><span>{message.authorRole === 'Driver' ? 'Driver' : 'Support'}</span><time dateTime={message.createdAt}>{when(message.createdAt)}</time></div><div className="si-message-body">{message.body}</div></article>)}
          </div>
          {readOnly ? <div className="si-readonly"><Check size={16} /> This ticket is {selected.status.toLowerCase()}. Replies are disabled.</div> : <form className="si-composer" onSubmit={event => {
            event.preventDefault()
            const body = reply.trim()
            if (body && !mutation.isPending) act(() => supportApi.reply(selected.id, body), ticket => ({ ...ticket, status: ticket.status === 'Open' ? 'InProgress' : ticket.status, messages: [...(ticket.messages ?? []), { id: `pending-${Date.now()}`, authorRole: user.role, authorName: user.name ?? user.fullName ?? 'Support', body, isSystem: false, createdAt: new Date().toISOString() }] }), true)
          }}><label htmlFor="support-reply">Reply to {selected.driverName}</label><textarea id="support-reply" value={reply} disabled={mutation.isPending} onChange={event => setReply(event.target.value)} maxLength={4000} rows={4} placeholder="Write a reply…" /><div className="si-composer-footer"><span>Visible to the driver <span>· {reply.length.toLocaleString()}/4,000</span></span><Button type="submit" disabled={mutation.isPending || !reply.trim()}><Send size={14} />{mutation.isPending ? 'Sending…' : 'Send reply'}</Button></div></form>}
        </section>

        <aside className="si-details" aria-label="Ticket details">
          <section className="si-detail-card rounded-xl bg-surface-container-lowest shadow-sm"><h3>Ticket details</h3><label htmlFor="support-status">Status</label><select id="support-status" value={selected.status} disabled={selected.status === 'Withdrawn' || mutation.isPending} onChange={event => { const status = event.target.value; act(() => supportApi.status(selected.id, status), ticket => ({ ...ticket, status })) }}>{statuses.map(status => <option key={status} value={status} disabled={status === 'Withdrawn' || (selected.refundStatus === 'PendingReview' && ['Resolved', 'Closed'].includes(status))}>{readable(status)}</option>)}</select>{selected.refundStatus === 'PendingReview' && <p className="si-notice">Review the pending refund before resolving this ticket.</p>}<dl><div><dt>Priority</dt><dd><span className={`si-priority si-priority-${selected.priority?.toLowerCase()}`}>{selected.priority}</span></dd></div><div><dt>Assigned to</dt><dd>{selected.assigneeName || 'Unassigned'}</dd></div><div><dt>Last updated</dt><dd>{when(selected.updatedAt || selected.createdAt)}</dd></div></dl><Button variant="outline" className="w-full" disabled={mutation.isPending || selected.assignedToUserId === user.id || selected.status === 'Withdrawn'} onClick={() => act(() => supportApi.assign(selected.id, user.id), ticket => ({ ...ticket, assignedToUserId: user.id, assigneeName: user.name ?? user.fullName ?? 'You' }))}>{selected.assignedToUserId === user.id ? <><Check size={14} /> Assigned to you</> : 'Assign to me'}</Button></section>
          <section className="si-detail-card rounded-xl bg-surface-container-lowest shadow-sm"><h3>Driver</h3><div className="si-driver"><span className="si-driver-avatar">{initials(selected.driverName)}</span><div><strong>{selected.driverName}</strong><p>{selected.driverEmail}</p></div></div><details className="si-record-ids"><summary>Reference IDs</summary><p>Ticket: {selected.id}</p>{selected.invoiceId && <p>Invoice: {selected.invoiceId}</p>}</details></section>
          {selected.refundStatus !== 'NotRequested' && <section className="si-detail-card si-refund rounded-xl bg-surface-container-lowest shadow-sm"><h3><Wallet size={16} /> Refund review</h3><strong className="si-refund-amount">{money(selected.requestedRefundAmount)}</strong><p className="si-refund-status">{readable(selected.refundStatus)}</p>{selected.refundStatus === 'PendingReview' && <div className="si-refund-actions"><Button disabled={mutation.isPending} onClick={() => reviewRefund(true)}>Approve</Button><Button variant="outline" disabled={mutation.isPending} onClick={() => reviewRefund(false)}>Reject</Button></div>}</section>}
          <details className="si-analysis rounded-xl bg-surface-container-lowest shadow-sm"><summary>Analysis &amp; validation <ChevronRight size={16} /></summary><SupportWorkflow key={`workflow-${selected.id}`} ticket={selected} onUseDraft={setReply} /></details>
          <details className="si-analysis rounded-xl bg-surface-container-lowest shadow-sm"><summary>Additional analysis <ChevronRight size={16} /></summary><TicketAnalysis key={selected.id} ticket={selected} onUseDraft={setReply} /></details>
        </aside>
      </>}
    </div>}
  </div>
}
