import { useMemo, useState } from 'react'
import SupportHeader from '../components/SupportHeader'
import SupportFilterBar from '../components/SupportFilterBar'
import TicketList from '../components/TicketList'
import ConversationPanel from '../components/ConversationPanel'
import TicketMetaRail from '../components/TicketMetaRail'
import { TICKETS, TICKET_DETAILS, buildFallbackDetail } from '../data/supportData'

/**
 * Support Manager ticket-queue workspace — list feed, conversation thread,
 * and the driver / telemetry / SLA context rail.
 */
export default function SupportInboxPage() {
  const [activeFilter, setActiveFilter] = useState('all')
  const [selectedId, setSelectedId] = useState('TCK-4829')

  const visibleTickets = useMemo(() => {
    if (activeFilter === 'all') return TICKETS
    return TICKETS.filter((t) => t.filterKeys.includes(activeFilter))
  }, [activeFilter])

  const selectedTicket =
    TICKETS.find((t) => t.id === selectedId) ?? visibleTickets[0] ?? TICKETS[0]
  const detail = TICKET_DETAILS[selectedTicket.id] ?? buildFallbackDetail(selectedTicket)

  return (
    <div className="flex w-full flex-col gap-space-lg">
      <SupportHeader />
      <SupportFilterBar active={activeFilter} onChange={setActiveFilter} />

      <div className="grid grid-cols-1 items-start gap-space-lg lg:grid-cols-12">
        <TicketList
          tickets={visibleTickets}
          selectedId={selectedTicket.id}
          onSelect={setSelectedId}
        />
        <ConversationPanel
          key={`conversation-${selectedTicket.id}`}
          ticket={selectedTicket}
          detail={detail}
        />
        <TicketMetaRail
          key={`meta-${selectedTicket.id}`}
          ticket={selectedTicket}
          detail={detail}
        />
      </div>
    </div>
  )
}
