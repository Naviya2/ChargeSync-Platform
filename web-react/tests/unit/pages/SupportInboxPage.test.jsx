import { beforeEach, describe, expect, it, vi } from 'vitest'
import { fireEvent, render, screen, within } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import SupportInboxPage from '@/features/support/pages/SupportInboxPage'
import supportApi from '@/api/endpoints/support'
import { useAuthStore } from '@/store/authStore'

const { confirm } = vi.hoisted(() => ({ confirm: vi.fn() }))
vi.mock('@/store/dialogStore', () => ({ default: { getState: () => ({ confirm }) } }))
vi.mock('@/api/endpoints/support', () => ({ default: {
  list: vi.fn(), reply: vi.fn(), assign: vi.fn(), status: vi.fn(), reviewRefund: vi.fn(),
} }))
vi.mock('@/features/support/components/SupportWorkflow', () => ({ default: () => <p>Workflow panel</p> }))
vi.mock('@/features/support/components/TicketAnalysis', () => ({ default: () => <p>Analysis panel</p> }))

const ticket = (id, subject, overrides = {}) => ({
  id, subject, driverName: 'Alex Silva', driverEmail: 'alex@example.com',
  description: 'Please review my charging session.', priority: 'Medium',
  status: 'Open', category: 'Charging', refundStatus: 'NotRequested',
  createdAt: '2026-10-05T08:00:00Z', updatedAt: '2026-10-05T08:00:00Z', messages: [],
  ...overrides,
})
const first = ticket('ticket-a', 'Charging interrupted')
const second = ticket('ticket-b', 'Meter reading', { status: 'InProgress' })

function renderInbox(path = '/support') {
  const client = new QueryClient({ defaultOptions: { queries: { retry: false } } })
  return render(<MemoryRouter initialEntries={[path]}><QueryClientProvider client={client}><SupportInboxPage /></QueryClientProvider></MemoryRouter>)
}

describe('Support ticket workspace', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    useAuthStore.setState({ user: { id: 'staff-1', role: 'SupportManager', fullName: 'Sam Silva' } })
    vi.mocked(supportApi.list).mockResolvedValue([first, second])
  })

  it('opens dashboard deep links and keeps the selected conversation within search results', async () => {
    renderInbox('/support?ticket=ticket-b')
    const conversation = await screen.findByRole('region', { name: 'Ticket conversation' })
    expect(within(conversation).getByRole('heading', { name: 'Meter reading' })).toBeInTheDocument()
    fireEvent.change(screen.getByRole('textbox', { name: 'Search tickets' }), { target: { value: 'Charging interrupted' } })
    expect(within(conversation).getByRole('heading', { name: 'Charging interrupted' })).toBeInTheDocument()
    fireEvent.change(screen.getByRole('textbox', { name: 'Search tickets' }), { target: { value: 'unmatched' } })
    expect(screen.getByText('No matching tickets')).toBeInTheDocument()
    expect(screen.queryByRole('region', { name: 'Ticket conversation' })).not.toBeInTheDocument()
    fireEvent.click(screen.getByRole('button', { name: 'Clear filters' }))
    expect(screen.getByRole('region', { name: 'Ticket conversation' })).toBeInTheDocument()
  })

  it('preserves a separate reply draft for each conversation', async () => {
    renderInbox()
    await screen.findByRole('region', { name: 'Ticket conversation' })
    fireEvent.change(screen.getByRole('textbox', { name: 'Reply to Alex Silva' }), { target: { value: 'Draft for the interrupted session' } })
    const queue = screen.getByRole('region', { name: 'Ticket queue' })
    fireEvent.click(within(queue).getByRole('button', { name: /Meter reading/ }))
    expect(screen.getByRole('textbox', { name: 'Reply to Alex Silva' })).toHaveValue('')
    fireEvent.change(screen.getByRole('textbox', { name: 'Reply to Alex Silva' }), { target: { value: 'Draft for the meter issue' } })
    fireEvent.click(within(queue).getByRole('button', { name: /Charging interrupted/ }))
    expect(screen.getByRole('textbox', { name: 'Reply to Alex Silva' })).toHaveValue('Draft for the interrupted session')
  })

  it('restores the reply after a failed send and retains the original ticket status', async () => {
    vi.mocked(supportApi.reply).mockRejectedValue(new Error('offline'))
    renderInbox()
    await screen.findByRole('region', { name: 'Ticket conversation' })
    fireEvent.change(screen.getByRole('textbox', { name: 'Reply to Alex Silva' }), { target: { value: 'We are reviewing your session.' } })
    fireEvent.click(screen.getByRole('button', { name: 'Send reply' }))
    expect(await screen.findByRole('alert')).toHaveTextContent('Your change could not be saved')
    expect(screen.getByRole('textbox', { name: 'Reply to Alex Silva' })).toHaveValue('We are reviewing your session.')
    expect(screen.getByRole('combobox', { name: 'Status' })).toHaveValue('Open')
    expect(supportApi.reply).toHaveBeenCalledWith('ticket-a', 'We are reviewing your session.')
  })

  it('blocks resolving pending refunds and submits review only after confirmation', async () => {
    const refund = { ...first, refundStatus: 'PendingReview', requestedRefundAmount: 20 }
    vi.mocked(supportApi.list).mockResolvedValue([refund])
    vi.mocked(supportApi.reviewRefund).mockResolvedValue({ ...refund, refundStatus: 'Approved' })
    confirm.mockResolvedValueOnce(false).mockResolvedValueOnce(true)
    renderInbox()
    await screen.findByRole('region', { name: 'Ticket conversation' })
    expect(within(screen.getByRole('combobox', { name: 'Status' })).getByRole('option', { name: 'Resolved' })).toBeDisabled()
    fireEvent.click(screen.getByRole('button', { name: 'Approve' }))
    await vi.waitFor(() => expect(confirm).toHaveBeenCalledTimes(1))
    expect(supportApi.reviewRefund).not.toHaveBeenCalled()
    fireEvent.click(screen.getByRole('button', { name: 'Approve' }))
    await vi.waitFor(() => expect(supportApi.reviewRefund).toHaveBeenCalledWith('ticket-a', true))
  })

  it('makes closed tickets read only', async () => {
    vi.mocked(supportApi.list).mockResolvedValue([{ ...first, status: 'Closed' }])
    renderInbox()
    expect(await screen.findByText('This ticket is closed. Replies are disabled.')).toBeInTheDocument()
    expect(screen.queryByRole('button', { name: 'Send reply' })).not.toBeInTheDocument()
  })
})
