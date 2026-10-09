import { useState } from 'react'
import { useBays, useAddBay, useUpdateBay, useDeleteBay } from '../../hooks/useStations'
import useDialogStore from '../../../../store/dialogStore'

function BayItem({ bay, stationId }) {
  const [isEditing, setIsEditing] = useState(false)
  const [name, setName] = useState(bay.name || '')
  
  const updateBay = useUpdateBay()
  const deleteBay = useDeleteBay()

  const handleUpdate = (e) => {
    e.preventDefault()
    updateBay.mutate(
      { stationId, bayId: bay.id, data: { name } },
      {
        onSuccess: () => setIsEditing(false),
        onError: () => useDialogStore.getState().alert({ title: 'Error', message: 'Failed to update bay.', variant: 'danger' })
      }
    )
  }

  const handleDelete = async () => {
    const ok = await useDialogStore.getState().confirm({
      title: 'Delete Bay',
      message: 'Are you sure you want to delete this bay?',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      variant: 'danger',
    })
    if (ok) {
      deleteBay.mutate(
        { stationId, bayId: bay.id },
        { onError: () => useDialogStore.getState().alert({ title: 'Error', message: 'Failed to delete bay.', variant: 'danger' }) }
      )
    }
  }

  if (isEditing) {
    return (
      <form onSubmit={handleUpdate} className="flex items-center gap-space-sm p-space-sm bg-surface-container-low rounded-lg">
        <input
          type="text"
          required
          className="flex-1 rounded border border-outline bg-surface px-space-sm py-space-2xs text-on-surface"
          value={name}
          onChange={(e) => setName(e.target.value)}
        />
        <button type="submit" disabled={updateBay.isPending} className="text-primary font-semibold text-sm">Save</button>
        <button type="button" onClick={() => setIsEditing(false)} className="text-on-surface-variant text-sm">Cancel</button>
      </form>
    )
  }

  return (
    <div className="flex items-center justify-between p-space-sm bg-surface-container-low rounded-lg">
      <span className="font-headline-sm text-headline-sm text-on-surface">{bay.name}</span>
      <div className="flex items-center gap-space-sm">
        <button type="button" onClick={() => setIsEditing(true)} className="text-on-surface-variant hover:text-primary">
          <span className="material-symbols-outlined text-lg">edit</span>
        </button>
        <button type="button" onClick={handleDelete} disabled={deleteBay.isPending} className="text-on-surface-variant hover:text-error">
          <span className="material-symbols-outlined text-lg">delete</span>
        </button>
      </div>
    </div>
  )
}

export default function BaysTab({ stationId }) {
  const { data: bays = [], isLoading } = useBays(stationId)
  const addBay = useAddBay()
  const [showAddForm, setShowAddForm] = useState(false)
  const [newBayName, setNewBayName] = useState('')

  const handleAddSubmit = (e) => {
    e.preventDefault()
    addBay.mutate(
      { stationId, data: { name: newBayName } },
      {
        onSuccess: () => {
          setShowAddForm(false)
          setNewBayName('')
        },
        onError: () => useDialogStore.getState().alert({ title: 'Error', message: 'Failed to add bay.', variant: 'danger' })
      }
    )
  }

  if (isLoading) {
    return <div className="p-space-lg text-center text-on-surface-variant">Loading bays...</div>
  }

  return (
    <div className="flex flex-col gap-space-md">
      <div className="flex items-center justify-between">
        <h3 className="font-headline-sm text-headline-sm text-on-surface">Station Bays ({bays.length})</h3>
        <button
          type="button"
          onClick={() => setShowAddForm(!showAddForm)}
          className="inline-flex items-center gap-space-2xs rounded-lg bg-primary px-space-md py-space-2xs font-headline-sm text-headline-sm text-on-primary shadow-sm hover:bg-primary-container"
        >
          <span className="material-symbols-outlined text-sm">{showAddForm ? 'close' : 'add'}</span> 
          {showAddForm ? 'Cancel' : 'Add Bay'}
        </button>
      </div>

      {showAddForm && (
        <form onSubmit={handleAddSubmit} className="bg-surface-container-low p-space-lg rounded-xl shadow-sm">
          <h4 className="font-headline-sm text-headline-sm text-on-surface mb-space-md">Create New Bay</h4>
          <div className="flex flex-col gap-space-2xs mb-space-md">
            <label className="font-label-sm text-label-sm text-on-surface">Bay Name / Label</label>
            <input
              type="text"
              required
              placeholder="e.g. Bay 1"
              className="rounded border border-outline bg-surface px-space-md py-space-sm text-on-surface"
              value={newBayName}
              onChange={(e) => setNewBayName(e.target.value)}
            />
          </div>
          <div className="flex justify-end">
            <button
              type="submit"
              disabled={addBay.isPending}
              className="rounded-lg bg-primary px-space-lg py-space-sm font-label-md text-label-md text-on-primary hover:bg-primary/90"
            >
              {addBay.isPending ? 'Saving...' : 'Save Bay'}
            </button>
          </div>
        </form>
      )}

      <div className="flex flex-col gap-space-xs">
        {bays.length === 0 && !showAddForm ? (
          <div className="p-space-xl text-center text-on-surface-variant bg-surface-container-low rounded-xl">
            No bays configured for this station.
          </div>
        ) : (
          bays.map((bay) => <BayItem key={bay.id} bay={bay} stationId={stationId} />)
        )}
      </div>
    </div>
  )
}
