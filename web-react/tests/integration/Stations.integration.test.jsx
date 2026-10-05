import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import RegisterStationPage from '../../src/features/stations/pages/RegisterStationPage';
import { expect, test, vi, beforeEach } from 'vitest';
import { BrowserRouter } from 'react-router-dom';

const mockNavigate = vi.fn();

vi.mock('react-router-dom', async () => {
  const actual = await vi.importActual('react-router-dom');
  return {
    ...actual,
    useNavigate: () => mockNavigate
  };
});

vi.mock('../../src/features/stations/hooks/useStations', () => ({
  useRegisterStation: () => ({
    mutate: vi.fn((data, options) => {
      if (options && options.onSuccess) {
        options.onSuccess();
      }
    }),
    isPending: false
  })
}));

vi.mock('../../src/components/shared/MapLocationPicker', () => ({
  default: ({ onLocationChange, onAddressFetched }) => (
    <div data-testid="map-picker">
      <button
        type="button"
        onClick={() => {
          onLocationChange(40.7128, -74.0060);
          onAddressFetched('123 New York St');
        }}
      >
        Set Location
      </button>
    </div>
  )
}));

vi.mock('../../src/components/shared/ImageUploader', () => ({
  default: ({ onChange }) => (
    <div data-testid="image-uploader">
      <button
        type="button"
        onClick={() => onChange(['http://example.com/doc.jpg'])}
      >
        Upload Doc
      </button>
    </div>
  )
}));

beforeEach(() => {
  vi.clearAllMocks();
});

test('registers a new station successfully', async () => {
  render(
    <BrowserRouter>
      <RegisterStationPage />
    </BrowserRouter>
  );

  expect(screen.getByText('Register New Station')).toBeInTheDocument();

  const nameInput = screen.getByPlaceholderText('e.g. Downtown Fast Charging Hub');
  await userEvent.type(nameInput, 'My New Station');

  const setLocationBtn = screen.getByText('Set Location');
  await userEvent.click(setLocationBtn);

  const uploadDocBtn = screen.getByText('Upload Doc');
  await userEvent.click(uploadDocBtn);

  const submitBtn = screen.getByText('Register Station');
  await userEvent.click(submitBtn);

  await waitFor(() => {
    expect(mockNavigate).toHaveBeenCalled();
  });
});
