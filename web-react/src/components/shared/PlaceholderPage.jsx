import { Construction } from 'lucide-react'
import PageHeader from './PageHeader'
import Card from '../ui/Card'

/**
 * Temporary scaffold page. Replace with the real feature UI.
 *
 * @param {{ title: string, description?: string }} props
 */
export default function PlaceholderPage({ title, description }) {
  return (
    <div>
      <PageHeader title={title} description={description} />
      <Card className="flex flex-col items-center justify-center gap-3 py-16 text-center">
        <Construction className="text-brand-500" size={32} />
        <p className="text-sm font-medium text-slate-700">{title} — coming soon</p>
        <p className="max-w-sm text-xs text-slate-500">
          This is a placeholder. Feature components, hooks, and pages live under
          <code className="mx-1 rounded bg-slate-100 px-1 py-0.5">src/features/</code>.
        </p>
      </Card>
    </div>
  )
}
