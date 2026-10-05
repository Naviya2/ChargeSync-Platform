import { beforeEach, describe, expect, it, vi } from 'vitest'
import { fireEvent, render, screen, within } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import SupportManagerDashboardPage from '@/features/dashboard/pages/SupportManagerDashboardPage'
import supportApi from '@/api/endpoints/support'
import { useAuthStore } from '@/store/authStore'

vi.mock('@/api/endpoints/support', () => ({ default: { list: vi.fn() } }))

const ticket = (id, overrides = {}) => ({
  id, subject: `Conversation ${id}`, driverName: 'Alex', category: 'Charging',
  priority: 'Medium', status: 'Open', refundStatus: 'NotRequested',
  createdAt: new Date().toISOString(), updatedAt: new Date().toISOString(),
  assignedToUserId: null, ...overrides,
})

function renderDashboard() {
  const client = new QueryClient({ defaultOptions: { queries: { retry: false } } })
  return render(<MemoryRouter><QueryClientProvider client={client}><SupportManagerDashboardPage /></QueryClientProvider></MemoryRouter>)
}

describe('Support manager dashboard', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    useAuthStore.setState({ user: { id: 'support-1', fullName: 'Sam Silva', role: 'SupportManager' } })
  })

  it('uses live tickets, prioritizes urgent work and links to the selected conversation', async () => {
    vi.mocked(supportApi.list).mockResolvedValue([
      ticket('medium', { assignedToUserId: 'support-1' }),
      ticket('urgent', { priority: 'Urgent', refundStatus: 'PendingReview', requestedRefundAmount: 750 }),
      ticket('closed', { status: 'Closed', priority: 'Urgent' }),
    ])
    renderDashboard()
    expect(await screen.findByText('1 conversation needs your care.')).toBeInTheDocument()
    const metrics = screen.getByRole('region', { name: 'Support metrics' })
    expect(within(metrics).getByText('2')).toBeInTheDocument()
    const queue = screen.getByText('Your next conversations').closest('section')
    const links = within(queue).getAllByRole('link').filter(link => link.classList.contains('sd-ticket'))
    expect(links[0]).toHaveAttribute('href', '/support?ticket=urgent')
    expect(within(queue).queryByText('Conversation closed')).not.toBeInTheDocument()
    expect(screen.getByText(/Requested across 1 pending refund review/)).toBeInTheDocument()
    fireEvent.click(screen.getByRole('button', { name: 'My queue' }))
    expect(within(queue).getByText('Conversation medium')).toBeInTheDocument()
    expect(within(queue).queryByText('Conversation urgent')).not.toBeInTheDocument()
    fireEvent.change(screen.getByRole('textbox', { name: 'Search dashboard tickets' }), { target: { value: 'unmatched' } })
    expect(screen.getByText('No conversations found')).toBeInTheDocument()
    fireEvent.change(screen.getByRole('combobox', { name: 'Ticket activity period' }), { target: { value: '30' } })
    expect(screen.getByText('tickets received in the last 30 calendar days')).toBeInTheDocument()
  })

  it('shows an honest empty state with no invented activity', async () => {
    vi.mocked(supportApi.list).mockResolvedValue([])
    renderDashboard()
    expect(await screen.findByText('A clear queue. A fresh start.')).toBeInTheDocument()
    expect(screen.getByText('No refunds awaiting review')).toBeInTheDocument()
    expect(screen.getByText('Your ticket activity will appear here.')).toBeInTheDocument()
  })

  it('reports API errors and lets the manager retry', async () => {
    vi.mocked(supportApi.list).mockRejectedValueOnce(new Error('offline')).mockResolvedValue([])
    renderDashboard()
    expect(await screen.findByRole('alert')).toHaveTextContent('We couldn’t refresh your tickets.')
    expect(screen.queryByRole('region', { name: 'Support metrics' })).not.toBeInTheDocument()
    fireEvent.click(screen.getByRole('button', { name: 'Try again' }))
    expect(await screen.findByText('A clear queue. A fresh start.')).toBeInTheDocument()
  })
})
