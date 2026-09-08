import StationCard from './StationCard'

/**
 * @param {{ stations: object[], selectedId: string, onSelect: (id: string) => void }} props
 */
export default function StationCardGrid({ stations, selectedId, onSelect }) {
  if (stations.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center gap-space-sm rounded-xl bg-surface-container-lowest p-space-3xl text-center shadow-sm">
        <span className="material-symbols-outlined text-3xl text-outline">ev_station</span>
        <p className="font-headline-sm text-headline-sm text-on-surface">No stations match this filter</p>
        <p className="font-body-sm text-body-sm text-on-surface-variant">
          Try a different status or clear your search.
        </p>
      </div>
    )
  }

  return (
    <div className="grid grid-cols-1 gap-space-lg md:grid-cols-2 lg:grid-cols-3">
      {stations.map((station) => (
        <StationCard
          key={station.id}
          station={station}
          selected={station.id === selectedId}
          onSelect={onSelect}
        />
      ))}
    </div>
  )
}
