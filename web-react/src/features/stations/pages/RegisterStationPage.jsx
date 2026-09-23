import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { ROUTES } from '../../../lib/constants'
import { useRegisterStation } from '../hooks/useStations'

export default function RegisterStationPage() {
    const navigate = useNavigate()
    const registerMutation = useRegisterStation()

    const [form, setForm] = useState({
        name: '',
        address: '',
        latitude: '',
        longitude: '',
    })

    const [error, setError] = useState(null)

    const handleSubmit = (e) => {
        e.preventDefault()
        setError(null)

        const lat = parseFloat(form.latitude)
        const lng = parseFloat(form.longitude)

        if (!form.name || !form.address) {
            setError('Name and address are required.')
            return
        }

        if (isNaN(lat) || isNaN(lng)) {
            setError('Latitude and Longitude must be valid numbers.')
            return
        }

        registerMutation.mutate(
            {
                name: form.name.trim(),
                address: form.address.trim(),
                latitude: lat,
                longitude: lng,
            },
            {
                onSuccess: () => navigate(ROUTES.STATIONS),
                onError: (err) => {
                    const serverMsg = err?.response?.data?.message || err?.response?.data?.title || err?.message
                    setError(serverMsg ? `Registration failed: ${serverMsg}` : 'Failed to register station. Please check network connection and inputs.')
                },
            }
        )
    }

    return (
        <div className="flex w-full max-w-3xl flex-col gap-space-xl mx-auto mt-space-2xl">
            <div className="flex flex-col gap-space-2xs">
                <h1 className="font-headline-lg text-headline-lg text-on-surface">Register New Station</h1>
                <p className="font-body-md text-body-md text-on-surface-variant">
                    Submit your station details. Once submitted, it will be in a <strong>Pending</strong> state
                    awaiting Platform Administrator approval.
                </p>
            </div>

            <form onSubmit={handleSubmit} className="flex flex-col gap-space-lg bg-surface-container-lowest p-space-xl rounded-xl shadow-md">
                {error && (
                    <div className="rounded bg-error-container p-space-md text-on-error-container font-body-sm">
                        {error}
                    </div>
                )}

                <div className="flex flex-col gap-space-2xs">
                    <label className="font-label-md text-label-md text-on-surface">Station Name</label>
                    <input
                        type="text"
                        className="rounded border border-outline bg-surface px-space-md py-space-sm text-on-surface"
                        placeholder="e.g. Downtown Fast Charging Hub"
                        value={form.name}
                        onChange={(e) => setForm({ ...form, name: e.target.value })}
                        required
                    />
                </div>

                <div className="flex flex-col gap-space-2xs">
                    <label className="font-label-md text-label-md text-on-surface">Full Address</label>
                    <input
                        type="text"
                        className="rounded border border-outline bg-surface px-space-md py-space-sm text-on-surface"
                        placeholder="123 Main St, City"
                        value={form.address}
                        onChange={(e) => setForm({ ...form, address: e.target.value })}
                        required
                    />
                </div>

                <div className="grid grid-cols-2 gap-space-lg">
                    <div className="flex flex-col gap-space-2xs">
                        <label className="font-label-md text-label-md text-on-surface">Latitude</label>
                        <input
                            type="number"
                            step="any"
                            className="rounded border border-outline bg-surface px-space-md py-space-sm text-on-surface"
                            placeholder="e.g. 6.9271"
                            value={form.latitude}
                            onChange={(e) => setForm({ ...form, latitude: e.target.value })}
                            required
                        />
                    </div>
                    <div className="flex flex-col gap-space-2xs">
                        <label className="font-label-md text-label-md text-on-surface">Longitude</label>
                        <input
                            type="number"
                            step="any"
                            className="rounded border border-outline bg-surface px-space-md py-space-sm text-on-surface"
                            placeholder="e.g. 79.8612"
                            value={form.longitude}
                            onChange={(e) => setForm({ ...form, longitude: e.target.value })}
                            required
                        />
                    </div>
                </div>

                <div className="mt-space-md flex gap-space-md">
                    <button
                        type="button"
                        onClick={() => navigate(ROUTES.STATIONS)}
                        className="rounded-lg border border-outline px-space-lg py-space-md font-label-lg text-label-lg text-on-surface transition-colors hover:bg-surface-container"
                    >
                        Cancel
                    </button>
                    <button
                        type="submit"
                        disabled={registerMutation.isPending}
                        className="rounded-lg bg-primary px-space-lg py-space-md font-label-lg text-label-lg text-on-primary transition-colors hover:bg-primary/90 disabled:opacity-50"
                    >
                        {registerMutation.isPending ? 'Submitting...' : 'Register Station'}
                    </button>
                </div>
            </form>
        </div>
    )
}
