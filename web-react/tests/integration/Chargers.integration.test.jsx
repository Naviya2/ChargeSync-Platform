import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import ChargersTab from '../../src/features/stations/components/tabs/ChargersTab';
import { expect, test, vi, beforeEach } from 'vitest';

vi.mock('../../src/features/stations/hooks/useStations', () => ({
  useAddCharger: () => ({
    mutate: vi.fn((data, options) => {
      options.onSuccess && options.onSuccess();
    }),
    isPending: false
  }),
  useUpdateCharger: () => ({
    mutate: vi.fn(),
    isPending: false
  }),
  useDeleteCharger: () => ({
    mutate: vi.fn(),
    isPending: false
  }),
  useBays: () => ({
    data: [{ id: 'bay-1', name: 'Bay 1' }, { id: 'bay-2', name: 'Bay 2' }]
  })
}));

vi.mock('../../src/store/dialogStore', () => ({
  default: {
    getState: () => ({
      alert: vi.fn(),
      confirm: vi.fn().mockResolvedValue(true)
    })
  }
}));

const mockChargers = [
  { id: 'ch-1', identifier: 'CH-01', connectorTypeId: 'CCS2', powerKw: 150, tariff: 0.50, status: 'available' }
];

beforeEach(() => {
  vi.clearAllMocks();
});

test('renders ChargersTab and lists chargers', () => {
  render(<ChargersTab stationId="st-1" chargers={mockChargers} />);
  expect(screen.getByText('Configured Chargers (1 Physical Units)')).toBeInTheDocument();
  expect(screen.getByText('CH-01')).toBeInTheDocument();
});

test('opens add charger form and submits', async () => {
  render(<ChargersTab stationId="st-1" chargers={mockChargers} />);

  const addButton = screen.getByText('Add Charger');
  await userEvent.click(addButton);

  expect(screen.getByText('Register New Charger')).toBeInTheDocument();

  const idInput = screen.getByLabelText(/Identifier/i);
  await userEvent.type(idInput, 'CH-02');

  const bayInput = screen.getByLabelText(/Bay Label/i);
  await userEvent.selectOptions(bayInput, 'Bay 2');

  const saveButton = screen.getByText('Save Charger');
  await userEvent.click(saveButton);

  await waitFor(() => {
    expect(screen.queryByText('Register New Charger')).not.toBeInTheDocument();
  });
});
