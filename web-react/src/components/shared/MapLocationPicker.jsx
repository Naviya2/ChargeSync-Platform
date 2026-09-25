import { useMemo, useRef, useState, useEffect } from 'react'
import { MapContainer, TileLayer, Marker, useMapEvents, useMap } from 'react-leaflet'
import 'leaflet/dist/leaflet.css'
import L from 'leaflet'
import { cn } from '../../lib/cn'

delete L.Icon.Default.prototype._getIconUrl
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png',
  iconUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
  shadowUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
})

const defaultCenter = { lat: 6.9271, lng: 79.8612 }

function MapUpdater({ trigger }) {
  const map = useMap()
  useEffect(() => {
    if (trigger) {
      map.flyTo(trigger, 15, { animate: true, duration: 1.5 })
    }
  }, [trigger, map])
  return null
}

function LocationMarker({ position, onLocationChange }) {
  const markerRef = useRef(null)

  useMapEvents({
    click(e) {
      if (onLocationChange) {
        onLocationChange(e.latlng.lat, e.latlng.lng)
      }
    },
  })

  const eventHandlers = useMemo(
    () => ({
      dragend() {
        const marker = markerRef.current
        if (marker != null) {
          const latLng = marker.getLatLng()
          if (onLocationChange) {
            onLocationChange(latLng.lat, latLng.lng)
          }
        }
      },
    }),
    [onLocationChange]
  )

  if (!position) return null

  return (
    <Marker
      draggable={true}
      eventHandlers={eventHandlers}
      position={position}
      ref={markerRef}
    />
  )
}

export default function MapLocationPicker({
  latitude,
  longitude,
  onLocationChange,
  onAddressFetched,
  className
}) {
  const [searchQuery, setSearchQuery] = useState('')
  const [isSearching, setIsSearching] = useState(false)
  const [errorMsg, setErrorMsg] = useState('')
  const [flyToTrigger, setFlyToTrigger] = useState(null)

  const hasLocation = latitude !== '' && longitude !== '' && latitude != null && !isNaN(latitude) && !isNaN(longitude)
  const markerPosition = hasLocation
    ? { lat: parseFloat(latitude), lng: parseFloat(longitude) }
    : null

  const updateLocation = async (lat, lon, knownAddress = null) => {
    if (onLocationChange) onLocationChange(lat, lon)
    
    if (onAddressFetched) {
      if (knownAddress) {
        onAddressFetched(knownAddress)
      } else {
        try {
          const response = await fetch(`https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lon}`)
          const data = await response.json()
          if (data && data.display_name) {
            onAddressFetched(data.display_name)
          }
        } catch (err) {
          console.error("Failed to reverse geocode:", err)
        }
      }
    }
  }

  const handleSearch = async (e) => {
    if (e && e.preventDefault) e.preventDefault()
    if (!searchQuery.trim()) return
    
    setIsSearching(true)
    setErrorMsg('')
    
    try {
      const response = await fetch(`https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(searchQuery)}`)
      const data = await response.json()
      
      if (data && data.length > 0) {
        const lat = parseFloat(data[0].lat)
        const lon = parseFloat(data[0].lon)
        updateLocation(lat, lon, data[0].display_name)
        setFlyToTrigger({ lat, lng: lon, timestamp: Date.now() })
      } else {
        setErrorMsg('Location not found.')
      }
    } catch (err) {
      setErrorMsg('Search failed. Try again.')
    } finally {
      setIsSearching(false)
    }
  }

  const handleKeyDown = (e) => {
    if (e.key === 'Enter') {
      e.preventDefault()
      handleSearch(e)
    }
  }

  const handleLocateMe = () => {
    if ('geolocation' in navigator) {
      setIsSearching(true)
      setErrorMsg('')
      navigator.geolocation.getCurrentPosition(
        (position) => {
          const lat = position.coords.latitude
          const lon = position.coords.longitude
          updateLocation(lat, lon)
          setFlyToTrigger({ lat, lng: lon, timestamp: Date.now() })
          setIsSearching(false)
        },
        (error) => {
          setErrorMsg('Failed to get current location.')
          setIsSearching(false)
        },
        { enableHighAccuracy: true, timeout: 5000, maximumAge: 0 }
      )
    } else {
      setErrorMsg('Geolocation not supported by browser.')
    }
  }

  return (
    <div className={cn('flex flex-col gap-space-2xs', className)}>
      <div className="flex flex-col gap-space-xs sm:flex-row sm:items-center justify-between">
        <label className="font-label-md text-label-md text-on-surface">
          Station Location (Pin)
        </label>
        
        <div className="flex gap-space-2xs items-center">
          <input
            type="text"
            placeholder="Search address or city"
            className="w-full sm:w-[220px] rounded border border-outline bg-surface px-space-sm py-1.5 text-on-surface text-sm focus:outline-primary"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            onKeyDown={handleKeyDown}
          />
          <button
            type="button"
            onClick={handleSearch}
            disabled={isSearching}
            className="rounded bg-primary px-space-sm py-1.5 text-sm font-medium text-on-primary hover:bg-primary/90 disabled:opacity-50 transition-colors"
          >
            {isSearching ? '...' : 'Search'}
          </button>
          <button
            type="button"
            onClick={handleLocateMe}
            disabled={isSearching}
            title="Use Current Location"
            className="rounded border border-outline bg-surface-container-low p-1.5 text-on-surface-variant hover:text-primary hover:bg-surface disabled:opacity-50 transition-colors flex items-center justify-center"
          >
            <span className="material-symbols-outlined text-[20px]">my_location</span>
          </button>
        </div>
      </div>

      {errorMsg && <span className="text-error font-body-xs">{errorMsg}</span>}

      <div className="rounded-lg overflow-hidden border border-outline relative shadow-sm h-[300px] z-0">
        <MapContainer
          center={markerPosition || defaultCenter}
          zoom={hasLocation ? 15 : 12}
          scrollWheelZoom={true}
          style={{ height: '100%', width: '100%' }}
        >
          <TileLayer
            attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
            url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
          />
          <LocationMarker position={markerPosition} onLocationChange={updateLocation} />
          {flyToTrigger && <MapUpdater trigger={flyToTrigger} />}
        </MapContainer>
        {!hasLocation && (
          <div className="absolute top-2 left-2 z-[400] bg-surface/90 px-space-sm py-space-2xs rounded border border-outline text-xs text-on-surface backdrop-blur-sm shadow-sm pointer-events-none">
            Click map to set initial pin
          </div>
        )}
      </div>
      
      <div className="flex justify-between font-body-xs text-on-surface-variant">
        <span>
          {hasLocation 
            ? `Lat: ${markerPosition.lat.toFixed(5)}, Lng: ${markerPosition.lng.toFixed(5)}` 
            : 'No coordinates selected'
          }
        </span>
        <span className="hidden sm:inline">Click map or drag pin to adjust</span>
      </div>
    </div>
  )
}