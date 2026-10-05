import { fireEvent, render, screen } from '@testing-library/react'
import { expect, test, vi } from 'vitest'
import OperatingHoursTab from '@/features/stations/components/tabs/OperatingHoursTab'

const { mutate } = vi.hoisted(() => ({ mutate: vi.fn() }))
vi.mock('@/features/stations/hooks/useStations', () => ({
  useUpdateOperatingHours: () => ({ mutate, isPending: false }),
}))

test('retains draft edits across identical refetches and resets when saved hours change', () => {
  const hours = [{ dayOfWeek: 1, openTime: '08:00:00', closeTime: '18:00:00' }]
  const { container, rerender } = render(<OperatingHoursTab stationId="station-1" hours={hours} />)
  const openingInput = () => container.querySelector('input[type="time"]')
  expect(openingInput()).toHaveValue('08:00')
  fireEvent.change(openingInput(), { target: { value: '09:00' } })

  rerender(<OperatingHoursTab stationId="station-1" hours={hours.map(row => ({ ...row }))} />)
  expect(openingInput()).toHaveValue('09:00')
  fireEvent.click(screen.getByRole('button', { name: /save access schedule/i }))
  expect(mutate).toHaveBeenCalledWith({
    stationId: 'station-1',
    data: expect.arrayContaining([
      expect.objectContaining({ dayOfWeek: 1, openTime: '09:00:00', closeTime: '18:00:00' }),
    ]),
  }, expect.any(Object))

  rerender(<OperatingHoursTab stationId="station-1" hours={[{ ...hours[0], openTime: '10:00:00' }]} />)
  expect(openingInput()).toHaveValue('10:00')
  rerender(<OperatingHoursTab stationId="station-2" hours={[]} />)
  expect(openingInput()).toHaveValue('06:00')
})
