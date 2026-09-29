import { useReservationsList } from '../../reservations/hooks/useReservations'
import { Card, Spinner } from '../../../components/ui'
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  BarChart,
  Bar,
  Legend,
} from 'recharts'
import { format, subDays, isSameDay } from 'date-fns'

export default function AnalyticsPage() {
  const { data, isLoading } = useReservationsList({}, { refetchInterval: 60000 })
  const reservations = data?.items || []

  if (isLoading) {
    return <div className="flex justify-center py-12"><Spinner size={24} /></div>
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
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Analytics Dashboard</h1>
        <p className="text-gray-500">Utilization, energy delivered, and revenue trends.</p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <Card className="p-6 h-96">
          <h2 className="text-lg font-semibold text-gray-900 mb-6">Reservations Trend (Last 7 Days)</h2>
          <ResponsiveContainer width="100%" height="100%">
            <LineChart data={chartData}>
              <CartesianGrid strokeDasharray="3 3" vertical={false} />
              <XAxis dataKey="date" />
              <YAxis allowDecimals={false} />
              <Tooltip />
              <Line type="monotone" dataKey="reservations" stroke="#3b82f6" strokeWidth={2} name="Reservations" />
            </LineChart>
          </ResponsiveContainer>
        </Card>

        <Card className="p-6 h-96">
          <h2 className="text-lg font-semibold text-gray-900 mb-6">Revenue Trend (Rs.)</h2>
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={chartData}>
              <CartesianGrid strokeDasharray="3 3" vertical={false} />
              <XAxis dataKey="date" />
              <YAxis />
              <Tooltip formatter={(value) => [`Rs. ${value}`, 'Revenue']} />
              <Bar dataKey="revenue" fill="#10b981" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </Card>

        <Card className="p-6 h-96">
          <h2 className="text-lg font-semibold text-gray-900 mb-6">Reservation Status Distribution</h2>
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={statusData} layout="vertical">
              <CartesianGrid strokeDasharray="3 3" horizontal={false} />
              <XAxis type="number" allowDecimals={false} />
              <YAxis dataKey="name" type="category" width={100} />
              <Tooltip />
              <Legend />
              <Bar dataKey="count" fill="#8b5cf6" name="Total Count" radius={[0, 4, 4, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </Card>
      </div>
    </div>
  )
}
