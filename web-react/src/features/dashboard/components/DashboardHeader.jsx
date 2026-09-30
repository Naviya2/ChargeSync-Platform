import { TIMEFRAMES } from '../data/dashboardData'
import { cn } from '../../../lib/cn'
import { useNavigate } from 'react-router-dom'

export default function DashboardHeader({ timeframe, setTimeframe, reservations = [], customRange, setCustomRange }) {
  const navigate = useNavigate()

  return (
    <div className="flex flex-col justify-between gap-space-lg lg:flex-row lg:items-center">
      <div className="flex flex-col">
        <div className="flex items-center gap-space-sm">
          <h1 className="font-headline-lg text-headline-lg text-on-surface">Station Dashboard</h1>
          <span className="inline-flex items-center gap-1 rounded-full bg-tertiary-container/15 px-space-xs py-space-2xs font-label-sm text-label-sm text-tertiary">
            <span className="h-1.5 w-1.5 animate-pulse rounded-full bg-tertiary" />
            Live Analytics
          </span>
        </div>
        <p className="font-body-md text-body-md text-on-surface-variant">
          Manage your charging stations, monitor live performance metrics, and track revenue.
        </p>
      </div>

      <div className="flex flex-wrap items-center gap-space-md">
        <div className="flex flex-col gap-2">
          <div className="inline-flex rounded-xl bg-surface-container p-space-2xs shadow-sm">
            {TIMEFRAMES.map((tf) => (
              <button
                key={tf}
                type="button"
                onClick={() => setTimeframe(tf)}
                className={cn(
                  'rounded-lg px-space-md py-space-xs font-label-md text-label-md transition-all',
                  timeframe === tf
                    ? 'bg-primary text-on-primary shadow-sm'
                    : 'text-on-surface-variant hover:text-on-surface',
                )}
              >
                {tf}
              </button>
            ))}
          </div>
          {timeframe === 'Custom Range' && (
            <div className="flex items-center gap-2 rounded-xl bg-surface-container-low p-2 shadow-sm text-sm">
               <input type="date" value={customRange?.start || ''} onChange={e => setCustomRange?.({ ...customRange, start: e.target.value })} className="rounded bg-surface-container px-2 py-1 border border-outline-variant text-on-surface" />
               <span className="text-on-surface-variant">to</span>
               <input type="date" value={customRange?.end || ''} onChange={e => setCustomRange?.({ ...customRange, end: e.target.value })} className="rounded bg-surface-container px-2 py-1 border border-outline-variant text-on-surface" />
            </div>
          )}
        </div>

        <div className="flex items-center gap-space-sm">
          <button
            type="button"
            onClick={() => {
               let csv = "\uFEFF"; // BOM for Excel UTF-8
               csv += 'System Name:,ChargeSync Platform\n';
               csv += `Report Generated:,${new Date().toLocaleString()}\n`;
               csv += `Timeframe Filter:,${timeframe}\n\n`;
               csv += 'Reservation ID,Customer,Station,Start Time,End Time,Status,Advance Deposit (LKR),Refund Status\n';
               
               reservations.forEach(r => {
                 const id = r.id || '';
                 const customer = r.driverName || 'Walk-In';
                 const station = r.stationName || 'N/A';
                 const start = new Date(r.startTime).toLocaleString();
                 const end = new Date(r.endTime).toLocaleString();
                 const status = r.status || '';
                 const deposit = r.advanceDepositAmount || 0;
                 const refund = r.refundStatus || 'Not Requested';
                 
                 csv += `"${id}","${customer}","${station}","${start}","${end}","${status}","${deposit}","${refund}"\n`;
               });

               const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
               const encodedUri = URL.createObjectURL(blob);
               const link = document.createElement("a");
               link.setAttribute("href", encodedUri);
               link.setAttribute("download", `ChargeSync_Report_${new Date().toISOString().slice(0, 10)}.csv`);
               document.body.appendChild(link);
               link.click();
               document.body.removeChild(link);
            }}
            className="inline-flex items-center gap-space-xs rounded-xl bg-surface-container-lowest px-space-md py-space-xs font-label-md text-label-md text-on-surface shadow-sm transition-all hover:bg-surface-container"
          >
            <span className="material-symbols-outlined text-base">download</span>
            <span>Export Reports</span>
          </button>
          <button
            type="button"
            onClick={() => navigate('/stations/new')}
            className="inline-flex items-center gap-space-xs rounded-xl bg-gradient-to-r from-primary to-tertiary px-space-lg py-space-xs font-label-md text-label-md text-on-primary shadow-md transition-all hover:brightness-105"
          >
            <span className="material-symbols-outlined text-base">add_circle</span>
            <span>Add New Station</span>
          </button>
        </div>
      </div>
    </div>
  )
}
