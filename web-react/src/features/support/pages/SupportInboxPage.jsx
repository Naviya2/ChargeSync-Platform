import { useMemo, useState } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import supportApi from '../../../api/endpoints/support'
import { useAuthStore } from '../../../store/authStore'

const statuses = ['Open', 'InProgress', 'Resolved', 'Closed']
const readable = (value) => value?.replace(/([a-z])([A-Z])/g, '$1 $2') ?? ''
const when = (value) => new Date(value).toLocaleString()
const tone = { Urgent: 'bg-error-container text-on-error-container', High: 'bg-orange-900/30 text-orange-200', Medium: 'bg-surface-container-high', Low: 'bg-surface-container' }

export default function SupportInboxPage() {
  const client = useQueryClient()
  const user = useAuthStore((state) => state.user)
  const [selectedId, setSelectedId] = useState(null)
  const [filter, setFilter] = useState('All')
  const [search, setSearch] = useState('')
  const [reply, setReply] = useState('')
  const query = useQuery({ queryKey: ['support-tickets'], queryFn: () => supportApi.list() })
  const tickets = useMemo(() => query.data ?? [], [query.data])
  const effectiveSelectedId = selectedId ?? tickets[0]?.id
  const selected = tickets.find((ticket) => ticket.id === effectiveSelectedId)
  const visible = useMemo(() => tickets.filter((ticket) => {
    const text = `${ticket.id} ${ticket.subject} ${ticket.driverName} ${ticket.category}`.toLowerCase()
    return (filter === 'All' || ticket.status === filter) && text.includes(search.toLowerCase())
  }), [tickets, filter, search])
  const mutation = useMutation({
    mutationFn: ({ run }) => run(),
    onMutate: async ({ optimistic, clearReply }) => {
      await client.cancelQueries({ queryKey: ['support-tickets'] })
      const previous = client.getQueryData(['support-tickets'])
      const previousReply = reply
      if (optimistic) client.setQueryData(['support-tickets'], (old = []) => old.map((item) => item.id === effectiveSelectedId ? optimistic(item) : item))
      if (clearReply) setReply('')
      return { previous, previousReply, clearReply }
    },
    onSuccess: (ticket) => {
      client.setQueryData(['support-tickets'], (old = []) => old.map((item) => item.id === ticket.id ? ticket : item))
    },
    onError: (_error, _variables, context) => {
      if (context?.previous) client.setQueryData(['support-tickets'], context.previous)
      if (context?.clearReply) setReply(context.previousReply)
    },
  })
  const act = (run, optimistic, clearReply = false) => mutation.mutate({ run, optimistic, clearReply })
  const error = query.error ?? mutation.error

  return <div className="flex flex-col gap-space-lg">
    <header className="rounded-xl bg-surface-container-lowest p-space-lg shadow-sm">
      <div className="flex flex-wrap items-center justify-between gap-space-md">
        <div><p className="text-xs uppercase tracking-wider text-on-surface-variant">Support Console</p><h1 className="text-2xl font-bold">Ticket queue</h1></div>
        <div className="flex gap-2"><span className="rounded-full bg-primary-fixed/30 px-4 py-2">{tickets.filter((t) => t.status === 'Open').length} open</span><button type="button" onClick={() => query.refetch()} className="rounded-lg bg-surface-container px-4 py-2">Refresh</button></div>
      </div>
      <div className="mt-4 flex flex-wrap gap-2"><input value={search} onChange={(event) => setSearch(event.target.value)} placeholder="Search tickets" className="min-w-64 flex-1 rounded-lg bg-surface-container-low px-4 py-2" /><select value={filter} onChange={(event) => setFilter(event.target.value)} className="rounded-lg bg-surface-container-low px-4 py-2"><option>All</option>{[...statuses, 'Withdrawn'].map((status) => <option key={status}>{status}</option>)}</select></div>
      {error && <p role="alert" className="mt-2 text-error">{error.response?.data?.detail ?? 'Support request failed. Refresh and try again.'}</p>}
    </header>

    {query.isLoading ? <p className="p-8">Loading tickets…</p> : <div className="grid grid-cols-1 gap-space-lg lg:grid-cols-12">
      <section className="max-h-[760px] overflow-y-auto rounded-xl bg-surface-container-lowest lg:col-span-4">
        {!visible.length && <p className="p-8 text-on-surface-variant">No matching tickets.</p>}
        {visible.map((ticket) => <button key={ticket.id} type="button" onClick={() => setSelectedId(ticket.id)} className={`w-full border-b border-surface-container p-4 text-left ${ticket.id === effectiveSelectedId ? 'bg-primary/10' : 'hover:bg-surface-container-low'}`}>
          <div className="flex justify-between"><span className="text-xs text-primary">#{ticket.id.slice(0, 8)}</span><span className={`rounded px-2 py-1 text-xs ${tone[ticket.priority]}`}>{ticket.priority}</span></div>
          <h3 className="mt-2 font-semibold">{ticket.subject}</h3><p className="line-clamp-2 text-sm text-on-surface-variant">{ticket.description}</p><div className="mt-2 flex justify-between text-xs text-on-surface-variant"><span>{ticket.driverName}</span><span>{readable(ticket.status)}</span></div>
        </button>)}
      </section>

      {!selected ? <section className="p-8 lg:col-span-8">Select a ticket.</section> : <>
        <main className="flex min-h-[620px] flex-col rounded-xl bg-surface-container-lowest lg:col-span-5">
          <div className="border-b border-surface-container p-5"><div className="flex gap-2 text-xs"><span className="rounded bg-surface-container-high px-2 py-1">{selected.category}</span><span className="rounded bg-surface-container-high px-2 py-1">{readable(selected.status)}</span></div><h2 className="mt-2 text-xl font-bold">{selected.subject}</h2><p className="text-sm text-on-surface-variant">Opened {when(selected.createdAt)} by {selected.driverName}</p></div>
          <div className="flex flex-1 flex-col gap-4 overflow-y-auto bg-surface-container-low/40 p-5">{selected.messages.map((message) => <div key={message.id} className={message.isSystem ? 'self-center rounded-full bg-surface-container-high px-4 py-2 text-xs' : message.authorRole === 'Driver' ? 'max-w-[85%] rounded-xl bg-surface-container-lowest p-4' : 'max-w-[85%] self-end rounded-xl bg-primary p-4 text-on-primary'}><div className="mb-1 text-xs opacity-75">{message.authorName} · {when(message.createdAt)}</div><p>{message.body}</p></div>)}</div>
          {!['Closed', 'Withdrawn'].includes(selected.status) && <form onSubmit={(event) => { event.preventDefault(); const body = reply.trim(); if (body) act(() => supportApi.reply(selected.id, body), (ticket) => ({ ...ticket, status: ticket.status === 'Open' ? 'InProgress' : ticket.status, messages: [...ticket.messages, { id: `pending-${Date.now()}`, authorRole: user.role, authorName: user.name ?? user.fullName ?? 'Support', body, isSystem: false, createdAt: new Date().toISOString() }] }), true) }} className="flex gap-2 p-4"><textarea value={reply} onChange={(event) => setReply(event.target.value)} maxLength={4000} rows={2} placeholder={`Reply to ${selected.driverName}`} className="flex-1 rounded-lg bg-surface-container-low p-3" /><button disabled={mutation.isPending || !reply.trim()} className="rounded-lg bg-primary px-5 text-on-primary disabled:opacity-50">{mutation.isPending ? 'Sending…' : 'Send'}</button></form>}
        </main>

        <aside className="flex flex-col gap-4 lg:col-span-3">
          <section className="rounded-xl bg-surface-container-lowest p-5"><h3 className="font-semibold">Workflow</h3><label className="mt-3 block text-xs text-on-surface-variant">Status</label><select value={selected.status === 'Withdrawn' ? 'Open' : selected.status} disabled={selected.status === 'Withdrawn' || mutation.isPending} onChange={(event) => { const status = event.target.value; act(() => supportApi.status(selected.id, status), (ticket) => ({ ...ticket, status })) }} className="mt-1 w-full rounded-lg bg-surface-container p-2">{statuses.map((status) => <option key={status} value={status} disabled={selected.refundStatus === 'PendingReview' && ['Resolved', 'Closed'].includes(status)}>{readable(status)}</option>)}</select>{selected.refundStatus === 'PendingReview' && <p className="mt-2 text-xs text-error">Approve or reject the pending refund before resolving this ticket.</p>}<button disabled={mutation.isPending || selected.assignedToUserId === user.id || selected.status === 'Withdrawn'} onClick={() => act(() => supportApi.assign(selected.id, user.id), (ticket) => ({ ...ticket, assignedToUserId: user.id, assigneeName: user.name ?? user.fullName ?? 'You' }))} className="mt-3 w-full rounded-lg bg-surface-container p-2 disabled:opacity-50">{selected.assignedToUserId === user.id ? 'Assigned to you' : mutation.isPending ? 'Saving…' : 'Assign to me'}</button>{selected.assigneeName && <p className="mt-2 text-xs text-on-surface-variant">Owner: {selected.assigneeName}</p>}</section>
          <section className="rounded-xl bg-surface-container-lowest p-5"><h3 className="font-semibold">Driver</h3><p>{selected.driverName}</p><p className="text-sm text-on-surface-variant">{selected.driverEmail}</p><p className="mt-3 break-all text-xs">Ticket: {selected.id}</p></section>
          {selected.refundStatus !== 'NotRequested' && <section className="rounded-xl bg-surface-container-lowest p-5"><h3 className="font-semibold">Refund review</h3><p className="mt-2 text-xl">LKR {Number(selected.requestedRefundAmount).toFixed(2)}</p><p>{readable(selected.refundStatus)}</p>{selected.invoiceId && <p className="mt-2 break-all text-xs">Invoice: {selected.invoiceId}</p>}{selected.refundStatus === 'PendingReview' && <div className="mt-3 grid grid-cols-2 gap-2"><button disabled={mutation.isPending} onClick={() => window.confirm('Approve and credit this refund once?') && act(() => supportApi.reviewRefund(selected.id, true))} className="rounded-lg bg-primary p-2 text-on-primary">Approve</button><button disabled={mutation.isPending} onClick={() => window.confirm('Reject this refund?') && act(() => supportApi.reviewRefund(selected.id, false))} className="rounded-lg bg-error-container p-2 text-on-error-container">Reject</button></div>}</section>}
        </aside>
      </>}
    </div>}
  </div>
}
