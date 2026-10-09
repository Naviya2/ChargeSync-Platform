import { render, screen, fireEvent } from '@testing-library/react'
import { expect, test, vi } from 'vitest'
import ImageUploader from '@/components/shared/ImageUploader'

test('NF-TC-04 Security: ImageUploader rejects non-image files (e.g. .exe)', async () => {
  const onChangeMock = vi.fn()
  render(<ImageUploader urls={[]} onChange={onChangeMock} />)

  const fileInput = screen.getByLabelText(/Upload/i)

  const maliciousFile = new File(['mock malware content'], 'malware.exe', { type: 'application/x-msdownload' })

  fireEvent.change(fileInput, { target: { files: [maliciousFile] } })

  const errorMessage = await screen.findByText(/failed/i, {}, { timeout: 2000 }).catch(() => null)

  expect(onChangeMock).not.toHaveBeenCalled()
})
