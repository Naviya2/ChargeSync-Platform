import { useParams, Link } from 'react-router-dom'
import { useStationDetail } from '../hooks/useStations'

export default function PendingStationPage() {
  const { id } = useParams()
  const { data: station, isLoading } = useStationDetail(id)

  if (isLoading) {
    return (
      <div className="flex h-full min-h-[50vh] items-center justify-center">
        <p className="font-body-md text-on-surface-variant">Loading station data...</p>
      </div>
    )
  }

  if (!station) {
    return (
      <div className="flex h-full min-h-[50vh] items-center justify-center">
        <p className="font-body-md text-error">Station not found.</p>
      </div>
    )
  }

  return (
    <div className="mx-auto flex max-w-2xl flex-col items-center justify-center gap-space-lg p-space-2xl text-center mt-space-3xl">
      <div className="rounded-full bg-secondary-container p-space-xl text-on-secondary-container mb-space-md">
        <span className="material-symbols-outlined text-6xl">hourglass_empty</span>
      </div>
      
      <h1 className="font-display-sm text-display-sm text-on-surface">
        Station Approval Pending
      </h1>
      
      <p className="font-body-lg text-body-lg text-on-surface-variant">
        Your station <strong className="text-on-surface">{station.name}</strong> is currently being reviewed by our compliance team.
      </p>
      
      <div className="rounded-xl bg-surface-container p-space-lg text-left w-full mt-space-md shadow-sm">
        <h3 className="font-headline-sm text-headline-sm text-on-surface mb-space-sm flex items-center gap-2">
          <span className="material-symbols-outlined text-primary">info</span> What happens next?
        </h3>
        <ul className="list-disc pl-space-xl font-body-md text-body-md text-on-surface-variant flex flex-col gap-space-xs">
          <li>Our team will verify the location details and utility capacity.</li>
          <li>We will review the provided documentation for compliance.</li>
          <li>You will receive an email notification once the station is approved.</li>
          <li>Once approved, you can access the full station control console to configure chargers and operating hours.</li>
        </ul>
      </div>

      <div className="mt-space-lg">
        <Link
          to="/"
          className="inline-flex items-center gap-space-sm rounded-lg bg-primary px-space-xl py-space-md font-label-lg text-label-lg text-on-primary transition-colors hover:bg-primary/90"
        >
          <span className="material-symbols-outlined">arrow_back</span>
          Return to Dashboard
        </Link>
      </div>
    </div>
  )
}
