import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import StationCard from '../../../src/features/stations/components/StationCard';
import { expect, test, vi } from 'vitest';

const mockStation = {
  id: 'st-01',
  name: 'Central Plaza',
  address: '123 Main St',
  sector: 'Downtown',
  status: { label: 'Online', tone: 'secondary', pulse: true },
  capacity: '500 kW',
  bayLabel: 'Available Bays',
  bayValue: '2 / 5',
  load: 40,
  trendLabel: 'Utilization',
  trendValue: '40%',
  sparkTone: 'secondary',
  footerLabel: 'Revenue',
  footerValue: '$120'
};

test('renders StationCard with correct information', () => {
  render(<StationCard station={mockStation} selected={false} onSelect={() => { }} />);

  expect(screen.getByText('Central Plaza')).toBeInTheDocument();
  expect(screen.getByText('123 Main St')).toBeInTheDocument();
  expect(screen.getByText('Online')).toBeInTheDocument();
  expect(screen.getByText('500 kW')).toBeInTheDocument();
});

test('calls onSelect when clicked', async () => {
  const onSelectMock = vi.fn();
  render(<StationCard station={mockStation} selected={false} onSelect={onSelectMock} />);

  const card = screen.getByRole('button');
  await userEvent.click(card);

  expect(onSelectMock).toHaveBeenCalledWith('st-01');
});
