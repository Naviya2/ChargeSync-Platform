import { useState } from 'react'
import DashboardHeader from '../components/DashboardHeader'
import MetricsGrid from '../components/MetricsGrid'
import AiGridQueue from '../components/AiGridQueue'
import RoleScopePanel from '../components/RoleScopePanel'
import SystemTelemetry from '../components/SystemTelemetry'
import ReservationsTable from '../components/ReservationsTable'
import { DashboardSkeleton, DashboardEmpty, DashboardError } from '../components/DashboardStates'
import DemoStateDock from '../components/DemoStateDock'

/**
 * Platform Admin dashboard — network telemetry, AI recommendation dispatch,
 * and multi-tenant station metrics.
 */
export default function AdminDashboardPage() {
  const [viewState, setViewState] = useState('normal')

  return (
    <div className="flex w-full flex-col gap-space-xl">
      <DashboardHeader />

      {viewState === 'loading' && <DashboardSkeleton />}
      {viewState === 'empty' && <DashboardEmpty onReset={() => setViewState('normal')} />}
      {viewState === 'error' && <DashboardError onRetry={() => setViewState('normal')} />}

      {viewState === 'normal' && (
        <div className="flex w-full flex-col gap-space-xl">
          <MetricsGrid />

          <div className="grid grid-cols-1 gap-space-lg lg:grid-cols-12">
            <div className="lg:col-span-8">
              <AiGridQueue />
            </div>
            <div className="flex flex-col gap-space-lg lg:col-span-4">
              <RoleScopePanel />
              <SystemTelemetry />
            </div>
          </div>

          <ReservationsTable />
        </div>
      )}

      <DemoStateDock value={viewState} onChange={setViewState} />
    </div>
  )
}
