import { useState } from 'react'
import { cn } from '../../../../lib/cn'
import { useAddCharger, useUpdateCharger, useDeleteCharger } from '../../hooks/useStations'

const STATE_STYLE = {
  dispensing: { cls: 'bg-secondary/10 text-secondary', dot: 'bg-secondary animate-pulse' },
  available: { cls: 'bg-tertiary/10 text-tertiary', dot: 'bg-tertiary' },
  reserved: { cls: 'bg-surface-container-high text-on-surface', dot: 'bg-secondary' },
}

function ChargerState({ state, label }) {
  const style = STATE_STYLE[state] ?? STATE_STYLE.available
  return (
    <span
      className={cn(
        'inline-flex items-center gap-1.5 rounded-lg px-space-xs py-space-2xs font-label-sm text-label-sm font-semibold',
        style.cls,
      )}
    >
      <span className={cn('h-2 w-2 rounded-full', style.dot)} />
      {label}
    </span>
  )
}

export default function ChargersTab({ stationId, chargers }) {
  const [showAddForm, setShowAddForm] = useState(false)
  const [editingChargerId, setEditingChargerId] = useState(null)
  
  const addCharger = useAddCharger()
  const updateCharger = useUpdateCharger()
  const deleteCharger = useDeleteCharger()

  const [form, setForm] = useState({
    identifier: '',
    bayLabel: '',
    connectorTypeId: 'CCS2',
    maxOutputKw: 150,
    pricePerKwh: 0.50,
    status: 'available'
  })

  const handleSubmit = (e) => {
    e.preventDefault()
    const payload = {
      Identifier: form.identifier,
      BayLabel: form.bayLabel,
      Connector: form.connectorTypeId,
      PowerKw: form.maxOutputKw,
      Tariff: form.pricePerKwh,
    }
    
    if (editingChargerId) {
      updateCharger.mutate(
        { stationId, chargerId: editingChargerId, data: payload },
        {
          onSuccess: () => {
            setShowAddForm(false)
            setEditingChargerId(null)
          },
          onError: (err) => {
            console.error(err)
            alert('Failed to update charger')
          }
        }
      )
    } else {
      addCharger.mutate(
        { stationId, data: payload },
        {
          onSuccess: () => {
            setShowAddForm(false)
          },
          onError: (err) => {
            console.error(err)
            alert('Failed to add charger')
          }
        }
      )
    }
  }

  const handleEdit = (ch) => {
    setForm({
      identifier: ch.identifier || '',
      bayLabel: ch.bayLabel || '',
      connectorTypeId: ch.connectorTypeId || ch.connector || 'CCS2',
      maxOutputKw: ch.powerKw || ch.maxOutputKw || ch.power || 150,
      pricePerKwh: ch.tariff || ch.pricePerKwh || 0.50,
      status: ch.status || 'available'
    })
    setEditingChargerId(ch.id)
    setShowAddForm(true)
  }

  const handleDelete = (ch) => {
    if (window.confirm(`Are you sure you want to delete charger ${ch.identifier}?`)) {
      deleteCharger.mutate(
        { stationId, chargerId: ch.id },
        {
          onError: () => alert('Failed to delete charger')
        }
      )
    }
  }

  return (
    <div className="flex flex-col gap-space-md">
      <div className="flex flex-col items-stretch justify-between gap-space-sm sm:flex-row sm:items-center">
        <div className="flex items-center gap-space-sm">
          <h3 className="font-headline-sm text-headline-sm text-on-surface">
            Configured Chargers ({chargers.length} Physical Units)
          </h3>
          <span className="rounded bg-surface-container px-space-xs py-space-2xs font-label-sm text-label-sm text-on-surface-variant">
            OCPP 2.0.1 Compliant
          </span>
        </div>
        <button
          type="button"
          onClick={() => {
            if (showAddForm) {
              setShowAddForm(false)
              setEditingChargerId(null)
            } else {
              setForm({
                identifier: '',
                bayLabel: '',
                connectorTypeId: 'CCS2',
                maxOutputKw: 150,
                pricePerKwh: 0.50,
                status: 'available'
              })
              setEditingChargerId(null)
              setShowAddForm(true)
            }
          }}
          className="inline-flex items-center gap-space-2xs self-start rounded-lg bg-primary px-space-md py-space-2xs font-headline-sm text-headline-sm text-on-primary shadow-sm transition-all hover:bg-primary-container"
        >
          <span className="material-symbols-outlined text-sm">{showAddForm ? 'close' : 'add'}</span> 
          {showAddForm ? 'Cancel' : 'Add Charger'}
        </button>
      </div>

      {showAddForm && (
        <form onSubmit={handleSubmit} className="bg-surface-container-low p-space-lg rounded-xl shadow-sm mb-space-md">
          <h4 className="font-headline-sm text-headline-sm text-on-surface mb-space-md">
            {editingChargerId ? 'Edit Charger' : 'Register New Charger'}
          </h4>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-space-md">
            <div className="flex flex-col gap-space-2xs">
              <label className="font-label-sm text-label-sm text-on-surface">Identifier (e.g. CH-01)</label>
              <input
                type="text"
                required
                className="rounded border border-outline bg-surface px-space-md py-space-sm text-on-surface"
                value={form.identifier}
                onChange={(e) => setForm({ ...form, identifier: e.target.value })}
              />
            </div>
            <div className="flex flex-col gap-space-2xs">
              <label className="font-label-sm text-label-sm text-on-surface">Bay Label (e.g. Bay 1)</label>
              <input
                type="text"
                required
                className="rounded border border-outline bg-surface px-space-md py-space-sm text-on-surface"
                value={form.bayLabel}
                onChange={(e) => setForm({ ...form, bayLabel: e.target.value })}
              />
            </div>
            <div className="flex flex-col gap-space-2xs">
              <label className="font-label-sm text-label-sm text-on-surface">Connector Type</label>
              <select
                className="rounded border border-outline bg-surface px-space-md py-space-sm text-on-surface"
                value={form.connectorTypeId}
                onChange={(e) => setForm({ ...form, connectorTypeId: e.target.value })}
              >
                <option value="CCS2">CCS2</option>
                <option value="CCS1">CCS1</option>
                <option value="CHADEMO">CHAdeMO</option>
                <option value="TYPE2">Type 2</option>
              </select>
            </div>
            <div className="flex flex-col gap-space-2xs">
              <label className="font-label-sm text-label-sm text-on-surface">Max Output (kW)</label>
              <input
                type="number"
                required
                className="rounded border border-outline bg-surface px-space-md py-space-sm text-on-surface"
                value={form.maxOutputKw}
                onChange={(e) => setForm({ ...form, maxOutputKw: parseFloat(e.target.value) })}
              />
            </div>
            <div className="flex flex-col gap-space-2xs">
              <label className="font-label-sm text-label-sm text-on-surface">Price per kWh ($)</label>
              <input
                type="number"
                step="0.01"
                required
                className="rounded border border-outline bg-surface px-space-md py-space-sm text-on-surface"
                value={form.pricePerKwh}
                onChange={(e) => setForm({ ...form, pricePerKwh: parseFloat(e.target.value) })}
              />
            </div>
            <div className="flex flex-col gap-space-2xs">
              <label className="font-label-sm text-label-sm text-on-surface">Initial Status</label>
              <select
                className="rounded border border-outline bg-surface px-space-md py-space-sm text-on-surface"
                value={form.status}
                onChange={(e) => setForm({ ...form, status: e.target.value })}
              >
                <option value="available">Available</option>
                <option value="maintenance">Maintenance</option>
                <option value="offline">Offline</option>
              </select>
            </div>
          </div>
          <div className="mt-space-lg flex justify-end">
            <button
              type="submit"
              disabled={addCharger.isPending || updateCharger.isPending}
              className="rounded-lg bg-primary px-space-lg py-space-sm font-label-md text-label-md text-on-primary transition-colors hover:bg-primary/90"
            >
              {addCharger.isPending || updateCharger.isPending ? 'Saving...' : 'Save Charger'}
            </button>
          </div>
        </form>
      )}

      <div className="overflow-x-auto rounded-xl bg-surface-container-lowest">
        <table className="w-full text-left font-body-md text-body-md">
          <thead className="bg-surface-container-low font-label-sm text-label-sm uppercase tracking-wider text-on-surface-variant">
            <tr>
              <th className="px-space-md py-space-sm">Charger ID</th>
              <th className="px-space-md py-space-sm">Connector Type</th>
              <th className="px-space-md py-space-sm">Max Output</th>
              <th className="px-space-md py-space-sm">Tariff</th>
              <th className="px-space-md py-space-sm">Current State</th>
              <th className="px-space-md py-space-sm text-right">Actions</th>
            </tr>
          </thead>
          <tbody className="text-on-surface">
            {chargers.map((ch) => (
              <tr key={ch.id} className="transition-colors hover:bg-surface-container-low/70">
                <td className="px-space-md py-space-sm font-headline-sm text-headline-sm font-semibold">
                  {ch.identifier || ch.id}
                </td>
                <td className="px-space-md py-space-sm">
                  <span className="inline-flex items-center rounded bg-surface-container px-space-xs py-space-2xs font-label-md text-label-md font-semibold text-on-surface">
                    {ch.connectorTypeId || ch.connector}
                  </span>
                </td>
                <td className="px-space-md py-space-sm font-headline-sm text-headline-sm font-semibold">
                  {ch.powerKw || ch.maxOutputKw || ch.power} kW
                </td>
                <td className="px-space-md py-space-sm font-body-sm text-body-sm">
                  <span className="font-semibold text-on-surface">${ch.tariff || ch.pricePerKwh || '0.00'} / kWh</span>
                </td>
                <td className="px-space-md py-space-sm">
                  <ChargerState state={ch.status?.toLowerCase() || ch.state} label={ch.status || ch.stateLabel || 'Available'} />
                </td>
                <td className="px-space-md py-space-sm text-right">
                  <div className="flex justify-end gap-space-md">
                    <button
                      type="button"
                      onClick={() => handleEdit(ch)}
                      className="rounded p-space-2xs text-on-surface-variant hover:bg-surface-container-high hover:text-primary transition-colors"
                      title="Edit Charger"
                    >
                      <span className="material-symbols-outlined text-xl">edit</span>
                    </button>
                    <button
                      type="button"
                      onClick={() => handleDelete(ch)}
                      disabled={deleteCharger.isPending}
                      className="rounded p-space-2xs text-on-surface-variant hover:bg-error-container hover:text-error transition-colors disabled:opacity-50"
                      title="Delete Charger"
                    >
                      <span className="material-symbols-outlined text-xl">delete</span>
                    </button>
                  </div>
                </td>
              </tr>
            ))}
            {chargers.length === 0 && (
              <tr>
                <td colSpan="6" className="p-space-lg text-center text-on-surface-variant">No chargers registered yet.</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  )
}
