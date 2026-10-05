import { useReservationsList } from '../../reservations/hooks/useReservations'
import { Spinner } from '../../../components/ui'
import PageHeader from '../../../components/shared/PageHeader'
import {
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  BarChart,
  Bar,
  AreaChart,
  Area
} from 'recharts'
import { format, subDays, isSameDay } from 'date-fns'

export default function AnalyticsPage() {
  const { data, isLoading } = useReservationsList({}, { refetchInterval: 60000 })
  const reservations = data?.items || []

  if (isLoading) {
    return <div className="flex justify-center py-16"><Spinner size={32} /></div>
  }

  // Prepare chart data for last 7 days
  const last7Days = Array.from({ length: 7 }).map((_, i) => subDays(new Date(), 6 - i))
  
  const chartData = last7Days.map(date => {
    const dayRes = reservations.filter(r => isSameDay(new Date(r.startTime), date))
    return {
      date: format(date, 'MMM dd'),
      reservations: dayRes.length,
      revenue: dayRes.reduce((sum, r) => sum + r.advanceDepositAmount, 0)
    }
  })

  // Status distribution
  const statusCounts = reservations.reduce((acc, r) => {
    acc[r.status] = (acc[r.status] || 0) + 1
    return acc
  }, {})

  const statusData = Object.entries(statusCounts).map(([name, count]) => ({
    name,
    count
  }))


  return (
    <div className="flex w-full flex-col gap-space-xl">
      <PageHeader
        title="Network Analytics"
        description="Comprehensive insights into network utilization, platform-wide revenue, and station telemetry."
      />

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-space-lg">
        {/* Reservations Area Chart */}
        <div className="flex flex-col gap-space-md overflow-hidden rounded-xl bg-surface-container-lowest p-space-lg shadow-sm">
          <h2 className="font-title-md text-title-md text-on-surface">Reservations Trend (Last 7 Days)</h2>
          <div className="h-80 w-full">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={chartData}>
                <defs>
                  <linearGradient id="colorRes" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#4f46e5" stopOpacity={0.3}/>
                    <stop offset="95%" stopColor="#4f46e5" stopOpacity={0}/>
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#374151" opacity={0.2} />
                <XAxis dataKey="date" axisLine={false} tickLine={false} tick={{fill: '#9ca3af', fontSize: 12}} />
                <YAxis allowDecimals={false} axisLine={false} tickLine={false} tick={{fill: '#9ca3af', fontSize: 12}} />
                <Tooltip content={<CustomTooltip />} />
                <Area type="monotone" dataKey="reservations" stroke="#4f46e5" strokeWidth={3} fillOpacity={1} fill="url(#colorRes)" name="Reservations" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Revenue Bar Chart */}
        <div className="flex flex-col gap-space-md overflow-hidden rounded-xl bg-surface-container-lowest p-space-lg shadow-sm">
          <h2 className="font-title-md text-title-md text-on-surface">Platform Revenue (LKR)</h2>
          <div className="h-80 w-full">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={chartData}>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#374151" opacity={0.2} />
                <XAxis dataKey="date" axisLine={false} tickLine={false} tick={{fill: '#9ca3af', fontSize: 12}} />
                <YAxis axisLine={false} tickLine={false} tick={{fill: '#9ca3af', fontSize: 12}} />
                <Tooltip content={<CustomTooltip prefix="LKR " />} />
                <Bar dataKey="revenue" fill="#10b981" radius={[4, 4, 0, 0]} name="Revenue" />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Status Distribution */}
        <div className="flex flex-col gap-space-md overflow-hidden rounded-xl bg-surface-container-lowest p-space-lg shadow-sm lg:col-span-2">
          <h2 className="font-title-md text-title-md text-on-surface">Reservation Status Distribution</h2>
          <div className="h-80 w-full">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={statusData} layout="vertical" barSize={32}>
                <CartesianGrid strokeDasharray="3 3" horizontal={false} stroke="#374151" opacity={0.2} />
                <XAxis type="number" allowDecimals={false} axisLine={false} tickLine={false} tick={{fill: '#9ca3af', fontSize: 12}} />
                <YAxis dataKey="name" type="category" width={100} axisLine={false} tickLine={false} tick={{fill: '#9ca3af', fontSize: 12}} />
                <Tooltip content={<CustomTooltip />} />
                <Bar dataKey="count" fill="#8b5cf6" name="Total Count" radius={[0, 4, 4, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>
    </div>
  )
}

const CustomTooltip = ({ active, payload, label, prefix = '' }) => {
  if (active && payload && payload.length) {
    return (
      <div className="rounded-xl border border-outline-variant bg-surface-container-low/95 p-3 shadow-lg backdrop-blur-md">
        <p className="font-label-md text-on-surface-variant mb-1">{label}</p>
        {payload.map((entry, index) => (
          <p key={index} className="font-metric-num-sm text-on-surface" style={{ color: entry.color }}>
            {entry.name}: {prefix}{entry.value}
          </p>
        ))}
      </div>
    )
  }
  return null
}
