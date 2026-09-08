/**
 * Mock data for the Station Owner "My Stations" workspace.
 * Replace with TanStack Query hooks against `src/api/endpoints/stations.js`.
 */

export const STATION_KPIS = [
  {
    key: 'total',
    label: 'Total Stations',
    icon: 'domain',
    value: '8',
    highlight: '6 Active',
    sub: '1 Pending Approval · 1 Maint.',
  },
  {
    key: 'ports',
    label: 'Operational Ports',
    icon: 'power',
    value: '36 / 42',
    highlight: '85.7% Live',
    sub: '6 bays in reserved or staging state',
  },
  {
    key: 'revenue',
    label: 'Daily Net Revenue',
    icon: 'payments',
    value: '$3,420.50',
    highlight: '+12.4%',
    sub: 'vs $3,042.80 preceding 7d avg',
  },
  {
    key: 'utilization',
    label: 'Fleet Utilization',
    icon: 'speed',
    value: '78.4%',
    highlight: 'Target: >75%',
    progress: 78.4,
  },
]

export const STATION_FILTERS = [
  { key: 'all', label: 'All Stations', count: 8 },
  { key: 'active', label: 'Active', count: 6 },
  { key: 'pending', label: 'Pending Approval', count: 1 },
  { key: 'suspended', label: 'Suspended', count: 1 },
]

const STATUS = {
  active: { key: 'active', label: 'Active', tone: 'tertiary', pulse: true },
  pending: { key: 'pending', label: 'Staging Approval', tone: 'secondary' },
  suspended: { key: 'suspended', label: 'Suspended', tone: 'error' },
}

export const STATIONS = [
  {
    id: 'ST-SF-9021',
    name: 'Downtown Metro Superhub #04',
    sector: 'Downtown Sector',
    address: '742 Market St, San Francisco, CA 94103',
    status: STATUS.active,
    filterKey: 'active',
    capacity: '8 Chargers (350kW DC & 22kW AC)',
    bayLabel: 'Live Bay State',
    bayValue: '7 of 8 in use (88% Load)',
    load: 88,
    trendLabel: '24h Utilization Profile',
    trendValue: 'Peak: 380 kW',
    footerLabel: 'Delivered Today',
    footerValue: '2,840 kWh · $1,248.30',
    sparkTone: 'text-primary',
  },
  {
    id: 'ST-SF-4402',
    name: 'Mission Bay Tech Center — Hub A',
    sector: 'Biotech Campus',
    address: '1650 Owens St, San Francisco, CA 94158',
    status: STATUS.active,
    filterKey: 'active',
    capacity: '6 Chargers (DC 150kW Dual)',
    bayLabel: 'Live Bay State',
    bayValue: '4 of 6 in use (67% Load)',
    load: 67,
    trendLabel: '24h Utilization Profile',
    trendValue: 'Peak: 220 kW',
    footerLabel: 'Delivered Today',
    footerValue: '1,910 kWh · $783.10',
    sparkTone: 'text-secondary',
  },
  {
    id: 'ST-SV-8830',
    name: 'Silicon Park North Station',
    sector: 'Santa Clara North',
    address: '3200 Scott Blvd, Santa Clara, CA 95054',
    status: STATUS.pending,
    filterKey: 'pending',
    capacity: '12 Chargers (Fleet Megawatt Depot)',
    bayLabel: 'Commissioning Status',
    bayValue: 'Pre-flight Testing',
    load: 25,
    trendLabel: 'Grid Interconnect Test',
    trendValue: 'Telemetry Active',
    footerLabel: 'Permits & Approval',
    footerValue: 'Phase 2 Review',
    sparkTone: 'text-outline',
  },
]

const STANDARD_HOURS = [
  { day: 'Monday', enabled: true, open: '06:00', close: '23:30', note: 'Peak window: 16:00 – 20:00', noteTone: 'primary' },
  { day: 'Tuesday', enabled: true, open: '06:00', close: '23:30', note: 'Peak window: 16:00 – 20:00', noteTone: 'primary' },
  { day: 'Wednesday', enabled: true, open: '06:00', close: '23:30', note: 'Peak window: 16:00 – 20:00', noteTone: 'primary' },
  { day: 'Thursday', enabled: true, open: '06:00', close: '23:30', note: 'Peak window: 16:00 – 20:00', noteTone: 'primary' },
  { day: 'Friday', enabled: true, open: '06:00', close: '23:30', note: 'Peak window: 16:00 – 20:00', noteTone: 'primary' },
  { day: 'Saturday', enabled: true, open: '07:00', close: '22:00', note: 'Weekend Flat Rate ($0.39)', noteTone: 'secondary' },
  { day: 'Sunday', enabled: true, open: '07:00', close: '22:00', note: 'Weekend Flat Rate ($0.39)', noteTone: 'secondary' },
]

/** Per-station deep-dive console data, keyed by station id. */
export const STATION_DETAILS = {
  'ST-SF-9021': {
    subtitle:
      'Primary 800V DC Hub connected to PG&E 1.2MW High-Cap Feeder. Real-time dynamic ISO pricing enabled.',
    tags: ['CCS2 & NACS Capable'],
    statusLabel: 'Active & Online',
    overview: {
      stats: [
        { label: 'Instantaneous Grid Load', value: '312', sub: '/ 400 kW Cap', progress: 78 },
        { label: 'Revenue Today', value: '$1,248.30', delta: '+18.2%', sub: '2,840 kWh distributed' },
        { label: 'Avg Dwell Session', value: '38', sub: 'Minutes', note: 'Fast turnaround (Target <45m)' },
        {
          label: 'Hardware Reliability',
          value: '99.8%',
          sub: '30d SLA',
          note: 'Zero safety disconnect faults',
          accent: 'text-tertiary',
        },
      ],
      bays: [
        { name: 'Bay 1A', state: 'occupied', stateLabel: 'Occupied (84%)', spec: 'CH-01 · 285 kW DC', who: 'Porsche Taycan', meta: '12m left', metaTone: 'text-primary' },
        { name: 'Bay 1B', state: 'occupied', stateLabel: 'Occupied (42%)', spec: 'CH-02 · 150 kW DC', who: 'Rivian R1T', meta: '24m left', metaTone: 'text-primary' },
        { name: 'Bay 2A', state: 'available', stateLabel: 'Available', spec: 'CH-03 · 350 kW DC', who: 'Connector Ready', meta: 'Idle', metaTone: 'text-tertiary' },
        { name: 'Bay 2B', state: 'queued', stateLabel: 'Reservation Queue', spec: 'CH-04 · 350 kW DC', who: 'ETA Polestar 3', meta: 'In 4 mins', metaTone: 'text-secondary' },
      ],
    },
    chargers: [
      { id: 'CH-01', bay: 'Bay 1A · HyperCharge Ultra-Liquid', connector: 'CCS Combo 1 / NACS', power: '350 kW', voltage: '800V DC', tariff: '$0.42 / kWh', tariffType: 'Dynamic Peak Tariff', tariffTone: 'text-tertiary', state: 'dispensing', stateLabel: 'Dispensing (285 kW)' },
      { id: 'CH-02', bay: 'Bay 1B · FastPro DC Line', connector: 'CCS Combo 1', power: '150 kW', voltage: '400V DC', tariff: '$0.38 / kWh', tariffType: 'Standard Flat Base', tariffTone: 'text-on-surface-variant', state: 'dispensing', stateLabel: 'Dispensing (112 kW)' },
      { id: 'CH-03', bay: 'Bay 2A · HyperCharge Ultra-Liquid', connector: 'NACS (Tesla Native)', power: '350 kW', voltage: '800V DC', tariff: '$0.42 / kWh', tariffType: 'Dynamic Peak Tariff', tariffTone: 'text-tertiary', state: 'available', stateLabel: 'Available (Idle)' },
      { id: 'CH-04', bay: 'Bay 2B · HyperCharge Ultra-Liquid', connector: 'CCS Combo 1 / NACS', power: '350 kW', voltage: '800V DC', tariff: '$0.42 / kWh', tariffType: 'Dynamic Peak Tariff', tariffTone: 'text-tertiary', state: 'reserved', stateLabel: 'Reserved (Driver en route)' },
      { id: 'CH-07', bay: 'Bay 4A · AC Destination Post', connector: 'J1772 / Type 1', power: '22 kW', voltage: '240V AC', tariff: '$0.24 / kWh', tariffType: 'Destination Long-Dwell', tariffTone: 'text-on-surface-variant', state: 'dispensing', stateLabel: 'Dispensing (19 kW)' },
    ],
    hours: STANDARD_HOURS,
    maintenance: [
      {
        icon: 'system_update_alt',
        iconTone: 'text-secondary',
        title: 'Firmware OTA v3.4.1 & Isolation Test',
        status: 'Scheduled',
        statusTone: 'text-secondary',
        body: 'Quarterly high-voltage safety compliance and CCS2 plug communication protocol upgrade.',
        chargers: 'CH-01, CH-02',
        when: 'Oct 28, 2025 · 02:00 AM – 04:30 AM PST',
        actions: ['Reschedule', 'View Runbook'],
      },
      {
        icon: 'build',
        iconTone: 'text-primary',
        title: 'Coolant Loop Flush & Cable Replacement',
        status: 'Confirmed · Tech Dispatched',
        statusTone: 'text-primary',
        body: 'Liquid-cooled hypercharge cable wear detected by internal thermistor sensor #TH-89.',
        chargers: 'CH-04 (Bay 2B)',
        when: 'Nov 04, 2025 · 08:00 AM – 12:00 PM PST',
        actions: ['Contact Tech', 'Telemetry Logs'],
      },
      {
        icon: 'electric_meter',
        iconTone: 'text-on-surface-variant',
        title: 'Grid Transformer Inspection (PG&E Utility-Led)',
        status: 'Pending Utility Approval',
        statusTone: 'text-on-surface-variant',
        body: 'Municipal substation phase load rebalancing and high-voltage breaker check. Entire station briefly offline.',
        chargers: 'All 8 Station Bays',
        when: 'Nov 15, 2025 · 01:00 AM – 03:00 AM PST',
        actions: ['Review Notice'],
      },
    ],
  },

  'ST-SF-4402': {
    subtitle: 'Dual-port 400V DC hub serving the Mission Bay biotech campus with flat daytime pricing.',
    tags: ['CCS2 Capable'],
    statusLabel: 'Active & Online',
    overview: {
      stats: [
        { label: 'Instantaneous Grid Load', value: '148', sub: '/ 300 kW Cap', progress: 49 },
        { label: 'Revenue Today', value: '$783.10', delta: '+6.1%', sub: '1,910 kWh distributed' },
        { label: 'Avg Dwell Session', value: '52', sub: 'Minutes', note: 'Campus long-dwell profile' },
        { label: 'Hardware Reliability', value: '99.4%', sub: '30d SLA', note: 'One soft fault auto-cleared', accent: 'text-tertiary' },
      ],
      bays: [
        { name: 'Bay 1', state: 'occupied', stateLabel: 'Occupied (61%)', spec: 'CH-01 · 96 kW DC', who: 'Hyundai Ioniq 6', meta: '18m left', metaTone: 'text-primary' },
        { name: 'Bay 2', state: 'occupied', stateLabel: 'Occupied (33%)', spec: 'CH-02 · 74 kW DC', who: 'VW ID.4', meta: '31m left', metaTone: 'text-primary' },
        { name: 'Bay 3', state: 'available', stateLabel: 'Available', spec: 'CH-03 · 150 kW DC', who: 'Connector Ready', meta: 'Idle', metaTone: 'text-tertiary' },
      ],
    },
    chargers: [
      { id: 'CH-01', bay: 'Bay 1 · FastPro DC Dual', connector: 'CCS Combo 1', power: '150 kW', voltage: '400V DC', tariff: '$0.36 / kWh', tariffType: 'Standard Flat Base', tariffTone: 'text-on-surface-variant', state: 'dispensing', stateLabel: 'Dispensing (96 kW)' },
      { id: 'CH-02', bay: 'Bay 2 · FastPro DC Dual', connector: 'CCS Combo 1', power: '150 kW', voltage: '400V DC', tariff: '$0.36 / kWh', tariffType: 'Standard Flat Base', tariffTone: 'text-on-surface-variant', state: 'dispensing', stateLabel: 'Dispensing (74 kW)' },
      { id: 'CH-03', bay: 'Bay 3 · FastPro DC Dual', connector: 'CCS Combo 1', power: '150 kW', voltage: '400V DC', tariff: '$0.36 / kWh', tariffType: 'Standard Flat Base', tariffTone: 'text-on-surface-variant', state: 'available', stateLabel: 'Available (Idle)' },
    ],
    hours: STANDARD_HOURS,
    maintenance: [
      {
        icon: 'build',
        iconTone: 'text-primary',
        title: 'Annual Connector Wear Inspection',
        status: 'Scheduled',
        statusTone: 'text-secondary',
        body: 'Routine visual and continuity inspection of all DC connectors and holsters.',
        chargers: 'CH-01, CH-02, CH-03',
        when: 'Dec 02, 2025 · 06:00 AM – 08:00 AM PST',
        actions: ['Reschedule', 'View Runbook'],
      },
    ],
  },

  'ST-SV-8830': {
    subtitle: 'Fleet megawatt depot in pre-commissioning. Grid interconnect testing with PG&E in progress.',
    tags: ['Fleet Depot', 'Pre-Commissioning'],
    statusLabel: 'Staging Approval',
    overview: {
      stats: [
        { label: 'Interconnect Test Load', value: '0', sub: '/ 1,200 kW Cap', progress: 4 },
        { label: 'Revenue Today', value: '$0.00', sub: 'Not yet operational' },
        { label: 'Commissioning Progress', value: '25%', sub: 'Phase 2 of 4' },
        { label: 'Permits Cleared', value: '3 / 5', sub: 'Utility approval outstanding', accent: 'text-secondary' },
      ],
      bays: [
        { name: 'Bay A1', state: 'queued', stateLabel: 'Pre-flight Test', spec: 'CH-01 · 1 MW DC', who: 'Test harness', meta: 'Running', metaTone: 'text-secondary' },
        { name: 'Bay A2', state: 'queued', stateLabel: 'Pre-flight Test', spec: 'CH-02 · 1 MW DC', who: 'Test harness', meta: 'Queued', metaTone: 'text-secondary' },
      ],
    },
    chargers: [
      { id: 'CH-01', bay: 'Bay A1 · Megawatt Fleet Dispenser', connector: 'MCS (Megawatt)', power: '1 MW', voltage: '1250V DC', tariff: '—', tariffType: 'Not set (pre-commissioning)', tariffTone: 'text-on-surface-variant', state: 'reserved', stateLabel: 'Commissioning Test' },
      { id: 'CH-02', bay: 'Bay A2 · Megawatt Fleet Dispenser', connector: 'MCS (Megawatt)', power: '1 MW', voltage: '1250V DC', tariff: '—', tariffType: 'Not set (pre-commissioning)', tariffTone: 'text-on-surface-variant', state: 'reserved', stateLabel: 'Commissioning Test' },
    ],
    hours: STANDARD_HOURS,
    maintenance: [
      {
        icon: 'electric_meter',
        iconTone: 'text-on-surface-variant',
        title: 'Grid Interconnect Commissioning (PG&E Utility-Led)',
        status: 'In Progress',
        statusTone: 'text-secondary',
        body: 'Substation interconnect verification, protection relay coordination, and load bank testing.',
        chargers: 'All 12 Depot Bays',
        when: 'Oct 20 – Nov 10, 2025 · Daily windows',
        actions: ['Review Notice'],
      },
    ],
  },
}

export const DETAIL_TABS = [
  { key: 'overview', label: 'Overview' },
  { key: 'chargers', label: 'Chargers' },
  { key: 'operating-hours', label: 'Operating Hours' },
  { key: 'maintenance', label: 'Maintenance' },
]
