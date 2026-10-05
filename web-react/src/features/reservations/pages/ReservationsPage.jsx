import { useMemo, useState } from 'react'
import { format, isValid } from 'date-fns'
import { CalendarDays, Search, X, Plus, RefreshCw, ChevronLeft, ChevronRight, ArrowUpRight, AlertCircle, Clock3 } from 'lucide-react'
import { useReservationsList } from '../hooks/useReservations'
import { useAuthStore } from '../../../store/authStore'
import PageHeader from '../../../components/shared/PageHeader'
import { Button, Card, Spinner } from '../../../components/ui'
import ReservationDetailsModal from '../components/ReservationDetailsModal'
import AddReservationModal from '../components/AddReservationModal'
import PendingApprovalsCard from '../../stations/components/PendingApprovalsCard'
import './reservations.css'

const statuses = ['All', 'Pending', 'Confirmed', 'CheckedIn', 'Completed', 'Cancelled']
const readable = status => status === 'CheckedIn' ? 'Checked in' : status
const money = value => new Intl.NumberFormat('en-LK', { style: 'currency', currency: 'LKR', maximumFractionDigits: 2 }).format(Number(value) || 0)
const dateText = (value, pattern) => {
  const date = new Date(value)
  return isValid(date) ? format(date, pattern) : 'Unavailable'
}
const customer = reservation => reservation.driverId ? reservation.driverName || 'Registered driver' : reservation.walkInCustomerName || 'Walk-in customer'
const initials = name => name.split(' ').filter(Boolean).slice(0, 2).map(word => word[0]).join('').toUpperCase()

export default function ReservationsPage() {
  const role = useAuthStore(state => state.user?.role)
  const canManage = ['Admin', 'StationOwner'].includes(role)
  const [selectedId, setSelectedId] = useState(null)
  const [search, setSearch] = useState('')
  const [sortOrder, setSortOrder] = useState('time_desc')
  const [status, setStatus] = useState('All')
  const [page, setPage] = useState(1)
  const [isAddModalOpen, setIsAddModalOpen] = useState(false)
  const query = useReservationsList({ page, pageSize: 20 }, { refetchInterval: 10000 })
  const { data, isLoading, isError } = query
  const reservations = useMemo(() => data?.items ?? [], [data])
  const total = data?.totalCount ?? reservations.length
  const totalPages = data?.totalPages ?? Math.max(1, Math.ceil(total / 20))
  const sortedAndFiltered = useMemo(() => {
    const q = search.trim().toLowerCase()
    return reservations.filter(reservation => (status === 'All' || reservation.status === status) &&
      `${customer(reservation)} ${reservation.stationName || ''} ${reservation.chargerName || ''} ${reservation.vehicleName || ''} ${reservation.id}`.toLowerCase().includes(q))
      .sort((a, b) => {
        if (sortOrder === 'time_asc') return new Date(a.startTime) - new Date(b.startTime)
        if (sortOrder === 'status') return (a.status || '').localeCompare(b.status || '')
        if (sortOrder === 'customer') return customer(a).localeCompare(customer(b))
        return new Date(b.startTime) - new Date(a.startTime)
      })
  }, [reservations, status, search, sortOrder])
  const hasFilters = search.trim() || status !== 'All'

  return <div className="rv-workspace">
    <PageHeader title="Reservations" description="View charging bookings, review requests, and manage reservation details." actions={<>
      <Button variant="outline" onClick={() => query.refetch?.()} disabled={query.isFetching}><RefreshCw size={15} className={query.isFetching ? 'rv-spin' : ''} /> Refresh</Button>
      {canManage && <Button onClick={() => setIsAddModalOpen(true)}><Plus size={16} /> Add Reservation</Button>}
    </>} />
    {canManage && <PendingApprovalsCard />}
    <div className="rv-toolbar"><div className="rv-tabs" role="group" aria-label="Reservation status filters">{statuses.map(value => <button key={value} type="button" aria-pressed={status === value} onClick={() => setStatus(value)}>{value === 'All' ? 'All bookings' : readable(value)}</button>)}</div>
      <div className="rv-tools"><label className="rv-search"><Search size={16} /><input aria-label="Search reservations" placeholder="Search this page by customer, station, or ID" value={search} onChange={event => setSearch(event.target.value)} />{search && <button aria-label="Clear reservation search" onClick={() => setSearch('')}><X size={14} /></button>}</label><select aria-label="Sort reservations" value={sortOrder} onChange={event => setSortOrder(event.target.value)}><option value="time_desc">Latest booking date</option><option value="time_asc">Earliest booking date</option><option value="status">Status</option><option value="customer">Customer name</option></select></div>
    </div>
    <Card className="rv-bookings p-0">
      <div className="rv-table-heading"><div><h2>Booking records <span>{isLoading || (isError && !data) ? '—' : total.toLocaleString()}</span></h2><p>Search, status filters, and sorting apply to the current page.</p></div><span className="rv-local-time"><Clock3 size={13} /> Local time</span></div>
      {isLoading ? <div role="status" className="rv-empty"><Spinner size={28} /><p>Loading reservations…</p></div> : isError ? <div role="alert" className="rv-empty"><AlertCircle size={28} /><h3>Failed to load reservations.</h3><p>Try refreshing to retrieve the latest bookings.</p><Button variant="outline" onClick={() => query.refetch?.()}>Try again</Button></div> : !sortedAndFiltered.length ? <div className="rv-empty"><CalendarDays size={30} /><h3>{hasFilters ? 'No matching reservations found.' : 'No reservations yet.'}</h3><p>{hasFilters ? 'Try another search or select a different status.' : 'New charging bookings will appear here.'}</p>{hasFilters && <Button variant="outline" onClick={() => { setSearch(''); setStatus('All') }}>Clear filters</Button>}</div> : <div className="rv-table-scroll"><table className="rv-table"><caption className="sr-only">Charging reservation records</caption><thead><tr><th scope="col">Customer</th><th scope="col">Station / charger</th><th scope="col">Schedule</th><th scope="col">Advance deposit</th><th scope="col">Status</th><th scope="col"><span className="sr-only">Actions</span></th></tr></thead><tbody>{sortedAndFiltered.map(reservation => <tr key={reservation.id}>
        <td><div className="rv-customer"><span className="rv-avatar">{initials(customer(reservation))}</span><div><strong>{customer(reservation)}</strong><span>{reservation.driverId ? reservation.vehicleName || 'Registered driver' : 'Walk-in booking'}</span></div></div><span className="rv-booking-id">#{reservation.id.slice(0, 8)}</span></td>
        <td><strong>{reservation.stationName || 'Unknown station'}</strong><span className="rv-cell-secondary">{reservation.chargerName || (reservation.chargerId ? `Charger ${reservation.chargerId.slice(0, 8)}` : 'Charger unavailable')}</span></td>
        <td className="rv-schedule"><strong>{dateText(reservation.startTime, 'dd MMM yyyy')}</strong><span className="rv-cell-secondary">{dateText(reservation.startTime, 'HH:mm')} – {dateText(reservation.endTime, 'HH:mm')}{dateText(reservation.startTime, 'yyyy-MM-dd') !== dateText(reservation.endTime, 'yyyy-MM-dd') && ` (${dateText(reservation.endTime, 'dd MMM')})`}</span></td>
        <td className="rv-amount"><strong>{reservation.advanceDepositAmount == null ? '—' : money(reservation.advanceDepositAmount)}</strong>{Number(reservation.cancellationFeesPaid) > 0 && <span className="rv-cell-secondary">{money(reservation.cancellationFeesPaid)} prior fees paid</span>}{Number(reservation.lateCancellationFee) > 0 && <span className="rv-fee-note">{money(reservation.lateCancellationFee)} cancellation fee</span>}</td>
        <td><span className={`rv-status rv-status-${reservation.status?.toLowerCase()}`}><span />{readable(reservation.status)}</span></td>
        <td><button className="rv-view" onClick={() => setSelectedId(reservation.id)}><span>View Details</span><ArrowUpRight size={14} /></button></td>
      </tr>)}</tbody></table></div>}
      {!isLoading && !isError && <div className="rv-table-footer"><span>{sortedAndFiltered.length} shown on page {page} · {total} total bookings</span><div><Button variant="ghost" size="sm" aria-label="Previous reservations page" disabled={page <= 1 || query.isFetching} onClick={() => setPage(value => value - 1)}><ChevronLeft size={15} /></Button><span>Page {page} of {Math.max(1, totalPages)}</span><Button variant="ghost" size="sm" aria-label="Next reservations page" disabled={page >= totalPages || query.isFetching} onClick={() => setPage(value => value + 1)}><ChevronRight size={15} /></Button></div></div>}
    </Card>
    {selectedId && <ReservationDetailsModal reservationId={selectedId} readOnly={role === 'SupportManager'} onClose={() => setSelectedId(null)} />}
    {isAddModalOpen && <AddReservationModal onClose={() => setIsAddModalOpen(false)} />}
  </div>
}
