import { AI_RECOMMENDATIONS } from '../data/dashboardData'
import { cn } from '../../../lib/cn'

const TAG_TONE = {
  neutral: 'bg-surface-container text-on-surface-variant',
  error: 'bg-error-container/40 text-on-error-container',
}

function RecommendationActions({ item }) {
  if (item.status === 'auto-approved') {
    return (
      <span className="inline-flex items-center gap-1 rounded-lg bg-tertiary-container/15 px-space-sm py-space-xs font-label-md text-label-md text-tertiary">
        <span className="material-symbols-outlined text-sm">verified</span>
        Auto Approved
      </span>
    )
  }
  if (item.status === 'awaiting-review') {
    return (
      <div className="flex items-center gap-space-xs">
        <button
          type="button"
          className="rounded-lg bg-primary px-space-sm py-space-xs font-label-md text-label-md text-on-primary transition-all hover:bg-primary-container"
        >
          Quick Approve
        </button>
        <button
          type="button"
          className="rounded-lg bg-surface-container-high px-space-sm py-space-xs font-label-md text-label-md text-on-surface transition-colors hover:bg-surface-container-highest"
        >
          Adjust
        </button>
        <button
          type="button"
          aria-label="Dismiss recommendation"
          className="rounded-lg p-space-xs text-on-surface-variant transition-colors hover:text-error"
        >
          <span className="material-symbols-outlined text-base">close</span>
        </button>
      </div>
    )
  }
  return (
    <button
      type="button"
      className="rounded-lg bg-surface-container-high px-space-md py-space-xs font-label-md text-label-md text-on-surface transition-colors hover:bg-surface-container-highest"
    >
      Review Plan
    </button>
  )
}

export default function AiGridQueue() {
  return (
    <div className="flex flex-col gap-space-md rounded-xl bg-surface-container-lowest p-space-lg shadow-sm">
      <div className="flex flex-col justify-between gap-space-sm pb-space-sm sm:flex-row sm:items-center">
        <div className="flex items-center gap-space-sm">
          <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-primary-container/15 text-primary">
            <span className="material-symbols-outlined text-lg">auto_awesome</span>
          </div>
          <div>
            <h2 className="font-headline-sm text-headline-sm text-on-surface">
              AI Dynamic Grid &amp; Rate Adjustments
            </h2>
            <p className="font-label-sm text-label-sm text-on-surface-variant">
              Real-time telemetry inference with automatic guardrail triggers
            </p>
          </div>
        </div>
        <span className="inline-flex items-center gap-1.5 self-start rounded-full bg-tertiary-container/10 px-space-sm py-space-2xs font-label-sm text-label-sm text-tertiary sm:self-auto">
          <span className="h-2 w-2 animate-ping rounded-full bg-tertiary" />
          Auto-Pilot Guardrails Active
        </span>
      </div>

      <div className="flex flex-col gap-space-sm">
        {AI_RECOMMENDATIONS.map((item) => (
          <div
            key={item.id}
            className="flex flex-col items-start justify-between gap-space-md rounded-xl bg-surface-container-low p-space-md transition-colors hover:bg-surface-container sm:flex-row sm:items-center"
          >
            <div className="flex min-w-0 items-start gap-space-md">
              <span className={cn('material-symbols-outlined mt-1 text-xl', item.iconTone)}>
                {item.icon}
              </span>
              <div className="min-w-0">
                <div className="flex flex-wrap items-center gap-space-xs">
                  <span className="font-headline-sm text-body-md font-semibold text-on-surface">
                    {item.title}
                  </span>
                  <span
                    className={cn(
                      'rounded px-space-xs py-0.5 font-label-sm text-label-sm',
                      TAG_TONE[item.tag.tone] ?? TAG_TONE.neutral,
                    )}
                  >
                    {item.tag.text}
                  </span>
                </div>
                <p className="mt-0.5 font-body-sm text-body-sm text-on-surface-variant">{item.body}</p>
              </div>
            </div>

            <div className="flex shrink-0 items-center gap-space-md self-end sm:self-center">
              <div className="text-right">
                <span className="font-label-sm text-label-sm text-on-surface-variant">Confidence</span>
                <p className={cn('font-label-md text-label-md font-semibold', item.confidenceTone)}>
                  {item.confidence}%
                </p>
              </div>
              <RecommendationActions item={item} />
            </div>
          </div>
        ))}
      </div>

      <div className="flex items-center justify-between pt-space-sm font-label-md text-label-md">
        <span className="text-on-surface-variant">System confidence baseline requirement: ≥ 85%</span>
        <a
          href="#queue"
          className="inline-flex items-center gap-1 font-semibold text-primary transition-colors hover:text-primary-container"
        >
          <span>View all 14 pending AI decisions</span>
          <span className="material-symbols-outlined text-sm">arrow_forward</span>
        </a>
      </div>
    </div>
  )
}
