import { lazy, Suspense } from 'react'
import { act, cleanup, render, screen } from '@testing-library/react'
import { afterEach, expect, it, vi } from 'vitest'
import BrandLoadingScreen from '../../src/components/shared/BrandLoadingScreen'
import lazyPage from '../../src/routes/lazyPage'

afterEach(() => {
  cleanup()
  vi.useRealTimers()
})

it('shows the branded fallback while a page loads and removes it when ready', async () => {
  let resolvePage
  const pageModule = new Promise((resolve) => { resolvePage = resolve })
  const Page = lazy(() => pageModule)
  render(<Suspense fallback={<BrandLoadingScreen />}><Page /></Suspense>)

  const loading = screen.getByRole('status', { name: 'Loading ChargeSync' })
  expect(loading).toHaveAttribute('aria-busy', 'true')
  expect(loading).toHaveTextContent('ChargeSync')
  expect(loading).toHaveTextContent('Powering Tomorrow')
  expect(loading.querySelector('img')).toHaveAttribute('src', '/brand/chargesync-icon.png')

  await act(async () => {
    resolvePage({ default: () => <h1>Page ready</h1> })
    await pageModule
  })

  expect(screen.getByRole('heading', { name: 'Page ready' })).toBeVisible()
  expect(screen.queryByRole('status')).not.toBeInTheDocument()
})

it('keeps the branded screen visible for 1.2 seconds even when a page is ready immediately', async () => {
  vi.useFakeTimers()
  const Page = lazyPage(() => Promise.resolve({ default: () => <h1>Page ready</h1> }))
  render(<Suspense fallback={<BrandLoadingScreen />}><Page /></Suspense>)

  await act(async () => { await vi.advanceTimersByTimeAsync(1199) })
  expect(screen.getByRole('status', { name: 'Loading ChargeSync' })).toBeVisible()
  expect(screen.queryByRole('heading', { name: 'Page ready' })).not.toBeInTheDocument()

  await act(async () => { await vi.advanceTimersByTimeAsync(1) })
  expect(screen.getByRole('heading', { name: 'Page ready' })).toBeVisible()
  expect(screen.queryByRole('status')).not.toBeInTheDocument()
})

it('continues loading after the minimum time if the page still is not ready', async () => {
  vi.useFakeTimers()
  let resolvePage
  const pageModule = new Promise((resolve) => { resolvePage = resolve })
  const Page = lazyPage(() => pageModule)
  render(<Suspense fallback={<BrandLoadingScreen />}><Page /></Suspense>)

  await act(async () => { await vi.advanceTimersByTimeAsync(2000) })
  expect(screen.getByRole('status', { name: 'Loading ChargeSync' })).toBeVisible()

  await act(async () => {
    resolvePage({ default: () => <h1>Page ready</h1> })
    await pageModule
  })
  expect(screen.getByRole('heading', { name: 'Page ready' })).toBeVisible()
  expect(screen.queryByRole('status')).not.toBeInTheDocument()
})
