import { beforeAll, afterAll, afterEach, describe, expect, it, vi } from 'vitest'
import { act, cleanup, render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'

let LandingPage
let gsap
let reducedMotion = false

beforeAll(async () => {
  vi.stubGlobal('matchMedia', (query) => ({
    media: query,
    matches: query.includes('no-preference') ? !reducedMotion : query.includes('reduce') && reducedMotion,
    addListener: vi.fn(),
    removeListener: vi.fn(),
    addEventListener: vi.fn(),
    removeEventListener: vi.fn(),
  }))
  vi.stubGlobal('scrollTo', vi.fn())
  ;({ gsap } = await import('gsap'))
  ;({ default: LandingPage } = await import('../../src/features/landing/pages/LandingPage'))
})

afterEach(() => {
  cleanup()
  reducedMotion = false
})

afterAll(() => vi.unstubAllGlobals())

function renderLanding() {
  return render(<MemoryRouter><LandingPage /></MemoryRouter>)
}

describe('landing page motion', () => {
  it('reverts animation styles when navigating away from the page', () => {
    const { container, unmount } = renderLanding()
    const cards = Array.from(container.querySelectorAll('[data-reveal]'))
    expect(cards.length).toBeGreaterThan(0)
    expect(cards.some((card) => card.style.visibility === 'hidden')).toBe(true)

    unmount()

    cards.forEach((card) => {
      expect(card.style.visibility).toBe('')
      expect(card.style.opacity).toBe('')
      expect(card.style.transform).toBe('')
    })
  })

  it('keeps all content visible when reduced motion is enabled', () => {
    reducedMotion = true
    const { container } = renderLanding()
    expect(screen.getByRole('heading', { level: 1 })).toBeVisible()
    expect(screen.getByRole('link', { name: 'Get Started Free' })).toBeVisible()
    expect(Array.from(container.querySelectorAll('[data-stat-count]'), (element) => element.textContent)).toEqual([
      '1,248+', '145,000+', '96.4%', '28 min',
    ])
    container.querySelectorAll('[data-reveal], [data-hero-copy] > *, [data-hero-device]').forEach((element) => {
      expect(element.style.visibility).toBe('')
      expect(element.style.opacity).toBe('')
      expect(element.style.transform).toBe('')
    })
  })

  it('restores content when the motion preference changes while the page is open', () => {
    const { container } = renderLanding()
    reducedMotion = true
    act(() => gsap.matchMediaRefresh())

    expect(Array.from(container.querySelectorAll('[data-stat-count]'), (element) => element.textContent)).toEqual([
      '1,248+', '145,000+', '96.4%', '28 min',
    ])

    container.querySelectorAll('[data-reveal], [data-hero-copy] > *, [data-hero-device]').forEach((element) => {
      expect(element.style.visibility).toBe('')
      expect(element.style.opacity).toBe('')
      expect(element.style.transform).toBe('')
    })
  })

  it('counts to the exact formatted metrics without changing their accessible values', () => {
    const { container } = renderLanding()
    const counters = Array.from(container.querySelectorAll('[data-stat-count]'))
    act(() => gsap.globalTimeline.getChildren(true, true, false)
      .filter((tween) => tween.vars.onUpdate && tween.vars.onComplete)
      .forEach((tween) => tween.progress(1)))

    expect(counters.map((element) => element.textContent)).toEqual([
      '1,248+', '145,000+', '96.4%', '28 min',
    ])
    counters.forEach((element) => {
      expect(element).toHaveAttribute('aria-hidden', 'true')
      expect(element.parentElement.querySelector('.sr-only').textContent).toBe(element.textContent)
    })
  })
})
