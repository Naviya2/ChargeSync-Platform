import ConversationMessage from './ConversationMessage'
import ReplyComposer from './ReplyComposer'

const FAST_ACTIONS = [
  { icon: 'arrow_upward', iconTone: 'text-secondary', label: 'Escalate to Tier 2', tone: 'bg-surface-container hover:bg-surface-container-high text-on-surface' },
  { icon: 'smart_toy', label: 'Link AI Approval', tone: 'bg-primary-fixed/40 hover:bg-primary-fixed/60 text-on-primary-fixed-variant' },
  { icon: 'print', label: 'Print / Audit', tone: 'bg-surface-container hover:bg-surface-container-high text-on-surface' },
]

/**
 * @param {{ ticket: object, detail: object }} props
 */
export default function ConversationPanel({ ticket, detail }) {
  return (
    <main className="flex flex-col overflow-hidden rounded-xl bg-surface-container-lowest shadow-sm lg:col-span-5">
      {/* Header */}
      <div className="flex flex-col gap-space-sm bg-surface-container-lowest p-space-lg">
        <div className="flex flex-col">
          <div className="mb-space-2xs flex items-center gap-space-xs">
            <span className="rounded bg-surface-container-high px-space-xs py-space-2xs font-label-sm text-label-sm text-on-surface-variant">
              #{ticket.id}
            </span>
            <span className="rounded bg-error-container px-space-xs py-space-2xs font-label-sm text-label-sm text-on-error-container">
              {detail.category}
            </span>
          </div>
          <h2 className="font-headline-md text-headline-md text-on-surface">{ticket.title}</h2>
          <p className="font-body-sm text-body-sm text-on-surface-variant">{detail.createdMeta}</p>
        </div>

        <div className="flex flex-wrap items-center gap-space-xs pt-space-xs">
          {FAST_ACTIONS.map((a) => (
            <button
              key={a.label}
              type="button"
              className={`flex items-center gap-space-xs rounded-lg px-space-md py-space-xs font-label-sm text-label-sm transition-all ${a.tone}`}
            >
              <span className={`material-symbols-outlined text-sm ${a.iconTone ?? ''}`}>{a.icon}</span>
              <span>{a.label}</span>
            </button>
          ))}
        </div>
      </div>

      {/* Thread */}
      <div className="flex max-h-[500px] flex-col gap-space-lg overflow-y-auto bg-surface-container-low/40 p-space-lg">
        {detail.thread.map((message, i) => (
          <ConversationMessage key={i} message={message} />
        ))}
      </div>

      <ReplyComposer recipient={detail.driver.name} draft={detail.draftReply} />
    </main>
  )
}
