/**
 * Mock data for the Support Manager ticket-queue workspace.
 * Replace with TanStack Query hooks against `src/api/endpoints/support.js`.
 */

export const SUPPORT_HEALTH = [
  { key: 'open', icon: '', label: '18 Open Tickets', tone: 'primary', dot: true },
  { key: 'response', icon: 'bolt', label: 'Avg First Response: 4.2m', tone: 'neutral' },
  { key: 'csat', icon: 'verified', label: 'CSAT: 98.4%', tone: 'tertiary' },
]

export const TICKET_FILTERS = [
  { key: 'all', label: 'All', count: 24 },
  { key: 'open', label: 'Open', count: 14 },
  { key: 'in-progress', label: 'In Progress', count: 6 },
  { key: 'escalated', label: 'Escalated', count: 3 },
  { key: 'sla', label: 'SLA Breaching', count: 1, tone: 'error' },
]

export const PRIORITY_TONE = {
  Urgent: 'bg-error-container text-on-error-container',
  High: 'bg-surface-container-high text-on-surface-variant',
  Medium: 'bg-surface-container text-on-surface-variant',
  Low: 'bg-surface-container text-on-surface-variant',
}

export const STATUS_TONE = {
  Open: 'bg-primary-fixed/40 text-on-primary-fixed-variant',
  'In Progress': 'bg-secondary-fixed text-on-secondary-fixed',
  Resolved: 'bg-tertiary-fixed text-on-tertiary-fixed',
  Closed: 'bg-tertiary-fixed text-on-tertiary-fixed',
}

export const TICKET_STATUSES = ['Open', 'In Progress', 'Resolved', 'Closed']

export const TICKETS = [
  {
    id: 'TCK-4829',
    priority: 'Urgent',
    status: 'In Progress',
    title: 'Bay 3B charger faulted mid-session, double billed idle fee',
    preview:
      'Charger stopped at 42.4 kWh, screen locked with isolation error while billing clock continued running...',
    customer: 'Marcus Vance',
    customerTag: 'Apex Platinum',
    initials: 'MV',
    age: '8m ago',
    sla: '12m left',
    slaTone: 'text-error',
    filterKeys: ['all', 'in-progress', 'escalated'],
  },
  {
    id: 'TCK-4825',
    priority: 'High',
    status: 'Open',
    title: 'NACS connector lock stuck on Rivian R1T port',
    preview: 'Latching solenoid failed to release after session termination pin code...',
    customer: 'Sarah Kim',
    initials: 'SK',
    age: '22m ago',
    sla: 'SLA: 38m left',
    slaTone: 'text-on-surface-variant',
    filterKeys: ['all', 'open'],
  },
  {
    id: 'TCK-4819',
    priority: 'Medium',
    status: 'In Progress',
    title: 'Loyalty point redemption voucher code not applying',
    preview: 'Applied fleet coupon code FLEET25 on checkout screen and received invalid hash...',
    customer: 'David L. (Amazon Fleet)',
    initials: 'DL',
    age: '1h ago',
    sla: 'Met SLA',
    slaTone: 'text-tertiary',
    filterKeys: ['all', 'in-progress'],
  },
  {
    id: 'TCK-4812',
    priority: 'Low',
    status: 'Open',
    title: 'Requesting invoice breakdown for monthly fleet charging',
    preview: 'Need consolidated tax schedule showing state green tariff credits for Q3...',
    customer: 'Elena Rostova',
    initials: 'ER',
    age: '2h ago',
    sla: 'SLA: 4h left',
    slaTone: 'text-on-surface-variant',
    filterKeys: ['all', 'open'],
  },
  {
    id: 'TCK-4790',
    priority: 'High',
    status: 'Resolved',
    title: 'Station access gate code failed at SF Metro Hub after 10 PM',
    preview: 'Gate keypad was offline; security bypassed car through manually...',
    customer: 'Jordan Miller',
    initials: 'JM',
    age: '4h ago',
    sla: 'Closed',
    slaTone: 'text-tertiary',
    dim: true,
    filterKeys: ['all'],
  },
]

/** Full conversation + context, keyed by ticket id. */
export const TICKET_DETAILS = {
  'TCK-4829': {
    category: 'Hardware & Billing',
    createdMeta: 'Created Today at 14:12 PST via ChargeSync Mobile App · Driver Marcus Vance (Tesla Model Y)',
    thread: [
      {
        type: 'system',
        icon: 'warning',
        iconTone: 'text-error',
        text: 'Ticket opened via in-app fault reporter · Anomaly flagged: ERR_ISO_FAULT_TEMP on Bay 3B',
      },
      {
        type: 'driver',
        author: 'Marcus Vance',
        time: 'Today, 14:12 PST',
        body: 'Hi support team, I was charging at Downtown Metro Hub Bay 3B when the session suddenly cut off around 42.4 kWh. The screen went blank with an isolation fault, but your mobile app kept running my session clock and billed me an extra $24.20 in idle fees while the cable was physically locked to my car. Can you please reverse this fee and check the station?',
      },
      {
        type: 'ai',
        author: 'ChargeSync Grid Sentinel™ (AI Diagnostics)',
        badge: 'Telemetry Audit Verified',
        body: 'Telemetry confirmed hardware voltage drop at 14:11:42. AI Approval Queue case #AI-REF-8902 generated for $42.00 full tariff & idle fee reversal with 94.2% confidence score.',
      },
      {
        type: 'support',
        author: 'Alex Chen (You)',
        time: 'Today, 14:18 PST',
        body: "Hello Marcus, thanks for reaching out right away. We sincerely apologize for the inconvenience. I have reviewed the telemetry logs from Bay 3B and verified the hardware voltage trip. I've initiated the release lock signal remotely and routed the $42.00 refund (covering the full tariff + disputed idle fee) to our priority AI Approval Queue for instant disbursement. You should see the lock disengage in 30 seconds.",
      },
      {
        type: 'driver',
        author: 'Marcus Vance',
        time: 'Today, 14:24 PST',
        body: 'Thank you Alex! The cable just unlocked and clicked off. Will I get an email confirmation once the refund clears?',
      },
    ],
    draftReply:
      "Yes, Marcus! You'll receive an automated confirmation email as soon as our platform supervisor clears the refund ticket. Is there anything else I can assist you with today?",
    driver: {
      name: 'Marcus Vance',
      email: 'marcus.vance@example.com',
      phone: '+1 (415) 892-1044',
      tier: 'Apex Platinum (4.95 ★)',
      lifetime: '142 sessions',
      vehicle: 'Tesla Model Y Long Range (2023)',
      vin: '5YJYGDEE8PF72910',
      port: 'NACS Native (Bay 3B)',
    },
    telemetry: {
      sessionId: 'SES-88219',
      rows: [
        { label: 'Station', value: 'Downtown Metro Hub #04' },
        { label: 'Dispatched Charger', value: 'Bay 3B (350kW DC Fast)' },
        { label: 'Delivered Energy', value: '42.4 kWh ($17.80)' },
        { label: 'Disputed Idle Fee', value: '$24.20', tone: 'text-error' },
        { label: 'Card Method', value: 'Visa •••• 4092' },
      ],
      aiCase: {
        id: 'AI-REF-8902',
        note: 'Full reversal ($42.00) pending supervisor single-click release.',
      },
    },
    sla: {
      remaining: '48m remaining of 60m',
      percent: 20,
      firstResponse: 'First Response: Met (6m)',
      target: 'Target: 15m',
    },
    tags: ['#HardwareFault', '#PG&E-Substation', '#ModelY-NACS'],
  },
}

/** Lightweight fallback detail for tickets without a full record yet. */
export function buildFallbackDetail(ticket) {
  return {
    category: ticket.priority,
    createdMeta: `Opened ${ticket.age} · ${ticket.customer}`,
    thread: [
      {
        type: 'driver',
        author: ticket.customer,
        time: ticket.age,
        body: ticket.preview,
      },
    ],
    draftReply: '',
    driver: { name: ticket.customer },
    telemetry: null,
    sla: {
      remaining: ticket.sla,
      percent: 55,
      firstResponse: 'First Response: pending',
      target: 'Target: 15m',
    },
    tags: [],
  }
}
