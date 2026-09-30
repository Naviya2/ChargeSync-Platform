import { useState, useEffect, useMemo } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { apiClient } from '../../../api/client'
import { useNotificationStore } from '../../../store/notificationStore'
import { useAuthStore } from '../../../store/authStore'

export default function AddReservationModal({ onClose }) {
  const [driverId, setDriverId] = useState('')
  const [vehicleId, setVehicleId] = useState('')
  const [stationId, setStationId] = useState('')
  const [chargerId, setChargerId] = useState('')
  const [date, setDate] = useState('')
  const [startTime, setStartTime] = useState('')
  
  const queryClient = useQueryClient()
  const notify = useNotificationStore(state => state.addNotification)
  const authUser = useAuthStore(state => state.user)

  // Fetch Drivers
  const { data: drivers = [] } = useQuery({
    queryKey: ['users'],
    queryFn: async () => {
      const res = await apiClient.get('/users')
      return res.data
    }
  })

  // Fetch Vehicles
  const { data: vehicles = [] } = useQuery({
    queryKey: ['vehicles', driverId],
    queryFn: async () => {
      const res = await apiClient.get(`/vehicles/user/${driverId}`)
      return res.data
    },
    enabled: !!driverId
  })

  // Fetch Stations
  const { data: stations = [] } = useQuery({
    queryKey: ['admin-stations', authUser?.role],
    queryFn: async () => {
      const endpoint = authUser?.role === 'Admin' ? '/stations/all' : '/stations'
      const res = await apiClient.get(endpoint)
      return res.data
    }
  })

  // Find chargers for selected station
  const selectedStation = stations.find(s => s.id === stationId)
  const chargers = selectedStation?.chargers || []
  const selectedCharger = chargers.find(c => c.id === chargerId)
  const selectedVehicle = vehicles.find(v => v.id === vehicleId)

  // Calculate dynamic duration like mobile app
  const durationMinutes = useMemo(() => {
    if (!selectedVehicle || !selectedCharger) return 60; // Default
    const effectivePowerKw = Math.min(selectedCharger.powerKw, selectedVehicle.maxChargeRateKw);
    if (effectivePowerKw <= 0) return 60;
    const hours = selectedVehicle.batteryCapacityKwh / effectivePowerKw;
    return Math.round(hours * 60);
  }, [selectedVehicle, selectedCharger]);

  // Fetch Available Slots
  const { data: availableSlots = [], isFetching: isSlotsLoading } = useQuery({
    queryKey: ['availability', chargerId, date, durationMinutes],
    queryFn: async () => {
      const res = await apiClient.get('/reservations/availability', {
        params: { chargerId, date, durationMinutes }
      })
      // The API returns either an array or { value: [...] } depending on standard response wrapping
      return Array.isArray(res.data) ? res.data : res.data?.value || []
    },
    enabled: !!chargerId && !!date && durationMinutes > 0
  })

  const createMutation = useMutation({
    mutationFn: async (payload) => {
      const res = await apiClient.post('/reservations/admin', payload)
      return res.data
    },
    onSuccess: () => {
      notify('success', 'Reservation Created Successfully', 'The reservation has been added on behalf of the driver.')
      queryClient.invalidateQueries({ queryKey: ['reservations'] })
      onClose()
    },
    onError: (error) => {
      notify('error', 'Creation Failed', error.response?.data?.message || 'Failed to create reservation')
    }
  })

  const handleSubmit = (e) => {
    e.preventDefault()
    if (!driverId || !chargerId || !startTime) return
    
    // Using the selected slot's full ISO start time
    const startDateTime = new Date(startTime)
    const endDateTime = new Date(startDateTime)
    endDateTime.setMinutes(endDateTime.getMinutes() + durationMinutes)

    createMutation.mutate({
      driverId,
      vehicleId: vehicleId || null,
      chargerId,
      startTime: startDateTime.toISOString(),
      endTime: endDateTime.toISOString()
    })
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm p-4">
      <div className="w-full max-w-lg rounded-2xl bg-surface-container-lowest p-space-lg shadow-xl overflow-y-auto max-h-[90vh]">
        <h2 className="text-xl font-bold text-on-surface mb-6">Add Reservation</h2>
        
        <form onSubmit={handleSubmit} className="flex flex-col gap-4">
          
          <div>
            <label className="block text-sm font-medium text-on-surface mb-1">Select Driver</label>
            <select 
              className="w-full rounded-lg bg-surface-container p-2 text-on-surface border border-outline"
              value={driverId}
              onChange={e => setDriverId(e.target.value)}
              required
            >
              <option value="">-- Select Driver --</option>
              {drivers.filter(d => d.role === 'Driver').map(d => (
                <option key={d.id} value={d.id}>{d.fullName} ({d.email})</option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-on-surface mb-1">Select Vehicle (Optional)</label>
            <select 
              className="w-full rounded-lg bg-surface-container p-2 text-on-surface border border-outline"
              value={vehicleId}
              onChange={e => setVehicleId(e.target.value)}
              disabled={!driverId}
            >
              <option value="">-- Walk-in / Unregistered --</option>
              {vehicles.map(v => (
                <option key={v.id} value={v.id}>{v.make} {v.model} ({v.licensePlate})</option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-on-surface mb-1">Select Station</label>
            <select 
              className="w-full rounded-lg bg-surface-container p-2 text-on-surface border border-outline"
              value={stationId}
              onChange={e => setStationId(e.target.value)}
              required
            >
              <option value="">-- Select Station --</option>
              {stations.map(s => (
                <option key={s.id} value={s.id}>{s.name}</option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-on-surface mb-1">Select Charger</label>
            <select 
              className="w-full rounded-lg bg-surface-container p-2 text-on-surface border border-outline"
              value={chargerId}
              onChange={e => setChargerId(e.target.value)}
              required
              disabled={!stationId}
            >
              <option value="">-- Select Charger --</option>
              {chargers.map(c => (
                <option key={c.id} value={c.id}>{c.bayLabel || c.identifier} ({c.powerKw}kW)</option>
              ))}
            </select>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-on-surface mb-1">Date</label>
              <input 
                type="date"
                className="w-full rounded-lg bg-surface-container p-2 text-on-surface border border-outline"
                value={date}
                onChange={e => {
                  setDate(e.target.value)
                  setStartTime('')
                }}
                required
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-on-surface mb-1">Estimated Charge Time</label>
              <div className="w-full rounded-lg bg-surface-container p-2 text-primary font-medium border border-outline">
                {selectedVehicle && selectedCharger ? `${durationMinutes} mins` : '-- mins'}
              </div>
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-on-surface mb-1">Select Available Time Slot</label>
            {isSlotsLoading ? (
              <div className="p-2 text-sm text-gray-500">Calculating available slots...</div>
            ) : availableSlots.length > 0 ? (
              <select 
                className="w-full rounded-lg bg-surface-container p-2 text-on-surface border border-outline"
                value={startTime}
                onChange={e => setStartTime(e.target.value)}
                required
              >
                <option value="">-- Choose a Time Slot --</option>
                {availableSlots.map(slot => {
                  const sTime = new Date(slot.startTime).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
                  const eTime = new Date(slot.endTime).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
                  return <option key={slot.startTime} value={slot.startTime}>{sTime} - {eTime}</option>
                })}
              </select>
            ) : date && chargerId ? (
              <div className="p-2 text-sm text-red-500">No available slots for this date/duration.</div>
            ) : (
              <div className="p-2 text-sm text-gray-500">Select charger, date, and duration to see slots.</div>
            )}
          </div>

          <div className="mt-4 flex justify-end gap-3">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 rounded-lg font-medium text-on-surface-variant hover:bg-surface-container transition-colors"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={createMutation.isPending}
              className="px-4 py-2 rounded-lg bg-primary text-on-primary font-medium hover:bg-primary/90 transition-colors disabled:opacity-50"
            >
              {createMutation.isPending ? 'Creating...' : 'Create Reservation'}
            </button>
          </div>

        </form>
      </div>
    </div>
  )
}
