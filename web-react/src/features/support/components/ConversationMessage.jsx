import { cn } from '../../../lib/cn'

function Avatar({ name }) {
  const initials = (name ?? '?')
    .split(' ')
    .map((w) => w[0])
    .slice(0, 2)
    .join('')
  return (
    <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-surface-container-high font-label-sm text-label-sm text-on-surface">
      {initials}
    </span>
  )
}

export default function ConversationMessage({ message }) {
  if (message.type === 'system') {
    return (
      <div className="flex justify-center">
        <div className="flex items-center gap-space-xs rounded-full bg-surface-container-high px-space-md py-space-2xs font-label-sm text-label-sm text-on-surface-variant shadow-sm">
          <span className={cn('material-symbols-outlined text-sm', message.iconTone)}>
            {message.icon}
          </span>
          <span>{message.text}</span>
        </div>
      </div>
    )
  }

  if (message.type === 'ai') {
    return (
      <div className="w-full rounded-xl bg-gradient-to-r from-primary-fixed/20 to-surface-container-lowest p-space-md shadow-sm">
        <div className="flex items-start gap-space-sm">
          <span className="material-symbols-outlined text-xl text-primary">psychology</span>
          <div className="flex flex-col gap-space-2xs">
            <div className="flex flex-wrap items-center gap-space-xs">
              <span className="font-headline-sm text-body-sm font-semibold text-primary">
                {message.author}
              </span>
              {message.badge && (
                <span className="rounded bg-primary px-space-xs py-space-2xs font-label-sm text-label-sm text-on-primary">
                  {message.badge}
                </span>
              )}
            </div>
            <p className="font-body-sm text-body-sm text-on-surface">{message.body}</p>
          </div>
        </div>
      </div>
    )
  }

  const isSupport = message.type === 'support'

  return (
    <div
      className={cn(
        'flex max-w-xl items-start gap-space-md',
        isSupport ? 'ml-auto flex-row-reverse' : '',
      )}
    >
      <Avatar name={message.author} />
      <div className={cn('flex flex-col gap-space-2xs', isSupport && 'items-end')}>
        <div className="flex items-center gap-space-xs">
          {isSupport ? (
            <>
              <span className="font-label-sm text-label-sm text-on-surface-variant">{message.time}</span>
              <span className="font-headline-sm text-headline-sm font-semibold text-primary">
                {message.author}
              </span>
            </>
          ) : (
            <>
              <span className="font-headline-sm text-headline-sm text-on-surface">{message.author}</span>
              <span className="font-label-sm text-label-sm text-on-surface-variant">{message.time}</span>
            </>
          )}
        </div>
        <div
          className={cn(
            'p-space-md font-body-md text-body-md shadow-sm',
            isSupport
              ? 'rounded-2xl rounded-tr-none bg-primary text-on-primary'
              : 'rounded-2xl rounded-tl-none bg-surface-container-lowest text-on-surface',
          )}
        >
          {message.body}
        </div>
      </div>
    </div>
  )
}
