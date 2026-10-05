import { useState } from 'react'
import { Link } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import { ArrowUpRight, ArrowRight, RefreshCw, Search, Inbox, Clock3, Wallet, CheckCircle2, AlertCircle, ChevronRight } from 'lucide-react'
import supportApi from '../../../api/endpoints/support'
import { useAuthStore } from '../../../store/authStore'
import PageHeader from '../../../components/shared/PageHeader'
import { Button, Card } from '../../../components/ui'
import './support-dashboard.css'

const active = ticket => ['Open', 'InProgress'].includes(ticket.status)
const priority = { Urgent: 0, High: 1, Medium: 2, Low: 3 }
const ticketUrl = ticket => `/support?ticket=${encodeURIComponent(ticket.id)}`
const money = value => new Intl.NumberFormat('en-LK', { style: 'currency', currency: 'LKR', maximumFractionDigits: 0 }).format(value)
const readable = value => value?.replace(/([a-z])([A-Z])/g, '$1 $2') || 'Unknown'
const dateLabel = value => {
  const date = new Date(value)
  return Number.isNaN(date.getTime()) ? 'Date unavailable' : date.toLocaleDateString('en-GB', { day: 'numeric', month: 'short' })
}

function Metric({ icon: Icon, label, value, detail, accent }) {
  return <Card className={`sd-metric ${accent ? 'sd-metric-accent' : ''}`}>
    <div className="sd-metric-top"><span>{label}</span><Icon size={18} aria-hidden="true" /></div>
    <strong>{value}</strong><p>{detail}</p>
  </Card>
}

export default function SupportManagerDashboardPage() {
  const user = useAuthStore(state => state.user)
  const [period, setPeriod] = useState(7)
  const [view, setView] = useState('Priority')
  const [search, setSearch] = useState('')
  const query = useQuery({ queryKey: ['support-tickets'], queryFn: () => supportApi.list(), refetchInterval: 30000 })
  const tickets = query.data ?? []
  const now = new Date()
  const open = tickets.filter(active)
  const urgent = open.filter(t => ['Urgent', 'High'].includes(t.priority))
  const refunds = tickets.filter(t => t.refundStatus === 'PendingReview' && t.status !== 'Withdrawn')
  const mine = open.filter(t => t.assignedToUserId === user?.id)
  const unassigned = open.filter(t => !t.assignedToUserId)
  const queue = (view === 'My queue' ? mine : view === 'Unassigned' ? unassigned : open)
    .filter(t => `${t.subject} ${t.driverName} ${t.id}`.toLowerCase().includes(search.toLowerCase()))
    .sort((a, b) => (priority[a.priority] ?? 4) - (priority[b.priority] ?? 4) || new Date(a.createdAt) - new Date(b.createdAt))
  const days = Array.from({ length: period }, (_, index) => {
    const day = new Date(now.getFullYear(), now.getMonth(), now.getDate() - period + index + 1)
    return { day, count: tickets.filter(t => new Date(t.createdAt).toDateString() === day.toDateString()).length }
  })
  const received = days.reduce((sum, day) => sum + day.count, 0)
  const maximum = Math.max(1, ...days.map(day => day.count))
  const categories = Object.entries(open.reduce((counts, ticket) => {
    counts[ticket.category || 'Other'] = (counts[ticket.category || 'Other'] || 0) + 1
    return counts
  }, {})).sort((a, b) => b[1] - a[1])
  const recent = [...tickets].sort((a, b) => new Date(b.updatedAt || b.createdAt) - new Date(a.updatedAt || a.createdAt)).slice(0, 4)
  const firstName = (user?.fullName || user?.name || 'there').split(' ')[0]

  return <div className="sd-dashboard">
    <PageHeader
      title="Support Dashboard"
      description={`Welcome back, ${firstName}. Manage tickets, review refunds, and monitor customer support.`}
      actions={<>
        <Button variant="outline" onClick={() => query.refetch()} disabled={query.isFetching} aria-label="Refresh dashboard"><RefreshCw size={16} className={query.isFetching ? 'sd-spin' : ''} /> Refresh</Button>
        <Link className="sd-primary-button" to="/support">Open support workspace <ArrowUpRight size={16} /></Link>
      </>}
    />

    {query.isError && <div className="sd-error" role="alert"><AlertCircle size={20} /><div><strong>We couldn’t refresh your tickets.</strong><p>{query.data ? 'Showing the last available data. Try refreshing again.' : 'Check your connection and try again.'}</p></div><button onClick={() => query.refetch()}>Try again</button></div>}
    {query.isLoading ? <div className="sd-loading" role="status"><div className="sd-skeleton" /><div className="sd-skeleton" /><div className="sd-skeleton" /><div className="sd-skeleton" /><p>Loading your support overview…</p></div> : query.data && <>
      <section className="sd-hero"><div className="sd-hero-copy"><span className="sd-eyebrow">PRIORITY OVERVIEW</span><h2>{urgent.length ? `${urgent.length} ${urgent.length === 1 ? 'conversation needs' : 'conversations need'} your care.` : 'Ready for the next conversation.'}</h2><p>{urgent.length ? 'High-priority conversations need a human touch. Start with the oldest, and help a driver get back on the road.' : 'Your high-priority queue is clear. Take a moment to review open conversations and follow up where it matters.'}</p><Link to={urgent[0] ? ticketUrl([...urgent].sort((a, b) => new Date(a.createdAt) - new Date(b.createdAt))[0]) : '/support'}>{urgent.length ? 'Review priority tickets' : 'Explore the inbox'} <ArrowRight size={16} /></Link></div></section>
      <section className="sd-metrics" aria-label="Support metrics"><Metric icon={Inbox} label="Active conversations" value={open.length} detail={`${tickets.filter(t => t.status === 'Open').length} open · ${tickets.filter(t => t.status === 'InProgress').length} in progress`} /><Metric icon={AlertCircle} label="Needs attention" value={urgent.length} detail="Urgent & high-priority active tickets" accent /><Metric icon={Clock3} label="Assigned to you" value={mine.length} detail={`${unassigned.length} active tickets still unassigned`} /><Metric icon={Wallet} label="Refunds awaiting review" value={refunds.length} detail={`${money(refunds.reduce((sum, t) => sum + (Number(t.requestedRefundAmount) || 0), 0))} requested`} /></section>

      <div className="sd-main-grid"><section className="rounded-xl bg-surface-container-lowest shadow-sm sd-panel sd-queue"><div className="sd-section-heading"><div><span className="sd-eyebrow">TICKET QUEUE</span><h2>Your next conversations</h2></div><Link to="/support" aria-label="View all tickets"><ArrowUpRight size={21} /></Link></div><div className="sd-queue-controls"><div className="sd-tabs" role="group" aria-label="Ticket queue filter">{['Priority', 'My queue', 'Unassigned'].map(tab => <button key={tab} aria-pressed={view === tab} onClick={() => setView(tab)} className={view === tab ? 'sd-tab-active' : ''}>{tab}</button>)}</div><label className="sd-search"><Search size={15} /><input aria-label="Search dashboard tickets" placeholder="Find a conversation" value={search} onChange={event => setSearch(event.target.value)} /></label></div><div className="sd-ticket-list">{queue.slice(0, 5).map(ticket => <Link className="sd-ticket" key={ticket.id} to={ticketUrl(ticket)}><span className="sd-avatar">{(ticket.driverName || 'D').slice(0, 1).toUpperCase()}</span><div className="sd-ticket-copy"><div><span className={`sd-priority sd-priority-${ticket.priority?.toLowerCase()}`}>{ticket.priority}</span><span className="sd-ticket-id">#{ticket.id.slice(0, 8)}</span></div><h3>{ticket.subject}</h3><p>{ticket.driverName || 'Driver'} <span>·</span> {readable(ticket.category)} <span>·</span> {dateLabel(ticket.createdAt)}</p></div><ChevronRight size={17} /></Link>)}{!queue.length && <div className="sd-empty"><CheckCircle2 size={29} /><h3>{search ? 'No conversations found' : 'A clear queue. A fresh start.'}</h3><p>{search ? 'Try a different name, subject, or ticket ID.' : 'Tickets will appear here when they need your attention.'}</p></div>}</div><div className="sd-panel-footer"><span>{queue.length ? `Showing ${Math.min(5, queue.length)} of ${queue.length} active conversations` : 'You’re up to date'}</span><Link to="/support">View inbox <ArrowRight size={14} /></Link></div></section>
      <aside className="sd-right-column"><section className="rounded-xl bg-surface-container-lowest shadow-sm sd-panel sd-refund-panel"><div className="sd-section-heading"><span className="sd-eyebrow">REFUND MANAGEMENT</span><Wallet size={19} /></div><h2>Pending refund requests</h2><strong className="sd-refund-total">{money(refunds.reduce((sum, t) => sum + (Number(t.requestedRefundAmount) || 0), 0))}</strong><p>Requested across {refunds.length} pending refund {refunds.length === 1 ? 'review' : 'reviews'}.</p>{refunds.length ? <Link className="sd-secondary-button" to={ticketUrl(refunds[0])}>Review a refund <ArrowUpRight size={16} /></Link> : <span className="sd-all-clear"><CheckCircle2 size={15} /> No refunds awaiting review</span>}<small>Refunds are reviewed in the support workspace. Administrator approval may be required.</small></section><section className="rounded-xl bg-surface-container-lowest shadow-sm sd-panel sd-categories"><div className="sd-section-heading"><h2>Ticket categories</h2><span className="sd-mini-label">ACTIVE</span></div>{categories.length ? categories.slice(0, 5).map(([category, count]) => <div className="sd-category" key={category}><div><span>{readable(category)}</span><strong>{count}</strong></div><div className="sd-track"><span style={{ width: `${count / open.length * 100}%` }} /></div></div>) : <p className="sd-muted">No active tickets to categorize.</p>}</section></aside></div>

      <div className="sd-bottom-grid"><section className="rounded-xl bg-surface-container-lowest shadow-sm sd-panel sd-trend"><div className="sd-section-heading"><div><span className="sd-eyebrow">INCOMING CONVERSATIONS</span><h2>Ticket activity</h2></div><select aria-label="Ticket activity period" value={period} onChange={event => setPeriod(Number(event.target.value))}><option value={7}>Last 7 days</option><option value={30}>Last 30 days</option></select></div><div className="sd-trend-summary"><strong>{received}</strong><span>tickets received in the last {period} calendar days</span></div><div className="sd-chart" role="img" aria-label={`Daily ticket arrivals: ${days.map(({ day, count }) => `${dateLabel(day)}: ${count}`).join(', ')}`}>{days.map(({ day, count }, index) => <div className="sd-bar-column" key={day.toISOString()}><div className="sd-bar-space"><span className="sd-bar" title={`${dateLabel(day)}: ${count} tickets`} style={{ height: `${count / maximum * 100}%`, minHeight: count ? '5px' : '0' }} /></div><span>{period === 7 || index % 5 === 0 || index === period - 1 ? day.getDate() : ''}</span></div>)}</div><p className="sd-chart-caption">Daily arrivals · {dateLabel(days[0].day)} – {dateLabel(now)} · local time</p></section><section className="rounded-xl bg-surface-container-lowest shadow-sm sd-panel sd-recent"><div className="sd-section-heading"><h2>Recently updated</h2><Clock3 size={18} /></div>{recent.map(ticket => <Link to={ticketUrl(ticket)} className="sd-recent-item" key={ticket.id}><span className={`sd-status-dot ${active(ticket) ? 'sd-status-active' : ''}`} /><div><h3>{ticket.subject}</h3><p>{readable(ticket.status)} · {dateLabel(ticket.updatedAt || ticket.createdAt)}</p></div><ArrowUpRight size={14} /></Link>)}{!recent.length && <p className="sd-muted">Your ticket activity will appear here.</p>}</section></div>
      <footer className="sd-footer"><span><span className="sd-live-dot" /> {query.isError ? 'Showing last available ticket data' : 'Connected to your support workspace'}</span><span>{query.isFetching ? 'Refreshing…' : `Updated ${new Date(query.dataUpdatedAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}`} · Auto-refresh every 30s</span></footer>
    </>}
  </div>
}
