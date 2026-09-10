import AuthBrandPanel from './AuthBrandPanel'

/**
 * Split-screen shell shared by the sign-in and sign-up screens:
 * the dark brand panel on the left, the form (`children`) on the right.
 *
 * @param {{ children: React.ReactNode, panelVariant?: 'signin' | 'signup' }} props
 */
export default function AuthLayout({ children, panelVariant = 'signin' }) {
  return (
    <div className="flex min-h-screen w-full flex-col bg-slate-50 md:flex-row">
      <AuthBrandPanel variant={panelVariant} />
      {children}
    </div>
  )
}
