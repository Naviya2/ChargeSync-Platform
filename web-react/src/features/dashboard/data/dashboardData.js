/**
 * Mock data for the admin dashboard. Swap these for TanStack Query hooks
 * hitting `src/api/endpoints/*` once the backend is available.
 */

export const TIMEFRAMES = ['24 Hours', '7 Days', '30 Days', 'Custom Range']

export const METRICS = [
  {
    key: 'stations',
    label: 'Total Active Stations',
    value: '1,248',
    delta: '+14.2% MoM',
    deltaTone: 'up',
    pill: { text: '98.6% Uptime', tone: 'tertiary' },
    viz: 'sparkline',
  },
  {
    key: 'energy',
    label: 'Daily kWh Delivered',
    value: '412.8',
    unit: 'MWh',
    delta: '+8.5% vs yesterday',
    deltaTone: 'up',
    viz: 'radial',
    radialPercent: 78,
  },
  {
    key: 'reservations',
    label: 'Active Reservations',
    value: '894',
    delta: '92% slot utilization',
    deltaTone: 'neutral',
    pill: { text: 'Live Now', tone: 'secondary' },
    viz: 'stack',
  },
  {
    key: 'ai',
    label: 'AI Guardrail Automation',
    value: '96.4%',
    delta: 'Auto-cleared 640/654',
    deltaTone: 'neutral',
    pill: { text: '14 Pending', tone: 'error' },
    viz: 'icon',
  },
]

export const AI_RECOMMENDATIONS = [
  {
    id: 'SB-SJ40',
    icon: 'electric_meter',
    iconTone: 'text-primary',
    title: 'Supercharger Bay 04 — Metro Hub San Jose',
    tag: { text: 'ID #SB-SJ40', tone: 'neutral' },
    body: 'Surge demand predicted +42% at 17:30 · Suggested action: shift peak tariff +$0.08/kWh & prioritize reservation buffers.',
    confidence: 98,
    confidenceTone: 'text-tertiary',
    status: 'auto-approved',
  },
  {
    id: 'EBLD-12',
    icon: 'warning',
    iconTone: 'text-error',
    title: 'East Bay Logistics Depot — Station #12',
    tag: { text: 'Critical Load', tone: 'error' },
    body: 'Grid load approaching 88% capacity · Suggested action: throttle non-fleet connectors to a 100kW cap.',
    confidence: 94,
    confidenceTone: 'text-primary',
    status: 'awaiting-review',
  },
  {
    id: 'SEA-DT',
    icon: 'ac_unit',
    iconTone: 'text-secondary',
    title: 'Seattle Downtown Core — Park & Charge',
    tag: { text: 'Weather Advisory', tone: 'neutral' },
    body: 'Temperature drop below 3°C detected · Pre-heat battery dispatch advisory + reserve 15% DC fast capacity.',
    confidence: 91,
    confidenceTone: 'text-on-surface',
    status: 'review-plan',
  },
]

export const ROLE_SCOPES = [
  {
    key: 'admin',
    icon: 'admin_panel_settings',
    title: 'Platform Administrator',
    subtitle: 'Full global tenant controls',
    active: true,
  },
  {
    key: 'owner',
    icon: 'storefront',
    title: 'Station Owner Portal',
    subtitle: 'Host payout & bay management',
  },
  {
    key: 'support',
    icon: 'support_agent',
    title: 'Customer Support Desk',
    subtitle: 'Disputes & emergency disconnect',
  },
]

export const TELEMETRY = [
  { name: 'OCPP 2.0.1 Gateway', status: '100.0% Uptime', percent: 100, tone: 'tertiary' },
  { name: 'Stripe Billing Relay', status: 'Healthy (99.99%)', percent: 99.9, tone: 'tertiary' },
  { name: 'Predictive ML Engine v4.2', status: '12ms Latency', percent: 92, tone: 'primary' },
]

export const RESERVATION_FILTERS = [
  { key: 'all', label: 'All', count: 2410 },
  { key: 'confirmed', label: 'Confirmed', count: 1850 },
  { key: 'in-progress', label: 'In-Progress', count: 382 },
  { key: 'pending', label: 'Pending Review', count: 24 },
  { key: 'flagged', label: 'Flagged / Disputes', count: 12 },
]

export const RESERVATIONS = [
  {
    id: 'RES-94021',
    initials: 'MV',
    avatarTone: 'bg-primary/10 text-primary',
    user: 'Marcus Vance · Tesla Model Y',
    station: 'Downtown Plaza Bay 3B',
    stationMeta: 'Level 3 DC Fast (150 kW)',
    window: 'Today, 14:15 – 15:00',
    windowMeta: '34m elapsed',
    energy: '42.4 kWh',
    cost: '$19.08 ($0.45/kWh)',
    verification: { icon: 'fingerprint', text: 'Automated Check-in', tone: 'text-tertiary' },
    status: { label: 'Active Charging', tone: 'tertiary', pulse: true },
    action: 'Manage',
  },
  {
    id: 'RES-94022',
    initials: 'SK',
    avatarTone: 'bg-secondary-container/30 text-secondary',
    user: 'Sarah Kim · Rivian R1T',
    station: 'Harbor West Pier Fleet Hub',
    stationMeta: 'Bay 01 · CCS 350 kW Ultra',
    window: 'Today, 14:45 – 15:30',
    windowMeta: 'Arriving in 6m',
    energy: 'Est. 68.0 kWh',
    cost: '$29.24 reserved hold',
    verification: { icon: 'smart_toy', text: 'AI Pre-Allocated', tone: 'text-secondary' },
    status: { label: 'Pending Handover', tone: 'secondary' },
    action: 'Manage',
  },
  {
    id: 'RES-93988',
    initials: 'DL',
    avatarTone: 'bg-error-container text-on-error-container',
    user: 'David Lin · Hyundai Ioniq 5',
    station: 'Airport Express Terminal 2',
    stationMeta: 'Bay 07 · Level 2 AC 22 kW',
    window: 'Expired 13:30 (1h 15m idle)',
    windowMeta: 'Grace period exceeded',
    energy: '22.8 kWh + $18 fee',
    cost: 'Idle penalty active',
    verification: { icon: 'warning', text: 'Overstay Sensor Alert', tone: 'text-error' },
    status: { label: 'Flagged Overstay', tone: 'error' },
    action: 'Intervene',
  },
  {
    id: 'RES-94025',
    initials: 'EL',
    avatarTone: 'bg-surface-container-high text-on-surface',
    user: 'Elena Rostova · Ford F-150 Lightning',
    station: 'Silicon Park Innovation Lot',
    stationMeta: 'Bay 12 · 250 kW Supercharger',
    window: 'Today, 15:15 – 16:00',
    windowMeta: 'Confirmed by user',
    energy: 'Est. 80.0 kWh',
    cost: '$32.00 estimate',
    verification: { icon: 'verified_user', text: 'App Pass Verified', tone: 'text-primary' },
    status: { label: 'Confirmed', tone: 'neutral' },
    action: 'Manage',
  },
]
