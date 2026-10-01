import { useState } from 'react'
import { useVehicles, useCreateVehicle, useUpdateVehicle, useDeleteVehicle } from '../hooks/useVehicles'
import { useUsers } from '../../users/hooks/useUsers'
import PageHeader from '../../../components/shared/PageHeader'
import { Spinner } from '../../../components/ui'

const CONNECTOR_OPTIONS = [
  { value: 0, label: 'CCS2 (Combo 2)', icon: 'electrical_services' },
  { value: 1, label: 'Type 2 (Mennekes)', icon: 'electrical_services' },
  { value: 2, label: 'CHAdeMO', icon: 'electrical_services' },
  { value: 3, label: 'NACS (Tesla)', icon: 'electrical_services' },
  { value: 4, label: 'GB/T', icon: 'electrical_services' },
  { value: 5, label: 'MCS (Megawatt)', icon: 'electrical_services' },
]

const CONNECTOR_COLORS = {
  0: 'bg-blue-500/10 text-blue-400 border border-blue-500/20',
  1: 'bg-purple-500/10 text-purple-400 border border-purple-500/20',
  2: 'bg-orange-500/10 text-orange-400 border border-orange-500/20',
  3: 'bg-red-500/10 text-red-400 border border-red-500/20',
  4: 'bg-green-500/10 text-green-400 border border-green-500/20',
  5: 'bg-yellow-500/10 text-yellow-400 border border-yellow-500/20',
}

const DEFAULT_FORM = {
  make: '',
  model: '',
  licensePlate: '',
  connector: 0,
  batteryCapacityKwh: '',
  maxChargeRateKw: '',
}

function VehicleCard({ vehicle, ownerName, onEdit, onDelete }) {
  const connectorLabel = CONNECTOR_OPTIONS.find(c => c.value === vehicle.connector)?.label || vehicle.connector
  const connectorColor = CONNECTOR_COLORS[vehicle.connector] || 'bg-surface-container text-on-surface-variant border border-outline-variant'

  return (
    <div className="group relative overflow-hidden rounded-2xl bg-surface-container-lowest border border-outline-variant/50 shadow-sm hover:shadow-md hover:border-primary/30 transition-all duration-200">
      {/* Top gradient accent */}
      <div className="absolute inset-x-0 top-0 h-[2px] bg-gradient-to-r from-primary via-tertiary to-secondary opacity-60" />

      <div className="p-5">
        {/* Header Row */}
        <div className="flex items-start justify-between gap-3 mb-4">
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-primary/20 to-tertiary/10 border border-primary/20">
              <span className="material-symbols-outlined text-[22px] text-primary">directions_car</span>
            </div>
            <div>
              <h3 className="font-semibold text-on-surface text-base leading-tight">
                {vehicle.make} {vehicle.model}
              </h3>
              <p className="text-xs text-on-surface-variant mt-0.5">
                {vehicle.licensePlate || 'No plate registered'}
              </p>
            </div>
          </div>
          <div className="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
            <button
              onClick={() => onEdit(vehicle)}
              className="flex h-8 w-8 items-center justify-center rounded-lg text-on-surface-variant hover:bg-primary/10 hover:text-primary transition-colors"
              title="Edit vehicle"
            >
              <span className="material-symbols-outlined text-[18px]">edit</span>
            </button>
            <button
              onClick={() => onDelete(vehicle)}
              className="flex h-8 w-8 items-center justify-center rounded-lg text-on-surface-variant hover:bg-error/10 hover:text-error transition-colors"
              title="Delete vehicle"
            >
              <span className="material-symbols-outlined text-[18px]">delete</span>
            </button>
          </div>
        </div>

        {/* Stats Grid */}
        <div className="grid grid-cols-2 gap-2 mb-4">
          <div className="rounded-xl bg-surface-container p-3">
            <p className="text-[10px] font-semibold uppercase tracking-wider text-on-surface-variant mb-1">Battery</p>
            <div className="flex items-baseline gap-1">
              <span className="text-lg font-bold text-on-surface">{vehicle.batteryCapacityKwh}</span>
              <span className="text-xs text-on-surface-variant">kWh</span>
            </div>
          </div>
          <div className="rounded-xl bg-surface-container p-3">
            <p className="text-[10px] font-semibold uppercase tracking-wider text-on-surface-variant mb-1">Max Rate</p>
            <div className="flex items-baseline gap-1">
              <span className="text-lg font-bold text-on-surface">{vehicle.maxChargeRateKw}</span>
              <span className="text-xs text-on-surface-variant">kW</span>
            </div>
          </div>
        </div>

        {/* Connector & Owner */}
        <div className="space-y-2">
          <div className="flex items-center justify-between">
            <span className={`inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-xs font-medium ${connectorColor}`}>
              <span className="material-symbols-outlined text-[13px]">bolt</span>
              {connectorLabel}
            </span>
          </div>
          {ownerName && (
            <div className="flex items-center gap-2 pt-1 border-t border-outline-variant/40">
              <span className="material-symbols-outlined text-[14px] text-on-surface-variant">person</span>
              <span className="text-xs text-on-surface-variant truncate">{ownerName}</span>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

function VehicleFormModal({ editingVehicle, onClose, onSubmit, isSubmitting }) {
  const [form, setForm] = useState(
    editingVehicle
      ? {
          make: editingVehicle.make || '',
          model: editingVehicle.model || '',
          licensePlate: editingVehicle.licensePlate || '',
          connector: editingVehicle.connector ?? 0,
          batteryCapacityKwh: editingVehicle.batteryCapacityKwh || '',
          maxChargeRateKw: editingVehicle.maxChargeRateKw || '',
        }
      : DEFAULT_FORM
  )

  const field = (key) => ({
    value: form[key],
    onChange: (e) => setForm((prev) => ({ ...prev, [key]: e.target.value })),
  })

  const handleSubmit = (e) => {
    e.preventDefault()
    onSubmit({
      ...form,
      connector: Number(form.connector),
      batteryCapacityKwh: parseFloat(form.batteryCapacityKwh),
      maxChargeRateKw: parseFloat(form.maxChargeRateKw),
    })
  }

  const inputClass =
    'w-full rounded-xl border border-outline-variant bg-surface-container-lowest p-3 text-sm text-on-surface placeholder:text-on-surface-variant/50 focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary transition-colors'
  const labelClass = 'mb-1.5 block text-sm font-medium text-on-surface'

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4 backdrop-blur-sm">
      <div className="w-full max-w-xl rounded-2xl bg-surface-container-lowest shadow-2xl animate-in fade-in duration-200">
        {/* Header */}
        <div className="flex items-center justify-between border-b border-outline-variant/50 px-6 py-5">
          <div className="flex items-center gap-3">
            <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-gradient-to-br from-primary/20 to-tertiary/10">
              <span className="material-symbols-outlined text-xl text-primary">
                {editingVehicle ? 'edit' : 'directions_car'}
              </span>
            </div>
            <div>
              <h2 className="text-lg font-semibold text-on-surface">
                {editingVehicle ? 'Edit Vehicle' : 'Add New Vehicle'}
              </h2>
              <p className="text-xs text-on-surface-variant">
                {editingVehicle ? 'Update vehicle information' : 'Register a vehicle to the system'}
              </p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="flex h-8 w-8 items-center justify-center rounded-lg text-on-surface-variant hover:bg-surface-container hover:text-on-surface transition-colors"
          >
            <span className="material-symbols-outlined text-xl">close</span>
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          {/* Make & Model */}
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className={labelClass}>Make</label>
              <input required type="text" placeholder="e.g. Tesla" {...field('make')} className={inputClass} />
            </div>
            <div>
              <label className={labelClass}>Model</label>
              <input required type="text" placeholder="e.g. Model 3" {...field('model')} className={inputClass} />
            </div>
          </div>

          {/* License Plate */}
          <div>
            <label className={labelClass}>License Plate <span className="text-on-surface-variant font-normal">(Optional)</span></label>
            <input type="text" placeholder="e.g. ABC-1234" {...field('licensePlate')} className={inputClass} />
          </div>

          {/* Connector */}
          <div>
            <label className={labelClass}>Connector Type</label>
            <select
              value={form.connector}
              onChange={(e) => setForm((prev) => ({ ...prev, connector: Number(e.target.value) }))}
              className={inputClass}
            >
              {CONNECTOR_OPTIONS.map((opt) => (
                <option key={opt.value} value={opt.value}>{opt.label}</option>
              ))}
            </select>
          </div>

          {/* Battery & Charge Rate */}
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className={labelClass}>Battery Capacity (kWh)</label>
              <input
                required
                type="number"
                step="0.1"
                min="0"
                placeholder="e.g. 75"
                {...field('batteryCapacityKwh')}
                className={inputClass}
              />
            </div>
            <div>
              <label className={labelClass}>Max Charge Rate (kW)</label>
              <input
                required
                type="number"
                step="0.1"
                min="0"
                placeholder="e.g. 150"
                {...field('maxChargeRateKw')}
                className={inputClass}
              />
            </div>
          </div>

          {/* Footer Actions */}
          <div className="flex justify-end gap-3 pt-4 border-t border-outline-variant/50">
            <button
              type="button"
              onClick={onClose}
              className="rounded-xl px-5 py-2.5 text-sm font-medium text-on-surface-variant hover:bg-surface-container transition-colors"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={isSubmitting}
              className="inline-flex items-center gap-2 rounded-xl bg-gradient-to-r from-primary to-tertiary px-5 py-2.5 text-sm font-semibold text-on-primary shadow-sm hover:brightness-105 disabled:opacity-50 transition-all"
            >
              {isSubmitting && <span className="material-symbols-outlined animate-spin text-base">progress_activity</span>}
              {editingVehicle ? 'Save Changes' : 'Add Vehicle'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

function DeleteConfirmModal({ vehicle, onClose, onConfirm, isDeleting }) {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4 backdrop-blur-sm">
      <div className="w-full max-w-sm rounded-2xl bg-surface-container-lowest shadow-2xl">
        <div className="p-6">
          <div className="flex h-12 w-12 items-center justify-center rounded-full bg-error/10 mb-4">
            <span className="material-symbols-outlined text-2xl text-error">delete_forever</span>
          </div>
          <h3 className="text-lg font-semibold text-on-surface mb-1">Remove Vehicle?</h3>
          <p className="text-sm text-on-surface-variant mb-6">
            This will permanently remove <span className="font-medium text-on-surface">{vehicle.make} {vehicle.model}</span>
            {vehicle.licensePlate ? ` (${vehicle.licensePlate})` : ''} from the system. This action cannot be undone.
          </p>
          <div className="flex justify-end gap-3">
            <button
              onClick={onClose}
              className="rounded-xl px-5 py-2.5 text-sm font-medium text-on-surface-variant hover:bg-surface-container transition-colors"
            >
              Cancel
            </button>
            <button
              onClick={onConfirm}
              disabled={isDeleting}
              className="inline-flex items-center gap-2 rounded-xl bg-error px-5 py-2.5 text-sm font-semibold text-on-error hover:brightness-105 disabled:opacity-50 transition-all"
            >
              {isDeleting && <span className="material-symbols-outlined animate-spin text-base">progress_activity</span>}
              Yes, Remove
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}

export default function VehiclesPage() {
  const { data: vehicles = [], isLoading: isVehiclesLoading } = useVehicles()
  const { data: users = [], isLoading: isUsersLoading } = useUsers()
  const createVehicle = useCreateVehicle()
  const updateVehicle = useUpdateVehicle()
  const deleteVehicle = useDeleteVehicle()

  const [isModalOpen, setIsModalOpen] = useState(false)
  const [editingVehicle, setEditingVehicle] = useState(null)
  const [deletingVehicle, setDeletingVehicle] = useState(null)
  const [searchQuery, setSearchQuery] = useState('')
  const [filterConnector, setFilterConnector] = useState('all')

  const isLoading = isVehiclesLoading || isUsersLoading

  const userMap = users.reduce((acc, u) => {
    acc[u.id] = u.fullName || u.email || 'Unknown'
    return acc
  }, {})

  const filtered = vehicles.filter((v) => {
    const q = searchQuery.toLowerCase()
    const matchesSearch =
      !q ||
      v.make?.toLowerCase().includes(q) ||
      v.model?.toLowerCase().includes(q) ||
      v.licensePlate?.toLowerCase().includes(q) ||
      userMap[v.ownerId]?.toLowerCase().includes(q)
    const matchesConnector = filterConnector === 'all' || String(v.connector) === filterConnector
    return matchesSearch && matchesConnector
  })

  const openCreate = () => {
    setEditingVehicle(null)
    setIsModalOpen(true)
  }

  const openEdit = (vehicle) => {
    setEditingVehicle(vehicle)
    setIsModalOpen(true)
  }

  const handleFormSubmit = (data) => {
    if (editingVehicle) {
      updateVehicle.mutate({ id: editingVehicle.id, ...data }, { onSuccess: () => setIsModalOpen(false) })
    } else {
      createVehicle.mutate(data, { onSuccess: () => setIsModalOpen(false) })
    }
  }

  const handleDeleteConfirm = () => {
    deleteVehicle.mutate(deletingVehicle.id, { onSuccess: () => setDeletingVehicle(null) })
  }

  return (
    <div className="flex w-full flex-col gap-6">
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-on-surface">Vehicle Management</h1>
          <p className="mt-1 text-sm text-on-surface-variant">
            Manage all registered driver vehicles in the platform.
          </p>
        </div>
        <button
          onClick={openCreate}
          className="inline-flex items-center gap-2 rounded-xl bg-gradient-to-r from-primary to-tertiary px-5 py-2.5 font-semibold text-sm text-on-primary shadow-md hover:brightness-105 transition-all"
        >
          <span className="material-symbols-outlined text-base">add</span>
          Add Vehicle
        </button>
      </div>

      {/* Stats Bar */}
      {!isLoading && (
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
          {[
            {
              label: 'Total Vehicles',
              value: vehicles.length,
              icon: 'directions_car',
              color: 'text-primary',
              bg: 'bg-primary/10',
            },
            {
              label: 'Unique Owners',
              value: new Set(vehicles.map((v) => v.ownerId)).size,
              icon: 'group',
              color: 'text-secondary',
              bg: 'bg-secondary/10',
            },
            {
              label: 'DC Fast Charge',
              value: vehicles.filter((v) => [0, 2, 3].includes(v.connector)).length,
              icon: 'bolt',
              color: 'text-tertiary',
              bg: 'bg-tertiary/10',
            },
            {
              label: 'AC Charge',
              value: vehicles.filter((v) => [1, 4, 5].includes(v.connector)).length,
              icon: 'electrical_services',
              color: 'text-on-surface-variant',
              bg: 'bg-surface-container',
            },
          ].map((stat) => (
            <div
              key={stat.label}
              className="flex items-center gap-3 rounded-xl bg-surface-container-lowest border border-outline-variant/50 p-4"
            >
              <div className={`flex h-9 w-9 items-center justify-center rounded-xl ${stat.bg}`}>
                <span className={`material-symbols-outlined text-[20px] ${stat.color}`}>{stat.icon}</span>
              </div>
              <div>
                <p className="text-[10px] font-semibold uppercase tracking-wider text-on-surface-variant">{stat.label}</p>
                <p className="text-xl font-bold text-on-surface">{stat.value}</p>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-3">
        <div className="relative flex-1">
          <span className="absolute left-3 top-1/2 -translate-y-1/2 material-symbols-outlined text-[18px] text-on-surface-variant">
            search
          </span>
          <input
            type="text"
            placeholder="Search by make, model, plate or owner..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full rounded-xl border border-outline-variant bg-surface-container-lowest py-2.5 pl-10 pr-4 text-sm text-on-surface placeholder:text-on-surface-variant/60 focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary transition-colors"
          />
        </div>
        <select
          value={filterConnector}
          onChange={(e) => setFilterConnector(e.target.value)}
          className="rounded-xl border border-outline-variant bg-surface-container-lowest py-2.5 px-4 text-sm text-on-surface focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary transition-colors"
        >
          <option value="all">All Connectors</option>
          {CONNECTOR_OPTIONS.map((c) => (
            <option key={c.value} value={String(c.value)}>{c.label}</option>
          ))}
        </select>
      </div>

      {/* Content */}
      {isLoading ? (
        <div className="flex flex-col items-center justify-center py-24">
          <Spinner />
          <p className="mt-3 text-sm text-on-surface-variant">Loading vehicles...</p>
        </div>
      ) : filtered.length === 0 ? (
        <div className="flex flex-col items-center justify-center rounded-2xl bg-surface-container-lowest border border-outline-variant/50 py-24 px-8 text-center">
          <div className="flex h-16 w-16 items-center justify-center rounded-2xl bg-surface-container mb-4">
            <span className="material-symbols-outlined text-4xl text-on-surface-variant">directions_car</span>
          </div>
          <h3 className="text-lg font-semibold text-on-surface">No vehicles found</h3>
          <p className="mt-1 text-sm text-on-surface-variant max-w-xs">
            {searchQuery || filterConnector !== 'all'
              ? 'No vehicles match your current filters. Try adjusting your search.'
              : 'No vehicles have been registered yet. Add the first vehicle to get started.'}
          </p>
          {!searchQuery && filterConnector === 'all' && (
            <button
              onClick={openCreate}
              className="mt-5 inline-flex items-center gap-2 rounded-xl bg-primary px-5 py-2.5 text-sm font-semibold text-on-primary hover:brightness-105 transition-all"
            >
              <span className="material-symbols-outlined text-base">add</span>
              Add First Vehicle
            </button>
          )}
        </div>
      ) : (
        <>
          <p className="text-xs text-on-surface-variant -mt-2">
            Showing {filtered.length} of {vehicles.length} vehicle{vehicles.length !== 1 ? 's' : ''}
          </p>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
            {filtered.map((vehicle) => (
              <VehicleCard
                key={vehicle.id}
                vehicle={vehicle}
                ownerName={userMap[vehicle.ownerId]}
                onEdit={openEdit}
                onDelete={setDeletingVehicle}
              />
            ))}
          </div>
        </>
      )}

      {/* Form Modal */}
      {isModalOpen && (
        <VehicleFormModal
          editingVehicle={editingVehicle}
          onClose={() => setIsModalOpen(false)}
          onSubmit={handleFormSubmit}
          isSubmitting={createVehicle.isPending || updateVehicle.isPending}
        />
      )}

      {/* Delete Confirm Modal */}
      {deletingVehicle && (
        <DeleteConfirmModal
          vehicle={deletingVehicle}
          onClose={() => setDeletingVehicle(null)}
          onConfirm={handleDeleteConfirm}
          isDeleting={deleteVehicle.isPending}
        />
      )}
    </div>
  )
}
