import { useLayoutEffect } from 'react'
import { gsap } from 'gsap'
import { ScrollTrigger } from 'gsap/dist/ScrollTrigger'

gsap.registerPlugin(ScrollTrigger)

/** Scope motion to this page and revert it on route or motion-preference changes. */
export default function useLandingAnimations(pageRef) {
  useLayoutEffect(() => {
    const page = pageRef.current
    if (!page) return

    const media = gsap.matchMedia()
    media.add(
      {
        motion: '(prefers-reduced-motion: no-preference)',
        reduced: '(prefers-reduced-motion: reduce)',
        desktop: '(min-width: 1024px)',
      },
      (context) => {
        if (!context.conditions.motion || context.conditions.reduced) return

        const select = gsap.utils.selector(page)
        const entrance = gsap.timeline({ defaults: { ease: 'power3.out' } })
        entrance
          .from(select('[data-hero-copy] > *'), {
            y: 24,
            autoAlpha: 0,
            duration: 0.8,
            stagger: 0.1,
            clearProps: 'transform,opacity,visibility',
          })
          .from(select('[data-hero-device]'), {
            y: 32,
            scale: 0.96,
            autoAlpha: 0,
            duration: 1,
            clearProps: 'transform,opacity,visibility',
          }, 0.2)
          .from(select('[data-hero-chip]'), {
            y: 12,
            autoAlpha: 0,
            duration: 0.65,
            stagger: 0.15,
            clearProps: 'transform,opacity,visibility',
          }, 0.65)

        select('[data-reveal]').forEach((element) => {
          const group = element.closest('[data-reveal-group]')
          const siblings = group ? Array.from(group.querySelectorAll('[data-reveal]')) : []
          gsap.from(element, {
            y: 24,
            autoAlpha: 0,
            duration: 0.7,
            delay: context.conditions.desktop ? Math.max(0, siblings.indexOf(element)) * 0.08 : 0,
            ease: 'power3.out',
            clearProps: 'transform,opacity,visibility',
            scrollTrigger: {
              trigger: element,
              start: 'top 90%',
              once: true,
            },
          })
        })

        const counters = select('[data-stat-count]').map((element) => ({
          element,
          original: element.textContent,
        }))
        counters.forEach(({ element }, index) => {
          const amount = Number(element.dataset.amount)
          const decimals = Number(element.dataset.decimals)
          const suffix = element.dataset.suffix
          const formatter = new Intl.NumberFormat('en-US', {
            minimumFractionDigits: decimals,
            maximumFractionDigits: decimals,
          })
          const counter = { value: 0 }
          const update = () => {
            element.textContent = `${formatter.format(counter.value)}${suffix}`
          }

          update()
          gsap.to(counter, {
            value: amount,
            duration: 1.9,
            delay: index * 0.12,
            ease: 'power2.out',
            onUpdate: update,
            onComplete: () => {
              element.textContent = `${formatter.format(amount)}${suffix}`
            },
            scrollTrigger: {
              trigger: element.closest('[data-reveal]'),
              start: 'top 90%',
              once: true,
            },
          })
        })

        if (context.conditions.desktop) {
          select('[data-hero-float]').forEach((element, index) => {
            gsap.to(element, {
              y: index % 2 === 0 ? -7 : 7,
              duration: 3 + index * 0.4,
              repeat: -1,
              yoyo: true,
              ease: 'sine.inOut',
              delay: 1.4,
              scrollTrigger: {
                trigger: select('[data-hero]')[0],
                start: 'top bottom',
                end: 'bottom top',
                toggleActions: 'play pause resume pause',
              },
            })
          })
        }

        // GSAP reverts its own styles; restore text changed by the counters too.
        return () => counters.forEach(({ element, original }) => {
          element.textContent = original
        })
      },
      page,
    )

    return () => media.revert()
  }, [pageRef])
}
