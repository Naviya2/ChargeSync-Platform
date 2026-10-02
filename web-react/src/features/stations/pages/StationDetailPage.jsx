import { useParams, useNavigate } from 'react-router-dom'
import { ROUTES } from '../../../lib/constants'
import { useStationDetail } from '../hooks/useStations'
import StationDetailConsole from '../components/StationDetailConsole'

export default function StationDetailPage() {
  const { id } = useParams()
  const navigate = useNavigate()
  const { data: station, isLoading, error } = useStationDetail(id)

  if (isLoading) {
    return <div className="p-space-xl text-center">Loading station details...</div>
  }

  if (error || !station) {
    return (
      <div className="flex flex-col items-center justify-center p-space-3xl text-center">
        <p className="font-headline-sm text-headline-sm text-error">Failed to load station</p>
        <button
          onClick={() => navigate(ROUTES.STATIONS)}
          className="mt-space-md text-primary underline"
        >
          Back to Stations
        </button>
      </div>
    )
  }

  return (
    <div className="flex w-full flex-col gap-space-xl">
      <button
        onClick={() => navigate(ROUTES.STATIONS)}
        className="inline-flex items-center gap-space-2xs self-start font-label-md text-label-md text-on-surface-variant hover:text-primary"
      >
        <span className="material-symbols-outlined text-sm">arrow_back</span> Back to Stations
      </button>
      
      <StationDetailConsole station={station} />
    </div>
  )
}
